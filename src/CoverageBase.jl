module CoverageBase

export testnames, runtests, merge_coverage

const need_inlining = ["resolve", "reflection", "meta", "pkg"]

function julia_top()
    dir = JULIA_HOME
    while !isdir(joinpath(dir,"base"))
        dir, _ = splitdir(dir)
        if dir == "/"
            error("Error parsing top dir")
        end
    end
    dir
end
const topdir = julia_top()
const basedir = joinpath(topdir, "base")
const testdir = joinpath(topdir, "test")

function testnames()
    Base.compileropts().can_inline == 1 && return need_inlining

    ast, _ = parse(readall(joinpath(testdir, "runtests.jl")), 1, greedy=true)
    ast.args[1] == :testnames || error("error parsing testnames")
    names = eval(ast.args[2])
    names = filter(x->!in(x, [need_inlining, "linalg"]), names)
    append!(names, ["unicode", "linalg1", "linalg2", "linalg3", "linalg4", "linalg/lapack", "linalg/triangular", "linalg/tridiag", "linalg/pinv", "linalg/cholmod", "linalg/umfpack", "linalg/givens", "parallel"])
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

end # module
