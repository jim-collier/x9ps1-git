#!/bin/bash

## Active shellchecks
# shellcheck disable=1090
# shellcheck disable=1091
# shellcheck disable=2001   ## Complaining about use of sed istead of bash search & replace.
# shellcheck disable=2002   ## Useless use of cat. This works well though and I don't want to break it for the sake of syntax purity.
# shellcheck disable=2004   ## Inappropriate complaining of "$/${} is unnecessary on arithmetic variables."
# shellcheck disable=2119   ## Disable confusing and inapplicable warning about function's $1 meaning script's $1.
# shellcheck disable=2120   ## OK with declaring variables that accept arguments, without calling with arguments (this is 'overloading').
# shellcheck disable=2143   ## Used grep -q instead of echo | grep
# shellcheck disable=2154
# shellcheck disable=2155   ## Disable check to 'Declare and assign separately to avoid masking return values'.
# shellcheck disable=2162
# shellcheck disable=2181
# shellcheck disable=2207
# shellcheck disable=2317   ## Can't reach

## Inactive shellchecks
# shellcheck disable=2034  ## Unused variables.


##	Purpose:
##		- CI/CD-friendly test harness that passes or fails.
##		- Tests random output and round-trips through v2 to make sure the initial output was correct (at least if v2 is also correct).
##		- This is NOT part of cicd script, as it's not a requirement to have v2 installed.
##	History: At bottom of this file. (Note: History for this is maintained outside of [or in addition to] git project.)

##	Copyright © 2026 Jim Collier (ID: 1cv◂‡Vᛦ)
##	Licensed under The MIT License (MIT). Full text at:
##		https://mit-license.org/
##	SPDX-License-Identifier: MIT


## Global settings
set -e
declare doLongTest=0 ; [[ "${CICDTEST_DO_LONGTEST}" == "1" ]] && doLongTest=1

fMain_Test(){

	## Settings
	exe1="../bin/x9ps1-git"

	## Environment overrides
	local LANG="C.UTF-8"  ## Splitting won't work correctly without this

	## Resolve paths
	fResolvePath_v1  exe1       "${exe1}"

	## Variables
	local inputVal=""  expectVal=""  gotVal=""  tmpVal=""
	local -i loopCount=0

	####
	#### Show basic info

	fEcho_Clean
	fEcho_Clean "Exe source ...: ${exe1}"
#	fEcho_Clean "Version ......: $("${exe1}" --version)"
	fEcho_Clean_Force
#	sleep 1


#	####
#	#### Test arg flags (make sure -e is enabled)
#	fEcho; fEcho ">>> TESTSECTION: Flags"; fEcho

}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Generic function(s) that can't be 'sourced'.
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
declare __fResolvePath_v1_PreviousDir=""
fResolvePath_v1(){
	## Purpose: Resolves an argument to a canonical full path, while being careful to not be too broad as to resolve to something else with the same name.
	## Searches common 'include|lib'-like sub-paths; then if arg is a single filename, seraches the system $PATH.
	## Subshells and external tools are OK in this very early function that preceeds any modules being loaded.
	## Validate nameref args (with no modules loaded yet to help)
	nref="${1:-}"; { [[ -n "${nref}" ]] && [[ ${nref} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && declare -p "${nref}" &>/dev/null; }  || { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Invalid nameref argument '${nref}'. Are one or more arguments missing?.\n" ; return ${ERRNUM_MSG_ALREADY_SHOWN}; }
	## Gather args
	local -n ref_Return_ResolvedPath_t4rej=$1  ; shift || :  ## Parent variable to store fully resolved path in.
	local -r nameOrPath="${1:-}"               ; shift || :  ## File or folder path (relative or absolute). If an executable file, can be just a name to search in $PATH, to fully resolve.
	local -i mustExist=${1:-1}                 ; shift || :  ## 1 [default]: path must exist or error occurs. 0: Just rationalize paths, doesn't have to exist.
	## Validate
	[[ "${nameOrPath}" ]] || { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Path or executable name not specified.\n" ; return ${ERRNUM_MSG_ALREADY_SHOWN}; }
	## Init
	ref_Return_ResolvedPath_t4rej=""
	## Variables
	local testPath=""
	## Obvious test, as-is
	if [[ -e "${nameOrPath}" ]]; then
		testPath="$(realpath -e "${nameOrPath}" 2>/dev/null || true)"
		[[ -e "${testPath}" ]] && { __fResolvePath_v1_PreviousDir="$(dirname "${testPath}")"; ref_Return_ResolvedPath_t4rej="${testPath}"; return 0; }
	fi
	## Constants
	local -r meMePath_t4rej="$(realpath -e "${BASH_SOURCE[0]}")"  ## Pathspec to this script.
	local -r meMeName_t4rej="$(basename "${meMePath_t4rej}")"
	local    meMeName_Simple_t4rej="${meMeName_t4rej//'0_'/''}"; meMeName_Simple_t4rej="${meMeName_Simple_t4rej//'.bash'/''}"; readonly meMeName_Simple_t4rej
	local -r meDirPath_t4rej="$(dirname "${meMePath_t4rej}")"  ## Path to script container dir.
	## Common path primitives (listed in order of likelihood and/or desired first-match if in multiple places).
	local -a tryBaseDirs=("${meDirPath_t4rej}/"  "${meMePath_t4rej}.d/"  "${meDirPath_t4rej}/${meMeName_Simple_t4rej}/"  "${meDirPath_t4rej}/${meMeName_Simple_t4rej}.d/"  "${HOME}/synced/0-0/common/exec/util/linux/bash/"  '/opt/'  '/usr/local/'  '/usr/local/'  "${HOME}/opt/"  "${HOME}/.local/"  "${HOME}/.local/")
	local -a tryRelSubs1=('include/'  'lib/'  'mod/'  'bin/'  'bin/lib/'  'bin/include/'  'inc/'  'includes/'  'module/'  'modules/'  '')  ## Common generic library subdirs (NOT relative to root), in order of likelihood.
	local -a tryRelSubs2=(''  'n8/'  'x9/'  "${meMeName_t4rej}/"  "${meMeName_Simple_t4rej}/")
	local -a tryPaths=()
	## Build common paths to check from primitives (starting with the last path for previous match)
	[[ -n "${__fResolvePath_v1_PreviousDir}" ]] && tryPaths+=("${__fResolvePath_v1_PreviousDir}/${nameOrPath}")  ## Add previous found dir to the top of the list
	for tryBaseDir in "${tryBaseDirs[@]}"; do
		for tryRelSub1 in "${tryRelSubs1[@]}"; do
			for tryRelSub2 in "${tryRelSubs2[@]}"; do
				testPath="${tryBaseDir}${tryRelSub1}${tryRelSub2}${nameOrPath}"; testPath="${testPath%%/}"; testPath="${testPath//'//'/'/'}"; tryPaths+=("${testPath}")
			done
		done
	done
	## Return first match.
	#{ for nextPath in "${tryPaths[@]}"; do echo "${nextPath}"; done; } | less  ## DEBUG
	for nextPath in "${tryPaths[@]}"; do [[ -e "${nextPath}" ]] && { __fResolvePath_v1_PreviousDir="$(dirname "${nextPath}")"; ref_Return_ResolvedPath_t4rej="${nextPath}"; return 0; }; done
	## No match; try 'which', if arg is a single file.
	if [[ "${nameOrPath}" != */* ]]; then
		testPath="$(which "${nameOrPath}" 2>/dev/null || true)"
		[[ -n "${testPath}" ]] && { testPath="$(realpath -e "${testPath}")"; __fResolvePath_v1_PreviousDir="$(dirname "${testPath}")"; ref_Return_ResolvedPath_t4rej="${testPath}"; return 0; }  ## Return 'which'
	fi
	## Haven't matched yet: revert to original argument
	testPath="${nameOrPath}"
	if ((mustExist)); then
		testPath="$(realpath -e "${testPath}" 2>/dev/null || true)"
		[[ -n "${testPath}" && -e "${testPath}" ]] || { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔs].\n"; return ${ERRNUM_MSG_ALREADY_SHOWN}; }
	else
		testPath="$(realpath -m "${testPath}" 2>/dev/null || true)"
		[[ -n "${testPath}" ]] || { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve even optionally nonexistent path '${nameOrPath}' [£ǝŔs].\n"; return ${ERRNUM_MSG_ALREADY_SHOWN}; }
	fi
	## If haven't returned with success or error by now, then we return what we have, which is either a real match, or valid hypothetical.
	__fResolvePath_v1_PreviousDir="$(dirname "${testPath}")"; ref_Return_ResolvedPath_t4rej="${testPath}"
}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
# Entry point
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••

if [[ -z "${meName_t4rgd+x}" ]]; then
	declare -r mePath_t4rgd="$(realpath -e "${BASH_SOURCE[0]}")"
	declare -r meName_t4rgd="$(basename "${mePath_t4rgd}")"
	declare -r meDir_t4rgd="$(dirname "${mePath_t4rgd}")"
	declare -r serialDT_t4rgd="$(date "+%Y%m%d-%H%M%S")"
fi

## Make sure relative path definitions will work
cd "${meDir_t4rgd}"

## Source the generic script 'utility/n8test'. It will call fMain() above.
declare n8test_resolved="utility/include/n8lib_test"
fResolvePath_v1  n8test_resolved  "${n8test_resolved}" ; readonly n8test_resolved
[[ -z "${n8test_resolved}" ]] || source "${n8test_resolved}"

## Initialize logging (fPipe_LogAndShowPartialOutput_InitLogfile() is defined in 'n8test')
declare logFile="${mePath_t4rgd%.*}.log"
fResolvePath_v1  logFile    "${logFile}"  0
fPipe_LogAndShowPartialOutput_InitLogfile "${logFile}"

## Kick off testing (functions are defined in 'n8test')
fEntryPoint | fPipe_LogAndShowPartialOutput



#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
##	Script history:
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
##		- 20260621 JC: Copied and updated from another project.
