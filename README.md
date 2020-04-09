# bashtools
A collection of Bash scripts to be reused

## Install

```bash
/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/completeworks/bashtools/master/install/install.sh)"
```

## Usage (example)

```bash
#! /usr/bin/env bash

# shellcheck disable=SC1090
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.bashtools/bashtools"

gitw sparsecheckout https://github.com/google/jsonnet.git .jsonnet
```