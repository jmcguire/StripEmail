## Turn a regular text file into a the type of test file we expect.

## After this runs, edit the part below "EXPECTEDRESULTS" and delete the lines
## that you think shouldn't be there.

perl -i -pe'BEGIN{undef $/} print; print "###EXPECTEDRESULT###\n"' $*
