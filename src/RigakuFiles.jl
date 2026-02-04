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
