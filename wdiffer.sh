#!/bin/bash
# Name: wdiffer.sh
# Author: Rob Toscani
# Date: 26-12-2025
# Description: Private version of wdiff() as a Bash/GAWK script.
# Alternative for the standard UNIX wdiff() utility.
# It displays word differences between two plain text files.
#
#     Usage: wdiffer.sh [OPTIONS] textfile1 textfile2
#
# Following options are available: -h, -w, -x, -y and -z (see man wdiff)
#
# This program is based on the 'Longest Common Subsequence' (LCS) algorithm
# as laid out in:
# https://en.wikipedia.org/wiki/Longest_common_subsequence
#
# LeChat Mistral (AI) has been used to convert the *recursive* printDiff() function
# from above source into the *iterative* code of the 'while (pointer >= 0)' loop in
# below 'wdiff_function()'.
#
# Version with 'true 2d-arrays' for the LCS-matrix 'M' and the stack.
# Prerequisite:
# - gawk
#
#####################################################################################
#
# Copyright (C) 2025 Rob Toscani <rob_toscani@yahoo.com>
#
# wdiffer.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# wdiffer.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################


wdiff_function()
{
    gawk -v separator="$separator"  -v start_delete="$start_delete" -v end_delete="$end_delete" \
        -v start_insert="$start_insert" -v end_insert="$end_insert" '\
    function max(a, b){
        if (a >= b)
            return a
        else
            return b
    }

    BEGIN {
        split("", words1)
        split("", words2)
        split("", words3)
        words1[0] = ""
        words2[0] = ""
        m = 0
        n = 0
        k = 0
        flag = 1
    }

    {
        if ($0 == separator){
            flag = 2
            next
        }

        if (flag == 1){
           for (f = 1; f <= NF; f++)
                words1[++m] = $f
            words1[++m] = "\n"
        }
        else{
            for (f = 1; f <= NF; f++)
                words2[++n] = $f
            words2[++n] = "\n"
        }
    }

    END {

        split("", M)
        for (i = 0; i < m+1; i++)
            M[i][0] = 0
        for (j = 0; j < n+1; j++)
            M[0][j] = 0
        for (i = 1; i < m+1; i++){
            for (j = 1; j < n+1; j++){
                if (words1[i] == words2[j])
                    M[i][j] = M[i-1][j-1] + 1
                else
                    M[i][j] = max(M[i][j-1], M[i-1][j])
             }
        }

        split("", stack)
        stack[0][0] = m
        stack[0][1] = n

        pointer = 0

        while (pointer >= 0){

            i = stack[pointer][0]
            j = stack[pointer][1]
            pointer--

            if (i >= 0 && j >= 0 && words1[i] == words2[j]){
                pointer++
                stack[pointer][0] = i-1
                stack[pointer][1] = j-1
                if (pointer < 0)
                    words3[k++] = words1[i]
                else{
                    pointer++
                    stack[pointer][0] = "print"
                    stack[pointer][1] = words1[i]
                }
            }
            else if (j > 0 && (i == 0 || M[i][j-1] >= M[i-1][j])){
                pointer++
                stack[pointer][0] = i
                stack[pointer][1] = j-1
                if (pointer < 0 || stack[pointer][0] != "print"){
                    pointer++
                    stack[pointer][0] = "print"
                    stack[pointer][1] = start_insert""words2[j]""end_insert
                }
            }
            else if (i > 0 && (j == 0 || M[i][j-1] < M[i-1][j])){
                pointer++
                stack[pointer][0] = i-1
                stack[pointer][1] = j
                if (pointer < 0 || stack[pointer][0] != "print"){
                    pointer++
                    stack[pointer][0] = "print"
                    stack[pointer][1] = start_delete""words1[i]""end_delete
                }
            }
            else{
                if (pointer < 0 || stack[pointer][0] != "print"){
                    pointer++
                    stack[pointer][0] = "print"
                    stack[pointer][1] = ""
                }
            }

            while (pointer >= 0 && stack[pointer][0] == "print"){

                msg = stack[pointer][1]
                pointer--

                if (msg)
                    words3[k++] = msg
            }
        }

        for (i = k-1; i > 0; i--){
            if (! (words3[i] == "\n" || words3[i] == ""))
                printf words3[i]" "
            else{
                print ""
            }
        }

    }' "$1"
}

options(){
# Specify options:
    while getopts "hw:x:y:z:" OPTION; do
        case $OPTION in
            h) helptext
               exit 0
               ;;
            w) start_delete="$OPTARG"
               ;;
            x) end_delete="$OPTARG"
               ;;
            y) start_insert="$OPTARG"
               ;;
            z) end_insert="$OPTARG"
               ;;
            *) helptext
               exit 1
               ;;
        esac
    done
}

helptext()
# Text printed if -h option (help) or a non-existent option has been given:
{
    while read "line"; do
        echo "$line" >&2         # print to standard error (stderr)
    done << EOF
Usage:
       wdiffer.sh [OPTION(S)]  FILE1  FILE2

|  -h          Help (this output)
|  -w STRING   String to mark beginning of delete region
|  -x STRING   String to mark end of delete region
|  -y STRING   String to mark beginning of insert region
|  -z STRING   String to mark end of insert region
EOF
}

make_separator()
# Unique random string to separate file2 from file1 in catenated stream to awk:
{
    echo "$(tr -dc a-z < /dev/urandom | head -c 80)"
}

start_delete=""
end_delete=""
start_insert=""
end_insert=""

# Execute the options:
options "$@"
shift $(( OPTIND - 1 ))

file_1="$1"
file_2="$2"

separator="$(make_separator)"

# Call wdiff_function with both files combined in one including separator line:
(cat "$file_1"; echo -e "\n$separator"; cat "$file_2") | wdiff_function -
