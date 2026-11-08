# Architecture profiles and boundaries

Use this when starting a project, extracting a feature, or deciding whether a codebase needs stronger module boundaries. The examples use a fictional organization membership product and are architectural sketches, not a required framework or scaffold.

## Profile 1: simple application

### Fits when

- Few routes support one cohesive workflow.
- Rules are short and local; there is one persistence/provider path.
- One deployable application and a small team own the code.

### Example shape

```text
src/
├── app/
│   ├── organizations/page.tsx
│   └── organizations/actions.ts
├── db/
│   ├── schema.ts
│   └── organizations.ts
└── lib/
    └── organization-name.ts
```

Keep a route/action small, validate inputs, authenticate before writes, and put repeated rules in a named helper. A direct persistence call can be reasonable when it is local and the project has no application boundary to preserve.

### Trade-off and evolution signal

This is easy to navigate and has little ceremony. If actions begin duplicating authorization, use cases span several adapters, or tests need to boot a framework/database to check a rule, extract a feature-owned application operation and a port. Do not pre-create `domain/`, `application/`, and `infrastructure/` folders with one-line wrappers.

## Profile 2: feature-based application

### Fits when

- The application has distinct business capabilities such as organizations, memberships, billing, and projects.
- Features change independently, but not every feature needs domain-heavy layering.
- Cross-feature use is occasional and can go through small public APIs.

### Example shape

```text
src/
├── app/
├── features/
│   ├── organizations/
│   │   ├── actions/
│   │   ├── queries/
│   │   ├── components/
│   │   └── index.ts
│   └── memberships/
│       ├── actions/
│       ├── queries/
│       ├── components/
│       └── index.ts
└── shared/
```

`memberships/` owns inviting/removing members and membership state; `organizations/` owns organization settings. An organization settings screen may display a member summary through the memberships API, but it should not query the membership table directly.

### Allowed and forbidden access

```ts
// Allowed: consume the public capability.
import { listOrganizationMembers } from '@/features/memberships/server';

// Forbidden from outside memberships/: reach into its database implementation.
import { membershipRepository } from '@/features/memberships/infrastructure/repository';
```

The public API is intentionally small. A feature may have one `index.ts` if it is runtime-neutral; use server/client entry points only when those boundaries need enforcement. Do not export all internals “just in case.”

### Trade-off and evolution signal

Feature folders make capability ownership visible without forcing every file through layers. Add `domain/`, `application/`, and `infrastructure/` to one feature when it develops meaningful invariants, multiple adapters, or independently testable use cases. Do not upgrade the whole repository because one feature grew.

## Profile 3: modular monolith with Hexagonal boundaries

### Fits when

- Business rules are non-trivial or authorization-sensitive.
- Database/auth/payment/email/storage integrations may change or need isolated tests.
- Use cases coordinate multiple capabilities or operations.
- Feature ownership and dependency rules must be reviewable or enforced.

### Example feature shape

```text
src/
├── app/                                      # Framework routes compose feature APIs
├── features/
│   └── organizations/
│       ├── domain/
│       │   ├── organization.ts                # Entity, name invariant, policies
│       │   └── errors.ts                      # Domain outcome codes
│       ├── application/
│       │   ├── ports/
│       │   │   └── organization-repository.ts # Contract required by use cases
│       │   └── use-cases/
│       │       └── rename-organization.ts     # Orchestration and business permission
│       ├── infrastructure/
│       │   ├── drizzle/
│       │   │   └── organization-repository.ts # SQL, row mapping, constraint translation
│       │   └── mappers/
│       ├── ui/
│       │   ├── actions/
│       │   ├── queries/
│       │   ├── components/
│       │   ├── hooks/
│       │   └── lib/
│       ├── composition.ts                    # Server-only assembly; internal
│       ├── index.ts                           # Optional universal public API
│       ├── server.ts                          # Optional server-only public API
│       └── client.ts                          # Optional client-only public API
└── shared/                                    # Neutral primitives with clear ownership
```

Remove empty directories. `mappers/`, `hooks/`, `client.ts`, and even `domain/` are optional unless they contain a real concept. A one-file projection may live beside its caller.

### Responsibility and dependency example

An organization rename has these responsibilities:

1. The route selects the feature query or renders the feature component.
2. A Server Action (framework boundary) validates form data, gets the authenticated actor from the server session, invokes the composed use case, maps its result to UI feedback, and requests cache/route updates when needed.
3. The use case checks membership/role policy using trusted actor ID, normalizes the name through the domain, then calls a repository port.
4. The domain owns the valid organization-name rule and the capability policy (for example, which roles may rename).
5. The Drizzle adapter implements the port, scopes the write to organization and actor membership, maps rows to domain/application values, and translates known constraint failures to typed outcomes. Unexpected database failures propagate.
6. The composition root constructs the database/repository adapter and injects it into the use case. UI never imports the repository.

Use distinct API shapes at boundaries: `FormData`/unknown → validated action data → use-case contract → persistence row → domain/application value → minimal UI DTO. Do not expose ORM rows as feature APIs just because their fields currently match.

### Dependency rules

| Importer | May depend on | Must not depend on |
| --- | --- | --- |
| `domain/` | Other domain concepts, neutral language/runtime types | React, Next.js, database/provider SDK, application/UI |
| `application/` | Domain, own ports, neutral contracts | Infrastructure implementation, ORM, React, Next.js |
| `infrastructure/` | Own application ports, domain contracts, DB/provider SDK | UI or route modules |
| `ui/` | Own application/composition/public contracts and framework APIs | Another feature's private files; direct DB/provider SDK access |
| `app/` | Feature public APIs and route-level composition | Feature internals or persistence details |
| `composition.ts` | Use-case factories and concrete adapters | Client modules; it remains a composition boundary, not a domain module |

Within a feature, internal imports can use direct relative paths. Across features, import only a published API. If two features share business meaning, first decide which feature owns it; only then create a neutral shared concept if ownership truly spans both.

### Authorization and atomic writes

Authentication answers “who is this request acting as?” Business authorization answers “may this actor perform this operation on this organization?” The UI may hide an unavailable button, but the use case must check the policy with the authenticated actor. The persistence write must also scope by organization and actor; when membership can be revoked concurrently, enforce the relevant membership condition in the same transaction/write, not only in an earlier read.

Do not accept `role`, `ownerId`, or `isAdmin` from a hidden input as authority. Derive actor identity from the server session and load permission from trusted data.

### Trade-off and evolution signal

Ports/adapters add files and indirection. They are worth it when they isolate a provider boundary, enable meaningful use-case tests, protect business rules, or make data ownership explicit. They are noise when a wrapper has one caller, forwards every argument unchanged, and no independent contract or volatility.

Consider a separate deployable service only when independent release/scaling/security/ownership requirements outweigh distributed-system costs. A modular monolith is usually enough to keep domain ownership and independent modules.

## Architecture selection examples

### Membership badge versus membership administration

Displaying a member's name/role in an organization header is a read projection; it does not justify creating another service or putting membership storage in `organizations/`. Use the memberships public read API or a feature-owned query. Inviting members, changing roles, and enforcing last-owner rules are a distinct capability: keep their use cases and policies under `memberships/`.

### When a “shared” folder is justified

`Result<T, E>` or a date formatter with no business meaning may be shared. An `OrganizationMember` policy is not generic merely because billing and projects both need it; decide whether membership owns the policy/API or whether the concept is truly a shared domain. Avoid `shared/utils` imports that make ownership impossible to identify.

## Before adding structure

- Which requirement or repeated change does this boundary serve?
- What concrete module owns the rule and data?
- Who will import this API, and which imports should be forbidden?
- Is a port useful because the dependency is external/volatile/test-significant, or is it forwarding one call?
- Can the selected profile be implemented with fewer files and still preserve the required boundary?
- What evidence would justify evolving the profile later?
