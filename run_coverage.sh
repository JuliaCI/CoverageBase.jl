#! /bin/bash
# NOTE: this script must be run with the environment variable
# REPO_TOKEN set to your coveralls.io token.
# See coveralls.io API documentation

# Build julia
git checkout master
git pull
make cleanall
make

# Clean old *.cov files
rm $(find base -name "*.jl.*cov")

cd test
# Run coverage with inlining on, to test the few that don't run with it off
../julia --precompiled=no --code-coverage=all -e 'using CoverageBase, Compat, Compat.Test; CoverageBase.runtests(CoverageBase.testnames())'
# Run coverage without inlining, to test the rest of base
../julia --precompiled=no --inline=no --code-coverage=all -e 'using CoverageBase, Compat, Compat.Test; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze and submit results
./julia -e 'using Coverage; results=Coveralls.process_folder("base"); Coveralls.submit_token(results)'
rm $(find base -name "*.jl.*cov")
