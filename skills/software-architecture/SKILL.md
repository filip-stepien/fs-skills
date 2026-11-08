---
name: software-architecture
description: Select, recognize, or evolve application architecture; organize features and layers, set dependency rules, design public APIs, and choose composition boundaries. Use before scaffolding a project or when a feature/module boundary is unclear.
---

# Software architecture

Choose the smallest architecture that preserves clear ownership and handles demonstrated change. Decide boundaries before directories. Use the existing project architecture in place unless it creates a material correctness, security, or maintenance problem.

## Decide the profile

Use these profiles in increasing order of structure:

1. **Simple application** — a few cohesive routes and limited business policy. Start with routes, a small set of domain/data helpers where useful, and direct persistence calls at the server boundary. Add no ports or layers without a reason.
2. **Feature-based application** — several capabilities with distinct behavior or change ownership. Organize by feature, keep feature internals together, and expose small public APIs. Add only the layers a feature needs.
3. **Modular monolith with Hexagonal boundaries** — substantial business rules, persistence/provider changes, security-sensitive use cases, or multiple contributors justify explicit domain, application, infrastructure, and UI boundaries. Keep one deployable application unless independent deployment is a real requirement.

Use the detailed profile comparison and folder examples in [profiles-and-boundaries.md](references/profiles-and-boundaries.md). A full directory tree is a menu of possible responsibilities, not a scaffold checklist. Create a directory only when it will contain a real responsibility.

Prefer a familiar pattern when it names a real responsibility more clearly than a project-specific abstraction. Consult [recognizable patterns](references/recognizable-patterns.md) for repository, ports/adapters, provider/gateway, strategy, factory, composition root, and facade decisions. Patterns are options, not a checklist: keep direct code when it is clearer, and do not add a layer, interface, or class just to match a pattern diagram.

Before choosing, capture the business capabilities, important rules, actor/permissions, data ownership, external systems, runtime/deployment constraints, and credible change axes. State which evidence justifies each boundary. Reuse a working profile for small changes rather than redesigning the system.

## Recognize and preserve an existing architecture

Read user-owned instructions and only the relevant `.fs-skills/` pages. Trace one representative feature from route or UI entry through policy, persistence, and response. Inspect imports, package/configuration, tests, and existing public exports. Treat folder names as hypotheses; confirm what code actually depends on what.

Separate durable conventions from project-specific decisions and framework-version-specific workarounds. Verify technical claims against the installed package/version. Do not universalize a workaround from one project. Existing conventions take precedence unless they cause significant correctness, security, or maintainability problems.

## Organize by capability and responsibility

- A feature owns a coherent business capability, its rules, use cases, and data boundary. Put behavior there because of what it does, not because a nearby route or feature folder exists.
- Use `domain/` for business vocabulary, invariants, policies, and domain outcomes where those concepts have real complexity. A domain layer is not a bag of interfaces.
- Use `application/` for use cases that coordinate a task and depend on application-owned ports. Pass trusted actor identity and task data explicitly. Keep framework and ORM types out of these contracts.
- Use `infrastructure/` for database/provider adapters that implement ports and translate persistence/vendor details into application contracts. Map rows when representation or invariants differ; do not add a mapper for a trivial identical shape.
- Use `ui/` or an equivalent delivery layer for framework boundaries, presentation DTOs, and interaction. Keep business rules in the domain/application layer.
- Use `shared/` only for genuinely cross-feature, business-neutral capabilities with clear ownership. Do not use it as a dumping ground or to bypass feature boundaries.

For smaller features, omit layers without useful work. A single feature may have a domain helper and a direct adapter until a use case or integration boundary makes more structure useful.

## Dependency direction and APIs

For the modular profile, allow:

- Domain → other domain concepts or neutral language/runtime primitives.
- Application → domain and application-owned ports.
- Infrastructure → application ports, domain contracts, and vendor/database APIs.
- UI → feature public APIs and UI adapters; never infrastructure internals.
- Composition root → application factories and concrete adapters to wire them together.
- One feature → another feature's intentional public API, not its private files.

Forbid domain → framework/ORM/provider; application → UI/Next/React; infrastructure → UI; external feature imports into `domain/`, `application/`, `infrastructure/`, or `ui/` private paths; and dependency cycles. Framework route files should compose feature APIs rather than become a second application layer.

Define a public API only for a real consumer boundary. In Next.js applications, a useful convention is an optional universal `index.ts`, server-only `server.ts`, and client-only `client.ts`; publish only meaningful exports. Use an internal server-only composition root to construct adapters and use cases. Do not make every internal import pass through its own feature barrel.

Keep domain and application behavior testable through their public contracts. A port helps isolate a meaningful external boundary, but does not imply a fake or mock for every dependency; use the `testing` skill to choose test doubles and levels that actually prove the boundary.

Keep tenant/owner scoping and business authorization at the application boundary and data boundary. A client-provided organization ID, role, or permission is untrusted. If authorization can change concurrently with a write, ensure the persistence operation is scoped atomically too.

## Evolve and record

Split a feature when it gains a separate capability, lifecycle, data owner, or independent reason to change. Keep related UI together when it composes another feature's public API; do not move rules into the page merely because that is where users see them. Promote a shared module only when multiple features use the same stable concept.

Add a concise ADR for durable, consequential choices: status/date, context, decision, consequences, and alternatives. Update `.fs-skills/` incrementally when module boundaries or dependency rules change. Do not create or edit `AGENTS.md`, `CLAUDE.md`, or other user-owned instruction files.

## Review checklist

- Was architecture chosen from requirements before creating structure?
- Can each feature's capability, data owner, and public API be stated clearly?
- Are only useful layers/directories present?
- Do imports follow dependency direction without cycles or private cross-feature access?
- Are framework, persistence, and provider details at appropriate boundaries?
- Are actor identity, authorization, and data scoping trusted and explicit?
- Do documented decisions match code, and are version-specific workarounds reverified?
- Does each abstraction use a familiar name for a real responsibility, and would an established pattern make it easier to understand?
- Would a smaller profile or fewer abstractions satisfy the same need?
