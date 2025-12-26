# Name: wordif.sh
wordif.sh  - compares plain-text-files word-by-word, and stores color-marked results in HTML-format.

# Name: wdiffer.py
wdiffer.py - private version of wdiff() as a Python3 script, mimicking the UNIX wdiff() utility.

# Name: wdiffer.sh
wdiffer.sh - private version of wdiff() as a Bash/GAWK script, mimicking the UNIX wdiff() utility.

# Description:
'wordif.sh' is a wrapper script around 'wdiff()' (see: https://www.gnu.org/software/wdiff/).

It performs word-by-word comparison of one or multiple pair(s) of plain-text-files.
Results are stored as color-marked difference-files in HTML-format, or in PDF-format if option -p is given.

A difference-file is a unification of the two input text-files, preserving original text sequence.
Text present in both files is printed in black. (Groups of) words locally missing in one of the two files
are color-marked as follows:
- red text is present in the 1st file, and not present (there) in the 2nd file;
- green text is present in the 2nd file and not present (there) in the 1st file;

With option -d, wordif.sh acts on two directories instead of two text-files.
It then compares each text-file in the 1st directory to its associated text-file in the 2nd directory.
The resulting difference-files are collected in a difference-directory.

To correctly associate two files in either directory to each other, their respective file names must
start with same unique number, followed by an underscore.

'wdiffer.py' is a private version of wdiff() that is run as a Python3 script, mimicking the UNIX wdiff() utility.
It can be called by wordif.sh as an alternative for wdiff() in case the latter is not available for installation.

'wdiffer.sh' is a Bash/GAWK equivalent of 'wdiffer.py'.

Both have been developed as a fun project, in an effort to achieve a 'self-supporting' version of wordif.sh.
A wdiffer-version in C is being considered as well.

Options for both 'wdiffer.py' and 'wdiffer.sh' are limited to -h, -w, -x, -y and -z as of now.


# How to use wordif.sh:
Usage:

	wordif.sh   [-p]  FILE1       FILE2
	          -d[-p]  DIRECTORY1  DIRECTORY2

Options:

	-h       Help (this output)
	-d       Specify two directories as arguments instead of two text-files;
	         Compare each file in 1st directory to equally unique-numbered file in 2nd directory
    -p       Output as PDF- instead of HTML-files

# How to use wdiffer.py and wdiffer.sh:
Usage:

	wdiffer.py   [OPTIONS]  FILE1       FILE2
	wdiffer.sh   [OPTIONS]  FILE1       FILE2

Options:

    -h         Help (this output)
    -w STRING  String to mark beginning of delete region
    -x STRING  String to mark end of delete region
    -y STRING  String to mark beginning of insert region
    -z STRING  String to mark end of insert region


# Author:
wordif.sh, wdiffer.py and wdiffer.sh have been written by Rob Toscani (rob_toscani@yahoo.com).
If you find any bugs or want to comment otherwise, please let me know.
