```@meta
CurrentModule = RigakuFiles
```

# RigakuFiles.jl

```@docs
RigakuFiles
```

RigakuFiles.jl reads the text-based output files emitted by Rigaku X-ray diffractometers (SmartLab, MiniFlex, Ultima, and similar SmartLabStudio exports). Both the canonical `.ras` format (with `*RAS_HEADER_START` / `*RAS_INT_START` section markers) and the simplified `.txt` export are supported. Multi-scan files are handled transparently.

The package is deliberately small: it parses a file into a concrete [`RigakuScan`](@ref) struct with the typical scan metadata surfaced as fields, and leaves the raw header dictionary around for anything else you need. There is no analysis code here — downstream packages (fitting, plotting, peak finding) build on top of this struct.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/garrekstemo/RigakuFiles.jl")
```

```julia
using RigakuFiles
```

## Why this exists

Rigaku's own software emits several closely-related text layouts, and many academic groups maintain private one-off parsers that break every time a firmware update shifts a field. This package normalizes parsing of the common variants so you can write analysis code against a stable Julia struct.

## Issues and contributions

If you run into a Rigaku file this package mis-parses — especially one from a firmware version or instrument line not yet covered — please open an issue at [github.com/garrekstemo/RigakuFiles.jl/issues](https://github.com/garrekstemo/RigakuFiles.jl/issues). A minimal excerpt of the offending file (sample names can be redacted) is the most helpful thing to attach.
