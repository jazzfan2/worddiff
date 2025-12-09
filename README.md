# Name: worddiff.sh and worddiff2.sh
worddiff.sh  - compares two flat text-files word-by-word, and outputs a colored difference-file in html-format.

worddiff2.sh - does same for two directories containing multiple flat text-files, by comparing all shared pairs.

# Description:
worddiff.sh is a wrapper script around 'wdiff()' (see https://www.gnu.org/software/wdiff/).
It does a word-by-word comparison between two flat text files.
The result is stored into a color-marked difference-file in .html format.

This difference-file is a UNITED version of the two input text files, with preserved original text sequence.
Color-marking is used to indicate text fragments not common in both files AT THE INDICATED POSITION, as follows:
- RED text is PRESENT in the 1st file and ABSENT THERE in the 2nd file;
- GREEN text is PRESENT in the 2nd file and ABSENT THERE in the 1st file;
- BLACK text (i.e. without color-marking) is PRESENT THERE in both files.

worddiff2.sh is similar to worddiff.sh, but does MULTIPLE comparing, as follows:
- It acts on two DIRECTORIES, by comparing each pair of equally numbered text-files in both directories;
- It stores all resulting files into a difference-directory;
- As an alternative for .html-output, it can also provide .pdf-output as an option.

# How to use worddiff.sh and worddiff2.sh:
Usage:

	worddiff.sh   <text-file1> <text-file2>
	worddiff2.sh  <path_to_directory1> <path_to_directory2>

Options:

	-h       Help (this output)
    -p       Output as .pdf- instead of .html-files (worddiff2.sh only)
	-w NUM   Wrap lines after each series of NUM words. NUM = 0 disables line-wrap.

# Author:
Written by Rob Toscani (rob_toscani@yahoo.com).
