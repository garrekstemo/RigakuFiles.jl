using RigakuFiles
using Dates
using Test

const DATADIR = joinpath(@__DIR__, "data")

@testset "RigakuFiles" begin

    @testset "Simplified .txt format" begin
        scan = read_scan(joinpath(DATADIR, "simple.txt"))

        @test scan isa RigakuScan
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

        # read_scans returns a vector
        scans = read_scans(joinpath(DATADIR, "simple.txt"))
        @test length(scans) == 1
        @test scans[1].sample == "ZIF-62 Test"
    end

    @testset "Canonical .ras format — multi-scan" begin
        scans = read_scans(joinpath(DATADIR, "multiscan.ras"))

        @test length(scans) == 2

        s1 = scans[1]
        @test s1.comment == "Low angle scan"
        @test s1.sample == "TestSample"
        @test s1.target == "Cu"
        @test s1.wavelength ≈ 1.540593
        @test length(s1) == 3
        @test s1.x == [10.0, 10.5, 11.0]
        @test s1.y == [100.5, 150.2, 300.8]
        @test s1.start_time == DateTime(2025, 1, 15, 10, 30, 0)

        s2 = scans[2]
        @test s2.comment == "High angle scan"
        @test length(s2) == 3
        @test s2.x == [20.0, 20.5, 21.0]
        @test s2.y == [80.3, 90.1, 110.7]
        @test s2.start_time == DateTime(2025, 1, 15, 10, 35, 0)

        # read_scan on multi-scan file returns first + warns
        scan = @test_logs (:warn, r"2 scans") read_scan(joinpath(DATADIR, "multiscan.ras"))
        @test scan.comment == "Low angle scan"
    end

    @testset "Three-column .ras format" begin
        scan = read_scan(joinpath(DATADIR, "three_column.ras"))

        @test scan.sample == "ThreeColSample"
        @test scan.target == "Mo"
        @test scan.wavelength ≈ 0.709319
        @test scan.yunits == "counts"
        @test length(scan) == 4
        @test scan.x == [10.0, 10.5, 11.0, 11.5]
        @test scan.y == [250.0, 310.5, 480.2, 390.7]
    end

    @testset "Minimal .txt — missing metadata defaults" begin
        scan = read_scan(joinpath(DATADIR, "minimal.txt"))

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
    end

    @testset "Show methods" begin
        scan = read_scan(joinpath(DATADIR, "simple.txt"))

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
    end

    @testset "Raw metadata access" begin
        scan = read_scan(joinpath(DATADIR, "simple.txt"))

        @test haskey(scan.metadata, "FILE_TYPE")
        @test scan.metadata["FILE_TYPE"] == "RAS_RAW"
        @test scan.metadata["MEAS_SCAN_START"] == "10.0000"
        @test scan.metadata["MEAS_SCAN_STOP"] == "12.0000"

        # Annotations stored with _ prefix
        @test scan.metadata["_Intensity_unit"] == "cps"
        @test scan.metadata["_Attenuator_coefficient"] == "1.0000"
    end

end
