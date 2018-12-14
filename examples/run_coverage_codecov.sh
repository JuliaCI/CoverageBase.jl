#! /bin/bash
# NOTE: this script must be run with the environment variable
# CODECOV_REPO_TOKEN set to your codecov.io token.
# See codecov.io API documentation

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
    git_info = Any[
        :branch => Base.GIT_VERSION_INFO.branch,
        :commit => Base.GIT_VERSION_INFO.commit,
        :token => ENV["CODECOV_REPO_TOKEN"]]
    Codecov.submit_generic(coverage; git_info...)'
rm -r test/lcov
