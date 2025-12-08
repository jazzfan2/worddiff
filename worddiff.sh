#!/bin/bash
# Naam: worddiff.sh
# Bron: Rob Toscani
# Datum: 02-12-2025
# Dit programma doet een woord-voor-woord vergelijking in kleur tussen de
# twee opgegeven platte tekstbestanden.
# Het is een wrapper-script rondom 'wdiff', met uitvoer naar html.
# Van daaruit kan b.v. geprint worden naar PDF.
#
# Benodigde vooraf geïnstalleerde programma's:
# - wdiff
# - ansifilter
#
# Zie ook:
# https://unix.stackexchange.com/questions/25199/how-can-i-get-the-most-bang-for-my-buck-with-the-diff-command
#
#####################################################

# Standaard aantal woorden tot regelafbreking (default "geen" regel-afbreking):
wordcount=30000

options(){
# Specify options:
    while getopts "hw:" OPTION; do
        case $OPTION in
            h) helptext
               exit 0
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
Usage: worddiff.sh [-hw NUM] textfile1 textfile2

-h       Help (this output)
-w NUM   Wrap lines after each series of NUM words. NUM = 0 disables line-wrap.
EOF
}

# Voer de opties uit:
options $@
shift $(( OPTIND - 1 ))

# De kleuren-diff maken:
wdiff -w "$(tput bold;tput setaf 1)" -x "$(tput sgr0)" -y "$(tput bold;tput setaf 2)" -z "$(tput sgr0)" "$1" "$2" |

# En deze omzetten naar HTML-formaat:
ansifilter -H --encoding=utf8           |

# Alle eventuele niet-utf-8 karakters eruit verwijderen:
iconv -f utf-8 -t utf-8 -c              |

# Tijdelijk spatie verwijderen uit '<span style=xxx>'-tag (in verband met regel-afbreking):
sed 's/<span style=/<span_style=/g'     |

# Alle regels afbreken bij spatie of tab na elke serie woorden met aantal = 'wordcount'
# (Dit doet ansifilter helaas niet zelf, ook niet met optie -w !):
sed -E "s/(([^ 	]+[ 	]+){$wordcount})/\1\n/g" |

# Spatie in '<span style=xxx>'-tag weer terugbrengen, en resultaat wegschrijven naar .html-file:
sed 's/<span_style=/<span style=/g'    >| out.html


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