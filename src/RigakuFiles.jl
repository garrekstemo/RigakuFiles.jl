"""
    RigakuFiles

Read Rigaku X-ray diffractometer output files (canonical `.ras` with `*RAS_*` section
markers, and the simplified `.txt` export) into [`RigakuScan`](@ref) structs.

Use [`read_scan`](@ref) for single-scan files or [`read_scans`](@ref) for multi-scan
files. Common header fields are exposed as struct fields; the full raw header is
preserved in `scan.metadata`.
"""
module RigakuFiles

using Dates

include("types.jl")
include("parser.jl")
include("utils.jl")

export AbstractRigakuSpectrum, RigakuScan
export read_scan, read_scans
export wavelength_alpha1, wavelength_alpha2, wavelength_beta
export scan_step, scan_speed, detector

end
