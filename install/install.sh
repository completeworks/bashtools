#!/usr/bin/env bash
#*******************************************************************************
# Copyright (c) 2020 Eclipse Foundation and others.
# This program and the accompanying materials are made available
# under the terms of the Eclipse Public License 2.0
# which is available at http://www.eclipse.org/legal/epl-v20.html,
# or the MIT License which is available at https://opensource.org/licenses/MIT.
# SPDX-License-Identifier: EPL-2.0 OR MIT
#*******************************************************************************

# Bash strict-mode
set -o errexit
set -o nounset
set -o pipefail

IFS=$'\n\t'

sparsecheckout() {
	local remote="${1}"
	local path="${2:-.}"
	local branch="${3:-master}"
	if [[ -d "${path}" ]]; then
		INFO "Fetching the tip of the branch '${branch}' from ${remote}..."
	  git -C "${path}" fetch -f --no-tags --depth 1 "${remote}" "+refs/heads/${branch}:refs/remotes/origin/${branch}" |& TRACE
		INFO "Checkouting branch ${branch}..."
	  git -C "${path}" checkout --no-progress -f "$(git -C "${path}" rev-parse "refs/remotes/origin/${branch}")" |& TRACE
	else
	  git init "${path}" |& TRACE
		INFO "Fetching the tip of the branch '${branch}' from ${remote}..."
	  git -C "${path}" fetch --no-tags --depth 1 "${remote}" "+refs/heads/${branch}:refs/remotes/origin/${branch}" |& TRACE
	  git -C "${path}" config remote.origin.url "${remote}" |& TRACE
	  git -C "${path}" config --add remote.origin.fetch "+refs/heads/${branch}:refs/remotes/origin/${branch}" |& TRACE
	  git -C "${path}" config core.sparsecheckout true |& TRACE
	  git -C "${path}" config advice.detachedHead false |& TRACE
		INFO "Checkouting branch ${branch}..."
	  git -C "${path}" checkout --no-progress -f "$(git -C "${path}" rev-parse "refs/remotes/origin/${branch}")" |& TRACE
	fi
}

INFO() {
	>&2 echo "INFO: $@"
}

TRACE() {
	cat > /dev/null
}

sparsecheckout https://github.com/completeworks/bashtools.git .bashtools
