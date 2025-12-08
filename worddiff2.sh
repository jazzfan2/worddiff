#!/bin/bash
# Naam: worddiff2.sh
# Bron: Rob Toscani
# Datum: 08-12-2025
# Dit programma doet een woord-voor-woord vergelijking in kleur tussen de
# genummerde platte tekstbestanden in de 1ste opgegeven directory en die
# in de 2de opgegeven directory. Het is een wrapper-script rondom 'wdiff'.
#
# Het nummer in de bestandsnaam bepaalt welke bestanden onderling worden
# vergeleken. De resultaten worden weggeschreven naar kleur-gemarkeerde
# verschil-bestanden in .html- of (optioneel) .pdf-formaat, verzameld in
# directory ./diff/.
#
# Vooraf moeten de volgende programma's op het systeem zijn geïnstalleerd:
# - wdiff
# - ansifilter
# - wkhtmltopdf (indien optie -p gewenst is)
# Zie ook:
# https://unix.stackexchange.com/questions/25199/how-can-i-get-the-most-bang-for-my-buck-with-the-diff-command
#
#######################################################
#
#
# HOE DIT PROGRAMMA TE GEBRUIKEN:
#
# 1. Voorbereiding:
# =================
#
# Maak van te voren twee mappen onder de projectmap aan, hier verder aangeduid
# als <MAP1> en <MAP2>.
#
# Als "oude" met "nieuwe" teksten moeten worden vergeleken, dan kan de naam
# van <MAP1> bijvoorbeeld zijn 'oud', en die van <MAP2> 'nieuw'.
#
# Leid nu platte tekstbestanden af van de te vergelijken bronteksten, bij
# voorkeur één bestand per hoofdstuk of artikel.
#
# B.v. tekst van een InDesign-artikel selecteren met 'Ctrl-A', kopiëren met
# 'Ctrl-C' en in een platte editor plakken met 'Ctrl-V'.
#
# Sla deze platte tekstbestanden zodanig op in <MAP1> en <MAP2> dat voor elk bestand
# in <MAP1> er een daarmee te vergelijken bestand bestaat in <MAP2>.
#
# Om twee bestanden in verschillende mappen aan elkaar te kunnen relateren moeten
# hun bestandsnamen beginnen met hetzelfde <NUMMER> gevolgd door een <UNDERSCORE>,
# eventueel gevolgd door een vrij te kiezen gedeelte (dat onderling verschillend
# mag zijn).
#
# Als b.v. in <MAP1> (b.v. genaamd "oud") de volgende bestanden zijn weggeschreven:
# - "1_voorwoord.txt"
# - "2_highlights.txt"
# - "3_tips.txt"
#
# En in <MAP2> (b.v. genaamd "nieuw") de volgende bestanden:
# - "1_inleiding.txt"
# - "2_highlights.txt"
# - "3_tips&tricks.txt"
#
# Dan zal programma de tekstbestanden in <MAP1> met die in <MAP2> vergelijken
# waarvan de naam met hetzelfde <NUMMER> begint.
#
# Dus hier:
#    "1_voorwoord.txt"   met  "1_inleiding.txt"
#    "2_highlights.txt"  met  "2_highlights.txt"
#    "3_tips.txt"        met  "3_tips&tricks.txt"
#
# Let op:
# - Het aantal genummerde bestanden in <MAP1> moet gelijk zijn aan dat in <MAP2>.
# - Per map mag elke waarde van <NUMMER> maar één keer voorkomen.
# - In bestandsnamen mogen na de "_" spaties voorkomen, maar vermijd het bij voorkeur.
#
#
# 2. Werking van het programma:
# =============================
#
# Om het programma te starten, typ in een terminal het volgende commando in,
# en druk daarna op <ENTER>:
#
#     worddiff2.sh <bestandspad_naar_MAP1> <bestandspad_naar_MAP2>
#
# Als <MAP1> overeenkomt met "oud", dan wordt deze dus als eerste opgegeven.
#
# Met optie -w (gevolgd door aantal woorden per regel) kan de regel-afbreking
# in de te leveren output worden beïnvloed.
#
# Het programma werkt nu één-voor-één alle paren van tekstbestanden in genoemde
# mappen af en genereert hieruit verschil-bestanden.
#
# Deze worden elk als apart .html-bestand in de map './diff/' geplaatst, met als
# bestandsnaam: "<DATUM>_<TIJD>_diff_<NUMMER>.html".
#
# Het <NUMMER> komt overeen met het <NUMMER> in de namen van de vergeleken
# tekstbestanden.
#
# Indien het programma doublures en/of ontbrekende waarden van <NUMMER> tegenkomt,
# geeft het daarvan waarschuwingen in de terminal, maar vervolgt wel zo goed
# mogelijk zijn taak.
#
# Zodra het programma klaar is, geeft het hiervan een melding in dezelfde terminal.
#
# In elk van de resulterende .html-bestanden in de map './diff/' is:
# - Zwarte tekst: WEL aanwezig in BEIDE vergeleken tekstbestanden in <MAP1> en <MAP2>
#
# - Rode tekst:   WEL aanwezig in het tekstbestand in <MAP1> ("oud");
#                 NIET in het vergeleken tekstbestand in <MAP2> ("nieuw")
#
# - Groene tekst: NIET aanwezig in het tekstbestand in <MAP1> ("oud");
#                 WEL in het vergeleken tekstbestand in <MAP2> ("nieuw")
#
# Vanuit elk van deze html-bestanden kan b.v. geprint worden naar pdf.
# Optie -p resulteert rechtstreeks in een (reeks) .pdf-bestand(en).
#
#
#######################################################

# Standaard aantal woorden tot regel-afbreking:
wordcount=10

# Standaard output-formaat:
format="html"

options(){
# Specify options:
    while getopts "hpw:" OPTION; do
        case $OPTION in
            h) helptext
               exit 0
               ;;
            p) format="pdf"
               ;;
            w) if grep -q [^0-9] <<< "$OPTARG"; then
                   echo "Invalid option argument to -w"
                   exit 1
               fi
               (( OPTARG > 0 )) && wordcount=$OPTARG || wordcount=30000
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
Usage: worddiff2.sh [-hpw NUM] directory1 directory2

-h       Help (this output)
-p       Output as .pdf- instead of .html-files
-w NUM   Wrap lines after each series of NUM words instead of 10. NUM = 0 disables line-wrap.
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

    # De kleuren-diff maken:
    wdiff -w "$(tput bold;tput setaf 1)" -x "$(tput sgr0)" -y "$(tput bold;tput setaf 2)" -z "$(tput sgr0)" \
    "$file1" "$file2"           |

    # En deze omzetten naar HTML-formaat:
    ansifilter -H --encoding=utf8           |

    # Alle eventuele niet-utf-8 karakters eruit verwijderen:
    iconv -f utf-8 -t utf-8 -c              |

    # Tijdelijk spatie verwijderen uit '<span style=xxx>'-tag (i.v.m regel-afbreking):
    sed 's/<span style=/<span_style=/g'     |

    # Alle regels afbreken bij spatie of tab na elke serie woorden met aantal = 'wordcount'
    # (Dit doet ansifilter helaas niet zelf, ook niet met optie -w !):
    sed -E "s/(([^ 	]+[ 	]+){$wordcount})/\1\n/g" |

    # Spatie in '<span style=xxx>'-tag herstellen, en output wegschrijven naar gewenst formaat:
    sed 's/<span_style=/<span style=/g'    | store2file - $NUMMER
}

store2file()
# Html-tekst wegschrijven naar (.html-)file, of (in geval van optie -p) omzetten naar pdf-file:
{
    file="$1"
    NUMMER="$2"
    if [[ $format == "html" ]]; then
        cat "$file" >| ./diff/"$(date +"%Y%m%d_%H%M")_diff_$NUMMER.html"
    else
        wkhtmltopdf "$file" ./diff/"$(date +"%Y%m%d_%H%M")_diff_$NUMMER.pdf" 2>/dev/null
    fi
}


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
