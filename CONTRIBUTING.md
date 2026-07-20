# Contributing

This repository is the public, sanitised account of a live residential network. The
rule below is the reason it exists in the shape it does, and it outranks everything
else here.

## The one-way boundary

**This repository contains no infrastructure code, and it never should.**

The working documentation for the real network is private and lives outside this
repository. It contains real addresses, hostnames, VLAN numbers, credential standards
and topology detail for a network that is currently carrying a family's traffic. Its
location is deliberately not written down here.

The relationship between the two is **one-way and lossy**:

> The private documentation informs what can be **said** here. It never supplies what
> can be **pasted** here.

What gets published is zone *names* and not VLAN numbers, component *roles* and not
addresses. That sanitisation is a security control, not an oversight or an incomplete
draft. Do not "improve" the pages by adding the specifics back.

Nothing in this repository may ever contain:

- IP addresses, subnet ranges or CIDR blocks
- VLAN IDs or numbers
- Hostnames, device names or DNS records
- Vendor model numbers precise enough to pin a firmware version to a known CVE
- Port numbers tied to a named service on a named host
- Credential standards, port references or device inventory
- Screenshots or diagram exports that were not scrubbed and then re-checked

Rewrite from understanding rather than transcribing. Not a config excerpt, not a
table, not "just the sanitised bits" of something that also contains unsanitised bits.
A commit is public permanently, and a network takes weeks to re-address.

## The checks

```
bash scripts/check-sanitisation.sh      # blocking in CI
bash scripts/check-diagram-drift.sh
python scripts/check-project-yaml.py    # needs pyyaml
```

The sanitisation guard greps every push for addresses, subnets, MACs, VLAN
identifiers, vendor strings, internal hostnames, credential-shaped assignments and key
material. **If it fires on something you believe is safe, rewrite the text rather than
loosening the pattern.** This repository describes a design, not a device.

It has two blind spots, both documented in the script header: it never reads git
history, and it cannot check the files that discuss its own rules. Those get read by a
human or they get read by nobody.

## Working here

Nothing builds, runs or tests. Adding a build would mean putting infrastructure code
in a repository whose entire purpose is not to hold any.

- `docs/CASE_STUDY.md` is the working surface for prose. `docs/source-pages/` is
  read-only history and should not be edited.
- The four Mermaid diagrams are canonical in `docs/diagrams/*.mmd`. The README and
  `project.yaml` both carry inlined copies, because GitHub and the portfolio each want
  diagram text rather than a path. Edit the `.mmd` first, then run
  `check-diagram-drift.sh` to find what needs pasting.
- Every published figure must be traceable to something real, or removed.
- Conventional Commits. No em dashes, in prose, comments or commit messages.
