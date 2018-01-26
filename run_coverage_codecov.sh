#! /bin/bash
# NOTE: this script must be run with the environment variable
# CODECOV_REPO_TOKEN set to your codecov.io token.
# See codecov.io API documentation

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
../julia --precompiled=no --code-coverage=all -e 'using CoverageBase, Compat, Compat.Test; CoverageBase.runtests(CoverageBase.testnames())'
# Run coverage without inlining, to test the rest of base
../julia --precompiled=no --inline=no --code-coverage=all -e 'using CoverageBase, Compat, Compat.Test; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze and submit results
./julia -e 'using Coverage; results=Codecov.process_folder("base"); git_info = Any[:branch => Base.GIT_VERSION_INFO.branch,:commit => Base.GIT_VERSION_INFO.commit,:token => ENV["CODECOV_REPO_TOKEN"]]; Codecov.submit_generic(results; git_info...);'
