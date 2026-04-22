```@meta
CurrentModule = RigakuFiles
```

# Quick start

## Loading a single scan

```julia
using RigakuFiles

scan = read_scan("mysample.ras")
# or, equivalently:
scan = RigakuScan("mysample.ras")

scan.sample      # "ZIF-62 Test"
scan.target      # "Cu"
scan.wavelength  # 1.540593  (Kα1, Å)
scan.x           # Vector{Float64} of 2θ values
scan.y           # Vector{Float64} of intensities
```

`read_scan` and the `RigakuScan(path)` outer constructor are equivalent — pick whichever reads better in context.

## Multi-scan files

Many `.ras` files contain more than one scan (e.g. a low-angle and high-angle pair measured in one run). Use [`read_scans`](@ref) to load all of them:

```julia
scans = read_scans("multiscan.ras")
for s in scans
    println(s.comment, ": ", length(s), " points")
end
```

Calling `read_scan` on a multi-scan file returns the first scan and emits a warning.

## Metadata accessors

Convenience accessors for common header fields:

```julia
wavelength_alpha1(scan)   # Kα1 wavelength (Å)
wavelength_alpha2(scan)   # Kα2 wavelength (Å), or 0.0 if not recorded
wavelength_beta(scan)     # Kβ wavelength (Å),  or 0.0 if not recorded
scan_step(scan)           # Scan step size
scan_speed(scan)          # Scan speed
detector(scan)            # Detector name, e.g. "HyPix3000(H)"
```

Everything else is preserved in `scan.metadata` (a `Dict{String, String}`):

```julia
scan.metadata["HW_XG_WAVE_LENGTH_ALPHA1"]  # "1.540593"
scan.metadata["_Intensity_unit"]           # "cps"  (from #Intensity_unit=cps annotation)
```

## Plotting

Since `RigakuScan` has `x` and `y` as plain `Vector{Float64}`, any Julia plotting package works directly:

```julia
using CairoMakie

scan = read_scan("mysample.ras")
fig, ax, _ = lines(scan.x, scan.y;
    axis = (xlabel = "2θ (deg)", ylabel = "Intensity (cps)"))
fig
```

## Multi-scan overlays

```julia
using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1], xlabel = "2θ (deg)", ylabel = "Intensity")
for s in read_scans("series.ras")
    lines!(ax, s.x, s.y; label = s.comment)
end
axislegend(ax)
fig
```
