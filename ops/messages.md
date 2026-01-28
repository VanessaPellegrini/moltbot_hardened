# Standard Messages

All user‑facing messages should follow the same JSON structure to keep CLI, Nginx, and Guardian consistent.

## Schema

See: `schemas/breaker-response.schema.json`

## Canonical Fields

- `schema_version` — message format version ("1.0")
- `state` — breaker state (CLOSED | OPEN | HALF)
- `reason` — enum reason
- `detected_at` — ISO 8601 UTC timestamp
- `actor` — user | guardian | system
- `message` — human‑readable summary
- `next_step` — human‑readable action

## Canonical Reasons

- `MANUAL_BLOCK`
- `MANUAL_OPEN`
- `RECOVERY`
- `EXPOSURE_DETECTED`
- `STATE_INVALID`
- `STATE_MISSING`

## Example: OPEN

```json
{
  "schema_version": "1.0",
  "state": "OPEN",
  "reason": "MANUAL_BLOCK",
  "detected_at": "2026-01-28T00:00:00Z",
  "actor": "user",
  "message": "Access blocked by circuit breaker",
  "next_step": "Fix configuration and run recovery"
}
```

## Example: HALF

```json
{
  "schema_version": "1.0",
  "state": "HALF",
  "reason": "RECOVERY",
  "detected_at": "2026-01-28T00:00:00Z",
  "actor": "user",
  "message": "System in recovery mode",
  "next_step": "Run verify, then open"
}
```

## Notes

- Nginx templates use static timestamps; the CLI/Guardian writes real timestamps to the state file.
- Avoid leaking sensitive details in `message` or `next_step`.
