using Coverage: Coverage
using CoverageBase
using Test

@testset "locate tests" begin
    @test isdir(CoverageBase.julia_top())
    tn = testnames()
    @test !isempty(tn)
    @test "goto" in tn
end

@testset "locate source" begin
    thisfile = pathof(CoverageBase)
    @test fixpath(thisfile) == thisfile
    @test fixpath("something/relative.jl") == "base/something/relative.jl"
    files = [Coverage.FileCoverage(f[2], "", Coverage.CovCount[]) for f in Base._included_files]
    @test all(isabspath(c.filename) for c in files) || files
    fixpath!(files)
    push!(files, Coverage.FileCoverage("test/goto.jl", "", Coverage.CovCount[]))
    for c in files
        @test !isabspath(c.filename) || c
        @test c.filename == "test/goto.jl" || startswith(c.filename, "base") || startswith(c.filename, "stdlib") || c
        lpath = CoverageBase.fixabspath(c.filename)
        @test isabspath(lpath)
        @test isfile(lpath)
        @test fixpath(lpath) == c.filename
    end
    files[1].source = "fakesource"
    push!(files, Coverage.FileCoverage(thisfile, "", Coverage.CovCount[]))
    push!(files, Coverage.FileCoverage(thisfile * "_nonexistant", "", Coverage.CovCount[]))
    readsource!(files)
    @test files[1].source == "fakesource"
    @test pop!(files).source == ""
    @test pop!(files).source == read(thisfile, String)
    @test all(!isempty(c.source) for c in files) || files
end

@testset "run tests" begin
    @test runtests(["goto", "Test"])
    @test_warn "ERROR: failed process" @test !runtests(["fail_does_not_even_exist", "goto"])
end
