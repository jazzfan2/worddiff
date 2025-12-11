# Name: worddiff.sh
worddiff.sh  - compares pair(s) of flat text-files word-by-word, and stores color-marked results in HTML-format.

# Description:
worddiff.sh is a wrapper script around 'wdiff()' (see https://www.gnu.org/software/wdiff/).

It performs word-by-word comparison of one or multiple pair(s) of flat-text files.
Results are stored as color-marked difference-files in HTML format, or (if option -p is given) in PDF format.

A difference-file is a union of the two input text files, following the their combined text sequence.
Text present in both files is printed in black. (Series of) words not appearing in one of the two files
(at the indicated position) are color-marked as follows:
- red text is present in the 1st file, and not present (there) in the 2nd file;
- green text is present in the 2nd file and not present (there) in the 1st file;

With option -d, worddiff.sh acts on two directories instead of two text-files.
It then compares each text-file in the 1st directory to its associated text-file in the 2nd directory.
The resulting difference-files are collected in a difference-directory.

On order to correctly associate two files in either directory to each other, their respective file names must
start with same unique number, followed by an underscore.

# How to use worddiff.sh:
Usage:

	worddiff.sh   [-p]  FILE1       FILE2
	            -d[-p]  DIRECTORY1  DIRECTORY2

Options:

	-h       Help (this output)
	-d       Specify two directories as arguments instead of two text-files;
	         Compare each file in 1st directory to equally unique-numbered file in 2nd directory
    -p       Output as PDF- instead of HTML-files

# Author:
Written by Rob Toscani (rob_toscani@yahoo.com).
