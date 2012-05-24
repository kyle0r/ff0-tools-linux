#!/bin/bash

printf '\n#-----------------\____________START_SCRIPT_____________/------------------#\n'

me="$(basename $0)"
working_dir="~/ff0-tools"
test_types="f c p t"
TMP="/tmp"
tmp_file="$(mktemp ${TMP}/${me}-XXXXXXXXXX)"
# store some test text in $tmp_file
printf -- "\n\n2 new lines prepended\nsome copy\n2 new lines appended\n\n\n" > $tmp_file

cd "$working_dir"
# include the require libs
. lib/stdin.inc.sh

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
		10) stdin_content="$1 is terminal, nothing interesting to do${suffix}";;
		20) stdin_content="$1 is character device, nothing interesting to do${suffix}";;
		30) stdin_content="$1 is an empty file${suffix}";;
		40) stdin_content="$1 is an empty text stream${suffix}";;
		50) stdin_content="unsuccessful read from $1${suffix}";;
		60) stdin_content="unsuccessful detection of $1${suffix}";;
		* ) stdin_content="invalid print_stdin() result - shit is broke!${suffix}"
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