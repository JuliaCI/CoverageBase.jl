#! /bin/bash
# NOTE: this script must be run with the environment variable
# REPO_TOKEN set to your coveralls.io token.
# See coveralls.io API documentation

# Build julia
git checkout master
git pull
make cleanall
make

cd test
# Clean old tracefiles
test -e lcov && rm -r lcov
mkdir lcov
../julia --sysimage-native-code=no --code-coverage=lcov/tracefile-%p.info --code-coverage=all -e 'using CoverageBase; CoverageBase.runtests(CoverageBase.testnames())'
cd ..

# Analyze and submit results
./julia -e '
    using Coverage
    results = LCOV.readfolder("test/lcov")
    coverage = merge_coverage_counts(coverage, filter!(
        let prefixes = (joinpath("base", ""),
                        joinpath("stdlib", ""))
            c -> any(p -> startswith(c.filename, p), prefixes)
        end,
        results))
    Coveralls.submit_token(coverage)'
rm -r test/lcov
