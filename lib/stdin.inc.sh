
#    <copyright license=lgpl>
#    ff0-tools - a collection of useful linux compatible scripts and programs
#    Copyright (C) 2012  Kyle       
#
#    This file is part of ff0-tools.
#
#    ff0-tools is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
# 
#    ff0-tools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
# 
#    You should have received a copy of the GNU General Public License
#    along with ff0-tools.  If not, see <http://www.gnu.org/licenses/>.
#
#    The GNU GPL does NOT permit incorporating ff0-tools into proprietary programs.
#
#    ----------
#
#    This program provides functions related to a shells /dev/stdin device.
#    Copyright (C) 2012  Kyle       
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    ----------
#
#    The GNU General Public License is provided in the COPYING file.
#    The GNU Lesser General Public License is provided in COPYING.LESSER file.
#    Please note that the LGPL is a set of additional permissions on top of the GPL.
#
#    The GNU LGPL DOES permit incorporating this program into proprietary programs.
#
#    See README file for contact details and more info.
#    </copyright>

stdin=/dev/stdin
print_stdin_return[0]="successfully printed ${stdin}"
print_stdin_return[10]="terminal detected, not interesting, nothing to do"
print_stdin_return[20]="character device detected, not interesting, nothing to do"
print_stdin_return[30]="empty file detected, nothing to do"
print_stdin_return[40]="empty text stream detected, nothing to do"
print_stdin_return[50]="timeout during read from ${stdin}, probably an empty pipe"
print_stdin_return[60]="unsuccessful detection of ${stdin}, probably a bug"
unset stdin

# note: http://stackoverflow.com/questions/6255303/bash-piping-prevents-global-variable-assignment
# the print_stdin_return array documents return codes
print_stdin() {
	local stdin; stdin=/dev/stdin
	local stdinput # local variable to store $stdin in memory
	# if dealing with a terminal, nothing to do, return
	if [[ -t "${stdin}" ]]; then
		return 10
	# if dealing with a character device, nothing to do, return
	elif [[ -c "${stdin}" ]]; then
		return 20
	# if $stdin is a file, we know we are dealing with file input redirection
	elif [[ -f "${stdin}" ]]; then
		# Use a subshell to store $stdin and append the character x
		# the quotes and echo x preserve whitespace and worksaround
		# bash stripping characters from $stdin in the variable assignment.
		stdinput="$(cat <${stdin}; echo x)"
		# if $stdin is !== character x, we know it was not empty
		if [[ "$stdinput" != x ]]; then
			stdinput="${stdinput%x}" # clean up $stdin
			printf -- "$stdinput"
			return 0
		fi
		return 30
	# if $stdin is a pipe
	elif [[ -p "${stdin}" ]]; then
		# Attempt to read the first char from $stdin, with a short timeout
		# use a very unlikely IFS to preserve any IFS characters in the first
		# character of $stdin.
		# This approach works should forks and subshells may be a factor
		# the timeout ensures the read is non-blocking.
		# I have tested many alternatives, this approach appears the most robust.
		if IFS='\0\0\0\t' read -t0.5 -N1 char <"${stdin}"; then
			# Use a subshell to store $stdin and append the character x
			# the quotes and echo x preserve whitespace and worksaround 
			# bash stripping characters from $stdin in the variable assignment.
			stdinput="${char}$(cat <${stdin}; echo x)" # variable to store "${stdin}" in memory
			unset char # don't need this
			# if $stdin is !== character x, we know it was not empty
			if [[ "$stdinput" != x ]]; then
				stdinput="${stdinput%x}" # clean up stdin
				printf -- "$stdinput"
				return 0
			fi
			return 40
		fi
		return 50
	fi
	return 60
}