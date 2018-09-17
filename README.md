# CoverageBase

[![Build Status](https://travis-ci.org/JuliaCI/CoverageBase.jl.svg?branch=master)](https://travis-ci.org/JuliaCI/CoverageBase.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaCI/CoverageBase.jl/badge.svg)](https://coveralls.io/r/JuliaCI/CoverageBase.jl)

A package for measuring the internal test coverage of the [Julia](http://julialang.org/) programming langauge.

## Installation

You can install this on your local machine with
```julia
(v1.1) pkg> add https://github.com/JuliaCI/CoverageBase.jl.git
```

However, this is not sufficient on its own, particularly if you want to submit results to [Coveralls.io](https://coveralls.io/).  You should also set up the following:

- A checkout of [julia's master
  branch](https://github.com/JuliaLang/julia), one that you don't mind
  updating to the current master every time you run coverage
  statistics.  Let's assume this checkout is in
  `/somedirectory/julia-coverage`.

- A `bash` script similar to the following:
```sh
#! /bin/bash

echo $(date)
cd /somedirectory/julia-coverage
REPO_TOKEN=<your token here> /path/to/CoverageBase/run_coverage.sh
```
`REPO_TOKEN` should be set for the Coveralls.io repository you want to
deposit the results in. You can find the token on the repo's main page
on Coveralls, if you are an owner of the corresponding GitHub
repository.

- Optionally, set up a `cron` job to run the above shell script on a
  regular basis. It's probably wise to direct the output to a log file
  so you can inspect the output in cases of trouble.
