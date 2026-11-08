# Recognizable patterns, used deliberately

Prefer a familiar pattern when it makes ownership and dependencies easier to understand. The examples use TypeScript and a feature-based, layered application. They are illustrative adaptations of patterns visible in `trainer` (application ports, repository adapters, use-case factories, and feature composition roots) and `weekend.jobs.v2` (feature-owned provider APIs). They are not a required folder layout.

Patterns overlap: a provider gateway can be an adapter in a ports-and-adapters design; a composition root may use factories; a feature's public API may serve as a facade. Use names that match the actual role. Do not add an interface, class, folder, or indirection solely to make a pattern visible.

## Repository

**Problem:** application behavior needs to load or save domain/application records without depending on a database schema, ORM, or query syntax.

**Use when:** persistence queries are a meaningful boundary, data ownership belongs to a feature, or use cases need focused tests independent of the database.

**Avoid when:** a small application has one local query with no reusable boundary, or a repository would merely forward a single call without mapping, policy, or independent ownership. Do not create a repository for every table by default.

**Owner and direction:** the contract belongs to the consuming application/feature. Its infrastructure adapter depends inward on that contract and outward on the database. Application/domain code must not import the ORM.

```ts
// features/memberships/application/ports/membership-repository.ts
export type Membership = {
  id: string;
  organizationId: string;
  userId: string;
  status: "active" | "invited";
};

export type MembershipRepository = {
  findActiveMember(params: {
    organizationId: string;
    userId: string;
  }): Promise<Membership | null>;
  save(membership: Membership): Promise<void>;
};
```

```ts
// Infrastructure adapter. `Database` and `memberships` are imported from the
// project's typed Drizzle client and schema; the application contract is imported above.
export function createDrizzleMembershipRepository({ db }: { db: Database }): MembershipRepository {
  return {
    async findActiveMember({ organizationId, userId }) {
      const row = await db.query.memberships.findFirst({
        where: (table, { and, eq }) => and(
          eq(table.organizationId, organizationId),
          eq(table.userId, userId),
          eq(table.status, "active"),
        ),
      });

      if (!row) return null;
      return {
        id: row.id,
        organizationId: row.organizationId,
        userId: row.userId,
        status: row.status,
      };
    },
    async save(membership) {
      await db.insert(memberships).values({
        id: membership.id,
        organizationId: membership.organizationId,
        userId: membership.userId,
        status: membership.status,
      });
    },
  };
}
```

**Unnecessary version:** `BaseRepository<T>` exposes generic `find`, `save`, `update`, `delete`, and ORM query builders for every table, even when callers need only one feature-owned operation. It hides data ownership and leaks persistence details. Prefer a small feature contract that names real operations.

## Ports and Adapters (Hexagonal Architecture)

**Problem:** business behavior must stay independent of delivery mechanisms and external effects while still being callable through them.

**Use when:** the feature has business rules worth isolating and one or more meaningful external boundaries, such as persistence, email, or a provider API.

**Avoid when:** adding a port/adapter pair only wraps a stable pure function or a trivial local operation. A simple app may keep a direct call at its server boundary.

**Owner and direction:** the application/domain core owns the contracts it needs. Inbound adapters (route, action, CLI) call inward; outbound adapters (database, mail provider) implement inward-owned ports. The core never imports adapters or framework code.

```ts
// Application-owned outbound port.
type InvitationMailer = {
  sendInvitation(params: { email: string; organizationName: string; inviteUrl: string }): Promise<void>;
};

type MembershipRepository = {
  saveInvitation(params: { organizationId: string; email: string; token: string }): Promise<void>;
};

function inviteMemberFactory({
  memberships,
  mailer,
}: {
  memberships: MembershipRepository;
  mailer: InvitationMailer;
}) {
  return async (params: {
    organizationId: string;
    email: string;
    organizationName: string;
    inviteUrl: string;
    token: string;
  }) => {
    await memberships.saveInvitation(params);
    await mailer.sendInvitation(params);
  };
}
```

The action or query is an inbound adapter; a mail implementation is an outbound adapter. Their composition belongs at the application boundary. Keep business authorization and invariants in the core, not in an adapter that can be bypassed.

**Unnecessary version:** a `StringTrimmingPort` and `StringTrimmingAdapter` around `value.trim()` add files and dependency wiring without isolating a real boundary. Call the language function directly.

## Provider / Gateway

**Problem:** an external vendor's API, error model, identifiers, or lifecycle should not leak into business rules and callers.

**Use when:** an integration has meaningful request/response mapping, retries, vendor errors, authentication, or a plausible provider change. A gateway is commonly an infrastructure adapter implementing an application-owned provider port.

**Avoid when:** a one-off, stable call has no meaningful translation or policy and adding a gateway would only rename the vendor SDK method. Still keep credentials and security-sensitive calls server-side.

**Owner and direction:** the application owns the provider capability it needs; infrastructure owns the vendor-specific gateway. Application depends on its neutral port; the gateway depends on that port and the vendor SDK. Do not expose vendor SDK types from a feature public API.

```ts
type PaymentProvider = {
  createCheckout(params: {
    paymentId: string;
    amountCents: number;
    returnUrl: string;
  }): Promise<{ checkoutUrl: string; providerReference: string }>;
};

export function createStripePaymentGateway({ stripe }: { stripe: StripeClient }): PaymentProvider {
  return {
    async createCheckout({ paymentId, amountCents, returnUrl }) {
      const session = await stripe.checkout.sessions.create({
        client_reference_id: paymentId,
        mode: "payment",
        line_items: [{ price_data: { currency: "pln", unit_amount: amountCents, product_data: { name: "Booking" } }, quantity: 1 }],
        success_url: returnUrl,
      });

      if (!session.url) throw new Error("Payment provider returned no checkout URL");
      return { checkoutUrl: session.url, providerReference: session.id };
    },
  };
}
```

Translate provider-specific statuses and expected errors at this boundary when the application needs stable outcomes. Keep retries and idempotency aligned with the actual provider contract; a gateway name alone does not provide those guarantees.

**Unnecessary version:** `PaymentProviderGatewayManager` wraps one `stripe.checkout.sessions.create` call, returns the raw Stripe response, and is used by only one function. It adds a name but no neutral contract or translation. Either make it a real provider boundary or call the SDK at the established integration boundary.

## Strategy

**Problem:** callers need one behavior, but several interchangeable algorithms vary independently and the correct one is selected from runtime/domain context.

**Use when:** multiple policies have distinct rules, are selected by trusted data/configuration, and should evolve or be tested independently. Functions in a map can be strategies; classes are not required.

**Avoid when:** there is one implementation, or a small fixed set is clearer as an exhaustive `switch`. Do not create a strategy registry for hypothetical future variation.

**Owner and direction:** the layer that owns the changing decision owns the strategy contract. Domain policy strategies belong in domain/application; provider implementation strategies belong in infrastructure. The selector depends on the common contract, and concrete strategies satisfy it.

```ts
type GeocodingProvider = {
  findCityLocationByPlaceId(placeId: string): Promise<CityLocation | null>;
};

type GeocodingMode = "live" | "mock";

const geocodingProviders: Record<GeocodingMode, GeocodingProvider> = {
  live: geoapifyGeocodingProvider,
  mock: mockGeocodingProvider,
};

const geocodingProvider = geocodingProviders[config.geocodingMode];
const resolveCity = resolveCityFactory({ cities: cityRepository, geocodingProvider });
```

This is justified because the same use case has interchangeable live and mock geocoding implementations selected by configuration. The example follows the provider selection and composition style demonstrated by `weekend.jobs.v2`. The strategies can be plain objects/functions; they need not be classes. If there is only one implementation, inject it directly and do not create a strategy registry.

**Unnecessary version:** `StrategyFactory`, `StrategyResolver`, one class per branch, and a plugin registry for two fixed expressions. The extra indirection makes a simple rule harder to inspect.

## Factory

**Problem:** creating a usable object/function requires assembling dependencies or applying non-trivial construction rules.

**Use when:** a use case needs explicit dependencies, construction is reused, or creation validates/normalizes a domain object. A `createXFactory` function returning a use-case operation is a recognizable functional factory.

**Avoid when:** an object literal, constructor, or direct function call is already clear. Do not add a factory around every type or simple value.

**Owner and direction:** the module that owns the created use case/entity owns the factory. The factory may depend on application contracts; infrastructure should not be constructed inside the use case. A composition root supplies concrete dependencies.

```ts
type BookingRepository = {
  findById(id: string): Promise<{ id: string; status: "confirmed" | "cancelled" } | null>;
  save(booking: { id: string; status: "confirmed" | "cancelled" }): Promise<void>;
};

export function cancelBookingFactory({ bookings }: { bookings: BookingRepository }) {
  return async (bookingId: string) => {
    const booking = await bookings.findById(bookingId);
    if (!booking) return { ok: false as const, error: { code: "BOOKING_NOT_FOUND" as const } };
    if (booking.status === "cancelled") return { ok: true as const, value: booking };

    const cancelledBooking = { ...booking, status: "cancelled" as const };
    await bookings.save(cancelledBooking);
    return { ok: true as const, value: cancelledBooking };
  };
}
```

**Unnecessary version:** `createBookingIdFactory()` returns `() => crypto.randomUUID()` for one caller and adds no deterministic seam, policy, or reusable construction. Call the generator directly unless a real boundary or test requirement justifies injection.

## Composition Root

**Problem:** concrete implementations must be connected to abstract use-case dependencies somewhere without making the core know infrastructure details.

**Use when:** a feature has meaningful ports/adapters and the wiring should be defined once and reused by its actions, queries, or other entry points.

**Avoid when:** a direct dependency at one simple entry point is clearer than a separate composition module. Do not build a service container or DI framework merely to wire a few dependencies.

**Owner and direction:** the application entry/composition boundary owns assembly. It may import both application factories and concrete infrastructure adapters; dependencies point from the composition root to both sides. Domain and application modules never import the composition root.

```ts
// features/bookings/composition.ts (server-only in a Next.js project)
const bookings = createDrizzleBookingRepository({ db });

export const cancelBooking = cancelBookingFactory({ bookings });
export const getBooking = getBookingFactory({ bookings });
```

This follows the feature composition style used in `trainer`: UI boundaries consume composed operations; adapters remain internal. Create the root at the narrowest useful scope, and account for request-scoped clients when the framework/provider requires them.

**Unnecessary version:** every route constructs its own repository, use case, and client, or a global `Container.register("bookingRepository", ...)` is added to wire one use case. Centralize real wiring without introducing a framework.

## Facade

**Problem:** consumers need a small, stable entry point to a cohesive subsystem whose internal operations should remain private.

**Use when:** a feature has multiple internal actions/queries/adapters and other modules need a deliberate public API. A feature `server.ts` or `index.ts` can serve as a facade without a class named `Facade`.

**Avoid when:** the facade republishes every internal function, combines unrelated features, or simply forwards one call with no boundary value.

**Owner and direction:** the feature that owns the capability owns the facade/public API. Internal implementation can depend on its own domain/application modules; consumers depend on the public API and must not import private infrastructure paths. The facade should not create reverse dependencies between features.

```ts
// features/memberships/server.ts
export { inviteMember } from "./composition";
export { listOrganizationMembers } from "./ui/queries/list-organization-members";
export type { MembershipSummary } from "./application/contracts/membership-summary";
```

The public surface is intentionally small; the database repository and provider adapters stay private. This can be a few explicit exports, not another orchestration layer.

**Unnecessary version:** `ApplicationFacade` gathers organizations, bookings, payments, and users into one object, exposing all implementation methods. It becomes a service locator and defeats feature ownership. Keep public APIs feature-scoped.

## Review before introducing a pattern

Direct code is often the right choice. For example, a small server-rendered settings page with one read and no repeated policy can query its database at the route boundary:

```ts
export async function getOrganizationName(organizationId: string): Promise<string | null> {
  const organization = await db.query.organizations.findFirst({
    where: (table, { eq }) => eq(table.id, organizationId),
    columns: { name: true },
  });
  return organization?.name ?? null;
}
```

Adding `OrganizationNameService`, `OrganizationNameRepository`, and a port for this one projection would not protect a meaningful rule or boundary. If authorization, multiple queries, reusable feature behavior, or a volatile integration appears, revisit the boundary then.

- Is the problem the pattern is known to solve present in this code?
- Does the abstraction have a clear owner and dependency direction?
- Is there more than one real implementation, meaningful volatility, or a contract worth protecting?
- Does the familiar name make the responsibility easier to understand?
- Would direct code or an existing project pattern be simpler?
- Does this change preserve established feature boundaries rather than creating a competing architecture?
