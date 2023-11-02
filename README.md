# gitTools
Vim plugin to perform multiple git commands from within vim.

This plugin allows to perform multiple git commands from within vim and show the results.

You will be able to perferom the basic git commands like, checkout, commit, push, pull, merge, cherry-pick, show-ref, log, navigate through branches and display diffs and vimdiffs on changes.

This is a port of plugin svnTools, modified to use git instead of svn.

Use :Gith to view an abridged command help.

Use :Git to show the commands on menu to select and launch a commands non requiring arguments.
When using a parameter, search all commands and show matching strings.
By instance: :Git merge to show all commands matching merge screen

It is advisable to install hi.vim (https://www.vim.org/scripts/script.php?script_id=5887) to display results colorized.

Previously on https://www.vim.org/scripts/script.php?script_id=6013
