__precompile__(true)
module CoverageBase
using Coverage
export testnames, runtests
export fixpath, fixpath!, readsource!

const need_inlining = []

function __init__()
    global _julia_top, julia_datapath
    dir = String(normpath(Sys.BINDIR::String, Base.DATAROOTDIR, "julia", ""))
    julia_datapath = dir
    if !(isdir(joinpath(dir, "base")) && isdir(joinpath(dir, "test")))
        # this branch shouldn't happen normally
        dir = Sys.BINDIR::String
        while !isdir(joinpath(dir, "base"))
            dir, _ = splitdir(dir)
            if dir == "/"
                error("Error parsing top directory; using Julia located at $BINDIR")
            end
        end
    end
    _julia_top = String(dir)
end
__init__()
julia_top() = _julia_top::String

"""
    build_basepath
Julia's top-level directory when Julia was built, as recorded by the entries in
`Base._included_files`.
"""
const build_basepath = begin
    sysimg_file = filter(x -> endswith(x[2], "sysimg.jl"), Base._included_files)[1][2]
    joinpath(dirname(dirname(sysimg_file)), "")
end
const build_datapath = normpath(build_basepath, "usr", "bin", Base.DATAROOTDIR, "julia", "")
const build_stdlibpath = joinpath(build_datapath, "stdlib", "v$(VERSION.major).$(VERSION.minor)", "")

"""
    fixpath(filename) -> filename

Rewrite filenames inside the julia folder into relative paths.
"""
function fixpath(filename)
    if startswith(filename, build_stdlibpath)
        return joinpath("stdlib", filename[(sizeof(build_stdlibpath) + 1):end])
    end
    if startswith(filename, build_datapath)
        return filename[(sizeof(build_datapath) + 1):end]
    end
    if startswith(filename, build_basepath)
        return filename[(sizeof(build_basepath) + 1):end]
    end
    STDLIB = Sys.STDLIB::String
    if startswith(filename, STDLIB) && filename[sizeof(STDLIB) + 1] == Base.Filesystem.pathsep()[1]
        return joinpath("stdlib", filename[(sizeof(STDLIB) + 2):end])
    end
    datapath = julia_datapath::String
    if startswith(filename, datapath)
        return filename[(sizeof(datapath) + 1):end]
    end
    if julia_datapath != julia_top() && startswith(filename, julia_top())
        return filename[(sizeof(julia_top()) + 1):end]
    end
    if !isabspath(filename)
        return joinpath("base", filename)
    end
    return filename
end

"""
    fixpath!(fcs::Vector{FileCoverage)) -> fcs

Rewrite filenames inside the julia folder into relative paths.
"""
function fixpath!(fcs::Vector{FileCoverage})
    for fc in fcs
        fc.filename = fixpath(fc.filename)
    end
    return fcs
end

"""
    fixabspath(fixpath(filename)) -> abspath

Rewrite a fixpath back into a local absolute path.
"""
function fixabspath(fixfilename)
    if isabspath(fixfilename)
        path = fixfilename
    elseif startswith(fixfilename, "stdlib") && fixfilename[7] == Base.Filesystem.pathsep()[1]
        path = joinpath(Sys.STDLIB::String, fixfilename[8:end])
    else
        path = joinpath(julia_top(), fixfilename)
    end
    return path
end


"""
    readsource!(filename) -> fcs

Populate the .source fields.
"""
function readsource!(fcs::Vector{FileCoverage})
    for fc in fcs
        if isempty(fc.source)
            path = fixabspath(fc.filename)
            if isfile(path)
                fc.source = read(path, String)
            end
        end
    end
    return fcs
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
    return names
end

function test_path(testdir, test)
    t = split(test, '/')
    if t[1] in BaseTestRunner.STDLIBS
        STDLIB = Sys.STDLIB::String
        if length(t) == 2
            return joinpath(STDLIB, t[1], "test", t[2])
        else
            return joinpath(STDLIB, t[1], "test", "runtests")
        end
    else
        return joinpath(testdir, test)
    end
end

function julia_cmd()
    julia = Base.julia_cmd()
    return `$julia --sysimage-native-code=no`
end

function runtests(names)
    topdir = julia_top()
    testdir = joinpath(topdir, "test")
    julia = julia_cmd()
    script = """
        using Distributed # from runtests.jl
        include("testdefs.jl")
        @time testresult = runtests(ARGS[1], ARGS[2])
        # TODO: exit(testresult.anynonpass ? 1 : 0)
        """
    anyfail = false
    cd(testdir) do
        for tst in names
            printstyled("RUNTEST: $tst\n", bold=true)
            tstpath = test_path(testdir, tst)
            cmd = `$julia -e $script -- $tst $tstpath`
            try
                run(pipeline(cmd, stdin=devnull))
            catch err
                bt = catch_backtrace()
                println(stderr)
                println(stderr, "-"^40)
                Base.display_error(stderr, err, bt)
                println(stderr, "-"^40)
                anyfail = true
            end
        end
    end
    return !anyfail
end

end # module
