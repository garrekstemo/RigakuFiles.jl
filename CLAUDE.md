# RigakuFiles.jl

A small Julia package that parses text output from Rigaku X-ray diffractometers into a concrete `RigakuScan` struct. No analysis code lives here — downstream packages build on top.

## What this package does

- Parses Rigaku `.ras` (canonical, with `*RAS_HEADER_START` / `*RAS_INT_START` section markers).
- Parses the simplified `.txt` export (same `*KEY "VALUE"` metadata, no section markers).
- Handles multi-scan files: [`read_scans`](@ref) returns a `Vector{RigakuScan}`; [`read_scan`](@ref) returns the first and warns.
- Exposes common header fields (sample, target, wavelength, scan axis/mode, timestamps, units) as struct fields.
- Preserves all raw header key/value pairs in `scan.metadata`.

## Project structure

```
src/
├── RigakuFiles.jl   # module, using Dates, include order, exports
├── types.jl         # AbstractRigakuSpectrum, RigakuScan, Base.show methods
├── parser.jl        # read_scan / read_scans / RigakuScan(path) constructor,
│                    #   _parse_ras, _parse_txt, _build_scan, _parse_datetime
└── utils.jl         # wavelength_alpha1/2/beta, scan_step, scan_speed, detector

test/
├── runtests.jl      # Aqua + ~16 @testsets
└── data/            # small synthetic fixtures: simple.txt, multiscan.ras,
                     #   three_column.ras, minimal.txt, empty.txt,
                     #   no_int_block.ras, iso_date.txt, bad_date.txt,
                     #   counter_name.ras, crlf.txt

docs/src/
├── index.md                 # overview
├── guide/quickstart.md      # usage + plotting
├── guide/formats.md         # .ras vs .txt layout, sentinels, datetime formats
└── lib/public.md            # @autodocs with Private = false
```

## Public API

| Symbol | Purpose |
|--------|---------|
| `read_scan(path)` | Load a single scan; warns and returns first if multi-scan. |
| `read_scans(path)` | Load all scans; returns `Vector{RigakuScan}`. |
| `RigakuScan` | Concrete struct; 14 fields plus raw `metadata` dict. |
| `AbstractRigakuSpectrum` | Supertype; interface: `x`, `y`, `metadata`. |
| `wavelength_alpha1/2/beta(s)` | Kα1 / Kα2 / Kβ wavelengths (Å). |
| `scan_step(s)`, `scan_speed(s)` | Scan parameters. |
| `detector(s)` | Detector name; falls back between `HW_COUNTER_SELECT_NAME` and `HW_COUNTER_NAME-0`. |

## Design decisions

### Sentinel values for missing fields

`RigakuScan` is concretely typed — missing metadata uses sentinels, not `Missing`:

| Field type | Sentinel |
|------------|----------|
| `String`   | `""` |
| `Float64`  | `0.0` |
| `DateTime` | `DateTime(1)` (year 0001) |

This trades Julia's idiomatic `Union{T, Missing}` for a simpler, concrete struct at the cost of making "recorded zero" and "absent" indistinguishable through the typed accessors. For strict present/absent checks, inspect the raw `metadata` dict. The `show(::MIME"text/plain", …)` method hides `DateTime(1)` so the sentinel never appears in user output.

### Metadata as `Dict{String, String}`

Values stay as strings even when numeric; parsing is deferred to accessors. Annotation lines (`#key=value`) are stored under `"_" * key` to avoid collisions with regular `*KEY` entries.

### Third-column attenuator data

Some `.ras` exports have a third column after intensity. It is parsed and silently discarded — only `x` and `y` are stored. If someone needs this later, the fix is a new field on `RigakuScan`, not a public API change to the readers.

### Datetime parsing

`_parse_datetime` tries `m/d/y H:M:S` then `y/m/d H:M:S` via `tryparse`. Unparseable non-empty strings emit a warning and fall back to `DateTime(1)`; empty strings are silent.

## Registry status

- UUID: `2299bd5a-4211-402e-a7bc-16f21a3e5d87`
- Currently unregistered; first submission to the General registry planned at `v0.1.0`.
- Targets Julia ≥ 1.10 (LTS).
- CI on push/PR; codecov integrated; Aqua.jl in the test suite.

## Testing

```julia
using Pkg; Pkg.test()
```

The test suite covers:
- Every format variant (`.txt`, `.ras` single, `.ras` multi-scan, three-column, minimal, header-only, CRLF)
- Both datetime formats + unparseable-datetime warning path
- Error paths: empty file, missing file
- `detector()` fallback to `HW_COUNTER_NAME-0`
- `Show` methods with both present and missing timestamps
- `AbstractString` dispatch (SubString paths)
- `RigakuScan(path)` ≡ `read_scan(path)`
- Aqua quality checks (ambiguities, piracy, stale deps, compat bounds)
