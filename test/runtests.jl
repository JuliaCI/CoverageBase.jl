using CoverageBase
using Coverage
using Base.Test

@test isdir(CoverageBase.julia_top())
@test !isempty(testnames())
runtests([joinpath(CoverageBase.julia_top(), "test", "goto")])
