---
name: clean-code
description: Write, review, or refactor maintainable application code using clear names, cohesive responsibilities, sound abstractions, testable design, and proportionate complexity. Use for implementation, refactoring, code quality review, or when code is hard to change safely.
---

# Clean code

Prefer code whose intent and behavior are easy to verify. Apply principles as decision aids, not as reasons to add ceremony. The detailed before/after cases are in [SOLID and refactoring examples](references/solid-and-refactoring.md).

## Practice

- Name values and operations for domain meaning and intent. Function and method names SHOULD use a verb that accurately describes the action; make surprising side effects, units, nullability, and lifecycle explicit. Any verbs shown in examples are illustrative, not a required or exhaustive vocabulary.
- Prefer established names for established responsibilities (`MembershipRepository`, `PaymentGateway`, `createBooking`, `composition.ts`) over clever project-specific terminology. Avoid vague `Manager`, `Handler`, `Engine`, `Processor`, or `Service` names when a more precise role or domain name is available; keep them when they accurately name a cohesive responsibility. Use terminology consistently across features.
- When a function takes several parameters, especially multiple values of the same type or optional settings, consider a single object with named fields so each argument's meaning is visible at the call site. Keep a few obvious, stable positional parameters when an object would add ceremony without clarity.
- Keep functions and modules cohesive. A unit should have one reason to change, not necessarily one line of work. Separate responsibilities when doing so clarifies ownership or enables independent change.
- Favor high cohesion and low coupling. Pass the data/dependencies a unit needs; avoid hidden global state and broad mutable objects.
- Keep control flow straightforward. Guard clauses, small helpers, and early returns are useful when they reduce nesting and clarify invariants.
- Use DRY for duplicated knowledge that must change together; duplication can be safer than a premature shared abstraction. Use KISS and YAGNI to avoid features and extension points without a present need.
- Apply each SOLID principle only where it reduces concrete change risk: keep responsibilities cohesive; add extension points for demonstrated variation; preserve behavioral contracts; keep consumer contracts narrow; invert dependencies at meaningful boundaries. Do not add interfaces for every class.
- Choose a recognizable, established design pattern only when it solves a real problem with reasonable complexity. Do not make one-class-per-pattern structures, add interfaces to imitate a pattern, or hide straightforward behavior behind an abstraction.
- Make dependencies replaceable at real external boundaries to support focused tests. Test behavior and contracts, not private implementation details; use the `testing` skill for scenario design and test infrastructure.
- Refactor in small behavior-preserving steps. Separate cleanup from behavior changes when that improves reviewability; preserve compatibility unless change is requested.

## Principle examples

Each example illustrates the principle, not a rule to extract or abstract code every time.

### Naming and explicit intent

`process(value)` hides both the meaning of `value` and the operation. A noun-only function name like `phoneNumber()` also leaves unclear whether it reads, looks up, formats, or changes a number. Choose a verb that matches the behavior; these examples are illustrative:

```ts
const phoneNumber = getPhoneNumber(user);
const user = findUserById(userId);
const taxCents = calculateSalesTax(subtotalCents);
```

Pick the verb that best communicates the operation and its outcome; other verbs may be clearer depending on the domain and project conventions. `subtotalCents` also makes it harder to accidentally pass a dollar amount. Add units when they prevent a realistic mistake.

### Make multiple arguments clear at the call site

Several positional numbers are easy to swap:

```ts
calculateTotal(1200, 96, 100);
```

An object makes each amount's role explicit:

```ts
calculateTotal({ subtotalCents: 1200, taxCents: 96, discountCents: 100 });
```

Use this when there are enough parameters that callers must remember their order, when several share a type, or when options are optional. A simple call such as `indexOf(item)` does not need an options object.

When extracting behavior that naturally uses several fields of one entity, pass that object instead of unpacking it into positional arguments:

```ts
type User = { id: string; name: string; email: string };

function buildWelcomeMessage(user: User): string {
  return `Welcome, ${user.name} (${user.email})! Your account ID is ${user.id}.`;
}

const message = buildWelcomeMessage(user);
```

This keeps the call tied to the `User` concept and avoids mismatching `userId`, `userName`, and `email`. Pass only the needed fields (or a smaller named options object) when the function uses just one field or should not depend on the full `User` contract.

### Make a sequence read like a short explanation

A compact chain can hide what each transformation is for:

```ts
type ReceiptOrder = { status: "paid" | "draft"; receiptEmail: string | null };

function getReceiptEmails(orders: ReceiptOrder[] | null): string[] {
  return (orders ?? [])
    .filter(order => order.status === "paid")
    .map(order => order.receiptEmail?.trim().toLowerCase() ?? "")
    .filter(email => email.length > 0);
}
```

Name the meaningful stages when that makes the intent easier to follow:

```ts
function getReceiptEmails(orders: ReceiptOrder[] | null): string[] {
  const availableOrders = orders ?? [];
  const paidOrders = availableOrders.filter(order => order.status === "paid");
  const normalizedEmails = paidOrders.map(
    order => order.receiptEmail?.trim().toLowerCase() ?? "",
  );
  const nonEmptyEmails = normalizedEmails.filter(email => email.length > 0);

  return nonEmptyEmails;
}
```

Now each line states its purpose: `?? []` treats missing input as no orders, `paidOrders` names the selected records, and the next stages normalize and discard missing email addresses. The extra names also make it easy to inspect an intermediate value while debugging. Keep a short chain inline when its steps are already obvious; extract variables for meaning, not just to make the function longer.

### Cohesive responsibilities

Invoice calculation and email delivery change for different reasons. Keep those operations clear, even if one application use case orchestrates both:

```ts
const invoice = buildInvoice(order);
await saveInvoice(invoice);
await sendInvoiceEmail(invoice);
```

The orchestration can stay together; the calculation and external delivery do not need to be hidden in one large `createInvoiceAndEmail` implementation.

### Cohesion, coupling, and ownership

Avoid a helper that reaches into a global database or another feature's private data. Pass the needed dependency or use its public API:

```ts
type Order = { status: "pending" | "shipped" };
type OrderReader = (id: string) => Promise<Order | null>;

async function canCancelOrder(id: string, readOrder: OrderReader): Promise<boolean> {
  const order = await readOrder(id);
  return order !== null && order.status === "pending";
}
```

The rule uses the reader contract rather than reaching into storage directly. A one-line wrapper with no ownership or testing benefit is not automatically an improvement.

### Prefer recognizable responsibility names

A name should tell the reader what role a unit has without learning a private vocabulary:

```ts
// Unclear: engine could mean policy, persistence, orchestration, or all three.
class MembershipEngine {
  execute(input: unknown) { /* ... */ }
}

// Clear: the use case states the operation; the repository states its boundary.
type MembershipRepository = {
  removeMember(params: { organizationId: string; memberId: string }): Promise<void>;
};

function removeOrganizationMemberFactory({
  memberships,
}: {
  memberships: MembershipRepository;
}) {
  return (params: { organizationId: string; memberId: string }) =>
    memberships.removeMember(params);
}
```

Prefer existing project vocabulary when it is established and precise. `Manager`, `Handler`, `Engine`, `Processor`, and `Service` are not forbidden words; they are weak names when they conceal the responsibility. Here a familiar use-case factory and repository make the direction and behavior apparent. Do not add a factory when direct construction is already clear; pattern selection and layer ownership are covered in [software-architecture](../software-architecture/references/recognizable-patterns.md).

### Straightforward control flow

Nested checks obscure the normal path:

```ts
type User = { name: string; isActive: boolean };

function greeting(user: User | null): string {
  if (!user) return "Guest";
  if (!user.isActive) return "Guest";
  return `Hello, ${user.name}`;
}
```

The guard clauses make the required conditions visible. Keep the nesting if it better communicates the logic; short functions are not a goal by themselves.

### DRY, KISS, and YAGNI

If checkout and invoice generation share the same tax policy, centralize that policy:

```ts
const SALES_TAX_RATE = 0.08;

function calculateSalesTax(subtotalCents: number): number {
  return subtotalCents * SALES_TAX_RATE;
}
```

Both callers then change together when the rule changes. If this rule has one caller and no real variation, do not build a configurable tax framework preemptively. Similar-looking code is not necessarily the same business rule; share knowledge that must stay consistent.

### SOLID in context

Dependency inversion is useful at a replaceable external boundary, such as a payment provider. Checkout depends on a small contract rather than provider-specific details:

```ts
type ChargePayment = (amountCents: number) => Promise<void>;

async function checkout(amountCents: number, chargePayment: ChargePayment) {
  await chargePayment(amountCents);
}
```

The provider adapter and a test fake can both satisfy this contract. Do not create an interface for every class or function; add a contract where it separates meaningful change or ownership.

### Patterns

For two fixed shipping options, a direct branch is easy to read:

```ts
function shippingCost(method: "pickup" | "courier", weightKg: number) {
  if (method === "pickup") return 0;
  return weightKg * 2.5;
}
```

Consider Strategy when algorithms have independent complexity, are selected dynamically, or need to be extended independently. A pattern should reduce change cost enough to pay for its extra indirection.

For when to use familiar architecture patterns such as Repository, Ports and Adapters, Provider/Gateway, Factory, Composition Root, and Facade—and where their contracts belong—see [recognizable architecture patterns](../software-architecture/references/recognizable-patterns.md).

### Testability

Pass meaningful external values in instead of hiding them in globals:

```ts
function isPastDue(dueAt: Date, today: Date): boolean {
  return dueAt.getTime() < today.getTime();
}
```

A test supplies a fixed `today` and checks dates before, on, and after the due date. Test observable behavior; avoid tests coupled to private helper calls.

### Refactoring

Suppose a view formats a person's name inline:

```ts
const label = `${firstName.trim()} ${lastName.trim()}`;
```

Capture that output in a test, then extract a named pure function without changing its behavior:

```ts
function formatFullName(firstName: string, lastName: string): string {
  return `${firstName.trim()} ${lastName.trim()}`;
}
```

For example, confirm that `formatFullName(" Ada ", "Lovelace ")` still returns `"Ada Lovelace"`. Make behavior changes separately when that keeps review and regression diagnosis clearer.

## Smells to investigate

Long or deeply nested functions, unclear names, boolean flags with unrelated modes, repeated conditionals, primitive-heavy domain rules, broad catch-and-ignore, mutable shared state, feature envy, shotgun changes, dead code, comments that paraphrase code, and abstractions used once without a clear boundary. A smell is a prompt to inspect, not an automatic rewrite.

| Smell | Example signal | First response to consider |
| --- | --- | --- |
| Long/deep function | One function validates input, calculates, writes to storage, and sends email | Identify responsibilities or boundaries that change independently; keep orchestration if it is cohesive. |
| Unclear name | `process(data)` or `x` for a domain value | Rename to state the operation and meaning, such as `calculateInvoiceTotal(items)`. |
| Vague role name | `MembershipEngine` owns persistence, authorization, and orchestration | Use precise established roles such as a use case, repository, provider, or policy when they match the responsibility; split only when ownership warrants it. |
| Boolean mode flag | `send(message, true)` selects email versus SMS | Use explicit operations or a discriminated option when the behaviors differ. |
| Repeated conditionals | The same access rule is copied into several handlers | Centralize it if all copies represent the same policy. |
| Primitive-heavy rule | A numeric amount sometimes means dollars and sometimes cents | Clarify units in names; introduce a domain type only if it prevents recurring mistakes. |
| Catch and ignore | `catch {}` hides a failed write | Handle at a boundary that can recover, report, or add useful context; otherwise let it propagate. |
| Shared mutable state | Several modules mutate one exported object | Give the state a clear owner and expose narrow operations. |
| Feature envy | A module repeatedly reads another feature's internals to apply its rules | Move the rule to its owner or call a public API. |
| Shotgun changes | One business rule must be updated manually in many files | Look for duplicated knowledge that should change together. |
| Dead code | An unreachable branch or unused export remains | Remove it when compatibility and generated/public API constraints allow. |
| Paraphrasing comment | `// increment count` above `count++` | Remove it; comment on rationale or constraints that code cannot show. |
| Unused abstraction | A wrapper only forwards one call and has no ownership or volatility boundary | Inline it unless it provides a concrete seam or clearer domain meaning. |

## Checklist

- Does each unit have a clear responsibility and change reason?
- Would a likely variation require editing unrelated callers, or is a real extension boundary justified?
- Do implementations honor the behavior callers rely on, and are contracts no broader than needed?
- Can a reader understand intent and important constraints locally?
- Are names specific, consistent, and honest about side effects?
- Are multi-parameter calls clear about each argument's meaning?
- Is each responsibility and dependency necessary?
- Are errors handled at the boundary that can make a useful decision?
- Are abstractions cheaper than the duplication/complexity they remove?
- Is the code testable through observable behavior?
- Did the change preserve scope and avoid unrelated refactoring?
