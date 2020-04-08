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
		>&2 echo "Fetching the tip of the branch '${branch}' from ${remote}..."
	  git -C "${path}" fetch -q -f --no-tags --depth 1 "${remote}" "+refs/heads/${branch}:refs/remotes/origin/${branch}";
		>&2 echo "Checkouting branch ${branch}..."
	  git -C "${path}" checkout --no-progress -f "$(git -C "${path}" rev-parse "refs/remotes/origin/${branch}")";
	else
	  git init -q "${path}";
		>&2 echo "Fetching the tip of the branch '${branch}' from ${remote}..."
	  git -C "${path}" fetch -q --no-tags --depth 1 "${remote}" "+refs/heads/${branch}:refs/remotes/origin/${branch}";
	  git -C "${path}" config remote.origin.url "${remote}";
	  git -C "${path}" config --add remote.origin.fetch "+refs/heads/${branch}:refs/remotes/origin/${branch}";
	  git -C "${path}" config core.sparsecheckout true;
	  git -C "${path}" config advice.detachedHead false;
		>&2 echo "Checkouting branch ${branch}..."
	  git -C "${path}" checkout --no-progress -f "$(git -C "${path}" rev-parse "refs/remotes/origin/${branch}")";
	fi
}

sparsecheckout https://github.com/completeworks/bashtools.git .bashtools
