#!/usr/bin/env bash
#
# Extract one version's section from CHANGELOG.md for use as GitHub Release notes.
# Shared by both release workflows so the notes are the curated, human-written
# changelog entry (Keep a Changelog format) rather than scraped commit subjects.
#
# Usage: changelog-section.sh <version> [changelog-path] [out-file]
#   version   e.g. 0.1.2 (no leading "v")
#
# Prints everything between the "## [<version>]" heading and the next "## ["
# heading, with leading blank lines trimmed. Falls back to a one-line note so a
# release is never published with an empty body.
set -euo pipefail

version="${1:?usage: changelog-section.sh <version> [changelog] [outfile]}"
changelog="${2:-CHANGELOG.md}"
out="${3:-RELEASE_NOTES.md}"

awk -v ver="$version" '
  index($0, "## [" ver "]") == 1 { flag = 1; next }   # start of our section
  flag && index($0, "## [") == 1 { exit }             # next version -> stop
  flag && /^\[[^]]+\]: / { exit }                      # link-ref block -> stop
  flag { print }
' "$changelog" | awk 'NF { seen = 1 } seen' > "$out"   # drop leading blank lines

if [ ! -s "$out" ]; then
  printf 'Release %s\n' "$version" > "$out"
fi
