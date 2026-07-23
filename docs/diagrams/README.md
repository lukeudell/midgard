# Diagrams

Mermaid sources, extracted from the frontmatter of `../source-pages/*.astro` so they
are diffable and reusable.

**These files are canonical.** The portfolio's `mermaid` embed takes the diagram text
itself rather than a path, so `project.yaml` carries an inlined copy of each one. That
copy can fall out of step with this one, so `scripts/check-diagram-drift.sh` fails CI
when a `.mmd` file and its copy in `project.yaml` disagree. Edit the `.mmd`, then re-run
the check to find out what to paste.

| File | Shows | Extracted from |
|---|---|---|
| `topology.mmd` | Physical path from the internet inward | `architecture.astro` |
| `trust-hierarchy.mmd` | Seven trust levels and the permitted exceptions between them | `segmentation.astro` |
| `dns-resolution.mmd` | Query path from device to authoritative nameserver | `services.astro` |
| `service-map.mmd` | Services on the always-on infrastructure node | `services.astro` |
| `telemetry-schema.mmd` | The telemetry store's data model (the design; the implementation is private) | authored 2026-07-23 |

## What changed during extraction

**Colour moved from per-node `style` directives to `classDef`s.** The class names
(`infra`, `trusted`, `restricted`, `blocked`) describe the trust tier, and the hex
literals on them are not decoration: the portfolio's diagram renderer treats each hue
as a semantic slot key and resolves it through the active theme's tokens, so a redesign
recolours every diagram in one place without touching these files. Removing the hex
entirely would leave the renderer nothing to map and the diagrams grey.

**`trust-hierarchy.mmd` was corrected, not just moved.** See the comment at the top of
that file. The original drew the trust ordering with the same plain arrows used
everywhere else for traffic, which reads as a permission chain and contradicts the
default-deny policy the diagram exists to illustrate. It now distinguishes ordering
(dotted) from permitted paths (solid, labelled).

## The labels are a sanitisation surface

Every node is a **role**: "Infrastructure Node", "Core Switch", "Filtering Resolver".
None is a hostname, an address, a VLAN number or a vendor model. That must survive
every future edit. A diagram is the easiest place for a real name to slip in, because
it does not read like prose and nobody proofreads a node label.

`scripts/check-sanitisation.sh` covers these files. One label was rewritten on
extraction: the DNS sinkhole was captioned with a dotted quad, which is harmless in
substance but trips the guard. Per the repo's rule the text changed rather than the
pattern.
