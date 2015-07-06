#! /bin/bash
# NOTE: this script must be run with the environment variable
# REPO_TOKEN set to your coveralls.io token.
# See coveralls.io API documentation

# Build julia
git checkout master
git pull
make cleanall
make
rm usr/lib/julia/sys.so

# Clean old *.cov files
rm $(find base -name "*.jl.*cov")

# Run coverage with inlining on, to test the few that don't run with it off
cd test
../julia --code-coverage=all -e 'import CoverageBase; using Base.Test; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze results
./julia -e 'using Coverage, HDF5, JLD; results=Coveralls.process_folder("base"); save("coverage_inline.jld", "results", results)'
rm $(find base -name "*.jl.*cov")

# Run coverage with inline=no
cd test
../julia --inline=no --code-coverage=all -e 'import CoverageBase; using Base.Test; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze results
./julia -e 'using Coverage, HDF5, JLD; results=Coveralls.process_folder("base"); save("coverage_noinline.jld", "results", results)'

# Merge results and submit
./julia -e 'using Coverage, CoverageBase, HDF5, JLD; r1 = load("coverage_noinline.jld", "results"); r2 = load("coverage_inline.jld", "results"); r = CoverageBase.merge_coverage(r1, r2); Coveralls.submit_token(r)'
