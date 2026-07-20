#!/usr/bin/env bash
#
# Diagram drift guard.
#
# The portfolio's `mermaid` embed kind takes diagram TEXT, not a file path, so every
# diagram exists twice: canonically in docs/diagrams/*.mmd, and inlined into
# project.yaml for import. Two copies of anything drift, and the failure is silent --
# the published diagram simply stops matching the one under review.
#
# This extracts each inlined block back out of project.yaml and compares it to its
# .mmd file. Comment lines (%%) are deliberately not compared: they explain the
# diagram to a maintainer reading the repo, and carrying them into a rendered embed
# would put internal notes on a public page.
#
# Usage: scripts/check-diagram-drift.sh

set -uo pipefail

cd "$(dirname "$0")/.."

STATUS=0

# Maps a .mmd file to the embed title it appears under in project.yaml. The title is
# the anchor because it is also what the contract requires for accessibility, so it
# cannot be dropped without the import failing first.
declare -A DIAGRAMS=(
  ["docs/diagrams/topology.mmd"]="Network topology"
  ["docs/diagrams/trust-hierarchy.mmd"]="Trust hierarchy and permitted paths"
  ["docs/diagrams/dns-resolution.mmd"]="DNS resolution chain"
  ["docs/diagrams/service-map.mmd"]="Infrastructure node service map"
)

# why: compare the diagram, not the YAML indentation depth it happens to sit at.
normalise() {
  grep -v '^[[:space:]]*%%' | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//'
}

# Pull the `source: |` block that follows a given embed title out of project.yaml.
extract_embed() {
  local title="$1"
  awk -v title="$title" '
    index($0, "title: " title) { found = 1; next }
    found && /source: \|/       { collecting = 1; indent = -1; next }
    collecting {
      if ($0 ~ /^[[:space:]]*$/) { print; next }
      match($0, /^[[:space:]]*/)
      if (indent == -1) indent = RLENGTH
      if (RLENGTH < indent) exit
      print
    }
  ' project.yaml
}

for mmd in "${!DIAGRAMS[@]}"; do
  title="${DIAGRAMS[$mmd]}"

  if [ ! -f "$mmd" ]; then
    echo "FAIL: $mmd is missing but is still referenced by this check"
    STATUS=1
    continue
  fi

  canonical=$(normalise < "$mmd")
  inlined=$(extract_embed "$title" | normalise)

  if [ -z "$inlined" ]; then
    echo "FAIL: no embed titled '$title' found in project.yaml (source: $mmd)"
    STATUS=1
    continue
  fi

  if [ "$canonical" != "$inlined" ]; then
    echo "FAIL: $mmd has drifted from the '$title' embed in project.yaml"
    diff <(printf '%s\n' "$inlined") <(printf '%s\n' "$canonical") \
      | sed 's/^/    /' | head -40
    echo
    STATUS=1
  fi
done

# README.md carries a third copy of the topology diagram, in a ```mermaid fence.
# GitHub renders those natively, which is the only place in this project a reader
# sees a drawn diagram rather than diagram source, so it is worth keeping correct.
readme_block=$(awk '/^```mermaid$/{collecting=1; next} collecting && /^```$/{exit} collecting' README.md | normalise)
topology=$(normalise < docs/diagrams/topology.mmd)

if [ -z "$readme_block" ]; then
  echo "FAIL: no \`\`\`mermaid block found in README.md"
  STATUS=1
elif [ "$readme_block" != "$topology" ]; then
  echo "FAIL: README.md's mermaid block has drifted from docs/diagrams/topology.mmd"
  diff <(printf '%s\n' "$readme_block") <(printf '%s\n' "$topology") \
    | sed 's/^/    /' | head -40
  echo
  STATUS=1
fi

if [ "$STATUS" -eq 0 ]; then
  echo "Clean: all ${#DIAGRAMS[@]} diagrams match their inlined copies, README included."
else
  echo
  echo "The .mmd file is canonical. Fix project.yaml to match it, not the reverse."
fi

exit "$STATUS"
