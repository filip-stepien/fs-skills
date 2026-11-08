# Scenario design and test doubles

Use this guide when tests make a reader reverse-engineer setup, when multiple files recreate the same dependency, or when choosing between a fake and a mock. The examples use a fictional room-booking feature and Vitest-style tests; adapt contracts and runner APIs to the project.

## Make the scenario visible

**Setup-heavy:** the test name says “occupied room,” but the reader has to inspect a user, room, repository, saved record, service, and positional call to discover why booking is forbidden.

```ts
it('rejects an occupied room', async () => {
  const user = { id: 'user-1', email: 'a@example.com', role: 'member' };
  const room = { id: 'room-1', capacity: 2 };
  const repository = new InMemoryBookingRepository();
  await repository.save({
    id: 'existing-booking',
    roomId: room.id,
    userId: 'another-user',
    startsAt: new Date('2026-01-10T10:00:00Z'),
  });
  const service = new BookingService(repository);

  const result = await service.book({
    userId: user.id,
    roomId: room.id,
    startsAt: new Date('2026-01-10T10:00:00Z'),
  });

  expect(result.ok).toBe(false);
});
```

Prefer a small scenario function whose options name the business conditions:

```ts
it('rejects booking when the room is occupied', async () => {
  const booking = givenBooking({ roomOccupied: true });

  const result = await booking.bookRoom();

  expect(result).toEqual({ ok: false, error: 'room-already-booked' });
  expect(booking.newBookings()).toEqual([]);
});

it('rejects booking when the user reaches the booking limit', async () => {
  const booking = givenBooking({ bookingLimit: 3, existingBookings: 3 });

  const result = await booking.bookRoom();

  expect(result).toEqual({ ok: false, error: 'booking-limit-reached' });
  expect(booking.newBookings()).toEqual([]);
});
```

Here is one implementation of that helper and its fake, so the fluent-looking test API is not magic. Defaults hide stable IDs and dates; the room occupancy and limit stay explicit because they explain each result.

```ts
type Room = { id: string };
type Booking = { id: string; roomId: string; userId: string; startsAt: Date };
type BookingError = 'room-not-found' | 'room-already-booked' | 'booking-limit-reached';
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
type BookRoomData = { roomId: string; userId: string; startsAt: Date };

type BookingRepository = {
  findRoomById(roomId: string): Promise<Room | null>;
  findByRoomAndTime(params: { roomId: string; startsAt: Date }): Promise<Booking | null>;
  countByUser(userId: string): Promise<number>;
  save(data: BookRoomData): Promise<Booking>;
};

function bookRoomFactory({
  bookings,
  bookingLimit,
}: {
  bookings: BookingRepository;
  bookingLimit: number;
}) {
  return async (data: BookRoomData): Promise<Result<Booking, BookingError>> => {
    if (!(await bookings.findRoomById(data.roomId))) {
      return { ok: false, error: 'room-not-found' };
    }
    if (await bookings.findByRoomAndTime(data)) {
      return { ok: false, error: 'room-already-booked' };
    }
    if ((await bookings.countByUser(data.userId)) >= bookingLimit) {
      return { ok: false, error: 'booking-limit-reached' };
    }
    return { ok: true, value: await bookings.save(data) };
  };
}

function createInMemoryBookingRepository(seed: {
  rooms: Room[];
  bookings: Booking[];
}) {
  const rooms = new Map(seed.rooms.map(room => [room.id, room]));
  const records = [...seed.bookings];
  const newlySaved: Booking[] = [];
  const repository: BookingRepository = {
    async findRoomById(roomId) {
      return rooms.get(roomId) ?? null;
    },
    async findByRoomAndTime({ roomId, startsAt }) {
      return records.find(
        booking =>
          booking.roomId === roomId && booking.startsAt.getTime() === startsAt.getTime(),
      ) ?? null;
    },
    async countByUser(userId) {
      return records.filter(booking => booking.userId === userId).length;
    },
    async save(data) {
      const booking = { ...data, id: `booking-${records.length + 1}` };
      records.push(booking);
      newlySaved.push(booking);
      return booking;
    },
  };

  return { repository, newlySaved: () => [...newlySaved] };
}

function givenBooking({
  roomOccupied = false,
  bookingLimit = 3,
  existingBookings = 0,
}: {
  roomOccupied?: boolean;
  bookingLimit?: number;
  existingBookings?: number;
} = {}) {
  const roomId = 'room-1';
  const userId = 'user-1';
  const startsAt = new Date('2026-01-10T10:00:00Z');
  const rooms = [{ id: roomId }];
  const seedBookings = Array.from({ length: existingBookings }, (_, index) => ({
    id: `existing-${index + 1}`,
    roomId: `other-room-${index + 1}`,
    userId,
    startsAt: new Date(startsAt.getTime() + (index + 1) * 60 * 60 * 1000),
  }));

  if (roomOccupied) {
    seedBookings.push({
      id: 'existing-room-booking',
      roomId,
      userId: 'another-user',
      startsAt,
    });
  }

  const fake = createInMemoryBookingRepository({ rooms, bookings: seedBookings });
  const bookRoom = bookRoomFactory({ bookings: fake.repository, bookingLimit });

  return {
    bookRoom: () => bookRoom({ roomId, userId, startsAt }),
    newBookings: fake.newlySaved,
  };
}
```

The fake stores records and implements the repository's reads and writes. It does **not** decide booking policy; the use case owns that rule. Its supported operations have meaningful semantics, and its deterministic IDs/time make assertions repeatable. It does not prove database transaction or concurrency behavior; cover those at the real adapter boundary. If a repository method is added, update the fake or split an overly broad port rather than weakening the test with a success stub.

### Scenario helper rules

- **Good:** `givenBooking({ roomOccupied: true })` exposes the condition that makes the booking fail.
- **Good:** a default room ID, fixed date, and fresh fake hide details that do not affect the current scenario.
- **Bad:** `givenBooking().withEverything()` silently creates a paid user, administrator role, confirmed email, and occupied room. The reader cannot tell which state matters.
- **Bad:** a shared mutable fixture is edited by tests and depends on execution order.
- **Bad:** a generic builder needs multiple files, callback registries, or hidden database work to create one ordinary scenario.

A plain factory with named options is often enough. Use fluent `withX()` methods only when they remain focused and make the test clearer than an object literal. Keep relevant values visible, as in `{ bookingLimit: 3, existingBookings: 3 }`.

An overbuilt helper can make the test shorter but less informative:

```ts
const booking = givenBooking().withDefaults().withAccess().withHappyPath();
const result = await booking.run();
```

The reader cannot see whether the room is occupied, what access was granted, or which behavior the setup selects. Prefer a named condition:

```ts
const booking = givenBooking({ roomOccupied: true });
const result = await booking.bookRoom();
```

The helper should remove fixture plumbing while preserving the reason the expected result follows.

## Reusable test infrastructure

Treat test helpers as maintained code: give them a name, narrow responsibility, deterministic defaults, and contract-level tests if their semantics are non-trivial or broadly reused.

Consider shared infrastructure when multiple tests repeatedly need the same meaningful behavior: an in-memory repository, fixed clock, deterministic ID source, controlled event publisher, or a scenario fixture. Keep one-off data local when extraction would add another concept without reducing cognitive load.

Do not implement unrelated ports just to satisfy a broad dependency. Give a use case the smallest useful contract. Avoid repeating this in individual tests:

```ts
const repository = {
  find: async () => { throw new Error('Not implemented'); },
  save: async () => expectedRecord,
  delete: async () => { throw new Error('Not implemented'); },
} as unknown as BroadRepository;
```

This cast lies about the contract and leaves unexpected calls undefined. Split reader/writer ports when consumers have distinct responsibilities, or use a shared complete fake. A deliberate unsupported operation can fail fast in one reusable helper, but it should preserve the method's expected shape and error semantics.

## Choose the simplest test double that proves the contract

| Double | Use it when | Example use |
| --- | --- | --- |
| Real dependency | It is cheap, local, deterministic, and its behavior is part of the test | Pure domain object, parser, or a real test database in an integration test |
| Fake | The test needs a lightweight working implementation with state | In-memory repository honoring reads, filters, writes, and missing-record behavior |
| Stub | The test needs a controlled answer from a dependency | Geocoder returns a known city or `null` |
| Spy | The interaction is itself part of the contract | Confirm a payment request uses the stable idempotency key |
| Mock | A specific interaction must be required or forbidden | Assert the event publisher is not called after persistence fails |

Prefer state/result assertions for business outcomes. Assert interactions when count, order, identity, or absence is a requirement: payment must not be submitted twice; an event must not be published after a rejected write. Avoid checking call counts merely because a method happens to be called in the current implementation.

For an external provider, use a controlled response in a unit/use-case test so it performs no network call. Keep a separate adapter/integration test for request serialization, signatures, or provider SDK behavior when that boundary is consequential. Do not mock every collaborator if a real pure object or faithful fake is simpler.

```ts
type ChargeRequest = { paymentId: string; amountCents: number; idempotencyKey: string };
type ChargeProvider = {
  charge(request: ChargeRequest): Promise<{ providerChargeId: string }>;
};

const providerRequests: ChargeRequest[] = [];
const provider: ChargeProvider = {
  async charge(request) {
    providerRequests.push(request);
    return { providerChargeId: 'provider-charge-1' };
  },
};

```

Pass the controlled provider to the use case and assert the saved payment outcome plus the request values it must send. The recorded request is a spy; its controlled return is a stub. No real network is needed for that application contract. An existing generic stub helper can be useful for uninteresting port methods. Prefer focused fakes when state semantics matter, and review broad proxy/cast helpers carefully: a default async rejection is unsafe for synchronous methods and does not implement repository behavior.

For example, if the requirement is to reuse the same idempotency key after a retryable timeout, assert the observable requests:

```ts
expect(providerRequests).toEqual([
  { paymentId: 'payment-1', amountCents: 2500, idempotencyKey: 'payment-1' },
  { paymentId: 'payment-1', amountCents: 2500, idempotencyKey: 'payment-1' },
]);
```

Keep the scenario's timeout and retry policy explicit in the test setup. This assertion protects the provider contract; it does not require asserting private retry-helper calls.

## Keep assertions independent from implementation

Prefer exact public outcomes and meaningful state changes. Avoid testing private helpers, incidental construction order, or the number of calls to an unimportant function. Do not copy the production algorithm into the test to calculate the expected answer; use a requirement or concrete scenario to derive it independently.

A test is too weak if it only checks `.toBeDefined()` or `result.ok === false` while several errors have different meanings. Assert the specific expected error, persisted state, emitted event, or user-visible result that matters. Keep snapshots for stable serialized contracts where the output itself is important, not as a substitute for understanding the behavior.
