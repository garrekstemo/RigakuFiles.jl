# RigakuFiles.jl

Parses text output from Rigaku X-ray diffractometers into a `RigakuFile` container of `RigakuScan` structs. **Reader only — no analysis code lives here.** Downstream packages build on top.

## Scope

- `.ras` — canonical format, with `*RAS_HEADER_START` / `*RAS_INT_START` section markers (supports multi-scan files).
- `.txt` — simplified export, same `*KEY "VALUE"` metadata but no section markers.

`RigakuFile(path)` is the **single public entry point**. It auto-detects format and throws `ArgumentError` on an empty file (or a RAS file with no header markers).

## Structure

Entry point: `src/parser.jl` (`RigakuFile` constructor, `_parse_ras`/`_parse_txt`/`_build_scan`/`_parse_datetime`). Types in `src/types.jl`, accessors in `src/utils.jl`. Browse `src/`.

## Public API

| Symbol | Notes |
|--------|-------|
| `RigakuFile(path)` | Entry point; `<: AbstractVector{RigakuScan}`. Navigate with Base verbs: `only` (strict single-scan), `first`, `file[i]`, iteration, `length`. |
| `RigakuScan` | Concrete struct; 13 typed fields plus a raw `metadata` dict (14 fields total). |
| `AbstractRigakuSpectrum` | Supertype; interface is `x`, `y`, `metadata`. |
| `wavelength_alpha1/2/beta(s)` | Kα1 / Kα2 / Kβ wavelengths (Å). |
| `scan_step(s)`, `scan_speed(s)` | Scan parameters. |
| `detector(s)` | Detector name; falls back between `HW_COUNTER_SELECT_NAME` and `HW_COUNTER_NAME-0`. |

## Design decisions

### Sentinel values, not `Union{T, Missing}`

To keep `RigakuScan` concretely typed, missing fields use fixed sentinels: `String → ""`, `Float64 → 0.0`, `DateTime → DateTime(1)` (year 0001). Trade-off: a **recorded zero is indistinguishable from absent** through the typed accessors. For strict present/absent checks, inspect the raw `metadata` dict. The `show(::MIME"text/plain", …)` method hides `DateTime(1)` so the sentinel never surfaces in user output.

### Metadata as `Dict{String, String}`

Values stay as strings even when numeric — parsing is deferred to accessors. Annotation lines (`#key=value`) are stored under `"_" * key` to avoid collisions with regular `*KEY` entries.

### Third-column attenuator data

Some `.ras` exports carry a third column after intensity. It is parsed then silently discarded — only `x` and `y` are stored. Surfacing it later means a new `RigakuScan` field, not a public-API change to the readers.

### Datetime parsing

`_parse_datetime` tries `m/d/y H:M:S` then `y/m/d H:M:S` via `tryparse`. Empty strings return `DateTime(1)` silently; non-empty unparseable strings `@warn` and fall back to `DateTime(1)`.

## Registry status

UUID `2299bd5a-4211-402e-a7bc-16f21a3e5d87`. Unregistered; planned first General submission at `v0.1.0` (verify it isn't yet registered before relying on this). Aqua.jl in the test suite; CI + codecov configured.
