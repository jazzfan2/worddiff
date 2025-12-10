#!/bin/bash
# Name: worddiff2.sh
# Author: Rob Toscani
# Date: 8th December 2025
# Description: This program is a wrapper-script around 'wdiff()'
# (https://www.gnu.org/software/wdiff/)
# It does a word-by-word comparison in color among each pair of equally 
# numbered flat-text files shared by the two given directories.
# The results are stored to color-marked difference-files in html-, or
# (optionally) pdf-format, and collected in the ./diff/ directory.
#
# Usage:     worddiff2.sh  [OPTION]... DIR1 DIR2 
#
# Options:
#   -h       Help (this output)
#   -p       Output as .pdf- instead of .html-files
#
# Prerequisites:
# - wdiff
# - wkhtmltopdf (if output to pdf is desired)
#
#####################################################################################
#
# Copyright (C) 2025 Rob Toscani <rob_toscani@yahoo.com>
#
# worddiff2.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# worddiff2.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################

# Standard output-format:
format="html"

# The html-tags to be pasted underneath the text:
html_coda="
</pre>
</body>
</html>"

# The color markings:
delete_start="<span style=\"font-weight:bold;color:#ff0000;\">"
insert_start="<span style=\"font-weight:bold;color:#00ff00;\">"
end="</span>"

# Escape < and > to prevent interpretation as html-syntax (tags):
esc_html="s/</\&lt;/g; s/>/\&gt;/g" 


# Functions:
# ==========

options(){
# Specify options:
    while getopts "hp" OPTION; do
        case $OPTION in
            h) helptext
               exit 0
               ;;
            p) format="pdf"
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
Usage: worddiff2.sh [-hp] directory1 directory2

-h       Help (this output)
-p       Output as .pdf- instead of .html-files
EOF
}

numberlist()
# Print a ('horizontal') list of the leading numbers in the file names in given directory:
{
    ls "$1"           |
    grep -oE ^[0-9]+_ |
    tr '_' ' '        |
    sort -n           |
    tr -d '\n'        |
    sed 's/ $//'
}

checkrepeat()
# Detect any repetitions in a sorted number list, and issue a warning if found:
{
    repeatnum="$(grep -oE "(\<[0-9]+\>) \1" <<< "$1")"
    if [[ -n "$repeatnum" ]]; then
        qty=$(wc -w <<< "$repeatnum")
        num=${repeatnum/ */}
        echo "Warning: number $num appears in $qty file-names in the $2."
        echo "Only one file with $num was compared with a (possibly wrong) file in the $3."
    fi
}

makediff()
# Compare all numbered text files in 1st directory with those in 2nd directory, and store output:
{
    NUMBER=$1
    file1="$(ls $2/$NUMBER"_"* 2>/dev/null | head -n 1)"
    file2="$(ls $3/$NUMBER"_"* 2>/dev/null | head -n 1)"

# The html-tags to be pasted above the text:
    html_intro="
<!DOCTYPE html>
<html>
<head>
<meta charset=\"utf8\">
<style type=\"text/css\">
pre {
  font-family:Courier New;
  font-size:12pt;
  white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  white-space: -webkit-pre-wrap;
  word-wrap: break-word;
}
</style>
<title>$file2</title>
</head>
<body>
<pre>"

    # Do nothing if a number is missing. and issue warning if appearing in one directory only:
    if ([[ -z "$file1" ]] || [[ -z "$file2" ]]); then
        if [[ -n "$file1" ]]; then
            echo "Warning: nummer $NUMBER appears in 1st directory only, not in 2nd directory."
        elif [[ -n "$file2" ]]; then
            echo "Warning: nummer $NUMBER appears in 2nd directory only, not in 1st directory."
        fi
        return
    fi

    # Generate the color-marked difference-file:
    wdiff -w "$delete_start" -x "$end" -y "$insert_start" -z "$end" \
              <(sed "$esc_html" "$file1") <(sed "$esc_html" "$file2") |

    # And save results in desired format (default .html):
    cat <(echo "$html_intro") - <(echo "$html_coda") | store2file - $NUMBER
}

store2file()
# Store html-text to (html-)file, or (if option -p is given) convert to pdf-file:
{
    file="$1"
    NUMBER="$2"
    if [[ $format == "html" ]]; then
        cat "$file" >| ./diff/"$(date +"%Y%m%d_%H%M")_diff_$NUMBER.html"
    else
        wkhtmltopdf "$file" ./diff/"$(date +"%Y%m%d_%H%M")_diff_$NUMBER.pdf" 2>/dev/null
    fi
}


# Main function:
# ==============

# Execute the options:
options $@
shift $(( OPTIND - 1 ))

# Check if given directories exist:
([[ ! -d "$1" ]] || [[ ! -d "$2" ]]) && echo "Specify existing directories." && exit 1

# Create the ./diff/-directory, unless it already exists:
[[ ! -d ./diff ]] && mkdir ./diff

# Create a list with all <NUMBER> values for each if the two directories:
list1="$(numberlist "$1")"
list2="$(numberlist "$2")"

# Check if de <NUMBER>-lists contain repetitions, and if so issue a warning:
checkrepeat "$list1" "1st directory" "2nd directory"
checkrepeat "$list2" "2nd directory" "1st directory"

# Determine the maximum <NUMBER> value appearing in any of the sorted lists:
max1=${list1/* /}
max2=${list2/* /}
(( max1 > max2 )) && max=$max1 || max=$max2

# While incrementing to max <NUMBER> value, call makediff() function with value argument:
NUMBER=0
while (( NUMBER <= max )); do
    makediff $NUMBER "$1" "$2"
    (( NUMBER += 1 ))
done

# Afsluiting:
echo "Ready! - Please find all difference-files in $(pwd)/diff/"
