using CoverageBase
using Base.Test

@test !isempty(CoverageBase.julia_top())
@test !isempty(testnames())
@test_throws ErrorException runtests(["junk"])
runtests([joinpath(CoverageBase.julia_top(), "test", "goto")])

r1 = [Dict("name" => "a", "source" => "blahblah", "coverage" => [1,nothing,1,nothing]),
      Dict("name" => "b", "source" => "blahblah", "coverage" => [nothing,5])]
r2 = [Dict("name" => "a", "source" => "blahblah", "coverage" => [3,nothing,0,2])]

r = merge_coverage(r1, r2)
@test length(r) == 2
for ri in r
    if ri["name"] == "a"
        @test ri["coverage"] == [3,nothing,1,2]
    elseif ri["name"] == "b"
        @test ri["coverage"] == [nothing,5]
    else
        error("test not recognized")
    end
end

cr1 = [("a",[1,nothing,1,nothing]),
      ("b",[nothing,5])]
cr2 = [("a",[3,nothing,0,2])]
cr = CoverageBase.merge_coverage_codecov(cr1, cr2)
@test length(cr) == 2
for ri in r
    if haskey(ri,"a")
        @test ri["a"] == [3,nothing,1,2]
    elseif haskey(ri,"b")
        @test ri["b"] == [nothing,5]
    end
end
