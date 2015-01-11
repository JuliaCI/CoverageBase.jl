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
