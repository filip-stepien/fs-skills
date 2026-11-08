# Vertical slice: organization settings

This anonymized example adapts the feature boundaries repeatedly used in the inspected projects: type-based contracts, application-owned ports, factory-built use cases, Drizzle adapters, a server-only composition root, one Server Action per file, server queries, and small public barrels. It illustrates ownership, not a required scaffold for every app.

The persistence names follow the inspected trainer project: `@/shared/server` exports `createNeonDrizzleDatabase()` and `DrizzleDatabase`; `@/shared` exports `Result`, `ok`, and `err`. Replace the provider factory with the adopting project’s existing one. Framework API semantics must be rechecked in the installed Next.js docs referenced by this skill.

## 1. Domain: organization and permission policy

`src/features/organizations/domain/organization.ts`

```ts
export const OrganizationRole = {
  Owner: 'owner',
  Admin: 'admin',
  Member: 'member',
} as const;

export type OrganizationRole = (typeof OrganizationRole)[keyof typeof OrganizationRole];

export const OrganizationErrorCode = {
  NotFound: 'organization_not_found',
  PermissionDenied: 'permission_denied',
  InvalidName: 'invalid_organization_name',
  Unavailable: 'organization_unavailable',
} as const;

export type OrganizationErrorCode =
  (typeof OrganizationErrorCode)[keyof typeof OrganizationErrorCode];

export type Organization = { id: string; name: string };
export type OrganizationMembership = {
  organizationId: string;
  userId: string;
  role: OrganizationRole;
  joinedAt: string;
};

export const OrganizationNameLength = { min: 2, max: 80 } as const;
export type OrganizationName = string;

export const organizationManagerRoles = [OrganizationRole.Owner, OrganizationRole.Admin] as const;

export function canManageOrganization(role: OrganizationRole): boolean {
  return role === OrganizationRole.Owner || role === OrganizationRole.Admin;
}

export function createOrganizationName(
  rawName: string,
): { ok: true; value: OrganizationName } | { ok: false; error: OrganizationErrorCode } {
  const name = rawName.trim();
  if (name.length < OrganizationNameLength.min || name.length > OrganizationNameLength.max) {
    return { ok: false, error: OrganizationErrorCode.InvalidName };
  }
  return { ok: true, value: name };
}
```

The domain owns the role policy and name invariant; no React, Next.js, Drizzle, or provider imports appear here. If branded types are not part of the project or do not prevent mistakes, use a plain validated string instead. In a strict codebase, avoid assertions by constructing a validated value object through a project-approved pattern; the assertion here is contained immediately after the invariant check.

## 2. Application port and use cases

`src/features/organizations/application/ports/organization-repository.ts`

```ts
import type { Result } from '@/shared';
import type {
  Organization,
  OrganizationErrorCode,
  OrganizationMembership,
  OrganizationName,
  OrganizationRole,
} from '../../domain/organization';

export type OrganizationRepository = {
  findRole(params: { organizationId: string; userId: string }): Promise<OrganizationRole | null>;
  findById(organizationId: string): Promise<Organization | null>;
  listMembers(organizationId: string): Promise<OrganizationMembership[]>;
  rename(params: {
    organizationId: string;
    actorId: string;
    name: OrganizationName;
  }): Promise<Result<Organization, OrganizationErrorCode>>;
};
```

`src/features/organizations/application/use-cases/rename-organization.ts`

```ts
import { err } from '@/shared';
import {
  canManageOrganization,
  createOrganizationName,
  OrganizationErrorCode,
} from '../../domain/organization';
import type { OrganizationRepository } from '../ports/organization-repository';

export type RenameOrganizationData = {
  actorId: string;
  organizationId: string;
  name: string;
};

export function renameOrganizationFactory({
  organizations,
}: {
  organizations: OrganizationRepository;
}) {
  return async ({ actorId, organizationId, name }: RenameOrganizationData) => {
    const actorRole = await organizations.findRole({ organizationId, userId: actorId });
    if (!actorRole || !canManageOrganization(actorRole)) {
      return err(OrganizationErrorCode.PermissionDenied);
    }

    const organizationName = createOrganizationName(name);
    if (!organizationName.ok) return organizationName;

    return organizations.rename({
      organizationId,
      actorId,
      name: organizationName.value,
    });
  };
}
```

`src/features/organizations/application/use-cases/get-organization-settings.ts`

```ts
import { err, ok } from '@/shared';
import { canManageOrganization, OrganizationErrorCode } from '../../domain/organization';
import type { OrganizationRepository } from '../ports/organization-repository';

export function getOrganizationSettingsFactory({
  organizations,
}: {
  organizations: OrganizationRepository;
}) {
  return async ({ organizationId, actorId }: { organizationId: string; actorId: string }) => {
    const actorRole = await organizations.findRole({ organizationId, userId: actorId });
    if (!actorRole) return err(OrganizationErrorCode.PermissionDenied);

    const organization = await organizations.findById(organizationId);
    if (!organization) return err(OrganizationErrorCode.NotFound);

    const members = await organizations.listMembers(organizationId);
    return ok({ organization, members });
  };
}
```

The query use case allows any member to view settings in this example; the mutation use case requires owner/admin. Change the policy to match the product. Neither use case accepts role/actor identity from the browser as trusted facts.

## 3. Drizzle schema and persistence mapper

`src/features/organizations/infrastructure/drizzle/organization-schema.ts`

```ts
import { pgEnum, pgTable, primaryKey, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const organizationRoleEnum = pgEnum('organization_role', ['owner', 'admin', 'member']);

export const organizationsTable = pgTable('organizations', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: text('name').notNull(),
});

export const organizationMembershipsTable = pgTable(
  'organization_memberships',
  {
    organizationId: uuid('organization_id')
      .notNull()
      .references(() => organizationsTable.id, { onDelete: 'cascade' }),
    userId: uuid('user_id').notNull(),
    role: organizationRoleEnum('role').notNull(),
    joinedAt: timestamp('joined_at', { withTimezone: true }).notNull().defaultNow(),
  },
  table => [primaryKey({ columns: [table.organizationId, table.userId] })],
);
```

This slice omits the app’s migration runner and auth-provider user table. The membership’s `userId` is the stable identity supplied by the existing authentication feature; it does not import that provider’s SDK.

`src/features/organizations/infrastructure/mappers/organization-membership.ts`

```ts
import type { OrganizationMembership } from '../../domain/organization';
import { organizationMembershipsTable } from '../drizzle/organization-schema';

type OrganizationMembershipRow = typeof organizationMembershipsTable.$inferSelect;

export function toOrganizationMembership(row: OrganizationMembershipRow): OrganizationMembership {
  return {
    organizationId: row.organizationId,
    userId: row.userId,
    role: row.role,
    joinedAt: row.joinedAt.toISOString(),
  };
}
```

The mapper is justified because database `Date` becomes a serializable domain string. If a selected row is already the exact contract and no invariant/representation changes, return it directly instead of creating a mapper for ceremony.

## 4. Repository adapter and atomic write scope

`src/features/organizations/infrastructure/drizzle/organization-repository.ts`

```ts
import { and, eq, exists, inArray, sql } from 'drizzle-orm';
import { err, ok, type DrizzleDatabase } from '@/shared/server';
import type { OrganizationRepository } from '../../application/ports/organization-repository';
import {
  organizationManagerRoles,
  OrganizationErrorCode,
  type Organization,
} from '../../domain/organization';
import { toOrganizationMembership } from '../mappers/organization-membership';
import { organizationMembershipsTable, organizationsTable } from './organization-schema';

export function createDrizzleOrganizationRepository({
  database,
}: {
  database: DrizzleDatabase;
}): OrganizationRepository {
  return {
    async findRole({ organizationId, userId }) {
      const rows = await database
        .select({ role: organizationMembershipsTable.role })
        .from(organizationMembershipsTable)
        .where(
          and(
            eq(organizationMembershipsTable.organizationId, organizationId),
            eq(organizationMembershipsTable.userId, userId),
          ),
        )
        .limit(1);
      return rows[0]?.role ?? null;
    },

    async findById(organizationId): Promise<Organization | null> {
      const rows = await database
        .select({ id: organizationsTable.id, name: organizationsTable.name })
        .from(organizationsTable)
        .where(eq(organizationsTable.id, organizationId))
        .limit(1);
      return rows[0] ?? null;
    },

    async listMembers(organizationId) {
      const rows = await database
        .select()
        .from(organizationMembershipsTable)
        .where(eq(organizationMembershipsTable.organizationId, organizationId));
      return rows.map(toOrganizationMembership);
    },

    async rename({ organizationId, actorId, name }) {
      const actorCanManage = exists(
        database
          .select({ one: sql`1` })
          .from(organizationMembershipsTable)
          .where(
            and(
              eq(organizationMembershipsTable.organizationId, organizationId),
              eq(organizationMembershipsTable.userId, actorId),
              inArray(organizationMembershipsTable.role, organizationManagerRoles),
            ),
          ),
      );

      const rows = await database
        .update(organizationsTable)
        .set({ name })
        .where(and(eq(organizationsTable.id, organizationId), actorCanManage))
        .returning({ id: organizationsTable.id, name: organizationsTable.name });

      const organization = rows[0];
      return organization ? ok(organization) : err(OrganizationErrorCode.Unavailable);
    },
  };
}
```

The use case checks the business policy and the write includes an atomic organization/manager-membership predicate so a stale permission read cannot authorize an unscoped update. The domain role list is reused by the SQL predicate to avoid drift. Known empty results become typed outcomes; unexpected database failures are not swallowed. In production, choose whether an unauthorized and nonexistent organization should share a non-enumerating outcome.

## 5. Composition root

`src/features/organizations/composition.ts`

```ts
import 'server-only';
import { createNeonDrizzleDatabase } from '@/shared/server';
import { getOrganizationSettingsFactory } from './application/use-cases/get-organization-settings';
import { renameOrganizationFactory } from './application/use-cases/rename-organization';
import { createDrizzleOrganizationRepository } from './infrastructure/drizzle/organization-repository';

const database = createNeonDrizzleDatabase();
const organizations = createDrizzleOrganizationRepository({ database });

export const renameOrganization = renameOrganizationFactory({ organizations });
export const getOrganizationSettings = getOrganizationSettingsFactory({ organizations });
```

The factory is internal and server-only. No DI container is needed for this small assembly; inject provider-specific clients at the composition root.

## 6. Form validation and UI messages

`src/features/organizations/ui/lib/validation.ts`

```ts
import 'server-only';
import { z } from 'zod';
import { OrganizationNameLength } from '../../domain/organization';

const renameOrganizationSchema = z.object({
  organizationId: z.uuid(),
  name: z.string().trim().min(OrganizationNameLength.min).max(OrganizationNameLength.max),
});

export type RenameOrganizationFieldErrors = Partial<
  Record<'organizationId' | 'name', string[]>
>;

export function validateRenameOrganizationForm(formData: FormData) {
  const parsed = renameOrganizationSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) {
    return {
      ok: false as const,
      fieldErrors: z.flattenError(parsed.error).fieldErrors satisfies RenameOrganizationFieldErrors,
    };
  }
  return { ok: true as const, data: parsed.data };
}

export function validateOrganizationId(organizationId: string) {
  const parsed = z.uuid().safeParse(organizationId);
  return parsed.success ? { ok: true as const, data: parsed.data } : { ok: false as const };
}
```

`src/features/organizations/ui/lib/messages.ts`

```ts
import { OrganizationErrorCode } from '../../domain/organization';

export const OrganizationErrorMessages: Record<OrganizationErrorCode, string> = {
  [OrganizationErrorCode.NotFound]: 'This organization is unavailable.',
  [OrganizationErrorCode.PermissionDenied]: 'You cannot change these organization settings.',
  [OrganizationErrorCode.InvalidName]: 'Enter a name between 2 and 80 characters.',
  [OrganizationErrorCode.Unavailable]: 'The organization could not be updated. Refresh and try again.',
};

export const OrganizationActionMessages = {
  Saved: 'Organization settings saved.',
};
```

Validation is a runtime boundary: `FormData` is not trusted because the browser form is typed. Keep domain error codes separate from UI wording, and make the message map exhaustive so a new domain code requires a deliberate user-facing decision.

## 7. Server Action: input → authenticated actor → use case → UI result

`src/features/organizations/ui/actions/rename-organization.ts`

```ts
'use server';

import { revalidatePath } from 'next/cache';
import { getAuthenticatedUserOrRedirect } from '@/features/auth/server';
import { renameOrganization as runRenameOrganization } from '../../composition';
import { OrganizationErrorMessages } from '../lib/messages';
import { validateRenameOrganizationForm } from '../lib/validation';

export type RenameOrganizationActionState = {
  error?: string;
  fieldErrors?: { organizationId?: string[]; name?: string[] };
  success?: boolean;
};

export async function renameOrganizationAction(
  formData: FormData,
): Promise<RenameOrganizationActionState> {
  const actor = await getAuthenticatedUserOrRedirect();
  const validation = validateRenameOrganizationForm(formData);
  if (!validation.ok) return { fieldErrors: validation.fieldErrors };

  const result = await runRenameOrganization({
    actorId: actor.id,
    organizationId: validation.data.organizationId,
    name: validation.data.name,
  });
  if (!result.ok) return { error: OrganizationErrorMessages[result.error] };

  revalidatePath(`/organizations/${validation.data.organizationId}/settings`);
  return { success: true };
}
```

The organization ID is still untrusted input and is validated; the actor ID is not accepted from the form. The use case owns the permission rule. The DB adapter scopes the write atomically. The action maps outcomes and calls the relevant invalidation API; consult the exact installed-version docs for cache semantics. If a successful workflow should navigate elsewhere, use a route helper and the documented redirect control flow after required invalidation.

## 8. Server query: authorize and return a minimal view DTO

`src/features/organizations/ui/queries/get-organization-settings-or-redirect.ts`

```ts
import 'server-only';
import { redirect } from 'next/navigation';
import { getAuthenticatedUserOrRedirect } from '@/features/auth/server';
import { getOrganizationSettings } from '../../composition';
import type { OrganizationRole } from '../../domain/organization';
import { validateOrganizationId } from '../lib/validation';

export type OrganizationSettingsView = {
  organization: { id: string; name: string };
  members: { userId: string; role: OrganizationRole }[];
};

export async function getOrganizationSettingsOrRedirect({
  organizationId,
}: {
  organizationId: string;
}): Promise<OrganizationSettingsView> {
  const actor = await getAuthenticatedUserOrRedirect();
  const validation = validateOrganizationId(organizationId);
  if (!validation.ok) redirect('/organizations');

  const result = await getOrganizationSettings({
    organizationId: validation.data,
    actorId: actor.id,
  });
  if (!result.ok) redirect('/organizations');

  return {
    organization: {
      id: result.value.organization.id,
      name: result.value.organization.name,
    },
    members: result.value.members.map(member => ({
      userId: member.userId,
      role: member.role,
    })),
  };
}
```

The query checks route input and membership before data crosses into rendering. The DTO omits `joinedAt` because this screen does not display it. Do not cache user-specific results unless you have verified the installed cache model and isolated authorization/data keys correctly.

## 9. Client hook adapter and form component

The action itself accepts only `FormData`. This hook adapts it to React’s `useActionState` state/pending contract; it is useful here because the form renders field/action feedback. Do not add this wrapper to every action automatically.

`src/features/organizations/ui/hooks/use-rename-organization.ts`

```tsx
'use client';

import { useActionState } from 'react';
import {
  renameOrganizationAction,
  type RenameOrganizationActionState,
} from '../actions/rename-organization';

const initialState: RenameOrganizationActionState = {};

async function adaptRenameAction(
  _previousState: RenameOrganizationActionState,
  formData: FormData,
) {
  return renameOrganizationAction(formData);
}

export function useRenameOrganization() {
  return useActionState(adaptRenameAction, initialState);
}
```

`src/features/organizations/ui/components/rename-organization-form.tsx`

```tsx
'use client';

import { useRenameOrganization } from '../hooks/use-rename-organization';

export function RenameOrganizationForm({
  organizationId,
  initialName,
}: {
  organizationId: string;
  initialName: string;
}) {
  const [state, formAction, isPending] = useRenameOrganization();

  return (
    <form action={formAction} aria-busy={isPending}>
      <input type='hidden' name='organizationId' value={organizationId} />
      <label htmlFor='organization-name'>Organization name</label>
      <input
        id='organization-name'
        name='name'
        defaultValue={initialName}
        required
        minLength={2}
        maxLength={80}
        aria-invalid={Boolean(state.fieldErrors?.name)}
        aria-describedby={state.fieldErrors?.name ? 'organization-name-error' : undefined}
      />
      {state.fieldErrors?.name?.[0] ? (
        <p id='organization-name-error' role='alert'>{state.fieldErrors.name[0]}</p>
      ) : null}
      {state.error ? <p role='alert'>{state.error}</p> : null}
      {state.success ? <p role='status'>Organization settings saved.</p> : null}
      <button type='submit' disabled={isPending}>
        {isPending ? 'Saving…' : 'Save'}
      </button>
    </form>
  );
}
```

The hidden organization ID selects a resource; it is validated and authorized server-side. No hidden actor ID or role is sent. The Client Component handles interaction and feedback, not business policy or database calls.

## 10. Server-rendered member list and App Router page

`src/features/organizations/ui/components/organization-members-list.tsx`

```tsx
import type { OrganizationSettingsView } from '../queries/get-organization-settings-or-redirect';

export function OrganizationMembersList({
  members,
}: {
  members: OrganizationSettingsView['members'];
}) {
  return (
    <ul aria-label='Organization members'>
      {members.map(member => (
        <li key={member.userId}>
          <span>{member.userId}</span>
          <span>{member.role}</span>
        </li>
      ))}
    </ul>
  );
}
```

`src/features/organizations/index.ts`

```ts
export { RenameOrganizationForm } from './ui/components/rename-organization-form';
export type { Organization, OrganizationMembership, OrganizationRole } from './domain/organization';
```

`src/features/organizations/server.ts`

```ts
import 'server-only';

export {
  getOrganizationSettingsOrRedirect,
  type OrganizationSettingsView,
} from './ui/queries/get-organization-settings-or-redirect';
export { OrganizationMembersList } from './ui/components/organization-members-list';
```

`src/features/organizations/client.ts` is optional; create it only if another feature must import a browser-only hook:

```ts
import 'client-only';

export { useRenameOrganization } from './ui/hooks/use-rename-organization';
```

`src/app/organizations/[organizationId]/settings/page.tsx`

```tsx
import { RenameOrganizationForm } from '@/features/organizations';
import {
  getOrganizationSettingsOrRedirect,
  OrganizationMembersList,
} from '@/features/organizations/server';

export default async function OrganizationSettingsPage({
  params,
}: {
  params: Promise<{ organizationId: string }>;
}) {
  const { organizationId } = await params;
  const settings = await getOrganizationSettingsOrRedirect({ organizationId });

  return (
    <main>
      <h1>{settings.organization.name} settings</h1>
      <RenameOrganizationForm
        organizationId={settings.organization.id}
        initialName={settings.organization.name}
      />
      <h2>Members</h2>
      <OrganizationMembersList members={settings.members} />
    </main>
  );
}
```

The route has no policy or database logic: it awaits route input, calls the server query, and composes UI. The `params` shape is framework-version-sensitive; this example follows the installed docs inspected for the source projects. Recheck that API before copying to another version.

## 11. Dependency map

```text
app page ────────> organizations/index.ts + organizations/server.ts
                         │                      │
                         │                      └── ui query ──> composition
                         └── UI components                     │
                                                               ├── use cases
client form ──> client hook ──> Server Action ──────────────────┘
                                                               │
domain <── application use cases ──> application port <── Drizzle adapter
                                                               │
                                                        composition root
```

Forbidden arrows include domain→React/Next/Drizzle, application→UI/framework, another feature→this feature’s deep paths, and client code→repository/provider. The composition root is the only place that intentionally joins application contracts to concrete infrastructure.

## 12. Adaptation and verification

- Replace the auth helper, shared Result/database primitives, route helpers, message language, and UI primitives with the project’s established conventions.
- Keep auth provider SDKs and ORM row types out of application/domain contracts.
- If there is no meaningful policy or external boundary, use a lighter architecture rather than copying every folder.
- Consult `authoritative-docs.md` for form/action signatures, redirect control flow, cache invalidation, Client Component boundaries, and async route params in the installed Next.js version.
- Check that every write validates input, derives actor identity from trusted auth, enforces business authorization, and scopes its persistence operation. Review the public exports and ensure server-only modules cannot enter a client bundle.
