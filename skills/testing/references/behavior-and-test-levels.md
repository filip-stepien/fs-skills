# Behavior, edge cases, and test levels

Use this guide to decide what matters to test, which boundary proves it, and what a meaningful edge case looks like. All payment and phone rules below are explicitly fictional examples; verify the product contract before adopting any expected result.

## Derive cases from the contract

Start from a rule, decision table, or user-visible promise—not from the current branches in the implementation. Partition inputs into meaningfully different categories, then test representative values and important boundaries. Avoid a case for every possible combination when cases exercise the same rule.

For a limit `N`, consider `N - 1`, `N`, and `N + 1`; for a time window, include just inside, exactly at, and just outside the boundary when inclusivity matters. Test absent, empty, malformed, duplicate, conflicting, unauthorized, and failed dependency inputs only if the contract defines different behavior for them.

Use table-driven tests when cases share one rule and the expected outcome is clear in each row. Give each row a scenario label. Keep separate `it` tests when cases represent different business meanings or need materially different setup.

## Example: phone-number normalization

Assume this **fictional input contract for the example only**: accept 9–15 digits, permit an optional leading `+` and spaces, parentheses, or hyphens as presentation separators, and normalize to `+` followed by digits. Reject alphabetic text, unsupported punctuation, fewer than 9 digits, and more than 15 digits. This is syntactic normalization, not proof that a number is assigned, reachable, or valid for a particular country.

The cases come from the contract's equivalence classes and boundaries:

| Input | Expected outcome | Why it matters |
| --- | --- | --- |
| `123 456 789` | `+123456789` | Optional plus omitted; spaces normalized |
| `123 456789` | `+123456789` | Different grouping has same meaning |
| `48123123123` | `+48123123123` | Digits-only international form |
| `+48 123 123 123 ` | `+48123123123` | Plus, separators, and surrounding whitespace |
| `+48 123-123-123` | `+48123123123` | Hyphen presentation form |
| `12345678` | invalid | One digit below minimum |
| `123456789` | `+123456789` | Exactly the minimum |
| `123456789012345` | `+123456789012345` | Exactly the maximum |
| `1234567890123456` | invalid | One digit above maximum |
| `abc123456789` | invalid | Alphabetic input is outside the contract |
| empty string | invalid | Missing value is distinct from a valid number |

```ts
import { describe, expect, it } from 'vitest';
import { normalizePhoneNumber } from './phone-number';

describe('normalizePhoneNumber', () => {
  it.each([
    ['spaces', '123 456 789', { ok: true, value: '+123456789' }],
    ['uneven spacing', '123 456789', { ok: true, value: '+123456789' }],
    ['international digits', '48123123123', { ok: true, value: '+48123123123' }],
    ['plus and trailing whitespace', '+48 123 123 123 ', { ok: true, value: '+48123123123' }],
    ['hyphens', '+48 123-123-123', { ok: true, value: '+48123123123' }],
    ['parentheses', '123 (456) 789', { ok: true, value: '+123456789' }],
    ['below minimum', '12345678', { ok: false, error: 'invalid-phone' }],
    ['at maximum', '123456789012345', { ok: true, value: '+123456789012345' }],
    ['above maximum', '1234567890123456', { ok: false, error: 'invalid-phone' }],
    ['letters', 'abc123456789', { ok: false, error: 'invalid-phone' }],
    ['empty', '', { ok: false, error: 'invalid-phone' }],
  ] as const)('handles %s', (_scenario, input, expected) => {
    expect(normalizePhoneNumber(input)).toEqual(expected);
  });
});
```

The test asserts specified examples, not a copy of the production regex. If requirements do not define whether a format is valid, resolve that ambiguity before turning current implementation behavior into a test contract. If the product only validates a local format, do not imply full international phone-number verification.

The projects examined use fixed timestamps and boundary cases effectively. For example, the phone-verification limit tests check just below and at the hourly limit, and attempts inside and outside hourly/daily windows. Keep that precision, while ensuring the contract—not a magic constant copied from current code—explains the expected result.

## Test a use case through its public contract

Test business policy without booting the framework or database. Keep reusable repository behavior in focused test support, then let each test show only the business conditions, action, and observable result.

This feature-specific helper is defined once in test support. It uses a stateful fake repository; the helper's inputs expose the roles that determine authorization, while stable IDs and dependency wiring stay out of each test.

```ts
import { changeMemberRoleFactory } from '../application/change-member-role';

type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
type Role = 'owner' | 'admin' | 'member';
type Membership = { id: string; organizationId: string; userId: string; role: Role };
type MembershipRepository = {
  findRole(params: { organizationId: string; userId: string }): Promise<Role | null>;
  updateRole(params: {
    organizationId: string;
    memberId: string;
    role: Role;
  }): Promise<Result<Membership, 'member-not-found'>>;
};

function createInMemoryMembershipRepository(initial: Membership[]) {
  const members = initial.map(member => ({ ...member }));
  const repository: MembershipRepository = {
    async findRole({ organizationId, userId }) {
      return members.find(
        member => member.organizationId === organizationId && member.userId === userId,
      )?.role ?? null;
    },
    async updateRole({ organizationId, memberId, role }) {
      const member = members.find(
        candidate =>
          candidate.organizationId === organizationId && candidate.id === memberId,
      );
      if (!member) return { ok: false, error: 'member-not-found' };
      member.role = role;
      return { ok: true, value: { ...member } };
    },
  };

  return {
    ...repository,
    findMember: async ({ organizationId, memberId }: { organizationId: string; memberId: string }) =>
      members.find(
        member => member.organizationId === organizationId && member.id === memberId,
      ) ?? null,
  };
}

function givenMemberRoleChange({
  actorRole,
  targetRole,
}: {
  actorRole: Role;
  targetRole: Role;
}) {
  const memberships = createInMemoryMembershipRepository([
    { id: 'member-actor', organizationId: 'org-1', userId: 'actor-1', role: actorRole },
    { id: 'member-target', organizationId: 'org-1', userId: 'target-1', role: targetRole },
  ]);
  const changeMemberRole = changeMemberRoleFactory({ memberships });

  return {
    changeRole: (role: Role) =>
      changeMemberRole({
        actorId: 'actor-1',
        organizationId: 'org-1',
        memberId: 'member-target',
        role,
      }),
    targetRole: async () =>
      (await memberships.findMember({ organizationId: 'org-1', memberId: 'member-target' }))
        ?.role ?? null,
  };
}
```

`createInMemoryMembershipRepository` is the shared, complete fake for this repository contract: it reads roles by organization and user, updates the matching membership, returns `member-not-found` for a missing record, and exposes a test-only read for assertions. It does not implement authorization; the use case owns that rule.

The test stays focused on the behavior. The actor and target roles are visible because they explain the denial; IDs and dependency assembly are incidental.

```ts
import { expect, it } from 'vitest';
import { givenMemberRoleChange } from '../test-support/member-role-change';

it('denies a member changing another member’s role', async () => {
  const membershipChange = givenMemberRoleChange({
    actorRole: 'member',
    targetRole: 'admin',
  });

  const result = await membershipChange.changeRole('member');

  expect(result).toEqual({ ok: false, error: 'permission-denied' });
  await expect(membershipChange.targetRole()).resolves.toBe('admin');
});
```

In production, derive the actor from trusted authentication and authorize again at the use-case/data boundary; a hidden role in test setup is not a production authorization mechanism. Use a local literal fake when it is clearer for a one-off test. Extract a reusable fake when its read/write semantics recur or need contract verification.

## Test payment transitions as a state machine

This is a **hypothetical** contract for a provider integration that supplies event IDs and monotonically increasing versions. A real provider may have different ordering, idempotency, status, and reconciliation guarantees; verify its contract before documenting or testing it.

| Current state | Verified event | Expected outcome | Required observable effect |
| --- | --- | --- | --- |
| pending | newer success | completed | Persist final state; publish completion once |
| pending | newer final failure | failed | Persist final state; do not publish completion |
| completed | same event ID delivered again | unchanged | No second state change or event |
| completed at version 4 | delayed event at version 3 | unchanged | Ignore stale event; do not regress state |
| completed | newer contradictory failure | conflict/reconciliation outcome | Keep current state; do not emit a contradictory completion/failure event |
| pending | transient charge timeout | still pending until verified outcome | Retry according to configured policy with the same idempotency key |

Test allowed and forbidden transitions with the domain policy. Test event de-duplication, ordering, persistence, and publication through the application contract. Keep the following examples independent: the pure transition decision belongs in domain tests; “store before publish” or “do not publish on failure” belongs in use-case tests; database uniqueness/transaction behavior belongs in adapter integration tests.

```ts
import { expect, it, vi } from 'vitest';
import { applyPaymentEvent } from './payment';
import type { Payment, VerifiedPaymentEvent } from './payment';

const pendingPayment: Payment = {
  id: 'payment-1',
  status: 'pending',
  lastEventVersion: 0,
  processedEventIds: [],
};

function verifiedEvent(overrides: Partial<VerifiedPaymentEvent> = {}): VerifiedPaymentEvent {
  return {
    id: 'event-1',
    paymentId: 'payment-1',
    version: 1,
    outcome: 'success',
    ...overrides,
  };
}

it('completes a pending payment after a newer verified success', () => {
  const result = applyPaymentEvent(pendingPayment, verifiedEvent());

  expect(result).toEqual({
    kind: 'applied',
    payment: {
      ...pendingPayment,
      status: 'completed',
      lastEventVersion: 1,
      processedEventIds: ['event-1'],
    },
    eventToPublish: 'payment-completed',
  });
});

it('does not publish the same provider event twice', () => {
  const completedPayment: Payment = {
    ...pendingPayment,
    status: 'completed',
    lastEventVersion: 1,
    processedEventIds: ['event-1'],
  };

  expect(applyPaymentEvent(completedPayment, verifiedEvent())).toEqual({
    kind: 'ignored',
    reason: 'duplicate-event',
    payment: completedPayment,
  });
});

it('does not move a completed payment backwards for an older event', () => {
  const completedPayment: Payment = {
    ...pendingPayment,
    status: 'completed',
    lastEventVersion: 4,
    processedEventIds: ['event-4'],
  };

  expect(
    applyPaymentEvent(
      completedPayment,
      verifiedEvent({ id: 'delayed-event-3', version: 3, outcome: 'failure' }),
    ),
  ).toEqual({
    kind: 'ignored',
    reason: 'stale-event',
    payment: completedPayment,
  });
});
```

The imported types and function are the production public domain contract under test; the expected payment/event values are independently specified. Add separate cases for pending-to-failure, a conflicting newer final outcome, and publisher/storage failures when those are part of the application contract. Avoid combining all state, retries, provider parsing, database updates, and HTTP signatures into one giant test.

For a charge retry, assert the externally meaningful guarantee: retryable timeouts reuse the same payment idempotency key and do not create a second provider charge. Do not assert private helper call order unless the order is itself required to protect that guarantee. Prefer a provider fake that records submitted request values over a mock of every internal method.

## Replace mock-heavy tests with state-based assertions

**Coupled to current call structure:**

```ts
import { expect, it, vi } from 'vitest';
import type { MembershipRepository } from '../ports/membership-repository';
import { changeMemberRoleFactory } from './change-member-role';

it('rejects a member role change', async () => {
  const findRole = vi.fn(async () => 'member' as const);
  const updateRole = vi.fn(async () => ({
    ok: true as const,
    value: { organizationId: 'org-1', userId: 'target-1', role: 'admin' as const },
  }));
  const repository: MembershipRepository = { findRole, updateRole };
  const useCase = changeMemberRoleFactory({ memberships: repository });

  const result = await useCase({ actorId: 'actor-1', organizationId: 'org-1', memberId: 'target-1', role: 'admin' });

  expect(findRole).toHaveBeenCalledTimes(1);
  expect(findRole).toHaveBeenCalledWith({ organizationId: 'org-1', userId: 'actor-1' });
  expect(updateRole).not.toHaveBeenCalled();
  expect(result.ok).toBe(false);
});
```

The method-count and argument checks are mostly implementation details, and `result.ok === false` does not say why access was denied.

**Behavior-focused:**

```ts
import { expect, it } from 'vitest';
import { givenMemberRoleChange } from '../test-support/member-role-change';

it('does not change a target member when the actor lacks permission', async () => {
  const membershipChange = givenMemberRoleChange({
    actorRole: 'member',
    targetRole: 'admin',
  });

  const result = await membershipChange.changeRole('member');

  expect(result).toEqual({ ok: false, error: 'permission-denied' });
  await expect(membershipChange.targetRole()).resolves.toBe('admin');
});
```

This version proves the denied operation leaves data unchanged. Use an interaction assertion if the contract explicitly says that a provider must not be called or that publication occurs only after persistence.

## Reproduce a regression

Suppose a bug allowed a reviewed/rejected listing to skip review when resubmitted. The regression test should state that prior state and action, then assert the policy—not the new helper's internal shape.

```ts
import { expect, it } from 'vitest';
import { resolveResubmittedOfferStatus } from './offer-status-rules';

it('sends a rejected offer back through review when it is resubmitted', () => {
  const status = resolveResubmittedOfferStatus({ currentStatus: 'rejected', isAdministrator: false });

  expect(status).toBe('pending_review');
});
```

Write this before the behavior fix when practical and confirm it fails for the reproduced reason. Keep the production change separate from unrelated cleanup so the failing test demonstrates the original defect. This example is fictional; it does not claim that either inspected project had this bug.

## Determinism and isolation

- Freeze the clock or inject a clock when expiry, retry windows, scheduling, or age affects the result. Use explicit instants and timezone where relevant.
- Use deterministic IDs when identity is not the behavior under test. If uniqueness is the behavior, use a controlled ID source or assert uniqueness directly.
- Control provider responses and asynchronous completion with fakes/deferred promises rather than arbitrary sleeps.
- Create fresh repository state per test. Do not mutate module-level fixtures or depend on prior test order.
- Keep cleanup explicit for resources the test creates. Avoid sharing databases, ports, files, or accounts unless the integration harness isolates them.

Retry loops that poll a real database or external process may require bounded polling. Prefer observable completion signals; if polling is the only reliable boundary, document the reason and use a deadline rather than an unbounded loop. Do not use a fixed delay as proof that work completed.

## Choose the test level

| Level | Use it to prove | Example | What it does not prove by itself |
| --- | --- | --- | --- |
| Unit: domain | A rule/invariant independent of infrastructure | Last-owner rule, phone normalization, payment transition | SQL, transaction, framework, provider behavior |
| Unit: use case | Orchestration, authorization, expected outcomes, port-level effects | A non-admin cannot change membership; no save occurs | That a real database query is scoped correctly |
| Integration | A real boundary works with its dependency | Drizzle filter, uniqueness, transaction, mapper, action serialization | Every user journey or all provider behavior |
| Component | User-observable interaction and UI states | Form validation feedback, pending state, accessible control flow | Server authorization or persistence correctness |
| End-to-end | A high-value path across deployed-like boundaries | Guest sign-in return flow, successful application persisted in test DB | Every domain edge case or every component detail |

Use the lowest reliable level and add higher-level tests only for risks those levels uniquely cover. A fake repository cannot prove a Drizzle query scopes by organization. A database integration test does not need to repeat every pure domain transition. A component hiding an admin button does not prove the server denies a forged request.

The inspected projects provide contrasting evidence: one uses Vitest for source tests and Cypress for E2E flows, with database tasks for test data; the other had no test files or configured runner at the time of review. Use the consuming project's actual tooling and add a runner only when its value justifies the setup. Do not introduce new tooling merely to match another project.

For React, test controls and transitions through accessible roles, labels, text, and user actions. Assert observable states such as validation feedback, pending, success, and recoverable errors; avoid testing hook state or component internals. For Next.js, keep domain/use-case rules testable outside the framework and add a boundary test where framework behavior, action validation, redirects, serialization, or database query scope is the risk. Consult the project's installed framework and test-tool documentation for APIs rather than copying a setup from another app.

## Review questions

- Which requirement or invariant does each test protect?
- Are cases equivalent, or do they represent different behavior?
- Are limit, time, permission, ordering, and failure boundaries tested where applicable?
- Would an off-by-one, removed authorization check, ignored filter, duplicate side effect, or swallowed error make the relevant test fail?
- Does the chosen level exercise the actual risky boundary?
- Are fake behavior and integration claims kept distinct?
- Can an engineer change internal structure without rewriting the test if public behavior remains the same?
