using RigakuFiles
using Dates
using Test
using Aqua

const DATADIR = joinpath(@__DIR__, "data")

@testset "RigakuFiles" begin

    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(RigakuFiles; deps_compat = (check_extras = false,))
    end

    @testset "Simplified .txt format" begin
        scan = only(RigakuFile(joinpath(DATADIR, "simple.txt")))

        @test scan isa RigakuScan
        @test scan isa AbstractRigakuSpectrum
        @test scan.sample == "ZIF-62 Test"
        @test scan.comment == "Test powder scan"
        @test scan.instrument == "SmartLabXE"
        @test scan.target == "Cu"
        @test scan.wavelength ≈ 1.540593
        @test scan.scan_axis == "TwoThetaTheta"
        @test scan.scan_mode == "CONTINUOUS"
        @test scan.xunits == "deg"
        @test scan.yunits == "cps"

        @test length(scan) == 5
        @test size(scan) == (5,)
        @test scan.x == [10.0, 10.5, 11.0, 11.5, 12.0]
        @test scan.y == [100.5, 150.2, 300.8, 200.1, 120.3]

        @test scan.start_time == DateTime(2025, 1, 15, 10, 30, 0)
        @test scan.end_time == DateTime(2025, 1, 15, 10, 31, 0)

        # Utility accessors
        @test wavelength_alpha1(scan) ≈ 1.540593
        @test wavelength_alpha2(scan) ≈ 1.544414
        @test wavelength_beta(scan) ≈ 1.392246
        @test scan_step(scan) ≈ 0.5
        @test scan_speed(scan) ≈ 2.0
        @test detector(scan) == "HyPix3000(H)"

        # RigakuFile is a 1-element AbstractVector for single-scan files
        file = RigakuFile(joinpath(DATADIR, "simple.txt"))
        @test length(file) == 1
        @test file[1].sample == "ZIF-62 Test"
        @test first(file).sample == "ZIF-62 Test"
    end

    @testset "Canonical .ras format — multi-scan" begin
        file = RigakuFile(joinpath(DATADIR, "multiscan.ras"))

        @test length(file) == 2
        @test size(file) == (2,)

        s1 = file[1]
        @test s1.comment == "Low angle scan"
        @test s1.sample == "TestSample"
        @test s1.target == "Cu"
        @test s1.wavelength ≈ 1.540593
        @test length(s1) == 3
        @test s1.x == [10.0, 10.5, 11.0]
        @test s1.y == [100.5, 150.2, 300.8]
        @test s1.start_time == DateTime(2025, 1, 15, 10, 30, 0)

        s2 = file[2]
        @test s2.comment == "High angle scan"
        @test length(s2) == 3
        @test s2.x == [20.0, 20.5, 21.0]
        @test s2.y == [80.3, 90.1, 110.7]
        @test s2.start_time == DateTime(2025, 1, 15, 10, 35, 0)

        # only() throws on multi-scan files (strict "I expect exactly one")
        @test_throws ArgumentError only(file)

        # first() and iteration still work without warning
        @test first(file).comment == "Low angle scan"
        comments = [s.comment for s in file]
        @test comments == ["Low angle scan", "High angle scan"]
    end

    @testset "Three-column .ras format" begin
        scan = only(RigakuFile(joinpath(DATADIR, "three_column.ras")))

        @test scan.sample == "ThreeColSample"
        @test scan.target == "Mo"
        @test scan.wavelength ≈ 0.709319
        @test scan.yunits == "counts"
        @test length(scan) == 4
        @test scan.x == [10.0, 10.5, 11.0, 11.5]
        @test scan.y == [250.0, 310.5, 480.2, 390.7]
    end

    @testset "Minimal .txt — missing metadata defaults" begin
        scan = only(RigakuFile(joinpath(DATADIR, "minimal.txt")))

        @test scan.sample == ""
        @test scan.comment == ""
        @test scan.instrument == ""
        @test scan.target == ""
        @test scan.wavelength == 0.0
        @test scan.xunits == "deg"  # default
        @test scan.start_time == DateTime(1)

        @test length(scan) == 2
        @test scan.x == [10.0, 20.0]
        @test scan.y == [50.0, 60.0]

        # Accessor sentinels for missing metadata
        @test wavelength_alpha2(scan) == 0.0
        @test wavelength_beta(scan) == 0.0
        @test scan_step(scan) == 0.0
        @test scan_speed(scan) == 0.0
        @test detector(scan) == ""
    end

    @testset "Show methods" begin
        scan = only(RigakuFile(joinpath(DATADIR, "simple.txt")))

        compact = sprint(show, scan)
        @test contains(compact, "RigakuScan")
        @test contains(compact, "ZIF-62 Test")
        @test contains(compact, "5 points")

        full = sprint(show, MIME("text/plain"), scan)
        @test contains(full, "RigakuScan")
        @test contains(full, "SmartLabXE")
        @test contains(full, "Cu")
        @test contains(full, "1.540593")
        @test contains(full, "TwoThetaTheta")
        @test contains(full, "Acquired:")

        # Show on a scan with missing timestamp should not print Acquired line
        minimal = only(RigakuFile(joinpath(DATADIR, "minimal.txt")))
        minimal_show = sprint(show, MIME("text/plain"), minimal)
        @test !contains(minimal_show, "Acquired:")
        @test !contains(minimal_show, "0001")

        # RigakuFile show
        file = RigakuFile(joinpath(DATADIR, "multiscan.ras"))
        file_show = sprint(show, MIME("text/plain"), file)
        @test contains(file_show, "2-element RigakuFile")
        @test contains(file_show, "multiscan.ras")
        @test contains(file_show, "[1]")
        @test contains(file_show, "[2]")
    end

    @testset "Raw metadata access" begin
        scan = only(RigakuFile(joinpath(DATADIR, "simple.txt")))

        @test haskey(scan.metadata, "FILE_TYPE")
        @test scan.metadata["FILE_TYPE"] == "RAS_RAW"
        @test scan.metadata["MEAS_SCAN_START"] == "10.0000"
        @test scan.metadata["MEAS_SCAN_STOP"] == "12.0000"

        # Annotations stored with _ prefix
        @test scan.metadata["_Intensity_unit"] == "cps"
        @test scan.metadata["_Attenuator_coefficient"] == "1.0000"
    end

    @testset "Error paths" begin
        @test_throws ArgumentError RigakuFile(joinpath(DATADIR, "empty.txt"))

        # Non-existent file surfaces a SystemError from readlines
        missing_path = joinpath(DATADIR, "does_not_exist.txt")
        @test_throws SystemError RigakuFile(missing_path)
    end

    @testset "Type hierarchy" begin
        @test RigakuFile <: AbstractVector{RigakuScan}
        @test RigakuScan <: AbstractRigakuSpectrum
    end

    @testset "RAS header with no *RAS_INT_START block" begin
        # Header-only RAS file: the header parses, the data vectors are empty.
        scan = only(RigakuFile(joinpath(DATADIR, "no_int_block.ras")))
        @test scan.sample == "HeaderOnly"
        @test scan.target == "Cu"
        @test isempty(scan.x)
        @test isempty(scan.y)
        @test length(scan) == 0
    end

    @testset "Alternate datetime format y/m/d H:M:S" begin
        scan = only(RigakuFile(joinpath(DATADIR, "iso_date.txt")))
        @test scan.start_time == DateTime(2025, 3, 14, 9, 0, 0)
        @test scan.end_time == DateTime(2025, 3, 14, 9, 5, 0)
    end

    @testset "Unparseable datetime warns and returns DateTime(1)" begin
        scan = @test_logs (:warn, r"Could not parse Rigaku datetime") match_mode = :any only(RigakuFile(joinpath(DATADIR, "bad_date.txt")))
        @test scan.start_time == DateTime(1)
        @test scan.sample == "BadDateSample"
    end

    @testset "Legacy HW_COUNTER_NAME-0 fallback" begin
        scan = only(RigakuFile(joinpath(DATADIR, "counter_name.ras")))
        @test detector(scan) == "D/teX Ultra"
        @test length(scan) == 2
    end

    @testset "CRLF line endings" begin
        scan = only(RigakuFile(joinpath(DATADIR, "crlf.txt")))
        @test scan.sample == "CRLFSample"
        @test scan.target == "Cu"
        @test scan.wavelength ≈ 1.540593
        @test scan.x == [10.0, 11.0, 12.0]
        @test scan.y == [100.0, 200.0, 300.0]
    end

    @testset "AbstractString path arguments" begin
        # SubString is the canonical case that breaks String-typed signatures
        full_path = joinpath(DATADIR, "simple.txt")
        sub_path = SubString(full_path, 1, length(full_path))
        scan = only(RigakuFile(sub_path))
        @test scan.sample == "ZIF-62 Test"
    end

end
