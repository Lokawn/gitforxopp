#!/bin/bash

# Source: https://linuxhint.com/debug-bash-script/
# Source: https://www.howtogeek.com/782514/how-to-use-set-and-pipefail-in-bash-scripts-on-linux/

# PS4='$LINENO-- ' # Print line number instead of + in xtrace mode

#if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
    set -o xtrace       # Trace the execution of the script (debug)
#fi

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    # A better class of script...
    set -o errexit      # Exit on most errors (see the manual)
    set -o nounset      # Disallow expansion of unset variables
    set -o pipefail     # Use last non-zero exit code in a pipeline
fi

#set -o noexec # No execution mode enabled
# set -o noglob # Disable file name generation (globbing).
# Source: https://mywiki.wooledge.org/BashFAQ/105
set -o noclobber # Disallow existing regular files to be overwritten by redirection of output

# nullglob and failglob are good for testing.
shopt -s nullglob # nullglob expands non-matching globs to zero arguments, rather than to themselves.
shopt -s failglob # If a pattern fails to match, bash reports an expansion error.
shopt -s nocasematch # Globs inside [[ and case commands are matched case-insensitive
shopt -s checkwinsize # Bash will check the terminal size when it regains control.

DirExist() {
	if [[ -d "$1" ]]
	then
		# $1 is name of directory containing xopp files
		direc="$1"
		# Source: https://stackoverflow.com/a/1371283
		# Source: https://mywiki.wooledge.org/glob#extglob
		shopt -s extglob           # Bash offers extended globs which have the expressive power of regular expressions.
		curDir=${direc%%+(/)}    # trim however many trailing slashes exist
		curDir=${curDir##*/}       # remove everything before the last / that still remains
		curDir=${curDir:-/}        # correct for dirname=/ case
		#shopt -u extglob
		parentDir=$(dirname "$direc")
		gitDir="${parentDir}/${curDir}-git"
		tmpDir="${gitDir}/.tmp"
		pdfDir="${parentDir}/${curDir}-pdf"
		# Source: https://www.shellcheck.net/wiki/SC2155
		export direc curDir parentDir gitDir tmpDir pdfDir

		if [[ -d "$pdfDir" ]]
		then
			true
		else
			mkdir -p "$pdfDir"
		fi

		if [[ -d "$tmpDir" ]]
		then
			true
		else
			mkdir -p "$tmpDir"
		fi

	else
		ScriptUsage
	fi
}

GitExist() {
			if [[ -d "${gitDir}/.git" ]]
			then
				true
			else   # check git repo exists if not create a dir and init a git vcs
				# Use parenthesis after OR operator. Source: https://stackoverflow.com/a/14836846
				mkdir -p "$tmpDir" || ( notify-send --wait "Bullshit" && exit 1 )
				cd "$gitDir" && git init
			fi
}

DecomXopp() {
			cd "$direc" || ( notify-send --wait "Bullshit" && exit 1 )
			for i in *.xopp
				do [ -e "$i" ] || continue
					gzip -cd "${direc}/$i" > "$tmpDir"/"${i::-5}.xml"
			done
}

CreateCommitMsg() {
#			CheckSha() {
#			[[ $(sha1sum "$i" | cut -d ' ' -f 1) == "$(sha1sum "$TmpDir"/"$i" | cut -d ' ' -f 1)" ]]
#			}
			# Source: https://linuxcent.com/bash-how-to-trim-string/
			cd "$tmpDir"
			for i in *.xml
			do [ -e "$i" ] || continue
				if [[ -f "${gitDir}/${i::-4}" ]]
				then
					if [[ $(sha1sum "${gitDir}/${i::-4}" | cut -d ' ' -f 1) == "$(sha1sum "${tmpDir}/$i" | cut -d ' ' -f 1)" ]]
					then
						true
					else
						mv "${tmpDir}/$i" "${gitDir}/${i::-4}"
						printf "%s\n" "Modified ${i::-4}.pdf" >> "${tmpDir}/Commit.msg"
#						xournalpp --create-pdf="${pdfDir}/${i::-4}.pdf" "${direc}/${i::-4}.xopp"
					fi
				else
					mv "${tmpDir}/$i" "${gitDir}/${i::-4}"
					printf "%s\n" "New file ${i::-4}.pdf added." >> "${tmpDir}/Commit.msg"
#					xournalpp --create-pdf="${pdfDir}/${i::-4}.pdf" "${direc}/${i::-4}.xopp"
				fi
			done
}

GitCommit() {
			if [[ -f "${tmpDir}/Commit.msg" ]]
			then
				cd "$gitDir" || ( notify-send --wait "Bullshit" && exit 1 )
				git add --all -- ':!.tmp'
				git commit -qF "${tmpDir}/Commit.msg"	# Use Commit.msg as Commit message.
			else
				exit 0
			fi
}

DeleteTmp() {
			if [[ "$?" == 0 ]]
			then
				rm -rf "$tmpDir"
			else
				notify-send --wait "git-xopp.sh failed"
				exit 1
			fi
}

ExtractXopp() {
#	if [[ -d "${1}/.git" && -f "${1}/${3::-5}" && -d "$4" ]]
	if [[ -d "${1}/.git" && -d "$4" ]]
	then
		cd "$1"
		if git cat-file commit "${2}"
		then
			git show "${2}":"${3::-5}" | gzip -c - > "${4}/${3}"
		else
			echo "Commit does not exist."
			exit 1
		fi
	else
		echo "Check if Source directory, file and Destination exist."
		exit 1
	fi
}

ExtractPdf() {

	body() { # TODO: Use a different background for PDF instead of hardcoded one, incase the pdf has been moved.
		if [[ -f "$( gzip -cd "${1}/.tmp/${3::-4}.xopp" | grep filename  | cut -d '"' -f 6)" ]]
		then
			xournalpp --create-pdf="${4}/${3}" "${1}/.tmp/${3::-4}.xopp"
			rm -rf "${1}/.tmp"
		else
			echo "PDF does not exist, check again."
		fi
	}
	if [[ -d "${1}/.tmp" && -d "${1}/.git" ]]
	then
		ExtractXopp "${1}" "$2" "${3::-4}.xopp" "${1}"/.tmp
		body "$@"
	else
		mkdir -p "${1}/.tmp" "${1}/.git"
		ExtractXopp "${1}" "$2" "${3::-4}.xopp" "${1}"/.tmp
		body "$@"
	fi
}

# DESC: Usage help
# ARGS: None
# OUTS: None
ScriptUsage() {
    cat << EOF
Usage:
	${BASH_SOURCE##*/} help
	${BASH_SOURCE##*/} extract(pdf) source hash filename.(xopp,pdf) destination (SOURCE_PDF)
	${BASH_SOURCE##*/} commit source

	Commands:

	help|h                       Displays this help
	extract|ex|e                 Extract a specified xopp from a commit
	commit|c|add|new             Commit any new or modified files if present
	extractpdf|pdf|epdf               Extract a specified PDF from a commit
	Options:
		For Extract Commands
		- source                 Source directory containing the Git VCS
		- hash                   Hash of commit to extract from
		- filename               File name for new file created
		- destination            Destination for the new extracted file

		For Commit Command
		- source                 Source directory containing the Xopp Files
EOF
exit 1
}

# Source: https://stackoverflow.com/a/2013589

checkVar() {
	local mcd="${1:-mcd}"
	if [[ "$mcd" == "mcd" ]]
	then
		ScriptUsage
	else
		true
	fi
}

cmd="${1:-cmd}"
case "$cmd" in
	extract|ex|e)
		shift
		checkVar "$@"
		ExtractXopp "$@"
		;;
	commit|add|new|c)
		shift
		checkVar "$@"
		DirExist "$@"
		GitExist
		DecomXopp
		CreateCommitMsg
		GitCommit
		DeleteTmp
		;;
	extractpdf|pdf|epdf)
		shift
		checkVar "$@"
		ExtractPdf "$@"
		;;
	help|h|*)
		ScriptUsage
		;;
esac
