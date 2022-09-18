

# Table of Contents

1.  [Repository containing files for modifying xopp files.](#orgdfa9662)
    1.  [git-xopp.sh - script for using git with xournalpp.](#org86affb0)
    2.  [change_page_no.bash - Script for transferring annotations in xournalpp.](#org0889d1d)
        1.  [Mindmap <code>[2/5]</code>](#org76b2a1a)



<a id="orgdfa9662"></a>

# Repository containing files for modifying xopp files.


<a id="org86affb0"></a>

## DONE git-xopp.sh - script for using git with xournalpp.


<a id="org0889d1d"></a>

## TODO change_page_no.bash - Script for transferring annotations in xournalpp.

-   Note taken on <span class="timestamp-wrapper"><span class="timestamp">[2022-09-18 Sun 23:32] </span></span>   
    If new pages are added to PDF before the page annotated in xournalpp, this creates discrepancy as the pages in pdf increase and the annotations remain on the original page no so they do not correspond to new pages. This script can change page no of the page containing annotation and of subsequent pages.


<a id="org76b2a1a"></a>

### TODO Mindmap <code>[2/5]</code>

1.  CANCELED <del>Add entry for pg no 103-106 before pg entry 103.</del>

    -   State "CANCELED"       from "TODO"       <span class="timestamp-wrapper"><span class="timestamp">[2022-09-18 Sun 23:34] </span></span>   
        Not to be done as there will be two entry for same page.

2.  DONE check the last pg no in the file i.e. pg 498 save it as a variable;

    -   State "DONE"       from "TODO"   <span class="timestamp-wrapper"><span class="timestamp">[2022-09-18 Sun 23:36]</span></span>

3.  TODO Obstacles: <code>[2/3]</code>

    -   [X] start changing pg entry 103 to 104 and then do likewise with all subsequent page entries till last page (pg no 498).
        -   a problem arises as now pg 103 is there twice and both will be changed.
    -   [X] Append a text sequence to differentiate from previous page entries.
        -   But how to account for missisng pages?
    -   [ ] Break the file in two, a line before the **from** page no and add missing pages to file no 1, and join the two files later on.

4.  TODO Check if everything works and add exit codes and ability to make backups.

5.  TODO In case new page no is less than original page no delete pages in the middle first, otherwise there will be 2 pages with the same page.

