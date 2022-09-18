#!/bin/bash

# Source: https://linuxhint.com/debug-bash-script/
# Source: https://www.howtogeek.com/782514/how-to-use-set-and-pipefail-in-bash-scripts-on-linux/

#if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
	PS4='$LINENO-- ' # Print line number instead of + in xtrace mode
	set -o xtrace       # Trace the execution of the script (debug)
#fi

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
#if ! (return 0 2> /dev/null); then
    # A better class of script...
#    set -o errexit      # Exit on most errors (see the manual): Unreliable
#    set -o nounset      # Disallow expansion of unset variables
#    set -o pipefail     # Use last non-zero exit code in a pipeline: Unreliable
#fi

#set -o noexec # No execution mode enabled
# set -o noglob # Disable file name generation (globbing).
# Source: https://mywiki.wooledge.org/BashFAQ/105
#set -o noclobber # Disallow existing regular files to be overwritten by redirection of output

# nullglob and failglob are good for testing.
#shopt -s nullglob # nullglob expands non-matching globs to zero arguments, rather than to themselves.
#shopt -s failglob # If a pattern fails to match, bash reports an expansion error.
#shopt -s nocasematch # Globs inside [[ and case commands are matched case-insensitive
#shopt -s checkwinsize # Bash will check the terminal size when it regains control.

total=$(grep pageno= "$1" | tail -n1 | cut -d'"' -f4)

from="${2}"
to="${3}"

for i in $(eval "echo {${from}..${total}}")
do
	sed -i "s#pageno=\"${i}\"#pageno=\"${to}_new\"#g" "${1}"
	((to += 1))
done
