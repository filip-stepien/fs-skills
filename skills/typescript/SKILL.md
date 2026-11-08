---
name: typescript
description: Model TypeScript domain types, application contracts, results/errors, generics, external-data validation, narrowing, and persistence mappings. Use whenever TypeScript contracts or type safety are part of the task.
---

# TypeScript engineering

Use the installed compiler settings and project conventions. Types describe trusted program values; they do not validate data at runtime. Prefer explicit, useful contracts over clever type machinery.

## Type and contract rules

- Prefer `type` aliases. Follow a clear established project convention that uses `interface`; if a class uses `implements`, declare that implemented contract as an `interface`.
- Use inference for obvious local values and explicit types at public APIs, use-case/port boundaries, and complex domain contracts.
- Model finite states with discriminated unions and handle every case. Use `null`/`undefined` deliberately rather than ambiguous empty or sentinel values.
- Use generics when callers need a real relationship between input and output types. Avoid broad utility types that obscure domain meaning.
- Use `unknown` at external boundaries, validate/narrow before use, and contain `any` or assertions at unavoidable interoperability seams. Never treat a cast as input validation.
- Keep ORM/provider types in infrastructure. Application ports and use cases expose domain/application contracts. Add DTOs/mappers when they clarify a boundary or transform representation; do not map an identical trivial projection.

## Results and errors

Use typed `Result<T, E>` when callers must branch on an expected outcome. Model domain errors as named codes/constants and keep UI wording at the UI boundary. Let unexpected failures propagate to an error boundary or translate them where a caller can meaningfully recover. See [contracts, results, and validation](references/contracts-results-validation.md) for a cohesive membership example.

## Check before adding type machinery

- Can the runtime value actually be trusted here, or does it still need parsing?
- Is a distinct type preventing a real category, unit, or invariant bug?
- Does a generic preserve a useful input/output relationship?
- Is an assertion backed by a nearby invariant that the compiler cannot express?
- Are public contracts explicit about nullability and expected failures?
- Do mappings clarify representation or enforce a boundary, rather than duplicate field names?
