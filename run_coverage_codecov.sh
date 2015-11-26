#! /bin/bash
# NOTE: this script must be run with the environment variable
# REPO_TOKEN set to your codecov.io token.
# See codecov.io API documentation

# Build julia
git checkout master
git pull
make cleanall
make

# Clean old *.cov files
rm $(find base -name "*.jl.*cov")

cd test
# Run coverage with inlining on, to test the few that don't run with it off
../julia --precompiled=no --code-coverage=all -e 'import CoverageBase; using Base.Test; CoverageBase.runtests(CoverageBase.testnames())'
# Run coverage without inlining, to test the rest of base
../julia --precompiled=no --inline=no --code-coverage=all -e 'import CoverageBase; using Base.Test; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze and submit results
./julia -e 'using Coverage; results=Codecov.process_folder("base"); Codecov.submit_token(results)'
