using CoverageBase
using Coverage
using Base.Test

@test !isempty(CoverageBase.julia_top())
@test !isempty(testnames())
@test_throws ErrorException runtests(["junk"])
runtests([joinpath(CoverageBase.julia_top(), "test", "goto")])
