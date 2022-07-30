#!/bin/bash

set -x

# $1 is name of directory containing xopp files

# Source: https://stackoverflow.com/a/1371283
Dir="$1"
shopt -s extglob           # enable +(...) glob syntax
curDir=${Dir%%+(/)}    # trim however many trailing slashes exist
curDir=${curDir##*/}       # remove everything before the last / that still remains
curDir=${curDir:-/}        # correct for dirname=/ case
shopt extglob
parentDir=$(dirname "$Dir")
gitDir="$parentDir"/"${curDir}-git"
TmpDir="${gitDir}/.tmp"

# Source: https://www.shellcheck.net/wiki/SC2155
export Dir
export curDir
export parentDir
export gitDir
export TmpDir

GitExist() {
			if [[ -d "${gitDir}/.git" ]]
			then
				if [[ -d "$TmpDir" ]]
				then
					true
				else
					mkdir "$TmpDir"
				fi
			else
				mkdir -p "$TmpDir" \
					&& cd "$gitDir" && git init \
					|| notify-send --wait "Bullshit"  # check git repo exists if not create a dir and init a git vcs
			fi
}

DecomXopp() {
			cd "$Dir" || notify-send --wait "Bullshit"
			for i in *.xopp
				do [ -e "$i" ] || continue
					gzip -cd "$i" > "$TmpDir"/"${i::-5}.xml"
			done
}

CreateCommitMsg() {
#			CheckSha() {
#			[[ $(sha1sum "$i" | cut -d ' ' -f 1) == "$(sha1sum "$TmpDir"/"$i" | cut -d ' ' -f 1)" ]]
#			}
			# Source: https://linuxcent.com/bash-how-to-trim-string/
			cd "$TmpDir" || notify-send --wait "Bullshit"
			for i in *.xml
			do [ -e "$i" ] || continue
				if [[ -f "$gitDir"/"${i::-4}" ]]
				then
					if [[ $(sha1sum "$gitDir"/"${i::-4}" | cut -d ' ' -f 1) == "$(sha1sum "$TmpDir"/"$i" | cut -d ' ' -f 1)" ]]
					then
						true
					else
						mv "$TmpDir"/"$i" "$gitDir"/"${i::-4}" && \
							printf "%s\n" "Modified ${i::-4}.pdf" >> "$TmpDir"/Commit.msg
					fi
				else
					mv "$TmpDir"/"$i" "$gitDir"/"${i::-4}" && \
						printf "%s\n" "Newly file ${i::-4}.pdf added." >> "$TmpDir"/Commit.msg
				fi
			done
}

GitCommit() {
			if [[ -f "$TmpDir"/Commit.msg ]]
			then
				git add .
				git commit -qm # Use Commit.msg Commit message
			else
				exit 0
			fi
}

DeleteTmp() {
			if [[ "$?" == 0 ]]
			then
				rm -rf "$TmpDir"
			else
				notify-send --wait "git-xopp.sh failed"
			fi
}

if [[ -d "$1" ]]
then
	true
else
	notify-send --wait "Bullshit" && exit 1
fi

GitExist
DecomXopp
CreateCommitMsg
#GitCommit
#DeleteTmp
