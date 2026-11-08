# TypeScript contracts, results, and validation

Examples use a fictional organization membership feature. Keep the source project’s validation library and error conventions; Zod below reflects a common runtime boundary, not a mandatory dependency.

## Result and domain error codes

```ts
export type Result<T, E> =
  | { ok: true; value: T }
  | { ok: false; error: E };

export const MembershipErrorCode = {
  OrganizationNotFound: 'organization_not_found',
  MemberNotFound: 'member_not_found',
  PermissionDenied: 'permission_denied',
  InvalidRoleChange: 'invalid_role_change',
} as const;

export type MembershipErrorCode =
  (typeof MembershipErrorCode)[keyof typeof MembershipErrorCode];
```

The constant object gives call sites a discoverable member and the derived union constrains outcomes. A plain union of string literals is also reasonable in a project that does not need a runtime dictionary. Avoid duplicating one code as an enum, string union, and message dictionary in the domain.

An application operation can return expected business outcomes without throwing:

```ts
type OrganizationRole = 'owner' | 'admin' | 'member';
type Membership = { organizationId: string; userId: string; role: OrganizationRole };

type ChangeMemberRoleData = {
  actorId: string;
  organizationId: string;
  memberId: string;
  role: OrganizationRole;
};

type ChangeMemberRole = (
  data: ChangeMemberRoleData,
) => Promise<Result<Membership, MembershipErrorCode>>;
```

`PermissionDenied` and `MemberNotFound` are expected alternatives that the caller can map. A database connection outage is not silently converted to `MemberNotFound`; let it reach the error boundary unless the application has an explicit recovery outcome.

## Application port and typed use case

```ts
type MembershipRepository = {
  findRole(params: {
    organizationId: string;
    userId: string;
  }): Promise<OrganizationRole | null>;
  updateRole(params: {
    organizationId: string;
    memberId: string;
    role: OrganizationRole;
  }): Promise<Result<Membership, MembershipErrorCode>>;
};

function canManageMembers(role: OrganizationRole): boolean {
  return role === 'owner' || role === 'admin';
}

function changeMemberRoleFactory({
  memberships,
}: {
  memberships: MembershipRepository;
}): ChangeMemberRole {
  return async data => {
    const actorRole = await memberships.findRole({
      organizationId: data.organizationId,
      userId: data.actorId,
    });

    if (!actorRole || !canManageMembers(actorRole)) {
      return { ok: false, error: MembershipErrorCode.PermissionDenied };
    }

    return memberships.updateRole({
      organizationId: data.organizationId,
      memberId: data.memberId,
      role: data.role,
    });
  };
}
```

The actor ID must come from the authenticated server session, never a client-supplied role/identity field. A real concurrent membership change may require the write to re-check authorization atomically in a transaction/adapter. Keep the port boundary scoped by tenant/organization so a caller cannot accidentally update another tenant’s member.

## Exhaustive result handling

```ts
function assertNever(value: never): never {
  throw new Error(`Unhandled membership outcome: ${String(value)}`);
}

function describeMembershipError(error: MembershipErrorCode): string {
  switch (error) {
    case MembershipErrorCode.OrganizationNotFound:
      return 'This organization is unavailable.';
    case MembershipErrorCode.MemberNotFound:
      return 'This member is no longer available.';
    case MembershipErrorCode.PermissionDenied:
      return 'You cannot change this member’s role.';
    case MembershipErrorCode.InvalidRoleChange:
      return 'That role change is not allowed.';
    default:
      return assertNever(error);
  }
}
```

In a real app, keep user-facing strings in the feature’s UI message dictionary, not in a domain/application module. `assertNever` makes adding a code visible at compile time. If the project uses exhaustive switch linting, follow that convention.

## Runtime validation at an untrusted boundary

```ts
import { z } from 'zod';

const changeMemberRoleSchema = z.object({
  organizationId: z.uuid(),
  memberId: z.uuid(),
  role: z.enum(['owner', 'admin', 'member']),
});

function parseChangeMemberRoleData(raw: unknown) {
  const parsed = changeMemberRoleSchema.safeParse(raw);
  if (!parsed.success) return { ok: false as const, issues: parsed.error.issues };
  return { ok: true as const, data: parsed.data };
}
```

Do not write `raw as ChangeMemberRoleData`: that silences checking without checking the runtime value. Validate at entry points (forms, route params, webhooks, external APIs), then pass typed data inward. The exact validator and field-error mapping belong to the project convention.

## Persistence row to domain mapping

Keep ORM row types inside the adapter. Map when persistence representation differs from the application contract:

```ts
type MembershipRow = {
  organizationId: string;
  userId: string;
  role: OrganizationRole;
  createdAt: Date;
};

function toMembership(row: MembershipRow): Membership & { createdAt: string } {
  return {
    organizationId: row.organizationId,
    userId: row.userId,
    role: row.role,
    createdAt: row.createdAt.toISOString(),
  };
}
```

If the row and contract are already identical and no boundary/invariant is clarified, returning a duplicate object adds noise. If database text can contain untrusted/legacy values, validate the role at the adapter boundary instead of asserting it is an `OrganizationRole`.

## Narrow external values and avoid unsafe escape hatches

```ts
function readOrganizationId(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = raw.trim();
  return value.length > 0 ? value : null;
}
```

This simple parser is enough if non-empty strings are the actual invariant. Use a schema validator for richer shape/field errors. Do not add branded ID types, generic parser frameworks, or `as unknown as T` unless they prevent a demonstrated category/safety bug and have a clear runtime boundary.
