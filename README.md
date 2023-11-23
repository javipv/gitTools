# gitTools

Previously at [vim.org/gitTools](https://www.vim.org/scripts/script.php?script_id=6013)

Vim plugin to perform multiple git commands from within vim.

This plugin allows to perform multiple git commands from within vim and show the results.

You will be able to perform the basic git commands like, checkout, commit, push, pull, merge, cherry-pick, show-ref, log, navigate through branches and display diffs and vimdiffs on changes.

It is advisable to install [hi.vim](https://github.com/javipv/hi.vim) plugin to display results colorized.

This is a port of plugin svnTools, modified to use git instead of svn.


## Abridged command help:

Use ":Gith" to show an abridged help, displaying the last set of commands available.

![Gith](Gith.png?raw=true ":Gith")


## Command search and launcher:

Use ":Git" without arguments, to open a menu window displaying all commands.

Use ":Git PATTERN1 PATTERN2", with arguments, to show the commands matching the selected patterns.

Then you can select on the menu window the command you want to launch..

For instance:
```vimscript

" Show all commands and descriptions matching "merge".
:Git merge

" Show all commands and descriptions matching "commit".
:Git commit

" Show all commands and descriptions matching "branch" and "merge".
:Git branch merge

" Show all commands.
:Git
```

## Usage simple example:

Do some changes on several files.

### Checkk Git status (Gitst or Gitsta), and perform Gita on the files not staged:

![Gitsta](Gitsta.png?raw=true ":Gitsta")

### Use Gitcm to open the commit message window (left) and modifications window (right):

![Gitcm](Gitcm.png?raw=true ":Gitcm")

### Use Gitcm again to perform de commit:

![Gitcm done](Gitcm_done.png?raw=true ":Git done")

### Use Gitpush to push changes to remote:

![Gitpush](Gitpush.png?raw=true ":Gitpush")

### Use Gitbl to check the blame:

![Gitbl](Gitbl.png?raw=true ":Gitbl")


### Once the cursor is position on the desired line, use Gitr to check the hash's commit changes:

![Gitr](Gitr.png?raw=true ":Gitr")


### Use Gitrl to check the reference log:

![Gitrl](Gitr.png?raw=true ":Gitrl")


