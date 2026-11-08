# Persistent project context example

This is shareable project context and should normally be version-controlled with the repository. Only create files that are useful in the adopting repository. Keep this information project-specific and review it when code changes invalidate it. Never store secrets, machine-specific state, personal notes, or temporary task progress here.

Suggested `project.md`:

```md
# Project

- Purpose and domain:
- Runtime and deployment:
- Important constraints:
- Current architecture profile:
- Relevant architecture links:
```

Suggested `architecture/overview.md`:

```md
# Architecture overview

- Profile and rationale:
- Runtime entry points:
- Main modules and responsibilities:
- Key integration boundaries:
- Known trade-offs:
```

Suggested `architecture/dependency-rules.md`:

```md
# Dependency rules

- Allowed dependency direction:
- Public module APIs:
- Forbidden imports/cycles:
- Data ownership:
- Composition roots:
```

Record decisions in short files under `architecture/decisions/` only when a choice is durable and non-obvious. Temporary task state belongs in the agent's active task/session, not here. Never put secrets in this directory.
