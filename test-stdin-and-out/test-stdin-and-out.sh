#!/bin/bash

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
#    This program attempts to test shell /dev/stdin and /dev/stdout devices.
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

# HOW/WHAT/WHEN
# =============
# The idea behind this script, is to test the stdin and stdout devices for a given shell instance.
# Given that a shell instance can be interactive, non-interactive, run under cron or ssh etc.
# Depending on how a shell instance is invokved changes how std devices behave, this script
# aim to show you the various behaviors. Good for learning about std devices and good for
# debugging when a std devices is doing what you want.

# TODO
# ====
# * Perhaps run similar tests for the 0 1 file handlers, as they behave differently

printf '\n#-----------------\____________START_SCRIPT_____________/------------------#\n'

me="$(basename $0)"
working_dir="/home/Kyle/ff0-tools"
test_types="f c p t"
TMP="/tmp"
tmp_file="$(mktemp ${TMP}/${me}-XXXXXXXXXX)"
# store some test text in $tmp_file
printf -- "\n\n2 new lines prepended\nsome copy\n2 new lines appended\n\n\n" > $tmp_file

# include the require libs
. "${working_dir}/lib/stdin.inc.sh"

stdin_tests() {
	local suffix="\n\n\n"
	local seperator=:@
	local stdin_content
	local stdin_content_result
	# use a subshell to store $1 and append the character x
	# the quotes and echo x preserve whitespace and worksaround bash stripping characters from $1 in the variable assignment
	# also exit with the function return, so we can use it in the test results
	stdin_content="$(print_stdin; result=$?; echo 'x'; exit $result)"; stdin_content_result=$?;
	
	case "$stdin_content_result" in
		0 ) stdin_content="${stdin_content%x}";;
		* ) stdin_content="${print_stdin_return[$stdin_content_result]}${suffix}";;
	esac
	
	# not able to store the result of these commands to variables (aka subshell) because
	# it effects the detection of $1, so using anon function block piped to formatter
	{
		std_tests "$1"
		
		printf -- "$1 content result${seperator}$stdin_content_result"
	} | column -t -s'@'

	printf "$1 textstream content:\n"
	printf -- "$stdin_content"
}

stdout_tests() {
	local seperator=:@

	# not able to store the result of these commands to variables (aka subshell) because
	# it effects the detection of $1, so using anon function block piped to formatter
	{
		std_tests "$1"
	} | column -t -s'@'
}

std_tests() {
	printf "file result${seperator}"; file -L "$1";
	printf "stat results${seperator}"; stat -L --printf="%n: type: %F, inode: %i\n" "$1"
	printf "ls results${seperator}"; ls -al "$1"
	printf "readlink results${seperator}"; readlink $(readlink $1) # readlink twice

	[[ -t "$1" ]] && printf "$1 test result${seperator}$1 is a terminal\n"
	[[ -c "$1" ]] && printf "$1 test result${seperator}$1 is a character device\n"
	[[ -p "$1" ]] && printf "$1 test result${seperator}$1 is a pipe\n"
	[[ -f "$1" ]] && printf "$1 test result${seperator}$1 is a file\n"	
}

# start the tests

std_type="/dev/stdin"


printf -- "\n#-------------------------------$std_type---------------------------------#\n"
printf -- "#-------------testing no input\n#-----------------------------\n"
stdin_tests "$std_type"
printf -- "#--------------------end test\n\n"


printf -- "#-----------testing pipe input\n#-----------------------------\n"
cat "$tmp_file" | stdin_tests "$std_type"
printf -- "#--------------------end test\n\n"

printf -- "#-------testing redirect input\n#-----------------------------\n"
stdin_tests "$std_type" < "$tmp_file"
printf -- "#--------------------end test\n\n"

std_type="/dev/stdout"

printf -- "\n#------------------------------$std_type---------------------------------#\n"
printf -- "#---------------testing stdout\n#-----------------------------\n"
stdout_tests "$std_type"
printf -- "#--------------------end test\n\n"
	
printf '#-----------------\_____________END_SCRIPT______________/------------------#\n\n'
rm -r ${TMP}/${me}-* 1>&2
