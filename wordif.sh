#!/bin/sh
# Name: wordif.sh
# Author: Rob Toscani
# Date: 25th August 2026
# Description: This program performs word-by-word comparison between
# two plain-text-files.
#
# It is a wrapper-script around 'diff()', and serves as an alternative
# for wdiff() (https://www.gnu.org/software/wdiff/).
#
# It can function in two modes:
# Either:
#     a. (default) one single comparison between given two text-files,
# or:
#     b. (optionally) multiple comparison of all pairs of text-files
#        with equally numbered name, shared by given two directories.
#
# The results are stored as color-marked difference-files in HTML-,
# or (optionally) PDF-format, or (optionally) sent to stdout in HTML-format.
#
# Prerequisite:
# - wkhtmltopdf (if output to PDF is desired)
#
# (The script 'shufflewords.sh' can be used to stress-test this program.)
#
#####################################################################################
#
# Copyright (C) 2026 Rob Toscani <rob_toscani@yahoo.com>
#
# wordif.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# wordif.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################

# Default arguments:
args="files"

# Default deletion- and insertion-colors:
delhex="ff0000"
inshex="00ff00"

# Default behaviour in case of word breaks at end of line - do not reunite:
reunite=false

# Standard character font:
font="\"Courier New\", monospace"

# Standard character size:
size=12

# Escape < and > to prevent interpretation as HTML-syntax (tags):
esc_html="s/</\&lt;/g; s/>/\&gt;/g"

# Unique string to temporarily add to file2, forcing diff to output if files are equal:
tempstring="$(date)"

# The HTML-tags to be pasted underneath the text:
html_coda="
</pre>
</body>
</html>"

# Standard output-directory:
outputdir="./"

# Standard output-format:
format="html_file"


# FUNCTIONS:
# ==========

options(){
# Specify options:
    while getopts "c:C:df:hoprz:" OPTION; do
        case $OPTION in
            c) if printf "$OPTARG" | grep -qE "^[0-9a-fA-F]{6}$" -; then
                   delhex="$OPTARG"
               else
                   helptext && exit 1
               fi
               ;;
            C) if printf "$OPTARG" | grep -qE "^[0-9a-fA-F]{6}$" -; then
                   inshex="$OPTARG"
               else
                   helptext && exit 1
               fi
               ;;
            d) args="directories"
               ;;
            f) if   [ $OPTARG = H ]; then font="\"Helvetica\", sans-serif"
               elif [ $OPTARG = h ]; then font="\"Helvetica Narrow\", sans-serif"
               elif [ $OPTARG = c ]; then font="\"Courier\", monospace"
               elif [ $OPTARG = n ]; then font="\"New Century Schoolbook\", serif"
               elif [ $OPTARG = p ]; then font="\"Palatino\", serif"
               elif [ $OPTARG = T ]; then font="\"Times New Roman\", serif"
               elif [ $OPTARG = t ]; then font="\"Times\", serif"
               else                       font="\"Courier New\", monospace"
               fi
               ;;
            h) helptext
               exit 0
               ;;
            o) if [ $format != "pdf_file" ]; then
                   format="html_stdout"
               fi
               ;;
            p) format="pdf_file"
               ;;
            r) reunite=true
               ;;
            z) if printf "$OPTARG" | grep -qE "^[[:digit:]]*\.?[[:digit:]]+$" -; then
                   size=$OPTARG
               else
                   helptext && exit 1
               fi
               ;;
            *) helptext
               exit 1
               ;;
        esac
    done
#  (Suggestion: an additional option could be introduced for showing 'deleted-text' in 'strikethrough' mode.)
}

helptext()
# Text printed if -h option (help) or a non-existent option has been given:
{
    while read "line"; do
        printf %s\\n "$line" >&2         # print to standard error (stderr)
    done << EOF
Usage:
|        wordif.sh   [OPTIONS]  FILE1       FILE2
|        wordif.sh -d[OPTIONS]  DIRECTORY1  DIRECTORY2
|
-h       Help (this output).
-c RGBHEX
|        Specify 'deleted-text' color by 6-digit rgb hex-value (default: ff0000 [red]).
-C RGBHEX
|        Specify 'inserted-text' color by 6-digit rgb hex-value (default: 00ff00 [green]).
-d       Specify two directories as arguments rather than two files.
|        Compare each file in directory2 to the equally unique-numbered file in directory1.
-f FONT
|        Character-font instead of default Courier New:
|        FONT  = H   Helvetica
|                h   Helvetica Narrow
|                c   Courier
|                n   New Century Schoolbook
|                p   Palatino
|                T   Times New Roman
|                t   Times
-o       Send HTML-text to stdout rather than to file.
-p       Convert HTML-text and save to PDF-file; this option overrides option -o
-r       Reunite words that are broken off at the end of a text line.
-z SIZE
|        Character size in pts as a replacement for 12 pts.
|        Also accepts values with decimal point.
EOF
}

checknumberless()
# Check on any unnumbered file names in a given directory, and if so issue a warning:
{
    if ls "$1" | grep -qv "^[0-9]\+_" ; then
        printf %s\\n "WARNING: Directory $2 contains unnumbered files that are excluded from comparison." >&2
    fi
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
# Detect any repeating numbers in a sorted number list, and issue a warning if found:
{
    repeatnum="$(printf "$1" |
    awk 'BEGIN { prevprint = -1 }
         { for (f = 2; f <= NF; f++)
               if ($f == $(f-1) && $f != prevprint){
                   printf ("%s ", $f)
                   prevprint = $f
               }
    }' - )"
    if [ -n "$repeatnum" ]; then
        printf %s%s  "WARNING: Number(s) $repeatnum" "found in more than one single file-name in directory $2. " >&2
        printf %s\\n "Per mentioned number, most files compare to a wrong file in directory $3." >&2
    fi
}

print_html_intro()
# Print the HTML-tags to be pasted above the text:
{
    intro="
<!DOCTYPE html>
<html>
<head>
<meta charset=\"utf8\">
<style type=\"text/css\">
pre {
  font-family: "$font";
  font-size:   "$size"pt;
  white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  white-space: -webkit-pre-wrap;
  word-wrap:   break-word;
}
</style>
<title>$1</title>
</head>
<body>
<pre>"
    printf %s\\n "$intro"
}

non_plain()
# Detect any non-plain-text contents:
{
    if file -bL "$1" | grep -qiv "text" || file -bL "$2" | grep -qiv "text"; then
        return 0
    fi
    return 1
}

splitwords()
# Place all words on a separate line, while preserving original newlines, spaces and tabs:
{
    awk '{
        gsub(/\r/,  "")            # Remove Carriage Return
        gsub(/ *$/, "")            # Remove Trailing Space(s)
        gsub(/^/, "\b")            # Place backspace at beginning of line as to mark original "new line"
        gsub(/ /, "\n")            # Replace Space by newline, putting each word on a separate line
        gsub(/\xc2\xa0/,     "\n") # Replace Non-Breaking Space    (U+00A0) by newline, for same reason
        gsub(/\xe2\x80\xaf/, "\n") # Replace Narrow No-Break Space (U+202F) by newline, for same reason
        gsub(/\t/,       "\n\t\n") # Put tab (tabulation) on a separate line as to treat it like a word
        print
    }' "$1"
}

unbreak_words()
# Only in case of option -r, reunite word-parts that are broken off at line end by either a (soft)hyphen or a space
# with unicode U+2006-, U+2009-, U+200A- U+200B- or U+200C. If option -r isn't given, don't reunite:
{
    awk -v reunite=$reunite 'BEGIN {
        prev = ""
    }
    {
        if (prev ~ "[^	\b\n ](-|\xc2\xad|\xe2\x80\x86|\xe2\x80\x89|\xe2\x80\x8a|\xe2\x80\x8b|\xe2\x80\x8c)$" &&
            $0 ~ "\b." && reunite == "true"){
            sub(/.$/, "", prev)
            sub(/\b/, "", $0)
            prev = prev""$0
        }
        else{
            print prev
            prev = $0
        }
    }
    END {
        print prev
    }' "$1"
}

cut_invisible()
# Remove invisible characters from input text-file:
{
    # https://stackoverflow.com/questions/27052194/how-to-replace-unicode-characters-with-ascii
    # https://thetexttool.com/blog/remove-invisible-unicode-characters
    # https://en.wikipedia.org/wiki/Whitespace_character#Unicode
    # \x-codes obtained through: echo "$(printf '\u00AD')" | hexdump -C
    awk '{
        gsub(/\xc2\xad/,     "")    # Remove Soft Hyphen               U+00AD
        gsub(/\xe2\x80\x86/, "")    # "      Six-per-Em Space          U+2006
        gsub(/\xe2\x80\x89/, "")    # "      Thin Space                U+2009
        gsub(/\xe2\x80\x8a/, "")    # "      Hair Space                U+200A
        gsub(/\xe2\x80\x8b/, "")    # "      Zero-Width Space          U+200B
        gsub(/\xe2\x80\x8c/, "")    # "      Zero-Width Non-Joiner     U+200C
        gsub(/\xef\xbb\xbf/, "")    # "      Zero-Width No-Break Space U+FEFF
        gsub(/\xe2\x81\xa0/, "")    # "      Zero-Width Word Joiner    U+2060
        print
    }' "$1"
}

untag_newlines()
# Remove tags caused by differences in newline placement:
{
    awk 'BEGIN {
        prev = ""
    }
    {
        prev_nobackspace = prev
        sub(/^[+-]/, " ", prev_nobackspace)
        sub(/\b/,     "", prev_nobackspace)
        pres_nobackspace = $0
        sub(/^[+-]/, " ", pres_nobackspace)
        sub(/\b/,     "", pres_nobackspace)
        if (pres_nobackspace == prev_nobackspace && prev ~ "^-" && $0 ~ "^\+"){
            prev = $0
            sub(/^\+/, " ", prev)
        }
        else{
            print prev
            prev = $0
        }
    }
    END {
        print prev
    }' "$1" 2>/dev/null
}

convert_tags()
# Replace '-' and '+' line tags by red and green html-color group tags, and remove leading space:
{
    tail -n +5 |
    awk -v delstart="$delete_start" -v insstart="$insert_start" -v end="$end" -v sign="xx" '
    {
        if (substr($0, 1, 1) == sign)
            qty += 1
        else{
            groups[++i, 0] = qty
            groups[  i, 1] = sign
            qty = 1
            sign = substr($0, 1, 1)
        }
        words[++j] = $0
    }
    END {
        groups[++i, 0] = qty
        groups[  i, 1] = sign
        j = 0
        for (k = 2; k <= i; k++){
            qty   = groups[k, 0]
            sign  = groups[k, 1]
            for (p = 1; p <= qty; p++){
                word = words[++j]
                if (sign == " " || (p > 1 && p < qty))
                    print substr(word, 2)
                else if (p == 1){
                    gsub(/^-/, delstart, word)
                    gsub(/^\+/, insstart, word)
                    if (qty == 1)
                        print word end
                    else
                        print word
                }
                else
                    print substr(word, 2) end
            }
        }
    }' -
}

joinwords()
# Place all words on the same line again, restore original newlines and remove temporarily added spaces:
{
    # Regex-group of a series of html color-tags as a string variable:
    taggroup="(($delete_start|$insert_start|$end)*)"

    # Restore original spaces from each temporary newline (adding some temporary spaces in the process):
    tr '\n' ' ' |

    # Restore original newlines from each temporary backspace:
    awk '{ gsub(/\b/, "\n"); print }' -  |

    # Remove all temporarily added single spaces: around each tab and at line end:
    sed -E 's_ '"$taggroup"'	'"$taggroup"' _\1	\3_g;
            s_ '"$taggroup"'$_\1_
            s/'"$tempstring"'//'
}

makediff()
# Perform text comparison between two text files, and generate color-marked difference-file:
{
    # Preprocessing steps:
    sed "$esc_html" "$1" | splitwords - | unbreak_words - | cut_invisible - >| "$tempdir"/file1_temp.txt
    sed "$esc_html" "$2" | splitwords - | unbreak_words - | cut_invisible - >| "$tempdir"/file2_temp.txt

    # Force diff -U to also output in case of no difference:
    printf %s\\n " $tempstring" >> "$tempdir"/file2_temp.txt

    # Do the actual 'diff -U'-operation, followed by the postprocessing steps:
    diff -U 100000000 "$tempdir/file1_temp.txt" "$tempdir/file2_temp.txt" |

    untag_newlines - |
    convert_tags -   |
    joinwords -
}

output()
# Save HTML-text-stream to file, convert to PDF-file (option -p), or catenate to stdout (option -o):
{
    file="$1"
    NUMBER="$2"
    if [ $format = "html_file" ]; then
        cat "$file" >| "$outputdir"/"$(date +"%Y%m%d_%H%M%S")_diff_$NUMBER.html"
    elif [ $format = "pdf_file" ]; then
        wkhtmltopdf "$file" "$outputdir"/"$(date +"%Y%m%d_%H%M%S")_diff_$NUMBER.pdf" 2>/dev/null
    elif [ $format = "html_stdout" ]; then
        cat "$file"   # Could be piped to e.g. 'bcat()' or any other "pipe2browser" program
    fi
}

rm_tempdir()
# Remove temporary directory:
{
    \rm -rf "$tempdir"
}


# MAIN FUNCTION:
# ==============

# Execute the options:
options "$@"
shift $(( OPTIND - 1 ))

[ $# -lt 2 ] && printf %s\\n "ERROR: Not enough arguments given" >&2 && exit 1

# Create directory for the temporary files:
if [ -d /tmp/ramdisk/ ]; then
    location="/tmp/ramdisk"
elif [ -d /dev/shm/ ]; then
    location="/dev/shm"
else
    location="."
fi
tempdir="$location/temp_$(date | tr ' ' '_')"
mkdir "$tempdir"

trap "rm_tempdir; exit 1" INT PIPE

# The HTML deletion- and insertion-tags:
delete_start="<span style=\"font-weight:bold;color:#$delhex;\">"
insert_start="<span style=\"font-weight:bold;color:#$inshex;\">"
end="</span>"

counter=0

if [ $args = "directories" ]; then

    # Check if given directories exist:
    ([ ! -d "$1" ] || [ ! -d "$2" ]) && printf %s\\n "ERROR: Specify existing directories." >&2 &&
    rm_tempdir && exit 1

    # Create the ./diff/-directory, unless it already exists:
    [ ! -d ./diff ] && mkdir ./diff
    outputdir="./diff"

    # Create a list of files and symlinks within either input directory:
    list1="$(find "$1" -maxdepth 1 -type f ; find "$1" -maxdepth 1 -type l)"
    list2="$(find "$2" -maxdepth 1 -type f ; find "$2" -maxdepth 1 -type l)"

    # Check on any unnumbered file names in either directory, and if so issue a warning:
    checknumberless "$1" 1
    checknumberless "$2" 2

    # Create a list with all <NUMBER> values for each of the two directories:
    numbers1="$(numberlist "$1")"
    numbers2="$(numberlist "$2")"

    # Check if the <NUMBER>-lists contain any repetitions, and if so issue a warning:
    checkrepeat "$numbers1" 1 2
    checkrepeat "$numbers2" 2 1

    # Determine the maximum <NUMBER> value appearing in any of the sorted lists:
    max1=$(printf "$numbers1" | awk '{ print $NF }')
    max2=$(printf "$numbers2" | awk '{ print $NF }')
    [ $max1 -gt $max2 ] && max=$max1 || max=$max2

    # While incrementing from 0 to max value, call makediff() function on each appropriate file pair:
    NUMBER=0
    while [ "$NUMBER" -le "$max" ]; do

        # Derive both file names from directory listings and <NUMBER>:
        if printf %s\\n "$numbers1" "$numbers2" | grep -q "\<$NUMBER\>"; then
            file1="$(printf "$list1" | grep -m 1 "\/"$NUMBER"_[^/]*$")"
            file2="$(printf "$list2" | grep -m 1 "\/"$NUMBER"_[^/]*$")"
        else
            NUMBER=$(( $NUMBER + 1 )) && continue
        fi

        # Issue warning and skip if <NUMBER> appears in one directory only, or file is not plain-text:
        if [ -z "$file1" ] || [ -z "$file2" ]; then
            if [ -n "$file1" ]; then
                printf %s\\n "WARNING: Number $NUMBER appears in directory 1 only, not in directory 2." >&2
            elif [ -n "$file2" ]; then
                printf %s\\n "WARNING: Number $NUMBER appears in directory 2 only, not in directory 1." >&2
            fi
            NUMBER=$(( $NUMBER + 1 )) && continue
        elif non_plain "$file1" "$file2"; then
            printf %s\\n "WARNING: Other than plain text in $1 and/or $2, skipping..." >&2
            NUMBER=$(( $NUMBER + 1 )) && continue
        fi

        # Prefix first (option -o) or each comparison (otherwise) by an html-intro including header:
        counter=$(( $counter + 1 ))
        ( if ([ $counter = 1 ] || [ $format != "html_stdout" ]); then
             print_html_intro "$file2"
        fi

        # Generate diff output:
        makediff "$file1" "$file2"

        # Postfix each comparison by a separation line (option -o) or html-coda (otherwise):
        if [ $format = "html_stdout" ]; then
            printf \\n%s\\n "<hr>"
        else
            printf %s\\n "$html_coda"
        fi ) |

       # Send comparison result to output:
        output - $NUMBER

        NUMBER=$(( $NUMBER + 1 ))
    done

    # Finish off with an html-coda (option -o) or a notification where to find results (otherwise):
    if [ $format = "html_stdout" ]; then
        printf %s\\n "$html_coda"
    else
        printf %s\\n "READY! - Please find all results in $(pwd)/diff/" >&2
    fi

else
    # In case of files instead of directories as arguments:
    if [ -f "$1" ] && [ -f "$2" ]; then
        print_html_intro "$2"
        makediff "$1" "$2"
        printf %s\\n "$html_coda"
    else
        printf %s\\n "ERROR: Specify existing files and no directories" >&2
        rm_tempdir
        exit 1
    fi | output -
fi

rm_tempdir
