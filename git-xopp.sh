#!/bin/bash

# Source: https://linuxhint.com/debug-bash-script/
# Source: https://www.howtogeek.com/782514/how-to-use-set-and-pipefail-in-bash-scripts-on-linux/

# PS4='$LINENO-- ' # Print line number instead of + in xtrace mode

set -o xtrace # Execution trace enabled
#set -o noexec # No execution mode enabled
# set -o noglob # Disable file name generation (globbing).
set -o nounset # Treat unset variables as an error when performing parameter expansion
#set -o errexit # Exit immediately if a simple command exits with a non-zero status. Not to be used.
# Source: https://mywiki.wooledge.org/BashFAQ/105
set -o noclobber # Disallow existing regular files to be overwritten by redirection of output
set -o pipefail # Exit immediately if a pipe exits with a non-zero status.

# nullglob and failglob are good for testing.
shopt -s nullglob # nullglob expands non-matching globs to zero arguments, rather than to themselves.
shopt -s failglob # If a pattern fails to match, bash reports an expansion error.
shopt -s nocasematch # Globs inside [[ and case commands are matched case-insensitive
shopt -s checkwinsize # Bash will check the terminal size when it regains control.

# $1 is name of directory containing xopp files

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
export direc
export curDir
export parentDir
export gitDir
export tmpDir
export pdfDir

GitExist() {
			if [[ -d "${gitDir}/.git" ]]
			then
				if [[ -d "$tmpDir" ]]
				then
					true
				else
					mkdir -p "$tmpDir"
				fi
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
			cd "$tmpDir" || ( notify-send --wait "Bullshit" && exit 1 )
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
						xournalpp --create-pdf="${pdfDir}/${i::-4}.pdf" "${direc}/${i::-4}.xopp"
					fi
				else
					mv "${tmpDir}/$i" "${gitDir}/${i::-4}"
					printf "%s\n" "New file ${i::-4}.pdf added." >> "${tmpDir}/Commit.msg"
					xournalpp --create-pdf="${pdfDir}/${i::-4}.pdf" "${direc}/${i::-4}.xopp"
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

#ExtractCommit() {
#	commitHash="$1"
#	fileName="$2"
#	destinationDir="$3"

#	git show "${1}":"${2}" | gzip -c - > "${3}/${2}.xopp"

#}


if [[ -d "$1" ]]
then
	direc="$1"
	true
else
	notify-send --wait "Bullshit"
	exit 1
fi

GitExist
DecomXopp

if [[ -d "$pdfDir" ]]
then
	true
else
	mkdir -p "$pdfDir"
fi

CreateCommitMsg
GitCommit
DeleteTmp

# TODO: Script needs to be fractionated with $1 for commiting and extracting file from a commit
