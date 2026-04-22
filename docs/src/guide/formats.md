```@meta
CurrentModule = RigakuFiles
```

# File formats

[`RigakuFile`](@ref) auto-detects which of the two common Rigaku text layouts a file uses.

## Canonical `.ras`

Canonical `.ras` files are plain text with section markers. A typical single-scan file looks like this:

```
*RAS_DATA_START
*RAS_HEADER_START
*FILE_SAMPLE "ZIF-62 Test"
*HW_XG_TARGET_NAME "Cu"
*HW_XG_WAVE_LENGTH_ALPHA1 "1.540593"
*MEAS_SCAN_AXIS_X "TwoThetaTheta"
*MEAS_SCAN_UNIT_X "deg"
*MEAS_SCAN_UNIT_Y "cps"
...
*RAS_HEADER_END
*RAS_INT_START
10.0000 100.5
10.5000 150.2
11.0000 300.8
*RAS_INT_END
*RAS_DATA_END
```

Multi-scan files contain several `*RAS_HEADER_START … *RAS_INT_END` blocks inside a single outer `*RAS_DATA_START … *RAS_DATA_END` wrapper; each block is parsed into its own [`RigakuScan`](@ref) element of the returned [`RigakuFile`](@ref).

Some exports include a third column after intensity (attenuator coefficient). It is parsed and silently discarded — only the first two columns are stored.

## Simplified `.txt`

The simplified text export drops the section markers. Metadata lines still start with `*KEY "VALUE"`, annotations with `#key=value`, and the data block is just whitespace-separated columns:

```
*FILE_SAMPLE "ZIF-62 Test"
*HW_XG_TARGET_NAME "Cu"
*HW_XG_WAVE_LENGTH_ALPHA1 "1.540593"
*MEAS_SCAN_UNIT_X "deg"
*MEAS_SCAN_UNIT_Y "cps"
#Intensity_unit=cps
10.0000 100.5
10.5000 150.2
11.0000 300.8
```

Annotation lines are stored in `scan.metadata` under `"_" * key` (so `#Intensity_unit=cps` becomes `scan.metadata["_Intensity_unit"] == "cps"`) to avoid colliding with regular `*KEY` entries.

## Missing-field sentinels

To keep [`RigakuScan`](@ref) concretely typed, missing metadata uses sentinel values rather than `missing`:

| Field type | Sentinel |
|------------|----------|
| `String`   | `""` |
| `Float64`  | `0.0` |
| `DateTime` | `DateTime(1)` (year 0001) |

Check `haskey(scan.metadata, "HW_XG_WAVE_LENGTH_ALPHA2")` when you need to distinguish a genuinely recorded zero from a missing value.

## Datetime formats

`MEAS_SCAN_START_TIME` and `MEAS_SCAN_END_TIME` are parsed using these formats, in order:

1. `"m/d/y H:M:S"` (US style, as emitted by most Rigaku firmware)
2. `"y/m/d H:M:S"` (occasional alternate ordering)

Unparseable non-empty timestamps emit a warning and fall back to `DateTime(1)`.

## Encoding and line endings

Files are read as plain text via `readlines`. Both Unix (`LF`) and Windows (`CRLF`) line endings are supported. Files with non-ASCII characters in metadata strings (e.g. sample names in Japanese) should be UTF-8 encoded. Older Shift-JIS Rigaku exports are not currently decoded automatically — convert to UTF-8 first, e.g. with `iconv -f SHIFT-JIS -t UTF-8`.
