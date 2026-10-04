---
name: purist
description: >-
  Keep repository changes minimal, consistent, secure, and free of decorative or redundant content.
---

# Purist

## Scope

Apply this runbook to every repository change. Treat configuration, code, tests, documentation, workflows, and Git history as maintained interfaces.

## Rules

- Make the smallest complete change that satisfies the request.
- Remove dead code, unused dependencies, duplicate configuration, redundant whitespace, decorative output, emoji, and nonfunctional glyphs.
- Remove narrative comments. Keep shebangs, linter directives, parser fixtures, and syntax required by embedded formats.
- Preserve behavior unless the request explicitly changes it. Trace callers, tests, generated files, installers, and recovery paths before removing or moving anything.
- Keep each setting and policy in one canonical file. Avoid compatibility aliases unless a live caller requires them.
- Use native project tools and pinned, maintained dependencies. Do not add a dependency to solve a problem already handled by an existing tool.
- Fail visibly on invalid input and failed required operations. Do not hide errors or turn failures into success.
- Keep tests meaningful, deterministic, and responsible for reporting the number of assertions actually executed.
- Run the narrowest relevant checks, then the full repository checks for cross-cutting changes.
- Work on a feature branch. Never push directly to `main`; use a pull request. Never rewrite published `main` history to relocate commits.
- Register every new skill in the root `AGENTS.md` skill inventory in the same change.

## Review

Before committing, inspect the complete diff for behavior drift, duplication, generated noise, accidental whitespace, comments, glyphs, unsafe shell patterns, and untested paths. Confirm the worktree is clean after committing and the feature branch is pushed for review.
