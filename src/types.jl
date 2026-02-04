"""
    AbstractRigakuSpectrum

Abstract type for Rigaku instrument data. All concrete types provide
`x` and `y` data vectors plus a `metadata` dictionary.
"""
abstract type AbstractRigakuSpectrum end

"""
    RigakuScan <: AbstractRigakuSpectrum

A single scan from a Rigaku instrument file (`.ras` or exported `.txt`).

# Fields
- `sample::String` — sample name (`FILE_SAMPLE`)
- `comment::String` — file comment (`FILE_COMMENT`)
- `instrument::String` — instrument model (`FILE_SYSTEM_NAME`)
- `target::String` — X-ray target element (`HW_XG_TARGET_NAME`), e.g. `"Cu"`
- `wavelength::Float64` — Kα1 wavelength in Angstrom (`HW_XG_WAVE_LENGTH_ALPHA1`)
- `scan_axis::String` — scan axis name (`MEAS_SCAN_AXIS_X`), e.g. `"TwoThetaTheta"`
- `scan_mode::String` — scan mode (`MEAS_SCAN_MODE`), e.g. `"CONTINUOUS"`
- `start_time::DateTime` — scan start time (`MEAS_SCAN_START_TIME`)
- `end_time::DateTime` — scan end time (`MEAS_SCAN_END_TIME`)
- `xunits::String` — x-axis units (`MEAS_SCAN_UNIT_X`), e.g. `"deg"`
- `yunits::String` — y-axis units (`MEAS_SCAN_UNIT_Y`), e.g. `"cps"`
- `x::Vector{Float64}` — angle values (typically 2θ)
- `y::Vector{Float64}` — intensity values
- `metadata::Dict{String, String}` — all raw header key-value pairs
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
