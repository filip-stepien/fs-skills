---
name: nextjs
description: Structure and implement Next.js App Router applications with feature ownership, Clean/Hexagonal boundaries, thin routes, Server Actions, server queries, persistence adapters, public APIs, and safe auth boundaries. Use for Next.js architecture or feature implementation.
---

# Next.js application architecture

This skill owns how framework entry points connect to feature-owned business code. It does not replace Next.js API documentation. Before using or changing framework behavior, follow [the versioned reference guide](references/authoritative-docs.md).

## First identify the actual framework contract

1. Find the Next.js version resolved by the target project’s package manager, not just a range in `package.json`.
2. Resolve the installed `next` package from the app/package being edited, including monorepo package boundaries.
3. When that installation provides `dist/docs/`, consult its relevant App Router pages before relying on APIs, caching, rendering, runtime, security, or performance behavior.
4. If package docs are absent, use official Next.js docs for the exact installed version. If version-specific docs cannot be found, state the uncertainty and avoid guessing from memory.
5. Apply this precedence to framework semantics only. For architecture, follow the existing project and these feature-boundary conventions unless correctness/security requires a change.

Do not copy framework rules into this skill. The mapping in `references/authoritative-docs.md` tells you where to verify App Router, components, data access, actions, caching, redirects, runtime, security, and performance.

## Boundary model

- `app/` is the routing/framework boundary. `page.tsx` and `layout.tsx` should select route data and compose feature APIs/components; keep business rules and database access out of them. Use route groups/private route files only when they improve route organization or runtime boundaries.
- A feature owns its capability and data/rules. The full example in [organizations-vertical-slice.md](references/organizations-vertical-slice.md) demonstrates a rename action and member-list query from domain through UI.
- `domain/` owns entities/value objects, invariants, policies, and business error codes. It does not import Next.js, React, ORM, or provider SDKs.
- `application/` owns use cases and ports. Use cases accept trusted actor identity and validated task data, apply business authorization/policy, coordinate ports, and return typed outcomes. They do not know about `FormData`, redirects, or UI messages.
- `infrastructure/` implements ports. Keep Drizzle/vendor types here, map persistence rows when shape or meaning differs, and translate known adapter failures into contract outcomes. Unexpected failures propagate.
- `ui/actions/` owns Server Action adapters: validate untrusted form data, get the authenticated actor server-side, call a composed use case, map typed outcomes to UI state, then request relevant route/cache updates or redirect. It owns no domain rules.
- `ui/queries/` owns server-side UI reads: authenticate, validate route/query input, invoke a feature use case, enforce access to the requested data, and return a minimal serializable view model. Do not scatter direct ORM access across Server Components.
- `ui/components/` owns presentation and transient interaction. Client hooks adapt React APIs or manage UI state; they do not own business permission rules or persistence.
- `composition.ts` is an internal server-only composition root: instantiate the project’s database/provider adapters and inject them into use-case factories. Do not expose it as a feature API.

Smaller applications may omit layers that have no real responsibility. Forcing this full shape onto a CRUD screen with one stable data source is overengineering; adding these boundaries to security-sensitive or multi-adapter features can make behavior testable and ownership clear.

## Authentication and authorization

Authentication establishes the actor from a trusted server session. Never accept actor ID, role, organization membership, or an `isAdmin` flag from a form or client component as authority.

Separate authentication from business authorization. Server Actions and server queries load/authenticate the actor at the framework boundary; application use cases decide whether that actor may perform the business operation using trusted membership/policy data. Queries/actions must not bypass the use case and query private infrastructure directly. Persistence writes should be scoped to the organization/tenant and actor; if access can change concurrently, enforce the critical membership condition atomically in the adapter/transaction as well.

Route guards, hidden controls, and middleware/proxy can improve navigation, but they do not replace authorization at the data/use-case boundary. Verify their actual runtime support in the installed version and provider combination before relying on them.

## Public APIs and runtime boundaries

Use these entry points only when they serve real consumers:

- `index.ts`: universal exports safe for server and client imports. It may expose serializable types, shared-safe domain helpers, and reusable components. Do not re-export `server-only` or `client-only` modules.
- `server.ts`: begins with the `server-only` marker and exposes a minimal intentional server API, commonly feature-owned UI queries. Keep composition roots, adapters, and provider clients internal.
- `client.ts`: begins with the `client-only` marker and exposes browser-only hooks/utilities that consumers need. A Client Component itself can still be imported by a Server Component; do not classify every component as client-only.
- `composition.ts`: internal server-only dependency assembly. Server Actions/queries call its composed use cases. Do not route internal feature imports through public barrels just for ceremony.

Cross-feature imports use the other feature’s public entry point. Never import its `domain/`, `application/`, `infrastructure/`, `ui/`, or `composition.ts` internals. Keep feature-specific view composition in its owner; pages can compose public feature components and data.

## Server Actions, queries, and error flow

Treat Actions and queries as network-like entry boundaries even when invoked from the same application. Validate every untrusted value; do not trust client-side types. Derive actor identity server-side. Keep field validation errors, expected domain errors, and unexpected failures distinct. Map domain codes to user-facing wording in the feature UI layer, not in domain/application code.

Use a Server Action for a user-triggered mutation when the project uses that interaction pattern. Keep the Action as orchestration at the edge; use a case factory/use case for rules that need independent tests, multiple operations, or a durable business boundary. A trivial one-off UI adapter need not acquire a port/use-case chain without benefit.

Server queries return explicit, minimal serializable DTOs. Do not pass ORM rows or domain aggregates to Client Components by convenience. Cache behavior, Server/Client serialization constraints, invalidation APIs, redirects, streaming, and action semantics must be checked in the installed-version docs.

Test domain policies and use cases independently from Next.js when possible; test Actions, queries, database adapters, and user flows at the boundary whose behavior matters. Use the `testing` skill to choose levels and avoid treating a fake repository as proof of real query authorization.

## Review checklist

- Are App Router files thin and limited to routing/composition?
- Does one feature own the behavior, rule, and data boundary?
- Are domain/application modules free from framework and ORM imports?
- Are Actions/queries validating input and deriving the actor from trusted auth?
- Is business authorization enforced by the application operation and write scope?
- Are server queries minimal, serializable, and feature-owned?
- Are adapters/composition roots server-only and private?
- Are public imports runtime-safe and cross-feature imports API-only?
- Were relevant framework semantics checked against the installed version’s authoritative docs?
- Is every layer/file earning its maintenance cost?
