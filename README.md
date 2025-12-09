# Name: worddiff.sh and worddiff2.sh
worddiff.sh  - compares two flat text-files word-by-word, and outputs a colored difference-file in html-format.

worddiff2.sh - does same for two directories containing multiple flat text-files, by comparing all shared pairs.

# Description:
worddiff.sh is a wrapper script around 'wdiff()' (see https://www.gnu.org/software/wdiff/).
It does a word-by-word comparison between two flat text files.
The result is stored into a color-marked difference-file in .html format.

This difference-file is a united version of the two input text files in the original text sequence.
Text fragments not common in both files (at the indicated position) are color-marked as follows:
- red text is present in the 1st file, and not present there in the 2nd file;
- green text is present in the 2nd file and not present there in the 1st file;
- black text (i.e. without color-marking) is present there in both files.

worddiff2.sh is similar to worddiff.sh, but does multiple comparing, as follows:
- it acts on two directories, by comparing each pair of equally numbered text-files in both directories;
- It stores all resulting files into a difference-directory;
- As an alternative for .html-output, it can also provide .pdf-output as an option.
Text-file names in the given directories must start with a number common to both directories,
followed by an underscore.

# How to use worddiff.sh and worddiff2.sh:
Usage:

	worddiff.sh  [OPTION]... FILE1 FILE2
	worddiff2.sh [OPTION]... DIR1  DIR2

Options:

	-h       Help (this output)
    -p       Output as .pdf- instead of .html-files (worddiff2.sh only)
	-w NUM   Wrap lines after each series of NUM words. NUM = 0 disables line-wrap.

# Author:
Written by Rob Toscani (rob_toscani@yahoo.com).
