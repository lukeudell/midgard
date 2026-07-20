# Agent instructions

**Read `@../CONTRIBUTING.md` first and treat it as binding.** It holds the one-way
vault boundary, the sanitisation rule, the standards and the workflow. It is written
for people, and none of it is relaxed for an agent. The boundary rule outranks
everything in this file.

@../CONTRIBUTING.md

---

The rest is specific to working here as an agent, and is not worth a human's time.

## Commits

- **No `Co-Authored-By` trailer and no "Generated with Claude Code" line** in this
  repository. Most of Luke's repos take the trailer and he wants them to. Midgard is
  one of a small set of originals separated out of `command_center` that stay solo.
- Conventional Commits, imperative subject, per [STD-10]. Describe the documentation
  change and never quote the sensitive detail that was removed.

## Prose

This repository is entirely prose, so writing quality is the deliverable rather than
a finish on top of one. Two things to run before presenting work:

- **No em dashes.** Mechanical and absolute, and the easiest rule to break while
  drafting. Period, colon, comma or parentheses instead.
- **Check against `udell-blueprints/reference/conventions/ai-tells.md`.** The tells
  that recur most here are the "X, not Y" antithesis, reflexive rule-of-three lists
  ("three things were decided..."), and aphoristic one-line section closers. Any
  single instance is fine. The density is the tell.

Do not invent a concrete detail to make prose land better. Wattage, latency figures,
incident anecdotes and uptime percentages are all unverifiable from inside this
repository, and the vault is off limits. If a number would help, ask for it.

## Layout

```
midgard/
├── CONTRIBUTING.md      the rules. Binding, read first
├── PROJECT_NOTES.md     honest assessment: what is missing, overclaimed, still open
├── README.md            short public-facing summary
├── project.yaml         how this appears on lukeudell.com
├── .gitignore           blocks .env, *.pdf, exports and private/. A net, not a licence
├── .github/workflows/   CI: sanitisation, import contract, diagram drift, links
├── scripts/
│   ├── check-sanitisation.sh    blocking; the one control before a published address
│   ├── check-project-yaml.py    project.yaml vs the portfolio import contract
│   └── check-diagram-drift.sh   .mmd files vs their inlined copies in project.yaml
└── docs/
    ├── CASE_STUDY.md    the sanitised narrative; source for project.yaml
    ├── diagrams/        Mermaid sources (.mmd). Canonical; project.yaml inlines copies
    └── source-pages/    the original five .astro pages, verbatim, read-only
```

## Why this file lives in `.claude/`

Claude Code auto-loads `.claude/CLAUDE.md` at the same priority as a root `CLAUDE.md`,
so nothing is lost by keeping it here. The root listing is the first thing a visitor
to a public repository sees, and the substantive rules belong in `CONTRIBUTING.md`
where a contributor will look for them. This file imports that one rather than
restating it, so there is one copy of the boundary rule and it cannot drift.
