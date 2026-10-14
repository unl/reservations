# Public API (v1)

Read-only JSON endpoints for tool reservations and tool utilization, served
by the app itself under `/api/v1` (`routes/public_api.rb`).

- **No login.** Responses never identify people: reservations are anonymous
  time blocks, and member activity only appears as counts (`unique_members`,
  `unique_borrowers`).
- **One service space.** Each deployment serves the tools of its own service
  space (`service_space_id` in the config): Innovation Studio or Engineering
  Design Hub.
- **Any website can call it.** Responses carry `Access-Control-Allow-Origin: *`.
- **Times** are ISO 8601 in the app's time zone (America/Chicago), e.g.
  `2026-10-14T09:00:00-05:00`. **Dates** are `YYYY-MM-DD` in that time zone.
- **Date ranges** use `start` and `end`, both inclusive. If you give only one,
  the other is filled in with the endpoint's default length.
- **Errors** return `{"error": "..."}` with status `400` (bad parameter) or
  `404` (unknown tool or endpoint).

| Endpoint | Default range | Longest range |
| --- | --- | --- |
| `GET /api/v1` | | |
| `GET /api/v1/tools` | | |
| `GET /api/v1/tools/:id` | | |
| `GET /api/v1/reservations` | today + 6 days | 92 days |
| `GET /api/v1/tools/:id/reservations` | today + 6 days | 92 days |
| `GET /api/v1/tools/:id/availability` | today + 6 days | 31 days |
| `GET /api/v1/utilization` | last 30 full days | 366 days |
| `GET /api/v1/tools/:id/utilization` | last 30 full days | 366 days |
| `GET /api/v1/checkout_tools` | | |
| `GET /api/v1/checkout_tools/utilization` | last 30 full days | 366 days |

## Tools

### `GET /api/v1/tools`

Lists every tool in the service space.

| Parameter | Effect |
| --- | --- |
| `category` | Only tools in this category id |
| `reservable` | `true` or `false` |

Each tool has the same fields as the single-tool endpoint below, minus
`lockouts`.

### `GET /api/v1/tools/:id`

```json
{
  "tool": {
    "id": 852,
    "name": "Waterjet Cutter",
    "model": "OMAX ProtoMAX",
    "category": { "id": 7, "name": "Engineering Design Hub" },
    "description": "Waterjet Cutter in the Engineering Design Hub.",
    "status": "locked_out",
    "reservable": true,
    "requires_authorization": true,
    "reservable_24_hours": true,
    "reservation_lengths_minutes": [30, 60, 90, 120, 150, 180, 210, 240],
    "max_upcoming_reservations_per_user": 2,
    "lockouts": [{ "starts_at": "2026-10-11T08:00:00-05:00", "ends_at": null }]
  }
}
```

- `status` is one of:
  - `operational`
  - `locked_out`: a lockout is in effect now.
  - `out_of_order`: the tool is marked INOP.
- `requires_authorization`: only members trained on the tool can reserve it.
- `reservable_24_hours`: the tool can be booked at any time of day, not just
  during opening hours. This applies to 24-hour tools in the Engineering
  Design Hub.
- `reservation_lengths_minutes`: the lengths the reserve page offers for this
  tool.
- `max_upcoming_reservations_per_user`: how many future reservations one
  member may hold, or `null` for no limit.
- `lockouts`: current and future lockouts. `ends_at: null` means no end has
  been set yet.

## Reservations

### `GET /api/v1/reservations`

Reservations on all tools, oldest first. A reservation is included if any part
of it falls in the date range.

| Parameter | Effect |
| --- | --- |
| `start`, `end` | The date range |
| `category` | Only tools in this category id |
| `tool_id` | Only this tool |

### `GET /api/v1/tools/:id/reservations`

The same as above for one tool.

```json
{
  "tool": { "id": 12, "name": "Laser Cutter Fusion 32 CO2" },
  "start": "2026-10-14",
  "end": "2026-10-14",
  "reservations": [
    {
      "id": 137729,
      "tool_id": 12,
      "starts_at": "2026-10-14T19:00:00-05:00",
      "ends_at": "2026-10-14T21:00:00-05:00",
      "minutes": 120,
      "type": "member",
      "event": null
    }
  ]
}
```

`type` is `member` or `training`. A training reservation holds the tool for a
training event. Its `event` gives the event's `id` and `title`, unless the
event is private, in which case `event` is `null`.

### `GET /api/v1/tools/:id/availability`

Free time per day: the tool's open time minus reservations and lockouts.

```json
{
  "tool": { "id": 12, "name": "Laser Cutter Fusion 32 CO2" },
  "bookable": true,
  "reservation_lengths_minutes": [30, 60, 90, 120, 150],
  "days": [
    {
      "date": "2026-10-14",
      "open": [{ "starts_at": "2026-10-14T09:00:00-05:00", "ends_at": "2026-10-14T21:00:00-05:00" }],
      "free": [{ "starts_at": "2026-10-14T09:00:00-05:00", "ends_at": "2026-10-14T19:00:00-05:00", "minutes": 600 }]
    }
  ]
}
```

- `open` follows the same rules as the reserve page:
  - It is the day's "open" blocks from the space hours. A one-off entry for
    that date replaces the weekly hours.
  - Closed days, and blocks marked "open, no reservations", are left out.
  - The whole day is open when no hours are set for it, or when the tool is
    reservable 24 hours.
- `free` never includes past time, or gaps shorter than the tool's shortest
  reservation length.
- `bookable` is `false` when the tool can't be reserved at all: it is not
  reservable, it is out of order, or it has no valid reservation length. Then
  `free` is always empty.
- A free window is not a guarantee of a booking. The reserve page also checks
  the member's authorization and reservation limit, allows one booking per
  tool per day, and only offers start times on its own time grid.

## Utilization

All utilization figures come from reservations, compared against the time the
tool could have been reserved:

| Field | Meaning |
| --- | --- |
| `open_minutes` | Time the tool was open for reservations (the same rules as `open` above) |
| `lockout_minutes` | Part of that time the tool was locked out |
| `reservable_minutes` | `open_minutes` - `lockout_minutes` |
| `reserved_minutes` | Length of member reservations, including any time outside opening hours |
| `training_minutes` | Length of training reservations |
| `utilization` | Share of `reservable_minutes` covered by any reservation (member or training), 0 to 1; `null` when `reservable_minutes` is 0 |
| `reservations` | Member reservations that started in the range |
| `average_reservation_minutes` | Their average length |
| `training_sessions` | Training reservations that started in the range |
| `unique_members` | Distinct members with a reservation starting in the range |

Reservation counts and member counts go to the day a reservation starts.
Minutes are split across days. Only tools with `reservable: true` are included.

### `GET /api/v1/utilization`

Totals for the service space, plus a breakdown per category and per tool.

| Parameter | Effect |
| --- | --- |
| `start`, `end` | The date range |
| `category` | Only tools in this category id |
| `tool_id` | Only this tool |
| `interval` | `day`, `week` or `month`: also return `series`, the totals per period |

`GET /api/v1/utilization?category=4&interval=week`, shortened:

```json
{
  "service_space": { "id": 1, "name": "Innovation Studio" },
  "start": "2026-09-13",
  "end": "2026-10-12",
  "totals": {
    "open_minutes": 460080, "lockout_minutes": 0, "reservable_minutes": 460080,
    "reserved_minutes": 37425, "training_minutes": 600, "utilization": 0.0826,
    "reservations": 310, "average_reservation_minutes": 121,
    "training_sessions": 5, "unique_members": 12
  },
  "categories": [{ "id": 4, "name": "Rapid Prototyping", "tools": 27, "utilization": 0.0826, "...": "..." }],
  "tools": [{ "id": 14, "name": "3D Printer", "category_id": 4, "status": "operational", "utilization": 0.0722, "...": "..." }],
  "series": [
    { "start": "2026-09-13", "end": "2026-09-13", "reservable_minutes": 0, "utilization": null, "...": "..." },
    { "start": "2026-09-14", "end": "2026-09-20", "reservable_minutes": 110160, "utilization": 0.0884, "...": "..." }
  ]
}
```

Weeks start on Monday. The first and last periods are cut off at `start` and
`end`.

### `GET /api/v1/tools/:id/utilization`

One tool: a `summary` with the fields above, and a `series` with one entry per
`interval` (default `day`).

## Checkout-desk tools

These are tools lent out at the Engineering Design Hub's checkout desk
(`/checkout/`). They are a separate list from the reservable tools above. In a
service space without a checkout desk, these endpoints return empty lists.

### `GET /api/v1/checkout_tools`

```json
{
  "service_space": { "id": 8, "name": "Engineering Garage" },
  "checkout_tools": [
    {
      "id": 1,
      "name": "Cordless Drill #1",
      "model": "DeWalt DCD791",
      "category": { "id": 7, "name": "Engineering Design Hub" },
      "description": "Cordless Drill #1 available at the checkout desk.",
      "status": "checked_out",
      "checked_out_since": "2026-10-13T12:43:25-05:00"
    }
  ]
}
```

`status` is `available`, `checked_out` or `out_of_order`. The response never
says who has a tool.

### `GET /api/v1/checkout_tools/utilization`

Built from the checkout desk's log. A checkout lasts until the tool's next
check-in. One that has not been checked back in counts until now.

| Field | Meaning |
| --- | --- |
| `checkouts` | Checkouts that started in the range |
| `checked_out_minutes` | Time checked out within the range |
| `average_checkout_minutes` | Average length of finished checkouts started in the range |
| `unique_borrowers` | Distinct people with a checkout overlapping the range |
| `open_minutes` | The space's opening hours in the range |
| `utilization` | Share of `open_minutes` the tool was checked out. In `totals`, the average over all tools |

```json
{
  "start": "2026-09-13",
  "end": "2026-10-12",
  "totals": { "checkouts": 65, "checked_out_minutes": 10415, "average_checkout_minutes": 160,
              "unique_borrowers": 10, "open_minutes": 19080, "utilization": 0.0546 },
  "checkout_tools": [{ "id": 1, "name": "Cordless Drill #1", "checkouts": 4, "checked_out_minutes": 640,
                       "average_checkout_minutes": 160, "unique_borrowers": 2, "open_minutes": 19080,
                       "utilization": 0.0335 }]
}
```

## Operating notes

- The API has no rate limiting or caching. A year of utilization across all of
  the Innovation Studio's tools takes about a second to compute. If the API is
  exposed publicly, consider caching or rate limiting at the web server.
- Tests: `spec/public_api_spec.rb`. rspec and rack-test are in the `development`
  gem group. With the database from `config/server.json` set up, run
  `bundle exec rspec spec/public_api_spec.rb`. The specs create their own data
  inside transactions that are rolled back.
