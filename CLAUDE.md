# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository stores personal Claude Code configuration: custom skills, hooks, and related tooling for the `folkengine` account. Skills here extend Claude Code's behavior and are loaded via the plugin/skill system.

## Repository Structure

Skills are the primary artifact — markdown files with YAML frontmatter and embedded prompt/instruction blocks.

- `skills/` — custom Claude Code skills

## Enabled Plugins (from `~/.claude/settings.json`)

The following plugins are active in this Claude Code environment and may be relevant when authoring skills or testing locally:

- `mcp-server-dev` — MCP server scaffolding
- `playground` — interactive HTML playground generator
- `code-simplifier` — post-edit code cleanup
- `code-review` — PR review skill
- `huggingface-skills` — HuggingFace Hub, training, datasets, Gradio
- `claude-md-management` — CLAUDE.md auditing and improvement
- `explanatory-output-style` — educational insight overlays
- `rust-analyzer-lsp`, `playwright`, `github`, `security-guidance`

## Skill Authoring Notes

- Skill files use YAML frontmatter to declare `name`, `description`, and `trigger` conditions.
- The `Skill` tool in Claude Code invokes skills by name; the system-reminder lists available skills each turn.
- Skills interact with users through standard tool calls (Read, Edit, Bash, Write, etc.) — they do not have a separate API.
