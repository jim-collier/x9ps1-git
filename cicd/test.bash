#!/bin/bash

## Active shellchecks
# shellcheck disable=1090
# shellcheck disable=1091
# shellcheck disable=2001   ## Complaining about use of sed istead of bash search & replace.
# shellcheck disable=2002   ## Useless use of cat. This works well though and I don't want to break it for the sake of syntax purity.
# shellcheck disable=2004   ## Inappropriate complaining of "$/${} is unnecessary on arithmetic variables."
# shellcheck disable=2016   ## Expressions don't expand in single quotes. Test names hold them on purpose.
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

##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under The MIT License (MIT). Full text at:
##		https://mit-license.org/
##	SPDX-License-Identifier: MIT


## Global settings
set -e
declare doLongTest=0 ; [[ "${CICDTEST_DO_LONGTEST}" == "1" ]] && doLongTest=1

## The bash the prompt runs under. X9PS1_TEST_BASH can name an older one, such as macOS's 3.2;
## the expansion to what's shown is always done by this one, since ${PS1@P} needs 4.4.
declare testBash="${X9PS1_TEST_BASH:-${BASH}}"

## Ignore the user's git config, so identity and hooks don't matter.
export GIT_CONFIG_GLOBAL=/dev/null  GIT_CONFIG_NOSYSTEM=1
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE X9PS1_STANDARD

## Scratch repos go under one folder this script makes, and removes on exit.
declare scratchRoot=""

fMakeRepo(){
	local -r dir="${scratchRoot}/$1"  branch="$2"  remote="$3"
	mkdir "${dir}"
	git -C "${dir}" init -q -b "${branch}"
	git -C "${dir}" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m test
	git -C "${dir}" config remote.origin.url "${remote}"
}

## Run the prompt the way PROMPT_COMMAND does, expand it the way bash does before showing it, and count lines holding the text.
## Takes variable names, not values, since fRunTest evals its command string.
## A clone two commits ahead of its upstream and one behind, with the remote named as given.
fMakeTracking(){
	local -r dir="${scratchRoot}/$1"  remote="$2"
	local -a who=(-c user.name=test -c user.email=test@example.com)
	git init -q --bare -b main "${dir}.up"
	git init -q -b main "${dir}.other"
	git -C "${dir}.other" "${who[@]}" commit -q --allow-empty -m one
	git -C "${dir}.other" push -q "${dir}.up" main
	git clone -q -o "${remote}" "${dir}.up" "${dir}"
	git -C "${dir}.other" "${who[@]}" commit -q --allow-empty -m two
	git -C "${dir}.other" push -q "${dir}.up" main
	git -C "${dir}" fetch -q "${remote}"
	git -C "${dir}" "${who[@]}" commit -q --allow-empty -m three
	git -C "${dir}" "${who[@]}" commit -q --allow-empty -m four
}

fCountShown(){
	( cd "${scratchRoot}/$1" && PS1="$("${BASH}" "${exe1}")" && printf '%s\n' "${PS1@P}" ) | grep -cF -- "${!2}" || true
}

## The same, through the sourced form .bashrc sets up. Takes a path under the scratch folder, or an absolute one.
fShownSourced(){
	local dir="$1"; [[ "${dir}" == /* ]] || dir="${scratchRoot}/${dir}"
	( cd "${dir}" && PS1="$("${testBash}" --norc --noprofile -c 'source "$1" && fX9ps1Git_SetPs1 && printf "%s" "${PS1}"' x "${exe1}")" && printf '%s\n' "${PS1@P}" )
}
fCountShownSourced(){
	fShownSourced "$1" | grep -cF -- "${!2}" || true
}

## Processes started per prompt, by an interactive bash set up the way the installation steps say.
## 'oneliner' as $2 uses the older PROMPT_COMMAND='PS1=`x9ps1-git`' instead. Counted as the
## difference between 2 prompts and 12, since a system bashrc runs its own commands at startup.
## A process that only runs now and then shows as a fraction.
fCountProcs(){
	local -r dir="${scratchRoot}/$1"  trace="${scratchRoot}/strace.out"  rcFile="${scratchRoot}/bashrc"
	if [[ "${2:-}" == "oneliner" ]]; then
		printf "PROMPT_COMMAND='PS1=\$(\"\${BASH}\" %q)'\n" "${exe1}" > "${rcFile}"
	else
		printf 'source %q\nPROMPT_COMMAND=fX9ps1Git_SetPs1\n' "${exe1}" > "${rcFile}"
	fi
	local -i forks=0  few=0  lines=0
	for lines in 1 11; do
		( cd "${dir}" && strace -f -qq -e trace=clone,clone3,fork,vfork -o "${trace}" "${testBash}" --noprofile --rcfile "${rcFile}" -i < <(yes : | head -n "${lines}") >/dev/null 2>&1 ) || true
		few=${forks}
		forks="$(grep -cE '(clone3?|v?fork)\(' "${trace}" || true)"
	done
	forks=$((forks - few))
	if ((forks % 10)); then echo "${forks}/10"; else echo "$((forks / 10))"; fi
}

fCountRan(){
	{ compgen -G "${scratchRoot}/$1/PWNED*" || true; } | wc -l
}

fRemoveScratch(){
	[[ "$(basename "${scratchRoot}")" == x9ps1-test.* && -d "${scratchRoot}" ]] && rm -rf -- "${scratchRoot}"
	:
}

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

	####
	#### Branch and remote names show as text, and run nothing
	fEcho; fEcho ">>> TESTSECTION: Names from git"; fEcho

	scratchRoot="$(mktemp -d -t x9ps1-test.XXXXXX)"
	trap fRemoveScratch EXIT

	local -r hostileBranch='$(touch${IFS}PWNED1)`touch${IFS}PWNED2`${HOME}'
	local -r hostileRemote='https://example.com/$(touch PWNED3)/`touch PWNED4`/a\b.git'
	local -r plainBranch="main"
	local -r plainRemote="github.com:someone/plain.git"  ## Shown without the part up to '@'
	fMakeRepo  hostile  "${hostileBranch}"  "${hostileRemote}"
	fMakeRepo  plain    "${plainBranch}"    "git@${plainRemote}"

	fRunTest  equal  1  "'fCountShown' hostile hostileBranch"
	fRunTest  equal  1  "'fCountShown' hostile hostileRemote"
	fRunTest  equal  0  "'fCountRan' hostile"
	fRunTest  equal  1  "'fCountShown' plain plainBranch"
	fRunTest  equal  1  "'fCountShown' plain plainRemote"

	####
	#### The git part shows with no origin, or no remote at all, and says how far from the upstream
	fEcho; fEcho ">>> TESTSECTION: Git part"; fEcho

	local -r loneBranch="lonebranch"
	local -r trackedUrl="${scratchRoot}/tracked.up"
	local -r aheadBehind="↑2↓1"
	mkdir "${scratchRoot}/lone"
	git -C "${scratchRoot}/lone" init -q -b "${loneBranch}"
	fMakeTracking  tracked  upstream

	fRunTest  equal  1  "'fCountShown' lone loneBranch"
	fRunTest  equal  1  "'fCountShown' tracked trackedUrl"
	fRunTest  equal  1  "'fCountShown' tracked aheadBehind"

	####
	#### Sourced, the way .bashrc sets it up, it shows the same
	fEcho; fEcho ">>> TESTSECTION: Sourced"; fEcho

	fRunTest  equal  1  "'fCountShownSourced' hostile hostileBranch"
	fRunTest  equal  1  "'fCountShownSourced' hostile hostileRemote"
	fRunTest  equal  0  "'fCountRan' hostile"
	fRunTest  equal  1  "'fCountShownSourced' plain plainRemote"
	fRunTest  equal  1  "'fCountShownSourced' lone loneBranch"
	fRunTest  equal  1  "'fCountShownSourced' tracked trackedUrl"
	fRunTest  equal  1  "'fCountShownSourced' tracked aheadBehind"

	####
	#### The repository is found from below it, through a .git file, through GIT_DIR and through a symlink, and not from outside
	fEcho; fEcho ">>> TESTSECTION: Finding the repository"; fEcho

	local -r markYes="✔"  markNo="✘"  ## Only the git part has them
	local -r wtBranch="wtbranch"
	mkdir -p "${scratchRoot}/tracked/sub/deeper" "${scratchRoot}/outside"
	git -C "${scratchRoot}/tracked" worktree add -q -b "${wtBranch}" "${scratchRoot}/wt"
	ln -s "${scratchRoot}/lone" "${scratchRoot}/lonelink"

	fRunTest  equal  1  "'fCountShownSourced' tracked/sub/deeper trackedUrl"
	fRunTest  equal  1  "'fCountShownSourced' wt wtBranch"
	fRunTest  equal  1  "'fCountShownSourced' lonelink loneBranch"
	fRunTest  equal  1  "GIT_DIR='${scratchRoot}/lone/.git' 'fCountShownSourced' outside loneBranch"
	fRunTest  equal  0  "'fCountShownSourced' outside markYes"
	fRunTest  equal  0  "'fCountShownSourced' outside markNo"
	fRunTest  equal  0  "'fCountShownSourced' / markYes"
	fRunTest  equal  0  "'fCountShownSourced' / markNo"

	####
	#### Processes per prompt: none outside a git working tree, and just the two git calls inside one
	fEcho; fEcho ">>> TESTSECTION: Processes per prompt"; fEcho

	if strace -f -qq -o /dev/null true >/dev/null 2>&1; then
		fRunTest  equal  0  "'fCountProcs' outside"
		fRunTest  equal  2  "'fCountProcs' tracked/sub/deeper"
		if [[ "${testBash}" == "${BASH}" ]]; then
			fRunTest  equal  1  "'fCountProcs' outside oneliner"  ## The new bash alone
			fRunTest  equal  3  "'fCountProcs' tracked/sub/deeper oneliner"
		fi
	else
		fEcho "strace can't run here, so the process counts were skipped."
	fi


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
##		- 20261006 JC: Sourced form, finding the repository, and processes per prompt. X9PS1_TEST_BASH runs it all under another bash.
