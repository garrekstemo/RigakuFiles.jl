# RigakuFiles.jl

[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Julia parser for Rigaku SmartLab XRD data files (`.ras` and `.txt` formats).

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/garrekstemo/RigakuFiles.jl")
```

## Usage

```julia
using RigakuFiles

# Read a single scan
scan = read_scan("data/sample.ras")

scan.two_theta  # 2θ values
scan.intensity  # counts
scan.metadata   # measurement parameters

# Read multi-scan files
scans = read_scans("data/multi_scan.ras")

# X-ray wavelengths
wavelength_alpha1(scan)
wavelength_alpha2(scan)
```

## Supported Formats

| Format | Description |
|--------|-------------|
| `.ras` | Rigaku native binary/text format (single and multi-scan) |
| `.txt` | Simplified text export |
