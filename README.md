# Midgard

**A home network run the way production infrastructure is run.** Nine VLANs enforcing
seven trust zones, default-deny between all of them, recursive DNS that no third party
ever sees a query from, surveillance that never touches the internet, and a
documentation set treated as a deliverable rather than an afterthought.

Named for the walled middle enclosure of Norse cosmology: a segmented, defended home.

## This repository holds the narrative, not the network

The working documentation for the real network is private. It lives in an Obsidian
vault outside this repository, and it contains addresses, hostnames, VLAN numbers,
credential standards and topology detail for a network that is currently in use.

What you are reading is the sanitised public account of that network. It publishes
zone names and not VLAN numbers, component roles and not addresses. That is a
security control and not an incomplete draft. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the rule in full before contributing anything.

> `PROJECT_NOTES.md` is the honest account: why this project is structurally unlike
> its siblings, which claim on the original pages overstated what is actually here and
> how it was corrected, and which decisions are still open.

## There is nothing to run

No build, no compose stack, no tests, no entry point. This project contains
documentation and diagrams only, and by design it always will. The telemetry pipeline
described in the case study runs on the real network, not here.

## What's inside

| Path | What |
|---|---|
| [CONTRIBUTING.md](CONTRIBUTING.md) | The vault boundary, the sanitisation rule, the standards. Read before changing anything |
| `docs/CASE_STUDY.md` | The sanitised narrative. Source for `project.yaml` and anything public |
| `docs/diagrams/` | Mermaid sources, extracted from the original pages. Canonical; `project.yaml` inlines copies |
| `docs/source-pages/` | The original five site pages, kept verbatim. Read-only history |
| `PROJECT_NOTES.md` | Honest assessment: what is missing, what is overclaimed |
| `project.yaml` | How this appears on lukeudell.com. See [CONTRIBUTING.md](CONTRIBUTING.md) |

## The shape of it

Nine VLANs, seven trust zones, 50+ firewall rules, zero cloud dependencies. Zones are
named after Rod Serling's *The Twilight Zone*, which is a memory aid rather than a
joke: asking whether a device belongs in The Machine Realm or Junior Dimension is a
question a person can answer, in a way that asking which of two VLAN numbers it takes
is not.

The design philosophy in one line, from the original pages:

> Everything denied by default. Anything allowed is explicit, documented, and
> intentional.

## CI

`.github/workflows/ci.yml`, four jobs. There is no application, so CI does the jobs
that matter here instead:

| Job | What |
|---|---|
| Sanitisation guard | `scripts/check-sanitisation.sh`: greps for IP addresses, CIDR blocks, MACs, VLAN numbers, vendor strings, internal hostnames, credentials and key material |
| Import contract | `scripts/check-project-yaml.py`: `project.yaml` satisfies the portfolio's contract before it is handed to the importer |
| Diagram drift | `scripts/check-diagram-drift.sh`: every `docs/diagrams/*.mmd` matches the copy inlined into `project.yaml` |
| Internal links | every relative markdown link resolves |

The guard is blocking. It is the one control standing between a late-night edit and
a published address, and on its first run it caught a real one. If it fires on
something you believe is safe, rewrite the sentence rather than loosening the
pattern.

Run them yourself:

```
bash scripts/check-sanitisation.sh
bash scripts/check-diagram-drift.sh
python scripts/check-project-yaml.py     # needs pyyaml
```

## Standards

Built to `udell-blueprints`. See [CONTRIBUTING.md](CONTRIBUTING.md) for the specific
standards that bite in this project, and for the one rule that outranks all of them.
