# gitTools
Vim plugin to perform multiple git commands from within vim.

This plugin allows to perform multiple git commands from within vim and show the results.

You will be able to perferom the basic git commands like, checkout, commit, push, pull, merge, cherry-pick, show-ref, log, navigate through branches and display diffs and vimdiffs on changes.

This is a port of plugin svnTools, modified to use git instead of svn.

Use ":Gith" to show an abridged command help.

Use ":Git" without arguments, to open a menu window displaying all commands.

Use ":Git PATTERN1 PATTERN2", with arguments, to show the commands matching the selected patterns.

Then you can select on the menu window the command you want to launch..

For instance:

- ":Git merge" to show all commands and descriptions matching "merge".

- ":Git commit" to show all commands and descriptions matching "commit".

- ":Git branch merge" to show all commands and descriptions matching "branch" and "merge".

- ":Git" show all commands.

It is advisable to install hi.vim (https://github.com/javipv/hi.vim) to display results colorized.

Previously on https://www.vim.org/scripts/script.php?script_id=6013
