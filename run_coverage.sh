#! /bin/bash
# NOTE: this script must be run with the environment variable
# REPO_TOKEN set to your coveralls.io token.
# See coveralls.io API documentation

# Build julia
git checkout master
git pull
make cleanall
make

# Determine the correct option name
PRECOMP="$(./julia -e 'print(VERSION >= v"0.7.0-DEV.1735" ? "sysimage-native-code" : "precompiled")')"

# Clean old *.cov files
rm $(find base -name "*.jl.*cov")

cd test
# Run coverage with inlining on, to test the few that don't run with it off
../julia --$PRECOMP=no --code-coverage=all -e 'using CoverageBase; CoverageBase.runtests(CoverageBase.testnames())'
# Run coverage without inlining, to test the rest of base
../julia --$PRECOMP=no --inline=no --code-coverage=all -e 'using CoverageBase; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze and submit results
./julia -e 'using Coverage; results=Coveralls.process_folder("base"); Coveralls.submit_token(results)'
rm $(find base -name "*.jl.*cov")
