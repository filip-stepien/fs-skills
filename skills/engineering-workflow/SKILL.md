---
name: engineering-workflow
description: Start and coordinate software engineering tasks by discovering project rules and context, selecting relevant fs-skills, keeping scope focused, verifying changes, and reporting results. Use for new projects, features, bug fixes, refactors, architecture work, reviews, and performance changes.
---

# Engineering workflow

Use this skill as the entry point for engineering work. Coordinate specialist skills; do not repeat their technical guidance. Load only the skills that apply to the actual task.

## Work through the task

1. **Understand:** identify the requested outcome, exclusions, affected code, and risk.
2. **Discover:** read active agent instructions; check relevant `.fs-skills/` context, nearby implementations, tests, and docs as needed. Read only what the task requires.
3. **Select skills:** use the routing table below as guidance, not a checklist. A task may need one specialist or several.
4. **Decide:** choose the smallest coherent solution that preserves established conventions. Before adding an abstraction, inspect existing patterns and consider whether a familiar established pattern expresses the responsibility clearly. For new projects, decide architecture before creating directories.
5. **Implement:** keep changes focused. Reuse suitable project patterns; avoid unrelated cleanup, new dependencies, and speculative abstractions.
6. **Verify:** run proportionate checks using existing project tooling and user-authorized scope. Never claim checks passed if they were not run.
7. **Report:** summarize the change, important decisions, checks performed, and material limitations.

## Route to specialist skills

| Task | Skills to consider |
| --- | --- |
| New project | `software-architecture`, relevant stack skills, `testing` for test strategy |
| New feature | Relevant architecture and technology skills; `clean-code`; `testing` and `documentation` when behavior or knowledge warrants them |
| Business rule or use case | `software-architecture`, `clean-code`, `typescript`, `testing` |
| Bug fix | Relevant technology skill and `testing` |
| Refactor | `clean-code`, relevant technology skill, `software-architecture` if boundaries change, `testing` to protect behavior |
| React UI | `react`; `typescript` for contracts; `testing` when interaction/state behavior matters |
| Next.js | `nextjs`; add `react` or `typescript` when relevant |
| Architecture decision or review | `software-architecture`, `clean-code` |
| Test creation or review | `testing` |
| Documentation creation, update, or audit | `documentation` |
| Performance work | Relevant technology skill; measure or establish the bottleneck first |
| Configure or reconfigure project engineering preferences | `configure` only when explicitly invoked by the user |

Do not load every skill, infer routing from file extensions alone, or use a specialist as a reason to ignore an explicit user constraint. If the user excludes tests, docs, refactoring, or other work, respect that choice and mention a significant risk only when useful.

## Respect project context and ownership

- Existing project conventions take precedence over generic defaults unless they create a material correctness, security, or maintainability problem.
- Treat `.fs-skills/` as durable, project-specific, version-controlled context by default so decisions travel across sessions, clones, agents, and teammates. Load only relevant parts, verify claims against code when affected, and update durable decisions incrementally. Keep it concise and shareable: no secrets, secret environment values, personal notes, machine-specific absolute paths, scratchpads, transcripts, generated artifacts, or temporary task progress. Do not duplicate human-facing explanations from `README.md` or `docs/`; link to useful documentation where appropriate. Do not add it to `.gitignore` by default; if an existing ignore rule blocks it, use `configure` guidance and get authorization before changing project ignore files. Never change global excludes automatically.
- Read accepted preferences in `.fs-skills/project.md` when relevant; apply their architecture, testing, and documentation defaults. A current-task request overrides a saved default, and a saved default is not a permanent prohibition. Do not repeat configuration questions already answered there.
- Keep temporary task progress out of durable context. Do not store secrets.
- Preserve `AGENTS.md`, `CLAUDE.md`, and equivalent user-owned instruction files. Never create or edit them automatically.
- Preserve unrelated working-tree changes. Do not overwrite or revert work outside the task.
- Version-controlled context does not authorize staging, committing, or pushing. Follow the Git authorization rules below.

## Apply checks proportionately

Consider tests for changed behavior, regression risk, and the real boundary being changed. Consider documentation when behavior, architecture, configuration, integration, or operational knowledge changes. Use `testing` and `documentation` for their detailed criteria; neither requires artificial work for trivial changes.

Run the relevant existing tests, type checks, lint, build, or focused integration checks when appropriate. State what was and was not run. If a needed check is unavailable or not authorized, report that limitation rather than implying success.

## Git conventions

- Use concise Conventional Commit subjects, for example `fix: prevent duplicate payment processing`.
- Follow a more specific repository convention when present.
- Never run `git commit` or `git push` without explicit authorization. Commit and push are separate permissions. Do not include unrelated changes or force-push without explicit authorization.

## Activation limits

Claude Code and Codex discover skills through their own mechanisms. Skill descriptions support model-selected activation; `/engineering-workflow` in Claude Code and `$engineering-workflow` in Codex are explicit entry points. This skill cannot guarantee that it activates or that another skill is loaded. A user may opt in to a short pointer in an existing active `CLAUDE.md` or `AGENTS.md` to improve consistency; use the platform-specific snippets in `integrations/` and obtain the owner's consent before changing those files. No hooks are installed by fs-skills.
