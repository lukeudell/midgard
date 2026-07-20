# Midgard: inherited state

Written 2026-07-19, at extraction from the `command_center` monorepo. Everything
here was found, not introduced.

Ordered by what would embarrass you most if a sharp interviewer found it first.

---

## 0. This project is not shaped like its siblings, and that is fine

The other three extracted projects are code repositories with a narrative attached.
Midgard is a narrative with no code at all. The five `.astro` pages in
`docs/source-pages/` are the entire contents of this repository, and by design they
always will be. The actual network configuration, scripts and telemetry pipeline
live in a private Obsidian vault outside this repository and must not be
copied here. See `CONTRIBUTING.md` for the boundary rule in full.

This is legitimate, and it is worth being able to say why without sounding
defensive. The subject of this project is a live residential network carrying a
family's traffic. Publishing its configuration would be a straightforward security
failure, and the discipline to publish the architecture without the addresses is
itself part of the exhibit. A hiring manager reading this should see someone who
understood the difference between showing their work and handing over the keys.

But the consequence is real: everything below follows from the fact that this
project cannot demonstrate itself the way the others can.

---

## 1. The published narrative claims code that is not in this repository

The index page says, of this project:

> "It also includes a real ETL pipeline: network telemetry scraped from the
> infrastructure controller, loaded into PostgreSQL, with automated alerting."

That claim is **true about the network and false about this repository**. The
pipeline exists (Python on a systemd timer, every fifteen minutes, into a local
Postgres), but it lives in the private vault under `04-Scripts/`, and this repo has
no `04-Scripts/` and never will. A visitor who reads "it also includes" and then
looks for it finds five Astro files.

This matters more than an ordinary inaccuracy. A portfolio piece that overstates is
worse than one that under-delivers, because the overstatement is the thing being
evaluated.

There are two honest resolutions, and the choice should be made deliberately rather
than deferred:

- **Extract a sanitised version.** Take the ETL, strip the real controller endpoint,
  credentials, addresses and device names, replace them with configuration read from
  environment variables, and commit that. This makes the claim demonstrable and gives
  the project the code artifact it currently lacks. It costs a careful scrubbing pass
  and an ongoing obligation to keep the sanitised copy from drifting back toward the
  real one.
- **Reword the claim.** Say plainly that the pipeline runs privately, describe its
  design (schedule, sources, destination, alerting, the four things the stored data
  enables), and do not imply the code is available. This costs nothing and is
  immediately true.

Either is defensible. Leaving it ambiguous is not. `docs/CASE_STUDY.md` has been
written to take the second option for now: it describes the pipeline's design and
states that the implementation is private. If you take the first option, the case
study needs updating to match.

## 2. The headline statistics are hand-written literals

The index page ticker publishes six figures: 9 VLANs, 7 trust zones, 50+ firewall
rules, 15+ doc pages, 99.9% uptime, 0 cloud dependencies. All six are typed into the
page by hand. Nothing measures any of them.

Most are defensible as counts of things you can go and count. The VLAN and zone
figures are structural and checkable against the vault. "50+" and "15+" are
deliberately loose, which is honest enough for round numbers.

**"99.9% uptime" is the weak one.** It is a precise-looking availability figure with
no measurement behind it, sitting next to five counts that are at least countable.
It is also the single claim on the page that an interviewer is most likely to ask
about, because it is the only one that implies instrumentation. Two options:

- Cite the source. The ETL does collect device uptime history, in the vault. If the
  figure comes from a real query over a stated window, say so: what was measured,
  over what period, and what counted as down.
- Drop it. A missing uptime number costs nothing. A number you cannot defend costs
  the credibility of the five next to it.

The same test applies to any figure added later: it is either traceable to something
real or it does not go on the page.

## 3. No demo, no dataset, no tests, so the writing has to do more work

This is the only one of the four projects with nothing to run. Andvari has a
forecaster and a 500K-row fact table. This has five pages of prose.

Under the portfolio's content contract that is fine. A project does not need a live
demo, and the `demo:` and `services:` blocks are meant to be left empty here. But it
changes what the case study has to carry. Elsewhere, a running application is the
evidence and the write-up is commentary. Here the write-up *is* the evidence, and
the only supporting artifacts available are diagrams and decision records.

Practically, that means:

- The four architecture decisions have to be written as real trade-offs, with the
  cost of each stated, not as a feature list. The single-infrastructure-node decision
  is the strongest of the four precisely because it accepts a single point of failure
  on purpose and explains the blast radius.
- The diagrams have to be good, because they are the only non-prose content.
- The documentation-as-artifact argument, which maps each vault section to its
  software-engineering equivalent, is the closest thing this project has to a thesis.
  It is also the part most directly relevant to a data engineering role. Lead with it
  rather than treating it as an appendix.

## 4. Sanitisation must be re-verified at publish time, not assumed

Every number, name and topology detail that goes public should be checked against the
sanitisation rule again immediately before publishing, not accepted as safe on the
grounds that it already appears in `docs/source-pages/`.

The existing pages are careful, and the sanitisation on them looks sound. But they
were written at one point in time against one state of the network, and the case
study rewrites and recombines their content, which is exactly the operation during
which a detail that was safe in isolation becomes identifying in combination. Zone
names plus role plus criticality plus a vendor model number is a materially
different disclosure from any one of those alone.

Treat the check as a release step with a named owner, not as an assumption inherited
from the source material.

## 5. The diagrams are trapped inside the Astro frontmatter

**Resolved 2026-07-19. See the addendum at the end of this section.**

There are four Mermaid diagrams, and all four exist only as template-literal strings
in the frontmatter of the pages that render them:

| Diagram | Currently in |
|---|---|
| Network topology | `architecture.astro` |
| Trust hierarchy | `segmentation.astro` |
| DNS resolution chain | `services.astro` |
| Service dependency map | `services.astro` |

The portfolio's content contract supports a `mermaid` embed kind directly, so these
should be extracted into `docs/diagrams/*.mmd` and referenced from `project.yaml`
rather than retyped. Worth doing: they are reusable, diffable once they are files,
and per §3 they are carrying an unusually large share of this project's evidential
weight.

Two things to handle in the extraction. The inline definitions carry hardcoded
vaporwave hex colours in `style` directives, which belong to the old site's theme and
may not survive the move. Decide whether the portfolio's renderer themes them
instead. And the diagram labels are themselves a sanitisation surface: they currently
use roles ("Compute Server", "Infrastructure Node") rather than hostnames, which is
correct and must stay that way.

### Addendum, 2026-07-19

All four are now in `docs/diagrams/*.mmd`, and all four are referenced from
`project.yaml`. What was decided along the way:

**Colour was dropped.** The hardcoded hex is gone, replaced by `classDef` classes
named for the trust tier: `infra`, `trusted`, `restricted`, `blocked`. The class
names survive a theme change; the hex would not have. If the portfolio wants colour it
assigns it once in the renderer.

**The `.mmd` files are canonical, and a check enforces it.** The contract's `mermaid`
embed takes diagram *text*, not a path, so `project.yaml` necessarily carries a second
copy of each diagram. `scripts/check-diagram-drift.sh` compares them and fails CI when
they disagree. Without it, the published diagram can stop matching the reviewed one
and nothing says so.

**`trust-hierarchy.mmd` was corrected, not just moved.** The original drew the trust
*ordering* using the same plain arrows the other diagrams use for *traffic*, so it
rendered as `TRUSTED --> WORK --> MEDIA --> IOT --> GUEST`, a permission chain, and
precisely the opposite of the default-deny policy the diagram exists to illustrate.
It now uses dotted edges for ordering and solid labelled edges for the actual written
exceptions.

That error is worth dwelling on for what kind of error it was. Nothing leaked and the
prose was accurate. The diagram's visual grammar simply contradicted the paragraph
beside it, which is a failure mode no regex catches and a reader of diagrams catches
immediately.

What this addendum does not resolve is listed under "open decisions" below.

---

## 6. Open decisions, for Luke

These are editorial or cross-repo calls rather than defects, so they are left open
deliberately.

**The portfolio renders `mermaid` embeds as source text.** The contract says so
plainly: *"`mermaid` | the diagram text itself | currently rendered as source text"*.
That is a problem specific to this project. §3 argues the diagrams carry an unusually
large share of the evidential weight precisely because there is nothing to run, and
right now they would publish as four code blocks. Ways out, in rough order of cost:
get the renderer to actually render Mermaid, which fixes it for every project at once
and is the right long-term answer; export PNG or SVG from the `.mmd` files and use
`image` embeds, which works today at the cost of a second artifact to keep in sync; or
accept source-text rendering, which is defensible for a technical audience and wastes
the diagrams on everyone else.

Decided 2026-07-19: import as-is and fix the renderer later. The `.mmd` files are the
input to any of the three, so nothing about the extraction is wasted either way. This
stays open because it is a portfolio-repo change, not a midgard one.

**Where the documentation argument sits. Decided 2026-07-19: moved to second.** §3
argued the documentation-as-artifact thesis should lead rather than sit as an appendix,
and it now runs directly after Overview in `project.yaml`. The counter-argument was
real, that a reader who has not yet seen the segmentation model has no reason to care
how it was documented, so the section opens by naming its own position and saying why:
segmentation is the more impressive artifact, documentation is the one that decides
whether any of it survives the person who built it. If that framing does not land with
readers, moving it back is a two-minute change and no other section depends on it.

**`published: false`.** `project.yaml` still ships unpublished, which is correct until
the sanitisation re-check in §4 has been done against the final text by a named owner.
That check is now partly mechanical (CI runs the guard on every push), but the guard
catches patterns, not judgement. The combination risk described in §4 (zone name plus
role plus criticality plus vendor detail) is invisible to a regex by construction, and
the leak found in this file's own appendix was invisible to it too. A green build is
not the signal to flip the flag. A human read is.

---

## Appendix: the sanitisation rule is now enforced, and it caught something

Added 2026-07-19.

`scripts/check-sanitisation.sh` turns the rule stated in `CONTRIBUTING.md` into a check
that CI runs on every push. It greps for IPv4 addresses, CIDR blocks, MAC
addresses, VLAN identifiers, vendor and model strings, internal hostnames and
domains, credential-shaped assignments, and key material.

**On its first run it found one real hit.** `docs/source-pages/segmentation.astro`
carried a rhetorical aside that named two specific VLAN numbers while arguing that
zone names are easier to remember than numbers. The argument survives without them,
and a reader has no way to know whether they were illustrative or real, so both were
replaced with `[redacted]`.

That is the only edit made to the archived pages, and it is marked inline rather
than done silently.

**This note used to quote the offending line in full, numbers included.** Which meant
the file explaining the redaction published exactly what the redaction removed, in the
same public repository, one directory up. Worse, it was invisible to CI: this file is
on the guard's exclude list, because a file that discusses the rules has to be able to
name the patterns it checks for. The exclusion is still right, but it is now understood
as a gap rather than a safe assumption. `.claude/CLAUDE.md`, `PROJECT_NOTES.md` and the check
itself are unguarded and get read by a human or they get read by nobody.

The general lesson is worth more than the specific fix: **a redaction and the note
describing it are the same disclosure**, and the note is the one nobody thinks to
check. If a future scrub needs recording, describe what class of thing was removed and
never restate the value.

Two notes on the check itself:

- It was noisy on first write. A bare CIDR pattern (`/24`, `/30`) matches
  Tailwind's opacity syntax, so `border-white/30` looked like a subnet. The
  pattern is now anchored to a dotted quad. A check that cries wolf is a check
  that gets skipped, so the tuning mattered.
- The publishable artifacts (`docs/CASE_STUDY.md`, `project.yaml`, `README.md`)
  pass cleanly on their own, which is the property that actually matters at
  publish time.

**If it fires on something you believe is safe, rewrite the sentence rather than
loosening the pattern.** This repository describes a design, not a device.
