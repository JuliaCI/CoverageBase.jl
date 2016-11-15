__precompile__(false)
module CoverageBase
using Coverage
export testnames, runtests

const need_inlining = []

function julia_top()
    dir = joinpath(JULIA_HOME, "..", "share", "julia")
    if isdir(joinpath(dir,"base")) && isdir(joinpath(dir,"test"))
        return dir
    end
    dir = JULIA_HOME
    while !isdir(joinpath(dir,"base"))
        dir, _ = splitdir(dir)
        if dir == "/"
            error("Error parsing top dir; JULIA_HOME = $JULIA_HOME")
        end
    end
    dir
end
const topdir = julia_top()
const basedir = joinpath(topdir, "base")
const testdir = joinpath(topdir, "test")

module BaseTestRunner
import ..testdir
include(joinpath(testdir, "choosetests.jl"))
include(joinpath(testdir, "testdefs.jl"))
end

function testnames()
    names, _ = BaseTestRunner.choosetests()
    if Base.JLOptions().can_inline == 0
        filter!(x -> !in(x, need_inlining), names)
    end

    # Manually add in `pkg`, which is disabled so that `make testall` passes on machines without internet access
    push!(names, "pkg")
    names
end

function runtests(names)
    cd(testdir) do
        for tst in names
            @time BaseTestRunner.runtests(tst)
        end
    end
end

end # module
