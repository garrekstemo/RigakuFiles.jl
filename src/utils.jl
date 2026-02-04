"""
    wavelength_alpha1(s::AbstractRigakuSpectrum) → Float64

Return the Kα1 wavelength in Angstrom. Shorthand for `s.wavelength`.
"""
wavelength_alpha1(s::AbstractRigakuSpectrum) = s.wavelength

"""
    wavelength_alpha2(s::AbstractRigakuSpectrum) → Float64

Return the Kα2 wavelength in Angstrom, or `0.0` if not recorded.
"""
function wavelength_alpha2(s::AbstractRigakuSpectrum)
    wl = get(s.metadata, "HW_XG_WAVE_LENGTH_ALPHA2", "")
    return something(tryparse(Float64, wl), 0.0)
end

"""
    wavelength_beta(s::AbstractRigakuSpectrum) → Float64

Return the Kβ wavelength in Angstrom, or `0.0` if not recorded.
"""
function wavelength_beta(s::AbstractRigakuSpectrum)
    wl = get(s.metadata, "HW_XG_WAVE_LENGTH_BETA", "")
    return something(tryparse(Float64, wl), 0.0)
end

"""
    scan_step(s::AbstractRigakuSpectrum) → Float64

Return the scan step size, or `0.0` if not recorded.
"""
function scan_step(s::AbstractRigakuSpectrum)
    step = get(s.metadata, "MEAS_SCAN_STEP", "")
    return something(tryparse(Float64, step), 0.0)
end

"""
    scan_speed(s::AbstractRigakuSpectrum) → Float64

Return the scan speed, or `0.0` if not recorded.
"""
function scan_speed(s::AbstractRigakuSpectrum)
    spd = get(s.metadata, "MEAS_SCAN_SPEED", "")
    return something(tryparse(Float64, spd), 0.0)
end

"""
    detector(s::AbstractRigakuSpectrum) → String

Return the detector name, or `""` if not recorded.
"""
function detector(s::AbstractRigakuSpectrum)
    return get(s.metadata, "HW_COUNTER_SELECT_NAME",
               get(s.metadata, "HW_COUNTER_NAME-0", ""))
end
