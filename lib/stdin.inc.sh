# note: http://stackoverflow.com/questions/6255303/bash-piping-prevents-global-variable-assignment
# return 0 : successfully printed stdin
# return 10: terminal, nothing interesting to print
# return 20: character device, nothing interesting to print
# return 30: attempting to print empty file
# return 40: attempting to print empty text stream
# return 50: unsuccessful read from stdin
# return 60: unsuccessful detection of /dev/stdin
print_stdin() {
	local stdinput # local variable to store /dev/stdin in memory
	# if dealing with a terminal, nothing to do, return
	if [[ -t /dev/stdin ]]; then
		return 10
	# if dealing with a character device, nothing to do, return
	elif [[ -c /dev/stdin ]]; then
		return 20
	# if /dev/stdin is a file, we know we are dealing with file input redirection
	elif [[ -f /dev/stdin ]]; then
		# use a subshell to store stdin and append the character x
		# the quotes and echo x preserve whitespace and worksaround bash stripping characters from stdin in the variable assignment
		stdinput="$(cat </dev/stdin; echo x)"
		# if stdin is !== character x, we know stdin was not empty
		if [[ "$stdinput" != x ]]; then
			stdinput="${stdinput%x}" # clean up stdin
			printf -- "$stdinput"
			return 0
		fi
		return 30
	# if /dev/stdin is a pipe
	elif [[ -p /dev/stdin ]]; then
		# attempt to read the first char from stdin, with a short timeout
		# use a very unlikely IFS to preserve any IFS characters in the text stream
		# this approach works when forks and subshells may be a factor
		# the timeout ensures the read is non-blocking
		if IFS='\0\0\0\t' read -t0.5 -N1 char </dev/stdin; then
			# use a subshell to store stdin and append the character x
			# the quotes and echo x preserve whitespace and worksaround bash stripping characters from stdin in the variable assignment
			stdinput="${char}$(cat </dev/stdin; echo x)" # variable to store /dev/stdin in memory
			unset char # don't need this
			# if stdin is !== character x, we know stdin was not empty
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