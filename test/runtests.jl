using CoverageBase
using Coverage
using Base.Test

@test !isempty(CoverageBase.julia_top())
@test !isempty(testnames())
@test_throws ErrorException runtests(["junk"])
runtests([joinpath(CoverageBase.julia_top(), "test", "goto")])

r1 = FileCoverage[FileCoverage("a","blahblah",[1,nothing,1,nothing]),
                  FileCoverage("b","blahblah",[nothing,5])]
r2 = FileCoverage[FileCoverage("a","blahblah",[3,nothing,0,2])]

r = merge_coverage(r1, r2)
@test length(r) == 2
for ri in r
    if ri.filename == "a"
        @test ri.coverage == [3,nothing,1,2]
    elseif ri.filename == "b"
        @test ri.coverage == [nothing,5]
    else
        error("test not recognized")
    end
end
