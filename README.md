# Name: worddiff.sh and worddiff.sh
worddiff.sh  - compares a two flat text-files word-by-word, and outputs a colored difference-file in html-format.

worddiff2.sh - does the same for two directories, by comparing all shared pairs of flat text files.

# Description:
worddiff.sh is a wrapper script around 'wdiff()'.
It does a word-by-word comparison between two flat text files.
The result is stored into a color-marked difference-file in .html format.

In this difference-file, the text is ONE combined version of the two input text files, preserving the original text sequences.
Color-marking is used for text fragments not common in both files AT THE INDICATED POSITION, as follows:
- RED text is PRESENT in the 1st file and ABSENT THERE in the 2nd file;
- GREEN text is ABSENT in the 1st file and PRESENT THERE in the 2nd file;
- BLACK text (i.e. without color-marking) is PRESENT THERE in both files.

worddiff2.sh is similar to worddiff.sh, with following difference:
- It acts on two DIRECTORIES of text files, by comparing each pair of corresponding text files common to both directories;
- It creates/updates a './diff/' directory containing difference-files for each pair of compared text files;
- As an alternative for .html-output, it can also provide .pdf-output as an option.

# How to use worddiff.sh and worddiff.sh:
Usage:

	worddiff.sh   <text_file1> <text_file1>
	worddiff2.sh  <path_to_directory1> <path_to_directory2>

Options:

	-h       Help (this output)
    -p       Output as .pdf- instead of .html-files (worddiff2.sh only)
	-w NUM   Wrap lines after each series of NUM words. NUM = 0 disables line-wrap.

# Author:
Written by Rob Toscani (rob_toscani@yahoo.com).
