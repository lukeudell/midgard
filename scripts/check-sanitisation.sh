#!/usr/bin/env bash
#
# Sanitisation guard.
#
# This repository is the public face of a live residential network. The rule that
# nothing identifying may appear here is stated in CONTRIBUTING.md, and a rule that
# is only stated is a rule that gets broken during a late-night edit. This turns it
# into a check.
#
# It is deliberately noisy rather than clever: a false positive costs one
# `git diff` and a false negative costs a published address.
#
# Two limits, stated because a guard whose blind spots are undocumented is worse
# than one with none:
#
#   1. It scans the WORKING TREE, tracked and untracked, never history. A value
#      that was committed and later removed stays in the history and in every
#      fork, and this check will go green anyway. If that ever happens, rewriting
#      history is the fix and rotating what leaked is the other half of it.
#   2. Files on the EXCLUDES list below are unchecked by design, because a file
#      that discusses the rules has to be able to name the patterns. Those files
#      get read by a human or they get read by nobody. That is not theoretical:
#      a note describing an earlier scrub once republished, in full, the values
#      that scrub had removed. A redaction and the note describing it are the
#      same disclosure.
#
# Usage: scripts/check-sanitisation.sh [path...]   (defaults to the whole repo)

set -uo pipefail

TARGETS=("${@:-.}")
STATUS=0

# Files that are allowed to discuss the rules themselves.
EXCLUDES=(
  ":(exclude)scripts/check-sanitisation.sh"
  ":(exclude).claude/CLAUDE.md"
  ":(exclude).github/workflows/ci.yml"
)

report() {
  local label="$1" pattern="$2"
  local hits
  # -I skips binary; -n gives line numbers; -E extended regex.
  # --untracked matters more than it looks: without it this scans only files git
  # already knows about, so a vault file copied in and not yet `git add`ed reports
  # Clean. That is the exact sequence the check exists to stop (drop file, run
  # guard, see green, `git add .`), and it is invisible in CI because a checkout
  # only ever contains tracked files. Gitignored paths stay excluded, which is
  # what `private/` is for.
  hits=$(git grep -InE --untracked "$pattern" -- "${TARGETS[@]}" "${EXCLUDES[@]}" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "FAIL: $label"
    echo "$hits" | sed 's/^/    /'
    echo
    STATUS=1
  fi
}

echo "Checking for anything that should not be public..."
echo

# RFC1918 and CGNAT ranges, plus any dotted quad. A public IP is as bad as a
# private one here: it identifies the household.
report "IPv4 address" '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'

# CIDR notation, which often survives when the address itself is redacted.
# Anchored to a dotted quad on purpose: a bare /24 also matches Tailwind's opacity
# syntax (border-white/30), which would make this check noise instead of signal.
report "CIDR block" '\b([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}\b'

# MAC addresses.
report "MAC address" '\b([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\b'

# VLAN identifiers. The published pages use zone NAMES on purpose; a number is a
# targeting aid and carries no explanatory value to a reader.
report "VLAN number" '\b(vlan|VLAN)[ _-]?[0-9]+'

# Vendor and model strings pin a firmware version to an exploit.
report "vendor or model string" '\b(unifi|udm|usg|pfsense|opnsense|mikrotik|ubiquiti|synology|qnap)\b'

# Internal hostnames and domains.
report "internal hostname or domain" '\.(local|lan|internal|home|arpa)\b'

# Credentials of any shape.
report "possible credential" '\b(password|passwd|psk|pre-?shared|api[_-]?key|secret|token)[ ]*[:=][ ]*[^ ]'

# SSH keys and certificates.
report "key material" '(BEGIN (RSA|OPENSSH|EC|PGP|CERTIFICATE)|ssh-(rsa|ed25519) )'

if [ "$STATUS" -eq 0 ]; then
  echo "Clean: nothing matched."
else
  echo "One or more checks failed."
  echo "If a match is genuinely safe, do not weaken the pattern -- rewrite the text"
  echo "so it does not need the exception. This repo describes a design, not a device."
fi

exit "$STATUS"
