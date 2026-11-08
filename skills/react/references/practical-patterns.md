# Practical React patterns

These examples use React 19-style APIs and ordinary TypeScript. Follow the React version and UI conventions already installed in the project. They focus on component ownership; Next.js server/client and data boundaries belong to the `nextjs` skill.

## 1. Keep a component focused

**Before:** one component owns selection, filtering, invitation, permission-based control visibility, and list rendering. Hiding the remove button is not authorization, and the component has several independent reasons to change.

```tsx
import { useState } from 'react';

type Member = { id: string; name: string; role: 'owner' | 'admin' | 'member' };
type MemberDirectoryProps = {
  members: Member[];
  currentUserId: string;
  onInvite(): void;
  onRemove(memberId: string): void;
};

export function MemberDirectory({ members, currentUserId, onInvite, onRemove }: MemberDirectoryProps) {
  const [query, setQuery] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const visibleMembers = members
    .filter(member => member.name.toLowerCase().includes(query.toLowerCase()))
    .sort((left, right) => left.name.localeCompare(right.name));
  const canManage = members.some(
    member => member.id === currentUserId && member.role !== 'member',
  );

  return (
    <section>
      <input value={query} onChange={event => setQuery(event.target.value)} />
      <button type="button" onClick={onInvite}>Invite</button>
      <ul>
        {visibleMembers.map(member => (
          <li key={member.id}>
            <label>
              <input
                type="checkbox"
                checked={selectedIds.includes(member.id)}
                onChange={event => setSelectedIds(current =>
                  event.target.checked
                    ? [...current, member.id]
                    : current.filter(id => id !== member.id),
                )}
              />
              {member.name}
            </label>
            {canManage ? (
              <button type="button" onClick={() => onRemove(member.id)}>Remove</button>
            ) : null}
          </li>
        ))}
      </ul>
    </section>
  );
}
```

**After:** the owner composes focused UI pieces and keeps only the state needed to coordinate them. Permission shown by the UI is a convenience; the server operation must authorize again.

```tsx
import { useState } from 'react';

type Member = { id: string; name: string; role: 'owner' | 'admin' | 'member' };
type FocusedMemberDirectoryProps = {
  members: Member[];
  canManageMembers: boolean;
  onInvite(): void;
  onRemove(memberId: string): void;
};

export function FocusedMemberDirectory({
  members,
  canManageMembers,
  onInvite,
  onRemove,
}: FocusedMemberDirectoryProps) {
  const [query, setQuery] = useState('');
  const visibleMembers = members
    .filter(member => member.name.toLowerCase().includes(query.toLowerCase()))
    .sort((left, right) => left.name.localeCompare(right.name));

  return (
    <section aria-label="Members">
      <MemberSearch value={query} onChange={setQuery} />
      {canManageMembers ? <button type="button" onClick={onInvite}>Invite</button> : null}
      <MemberList
        members={visibleMembers}
        canManageMembers={canManageMembers}
        onRemove={onRemove}
      />
    </section>
  );
}

function MemberSearch({ value, onChange }: { value: string; onChange(value: string): void }) {
  return (
    <label>
      Search members
      <input value={value} onChange={event => onChange(event.target.value)} />
    </label>
  );
}

function MemberList({
  members,
  canManageMembers,
  onRemove,
}: {
  members: Member[];
  canManageMembers: boolean;
  onRemove(memberId: string): void;
}) {
  return (
    <ul>
      {members.map(member => (
        <li key={member.id}>
          <span>{member.name}</span>
          {canManageMembers ? (
            <button type="button" onClick={() => onRemove(member.id)}>Remove</button>
          ) : null}
        </li>
      ))}
    </ul>
  );
}
```

The extraction is useful because search, list rendering, invitation, and removal have distinct interaction/API needs. If this is a tiny one-off screen, a single component with derived `visibleMembers` can be clearer; do not split markup merely to reduce line count.

## 2. A useful custom hook

A hook is useful when several screens share a stateful interaction with the same behavior, such as selecting visible rows while preserving hidden selections.

```tsx
import { useState } from 'react';

type Member = { id: string; name: string; role: 'owner' | 'admin' | 'member' };

export function useMemberSelection(members: Member[]) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set());
  const visibleIds = members.map(member => member.id);
  const selectedCount = visibleIds.filter(id => selectedIds.has(id)).length;
  const allVisibleSelected = visibleIds.length > 0 && selectedCount === visibleIds.length;

  function toggle(memberId: string) {
    setSelectedIds(current => {
      const next = new Set(current);
      if (next.has(memberId)) next.delete(memberId);
      else next.add(memberId);
      return next;
    });
  }

  function toggleAllVisible() {
    setSelectedIds(current => {
      const next = new Set(current);
      if (allVisibleSelected) visibleIds.forEach(id => next.delete(id));
      else visibleIds.forEach(id => next.add(id));
      return next;
    });
  }

  return { selectedIds, selectedCount, allVisibleSelected, toggle, toggleAllVisible };
}
```

Keep this hook only if selection behavior is reused or its transition logic warrants a named unit. If selection is a single checkbox on one screen, local `useState` is simpler.

## 3. An unnecessary custom hook

```tsx
function useFullName(firstName: string, lastName: string) {
  return `${firstName} ${lastName}`;
}
```

This adds a hook name and file without using React state, effects, or reusable interaction. Use a pure formatter if the rule deserves a shared name, or keep the expression inline:

```tsx
const fullName = `${firstName} ${lastName}`;
```

## 4. Derive values during render instead of synchronizing them with an effect

**Before:** `filteredMembers` is a second copy of props that must be kept synchronized.

```tsx
import { useEffect, useState } from 'react';

type Member = { id: string; name: string; role: 'owner' | 'admin' | 'member' };

function MemberSearchResults({ members, query }: { members: Member[]; query: string }) {
  const [filteredMembers, setFilteredMembers] = useState(members);

  useEffect(() => {
    setFilteredMembers(
      members.filter(member => member.name.toLowerCase().includes(query.toLowerCase())),
    );
  }, [members, query]);

  return <ul>{filteredMembers.map(member => <li key={member.id}>{member.name}</li>)}</ul>;
}
```

**After:** calculate the view from the current inputs. Add `useMemo` only if profiling shows the calculation is costly or stable identity is required by a measured consumer.

```tsx
type Member = { id: string; name: string; role: 'owner' | 'admin' | 'member' };

function MemberSearchResults({ members, query }: { members: Member[]; query: string }) {
  const normalizedQuery = query.trim().toLowerCase();
  const filteredMembers = members.filter(member =>
    member.name.toLowerCase().includes(normalizedQuery),
  );

  return <ul>{filteredMembers.map(member => <li key={member.id}>{member.name}</li>)}</ul>;
}
```

Use an effect when synchronizing with an external system, such as subscribing to a browser event. Do not use it to copy props into state or to calculate render data.

## 5. Compose variants instead of growing boolean props

**Before:** combinations are unclear, and adding a third mode multiplies conditionals.

```tsx
type DialogProps = {
  isOpen: boolean;
  isDestructive?: boolean;
  isInvite?: boolean;
  showMemberPicker?: boolean;
};
```

**After:** compose the content and action that differ. The dialog owns shared behavior; each feature owns its meaningful contents.

```tsx
import type { ReactNode } from 'react';

type DialogProps = {
  title: string;
  children: ReactNode;
  onClose(): void;
};

function Dialog({ title, children, onClose }: DialogProps) {
  return (
    <section role="dialog" aria-modal="true" aria-label={title}>
      <button type="button" onClick={onClose} aria-label="Close dialog">Close</button>
      {children}
    </section>
  );
}

function RemoveMemberDialog({ memberName, onConfirm, onClose }: {
  memberName: string;
  onConfirm(): void;
  onClose(): void;
}) {
  return (
    <Dialog title="Remove member" onClose={onClose}>
      <p>Remove {memberName} from this organization?</p>
      <button type="button" onClick={onConfirm}>Remove member</button>
    </Dialog>
  );
}
```

Use a small discriminated `variant` when alternatives share the same structure and only one can be active. Composition is clearer when modes have materially different content or behavior.

## 6. Form state and recoverable errors

This client form owns transient input and feedback. It performs helpful local validation but leaves authoritative validation and authorization to the server action.

```tsx
import { useState } from 'react';
import type { FormEvent } from 'react';

type CreateProject = (input: { name: string }) => Promise<{ ok: true } | { ok: false; message: string }>;

function CreateProjectForm({ createProject }: { createProject: CreateProject }) {
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, setIsPending] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setIsPending(true);

    try {
      const result = await createProject({ name });
      if (!result.ok) {
        setError(result.message);
        return;
      }
      setName('');
    } catch {
      setError('The project could not be saved. Try again.');
    } finally {
      setIsPending(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} aria-busy={isPending}>
      <label htmlFor="project-name">Project name</label>
      <input
        id="project-name"
        value={name}
        onChange={event => setName(event.target.value)}
        aria-invalid={Boolean(error)}
        aria-describedby={error ? 'project-name-error' : undefined}
        required
        minLength={2}
      />
      {error ? <p id="project-name-error" role="alert">{error}</p> : null}
      <button type="submit" disabled={isPending}>{isPending ? 'Saving…' : 'Create project'}</button>
    </form>
  );
}
```

The example preserves input on failure and clears it only on success. In a Next.js application, use the project’s established Server Action form pattern and consult the `nextjs` skill for the server boundary.

## 7. Optimize a demonstrated rendering bottleneck

Suppose profiling shows each keystroke causes an expensive chart to render. Keep the changing query state near the search field and isolate the stable chart inputs before adding memoization.

```tsx
import { memo, useState } from 'react';

type RevenuePoint = { month: string; amountCents: number };

function ExpensiveSvgChart({ points }: { points: RevenuePoint[] }) {
  return (
    <svg role="img" aria-label="Monthly revenue">
      {points.map((point, index) => (
        <circle key={point.month} cx={index * 12} cy={point.amountCents / 1000} r={4} />
      ))}
    </svg>
  );
}

function RevenueChartBefore({ points }: { points: RevenuePoint[] }) {
  return <ExpensiveSvgChart points={points} />;
}

const RevenueChart = memo(function RevenueChart({ points }: { points: RevenuePoint[] }) {
  return <ExpensiveSvgChart points={points} />;
});

function RevenueDashboardBefore({ points }: { points: RevenuePoint[] }) {
  const [query, setQuery] = useState('');
  return (
    <section>
      <label>
        Search dashboard
        <input value={query} onChange={event => setQuery(event.target.value)} />
      </label>
      <p>Showing results for {query || 'all activity'}.</p>
      <RevenueChartBefore points={points} />
    </section>
  );
}

function RevenueDashboard({ points }: { points: RevenuePoint[] }) {
  const [query, setQuery] = useState('');
  return (
    <section>
      <label>
        Search dashboard
        <input value={query} onChange={event => setQuery(event.target.value)} />
      </label>
      <p>Showing results for {query || 'all activity'}.</p>
      <RevenueChart points={points} />
    </section>
  );
}
```

In the before version, every search keystroke re-renders the expensive SVG despite unchanged chart data. In the after version, `memo` can skip that work because `points` keeps the same reference. This helps only when profiling confirms the chart is expensive and the parent passes stable data; if the chart is cheap or `points` is recreated on every render, remove the memo or fix the unstable input. Measure before and after and record the interaction and data size.

## Review checklist

- Does each component own one coherent UI responsibility?
- Is state stored at the lowest common owner and are derived values computed from current inputs?
- Does a custom hook package reusable stateful behavior rather than a trivial calculation or business rule?
- Are effects synchronizing external systems with symmetric cleanup?
- Do props describe capabilities/content clearly, with composition for distinct modes?
- Can a user understand pending, success, and recoverable error states with keyboard and assistive technology?
- Is a performance change supported by a measured bottleneck and checked after the change?
