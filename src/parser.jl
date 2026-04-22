# Metadata line pattern: *KEY "VALUE"
const _METADATA_RE = r"^\*(\S+)\s+\"(.*)\""

# Annotation line pattern: #key=value
const _ANNOTATION_RE = r"^#(\S+?)=(.*)"

# Datetime formats seen in Rigaku firmware exports
const _DATE_FORMATS = (dateformat"m/d/y H:M:S", dateformat"y/m/d H:M:S")

"""
    RigakuFile(path::AbstractString) -> RigakuFile

Read a Rigaku `.ras` or exported `.txt` file into a [`RigakuFile`](@ref)
container holding one or more [`RigakuScan`](@ref)s.

Auto-detects the file format (canonical RAS with `*RAS_HEADER_START` /
`*RAS_INT_START` section markers vs simplified `.txt` export).

Use Base array verbs to navigate: `only(file)` for a strict single-scan
assertion, `first(file)`, `file[i]`, iteration, `length(file)`.

# Throws
- `ArgumentError` if the file is empty or contains no parseable scans.
- `SystemError` if the file cannot be read from disk.

# Examples
```julia
# single-scan file (throws if the file actually contains >1 scan)
scan = only(RigakuFile("sample.ras"))

# multi-scan file
file = RigakuFile("multiscan.ras")
length(file)   # number of scans
for scan in file
    println(scan.sample, ": ", length(scan.x), " points")
end
```
"""
RigakuFile(path::AbstractString) = RigakuFile(String(path), _parse_file(path))

function _parse_file(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("Empty file: $path"))

    has_ras_markers = any(l -> startswith(l, "*RAS_DATA_START") ||
                                startswith(l, "*RAS_HEADER_START"), lines)

    return has_ras_markers ? _parse_ras(lines) : [_parse_txt(lines)]
end

# Parse simplified .txt export (no *RAS_HEADER_START section markers).
# Metadata lines begin with `*`, annotations with `#`, everything else
# is treated as whitespace-separated numeric data (first two columns).
function _parse_txt(lines::Vector{String})
    metadata = Dict{String, String}()
    x = Float64[]
    y = Float64[]

    for line in lines
        if startswith(line, '*')
            m = match(_METADATA_RE, line)
            if m !== nothing
                metadata[m.captures[1]] = m.captures[2]
            end
        elseif startswith(line, '#')
            m = match(_ANNOTATION_RE, line)
            if m !== nothing
                metadata["_" * m.captures[1]] = strip(m.captures[2])
            end
        else
            _push_data!(x, y, line)
        end
    end

    return _build_scan(metadata, x, y)
end

# Parse canonical .ras format with *RAS_HEADER_START / *RAS_INT_START markers.
# Supports multi-scan files where each scan is wrapped in its own header/data
# block. The outer *RAS_DATA_START / *RAS_DATA_END pair is tolerated but not
# required.
function _parse_ras(lines::Vector{String})
    scans = RigakuScan[]
    i = 1
    n = length(lines)

    while i <= n
        if startswith(lines[i], "*RAS_HEADER_START")
            metadata = Dict{String, String}()
            i += 1

            while i <= n && !startswith(lines[i], "*RAS_HEADER_END")
                m = match(_METADATA_RE, lines[i])
                if m !== nothing
                    metadata[m.captures[1]] = m.captures[2]
                end
                i += 1
            end
            i += 1  # skip *RAS_HEADER_END

            x = Float64[]
            y = Float64[]
            if i <= n && startswith(lines[i], "*RAS_INT_START")
                i += 1
                while i <= n && !startswith(lines[i], "*RAS_INT_END")
                    _push_data!(x, y, lines[i])
                    i += 1
                end
                i += 1  # skip *RAS_INT_END
            end

            push!(scans, _build_scan(metadata, x, y))
        else
            i += 1
        end
    end

    isempty(scans) && throw(ArgumentError("No scans found in RAS file: missing *RAS_HEADER_START markers"))
    return scans
end

# Parse one whitespace-separated data line and append the first two numeric
# columns to `x` and `y`. Third-column attenuator values (present in some
# `.ras` exports) are intentionally ignored. Lines that fail to parse as
# numbers are silently skipped, matching the behavior of Rigaku's own tools.
function _push_data!(x::Vector{Float64}, y::Vector{Float64}, line::AbstractString)
    parts = split(line)
    length(parts) >= 2 || return
    xval = tryparse(Float64, parts[1])
    yval = tryparse(Float64, parts[2])
    if xval !== nothing && yval !== nothing
        push!(x, xval)
        push!(y, yval)
    end
    return
end

# Build a RigakuScan from a parsed metadata dict and x/y data vectors.
# Missing header keys fall back to empty strings, `0.0`, or `DateTime(1)`
# — see the RigakuScan docstring for the full sentinel table.
function _build_scan(metadata::Dict{String, String}, x::Vector{Float64}, y::Vector{Float64})
    sample = get(metadata, "FILE_SAMPLE", "")
    comment = get(metadata, "FILE_COMMENT", "")
    instrument = get(metadata, "FILE_SYSTEM_NAME", "")
    target = get(metadata, "HW_XG_TARGET_NAME", "")

    wl_str = get(metadata, "HW_XG_WAVE_LENGTH_ALPHA1", "")
    wavelength = something(tryparse(Float64, wl_str), 0.0)

    scan_axis = get(metadata, "MEAS_SCAN_AXIS_X", "")
    scan_mode = get(metadata, "MEAS_SCAN_MODE", "")

    xunits = get(metadata, "MEAS_SCAN_UNIT_X", "deg")
    yunits = get(metadata, "MEAS_SCAN_UNIT_Y",
                 get(metadata, "_Intensity_unit", ""))

    start_time = _parse_datetime(get(metadata, "MEAS_SCAN_START_TIME", ""))
    end_time = _parse_datetime(get(metadata, "MEAS_SCAN_END_TIME", ""))

    return RigakuScan(sample, comment, instrument, target, wavelength,
                      scan_axis, scan_mode, start_time, end_time,
                      xunits, yunits, x, y, metadata)
end

# Parse a datetime string using the formats Rigaku firmware is known to emit.
# Returns `DateTime(1)` (year 0001) as the "missing" sentinel when the input
# is empty; warns once per bad string and returns the same sentinel when the
# input is non-empty but unparseable.
function _parse_datetime(s::AbstractString)
    isempty(s) && return DateTime(1)
    for fmt in _DATE_FORMATS
        dt = tryparse(DateTime, s, fmt)
        dt !== nothing && return dt
    end
    @warn "Could not parse Rigaku datetime: $(repr(s))"
    return DateTime(1)
end
