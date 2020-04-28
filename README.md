# bashtools
A collection of Bash scripts to be reused

## Install

```bash
/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/completeworks/bashtools/master/install.sh)"
```

## Usage (example)

```bash
#! /usr/bin/env bash

# shellcheck disable=SC1090
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.bashtools/bashtools"

gitw sparsecheckout https://github.com/google/jsonnet.git .jsonnet
```

## Available commands

Default brings logger support. See https://github.com/completeworks/b-log#examples for details. No need to source it, it's made available from the bashtools script.

* `gitw sparsecheckout <remote> <path:.> <branch:master>`
* `download withcache  <url> <output> <cache_duration_sec:24h> <lastchecked_file:${output}.lastchecked>`
* `download ifmodified <url> <output> <etag_file:${output}.etag>`
* `version compare <version1> <version2>`