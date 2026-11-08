# SOLID and refactoring examples

These examples use TypeScript-like contracts and fictional organization membership/payment flows. Adapt names and error conventions to the project. They illustrate decisions, not mandatory class structures.

## Single Responsibility: separate changes, keep orchestration

**Before:** formatting a receipt, writing to storage, and sending an email are mixed into a function that is hard to test without all three systems.

```ts
type Order = { id: string; email: string; items: { priceCents: number }[] };
type Receipt = { orderId: string; totalCents: number };
type ReceiptDatabase = { insert(receipt: Receipt): Promise<void> };
type ReceiptMailer = { send(email: string, subject: string): Promise<void> };

async function completeCheckoutBefore(
  order: Order,
  database: ReceiptDatabase,
  mailer: ReceiptMailer,
) {
  const receipt = {
    orderId: order.id,
    totalCents: order.items.reduce((sum, item) => sum + item.priceCents, 0),
  };
  await database.insert(receipt);
  await mailer.send(order.email, `Receipt total: ${receipt.totalCents} cents`);
  return receipt;
}
```

**After:** extract responsibilities with separate policies/dependencies; the use-case can still coordinate the whole user goal.

```ts
function calculateTotalCents(items: Order['items']): number {
  return items.reduce((sum, item) => sum + item.priceCents, 0);
}

function buildReceipt(order: Order): Receipt {
  return { orderId: order.id, totalCents: calculateTotalCents(order.items) };
}

async function completeCheckout(
  order: Order,
  saveReceipt: (receipt: Receipt) => Promise<void>,
  sendReceipt: (email: string, receipt: Receipt) => Promise<void>,
): Promise<Receipt> {
  const receipt = buildReceipt(order);
  await saveReceipt(receipt);
  await sendReceipt(order.email, receipt);
  return receipt;
}
```

**Why/trade-off:** receipt calculation, persistence, and email delivery have different reasons to change. Keep orchestration together because it expresses the use case. Do not split every line into a helper. If the project already has an application port/use-case structure, the persistence and email contracts belong to that existing boundary; see `software-architecture` for layer ownership.

## Open/Closed: extend only when variation is real

For a closed set of a few domain states, an exhaustive switch is often best. Do not hide a small union behind a plugin system. If a growing, independently configured set of payment providers changes at runtime, an explicit strategy registry can isolate provider variation:

```ts
type PaymentMethod = 'card' | 'bank-transfer';
type PaymentResult = { ok: true; reference: string } | { ok: false; reason: string };
type Charge = (amountCents: number) => Promise<PaymentResult>;

const chargeCard: Charge = async amountCents => ({
  ok: true,
  reference: `card-${amountCents}`,
});
const chargeByBankTransfer: Charge = async amountCents => ({
  ok: true,
  reference: `transfer-${amountCents}`,
});

const paymentMethods: Record<PaymentMethod, Charge> = {
  card: chargeCard,
  'bank-transfer': chargeByBankTransfer,
};

function charge(method: PaymentMethod, amountCents: number) {
  return paymentMethods[method](amountCents);
}
```

**Counterexample:** introducing a generic `PluginManager<Context, Resolver, Hook>` for two fixed methods. **Why/trade-off:** the map avoids editing an unrelated coordinator as actual providers grow, but each strategy is another contract and must preserve common error/authorization behavior. For a stable set of two simple choices, a `switch` is clearer.

## Liskov Substitution: implementations keep the same contract

If a repository contract says a missing membership returns `null`, every implementation must do so; a test fake that returns an empty object or a database adapter that throws for ordinary absence breaks callers.

```ts
type Membership = { id: string; organizationId: string; userId: string };
const testMemberships: Membership[] = [];

type MembershipReader = {
  findById(id: string): Promise<Membership | null>;
};

const memoryReader: MembershipReader = {
  async findById(id) {
    return testMemberships.find(membership => membership.id === id) ?? null;
  },
};
```

The SQL adapter and test fake must agree on absence, ordering, and failure semantics. **Exception:** provider-specific capabilities need a separate contract rather than pretending every implementation supports them. Add contract tests when several adapters implement the same port.

## Interface Segregation: make contracts match consumers

**Before:** a read-only query receives a huge repository object and could accidentally call delete/update operations.

```ts
type Organization = { id: string; name: string };
type Membership = { id: string; organizationId: string; userId: string };
type OrganizationName = string;
type OrganizationError = 'not-found' | 'invalid-name';
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

type OrganizationRepository = {
  findById(id: string): Promise<Organization | null>;
  listMembers(id: string): Promise<Membership[]>;
  rename(id: string, name: string): Promise<void>;
  delete(id: string): Promise<void>;
};
```

**After:** split contracts when consumers have distinct needs:

```ts
type OrganizationReader = {
  findById(id: string): Promise<Organization | null>;
};

type OrganizationWriter = {
  rename(id: string, name: OrganizationName): Promise<Result<Organization, OrganizationError>>;
};
```

**Why/trade-off:** narrow ports make required capabilities explicit and fakes smaller. Do not fragment one cohesive repository into one type per method just to satisfy a slogan; split when consumers or change ownership differ.

## Dependency Inversion: depend on a useful boundary

**Before:** a use case imports Drizzle and owns a query, making the rule depend on persistence and difficult to test alone.

```ts
async function renameOrganization(id: string, name: string) {
  const rows = await db.update(organizations).set({ name }).where(eq(organizations.id, id));
  return rows;
}
```

**After:** the application operation depends on a port; infrastructure implements it and a composition root supplies the implementation.

```ts
type Organization = { id: string; name: string };
type OrganizationName = string;
type OrganizationError = 'not-found' | 'invalid-name';
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

type OrganizationWriter = {
  rename(params: { id: string; name: OrganizationName }):
    Promise<Result<Organization, OrganizationError>>;
};

type RenameOrganizationData = { id: string; name: OrganizationName };

function renameOrganizationFactory({ organizations }: { organizations: OrganizationWriter }) {
  return (data: RenameOrganizationData) => organizations.rename(data);
}
```

The boundary is justified because persistence is external and needs isolated testing. A single local calculation does not need a repository port.

## DRY: share a policy, not just matching text

**Before:** organization invite and member management each implement the same role rule, then disagree after one copy changes.

```ts
type OrganizationRole = 'owner' | 'admin' | 'member';

function canInviteBefore(role: OrganizationRole): boolean {
  return role === 'owner' || role === 'admin';
}

function canManageMemberBefore(role: OrganizationRole): boolean {
  return role === 'owner' || role === 'admin';
}
```

**After:** centralize the same business fact and call it at both sites:

```ts
function canManageMembers(role: OrganizationRole): boolean {
  return role === 'owner' || role === 'admin';
}
```

If two code blocks look similar but represent different policies, keep them separate and name the distinction. Duplication is safer than a shared abstraction whose callers need different behavior.

## KISS and YAGNI: do not create extension points for imagined needs

**Counterexample:** a one-off organization-name check introduces `ValidationPipeline`, a registry, pluggable rules, configuration, and a builder.

```ts
function isValidOrganizationName(name: string): boolean {
  return name.trim().length >= 2 && name.trim().length <= 80;
}
```

Start with the direct rule. Add multiple validators/configuration only when the project has real varying policies or callers. This keeps the path inspectable; the exception is a framework already established by the project or a concrete extension requirement.

## Naming and parameters: reveal meaning at the call site

**Before:** positional strings/numbers can be swapped and a noun does not describe an operation.

```ts
const total = calc(id, name, 1200, 100);
```

**After:** use a domain verb and named data when several values belong together:

```ts
const totalCents = calculateInvoiceTotal({
  subtotalCents: 1200,
  discountCents: 100,
});
```

Use the verb that matches the action; examples such as `find`, `read`, `calculate`, or `update` are not an exhaustive vocabulary. A small call like `parse(text)` may remain positional.

## A React component with business logic

**Before:** a component both decides permission and renders controls, so another entry point can bypass the rule and the UI is hard to test.

```tsx
type Member = { id: string; name: string };
type Props = {
  member: Member;
  currentRole: 'owner' | 'admin' | 'member';
  onRemove(memberId: string): void;
};

function MemberActions({ member, currentRole, onRemove }: Props) {
  const canRemove = currentRole === 'owner' || currentRole === 'admin';
  return canRemove ? (
    <button type="button" onClick={() => onRemove(member.id)}>Remove {member.name}</button>
  ) : null;
}
```

**After:** put authoritative permission in a domain/application policy; the UI receives a presentation capability or hides a control for usability. The application operation repeats authorization before mutation.

```tsx
type Member = { id: string; name: string };
type MemberActionsProps = {
  memberId: string;
  canRemove: boolean;
  onRemove(memberId: string): void;
};

function MemberActions({ memberId, canRemove, onRemove }: MemberActionsProps) {
  return canRemove ? (
    <button type="button" onClick={() => onRemove(memberId)}>Remove member</button>
  ) : null;
}
```

**Why/trade-off:** UI can reflect permissions but is not a security boundary. Avoid passing role logic into many components. For a trivial presentation-only condition, keep it local.

## Refactor in behavior-preserving steps

Before extracting behavior, capture its observed behavior in a test. Then make one structural change and run the smallest relevant validation. For example, extract a pure name formatter without changing trimming, spacing, or empty-name behavior:

```ts
function formatMemberName(firstName: string, lastName: string): string {
  return `${firstName.trim()} ${lastName.trim()}`;
}
```

If the current output for blank names is odd, first preserve it during extraction; make a separate behavior change with an explicit requirement. This reduces the chance that a cleanup hides a regression.

## Review questions

- Which concrete requirement or change reason justifies the helper/contract/pattern?
- Is business policy duplicated, or are two similar blocks actually different rules?
- Can a caller understand a function's behavior, units, and side effects from its name and parameters?
- Do fakes/adapters match the same public contract?
- Does the UI only represent a permission, with enforcement still at the use-case/data boundary?
- Is the change behavior-preserving, or are structural and behavior changes mixed?
