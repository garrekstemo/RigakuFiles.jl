# RigakuFiles.jl

[![CI](https://github.com/garrekstemo/RigakuFiles.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/garrekstemo/RigakuFiles.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/garrekstemo/RigakuFiles.jl/graph/badge.svg)](https://codecov.io/gh/garrekstemo/RigakuFiles.jl)
[![stable](https://img.shields.io/badge/docs-stable-blue)](https://garrekstemo.github.io/RigakuFiles.jl/stable/)
[![dev](https://img.shields.io/badge/docs-dev-blue)](https://garrekstemo.github.io/RigakuFiles.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Read Rigaku X-ray diffractometer output files (SmartLab, MiniFlex, Ultima) in Julia.

## Highlights

- Canonical `.ras` (with `*RAS_HEADER_START` / `*RAS_INT_START` markers) and simplified `.txt` exports
- Multi-scan files in a single read
- Common metadata surfaced as typed fields; the full raw header is preserved too
- Three-column attenuator data tolerated
- Works with either Unix or Windows line endings

## Installation

```julia
julia>]
pkg> add RigakuFiles
```

```julia
using RigakuFiles
```

## Quick start

```julia
using RigakuFiles

scan = read_scan("mysample.ras")

scan.sample      # "ZIF-62 Test"
scan.target      # "Cu"
scan.wavelength  # 1.540593  (Kα1, Å)
scan.x           # Vector{Float64} of 2θ values
scan.y           # Vector{Float64} of intensities
```

## Multi-scan files

```julia
scans = read_scans("multiscan.ras")
for s in scans
    println(s.comment, ": ", length(s), " points")
end
```

Calling `read_scan` on a multi-scan file returns the first scan and emits a warning.

## Accessors

```julia
wavelength_alpha1(scan)   # Kα1 wavelength (Å)
wavelength_alpha2(scan)   # Kα2 wavelength (Å), or 0.0 if not recorded
wavelength_beta(scan)     # Kβ wavelength (Å),  or 0.0 if not recorded
scan_step(scan)           # Scan step size
scan_speed(scan)          # Scan speed
detector(scan)            # Detector name, e.g. "HyPix3000(H)"
```

Anything not exposed by the accessors is available in `scan.metadata` (a `Dict{String, String}`). See the [documentation](https://garrekstemo.github.io/RigakuFiles.jl/stable/) for the full field list and file-format notes.

## Issues and contributions

If you run into a Rigaku file this package mis-parses — especially one from a firmware version or instrument line not yet covered — please [open an issue](https://github.com/garrekstemo/RigakuFiles.jl/issues). A minimal excerpt of the offending file (sample names can be redacted) is the most helpful thing to attach.
