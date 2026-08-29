#!/usr/bin/env python3
"""Behavioural tests for check_purity.py.

Each test builds a synthetic crate in a temp dir and runs the checker as a
subprocess, asserting the exit code and the severity of the findings. Every
test here corresponds to a finding in CRITIQUE.md.

Run: python3 scripts/test_check_purity.py
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECKER = Path(__file__).resolve().parent / "check_purity.py"


def run_checker(cargo_toml: str, lib_rs: str):
    """Build a crate from the two given file bodies; return (exit_code, stdout)."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "Cargo.toml").write_text(cargo_toml, encoding="utf-8")
        (root / "src").mkdir()
        (root / "src" / "lib.rs").write_text(lib_rs, encoding="utf-8")
        proc = subprocess.run(
            [sys.executable, str(CHECKER), str(root)],
            capture_output=True, text=True,
        )
        return proc.returncode, proc.stdout


PURE_CARGO = """
[package]
name = "kernel"
version = "0.1.0"

[dependencies]
"""


class BannedCrateCoverage(unittest.TestCase):
    """CRITIQUE FATAL — the ban list must cover the invariant, not one stack."""

    def test_serde_json_error_in_public_signature_is_hard(self):
        code, out = run_checker(
            PURE_CARGO + 'serde_json = "1"\n',
            "pub fn to_json(&self) -> Result<String, serde_json::Error> { todo!() }\n",
        )
        self.assertEqual(code, 1, out)
        self.assertIn("HARD", out)

    def test_bincode_error_in_public_signature_is_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            "pub fn enc(&self) -> Result<Vec<u8>, bincode::Error> { todo!() }\n",
        )
        self.assertEqual(code, 1, out)

    def test_nonoptional_rand_dependency_is_hard(self):
        code, out = run_checker(PURE_CARGO + 'rand = "0.8"\n', "pub fn f() {}\n")
        self.assertEqual(code, 1, out)
        self.assertIn("rand", out)


class PublicSignatureDetection(unittest.TestCase):
    """CRITIQUE SERIOUS — the regex must cross an inner generic boundary."""

    def test_nested_generic_error_leak_is_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            "pub fn to_many(&self) -> Result<Vec<String>, serde_yaml::Error> { todo!() }\n",
        )
        self.assertEqual(code, 1, out)
        self.assertIn("HARD", out)

    def test_format_crate_as_public_argument_is_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            "pub fn load(v: serde_json::Value) -> u8 { todo!() }\n",
        )
        self.assertEqual(code, 1, out)

    def test_format_crate_in_an_enum_variant_payload_is_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            "pub enum KernelError {\n"
            "    Codec(serde_json::Error),\n"
            "}\n",
        )
        self.assertEqual(code, 1, out)
        self.assertIn("HARD", out)

    def test_flat_error_leak_is_still_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            "pub fn to_yaml(&self) -> Result<String, serde_yaml::Error> { todo!() }\n",
        )
        self.assertEqual(code, 1, out)


class DirectIoSeverity(unittest.TestCase):
    """CRITIQUE SERIOUS — a CI gate must fail on invariant #1 violations."""

    def test_filesystem_write_in_production_code_is_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            'pub fn save() { std::fs::write("generated/x", b"y").unwrap(); }\n',
        )
        self.assertEqual(code, 1, out)
        self.assertIn("HARD", out)

    def test_env_and_clock_access_is_hard(self):
        code, out = run_checker(
            PURE_CARGO,
            'pub fn f() { let _ = std::env::var("HOME"); }\n'
            "pub fn g() { let _ = std::time::SystemTime::now(); }\n",
        )
        self.assertEqual(code, 1, out)


class TestModuleScoping(unittest.TestCase):
    """CRITIQUE SERIOUS — suppression must end with the test module."""

    def test_io_below_a_test_module_is_still_flagged(self):
        code, out = run_checker(
            PURE_CARGO,
            "#[cfg(test)]\n"
            "mod tests {\n"
            '    #[test] fn t() { let _ = std::fs::read("f"); }\n'
            "}\n"
            "\n"
            'pub fn save() { std::fs::write("generated/x", b"y").unwrap(); }\n',
        )
        self.assertEqual(code, 1, out)
        self.assertIn("HARD", out)

    def test_io_inside_a_test_module_is_not_flagged(self):
        code, out = run_checker(
            PURE_CARGO,
            "pub fn pure(a: u8) -> u8 { a }\n"
            "\n"
            "#[cfg(test)]\n"
            "mod tests {\n"
            '    #[test] fn t() { let _ = std::fs::read("fixture"); }\n'
            "}\n",
        )
        self.assertEqual(code, 0, out)

    def test_cfg_test_inside_a_comment_does_not_suppress(self):
        code, out = run_checker(
            PURE_CARGO,
            "// helpers live under #[cfg(test)] in the sibling file\n"
            'pub fn save() { std::fs::write("generated/x", b"y").unwrap(); }\n',
        )
        self.assertEqual(code, 1, out)


class DefaultFeaturePurity(unittest.TestCase):
    """CRITIQUE SERIOUS — invariant #3, pure by default."""

    def test_default_feature_enabling_a_format_crate_is_hard(self):
        code, out = run_checker(
            PURE_CARGO
            + 'serde_json = { version = "1", optional = true }\n'
            + "\n[features]\ndefault = [\"serialization\"]\n"
            + 'serialization = ["dep:serde_json"]\n',
            "pub fn f() {}\n",
        )
        self.assertEqual(code, 1, out)
        self.assertIn("HARD", out)


class CleanCrate(unittest.TestCase):
    """No false positives on a crate that honours every invariant."""

    def test_pure_crate_exits_zero(self):
        code, out = run_checker(
            PURE_CARGO + 'serde = { version = "1", features = ["derive"] }\n'
            + "\n[features]\ndefault = []\n",
            "pub struct State(u8);\n"
            "pub fn apply(s: State, a: u8) -> State { State(s.0 + a) }\n",
        )
        self.assertEqual(code, 0, out)


if __name__ == "__main__":
    unittest.main(verbosity=2)
