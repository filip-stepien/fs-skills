---
name: testing
description: Design, write, review, or maintain tests for business behavior, contracts, invariants, edge cases, integrations, and user-visible flows. Use during meaningful implementation work, bug fixes, refactors, or explicit test reviews.
---

# Testing

Write tests that read like concise explanations of behavior. Hide incidental dependency setup, but keep the conditions that explain the result visible. Test stable contracts and observable outcomes, not private implementation structure. Testing code must meet the same readability and maintenance standards as production code.

Use this skill with the project's existing runner and conventions. Do not add a framework, test every trivial change, or optimize for coverage numbers. Follow `clean-code` for test readability, `software-architecture` for boundaries, `typescript` for contracts, and the applicable `react` or `nextjs` skill for framework-specific behavior.

## Choose scenarios and test level

1. Read the relevant tests, test config, fixtures, fakes, and package scripts before adding infrastructure. Learn what the project already reuses and what its test commands actually run.
2. State the behavior or contract that could regress. Consider valid, invalid, boundary, missing, conflicting, unauthorized, duplicate, delayed, and failure cases only where the real contract makes them meaningful.
3. Use the lowest test level that can reliably prove the behavior. Unit-test domain rules and use cases; integrate with real adapters where query, transaction, framework, or serialization behavior matters; test UI through user-observable interaction.
4. Make the scenario explicit in its name, setup, action, and assertion. Hide stable defaults and technical wiring in a focused helper; expose the preconditions that determine the expected result.
5. Prefer the simplest suitable real dependency, fake, stub, spy, or mock. Reuse test infrastructure when a recurring contract needs it, and keep doubles faithful to that contract.
6. Keep tests deterministic and isolated. Control clocks, generated IDs, asynchronous results, external calls, and mutable state when they affect the assertion.
7. For bug fixes, reproduce the defect in a focused failing test when practical. Refactor against the public behavior contract, not the shape of the old implementation.
8. Review whether a plausible incorrect implementation would fail the test. Run relevant project checks when appropriate and authorized; report exactly what ran.

Read [scenario design and test doubles](references/scenario-design-and-test-doubles.md) when tests are setup-heavy or need reusable fakes. Read [behavior, edge cases, and test levels](references/behavior-and-test-levels.md) when selecting coverage, testing stateful behavior, or choosing unit/integration/component/E2E scope.

## Test quality review

- Does the test name state an observable outcome and meaningful condition?
- Can the reader identify setup, action, and expected result without tracing helper internals?
- Are behaviorally important preconditions explicit while incidental IDs and wiring stay out of the way?
- Does the double preserve the relevant contract, and is the chosen test level able to prove the claim?
- Would the test fail for a realistic regression without breaking on an unrelated refactor?
- Is the test deterministic, isolated, and worth maintaining?
