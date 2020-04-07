#!/usr/bin/env bash
#*******************************************************************************
# Copyright (c) 2020 Eclipse Foundation and others.
# This program and the accompanying materials are made available
# under the terms of the Eclipse Public License 2.0
# which is available at http://www.eclipse.org/legal/epl-v20.html,
# or the MIT License which is available at https://opensource.org/licenses/MIT.
# SPDX-License-Identifier: EPL-2.0 OR MIT
#*******************************************************************************

set -o errexit
set -o nounset
set -o pipefail

IFS=$'\n\t'

download_withcache() {
  local url="${1}"
  local output="${2}"
  local cache_duration_sec="${3:-$((24 * 3600))}"
  local lastchecked_file="${4:-.${output}.lastchecked}"

  local lastchecked
  lastchecked="$(date +%s)";
  if [[ -f "${lastchecked_file}" ]]; then
    lastchecked=$(cat "${lastchecked_file}")
    lastchecked=$((lastchecked + cache_duration_sec))
  fi

  if [[ ! -f "${output}" ]] || [[ ${lastchecked} -le $(date +%s) ]]; then
    local code
    code=$(download_ifmodified "${url}" "${output}")
    if [[ ${code} -lt 400 ]]; then
      date +%s > "${lastchecked_file}"
    fi
    echo "${code}"
  else
    log_debug "File '%s' has been checked for update in the last %s, no remote call will be done." "$(realpath --relative-to="$(pwd)" "${output}")" "$(__show_time "${cache_duration_sec}")"
    echo "304"
  fi
}

CURL_OPTS=(
  "--retry"
  "5"
  "--connect-timeout"
  "10" 
  "-sS" 
  "-L" 
  "-w"
  "%{http_code}"
)

# Downloads URL $1 to file $2 properly using If-Modified-Since and If-None-Match headers when supported by the server.
# ETag reported by the server is stored in file $2.etag, so it should be kept around for proper re-use
# It prints out the status code of the HTTP response to stdout and some debug information on stderr. If code 
download_ifmodified() {
  local url="${1}"
  local output="${2}"
  local code=0

  local header
  header="$(mktemp)"
  if [[ -f "${output}" ]]; then
    >&2 echo "Downloading (if required) ${url}"
    # use -o "${output}.tmp" and not -o "${output}" because in case of 304, output will be empty, and file trimmed
    if [[ -f ".${output}.etag" ]]; then
      # do no specify -z here as some servers do not respect precedence of If-None-Match over If-Modified-Since
      code="$(curl "${url}" "${CURL_OPTS[@]}" --dump-header "${header}" -o "${output}.tmp" --header "If-None-Match: $(head -n1 ".${output}.etag")")"
    else 
      code="$(curl "${url}" "${CURL_OPTS[@]}" --dump-header "${header}" -o "${output}.tmp" -z "${output}")"
    fi

    local curl_ret=${?}
    if [[ ${curl_ret} -eq 28 ]]; then
      log_warning "connection timed out to ${url}"
      code=328
    elif [[ ${code} -ge 400 ]]; then
      rm -f "${output}.tmp"
      log_warning "unable (status: ${code}) to retrieve '${url}', will use cached file '$(realpath --relative-to="$(pwd)" "${output}")'"
      code=332
    elif [[ ${code} -eq 304 ]]; then
      rm -f "${output}.tmp"
      log_debug "File '%s' is up to date" "$(realpath --relative-to="$(pwd)" "${output}")"
    else
      mv "${output}.tmp" "${output}"
      log_debug "File '%s' has been updated" "$(realpath --relative-to="$(pwd)" "${output}")"
    fi 
  else
    log_debug "Downloading %s" "${url}"
    mkdir -p "$(dirname "${output}")"
    code="$(curl "${url}" "${CURL_OPTS[@]}" --dump-header "${header}" -o "${output}")"
    local curl_ret=${?}
    if [[ ${curl_ret} -eq 28 ]]; then
      log_warning "connection timed out to ${url}"
      code=328
    elif [[ ${code} -ge 400 ]]; then
      log_error "unable to retrieve '%s' (status: %d)" "${url}" "${code}"
      rm -f "${output}"
    fi
  fi

  local etag
  etag="$(grep -Ei 'etag *: *"?[^"]*"?' "${header}" | sed -Ee 's/[^:]*: *([^ ]*)/\1/g' | tail -n1 | tr -d '\r' | tr -d '\n')"
  if [[ -n "${etag}" ]]; then
    echo -n "${etag}" > ".${output}.etag"
  fi
  rm "${header}"

  echo "${code}"
}

log_debug() {
  if [[ -n "${DEBUG+x}" ]]; then
    >&2 printf "DEBUG: %s\n%s" "${1}" "${@:2}"
  fi
}

log_warning() {
  >&2 printf "WARNING: %s\n%s" "${1}" "${@:2}"
}

log_error() {
  >&2 printf "ERROR: %s\n%s" "${1}" "${@:2}"
}

__show_time() {
    local num="${1}"
    local min=0
    local hour=0
    local day=0
    if [[ ${num} -gt 59 ]]; then
      sec=$((num%60))
      num=$((num/60))
      if [[ ${num} -gt 59 ]]; then
        min=$((num%60))
        num=$((num/60))
        if [[ ${num} -gt 23 ]]; then
          hour=$((num%24))
          day=$((num/24))
        else
          hour=$((num))
        fi
      else
        min=$((num))
      fi
    else
      sec=$((num))
    fi
    if [[ ${day} -gt 0 ]]; then
      echo -n "${day}"d
    elif [[ ${hour} -gt 0 ]]; then
      if [[ ${day} -gt 0 ]]; then
        echo -n " "
      fi
      echo -n "${hour}"h
    elif [[ ${min} -gt 0 ]]; then
      if [[ ${hour} -gt 0 ]] || [[ ${day} -gt 0 ]]; then
        echo -n " "
      fi
      echo -n "$min"m
    elif [[ ${sec} -gt 0 ]]; then
      if [[ ${min} -gt 0 ]] || [[ ${hour} -gt 0 ]] || [[ ${day} -gt 0 ]]; then
        echo -n " "
      fi
      echo -n "${sec}"s
    fi
}
