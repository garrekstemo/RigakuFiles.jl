"""
    AbstractRigakuSpectrum

Abstract supertype for Rigaku instrument data.

## Interface

Concrete subtypes must provide:

- `x::Vector{Float64}` — independent-axis values (typically 2θ or angle)
- `y::Vector{Float64}` — dependent-axis values (typically intensity)
- `metadata::Dict{String, String}` — raw header key/value pairs, with
  annotation lines (`#key=value`) stored under `"_" * key`

Providing these three fields enables `length`, `size`, and the accessor
helpers in this package (`wavelength_alpha1`, `scan_step`, `detector`, …)
to work out of the box.
"""
abstract type AbstractRigakuSpectrum end

"""
    RigakuScan <: AbstractRigakuSpectrum

A single scan from a Rigaku instrument file (`.ras` or exported `.txt`).

# Fields
- `sample::String` — sample name (`FILE_SAMPLE`); `""` if not recorded
- `comment::String` — file comment (`FILE_COMMENT`); `""` if not recorded
- `instrument::String` — instrument model (`FILE_SYSTEM_NAME`); `""` if not recorded
- `target::String` — X-ray target element (`HW_XG_TARGET_NAME`), e.g. `"Cu"`
- `wavelength::Float64` — Kα1 wavelength in ångström (`HW_XG_WAVE_LENGTH_ALPHA1`); `0.0` if not recorded
- `scan_axis::String` — scan axis name (`MEAS_SCAN_AXIS_X`), e.g. `"TwoThetaTheta"`
- `scan_mode::String` — scan mode (`MEAS_SCAN_MODE`), e.g. `"CONTINUOUS"`
- `start_time::DateTime` — scan start (`MEAS_SCAN_START_TIME`); `DateTime(1)` if not recorded
- `end_time::DateTime` — scan end (`MEAS_SCAN_END_TIME`); `DateTime(1)` if not recorded
- `xunits::String` — x-axis units (`MEAS_SCAN_UNIT_X`), defaults to `"deg"`
- `yunits::String` — y-axis units (`MEAS_SCAN_UNIT_Y` or `#Intensity_unit`), `""` if not recorded
- `x::Vector{Float64}` — angle values (typically 2θ)
- `y::Vector{Float64}` — intensity values
- `metadata::Dict{String, String}` — all raw header key/value pairs;
  annotation lines (`#key=value`) are stored under `"_" * key`

# Sentinels for missing fields

To keep the struct concretely typed, missing fields use fixed sentinel values:

| Field type | Sentinel |
|------------|----------|
| `String`   | `""` |
| `Float64`  | `0.0` |
| `DateTime` | `DateTime(1)` (year 0001) |

For strict "present vs. missing" checks, inspect the raw `metadata` dict
instead of relying on the sentinel.
"""
struct RigakuScan <: AbstractRigakuSpectrum
    sample::String
    comment::String
    instrument::String
    target::String
    wavelength::Float64
    scan_axis::String
    scan_mode::String
    start_time::DateTime
    end_time::DateTime
    xunits::String
    yunits::String
    x::Vector{Float64}
    y::Vector{Float64}
    metadata::Dict{String, String}
end

Base.length(s::AbstractRigakuSpectrum) = length(s.x)
Base.size(s::AbstractRigakuSpectrum) = (length(s.x),)

function Base.show(io::IO, s::RigakuScan)
    print(io, "RigakuScan(")
    if !isempty(s.sample)
        print(io, "\"", s.sample, "\", ")
    end
    print(io, length(s.x), " points")
    if !isempty(s.x)
        print(io, ", ", s.x[1], "–", s.x[end], " ", s.xunits)
    end
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", s::RigakuScan)
    println(io, "RigakuScan")
    !isempty(s.sample) && println(io, "  Sample:     ", s.sample)
    !isempty(s.instrument) && println(io, "  Instrument: ", s.instrument)
    if !isempty(s.target)
        if s.wavelength > 0
            println(io, "  Target:     ", s.target, " (λ = ", s.wavelength, " Å)")
        else
            println(io, "  Target:     ", s.target)
        end
    end
    if !isempty(s.scan_axis)
        if !isempty(s.scan_mode)
            println(io, "  Scan:       ", s.scan_axis, " (", s.scan_mode, ")")
        else
            println(io, "  Scan:       ", s.scan_axis)
        end
    end
    if !isempty(s.x)
        println(io, "  Range:      ", s.x[1], " – ", s.x[end], " ", s.xunits)
    end
    println(io, "  Points:     ", length(s.x))
    !isempty(s.yunits) && println(io, "  Intensity:  ", s.yunits)
    if s.start_time != DateTime(1)
        print(io, "  Acquired:   ", Dates.format(s.start_time, "yyyy-mm-dd HH:MM:SS"))
    end
end
