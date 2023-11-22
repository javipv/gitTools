" Script Name: gitTools/help.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"

"- Help functions -----------------------------------------------------------

function! gitTools#help#MergeLayoutHelp()
    let text =  "[GitTools.vim] merge help (v".g:gitTools_version."):\n"
    let text .= "\n"
    let text .= "Merge layouts:  ".g:gitTools_mergeLayouts.".\n"
    let text .= "Default layout: ".g:gitTools_dfltMergeLayout.".\n"
    let text .= "\n"
    let text .= "Layout 1:\n"
    let text .= "----------\n"
    let text .= "|        |\n"
    let text .= "| MERGED |\n"
    let text .= "|        |\n"
    let text .= "----------\n"
    let text .= "\n"
    let text .= "Layout 2 or 2A:\n"
    let text .= "-------------------\n"
    let text .= "|        |        |\n"
    let text .= "| LOCAL  | MERGED |\n"
    let text .= "|        |        |\n"
    let text .= "-------------------\n"
    let text .= "Layout 2B:\n"
    let text .= "-------------------\n"
    let text .= "|        |        |\n"
    let text .= "| MERGED | REMOTE |\n"
    let text .= "|        |        |\n"
    let text .= "-------------------\n"
    let text .= "\n"
    let text .= "Layout 3 or 3A:\n"
    let text .= "----------------------------\n"
    let text .= "|       |         |        |\n"
    let text .= "| LOCAL | MERGED  | REMOTE |\n"
    let text .= "|       |         |        |\n"
    let text .= "----------------------------\n"
    let text .= "\n"
    let text .= "Layout 3B:\n"
    let text .= "------------------\n"
    let text .= "|       |        |\n"
    let text .= "| LOCAL | REMOTE |\n"
    let text .= "|       |        |\n"
    let text .= "------------------\n"
    let text .= "|     MERGED     |\n"
    let text .= "------------------\n"
    let text .= "\n"
    let text .= "Layout 4:\n"
    let text .= "-------------------------\n"
    let text .= "|      |       |        |\n"
    let text .= "| BASE | LOCAL | REMOTE |\n"
    let text .= "|      |       |        |\n"
    let text .= "-------------------------\n"
    let text .= "|        MERGED         |\n"
    let text .= "-------------------------\n"
    let text .= "\n"

    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()
    setl nowrap
    set buflisted
    set bufhidden=delete
    set buftype=nofile
    setl noswapfile
    silent put = l:text
    silent! exec '0file | file gitTools_plugin_svn_merge_layout_help'
    normal ggdd
endfunction


function! gitTools#help#StatusHelp()
    let text =  "[GitTools.vim] help (v".g:gitTools_version."):\n"
    let text .= "\n"
    let text .= "Git status help:\n"
    let text .= "\n"
    let text .= "Symbols:\n"
    let text .= "    ' ' = unmodified\n"
    let text .= "    M = modified\n"
    let text .= "    T = file type changed (regular file, symbolic link or submodule)\n"
    let text .= "    A = added\n"
    let text .= "    D = deleted\n"
    let text .= "    R = renamed\n"
    let text .= "    C = copied (if config option status.renames is set to \"copies\")\n"
    let text .= "    U = updated but unmerged\n"
    let text .= "\n"
    let text .= "Table of states:\n"
    let text .= "   X          Y     Meaning\n"
    let text .= "   -------------------------------------------------\n"
    let text .= "            [AMD]   not updated\n"
    let text .= "   M        [ MTD]  updated in index\n"
    let text .= "   T        [ MTD]  type changed in index\n"
    let text .= "   A        [ MTD]  added to index\n"
    let text .= "   D                deleted from index\n"
    let text .= "   R        [ MTD]  renamed in index\n"
    let text .= "   C        [ MTD]  copied in index\n"
    let text .= "   [MTARC]          index and work tree matches\n"
    let text .= "   [ MTARC]    M    work tree changed since index\n"
    let text .= "   [ MTARC]    T    type changed in work tree since index\n"
    let text .= "   [ MTARC]    D    deleted in work tree\n"
    let text .= "               R    renamed in work tree\n"
    let text .= "               C    copied in work tree\n"
    let text .= "   -------------------------------------------------\n"
    let text .= "   D           D    unmerged, both deleted\n"
    let text .= "   A           U    unmerged, added by us\n"
    let text .= "   U           D    unmerged, deleted by them\n"
    let text .= "   U           A    unmerged, added by them\n"
    let text .= "   D           U    unmerged, deleted by us\n"
    let text .= "   A           A    unmerged, both added\n"
    let text .= "   U           U    unmerged, both modified\n"
    let text .= "   -------------------------------------------------\n"
    let text .= "   ?           ?    untracked\n"
    let text .= "   !           !    ignored\n"
    let text .= "   -------------------------------------------------\n"

    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()
    setl nowrap
    set buflisted
    set bufhidden=delete
    set buftype=nofile
    setl noswapfile
    silent put = l:text
    silent! exec '0file | file gitTools.vim_git_status_help'
    normal ggdd
endfunction


function! gitTools#help#Help()
    if g:gitTools_runInBackground == 1
        let l:job = "foreground"
    else
        let l:job = "background"
    endif

    let l:list = ["[gitTools.vim] help (v".g:gitTools_version."):"]
    let l:text = gitTools#tools#EncloseOnRectangle(l:list, "bold", "")
    let l:text .= "\n"
    let l:text .= "Abridged command help:\n"
    let l:text .= "\n"
    let l:text .= "    :Git [filter]         : menu to select and launch a command.\n"
    let l:text .= "\n"
    let l:text .= "- Info:\n"
    let l:text .= "    :Giti                 : get current revision info.\n"
    let l:text .= "\n"
    let l:text .= "- Branch:\n"
    let l:text .= "    :Gitb                 : show branch info.\n"
    let l:text .= "    :Gitbv                : show branch verbose info.\n"
    let l:text .= "    :Gitbd                : delete branch.\n"
    let l:text .= "    :Gitbmv               : rename branch.\n"
    let l:text .= "    :Gitbc                : show config of current branch.\n"
    let l:text .= "    :Gitsw                : switch branch.\n"
    let l:text .= "\n"
    let l:text .= "- Blame:\n"
    let l:text .= "    :Gitbl                : get blame of current file.\n"
    let l:text .= "\n"
    let l:text .= "- Status: show status screen\n"
    let l:text .= "    :Gitst                : show file's status (conceal symbols: X and ?).\n"
    let l:text .= "    :Gitsta               : show status files (show all symbols).\n"
    let l:text .= "    :Gitstf               : show current file status.\n"
    let l:text .= "    :Gitstd               : show current directory status.\n"
    let l:text .= "\n"
    let l:text .= "- Short Status:\n"
    let l:text .= "    :GitSt                : show file's status (conceal symbols: X and ?).\n"
    let l:text .= "    :GitSta               : show status files (show all symbols).\n"
    let l:text .= "    :GitStf               : show current file status.\n"
    let l:text .= "    :GitStd               : show current directory status.\n"
    let l:text .= "    :GitSth               : show the git status symbols' help.\n"
    let l:text .= "\n"
    let l:text .= "- Status commands:\n"
    let l:text .= "  Can be lanuched from within status screen when cursor placed on git file or directory.\n"
    let l:text .= "    :Gita  [FILEPATH]     : add file to git stage.\n"
    let l:text .= "    :Gitu  [FILEPATH]     : unstage file.\n"
    let l:text .= "    :GitR  [FILEPATH]     : restore file.\n"
    let l:text .= "    :Gitrm [FILEPATH]     : remove file/dir from repository.\n"
    let l:text .= "    :Gitmv [FILEPATH]     : move file/dir path.\n"
    let l:text .= "    :GitRM [FILEPATH]     : Remove from disk.\n"
    let l:text .= "\n"
    let l:text .= "- Log:\n"
    let l:text .= "    :Gitl [OPTIONS]       : show git log.\n"
    let l:text .= "    :Gitlo                : show git log with options oneline and decorate full.\n"
    let l:text .= "    :Gitlf                : show git log for current file.\n"
    let l:text .= "    :Gitlfd               : show git log and diff for current file.\n"
    let l:text .= "    :Gitlp                : show git log and patch for the last 10 commits.\n"
    let l:text .= "    :Gitla AUTHOR         : show git log from author.\n"
    let l:text .= "    :Gitls STRING         : show git log changing string.\n"
    let l:text .= "    :GitlS PATTERN [OPT]  : show git log entries matching search pattern.\n"
    let l:text .= "    :Gitlg [OPTIONS]      : show git log graph.\n"
    let l:text .= "    :Gitlgo               : show git log graph, with options and decorate oneline.\n"
    let l:text .= "    :Gitrl                : show git reference log.\n"
    let l:text .= "    :GitL [FUNCNAME] [FILE] : search function name changes history.\n"
    "let l:text .= "    :Gitlr [NUM]          : show git log for the required commit.\n"
    "let l:text .= "    :Gitlf FILEPATH       : show file log.\n"
    "let l:text .= "    :Gitlr [NUM]          : when placed on a git log file, get the log and diff of each revison.\n"
    "let l:text .= "                           NUM: given a number, only first number of changes will be get.\n"
    let l:text .= "\n"
    let l:text .= "- Grep:\n"
    let l:text .= "    :Gitg [PATTERN]       : print repository lines matching the pattern.\n"
    let l:text .= "\n"
    let l:text .= "- Show-ref:\n"
    let l:text .= "    :Gitsr ARGS           : call git show-ref ARGS.\n"
    let l:text .= "    :Gitsrt               : call git show-ref --tags to show all tags.\n"
    let l:text .= "\n"
    let l:text .= "- Stash:\n"
    let l:text .= "    :Gitsth [NUM]         : show stash list, if NUM (0, 1 ....) is set show stash diff.\n"
    let l:text .= "    :Gitsthl              : show stash list menu, select stash to show stash diff.\n"
    let l:text .= "    :Gitsthmv [COMMENT]   : save to stash, move staged files to the stash.\n"
    let l:text .= "    :Gitsthcp [COMMENT]   : save to stash, copy staged files to the stash and keep local files.\n"
    let l:text .= "    :Gitstha [NUM]        : apply changes from stash.\n"
    let l:text .= "    :Gitsthd [NUM]        : delete stash entry.\n"
    let l:text .= "\n"
    let l:text .= "- Tags:\n"
    let l:text .= "    :Gitt [PATTERN]       : show git tags, if argument provided show tags matching pattern.\n"
    let l:text .= "    :Gittm [PATTERN]      : show git tags menu, if argument provided show tags matching pattern.\n"
    let l:text .= "    :Gitta [NAME]         : add new tag.\n"
    let l:text .= "    :Gittd [NAME]         : delete tag.\n"
    let l:text .= "    :Gittpush [TAG]       : push tags.\n"
    let l:text .= "    :Gittpushd [TAG]      : delete tag on remote.\n"
    let l:text .= "\n"
    let l:text .= "- Checkout:\n"
    let l:text .= "    :Gitco                : perform checkout from branch.\n"
    let l:text .= "    :Gitcob [NEW_BRANCH]  : perform checkout from branch on new branch.\n"
    let l:text .= "\n"
    let l:text .= "- Commit:\n"
    let l:text .= "    :Gitcm [FILEPATH/DESC]: perform git commit.\n"
    let l:text .= "    :GitcmAll [FILEPATH/DESC]: perform git commit adding any changed files already traked.\n"
    let l:text .= "                             caution: this commands skips the staging area.\n"
    let l:text .= "    :GitcmAm [FILEPATH/DESC]: amend previous commit.\n"
    let l:text .= "\n"
    let l:text .= "- Diff:\n"
    let l:text .= "    Basic:\n"
    let l:text .= "      :Gitd PATH          : get diff of changes on the selected path.\n"
    let l:text .= "      :Gitdf              : get diff of changes on current file.\n"
    let l:text .= "      :Gitdd              : get diff of changes on current file's directory.\n"
    let l:text .= "      :Gitda              : get diff of (all) changes on current workind directory.\n"
    let l:text .= "      :Gitds              : get diff of (all) staged changes on current workind directory.\n"
    let l:text .= "    Advanced: allows to filter files and binaries.\n"
    let l:text .= "      :GitD PATH [FLAGS]  : get diff of changes on selected path.\n"
    let l:text .= "      :GitDD [FLAGS]      : get diff of changes on current file's directory.\n"
    let l:text .= "      :GitDA [FLAGS]      : get diff of (all) changes on workind directory.\n"
    let l:text .= "    Gitdvdr              : when placed on a git log and diff file (after Gitr/Gitdd/Gitdf/Gitda)\n"
    let l:text .= "                           get each file changes vimdiff.\n"
    let l:text .= "    :Gitdapp [FILES]       : apply patch of diff files.\n"
    let l:text .= "    :Gitdrev [FILES]       : reverse patch of diff files.\n"
    let l:text .= "\n"
    let l:text .= "- Vimdiff:\n"
    let l:text .= "    Basic:\n"
    let l:text .= "      :Gitvdf             : get vimdiff of current file changes.\n"
    let l:text .= "      :Gitvd PATH         : get vimdiff of (all) changes on working dir.\n"
    let l:text .= "      :Gitvdd             : get vimdiff of current file's directory changes.\n"
    let l:text .= "      :Gitvda             : get vimdiff of (all) files with changes on working dir.\n"
    let l:text .= "  * Advanced: allows to filter files and binaries.\n"
    let l:text .= "      :GitvD PATH [FLAGS] : get vimdiff of the files with changes on the selected path.\n"
    let l:text .= "      :GitvDD [FLAGS]     : get vimdiff of the files with changes on current file's directory.\n"
    let l:text .= "      :GitvDA [FLAGS]     : get vimdiff of the files with changes on working directory.\n"
    let l:text .= "  * FLAGS:\n"
    let l:text .= "      B:  show binaries.\n"
    let l:text .= "      NB: skip binaries (default).\n"
    let l:text .= "      EQ: show equal (default).\n"
    let l:text .= "      NEQ: skip equal.\n"
    let l:text .= "      +pattern (keep only files with pattern).\n"
    let l:text .= "      -pattern (skip all files with pattern).\n"
    let l:text .= "\n"
    "let l:text .= "- Directory compare (sandbox compare):\n"
    "let l:text .= "    Compare files with changes on both paths:\n"
    "let l:text .= "      :Gitdc [PATH1] PATH2 [FLAG]  : get diff on all changes.\n"
    "let l:text .= "      :Gitvdc [PATH1] PATH2 [FLAG] : get vimdiff on all changes.\n"
    "let l:text .= "    FLAG:\n"
    "let l:text .= "      ALL: show all files.\n"
    "let l:text .= "      EO: equal files only.\n"
    "let l:text .= "      SE: skip equal files (default).\n"
    "let l:text .= "      BO: binary files only. \n"
    "let l:text .= "      SB: skip binary files (default).\n"
    "let l:text .= "      C1: check only git changes on path1.\n"
    "let l:text .= "      C2: check only git changes on path2.\n"
    "let l:text .= "\n"
    let l:text .= "- Revision:\n"
    let l:text .= "    :Gitr [REV]           : get diff of selected revision number.\n"
    let l:text .= "    :Gitrsh [REV]         : show the file on the requested revision number\n"
    let l:text .= "\n"
    let l:text .= "- Describe:\n"
    let l:text .= "    :Gitdesca [HASH]      : Describe tags of hash.\n"
    let l:text .= "\n"
    let l:text .= "- Cherry-picking:\n"
    let l:text .= "    :Gitcp [HASH]         : git cherry-pick. Add commit hash.\n"
    let l:text .= "    :Gitcpe [HASH]        : git cherry-pick. Add commit hash and edit message.\n"
    let l:text .= "    :GitcpNC [HASH]       : git cherry-pick. Add commit hash but no commit.\n"
    let l:text .= "\n"
    let l:text .= "- Conflicts:\n"
    let l:text .= "    :Gitmc [LAYOUT]       : merge all conflicts with vimdiff.\n"
    let l:text .= "    :Gitmcf [LAYOUT]      : merge current file conflict with vimdiff.\n"
    let l:text .= "    :Gitmcp PATH [LAYOUT] : merge selected path conflicts with vimdiff.\n"
    let l:text .= "    :Gitmch               : merge tool layout help.\n"
    let l:text .= "    :Gitmcrm              : remove merge tool temporary files.\n"
    let l:text .= "    :Gitmcs               : search merge tags.\n"
    let l:text .= "\n"
    let l:text .= "- Remote branches:\n"
    let l:text .= "    :Gitpush [REMOTE_BRANCH] : perform git push to remote branch.\n"
    let l:text .= "    :Gitpushd [REMOTE_BRANCH]: delete remote branch.\n"
    let l:text .= "    :Gitpull [REMOTE_BRANCH] : perform git pull from branch.\n"
    let l:text .= "    :Gitreme                 : remote edit. Edit saved remote's file.\n"
    let l:text .= "    :Gitrso [filter]         : show origin on remote branches.\n"
    let l:text .= "    :Gitrb [pattern]         : show remote branches.\n"
    let l:text .= "    :Gitro [name]            : change default remote (origin).\n"
    let l:text .= "    :Gitrov [name]           : change default remote (origin), show push/pull URL.\n"
    let l:text .= "\n"
    let l:text .= "- Merge:\n"
    let l:text .= "    :Gitmb                : merge with local branch.\n"
    let l:text .= "    :GitmbS               : merge with local branch and squash commits.\n"
    let l:text .= "    :Gitmr [BRANCH]       : Merge with remote branch.\n"
    let l:text .= "    :GitmrS [BRANCH]      : Merge with remote branch and squash commits.\n"
    let l:text .= "\n"
    let l:text .= "- Reset:\n"
    let l:text .= "    :Gitreset [HASH]      : soft reset.\n"
    let l:text .= "    :Gitresetm [HASH]     : medium reset.\n"
    let l:text .= "    :Gitreseth [HASH]     : hard reset.\n"
    let l:text .= "\n"
    let l:text .= "- Tools:\n"
    let l:text .= "    :Gitbg                : toogle git job run on ".l:job."\n"
    let l:text .= "\n"
    let l:text .= "\n"
    let l:text .= "-------------------------------------------------------------------------\n"
    let l:text .= "\n"
    let l:text .= "EXAMPLES:\n"
    let l:text .= "\n"
    let l:text .= "- Get diff of all modified files:\n"
    let l:text .= "    :Gitda\n"
    let l:text .= "\n"
    let l:text .= "- Get diff off all changes on selected path (show equal and binary files):\n"
    let l:text .= "    :GitD project1/source ALL\n"
    let l:text .= "\n"
    let l:text .= "- Get diff off all changes on selected path, only cpp files:\n"
    let l:text .= "    :GitD project1/source +cpp\n"
    let l:text .= "\n"
    let l:text .= "- Get diff off all changes on all cpp files:\n"
    let l:text .= "    :GitDA +cpp\n"
    let l:text .= "\n"
    let l:text .= "- Get diff off all changes on all cpp and xml files, skip config files:\n"
    let l:text .= "    :GitDA +cpp +xml -config\n"
    let l:text .= "\n"
    let l:text .= "- Get vimdiff off each cpp file with changes on the selected path\n"
    let l:text .= "    :GitVD project1/source +cpp\n"
    let l:text .= "\n"
    let l:text .= "- Get vimdiff off every file changed:\n"
    let l:text .= "    :Gitvda\n"
    let l:text .= "\n"
    let l:text .= "- Get vimdiff off each cpp and xml, but not config file with changes:\n"
    let l:text .= "    :GitVDA +cpp +xml -config\n"
    let l:text .= "\n"
    "let l:text .= "- Compare the files changed on two directories (omitt binaries and equal files):\n"
    "let l:text .= "    :Gitvdc /home/jp/sandbox1 /home/jp/sandbox2/\n"
    "let l:text .= "\n"
    "let l:text .= "- Compare the files changed on two directories (show equal and binary files):\n"
    "let l:text .= "    :Gitvdc /home/jp/sandbox1 /home/jp/sandbox2/ ALL\n"
    "let l:text .= "\n"
    "let l:text .= "- Compare the files changed on current directory (flag C1) with its counterpart on another directory:\n"
    "let l:text .= "  (equal files and binaries omitted by default)\n"
    "let l:text .= "    :Gitvdc /home/jp/sandbox2/ C1\n"
    "let l:text .= "\n"
    let l:text .= "- Show git list and git stash 3:\n"
    let l:text .= "    :Gitsh\n"
    let l:text .= "    :Gitsh 3\n"
    let l:text .= "\n"
    let l:text .= "- Perform git commit, edit default description file:\n"
    let l:text .= "    :Gitcm\n"
    let l:text .= "\n"
    let l:text .= "- Perform git commit with message:\n"
    let l:text .= "    :Gitcm Commit description message\n"
    let l:text .= "\n"
    let l:text .= "- Perform git commit, get  message from file:\n"
    let l:text .= "    :Gitcm /dir/file\n"
    let l:text .= "\n"

    call gitTools#tools#WindowSplitMenu(4)
    call gitTools#tools#WindowSplit()
    call gitTools#tools#WindowSplitEnd()
    setl nowrap
    set buflisted
    set bufhidden=delete
    set buftype=nofile
    setl noswapfile
    silent put = l:text
    silent! exec '0file | file gitTools_plugin_help'
    normal ggdd

    call s:HelpHighlightColors()
endfunction


function! s:HelpHighlightColors()
    if exists('g:HiLoaded')
        let g:HiCheckPatternAvailable = 0

        silent! call hi#config#PatternColorize("Abridged", "w3*")
        silent! call hi#config#PatternColorize("- ",       "w3*")
        silent! call hi#config#PatternColorize("EXAMPLES", "w3*")

        silent! call hi#config#PatternColorize(":Git[a-zA-Z]", "b")
        silent! call hi#config#PatternColorize(":Git[a-zA-Z][a-zA-Z]", "b")
        silent! call hi#config#PatternColorize(":Git[a-zA-Z][a-zA-Z][a-zA-Z]", "b")
        silent! call hi#config#PatternColorize(":Git[a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z]", "b")
        silent! call hi#config#PatternColorize(":Git[a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z]", "b")

        let g:HiCheckPatternAvailable = 1
    endif
endfunction

" Test git status colors:
"A     unmerged, added by us
 "A    unmerged, added by us
"AA    unmerged, added by us
 "D    unmerged, added by us
"D     unmerged, added by us
"DD    unmerged, added by us
"M     unmerged, added by us
 "M    unmerged, added by us
"MM    unmerged, added by us
"T     unmerged, added by us
 "T    unmerged, added by us
"TT    unmerged, added by us
"R     unmerged, added by us
 "R    unmerged, added by us
"RR    unmerged, added by us
"C     unmerged, added by us
 "C    unmerged, added by us
"CC    unmerged, added by us
"AD    unmerged, added by us
"DD    unmerged, both deleted
"AU    unmerged, added by us
"UD    unmerged, deleted by them
"UA    unmerged, added by them
"DU    unmerged, deleted by us
"AA    unmerged, both added
"UU    unmerged, both modified
"

" Open a menu and select a git command to launch.
" Cmd: Git
function! gitTools#help#LaunchCommandMenu(...)
    let l:cmdList = []

    if a:0 >= 1
        let l:filter = a:1
    else
        let l:filter = ""
    endif


    "let l:cmdList += [ "GitD PATH [FLAGS]       : get diff of changes on selected path." ]
    "let l:cmdList += [ "Gitd PATH               : get diff of changes on the selected path." ]
    "let l:cmdList += [ "GitlS PATTERN [OPT]     : show git log entries matching search pattern." ]
    "let l:cmdList += [ "Gitla AUTHOR            : show git log from author." ]
    "let l:cmdList += [ "Gitls STRING            : show git log changing string." ]
    "let l:cmdList += [ "Gitmcp PATH [LAYOUT]    : merge selected path conflicts with vimdiff." ]
    "let l:cmdList += [ "Gitsr ARGS              : call git show-ref ARGS." ]
    "let l:cmdList += [ "GitvD PATH [FLAGS]      : get vimdiff of the files with changes on the selected path." ]
    let l:cmdList += [ "" ]

    let l:cmdList += [ "!== Info commands == " ]
    let l:cmdList += [ "Giti      : get branch info." ]
    let l:cmdList += [ "Gitid     : get branch info description." ]
    let l:cmdList += [ "Gitc      : show git config." ]

    let l:cmdList += [ "!== Status commands == " ]
    let l:cmdList += [ "Gitst     : show file's status (conceal symbols: X and ?)." ]
    let l:cmdList += [ "Gitsta    : show status files (show all symbols)." ]
    let l:cmdList += [ "Gitstd    : show current directory status." ]
    let l:cmdList += [ "Gitstf    : show current file status." ]
    let l:cmdList += [ "!====" ]
    let l:cmdList += [ "GitSt     : show file's status (conceal symbols: X and ?)." ]
    let l:cmdList += [ "GitSta    : show status files (show all symbols)." ]
    let l:cmdList += [ "GitStd    : show current directory status." ]
    let l:cmdList += [ "GitStf    : show current file status." ]
    let l:cmdList += [ "GitSth    : show the git status symbols' help." ]
    let l:cmdList += [ "!== Status action commands == " ]
    let l:cmdList += [ "Gita      : git status. Add file to git stage." ]
    let l:cmdList += [ "Gitmv     : git status. Move file/dir path." ]
    let l:cmdList += [ "Gitrm     : git status. Remove file/dir from repository." ]
    let l:cmdList += [ "GitR      : git status. Restore file." ]
    let l:cmdList += [ "GitRM     : git status. Remove from disk." ]
    let l:cmdList += [ "Gitu      : git status. Unstage file." ]

    let l:cmdList += [ "!== Branch commands == " ]
    let l:cmdList += [ "Gitb      : show branch info." ]
    let l:cmdList += [ "Gitbv     : show branch verbose info." ]
    let l:cmdList += [ "Gitbd     : delete branch." ]
    let l:cmdList += [ "Gitbmv    : rename branch." ]
    let l:cmdList += [ "Gitbc     : show git config of current branch." ]
    let l:cmdList += [ "Gitsw     : switch branch." ]

    let l:cmdList += [ "!== Commit commands ==" ]
    let l:cmdList += [ "Gitcm     : perform git commit." ]
    let l:cmdList += [ "GitcmAll  : perform git commit adding any changed files already traked." ]
    let l:cmdList += [ "GitcmAm   : amend previous commit." ]

    let l:cmdList += [ "!== Checkout commands ==" ]
    let l:cmdList += [ "Gitco     : perform checkout from branch." ]
    let l:cmdList += [ "Gitcob    : perform checkout from branch on new branch." ]

    let l:cmdList += [ "!== Diff commands ==" ]
    let l:cmdList += [ "Gitda     : get diff of (all) changes on current workind directory." ]
    let l:cmdList += [ "Gitdd     : get diff of changes on current file's directory." ]
    let l:cmdList += [ "Gitdf     : get diff of changes on current file." ]
    let l:cmdList += [ "Gitds     : get diff of (all) staged changes on current workind directory." ]
    let l:cmdList += [ "Gitdvdr   : when placed on a git log and diff file (after Gitr/Gitdd/Gitdf/Gitda." ]
    let l:cmdList += [ "Gitdapp [FILES] : apply patch of diff files." ]
    let l:cmdList += [ "Gitdapp [FILES] : reverse patch of diff files." ]
    "let l:cmdList += [ "GitDA     : get diff of (all) changes on workind directory." ]
    "let l:cmdList += [ "GitDD     : get diff of changes on current file's directory." ]

    let l:cmdList += [ "!== Vim diff commands == " ]
    let l:cmdList += [ "Gitvda    : get vimdiff of (all) files with changes on working dir." ]
    let l:cmdList += [ "Gitvdd    : get vimdiff of current file's directory changes." ]
    let l:cmdList += [ "Gitvdf    : get vimdiff of current file changes." ]
    "let l:cmdList += [ "GitvDA    : get vimdiff of the files with changes on working directory." ]
    "let l:cmdList += [ "GitvDD    : get vimdiff of the files with changes on current file's directory." ]

    let l:cmdList += [ "!== Log commands ==" ]
    let l:cmdList += [ "Gitl      : show git log." ]
    let l:cmdList += [ "Gitlo     : show git log oneline decorate full." ]
    let l:cmdList += [ "Gitlf     : show git log for current file." ]
    let l:cmdList += [ "Gitlfd    : show git log and diff for current file." ]
    let l:cmdList += [ "Gitlg     : show git log graph." ]
    let l:cmdList += [ "Gitlgo    : show git log graph, decorate oneline." ]
    let l:cmdList += [ "Gitlp     : show git log and patch for the last 10 commits." ]
    let l:cmdList += [ "Gitrl     : show git reference log." ]
    let l:cmdList += [ "GitL     : search function name changes history." ]

    let l:cmdList += [ "!== Grep commands ==" ]
    let l:cmdList += [ "Gitg      : grep pattern on the repository." ]

    let l:cmdList += [ "!== Merge branch commands ==" ]
    let l:cmdList += [ "Gitmb     : merge branch." ]
    let l:cmdList += [ "GitmbS    : merge branch and squash commits." ]
    let l:cmdList += [ "Gitmr     : Merge current branch with remote branch." ]
    let l:cmdList += [ "GitmrS    : Merge current branch with remote branch and squash commits." ]

    let l:cmdList += [ "!== Merge conflicts commands == " ]
    let l:cmdList += [ "Gitmc     : merge all conflicts with vimdiff." ]
    let l:cmdList += [ "Gitmcf    : merge current file conflict with vimdiff." ]
    let l:cmdList += [ "Gitmch    : merge tool layout help." ]
    let l:cmdList += [ "Gitmcrm   : remove merge tool temporary files." ]
    let l:cmdList += [ "Gitmcs    : search merge tags." ]

    let l:cmdList += [ "!== Remote commands == " ]
    let l:cmdList += [ "Gitpull   : perform git pull from branch." ]
    let l:cmdList += [ "Gitpush   : perform git push to remote branch." ]
    let l:cmdList += [ "Gitpushd  : delete remote branch." ]
    let l:cmdList += [ "Gitreme   : remote edit. Edit saved remote's file." ]
    let l:cmdList += [ "Gitrb     : show remote branches." ]
    let l:cmdList += [ "Gitrso    : show origin on remote branches." ]
    let l:cmdList += [ "Gitro     : change default remote repository." ]
    let l:cmdList += [ "Gitrov    : change default remote repository, show push/pull URL." ]

    let l:cmdList += [ "!== Show reference commands ==" ]
    let l:cmdList += [ "Gitsr     : show references." ]
    let l:cmdList += [ "Gitsrt    : show all tags." ]

    let l:cmdList += [ "!== Reset commands ==" ]
    let l:cmdList += [ "Gitreset  : soft reset." ]
    let l:cmdList += [ "Gitreseth : hard reset." ]
    let l:cmdList += [ "Gitresetm : medium reset." ]

    let l:cmdList += [ "!== Revision (hash) commands ==" ]
    let l:cmdList += [ "Gitr      : get diff of selected hash/revision number." ]
    let l:cmdList += [ "Gitrsh    : show the file on the requested hash/revision number." ]

    let l:cmdList += [ "!== Describe commands == " ]
    let l:cmdList += [ "Gitdesca [HASH] : Describe tags of hash." ]

    let l:cmdList += [ "!== Cherry-picking commands == " ]
    let l:cmdList += [ "Gitcp    [HASH] : cherry pick commit hash." ]
    let l:cmdList += [ "Gitcpe   [HASH] : cherry pick commit hash and edit message." ]
    let l:cmdList += [ "GitcpNC  [HASH] : cherry pick commit hash but no commit." ]

    let l:cmdList += [ "!== Stash commands ==" ]
    let l:cmdList += [ "Gitsth    : show stash list, if NUM (0, 1 ....) is set show stash diff." ]
    let l:cmdList += [ "Gitsthl   : show stash list menu, select to show stash diff." ]
    let l:cmdList += [ "Gitstha   : apply changes from stash." ]
    let l:cmdList += [ "Gitsthcp  : save to stash, copy staged files to the stash and keep local files." ]
    let l:cmdList += [ "Gitsthd   : delete stash entry." ]
    let l:cmdList += [ "Gitsthmv  : save to stash, move staged files to the stash." ]

    let l:cmdList += [ "!== Tag commands ==" ]
    let l:cmdList += [ "Gitt      : show git tags on buffer." ]
    let l:cmdList += [ "Gittm     : show git tags on menu." ]
    let l:cmdList += [ "Gitta     : add new tag." ]
    let l:cmdList += [ "Gittd     : delete tag." ]
    let l:cmdList += [ "Gittpush  : push tags." ]
    let l:cmdList += [ "Gittpushd : delete tag on remote." ]

    let l:cmdList += [ "!== Blame commands == " ]
    let l:cmdList += [ "Gitbl     : get blame of current file." ]

    " Filter commands to be displayed:
    if l:filter != ""
        let l:cmdFilterList = []

        for l:cmd in l:cmdList
            for l:filt in split(l:filter)
                if matchstr(l:cmd, l:filt) != ""
                    let l:cmdFilterList += [ l:cmd ]
                endif
            endfor
        endfor
    else
        let l:cmdFilterList = l:cmdList
    endif

    let l:header = [ "[gitTools] Select command:" ]
    let l:callback = "gitTools#help#LaunchCommand"

    call gitTools#menu#SelectWindowPosition(1)
    call gitTools#menu#AddCommentLineColor("!", "w4*")
    call gitTools#menu#ShowLineNumbers("no")
    call gitTools#menu#OpenMenu(l:header, l:cmdFilterList, l:callback, "")
endfunction


function! gitTools#help#LaunchCommand(cmd)
    redraw
    "echom "Cmd: ".a:cmd

    if a:cmd == ""
        call gitTools#tools#Error("[gitTools.vim] No command selected")
        return
    endif

    let l:list = split(a:cmd)
    let l:cmd = ":".l:list[0]

    if l:cmd == ""
        call gitTools#tools#Error("[gitTools.vim] Empty command")
        return
    endif

    echo l:cmd
    exec(l:cmd)
endfunction

