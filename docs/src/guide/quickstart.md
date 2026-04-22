```@meta
CurrentModule = RigakuFiles
```

# Quick start

## Loading a single scan

For files that contain exactly one scan, use `only` to assert that expectation:

```julia
using RigakuFiles

scan = only(RigakuFile("mysample.ras"))

scan.sample      # "ZIF-62 Test"
scan.target      # "Cu"
scan.wavelength  # 1.540593  (Kα1, Å)
scan.x           # Vector{Float64} of 2θ values
scan.y           # Vector{Float64} of intensities
```

If the file turns out to contain more than one scan, `only` throws `ArgumentError` — so single-scan code fails loudly instead of silently discarding data.

## Multi-scan files

Many `.ras` files contain more than one scan (e.g. a low-angle and high-angle pair measured in one run). A `RigakuFile` is an `AbstractVector{RigakuScan}`, so iteration, indexing, and `length` all work out of the box:

```julia
file = RigakuFile("multiscan.ras")

length(file)     # number of scans
file[1]          # first scan
file[end]        # last scan

for s in file
    println(s.comment, ": ", length(s), " points")
end
```

If you want the first scan of a possibly-multi-scan file and are fine with ignoring the rest, say so explicitly:

```julia
scan = first(RigakuFile("maybe_multi.ras"))
```

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

scan = only(RigakuFile("mysample.ras"))
fig, ax, _ = lines(scan.x, scan.y;
    axis = (xlabel = "2θ (deg)", ylabel = "Intensity (cps)"))
fig
```

## Multi-scan overlays

```julia
using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1], xlabel = "2θ (deg)", ylabel = "Intensity")
for s in RigakuFile("series.ras")
    lines!(ax, s.x, s.y; label = s.comment)
end
axislegend(ax)
fig
```
