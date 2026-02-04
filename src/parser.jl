# Metadata line pattern: *KEY "VALUE"
const _METADATA_RE = r"^\*(\S+)\s+\"(.*)\""

# Annotation line pattern: #key=value
const _ANNOTATION_RE = r"^#(\S+?)=(.*)"

"""
    read_scan(path::String) → RigakuScan

Read a single scan from a Rigaku `.ras` or exported `.txt` file.
Auto-detects the file format (canonical RAS with section markers vs
simplified text export).

If the file contains multiple scans, returns the first and emits a warning.
Use [`read_scans`](@ref) to load all scans from a multi-scan file.

# Examples
```julia
scan = read_scan("data/sample.txt")
scan.x   # 2θ values
scan.y   # intensity values
scan.target  # "Cu"
```
"""
function read_scan(path::String)
    scans = read_scans(path)
    if length(scans) > 1
        @warn "File contains $(length(scans)) scans, returning first. Use read_scans() for all."
    end
    return scans[1]
end

"""
    read_scans(path::String) → Vector{RigakuScan}

Read all scans from a Rigaku `.ras` or exported `.txt` file.
Returns a vector of `RigakuScan` objects (length 1 for single-scan files).

# Examples
```julia
scans = read_scans("data/multiscan.ras")
for s in scans
    println(s.sample, ": ", length(s.x), " points")
end
```
"""
function read_scans(path::String)
    lines = readlines(path)
    isempty(lines) && error("Empty file: $path")

    has_ras_markers = any(l -> startswith(l, "*RAS_DATA_START"), lines)

    if has_ras_markers
        return _parse_ras(lines)
    else
        return [_parse_txt(lines)]
    end
end

# Parse simplified .txt export (no section markers)
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
            parts = split(line)
            if length(parts) >= 2
                xval = tryparse(Float64, parts[1])
                yval = tryparse(Float64, parts[2])
                if xval !== nothing && yval !== nothing
                    push!(x, xval)
                    push!(y, yval)
                end
            end
        end
    end

    return _build_scan(metadata, x, y)
end

# Parse canonical .ras format (with *RAS_DATA_START markers)
function _parse_ras(lines::Vector{String})
    scans = RigakuScan[]
    i = 1
    n = length(lines)

    while i <= n
        if startswith(lines[i], "*RAS_HEADER_START")
            metadata = Dict{String, String}()
            i += 1

            # Read header block
            while i <= n && !startswith(lines[i], "*RAS_HEADER_END")
                m = match(_METADATA_RE, lines[i])
                if m !== nothing
                    metadata[m.captures[1]] = m.captures[2]
                end
                i += 1
            end
            i += 1  # skip *RAS_HEADER_END

            # Read data block
            x = Float64[]
            y = Float64[]
            if i <= n && startswith(lines[i], "*RAS_INT_START")
                i += 1
                while i <= n && !startswith(lines[i], "*RAS_INT_END")
                    parts = split(lines[i])
                    if length(parts) >= 2
                        xval = tryparse(Float64, parts[1])
                        yval = tryparse(Float64, parts[2])
                        if xval !== nothing && yval !== nothing
                            push!(x, xval)
                            push!(y, yval)
                        end
                    end
                    i += 1
                end
                i += 1  # skip *RAS_INT_END
            end

            push!(scans, _build_scan(metadata, x, y))
        else
            i += 1
        end
    end

    isempty(scans) && error("No scans found in RAS file")
    return scans
end

# Construct a RigakuScan from parsed metadata and data vectors
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
    # Check both metadata and annotations for intensity units
    yunits = get(metadata, "MEAS_SCAN_UNIT_Y",
                 get(metadata, "_Intensity_unit", ""))

    start_time = _parse_datetime(get(metadata, "MEAS_SCAN_START_TIME", ""))
    end_time = _parse_datetime(get(metadata, "MEAS_SCAN_END_TIME", ""))

    return RigakuScan(sample, comment, instrument, target, wavelength,
                      scan_axis, scan_mode, start_time, end_time,
                      xunits, yunits, x, y, metadata)
end

# Parse datetime strings in Rigaku format (MM/DD/YYYY HH:MM:SS)
function _parse_datetime(s::String)
    isempty(s) && return DateTime(1)
    try
        return DateTime(s, dateformat"m/d/y H:M:S")
    catch
        try
            return DateTime(s, dateformat"y/m/d H:M:S")
        catch
            return DateTime(1)
        end
    end
end
