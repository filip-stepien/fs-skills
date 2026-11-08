# fs-skills

Portable engineering skills and a lightweight workflow for coding agents. The shared source of truth is `skills/`: each skill follows the Agent Skills `SKILL.md` format and contains no agent-specific commands or APIs.

## v1 support

| Environment | Skill discovery | Workflow activation | Installation status |
| --- | --- | --- | --- |
| Claude Code | Project `.claude/skills/` or user `~/.claude/skills/`; descriptions support model-selected use and `/skill-name` explicit invocation. The Claude plugin packages the same shared folders. | The model may select specialists directly or miss the coordinator. Use `/engineering-workflow` for explicit invocation or opt into the routing pointer below. | Native project/user skill installs and Claude marketplace plugin are available. |
| OpenAI Codex | Project `.agents/skills/` or user `~/.agents/skills/`; skills are supported in CLI and IDE extension. Descriptions support implicit selection and `$skill-name` explicit invocation. | The model may select specialists directly or miss the coordinator. Use `$engineering-workflow` for explicit invocation or opt into the routing pointer below. | Installer copies shared folders to native project/user skill locations. This repository does not package a Codex plugin. |

Support here means the format and native skill locations are implemented. A read-only smoke task ran in Codex CLI 0.166.0 and selected specialist skills but skipped `engineering-workflow`; Claude Code 2.1.318 listed the installed skills but could not complete a model request because no API credential was configured. See [platform notes](references/platforms.md) for the evidence and limitations. This v1 does not include Cursor, Gemini CLI, or other adapters.

## Install

Clone/download this repository, then run one command from its root. Review the scripts before execution as you would any third-party installer.

**Claude Code, project scope** (only this repository):

```sh
sh integrations/claude-code/install.sh project
```

**Claude Code, marketplace/plugin install** (user scope, with marketplace-managed updates):

```text
claude plugin marketplace add filip-stepien/fs-skills
claude plugin install fs-skills@fs-skills
```

To install the plugin for one project, use `claude plugin install fs-skills@fs-skills --scope project` as an alternative project-scoped install. Plugin-provided skill names are namespaced, for example `/fs-skills:engineering-workflow`.

**Claude Code, user scope** (all projects):

```sh
sh integrations/claude-code/install.sh user
```

**Codex, project scope**:

```sh
sh integrations/codex/install.sh project
```

**Codex, user scope**:

```sh
sh integrations/codex/install.sh user
```

PowerShell alternatives are provided as `install.ps1`. Use `-Scope Project` or `-Scope User`. Project install targets `.claude/skills/` or `.agents/skills/` under the current working directory. User install targets `~/.claude/skills/` or `~/.agents/skills/`.

Installers update only skill directories named by this repository. They do not create, overwrite, or edit `AGENTS.md`, `CLAUDE.md`, or other agent instruction files. Matching files in a same-named installed skill directory may be replaced; unrelated files are left in place. Re-run the installer to update skills.

To remove a direct install, delete the fs-skills directories from that install's `.claude/skills/`, `~/.claude/skills/`, `.agents/skills/`, or `~/.agents/skills/` location. To remove the Claude marketplace plugin, use Claude Code's `/plugin` browser. Codex plugins are available in the Codex CLI and ChatGPT desktop app, but this repository currently distributes Codex skills through native folders; the Codex IDE extension does not support plugins.

## How activation works

The Agent Skills format standardizes skill packaging and descriptive metadata, not a universal dispatcher or enforcement policy. Claude Code and Codex expose available skill descriptions to the model, which decides whether a task matches. Specialist skills can be selected directly without the coordinator, and a relevant skill can be missed. Explicit entry points are `/engineering-workflow` (Claude direct install), `/fs-skills:engineering-workflow` (Claude plugin), and `$engineering-workflow` (Codex).

### Optional workflow routing pointer

For more consistent coordinator use, a project or user may opt in to a short always-loaded instruction pointer. Review and append the matching snippet to the existing effective instruction file:

- Claude Code: [workflow pointer](integrations/claude-code/workflow-pointer.md) in an existing project `CLAUDE.md` or `~/.claude/CLAUDE.md`.
- Codex: [workflow pointer](integrations/codex/workflow-pointer.md) in an existing project `AGENTS.md` or `~/.codex/AGENTS.md` (account for an active `AGENTS.override.md`).

These files are user-owned; fs-skills installers never create or modify them. The pointers request coordinator activation but remain model-followed instructions, not hard enforcement. Remove the marked pointer block to uninstall it.

Claude Code and Codex also support native lifecycle hooks, but fs-skills installs none. A prompt hook could inject a reminder on every turn, yet it adds execution/context overhead, needs platform-specific configuration and trust, and still cannot guarantee the skill's instructions are followed. The skills and optional instruction pointer work without hooks. See [platform notes](references/platforms.md) for current event/configuration details and limitations.

### Verify discovery and troubleshoot

- Start a fresh session after installation. In Claude Code, confirm the skills appear as slash commands and try `/engineering-workflow` or `/configure` explicitly. Plugin-installed commands are namespaced, for example `/fs-skills:configure`.
- In Codex, use `$engineering-workflow` or `$configure` explicitly to verify invocation. For implicit routing, use a representative prompt without naming skills and review the session evidence where the installed surface exposes it.
- If a skill is missing, check the native directory, frontmatter `name`/`description`, and whether the session needs restarting. For Codex plugins, remember they are not available in the IDE extension; direct `.agents/skills/` installation is.
- If a specialist is selected but the coordinator is skipped, add the optional pointer to the active instruction file or invoke the coordinator explicitly. One successful activation is not a guarantee for future prompts.

## Skills and how they fit together

| Skill | Owns | Detailed examples |
| --- | --- | --- |
| `engineering-workflow` | Project discovery, task classification, skill routing, proportional planning, review, validation, and durable `.fs-skills/` updates | It routes a Next.js feature through architecture, TypeScript, React, and clean-code guidance as applicable. |
| `configure` | Explicit interactive setup or reconfiguration of project architecture, testing, and documentation preferences | Establishes decisions from repository evidence and saves accepted choices in `.fs-skills/project.md`; does not scaffold or migrate application code. |
| `testing` | Behavior-focused test strategy, readable scenarios, test doubles, reusable infrastructure, determinism, edge cases, and test-level selection | [Scenario design and test doubles](skills/testing/references/scenario-design-and-test-doubles.md) and [behavior, edge cases, and test levels](skills/testing/references/behavior-and-test-levels.md) give practical examples. |
| `documentation` | Concept-first explanations, scope selection, operational caveats, documentation audits, and freshness checks | [Writing guidance and worked examples](skills/documentation/references/writing-and-scope.md) explain scope; [examples](skills/documentation/references/examples.md) show good/bad docs, payment lifecycle, caveats, updates, and architecture. |
| `software-architecture` | Architecture profile selection, feature ownership, layer boundaries, dependency direction, public APIs, and architecture evolution | [Profile and boundary examples](skills/software-architecture/references/profiles-and-boundaries.md) compare simple, feature-based, and modular Hexagonal structures. |
| `clean-code` | SOLID decisions, cohesion, naming, function responsibilities, refactoring, testability, and avoiding needless abstractions | [Before/after refactoring examples](skills/clean-code/references/solid-and-refactoring.md) cover each SOLID principle and common smells. |
| `react` | Component responsibility/composition, hooks, props, state, effects, forms, accessibility, and measured rendering optimization | [Practical React patterns](skills/react/references/practical-patterns.md) includes component refactors, hook choices, derived state, forms, and performance. |
| `typescript` | Types/contracts, Result/error models, validation, narrowing, exhaustive handling, and persistence mapping | [Contracts and validation examples](skills/typescript/references/contracts-results-validation.md) builds a membership contract and error flow. |
| `nextjs` | Feature architecture integrated with App Router, Server Actions, server queries, auth boundaries, and adapters | [Organization settings vertical slice](skills/nextjs/references/organizations-vertical-slice.md) traces one feature from domain through persistence and UI. |

The shared architectural preference is feature ownership with explicit boundaries when business complexity warrants them. The examples draw on patterns demonstrated in the inspected `weekend.jobs.v2` and `trainer` projects, while keeping provider, deployment, and framework-version choices project-specific. A feature directory is not a reason to keep adding unrelated capability: split a feature when its behavior, data owner, lifecycle, or reason to change is distinct; expose cross-feature use through a public API.

Repeated implementation patterns in those projects include factory-created use cases with injected ports, runtime validation at server entry points, trusted actor identity from authentication, explicit Result outcomes for expected business failures, and provider-specific persistence kept behind adapters. `trainer` documents the layered feature boundaries more strictly; `weekend.jobs.v2` also demonstrates static import-boundary checks and practical parser-to-action flows. These are strong defaults for similarly complex features, not a mandate to add every layer to every screen. The TypeScript skill prefers `type`, follows an existing `interface` convention, and uses `interface` for a contract implemented by a class.

For a new project, explicitly invoke the workflow before creating folders. It selects the smallest fitting architecture profile, explains important trade-offs, then uses stack-specific skills. For an existing project, it reads relevant instructions and `.fs-skills/` context, traces the established code path, and preserves conventions unless there is a material correctness, security, or maintainability reason to change them.

### Configure project preferences

Invoke the configuration skill only when you want to establish or change project defaults. In Claude Code, use `/configure` for a direct install or `/fs-skills:configure` for the plugin. In Codex, use `$configure` (or select `configure` from `/skills` in supported surfaces). Claude Code marks this skill as user-invoked only in its skill frontmatter. The skill also includes Codex's native `agents/openai.yaml` policy to disable implicit invocation while retaining explicit `$configure` use.

The skill detects the existing stack, architecture, test and documentation tooling before asking about unresolved preferences. It records accepted decisions in `.fs-skills/project.md` and updates only selected decisions when reconfigured. This context is durable project knowledge and should normally be version-controlled; configuration does not generate a README, change ignore rules automatically, or modify agent instruction files, scaffold application code, or migrate architecture.

## Next.js technical references

The `nextjs` skill owns application architecture rather than reprinting framework documentation. It first resolves the Next.js version for the app being changed, then looks for that package's `dist/docs/` references. The [reference map](skills/nextjs/references/authoritative-docs.md) lists topics and package-relative paths verified in the source projects' Next.js 16.3.1 and 16.3.4 installations. If package-local docs are absent, it directs the agent to version-matched official docs and to state uncertainty when behavior cannot be verified.

## Example usage

- “Add organization invitations” → with the coordinator active, it checks whether invitations belong to the existing organization capability or represent a distinct feature, then routes boundaries to `software-architecture`, contracts/errors to `typescript`, UI to `react`, and App Router integration to `nextjs`.
- “Fix the project search bug” → it traces the existing route/component/query path, loads relevant context and skills, makes the smallest fix, and runs the project's appropriate validation.
- “Start a small marketing site” → architecture chooses a simple profile rather than adding repositories and ports without business rules or external boundaries.
- “Review a role-change feature” → architecture and clean-code check ownership/dependency risks, TypeScript checks contracts and exhaustive errors, and Next.js checks auth/action/query boundaries and versioned framework behavior.

## Workflow

The coordinator skill covers new project initialization, feature work, bug fixes, refactoring, architecture changes, reviews, and performance work:

1. Discover applicable instructions and relevant cached project context.
2. Classify scope and risk; select relevant skills based on stack and task.
3. Plan proportionately (new projects make architecture choices before directories).
4. Implement while preserving conventions and boundaries.
5. Identify meaningful behavior scenarios and add appropriate tests alongside implementation; skip artificial tests for trivial changes.
6. Check documentation impact for meaningful behavior, architecture, configuration, integration, security, and operations changes; update only affected explanations.
7. Review code, tests, and documentation against applicable checklists.
8. Validate with appropriate existing checks and report what ran.
9. Persist only durable project context changes.

When `engineering-workflow` is activated, it routes explicit test creation/review to `testing` and documentation tasks/audits to `documentation`. For meaningful changes it considers both without requiring separate user invocation. Trivial changes do not require artificial tests or documentation edits that add no useful knowledge. Without the optional always-loaded pointer, coordinator activation remains model-dependent.

The workflow doesn't require a specific agent tool/API. Each environment can use its native editing, shell, validation, and skill-loading mechanisms.

## Persistent project context

Repositories adopting fs-skills may keep project-specific decisions in `.fs-skills/`. It is separate from agent memory and portable between agents. Start with only relevant files, for example:

```text
.fs-skills/
├── project.md
├── architecture/
│   ├── overview.md
│   ├── dependency-rules.md
│   ├── module-map.md
│   └── decisions/
└── conventions/
```

This is an optional shape, not a scaffold requirement. Create files as useful. `.fs-skills/` is shareable, version-controlled project context by default. Store concise durable project facts and decisions, not generic principles or temporary task notes. Read only context relevant to a task, verify it against code when the affected area changes, and update incrementally. Do not store credentials, secrets, personal notes, machine-specific paths, or scratch data. Preserve user-authored documentation; if a context file conflicts with implementation, investigate and reconcile deliberately. Do not automatically add this directory to `.gitignore` or stage/commit it.

## New projects

Invoke the workflow before scaffolding. Capture requirements/domain, stack/runtime, deployment, constraints, and likely change axes; choose the smallest justified profile: simple application, lightweight feature-based app, modular monolith, domain-heavy Clean/Hexagonal, or monorepo. Then define module responsibilities, dependency direction, public APIs, composition roots, directory structure, and an appropriate testing strategy using available tooling. Explain consequential trade-offs. Record durable decisions in `.fs-skills/` and scaffold only the chosen structure. Do not add ports, repositories, layers, test frameworks, or packages without a concrete need.

## Extend

Add a directory under `skills/<skill-name>/` with one `SKILL.md` whose frontmatter `name` matches its directory and whose description explains scope and activation cues. Keep the body concise and actionable; move deeper guidance to skill-local `references/`. Use MUST for invariants, SHOULD for strong defaults, and CONSIDER for contextual choices. Keep shared engineering guidance agent-neutral. Add a new adapter only for verified native discovery/activation/installation differences; do not fork the skill content.

## Known limitations

- Skill auto-selection and coordinator routing are model-driven and can miss a relevant skill; explicit invocation is available, and the optional pointer improves consistency without enforcing behavior.
- There is no universal skill installation/update command. v1 offers small copy installers and a Claude-native marketplace plugin; Codex installs directly into its native skill directory.
- Installers copy files; they do not link to the source or auto-update.
- Codex project skills are not in the same directory as Claude project skills.
- Hooks are available in both platforms but are not installed; users must review and trust any hook implementation they configure.
- Existing instruction files remain untouched; adding/removing the optional marked pointer is a user action.
- Claude model-selected activation could not be tested here without an API credential. Codex runtime evidence is limited to the single smoke scenario documented in [integration notes](references/platforms.md).


