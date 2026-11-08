---
name: configure
description: Interactively establish or change a project's engineering preferences, including architecture, testing, and documentation policy. Use only when the user explicitly asks to configure or reconfigure project conventions; do not start this workflow during ordinary engineering work.
disable-model-invocation: true
---

# Configure project engineering preferences

Use this skill only after explicit user invocation. Discover the repository and record accepted project decisions; this is not a project generator or architecture migration. Reuse [software-architecture](../software-architecture/SKILL.md), [testing](../testing/SKILL.md), [documentation](../documentation/SKILL.md), and relevant stack skills as the source of detailed guidance.

## Discover before asking

1. Identify the project root and whether this is a new or established project.
2. Read applicable `AGENTS.md`, `CLAUDE.md`, and equivalent instructions without changing them. Read existing `.fs-skills/` context, especially `project.md`, and relevant architecture decisions.
3. Inspect manifests and framework/tool configuration to identify the real stack, test runner, documentation system, and quality tooling.
4. For an established project, inspect representative source imports and dependencies, tests, and docs. Treat directory names as clues, not proof of architecture.
5. Separate existing facts and accepted preferences from unresolved choices. Do not ask the user to repeat discoverable information.

## Establish or change decisions

Keep the conversation short and progressive. Summarize what is already known, then ask only about consequential unresolved decisions. Group related choices when that is easier. For each choice, explain the practical trade-off, recommend a default based on repository evidence, and let the user decide. Recommendations are not requirements.

If a new or empty project has no stated purpose or constraints, ask one concise question covering its goal/domain, intended application type or stack, and any known deployment or integration constraints. Do not ask again for details already present in the request or files.

- **Architecture:** consult `software-architecture` for its current profiles and criteria. For a new project, recommend a profile from requirements, capabilities, complexity, integrations, and constraints; briefly compare suitable options and their likely structure. For an established project, identify and preserve the architecture already demonstrated by code. Do not silently migrate it. Discuss initial business capabilities only when requirements support them; do not scaffold modules.
- **Testing policy:** inspect current tools and conventions, then establish the default: tests for meaningful behavior, tests on demand, or no automatic new tests. These are project preferences, not permanent prohibitions: follow a later explicit task request. Do not install or replace tools.
- **Documentation policy:** inspect existing documentation and its renderer, then establish continuous updates for meaningful changes, important decisions/constraints only, or documentation on demand. Follow `documentation` for writing quality; do not choose or install a renderer without a separate need.
- **Other conventions:** ask only if a consequential project decision is genuinely unresolved. Detect technologies and existing choices from files. Do not pre-decide hypothetical future dependencies, tools, directories, or implementation details.

Do not require a full questionnaire when reconfiguring. First show a concise summary of saved preferences and any relevant difference from current code, ask which setting(s) the user wants to change, then edit only those decisions. Changing a saved architecture preference does not migrate code.

## Persist accepted decisions

Use `.fs-skills/project.md`, unless the project already has a suitable `.fs-skills/` context structure. Create only what is needed. Keep the profile concise and project-specific: actual stack, selected architecture and established boundaries, testing default, documentation default, and other decisions the user accepted. Record unknowns as unknown only when helpful; never infer consent from an agent recommendation.

When reconfiguring, update only the affected section and preserve unrelated user-authored context. Do not copy generic skill guidance or full architecture documentation into project context. Human-facing explanations belong in the project's existing documentation. Never store secrets, credentials, tokens, or private environment values.

Do not create, overwrite, or edit `AGENTS.md`, `CLAUDE.md`, or other user-owned agent instruction files. Do not generate application code/directories, install dependencies, add test/documentation tooling, introduce CI, or refactor the project as part of configuration.

## Keep project context shareable

Treat `.fs-skills/` as durable, project-specific engineering context that should normally be version-controlled. It lets the team and agents on fresh clones share accepted architecture, module boundaries, testing/documentation policies, and other lasting conventions. Store only shareable project decisions: no secrets, secret environment values, personal notes, absolute machine paths, scratchpads, transcripts, generated artifacts, or temporary task progress.

Do not add `.fs-skills/` to `.gitignore` as part of configuration. If the intended context path is already ignored, identify the source of the rule before proposing a fix. Use `git check-ignore -v` for the relevant path, then inspect the reported project `.gitignore` or nested ignore file, `.git/info/exclude`, or configured global excludes file as applicable.

- If no ignore rule applies, take no Gitignore action.
- If a project-local ignore rule applies, explain that durable context is intended to be shared and propose the smallest targeted edit. Modify the ignore file only after the user authorizes that edit; preserve unrelated rules and working-tree changes.
- Do not modify global Git configuration or global exclude files automatically. Explain the local-only effect and offer a repository-scoped correction only with authorization.
- Never stage or commit context automatically. Do not run `git rm --cached` or other destructive Git commands. Existing tracked files stay tracked.

If there is no Git repository, record the decisions normally; do not initialize Git. Report that version control was unavailable.

Configuration does not generate or rewrite README files or create documentation. If a separate project-initialization task requests a README, follow the `documentation` skill. Preserve an existing README unless the user requests a change or the task directly requires one. Do not create empty `docs/` folders or placeholder links.

## Finish

Summarize the detected stack and architecture, decisions established or changed, where they were recorded, and whether the context can be shared through Git. Mention any conflicting ignore rule or the absence of a Git repository when relevant. Do not imply that any application code or README was scaffolded, migrated, or rewritten.
