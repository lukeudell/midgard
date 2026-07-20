# Contributing

Read this before changing anything in this repository. The first section is not
boilerplate: it is the reason the repository exists in the shape it does.

---

## The one-way boundary

**This repository contains no infrastructure code, and it never should.**

The real documentation lives privately in an Obsidian vault outside this repository.
It is organised into numbered sections for configuration, reference, operations and
scripts, alongside automation and network diagrams. It contains real IP addresses,
real hostnames, real VLAN numbers, credential standards and topology detail for a
network that is currently carrying a family's traffic.

The vault's location is deliberately not written down here. This file is public, and
naming the path would turn a foothold on the workstation into a directed grab at a
known target.

This repository is the sanitised, public-facing narrative about that network. The
relationship between the two is **one-way and lossy**:

> The vault informs what can be **said** here. It never supplies what can be
> **pasted** here.

The published pages deliberately give zone *names* and not VLAN numbers, component
*roles* and not addresses, and carry an explicit disclaimer that everything has been
sanitised: "an architecture showcase, not a penetration test invitation". That
sanitisation is a **security control**, not an oversight or an incomplete draft. Do
not "improve" the pages by adding the specifics back.

Concretely, nothing in this repository may ever contain:

- IP addresses, subnet ranges or CIDR blocks
- VLAN IDs or numbers
- Hostnames, device names or DNS records
- Vendor model numbers precise enough to pin a firmware version to a known CVE
- Port numbers tied to a named service on a named host
- Anything from the vault's port reference, password standards or device inventory
- Screenshots or PDF exports of the controller, dashboards or diagrams that were not
  scrubbed and then re-checked

**Do not read anything outside this repository, and do not go looking for the vault.**
You do not need it to work here, and reading it puts sensitive strings into whatever
produces the public text. The rule is deliberately broader than "avoid one path": a
rule that names its target is a rule that tells you where to look. If a fact is
missing, ask for a sanitised version rather than fetching it.

---

## Read these first

1. `PROJECT_NOTES.md`. This project is structurally unlike its three siblings: no
   code, no demo, no dataset, no tests. That is legitimate, but it changes what the
   case study has to carry, and it records which claims were overstated and which
   decisions are still open. Those are decisions to make, not bugs to fix quietly.
2. `README.md`, for what this is and the vault boundary in short form.
3. `docs/CASE_STUDY.md`, the sanitised narrative. This is the source for
   `project.yaml` and for anything public-facing.
4. `docs/source-pages/*.astro`, the original pages kept verbatim as reference. Do not
   edit these. They are a historical record, not a build input.

## What this project is for

Two audiences, and they want different things:

- **A hiring manager** wants evidence of systems thinking outside of paid work. The
  segmentation model and the four architecture decisions are the strongest artifacts.
  Each is a trade-off that was reasoned about and then written down, including the one
  that accepts a single point of failure on purpose.
- **Whoever maintains this in six months** wants an accurate public record of a
  network that will have changed by then, with no sensitive detail in it that would
  have to be scrubbed retroactively.

Both are served by the same discipline: every claim must be true, and nothing
published may help someone attack the network.

## Standards

Built to `udell-blueprints`. The ones that bite hardest in a repository made entirely
of prose:

- **[STD-11] Documentation.** This project *is* documentation. There is no code to
  hide behind, so the prose carries the argument on its own: structure, accuracy, and
  explaining *why* a decision was made rather than restating what was configured.
- **[STD-05] Security.** No credentials, no addresses, no topology detail. `.env`,
  `*.pdf`, spreadsheet and diagram exports, and `private/` are all gitignored so that
  a vault file dropped here by accident cannot reach a commit. That is a safety net,
  not permission to put one there.
- **[STD-09] Code quality and annotation.** Comments and prose explain *why*, never
  *what*. Applies to Mermaid diagram source as much as to code.
- **[STD-10] Conventional commits.** Commit messages describe the documentation
  change and never quote the sensitive detail that was removed.
- **No em dashes**, in prose, docs, comments or commit messages. Use a period, colon,
  comma or parentheses.

## There are no quick commands

Nothing here builds, runs, serves or tests. There is no compose stack, no package
manifest and no entry point, and adding one would mean putting infrastructure code in
a repository whose entire purpose is not to hold any.

What you do instead:

- **Edit prose.** `docs/CASE_STUDY.md` is the working surface. `docs/source-pages/` is
  read-only history.
- **Keep the diagrams in sync.** The four Mermaid definitions live in
  `docs/diagrams/*.mmd`, which are canonical. The portfolio's `mermaid` embed takes
  diagram text rather than a path, so `project.yaml` carries an inlined copy of each.
  Edit the `.mmd` first, then run `bash scripts/check-diagram-drift.sh` to find what
  needs pasting. See `PROJECT_NOTES.md` §5.
- **Re-verify sanitisation.** Before anything is published, walk every number, name
  and topology detail against the rules above. Do this at publish time. Do not assume
  a detail is safe because it already appears in `source-pages/`.
- **Check claims.** Every figure should be traceable to something real, or removed.
  See `PROJECT_NOTES.md` §2.

Run the checks before you commit:

```
bash scripts/check-sanitisation.sh
bash scripts/check-diagram-drift.sh
python scripts/check-project-yaml.py     # needs pyyaml
```

The sanitisation guard is blocking in CI. **If it fires on something you believe is
safe, rewrite the text rather than loosening the pattern.** This repository describes
a design, not a device. Note its two blind spots, documented in the script header: it
never reads git history, and it cannot check the files that discuss its own rules.

## Plugging into the portfolio

`project.yaml` is the contract. The portfolio imports it at `/admin/import`, shows a
diff, and applies it: sections and embeds become rows, no redeploy.

- **This project has no demo**, and it will never have one. It leans entirely on prose
  sections, `mermaid` embeds and image embeds. That is a supported shape under the
  content contract, but it means the written material has to be better than it would
  need to be elsewhere.
- Do **not** fill in the `demo:` or `services:` blocks. The connector that would host a
  live container is not built, and here there would be nothing to host. They parse and
  are ignored.
- Validate locally with `python scripts/check-project-yaml.py` before importing. The
  importer reports every problem at once, each with its path:
  `sections[2].embeds[0].kind: unknown kind`.

## Things not to do

- **Do not copy anything out of the private vault into this repository.** Not a config
  excerpt, not a table, not a diagram export, not "just the sanitised bits" of a file
  that also contains unsanitised bits. Rewrite from understanding instead of
  transcribing. This is the first rule and the one that costs most if broken, because
  a commit is public permanently and a network takes weeks to re-address.
- Do not add IPs, subnets, VLAN numbers, hostnames or exploitable model numbers, even
  in a diagram, even in a code comment, even as a placeholder you intend to scrub
  later.
- Do not add infrastructure code here to make the project look more substantial. If a
  sanitised extract of the ETL is wanted, that is a deliberate decision with its own
  scrubbing pass, see `PROJECT_NOTES.md` §1, not something to slip in.
- Do not "fix" the narrative by editing `docs/source-pages/`. Fix `docs/CASE_STUDY.md`
  and `project.yaml`, which are what actually get published.
- Do not restate an unverifiable figure just because it appears on an existing page.
  `99.9% uptime` is the current example.
