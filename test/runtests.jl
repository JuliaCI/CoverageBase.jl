using CoverageBase
using Coverage
using Compat
using Compat.Test

@test isdir(CoverageBase.julia_top())
@test !isempty(testnames())
runtests([joinpath(CoverageBase.julia_top(), "test", "goto")])
