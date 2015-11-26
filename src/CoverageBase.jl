module CoverageBase
using Coverage
export testnames, runtests

const need_inlining = ["reflection", "meta"]

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
include(joinpath(testdir, "choosetests.jl"))

function testnames()
    Base.JLOptions().can_inline == 1 && return need_inlining

    names, _ = choosetests()
    filter!(x -> !in(x, need_inlining), names)

    # Manually add in `pkg`, which is disabled so that `make testall` passes on machines without internet access
    push!(names, "pkg")
    names
end

function runtests(names)
    cd(testdir) do
        for tst in names
            println(tst)
            include(tst*".jl")
        end
    end
end

end # module
