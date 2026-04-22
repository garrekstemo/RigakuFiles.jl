"""
    RigakuFiles

Read Rigaku X-ray diffractometer output files (canonical `.ras` with `*RAS_*` section
markers, and the simplified `.txt` export) into a [`RigakuFile`](@ref) container of
[`RigakuScan`](@ref) elements.

`RigakuFile(path)` is the single entry point. Use Base array verbs (`only`, `first`,
`length`, indexing, iteration) to navigate. Common header fields are exposed as
struct fields on `RigakuScan`; the full raw header is preserved in `scan.metadata`.
"""
module RigakuFiles

using Dates

include("types.jl")
include("parser.jl")
include("utils.jl")

export AbstractRigakuSpectrum, RigakuScan, RigakuFile
export wavelength_alpha1, wavelength_alpha2, wavelength_beta
export scan_step, scan_speed, detector

end
