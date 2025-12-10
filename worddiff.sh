#!/bin/bash
# Naam: worddiff.sh
# Bron: Rob Toscani
# Datum: 08-12-2025
# Dit programma doet een woord-voor-woord vergelijking in kleur tussen de twee
# opgegeven platte tekstbestanden.
# Het is een wrapper-script rondom 'wdiff' (https://www.gnu.org/software/wdiff/),
# met uitvoer naar html. Van daaruit kan b.v. geprint worden naar PDF.
#
# Benodigd vooraf geïnstalleerd programma:
# - wdiff
# - wkhtmltopdf (in geval dat output naar pdf-formaat gewenst is)
#
################################################################################

# Standaard output-formaat:
format="html"

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
Usage: worddiff.sh [-hp] textfile1 textfile2

-h       Help (this output)
-p       Output as .pdf- instead of .html-file
EOF
}

store2file()
# Html-tekst wegschrijven naar (.html-)file, of (in geval van optie -p) omzetten naar pdf-file:
{
    if [[ $format == "html" ]]; then
        cat "$1" >| out.html
    else
        wkhtmltopdf "$1" out.pdf 2>/dev/null
    fi
}


# Voer de opties uit:
options $@
shift $(( OPTIND - 1 ))

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
<title>$2</title>
</head>
<body>
<pre>"

html_coda="
</pre>
</body>
</html>"

delete_start="<span style=\"font-weight:bold;color:#ff0000;\">"
insert_start="<span style=\"font-weight:bold;color:#00ff00;\">"
end="</span>"

# De kleur-gemarkeerde difference-file maken:
wdiff -w "$delete_start" -x "$end" -y "$insert_start" -z "$end" "$1" "$2" |

# En wegschrijven naar het gewenste formaat (default .html):
cat <(echo "$html_intro") - <(echo "$html_coda") | store2file -


#####################################################################################
#
# Copyright (C) 2025 Rob Toscani <rob_toscani@yahoo.com>
#
# worddiff.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# worddiff.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################