module CoverageBase

export testnames, runtests, merge_coverage

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

function merge_coverage_counts(a1, a2)
    n = max(length(a1),length(a2))
    a = Array(Union(Void,Int), n)
    for i = 1:n
        a1v = isdefined(a1, i) ? a1[i] : nothing
        a2v = isdefined(a2, i) ? a2[i] : nothing
        a[i] = a1v == nothing ? a2v :
               a2v == nothing ? a1v : max(a1v, a2v)
    end
    a
end

function merge_coverage(r1a, r2a)
    r1 = todict(r1a)
    r2 = todict(r2a)
    files = union(collect(keys(r1)), collect(keys(r2)))
    r = []
    for f in files
        src = haskey(r1, f) ? r1[f][1] : r2[f][1]
        c1 = haskey(r1, f) ? r1[f][2] : []
        c2 = haskey(r2, f) ? r2[f][2] : []
        push!(r, Dict("name" => f, "source" => src, "coverage" => merge_coverage_counts(c1,c2)))
    end
    r
end

function todict(results)
    d = Dict{Any,Any}()
    for r in results
        d[r["name"]] = (r["source"], r["coverage"])
    end
    d
end

function merge_coverage_counts_codecov(a1, a2)
    n = max(length(a1),length(a2))
    a = Array(Union(Void,Int), n)
    for i = 1:n
        a1v = isdefined(a1, i) ? a1[i] : nothing
        a2v = isdefined(a2, i) ? a2[i] : nothing
        a[i] = a1v == nothing ? a2v :
               a2v == nothing ? a1v : max(a1v, a2v)
    end
    a
end

function merge_coverage_codecov(r1a, r2a)
    r1 = todict_codecov(r1a)
    r2 = todict_codecov(r2a)
    files = union(collect(keys(r1)), collect(keys(r2)))
    r = []
    for f in files
        c1 = haskey(r1, f) ? r1[f] : []
        c2 = haskey(r2, f) ? r2[f] : []
        push!(r, (string(f),merge_coverage_counts_codecov(c1,c2)))
    end
    r
end

function todict_codecov(results)
    d = Dict{Any,Any}()
    for r in results
        d[r[1]] = r[2]
    end
    d
end

end # module
