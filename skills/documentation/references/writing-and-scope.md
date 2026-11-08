# Writing and scope

Use this guide when creating or restructuring project documentation. Follow the project's existing renderer, navigation, terminology, and language conventions where they work.

## Keep the root README focused

The root README is the reader's entry point. In a few lines, explain what problem the project solves, give the verified first-use/development path, and link to deeper docs that actually exist. Include real prerequisites and setup caveats, especially when they block a clean start. For a library or tool, include enough verified usage to get value from it.

Do not default to a source tree, technology list, feature catalog, badges, roadmap, contribution/deployment/FAQ boilerplate, or architecture inferred from folder names. Add such material only when it answers a real reader question or was explicitly requested. Keep deeper mental models, workflows, business rules, architecture rationale, and operational caveats in the appropriate docs rather than duplicating them in the README.

For an existing README, preserve valuable and accurate setup, security, and operational guidance. Edit only what the task requires; minimal is not a reason to delete useful information or rewrite the whole file. Verify commands, package manager, environment prerequisites, and destination links. Do not create empty documentation directories or placeholder links.

## Lead with the concept

Organize an explanation around what a reader needs to understand, in this order when useful:

1. **Context:** what problem or responsibility exists?
2. **Mental model:** what is the simplest accurate way to think about it?
3. **Behavior:** what happens in normal, boundary, and failure scenarios?
4. **Rules:** which invariants, permissions, and transitions must hold?
5. **Caveats:** what is surprising, risky, delayed, limited, or operationally important?
6. **Implementation overview:** which boundaries realize the behavior?
7. **Reference:** where can a reader find exact contracts, keys, or parameters?

Do not force headings for every step. The sequence is a guide: explain the idea before its code, and introduce technical detail only when it answers a reader's question. Keep the opening short enough to give the reader a usable mental model; expand depth progressively with links, diagrams, and examples.

Prefer a scenario over a list of files. Explain why a payment cannot be marked complete from a browser form, what happens when an invitation is duplicated, or which permission a membership change requires. Source links should verify or locate the implementation after the explanation.

When referring to a repository file, prefer a descriptive Markdown link over an inline code path. Use a relative link so the document remains portable. For example, replace the target in this pattern with the verified path:

```md
[Membership authorization](relative/path/to/file.ts)
```

Keep a path inline only when the literal path itself is important, such as when documenting a command, configuration value, or filesystem location. Use link text that tells the reader what they will find; avoid bare paths and generic labels such as “here.”

## Choose scope by the question

| Reader's question | Useful scope | Include |
| --- | --- | --- |
| “How does this mechanism work across the product?” | Concept | Mental model, behavior, invariants, actors/events, failure cases |
| “What can a user do, and what rules apply?” | Feature | User goal, business rules, important scenarios, permissions, limits |
| “How do I perform or change this task?” | Guide | Preconditions, steps, verification, recovery, links to related concepts |
| “Why are boundaries/dependencies arranged this way?” | Architecture | System responsibilities, allowed relationships, rationale, trade-offs, decisions |
| “How do I operate or troubleshoot this?” | Operations | Symptoms, likely causes, monitoring, recovery, configuration, risks |
| “What exact shape/value/parameter is accepted?” | Reference | Schema, event fields, config keys, API contract, units and defaults |

These scopes can link to each other; they do not require one document per feature or a fixed folder tree. Create only the useful category folders for the project. Titles should use reader language, such as “How payments settle” or “Recovering a delayed webhook,” rather than class names. Keep exact technical inventories in reference material and avoid letting them dominate the concept explanation.

## Make caveats useful

For each material caveat, explain as much of this as applies:

- **Constraint:** what is limited or assumed? Give a measured value only if verified.
- **Reason:** what safety, provider, product, or resource concern causes it?
- **Effect:** what does a user/operator/system observe when it is reached or violated?
- **Control:** where is the authoritative configuration or policy, and how can an authorized change be made?
- **Consequences:** what behavior, cost, security property, data, or downstream system might change?
- **Recovery:** how can the failure be detected, retried, reconciled, or safely escalated?

Keep security assumptions, transaction/concurrency scope, idempotency, retry/timeout policy, permissions, feature flags, delayed consistency, migrations, and external-service limitations near the behavior they affect. Do not bury a dangerous caveat in an API table. Verify operational claims against code, configuration, dashboards/runbooks, or provider documentation. Say when a fact is unknown instead of guessing.

## Explain decisions without duplicating records

Explain a choice when it affects future behavior or change cost: what pressure led to it, what was chosen, and what trade-off follows. Use an ADR for a consequential architecture decision when the project already uses ADRs or the decision warrants a durable record. The concept or guide should summarize the decision in reader-facing terms and link to the ADR; do not copy the ADR into multiple documents.

Keep human documentation separate from `.fs-skills/` project context. Human docs help developers and operators understand the system. `.fs-skills/` helps agents quickly locate project boundaries, conventions, and durable decisions. A concise summary may link to a fuller concept page, but neither should be a stale competing source of truth.

## Use diagrams deliberately

Use a state diagram for permitted transitions, a sequence diagram for responsibility over time, or a dependency diagram for conceptual boundaries. Mermaid is useful when the renderer supports it. Diagram the few important actors and rules; do not draw every class, function, or directory. Pair the diagram with a sentence that explains what the reader should notice.

## Readability review

- Does the opening state the problem and mental model plainly?
- Can the reader follow a realistic scenario before learning implementation terminology?
- Are rules, permissions, transitions, caveats, and failure recovery explicit where relevant?
- Does every implementation detail help explain behavior or lead to its authoritative source?
- Are repository files linked with descriptive Markdown links instead of inline path text where possible?
- Is the document organized for a reader question rather than a source tree?
- Are facts verified, examples clearly labeled, and exact values traceable?
- Is the document concise, non-repetitive, and linked to deeper material only when useful?
- Can a maintainer find where to change or troubleshoot the behavior?
