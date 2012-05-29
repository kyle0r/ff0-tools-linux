#!/bin/bash

#    <copyright license=gpl>
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
#    This program formats GTAIV handling.dat file(s) in a human readable way.
#    Copyright (C) 2012  Kyle       
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#	 The GNU GPL does NOT permit incorporating this program into proprietary programs.
#
#    ----------
#
#    The GNU General Public License is provided in the COPYING file.
#
#    See README file for contact details and more info.
#    </copyright>

# This script will parse a GTAIV handling.dat file, assuming that its in original R* form.
# Modifications to the config lines in the handling.dat are fine, so long as the overall form of the file matches the R* original.
# For this script to work, its important not to adjust the handling.dat outside of the actual config lines.

# The reason awk doesn't just process and output the whole file, is because of the way awk doesn't preserve whitespace,
# even for lines its simply printing. A bit of a pitfall of awk I've learnt about while writing this script!

# The basic approach is:
# 1. determine the line the actual handling config lines start, in the original R* file this is demarked by > THE DATA <
# 2. from the determined start point, awk through the handling file, formatting in a human readable way, store to file
# 3. when awk matches non interesting handling config lines, exit, storing while line it stopped processing
# 4. stitch everything together

# The three parts of the stitch are:
# 1. the initial lines of the file, that that we don't want awk to process
# 2. the lines that awk has processed
# 3. the remaining lines that we don't want awk to process

me="$(basename $0)"
lib_dir="/home/Kyle/ff0-tools/lib"
TMP="/tmp"

# include the required libs
. "${lib_dir}/stdin.inc.sh"

# set up a temp dir, and change to it
tmp_working_dir="$(mktemp -d $TMP/$me-XXXXXXXXXX)"
cd $tmp_working_dir
tmp_file_template="$tmp_working_dir/tmp.XXXXXXXXXX"

# options
attempt_to_clobber_original_file=true
debug=true

# variable declarations
handling_file="$(cygpath 'S:\!Installed Games\Steam\steamapps\common\grand theft auto iv\GTAIV\common\data\handling.dat')"
#handling_file="$(cygpath 'S:\Program Files\SparkIV 0.6.9\mods\ultimate_vehicle_pack_v9_extracted\GTAIV-pack\common\data\handling.dat')"
#handling_file="$(cygpath 'S:\Program Files\SparkIV 0.6.9\mods\ultimate_vehicle_pack_v9_extracted\TBoGT-pack\common\data\handling.dat')"
handling_file_human_readable="$handling_file.new"
handling_file_dir=$(dirname "$handling_file")

# functions
was_invoked_interactively() { [[ -t 1 || -p /dev/stdout ]] && return 0 || return 1; }
should_clobber_original_file() { [[ true == "$attempt_to_clobber_original_file" ]] && return 0 || return 1; }
do_debug() { [[ true == "$debug" ]] && return 0 || return 1; }

print_debug() {
	if do_debug; then
		# if any function arguments exist, print them first
		if [[ -n "$*" ]]; then
			printf -- "$*\n"
		fi
		
		print_stdin
	fi
}
print_error() { printf -- "$*" 1>&2; }

# prerequisite checks
# can we read the $handling_file?
if [[ ! -r "$handling_file" ]]; then print_error "Couldn't read handling file, exiting: \"$handling_file\"\n"; exit 1; fi
# determine which line to start processing the file with awk
which_line_to_start_awk=$(grep -m1 -n '> THE DATA <' "$handling_file" | egrep -o '^[0-9]+')
if [[ -z "$which_line_to_start_awk" ]]; then print_error "Couldn't determine which line to start on, exiting.\n"; exit 1; fi

group_header_file=$(mktemp $tmp_file_template)
which_line_did_awk_stop_file=$(mktemp $tmp_file_template)
new_handing_file_part1=$(mktemp $tmp_file_template)
new_handing_file_part2=$(mktemp $tmp_file_template)
new_handing_file_part3=$(mktemp $tmp_file_template)

print_debug "awk will start on line $which_line_to_start_awk"

# FIX ME translating tabs to spaces, this is probably what is causing whitespace issues
# this current allows column -t -x to work, but perhaps its not needed or should be done inline?
tr '\t' ' ' < "$handling_file" |
awk -v group_header_file=$group_header_file -v start_line=$which_line_to_start_awk -v stop_line=$which_line_did_awk_stop_file '
BEGIN {
	command = "column -t -x"
	group_header_written = 0
}
NR < start_line { next } # skip non-interesting lines
{
	#print "debugline: "NR": "$0 > "/dev/stderr" # debug
}
# deal with group header lines
NR > start_line && /^; name/ {
	#print NR"group hearder line" > "/dev/stderr" # debug
	if ($1$2 == ";name" && 0 == group_header_written) {
		printf $1" "$2"          "$3"     "$4"  "$5" "$6"       "$7"                "$8"            "$9" "$10"                  "$11"                               "$12"              "$13"  "$14"     "$15"    "$16"   "$17"\n" > group_header_file
		#printf $1$2"\t\t"$3"\t "$4"  "$5" "$6"\t      "$7"\t\t  "$8"\t    "$9" "$10"\t\t  "$11"\t\t\t\t       "$12"\t\t    "$13"  "$14"     "$15"    "$16"    "$17"\n" > group_header_file
		group_header_written = 1
	}
	if ($1$2 == ";name") {
		print "%GROUP_HEADER%" | command
	}
}
# deal with header lines
/^; A.*Ma$/ {
	#print NR"header line" > "/dev/stderr" # debug
	header = ";:h:"$2" "
	for (i=3;i<=NF;i++) header = header $i" "
	header = header "\n"
	print header | command
}
# deal with the actual handling config lines, the ones we want to be human readable
NR > start_line && ( /^[A-Z]/ || /^#[A-Z]/ ) {
	#print NR"config line" > "/dev/stderr" # debug
	printf "%s %.01f %.01f %2d %.02f %.02f %.02f %.02f %1d %.02f %.02f %03d %.02f %.02f %.02f %.01f %.02f %.02f %.01f %.02f %.02f %.01f %.01f %.01f %.02f %.02f %.02f %.02f %.01f %.01f %.01f %.01f %.02f %-6d %-8d %-8d %-2d\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37 | command
}
/^;([[:blank:]]+)?$/ || /^;:c:/ || /^;:h:/ {
	print $0 | command
}
# deal with category lines
NR > start_line && ( /^;-+/ ) {
	#print NR"category line" > "/dev/stderr" # debug
	category = ";:c:" gensub("[- ]", "", "g")
	print category | command
	
}
# as soon as a line that is not of interest is matched, store the line number in stop_line file and exit
# non interesting lines are those lines which have not prevoiusly matched above, perhaps there is a better
# way of expressing that in awk?
NR > start_line && ! ( /^[A-Z]/ || /^#[A-Z]/ || /^; A.*Ma$/ || /^;([[:blank:]]+)?$/ || /^; name/ || /^;-+/ || /^;:c:/ || /^;:h:/ ) {
	print NR > stop_line
	exit
}
' > $new_handing_file_part2

# set variables post awk
group_header_line=$(< $group_header_file)
which_line_did_awk_stop=$(< $which_line_did_awk_stop_file)

print_debug "awk stopped on line $which_line_did_awk_stop"

# replace group header placeholders with group header line
sed "s/%GROUP_HEADER%/$group_header_line/" < $new_handing_file_part2 > $new_handing_file_part2~
mv -vf $new_handing_file_part2~ $new_handing_file_part2 | print_debug

# get file part 1 & 3, the bits we didn't want awk to process
head -n $which_line_to_start_awk "$handling_file" > $new_handing_file_part1
tail -n +$which_line_did_awk_stop "$handling_file" > $new_handing_file_part3

# stitch it all together
cat $new_handing_file_part{1,2,3} > "$handling_file_human_readable"

print_debug "========== CLEAN UP =========="
rm -rv $tmp_working_dir | print_debug

# debug
#less "$handling_file_human_readable"
#exit

print_debug "========== VALIDATION =========="
print_debug "File line counts:"
line_counts=$(wc -l "$handling_file" "$handling_file_human_readable" | head -n 2)
print_debug "$line_counts"
original_count=$(echo "$line_counts" | awk '{ print $1; exit }')
new_count=$(echo "$line_counts" | awk 'NR == 2 { print $1; exit }' )
if [[ "$original_count" != "$new_count" ]]; then print_error "Line count validation failed, exiting!\n"; exit 1; fi


if should_clobber_original_file; then
	print_debug "script is set to clobber original file."
	# can we write the target?
	if [[ ! -w "$handling_file" ]]; then print_error "Couldn't write to target file , exiting: \"$handling_file\"\n"; exit 1; fi
	if was_invoked_interactively; then
		print_error "Should the original file be clobbered? [Y/n]: " 
		read attempt_to_clobber_original_file
		shopt -s nocasematch
		if [[ "$attempt_to_clobber_original_file" =~ (^([y]{1}|yes)$|^$) ]]; then
			attempt_to_clobber_original_file=true
		else
			attempt_to_clobber_original_file=false
		fi
		shopt -u nocasematch
	fi
	if should_clobber_original_file; then
		cp -va "$handling_file"{,.bak} | print_debug
		mv -vf "$handling_file_human_readable" "$handling_file" | print_debug
		print_debug "original file backed up and clobbered, work done, exiting."
	else
		print_debug "not clobbering, work done, exiting."
	fi
else
	print_debug "script is set not to clobber original file. work done, exiting."
fi

exit 0