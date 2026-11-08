# Platform integration notes

Last checked: 2026-11-05. Platform capabilities change; use the linked official documentation for current product-surface and version details.

## Shared Agent Skills format

The [Agent Skills specification](https://agentskills.io/specification) standardizes the skill folder and `SKILL.md` metadata/resources. It does not define automatic routing, a mandatory coordinator, project instruction files, or enforcement. Claude Code and Codex both use the description as an input to model-selected activation, and both allow explicit invocation through their own interface.

`skills/` is the single source of engineering guidance in this repository. Installers copy these folders into each agent's native directory; they do not create separate platform-specific skill bodies or symlink for live updates. Re-run an installer to update copied skills.

## Claude Code

- **Native skill discovery:** project skills in `.claude/skills/<name>/SKILL.md`; user skills in `~/.claude/skills/<name>/SKILL.md`. Descriptions help Claude select skills automatically when relevant. Skill directories also become slash commands such as `/engineering-workflow`.
- **Explicit-only configure:** `configure` sets Claude Code's `disable-model-invocation: true` extension in frontmatter. Claude Code documents this as keeping the skill manually invocable while disabling automatic model invocation. Use `/configure` after a direct install or `/fs-skills:configure` through this plugin. Other Agent Skills hosts may ignore this Claude-specific field.
- **Project/user instructions:** `CLAUDE.md` can be project-level (`./CLAUDE.md` or `./.claude/CLAUDE.md`) or personal (`~/.claude/CLAUDE.md`). These files load as instructions at session start, but Claude treats them as guidance, not enforced configuration. Claude Code v2.1.277+ can read `AGENTS.md` if no applicable `CLAUDE.md` takes precedence; some product/provider sessions have limitations. Prefer editing the effective native instruction file only with the owner's consent.
- **Plugin packaging:** this repository has a Claude Code marketplace plugin. It packages the same root `skills/` directories, supports marketplace-managed updates, and namespaces explicit commands (for example, `/fs-skills:engineering-workflow`). Direct skill-folder installation remains available at project or user scope.
- **Hooks:** Claude Code supports lifecycle hooks from user/project settings and plugin `hooks/hooks.json`, including `UserPromptSubmit`, whose output can add context or block a prompt. Hooks are not required for skill discovery. This repository installs no hooks: injecting a reminder on every prompt adds execution/context cost and still does not guarantee that the model follows it or loads the coordinator. Hooks can run commands and should be reviewed as executable configuration.
- **Official references:** [Skills](https://code.claude.com/docs/en/skills), [memory and project instructions](https://code.claude.com/docs/en/memory), [hooks](https://code.claude.com/docs/en/hooks), [plugins](https://code.claude.com/docs/en/plugins).

## OpenAI Codex

- **Native skill discovery:** repo skills in `.agents/skills/<name>/SKILL.md`; user skills in `~/.agents/skills/<name>/SKILL.md`. Codex CLI and IDE extension support skills. The model may choose them implicitly by description; `$engineering-workflow` and `$configure` are explicit invocations in supported Codex surfaces. Start a new session after installation if a current session does not discover new skills.
- **Explicit-only configure:** the shared `configure` skill includes `agents/openai.yaml` with `policy.allow_implicit_invocation: false`. Codex documents this as disabling implicit invocation while retaining explicit `$configure` invocation. This is Codex-specific metadata; other hosts can ignore it.
- **Project/user instructions:** Codex loads `AGENTS.md` guidance from `~/.codex/` and the project path. `AGENTS.override.md` takes precedence over `AGENTS.md` at the same level. Instructions are included as context but are not a hard enforcement layer. This repository never creates or edits those user-owned files.
- **Plugin packaging:** Codex plugins can package skills and are available through the Codex CLI plugin browser and the ChatGPT desktop app, but not the Codex IDE extension. This repository does not publish a Codex plugin; its native `.agents/skills/` installer covers project/user installs for CLI and IDE. Claude's plugin manifest is not a Codex plugin manifest.
- **Hooks:** Codex supports lifecycle hooks, including `SessionStart` and `UserPromptSubmit`, in user/project config and plugins on supported local surfaces. Non-managed hooks require review and trust; project hooks also depend on project trust. Hook availability differs for cloud-orchestrated surfaces. Hooks could inject a routing reminder but do not prove that a skill was followed. This repository installs no Codex hooks.
- **Official references:** [Skills and customization](https://learn.chatgpt.com/docs/customization/overview), [Codex skills](https://developers.openai.com/codex/skills), [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [hooks](https://learn.chatgpt.com/docs/hooks), [plugins](https://learn.chatgpt.com/docs/plugins).

## Skill activation model

1. **Automatic discovery/selection:** native skill metadata makes names and descriptions available; the model decides whether a skill matches. It can select a specialist without selecting `engineering-workflow`, or miss a relevant skill. This is not a guaranteed dispatcher.
2. **Explicit invocation:** use `/engineering-workflow` or `/configure` in a direct Claude install, `/fs-skills:engineering-workflow` or `/fs-skills:configure` through the Claude plugin, or `$engineering-workflow` / `$configure` in Codex. The configure skill is manual-only through native Claude Code frontmatter and Codex `agents/openai.yaml` policy.
3. **Persistent routing instruction:** optionally add the short pointer from the matching `integrations/<agent>/workflow-pointer.md` to an existing effective `CLAUDE.md` or `AGENTS.md`. This makes the request to load the coordinator available at startup. It still guides the model rather than enforcing behavior. Review the snippet and consent before editing; remove the marked block to uninstall it. The installers do not perform this edit.
4. **Hooks:** supported natively on both platforms, but not included. They would run at lifecycle points and may add context; they are not needed for skills to exist and do not guarantee complete workflow execution.

Do not treat plugin presence, skill availability, routing text, or a static routing table as proof of invocation. Verify discovery and behavior separately for the target agent and surface.

## Verification status in this repository

- **Structurally verified:** skill metadata validates; Claude and Codex copy installers put the shared skills in their native project directories; a temporary install smoke test confirmed both installers preserve existing `AGENTS.md` and `CLAUDE.md` files.
- **Claude Code 2.1.318 runtime:** a project-local session listed the eight fs-skills present at that time as available slash commands. The model request could not complete because the installed CLI reported `apiKeySource: none` and retried without an available credential. The new `configure` command and its manual-only behavior are documented/structurally configured but were not runtime-tested. Actual Claude model-selected activation remains unverified here.
- **Codex CLI 0.166.0 runtime:** a read-only React refactoring smoke task selected `react`, `clean-code`, and `typescript`; it did not select `engineering-workflow`. This confirms specialist model-selection in that session and exposes why an optional always-loaded instruction pointer can improve coordinator consistency. It does not prove consistent behavior across prompts, models, Codex IDE, plugins, or future versions.

When changing platform integrations, repeat the smoke test on the installed CLI/app and the intended product surface. Report structural validation, documentation-based expectations, and live runtime observations separately.
