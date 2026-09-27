#!/usr/bin/env bash
# huxley-scan.sh — find every commit, in every repo named by a .huxley file,
# that added or removed a search term. Read-only: uses git log only.
#
# Usage: bash huxley-scan.sh <.huxley path> <term> [<term> ...]
#        bash huxley-scan.sh --repos <.huxley path>
# Output: TSV sorted oldest first, one line per commit:
#   iso-datetime<TAB>repo<TAB>sha<TAB>terms-hit(comma list)<TAB>subject<TAB>commit-url
# --repos output: one line per repo:
#   repo<TAB>local-path<TAB>web-url<TAB>head-sha<TAB>head-pushed(yes|no)
# web-url and commit-url are "-" when the repo has no GitHub address.
# Stderr: progress, "MISSING <entry> -> <path>" for unresolved repos, git errors.
# -S matches substrings: a short term also hits longer identifiers.
#
# Resolution: https://github.com/Owner/name(.git) -> $HUXLEY_ROOT/github.com/Owner/name
# (HUXLEY_ROOT defaults to ~/src). Absolute or ~ paths are used as-is.
# HUXLEY_ALL=1 scans all branches (git log --all), not only HEAD.
# The repo that holds the .huxley file is always scanned too.
set -euo pipefail

list_repos=no
if [ "${1:-}" = --repos ]; then list_repos=yes; shift; fi
[ $# -ge 1 ] && { [ $list_repos = yes ] || [ $# -ge 2 ]; } \
  || { echo "usage: $0 <.huxley> <term> [term...] | $0 --repos <.huxley>" >&2; exit 2; }
config=$1; shift
root=${HUXLEY_ROOT:-$HOME/src}
home_repo=$(git -C "$(dirname "$config")" rev-parse --show-toplevel)

resolve() {
  local e=$1
  case $e in
    http*://*|git@*)
      e=${e%.git}; e=${e%/}
      e=${e#*://}; e=${e#git@}; e=${e/://}
      echo "$root/$e" ;;
    "~"/*) echo "$HOME/${e#\~/}" ;;
    *) echo "$e" ;;
  esac
}

# Web address of a repo: https://github.com/Owner/name, or "-" if not on GitHub.
web_url() {
  local e=$1
  e=${e%.git}; e=${e%/}
  case $e in
    git@github.com:*) echo "https://github.com/${e#git@github.com:}" ;;
    ssh://git@github.com/*) echo "https://github.com/${e#ssh://git@github.com/}" ;;
    https://github.com/*|http://github.com/*) echo "https://github.com/${e#*://github.com/}" ;;
    *) echo "-" ;;
  esac
}
origin_url() { git -C "$1" remote get-url origin 2>/dev/null || echo "-"; }

repos=("$home_repo")
webs=("$(web_url "$(origin_url "$home_repo")")")
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%%#*}; line=$(echo "$line" | xargs)
  [ -n "$line" ] || continue
  path=$(resolve "$line")
  if git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    repos+=("$path")
    w=$(web_url "$line"); [ "$w" = - ] && w=$(web_url "$(origin_url "$path")")
    webs+=("$w")
  else
    echo "MISSING $line -> $path" >&2
  fi
done < "$config"

if [ $list_repos = yes ]; then
  for i in "${!repos[@]}"; do
    repo=${repos[$i]}
    head=$(git -C "$repo" rev-parse HEAD)
    pushed=no; [ -n "$(git -C "$repo" branch -r --contains "$head" 2>/dev/null)" ] && pushed=yes
    printf '%s\t%s\t%s\t%s\t%s\n' "$(basename "$repo")" "$repo" "${webs[$i]}" "$head" "$pushed"
  done
  exit 0
fi

for i in "${!repos[@]}"; do
  repo=${repos[$i]}; web=${webs[$i]}
  name=$(basename "$repo")
  echo "scanning $name" >&2
  for term in "$@"; do
    if [ "$web" = - ]; then fmt="%aI%x09$name%x09%h%x09$term%x09%s%x09-"
    else fmt="%aI%x09$name%x09%h%x09$term%x09%s%x09$web/commit/%H"; fi
    git -C "$repo" log ${HUXLEY_ALL:+--all} -S"$term" --format="$fmt" \
      || echo "ERROR git log failed in $repo for term: $term" >&2
  done
done | awk -F'\t' -v OFS='\t' '
  { k = $2 SUBSEP $3
    if (k in terms) { terms[k] = terms[k] "," $4 }
    else { terms[k] = $4; line[k] = $1 OFS $2 OFS $3; subj[k] = $5; url[k] = $6; order[++n] = k } }
  END { for (i = 1; i <= n; i++) { k = order[i]; print line[k], terms[k], subj[k], url[k] } }
' | sort -s -t$'\t' -k1,1
