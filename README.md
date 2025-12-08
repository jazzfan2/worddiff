# Name: worddiff.sh
worddiff.sh - compares two flat text files word-for-word, and produces a colored diff-file in .html format.

# Description:
worddiff.sh is a wrapper script around 'wdiff()'.
It does a word-for-word comparison between two flat text files.
The resulting colored diff-file is stored into a .html file.

In this file, the text is ONE combined version of the two input text files, preserving the original text sequence,
in which color-marking is used for text fragments not common in both files, as follows:
- RED text is PRESENT in the 1st file and ABSENT in the 2nd file;
- GREEN text is ABSENT in the 1st file and PRESENT in the 2nd file;
- BLACK text (i.e. without color-marking) is PRESENTin both files.

# How to use worddiff.sh:
Usage:

	worddiff.sh  <text_file1> <text_file1>

Options:

	-h     Help (this output)
	-w     Wrap lines after each series of NUM words. NUM = 0 disables line-wrap.

# Author:
Written by Rob Toscani (rob_toscani@yahoo.com).
