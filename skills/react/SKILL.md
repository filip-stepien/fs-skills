---
name: react
description: Design, implement, refactor, or review React components, hooks, props, state, effects, forms, accessibility, and rendering performance. Use when changing React UI or deciding where UI state and behavior belong.
---

# React engineering

Use the installed React version and project conventions. React owns presentation, interaction, and short-lived client state. Business policy belongs in the domain/application layer; framework-specific Server Component, Server Action, and data-fetching behavior belongs to `nextjs`.

## Components and composition

- A component should have a clear UI responsibility and predictable props. Extract a component when it names a useful piece of UI, owns coherent interaction/state, is reused, or can be changed/tested independently. Do not make a component for every wrapper or line of markup.
- Keep components declarative: receive data/capabilities, render semantic UI, and emit user intent through callbacks/actions. A hidden/disabled button is usability, never authorization.
- Prefer composition for optional regions and distinct modes over a growing set of boolean props. Use a discriminated `variant` when choices are mutually exclusive and structurally similar.
- Keep props small and purposeful. Pass an entity when the component truly represents that entity; pass narrow display data/callbacks when that avoids coupling to a large domain contract.

## State, hooks, and effects

- Keep state at the lowest common owner that coordinates it. Use local state for transient interaction; lift it only when siblings coordinate. Use reducers when related transitions have meaningful complexity. Do not copy props or derived values into state without a synchronization requirement.
- Compute derived state during render (`filter`, `map`, selected item); reach for `useMemo` only for a measured/evident expensive calculation or referential stability a consumer needs.
- Custom hooks package reusable stateful behavior or a coherent UI interaction. Do not create a hook for a one-line calculation or to hide business rules. A hook may adapt an action to a particular React form API where that adapter removes real repetition; do not wrap every Server Action by default.
- Effects synchronize with external systems (subscriptions, browser APIs, timers, imperative widgets). They are not for deriving render data or running work that belongs directly in an event handler. Keep setup/cleanup symmetric and dependencies correct.
- Preserve stable list keys based on identity. Avoid index keys where items can be inserted, removed, or reordered.

## Forms, accessibility, and feedback

- Let a form own transient draft/pending/field-feedback state. Keep authoritative validation and business rules at trusted boundaries; client validation improves feedback but does not replace server validation.
- Use native form controls, labels, semantic buttons, keyboard-operable interactions, visible focus, and accessible names/states. Show relevant pending, success, field-error, and failure states; don't clear user input on recoverable failure.
- Follow the project’s established form library and component primitives rather than introducing a second form abstraction for one screen.

## Rendering performance

Render pure, cheap UI first. Profile a user-visible slow path before memoizing. `memo`, `useMemo`, and `useCallback` add comparison and maintenance cost; apply them when profiling or a known expensive boundary shows benefit. Keep state local so unrelated parts do not re-render. For genuinely large collections, evaluate pagination/virtualization and accessibility trade-offs.

## Detailed examples and checks

See [practical React patterns](references/practical-patterns.md) for before/after examples of component boundaries, useful/unnecessary hooks, derived state vs effects, composition, forms, and a measured performance fix.
Use the `testing` skill for readable component scenarios and observable interaction tests; keep authorization and server behavior covered at their trusted boundaries.

- Does each component render one coherent responsibility and expose a purposeful API?
- Is state local to the UI that owns it, with derived values computed rather than duplicated?
- Does every effect synchronize with an external system and clean up correctly?
- Are hooks packaging a reusable UI concern rather than business policy or trivial calculation?
- Are form states accessible and recoverable, with authoritative validation outside the client?
- Is an optimization based on measurement or a demonstrated hot path?
