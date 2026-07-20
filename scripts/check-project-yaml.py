#!/usr/bin/env python3
"""Validate project.yaml against the portfolio's import contract.

The importer at /admin/import is the authority and reports every problem at once.
This reproduces its rules locally so a typo costs a second rather than a round trip
through the admin UI. When the two disagree, the importer is right and this file is
stale: fix it here and say so in the commit.

Contract: luke-udell-portfolio/docs/contracts/project-config-handoff.md (v1.1)
Usage: python scripts/check-project-yaml.py [path]
"""

import re
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

# Unknown keys are errors in the importer, not warnings. A key that imports cleanly
# and silently does nothing is the failure mode the contract calls worst, so these
# sets are exhaustive rather than permissive.
TOP_LEVEL = {
    "contract_version", "slug", "title", "summary", "repo_url",
    "published", "tags", "sections",
    # Parsed and ignored: the connector that would host a live container is not
    # built. Midgard will never fill these, but they are not rejections.
    "demo", "services",
}
TOP_REQUIRED = {"contract_version", "slug", "title", "summary", "sections"}
SECTION_KEYS = {"slug", "title", "published", "body", "embeds"}
SECTION_REQUIRED = {"slug", "title"}
EMBED_KEYS = {"kind", "title", "source", "aspect_ratio", "fallback_url"}
EMBED_REQUIRED = {"kind", "title", "source"}
EMBED_KINDS = {"plugin_demo", "metabase_report", "external_app", "video", "image", "mermaid"}
FRAMED_KINDS = {"plugin_demo", "metabase_report", "external_app"}

SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

errors = []


def err(path, msg):
    errors.append(f"{path}: {msg}")


def check_slug(value, path):
    if not isinstance(value, str) or not SLUG_RE.match(value):
        err(path, "slug must be lowercase, alphanumeric, with internal hyphens only")
    elif len(value) > 40:
        err(path, f"slug must be 40 characters or fewer (got {len(value)})")


def main(path="project.yaml"):
    try:
        with open(path, encoding="utf-8") as fh:
            doc = yaml.safe_load(fh)
    except FileNotFoundError:
        sys.exit(f"{path} not found")
    except yaml.YAMLError as exc:
        sys.exit(f"{path} is not valid YAML: {exc}")

    if not isinstance(doc, dict):
        sys.exit(f"{path} must be a mapping at the top level")

    for key in sorted(set(doc) - TOP_LEVEL):
        err(key, "unknown key")
    for key in sorted(TOP_REQUIRED - set(doc)):
        err(key, "required")

    version = str(doc.get("contract_version", ""))
    if version and not version.startswith("1."):
        err("contract_version", f"must be 1.x (got {version!r})")

    if "slug" in doc:
        check_slug(doc["slug"], "slug")

    repo_url = doc.get("repo_url")
    if repo_url is not None and not str(repo_url).startswith("https://"):
        err("repo_url", "must be an https:// URL")

    sections = doc.get("sections")
    if not isinstance(sections, list) or not sections:
        err("sections", "required, at least one section")
        return report()

    # published defaults to FALSE on a section, so an all-default file imports as an
    # invisible project. The contract rejects that rather than publishing nothing.
    if not any(s.get("published") is True for s in sections if isinstance(s, dict)):
        err("sections", "at least one section must have published: true")

    seen = {}
    for i, section in enumerate(sections):
        p = f"sections[{i}]"
        if not isinstance(section, dict):
            err(p, "must be a mapping")
            continue

        for key in sorted(set(section) - SECTION_KEYS):
            err(f"{p}.{key}", "unknown key")
        for key in sorted(SECTION_REQUIRED - set(section)):
            err(f"{p}.{key}", "required")

        slug = section.get("slug")
        if slug is not None:
            check_slug(slug, f"{p}.slug")
            if slug in seen:
                err(f"{p}.slug", f"duplicate of sections[{seen[slug]}].slug ({slug!r})")
            else:
                seen[slug] = i

        for j, embed in enumerate(section.get("embeds") or []):
            ep = f"{p}.embeds[{j}]"
            if not isinstance(embed, dict):
                err(ep, "must be a mapping")
                continue

            for key in sorted(set(embed) - EMBED_KEYS):
                err(f"{ep}.{key}", "unknown key")
            for key in sorted(EMBED_REQUIRED - set(embed)):
                err(f"{ep}.{key}", "required")

            kind = embed.get("kind")
            if kind is not None and kind not in EMBED_KINDS:
                err(f"{ep}.kind", f"unknown kind {kind!r}")

            source = embed.get("source")
            if kind in FRAMED_KINDS and not str(source or "").startswith("https://"):
                err(f"{ep}.source", f"a {kind} source must be an https:// URL")
            if kind == "image" and str(source or "").startswith(("http://", "https://")):
                err(f"{ep}.source", "image sources must be first-party paths, not remote URLs")
            if kind == "mermaid" and not str(source or "").strip():
                err(f"{ep}.source", "a mermaid source must be the diagram text")

    return report()


def report():
    if errors:
        print(f"{len(errors)} problem(s) in project.yaml:\n")
        for e in errors:
            print(f"    {e}")
        print("\nThe importer reports every problem at once. Fix them all, then re-run.")
        return 1
    print("Clean: project.yaml satisfies the import contract.")
    return 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
