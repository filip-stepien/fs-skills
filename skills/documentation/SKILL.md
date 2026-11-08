---
name: documentation
description: Explain system behavior, business concepts, constraints, operational knowledge, and design rationale; create, update, or audit project documentation when code changes affect what readers need to understand.
---

# Documentation

Write to transfer understanding, not to inventory implementation. Explain the concept before how the code realizes it. The reader should understand the system's behavior and important constraints before opening source files.

Use this skill when documenting or auditing a system, and consider it during meaningful feature, behavior, architecture, configuration, integration, security, or operations changes. Do not add documentation for trivial changes whose behavior and constraints are already clear.

## Document a system

1. Read the existing documentation and renderer conventions before creating a file. Inspect relevant code, configuration, tests, and operational settings; never invent states, limits, guarantees, or provider behavior.
2. Identify the reader's question and choose a scope: concept, feature, guide, architecture, operations, or reference. Create a new document only when the knowledge merits a separate place; otherwise improve the closest existing document.
3. Start with the problem and a useful mental model. Explain important scenarios, invariants, permissions, decisions, caveats, and failure recovery. Add implementation details only to connect the concept to authoritative code or configuration.
4. Use a concrete scenario, decision table, or conceptual Mermaid diagram when it makes behavior easier to grasp. Keep deeper technical details and reference material available without leading with them.
5. Link consequential claims to the relevant project documentation or source/configuration. Distinguish verified project facts from illustrative examples and unverified assumptions.
6. Review for reader understanding, caveat visibility, duplication, correctness, and freshness. Check links and examples affected by the change.

Read [writing and scope guidance](references/writing-and-scope.md) when choosing a document type, shaping an explanation, or recording caveats. Read [worked examples](references/examples.md) for concept-first rewrites, payment lifecycle, configuration caveats, targeted updates, and architecture documentation.

## Root README: project entry point

Treat a root `README.md` as a concise entry point, not an implementation inventory. It should answer what the project is for, how to start using or developing it, and where to find deeper documentation when it exists. Include only verified prerequisites, setup requirements, and commands needed by the intended reader. For a package or tool, retain the essential install/use instructions that make it usable.

Do not generate a file tree, feature or technology inventory, generic badges, or boilerplate sections by default. Every section must help the reader or satisfy an explicit request. Put concepts, workflows, architecture rationale, and operational details in existing deeper documentation, then link to them from the README only when those documents exist. Minimal means focused, not incomplete.

When editing an existing README, preserve accurate and useful content, essential setup instructions, and security/operational warnings. Make a targeted change; do not regenerate the whole file or restructure it for style alone. Verify the actual package manager, scripts, prerequisites, and links before adding instructions. Do not create empty `docs/` folders or placeholder links.

Illustrative shape only; verify real project commands before using them:

```md
# Booking App

An application for managing room reservations across multiple locations.

## Development

npm install
npm run dev
```

Use the detailed concept-first writing guidance below for deeper documents; a README should point to those explanations instead of repeating them.

## Keep documentation current

As part of implementation, compare relevant docs with the changed behavior. Update only claims that became inaccurate or knowledge that was added: business rules, transitions, constraints, decisions, configuration, integrations, operational recovery, guides, or examples. Preserve good explanations; do not regenerate a technical inventory or create a document just to mention the code change.

For a documentation audit, discover current docs, trace their claims to actual behavior/configuration, and prioritize gaps by impact, difficulty of discovery, and likelihood of future use. Recommend what to clarify, correct, consolidate, or remove; do not aim to document every file or feature.

## Keep human docs distinct from project context

Human-facing docs explain concepts, behavior, guides, operations, architecture, and references. `.fs-skills/` stores concise project context for agents, such as boundaries, conventions, and durable decisions. Link between them where useful; do not maintain competing copies. Preserve existing docs and user-owned instruction files. Never create or edit `AGENTS.md` or `CLAUDE.md` automatically.

## Done when

- A reader can understand the concept and important behavior without first reading the implementation.
- Important constraints and failure scenarios are easy to find and are supported by project evidence.
- The document's scope matches the reader's question, and implementation details serve the explanation.
- Existing documents and examples affected by the change are accurate, links work, and nothing is duplicated unnecessarily.
