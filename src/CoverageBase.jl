__precompile__(true)
module CoverageBase
using Coverage
export testnames, runtests

const need_inlining = []

function julia_top()
    dir = joinpath(Sys.BINDIR, "..", "share", "julia")
    if isdir(joinpath(dir,"base")) && isdir(joinpath(dir,"test"))
        return dir
    end
    dir = Sys.BINDIR
    while !isdir(joinpath(dir,"base"))
        dir, _ = splitdir(dir)
        if dir == "/"
            error("Error parsing top dir; Sys.BINDIR = $(Sys.BINDIR)")
        end
    end
    dir
end

module BaseTestRunner
import ..julia_top
let testdir = joinpath(julia_top(), "test")
    include(joinpath(testdir, "choosetests.jl"))
end
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

function julia_cmd()
    julia = Base.julia_cmd()
    inline = Base.JLOptions().can_inline == 0 ? "no" : "yes"
    cc = ("none", "user", "all")[Base.JLOptions().code_coverage + 1]
    return `$julia --precompiled=no --inline=$inline --code-coverage=$cc`
end

function runtests(names)
    topdir = julia_top()
    testdir = joinpath(topdir, "test")
    testrunner = joinpath(@__DIR__, "testrunner.jl")
    julia = julia_cmd()
    script = """
        include("testdefs.jl")
        @time testresult = runtests(ARGS[1])
        # TODO: exit(testresult.anynonpass ? 1 : 0)
        """
    fail = false
    cd(testdir) do
        for tst in names
            print_with_color(:bold, "RUNTEST: $tst\n")
            cmd = Cmd(`$julia -e $script -- $tst`, dir = testdir)
            try
                success(spawn(cmd, DevNull, STDOUT, STDERR))
            catch err
                bt = catch_backtrace()
                println(STDERR)
                println(STDERR, "-"^40)
                Base.display_error(STDERR, err, bt)
                println(STDERR, "-"^40)
                fail = true
            end
        end
    end
    !fail
end

end # module
