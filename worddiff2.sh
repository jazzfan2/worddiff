#!/bin/bash
# Naam: worddiff2.sh
# Bron: Rob Toscani
# Datum: 08-12-2025
# Dit programma doet een woord-voor-woord vergelijking in kleur tussen de
# genummerde platte tekstbestanden in de 1ste opgegeven directory en die
# in de 2de opgegeven directory.
# Het is een wrapper-script rondom 'wdiff' (https://www.gnu.org/software/wdiff/),
# met uitvoer naar html- of optioneel naar pdf-formaat.

# Het nummer in de bestandsnaam bepaalt welke bestanden onderling worden
# vergeleken. De resultaten worden weggeschreven naar kleur-gemarkeerde
# verschil-bestanden in .html- of (optioneel) .pdf-formaat, verzameld in
# directory ./diff/.
#
# Vooraf moeten de volgende programma's op het systeem zijn geïnstalleerd:
# - wdiff
# - wkhtmltopdf (indien optie -p gewenst is)
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

# Stel html als output-formaat in:
format="html"

# De kleurmarkeringen:
delete_start="<span style=\"font-weight:bold;color:#ff0000;\">"
insert_start="<span style=\"font-weight:bold;color:#00ff00;\">"
end="</span>"

# De html-tags die voor en achter de tekst worden geplakt:
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

# Escape < and > in case literal html-tags appear in the text:
regex="s/</\&lt;/g; s/>/\&gt;/g" 


# De functies:
# ============

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
# Een (horizontale) lijst printen van nummers waarmee de bestanden in de gegeven map beginnen:
{
    ls "$1"           |
    grep -oE ^[0-9]+_ |
    tr '_' ' '        |
    sort -n           |
    tr -d '\n'        |
    sed 's/ $//'
}

checkrepeat()
# Eventuele herhalingen in een gesorteerde nummerlijst signaleren en hiervan een melding maken:
{
    repeatnum="$(grep -oE "(\<[0-9]+\>) \1" <<< "$1")"
    if [[ -n "$repeatnum" ]]; then
        qty=$(wc -w <<< "$repeatnum")
        num=${repeatnum/ */}
        echo "Waarschuwing: nummer $num KOMT $qty KEER voor in bestandsnamen in de $2."
        echo "SLECHTS ÉÉN BESTAND met $num is vergeleken met een (MOGELIJK VERKEERD) bestand in de $3"
    fi
}

makediff()
# Alle genummerde tekstbestanden in <MAP1> met die in <MAP2> vergelijken en de output opslaan:
{
    NUMMER=$1
    file1="$(ls $2/$NUMMER"_"* 2>/dev/null | head -n 1)"
    file2="$(ls $3/$NUMMER"_"* 2>/dev/null | head -n 1)"

    # Niets doen als een nummer niet voorkomt, met waarschuwing als dat in 1 van de 2 directories is:
    if ([[ -z "$file1" ]] || [[ -z "$file2" ]]); then
        if [[ -n "$file1" ]]; then
            echo "Waarschuwing: nummer $NUMMER KOMT WEL voor in de 1e map, MAAR NIET in de 2e map."
        elif [[ -n "$file2" ]]; then
            echo "Waarschuwing: nummer $NUMMER KOMT WEL voor in de 2e map, MAAR NIET in de 1e map."
        fi
        return
    fi

    # De kleur-gemarkeerde difference-file maken:
    wdiff -w "$delete_start" -x "$end" -y "$insert_start" -z "$end" \
              <(sed "$regex" "$file1") <(sed "$regex" "$file2") |

    # En wegschrijven naar het gewenste formaat (default .html):
    cat <(echo "$html_intro") - <(echo "$html_coda") | store2file - $NUMMER
}

store2file()
# Html-tekst wegschrijven naar (html-)file, of (in geval van optie -p) omzetten naar pdf-file:
{
    file="$1"
    NUMMER="$2"
    if [[ $format == "html" ]]; then
        cat "$file" >| ./diff/"$(date +"%Y%m%d_%H%M")_diff_$NUMMER.html"
    else
        wkhtmltopdf "$file" ./diff/"$(date +"%Y%m%d_%H%M")_diff_$NUMMER.pdf" 2>/dev/null
    fi
}


# De main-functie:
# ================

# Voer de opties uit:
options $@
shift $(( OPTIND - 1 ))

# Check of de twee opgegeven mappen bestaan:
([[ ! -d "$1" ]] || [[ ! -d "$2" ]]) && echo "Geef bestaande mappen op." && exit 1

# Maak de ./diff/-directory aan, tenzij deze al bestaat:
[[ ! -d ./diff ]] && mkdir ./diff

# Maak twee lijsten: een met alle waarden van <NUMMER> in <MAP1> en een met alle in <MAP2>:
list1="$(numberlist "$1")"
list2="$(numberlist "$2")"

# Check of de <NUMMER>-lijsten herhalingen bevatten en zo ja geef hiervan een melding:
checkrepeat "$list1" "1e map" "2e map"
checkrepeat "$list2" "2e map" "1e map"

# Stel vast wat de maximaal voorkomende waarde van <NUMMER> is in beide gesorteerde lijsten:
max1=${list1/* /}
max2=${list2/* /}
(( max1 > max2 )) && max=$max1 || max=$max2

# Doorloop alle waarden van <NUMMER> en roep per waarde de functie makediff() aan:
NUMMER=0
while (( NUMMER <= max )); do
    makediff $NUMMER "$1" "$2"
    (( NUMMER += 1 ))
done

# Afsluiting:
echo "Klaar! - De verschilbestanden zijn verzameld in $(pwd)/diff/"
