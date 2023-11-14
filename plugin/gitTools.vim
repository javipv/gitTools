" Script Name: gitTools.vim
 "Description: 
"
" Copyright:   (C) 2022-2023 Javier Puigdevall
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies: jobs.vim, git.
"
" NOTES:
"
" Version:      0.1.1
" Changes:
" 0.1.1 	Fri, 28 Jul 23.     JPuigdevall
"   - New: make menu window display default option highligted.
"   - Change: Gitb, open in menu window. Copy branch name to default buffer on branch selection.
"   - New: Gitdapp, to apply a patch. Use provided filepath (diff or patch file) or current buffer if no filepath provided.
"   - New: Gitdrev, to reverese a patch. Use provided filepath (diff or patch file) or current buffer if no filepath provided.
"   - Change: Gitvda, ask user permission when more than 10 files modified to be opened with vimdiff.
"   - Fix: Gitr command, error, fix unknown variable l:rev.
"   - Fix: cherry picking callback function.
" 0.1.0 	Thu, 15 Jun 23.     JPuigdevall
"   - New: command Gitcp (cherry-pick), Gitcpe (cherry-pick --edit)  and GitcpNC (chrerry-pick --no-commit) 
"      If no hash provided, try extract hash from current line or word under cursor.
"   - New: Gitro and Gitrov to change default remote (by default set to: origin, modify on g:gitTools_origin).
"   - New: Gitc to show git config.
"   - New: Gitbc to show git config of current branch.
"   - Fix: on :Gitda show commit log header strings commented.
"   - Code refactoring, move local branch procedures to file branch.vim
"   - NEW!: menu to select options. Apply this menu to every local/remote branch selection.
"   - NEW!: command Git, to open a menu and select a git command to launch.
"   - New: command Gitmcs to search merge tags when solving conflicts.
"   - New: command GitlG to show graph with only oneline per commit.
"   - Change: on remove local branch (Gitbd) allow to remove several branches.
"   - New: Gitreseth and Gitresetm to launch hard and medium resets.
"   - Change: Gitreset to launch soft reset on provided hash number or hash number under cursor.
" 0.0.7 	Tue, 05 Mar 23.     JPuigdevall
"   - New: Gitsr ARGS (git show-ref ARGS) and Gitsrt (git show-ref --tags) to call show-ref commands.
"   - New: Gitid info describe (--tags --always --dirty).
"   - Fix: improve isGitAvailable time by moving to git branch command.
"   - New: command Gitrso to show remote branches origin.
"   - New: command Gitbr to show remote branches.
"   - Change: for Gitb, Gitsw, Gitbd... improve command speed, do not aswk isGitAvailable.
"     use git branch response to know if git is available.
"   - Change: rename git commit all from Gitcma to GitcmAll.
"   - Change: rename git commit ammend from GitcmA to GitcmAm.
"   - Change: change conflict merge commands to Gitmc[f/p/h/rm].
"   - New: command GitmbS to merge branch with squash parameter, merge as a
"     single commit.
"   - New: command Gitmb to merge branch.
"   - New: improve GitRM command to remove files from disk, adding menu option 'a' to
"     remove all files selected.
"   - New: command Gitbmv to rename branches.
"   - Fix: Gitb nor working on empty buffer.
"   - New: command git status :Gitsta execution on background.
"   - New: command :Gitreset.
"   - New: show Gitsw output on new window and highlight.
"   - New: on status commands Gita, Gitrm, Gitu, GitR and GitRM, accept % as
"     first argument, and substitute for current file.
"   - New: commands Gitlf get file's log, and Gitlfd get file's log and diff.
"   - New: on Gitd commands, add branch names to the buffer name.
"   - Fix: git merge issue (Gitm) bad substitution removing 'u' from path.
"   - New: add color highlighting to git pull buffer.
"   - New: add date to git push and git pull buffer names.
"   - New: adapt to Jobs.vim change. g:loaded_jobs renamed to g:VimJobsLoaded
"   - New: launch push and pull commands on background.
"   - New: on help command (:Gith), add color highlighting.
"   - New: remote branch merge command Gitmr.
"   - New: remote branch merge --squash command GitmrS, merge as a single commit.
"   - New: checkout command Gitco
"   - New: checkout and new branch command Gitcob
" 0.0.6 	Thu, 27 Oct 22.     JPuigdevall
"   - New: highlight command help window.
"   - New: branch delete command Gitbd.
"   - New: remote branch push command Gitpush.
"   - New: remote branch delete command Gitpushd.
"   - New: remote branch pull command Gitpull.
"   - New: command Gitreme to edit saved remote branches.
" 0.0.5 	Thu, 20 Oct 22.     JPuigdevall
"   - Fix: Gitvda, get current branch error.
"   - New: after commit ask user if merge files should be removed. 
"   - New: command Gitmrm to delete the temporary files (REMOTE, LOCAL, BACKUP) 
"     from previous merge.
"   - New: for commands Gitm, Gitd and Gitvd, use git diff to get unmerged or modified 
"     files instead of git status.
"   - Fix: issue on merge command Gitm, error opening layout 3A.
"   - New: command Gitsthmv to move staged changes to stash.
"   - New: command Gitsthcp to copy staged changes to stash and keep local copy.
"   - New: command Gitstha to apply changes from stash.
"   - New: command Gitsthd to delete apply changes from stash.
"   - Change: rename Gitsh command to Gitsth.
"   - New: command Gitsw to perform git switch.
"   - Change: rename command Gita (show branches) to Gitb.
" 0.0.4 	Mon, 28 Sep 22.     JPuigdevall
"   - New: on commands Gitda, Gitdf..., add date, hour and branch name to the generated diff file name.
"   - Fix: commands Gitm, Gitmf, Gitmp used to merge conlicts. Allowed layouts: 1, 2, 3, 4.
"   - New: command GitcmA to ammend previous commit
"   - New: command Gitcma to commit all changed files already tracked skipping stage area.
"   - New: command GitlS to display log changing string.
"   - New: command Gitla to display log from author.
"   - New: command Gitrl to display reference log.
"   - New: command Gitlg to display log graph. Add color highligting with hi.vim plugin.
"   - Fix: on Gitsh, prevent showing diff path with a/ and b/ prefixes.
"   - Fix: on Gitr, prevent showing diff path with a/ and b/ prefixes.
"   - New: on Gitsh display both git list and git list --stat. Add color highlighting.
" 0.0.3 	Fry, 29 Jul 22.     JPuigdevall
"   - New: stash command Gitsh [STASH_NUM]
"   - Fix: perform Gitst on foreground, no need of Jobs.vim.
"   - New: Gitcm [FILE/DESC] command. 
"     Launch without arguments to open commit message on first launch, then commit on
"     second launch.
"   - New: Gitds command to show diff with all staged chages.
"   - New: when callign Gitsta, if current buffer already shows a git status,
"     refresh it, do not ask user to open a new window/tab.
" 0.0.2 	Fry, 08 Jul 22.     JPuigdevall
"   - New: Gitvdf, do not open new tab when asking for vimdiff of current file.
"   - Fix: Gitvdf always shows file is not modified.
"   - New: remove from disk command GitRM.
"   - New: git move command Gitmv.
"   - New: remove from disk command Gitrm.
"   - New: git restore command Gitr.
"   - New: git unstage command Gitu.
"   - New: git add command Gita.
"   - Fix: call again ChooseBranchMenu(), when no branch choosen. 
"   - New: Gitm (git merge) command to show on vimdiff the files with
"     conflicts.
"   - Fix: Gitvd... and GitVD... commands not showing merge issues.
" 0.0.1 	Tue, 19 Apr 22.     JPuigdevall
"   - Initial realease.
"     Adapt plugin svnTools to use git instead of subversion.

if exists('g:loaded_gittools')
    finish
endif

let g:loaded_gittools = 1
let s:save_cpo = &cpo
set cpo&vim

let g:gitTools_version = "0.1.1"

"- configuration --------------------------------------------------------------

let g:gitTools_gitCmd          = get(g:, 'gitTools_gitCmd', "git")
let g:gitTools_userAndPsswd    = get(g:, 'gitTools_userAndPsswd', 0)
let g:gitTools_gitUser         = get(g:, 'gitTools_gitUser', "")
let g:gitTools_storeGitPsswd   = get(g:, 'gitTools_storeGitPsswd', 1)
let g:gitTools_runInBackground = get(g:, 'gitTools_runInBackground', 1)
let g:gitTools_gotoWindowOnEnd = get(g:, 'gitTools_gotoWindowOnEnd', 1)
let g:gitTools_lastCommits     = get(g:, 'gitTools_lastCommits', 3000)
let g:gitTools_mode            = get(g:, 'gitTools_mode', 3)

" On vimdiff window (commands: Gitvd, Gitvdp, Gitvda, Gitvdd, Gitvdf...) resize the right most window 
" multiplying current width with this value.
let g:gitTools_vimdiffWinWidthMultiplyValue = get(g:, 'gitTools_vimdiffWinWidthMultiplyValue', 1.3)

" Git commit options:
let g:gitTools_commitDescriptionDefaultFile = get(g:, 'gitTools_commitDescriptionDefaultFile',  ".git/COMMIT_EDITMSG")
"let g:gitTools_commitDryRunCmd   = get(g:, 'gitTools_commitDryRunCmd',  "git commit -v --branch --dry-run --long")
"let g:gitTools_commitDescFileCmd = get(g:, 'gitTools_commitDescFileCmd',  "git commit -v -F ".g:gitTools_commitDescriptionDefaultFile." --cleanup=strip")
let g:gitTools_commitDryRunCmd   = get(g:, 'gitTools_commitDryRunCmd',  "git commit --branch --dry-run")
let g:gitTools_commitDescFileCmd = get(g:, 'gitTools_commitDescFileCmd',  "git commit -F ".g:gitTools_commitDescriptionDefaultFile." --cleanup=strip")
let g:gitTools_commitMssgCmd     = get(g:, 'gitTools_commitMssgCmd',  "git commit -m ")

" Merge Layout:
let g:gitTools_dfltMergeLayout = get(g:, 'gitTools_dfltMergeLayout', "4")
let g:gitTools_mergeLayouts    = get(g:, 'gitTools_mergeLayouts', "1 2A 2B 3A 3B 4")

" Remotes:
let g:gitTools_remoteBranchFile = get(g:, 'gitTools_remoteBranchFile', ".gitTools_remotes")

" Menu:
let g:GitTools_menuMaxLines = get(g:, 'GitTools_menuMaxLines', 15)

" Default Remote Branch:
let g:gitTools_origin = get(g:, 'gitTools_origin', "origin")

" Menu Window:
let g:gitTools_menu_headerColor          = get(g:, 'gitTools_menu_headerColor', "b")
let g:gitTools_menu_defaultLineColor     = get(g:, 'gitTools_menu_defaultLineColor', "y8")
let g:gitTools_menu_highlightDefaultLine = get(g:, 'gitTools_menu_highlightDefaultLine', "")


"- commands -------------------------------------------------------------------

" INFO: 
command! -nargs=0  Giti                               call gitTools#info#Info()
command! -nargs=0  Gitid                              call gitTools#info#Describe()
command! -nargs=0  Gitc                               call gitTools#info#Config()

" BRANCHES: 
command! -nargs=0  Gitb                               call gitTools#branch#Branch("")
command! -nargs=0  Gitbv                              call gitTools#branch#Branch(" -vv")
command! -nargs=0  Gitbd                              call gitTools#branch#Delete()
command! -nargs=0  Gitsw                              call gitTools#branch#Switch()
command! -nargs=0  Gitbmv                             call gitTools#branch#Rename()
command! -nargs=0  Gitbc                              call gitTools#branch#Config()

command! -nargs=1  Gitsr                              call gitTools#generic#CommandBg("ShowRef", 3, "show-ref", "<args>")
command! -nargs=0  Gitsrt                             call gitTools#generic#CommandBg("ShowRef", 3, "show-ref", "--tags")

" STATUS COMMANDS:
command! -nargs=? -range Gita                         <line1>,<line2>call gitTools#commands#Add("<args>")
command! -nargs=? -range Gitu                         <line1>,<line2>call gitTools#commands#Unstage(<q-args>)
command! -nargs=? -range GitR                         <line1>,<line2>call gitTools#commands#Restore(<q-args>)
command! -nargs=? -range Gitrm                        <line1>,<line2>call gitTools#commands#Remove(<q-args>)
command! -nargs=* -range Gitmv                        call gitTools#commands#Move(<f-args>)
command! -nargs=? -range GitRM                        <line1>,<line2>call gitTools#commands#DiskRemove(<q-args>)

" STATUS: 
command! -nargs=1  -complete=dir   Gitstp             call gitTools#status#GetStatus(<q-args>, "-uno")
command! -nargs=0  Gitst                              call gitTools#status#GetStatus(getcwd(), "-uno")
command! -nargs=0  Gitsta                             call gitTools#status#GetStatus(getcwd(), "")
command! -nargs=0  Gitstf                             call gitTools#status#GetStatus(expand('%'), "-uno")
command! -nargs=0  Gitstd                             call gitTools#status#GetStatus(expand('%:h'), "-uno")

command! -nargs=1  -complete=dir   GitStp             call gitTools#status#GetStatus(<q-args>, "-suno")
command! -nargs=0  GitSt                              call gitTools#status#GetStatus(getcwd(), "-suno")
command! -nargs=0  GitSta                             call gitTools#status#GetStatus(getcwd(), "-s")
command! -nargs=0  GitStf                             call gitTools#status#GetStatus(expand('%'), "-suno")
command! -nargs=0  GitStd                             call gitTools#status#GetStatus(expand('%:h'), "-suno")
command! -nargs=0  GitSth                             call gitTools#help#StatusHelp()

" GIT STASH: 
command! -nargs=?  Gitsth                             call gitTools#stash#Show("<args>")
command! -nargs=?  Gitsthmv                           call gitTools#stash#Save("", "<args>")
command! -nargs=?  Gitsthcp                           call gitTools#stash#Save("-k ", "<args>")
command! -nargs=*  Gitstha                            call gitTools#stash#Apply(<args>)
command! -nargs=*  Gitsthd                            call gitTools#stash#Delete(<args>)

" GIT DIFF: 
" Simple diff
command! -nargs=1  -complete=dir   Gitd               call gitTools#diff#Diff("--unified=4 --no-prefix", <q-args>)
command! -nargs=0  Gitdf                              call gitTools#diff#Diff("--unified=4 --no-prefix", expand('%'))
command! -nargs=0  Gitdd                              call gitTools#diff#Diff("--unified=4 --no-prefix", expand('%:h'))
command! -nargs=0  Gitda                              call gitTools#diff#Diff("--unified=4 --no-prefix", getcwd())
command! -nargs=0  Gitdap                             call gitTools#diff#Diff("--unified=4", getcwd())
command! -nargs=0  Gitds                              call gitTools#diff#Diff("--unified=4 --no-prefix --staged", getcwd())
command! -nargs=*  Gitdapp                            call gitTools#diff#Apply("-p0", <f-args>)
command! -nargs=*  Gitdrev                            call gitTools#diff#Apply("-p0 --reverse", <f-args>)

" Flags:
"  ALL:show all files modified.
"  BO: show binaries only.
"  SB: skip binaries (default). 
"  +KeepPattern  : pattern used to keep files with names matching.
"  -SkipPattern  : pattern used to skip files with names not matching.
command! -nargs=*  -complete=dir   GitD               call gitTools#diff#DiffAdv(<f-args>)
command! -nargs=*  GitDD                              call gitTools#diff#DiffAdv(expand('%:h'), <f-args>)
command! -nargs=*  GitDA                              call gitTools#diff#DiffAdv(getcwd(), <f-args>)

" GIT DIFF WITH VIMDIF:
command! -nargs=0  Gitvdf                             call gitTools#vimdiff#File(expand('%'))

command! -nargs=1  -complete=dir   Gitvd              call gitTools#vimdiff#Path(<q-args>)
command! -nargs=0  Gitvdd                             call gitTools#vimdiff#Path(expand('%:h'))
command! -nargs=0  Gitvda                             call gitTools#vimdiff#Path(getcwd())

" Flags:
"  ALL:show all files modified.
"  BO:  show binaries only.
"  SB: skip binaries (default). 
"  +KeepPattern  : pattern used to keep files with names matching.
"  -SkipPattern  : pattern used to skip files with names not matching.
command! -nargs=*  -complete=dir   GitVD              call gitTools#vimdiff#PathAdv(<f-args>)
command! -nargs=*  GitVDD                             call gitTools#vimdiff#PathAdv(expand('%:h'), <f-args>)
command! -nargs=*  GitVDA                             call gitTools#vimdiff#PathAdv(getcwd(), <f-args>)

" DIFF FILES BETWEEN DIRECTORIES:
" Allowed options:
"  ALL:show all files modified.
"  BO: show binaries only.
"  SB: skip binaries (default). 
"  EO: show equal files only .
"  SE: skip equal files (default). 
"  C1: use only git changes on path1. 
"  C2: use only git changes on path2. 
"command! -nargs=*  -complete=dir   Gitdc              call gitTools#directory#CompareChanges("diff", <f-args>)
"command! -nargs=*  -complete=dir   Gitvdc             call gitTools#directory#CompareChanges("vimdiff", <f-args>)

" Open with vimdiff all files modified on a revsion or between two different revisions
" Gitvdr REV1
" Gitvdr REV1 REV2
" When no revision number provided as argument, try get word under cursor as the revision number.
"command! -nargs=*  Gitvdr                             call gitTools#vimdiff#RevisionsCompare(<f-args>)

" DIFF FILE TOOLS:
" When placed on buffer with a diff file opened.
"command! -nargs=0  Gitdvdr                            call gitTools#diffFile#OpenVimDiffOnEachFileAndRevision()
" Show vimdiff of each modified file
"command! -nargs=*  GitDiffVdr                         call gitTools#diffFile#OpenVimDiffOnAllFiles(<f-args>)
" When placed on a line starting with 'Index' or '---' or " '+++'
" Show vimdiff of current modified file
"command! -nargs=*  GitDiffVdrf                        call gitTools#diffFile#OpenVimDiffGetFileAndRevisionFromCurrentLine(<f-args>)

" GIT LOG: 
command! -nargs=?  Gitl                               call gitTools#log#GetHistory(<q-args>)
command! -nargs=0  Gitlo                              call gitTools#log#GetHistory("--oneline --decorate=full")
command! -nargs=0  Gitlp                              call gitTools#log#GetHistory("-p -10")
command! -nargs=1  Gitla                              call gitTools#log#GetHistory("--author <args>")
command! -nargs=1  GitlS                              call gitTools#log#GetHistory("-S <args>")
command! -nargs=0  Gitlf                              call gitTools#log#GetHistory(expand('%'))
command! -nargs=0  Gitlfd                             call gitTools#log#GetHistory("-p -- ".expand('%'))
command! -nargs=1  Gitls                              call gitTools#log#SearchPattern(<f-args>)
command! -nargs=?  Gitlg                              call gitTools#log#Graph(<q-args>)
command! -nargs=?  Gitlgo                             call gitTools#log#Graph("--decorate --oneline")
command! -nargs=?  Gitrl                              call gitTools#log#GetRefLog(<q-args>)

" Pending: adapt for git.
"command! -nargs=?  Gitlr                              call gitTools#log#GetRevDiff("<args>")

" Get log and diff from selected revision.
command! -nargs=?  Gitr                               call gitTools#log#GetLogAndDiff(<q-args>)

" DESCRIBE:
command! -nargs=*  Gitdesca                            call gitTools#describe#Describe("--all", <f-args>)

" CHERRY PICKING:
command! -nargs=* -range Gitcp                       <line1>,<line2>call gitTools#cherrypick#CherryPick("", <f-args>)
command! -nargs=* -range Gitcpe                      <line1>,<line2>call gitTools#cherrypick#CherryPick("--edit", <f-args>)
command! -nargs=* -range GitcpNC                     <line1>,<line2>call gitTools#cherrypick#CherryPick("--no-commit", <f-args>)

" GIT SHOW: show file on its state on another revision.
command! -nargs=1  Gitrsh                             call gitTools#show#Revision(<f-args>)

" GIT BLAME:
command! -nargs=0  Gitbl                              call gitTools#blame#Blame("")

" GIT CONFLICTS:
command! -nargs=*  Gitmc                              call gitTools#conflict#Merge(getcwd(), <f-args>)
command! -nargs=*  Gitmcf                             call gitTools#conflict#Merge(expand('%'), <f-args>) 
command! -nargs=*  Gitmcp                             call gitTools#conflict#Merge(<f-args>)
command! -nargs=*  Gitmch                             call gitTools#help#MergeLayoutHelp()
command! -nargs=0  Gitmcrm                            call gitTools#conflict#CleanTemporaryMergeFiles()
command! -nargs=0  Gitmcs                             call gitTools#conflict#SearchMergeTags()

"command! -nargs=*  Gitcma                             call gitTools#conflict#MergeListAddFile(<f-args>)
"command! -nargs=*  Gitcmd                             call gitTools#conflict#MergeListDelete(<f-args>)

" GIT COMMIT: 
command! -nargs=?  -complete=file Gitcm                call gitTools#commit#Commit("", "<args>")
command! -nargs=?  -complete=file GitcmAll             call gitTools#commit#Commit("-a", "<args>")
command! -nargs=?  -complete=file GitcmAm              call gitTools#commit#Commit("--amend", "<args>")

" GIT FETCH: 
command! -nargs=0  Gitf                               call gitTools#fetch#Fetch()

" GIT REMOTE: 
command! -nargs=0  Gitreme                            call gitTools#remote#Edit()
command! -nargs=*  Gitpush                            call gitTools#remote#Push("", <f-args>)
command! -nargs=*  Gitpushd                           call gitTools#remote#Push("delete", <f-args>)
command! -nargs=*  Gitpull                            call gitTools#remote#Pull(<f-args>)
command! -nargs=?  Gitrso                             call gitTools#remote#ShowOrigin("<args>")
command! -nargs=?  Gitrb                              call gitTools#remote#GetBranches("<args>")
command! -nargs=?  Gitro                              call gitTools#remote#Origin("", "<args>")
command! -nargs=?  Gitrov                             call gitTools#remote#Origin("-v", "<args>")
command! -nargs=?  Gitrls                             call gitTools#remote#LsBranches("<args>")

" GIT MERGE: 
command! -nargs=0  Gitmb                              call gitTools#merge#LocalBranch("")
command! -nargs=0  GitmbS                             call gitTools#merge#LocalBranch("--squash")
command! -nargs=*  Gitmr                              call gitTools#merge#RemoteBranch("", <f-args>)
command! -nargs=*  GitmrS                             call gitTools#merge#RemoteBranch("squash", <f-args>)

" GIT CHECKOUT:
command! -nargs=*  Gitco                              call gitTools#checkout#CheckOut("", <f-args>)
command! -nargs=*  Gitcob                             call gitTools#checkout#CheckOut("-b", <f-args>)

" GIT RESET:
command! -nargs=?  Gitreset                           call gitTools#reset#GitReset("soft","<args>")
command! -nargs=?  Gitresetm                          call gitTools#reset#GitReset("medium","<args>")
command! -nargs=?  Gitreseth                          call gitTools#reset#GitReset("hard","<args>")

" Other:
command! -nargs=0  Gith                               call gitTools#help#Help()
command! -nargs=?  Git                                call gitTools#help#LaunchCommandMenu("<args>")

" Toogle background/foreground execution of the git commands.
command! -nargs=?  Gitbg                              call gitTools#gitTools#BackgroundMode("<args>")

command! -nargs=?  Gitv                               call gitTools#tools#Verbose("<args>")

" Release functions:
command! -nargs=0  Gitvba                             call gitTools#gitTools#NewVimballRelease()

" Edit plugin files:
command! -nargs=0  Gitedit                            call gitTools#gitTools#Edit()

" Git user and password functions:
"command! -nargs=0  Gitpwd                             call gitTools#tools#SetUserAndPsswd()


"- abbreviations -------------------------------------------------------------------

" DEBUG functions: reload plugin
cnoreabbrev _gitrl    <C-R>=gitTools#gitTools#Reload()<CR>


"- Menus -------------------------------------------------------------------

if has("gui_running")
    call gitTools#gitTools#CreateMenus('cn' , ''               , ':Git'     , 'Choose git command on menu'                             , ':Git [filter]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Info'         , ':Giti'    , 'Working dir info'                                       , ':Giti')
    call gitTools#gitTools#CreateMenus('cn' , '.&Info'         , ':Gitc'    , 'Show git config'                                        , ':Gitc')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitb'    , 'Show branches info'                                     , ':Gitb')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitbv'   , 'Show branches verbose info'                             , ':Gitbv')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitbd'   , 'Delete branch'                                          , ':Gitbd')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitbmv'  , 'Rename branch'                                          , ':Gitbmv')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitbc'   , 'Get branch config'                                      , ':Gitbc')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitmb'   , 'Merge branch'                                           , ':Gitmb')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':GitmbS'  , 'Merge branch as a signle commit'                        , ':GitmbS')
    call gitTools#gitTools#CreateMenus('cn' , '.&Branch'       , ':Gitsw'   , 'Switch branches'                                        , ':Gitsw')
    call gitTools#gitTools#CreateMenus('cn' , '.&Blame'        , ':Gitbl'   , 'Get file blame'                                         , ':Gitbl')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitl'    , 'Show git log'                                           , ':Gitl [OPT]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlo'   , 'Show git log oneline decorate full'                     , ':Gitlo')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlf'   , 'Show git log from current file'                         , ':Gitl')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlfd'  , 'Show git log and diff from current file'                , ':Gitl')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlp'   , 'Show git log and patch, last 10 commits'                , ':Gitlp')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitla'   , 'Show git log from author'                               , ':Gitla AUTHOR')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':GitlS'   , 'Show git log changing string'                           , ':Gitls STRING')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitls'   , 'Show git log matching search pattern'                   , ':GitlS PATTERN')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlg'   , 'Show git log graph'                                     , ':Gitlg')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlgo'  , 'Show git log graph, one line'                           , ':Gitlgo')
    call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitrl'   , 'Show git reference log'                                 , ':Gitrl')
    "call gitTools#gitTools#CreateMenus('cn' , '.&Log'          , ':Gitlr'   , 'On git log file, get each revision diff'                , ':Gitlr')
    call gitTools#gitTools#CreateMenus('cn' , '.&Show-ref'     , ':Gitsr'   , 'Call git show-ref ARG'                                  , ':Gitsr ARGS')
    call gitTools#gitTools#CreateMenus('cn' , '.&Show-ref'     , ':Gitsrt'  , 'Show all tags. git show-ref --tags'                     , ':Gitsrt')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitd'    , 'Get file/path diff'                                     , ':Gitd PATH')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitdf'   , 'Get file diff'                                          , ':Gitdf')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitdd'   , 'Get dir diff'                                           , ':Gitdd')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitda'   , 'Get working dir changes diff'                           , ':Gitda')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitds'   , 'Get working dir staged changes diff'                    , ':Gitds')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitdapp' , 'Apply diff or patch file'                               , ':Gitdapp [FILES]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Diff'         , ':Gitdrev' , 'Revers diff or patch file'                              , ':Gitdrev [FILES]')
    call gitTools#gitTools#CreateMenus('cn' , '.&DiffFilt'     , ':GitD'    , 'Get (filtered) file/path diff'                          , ':GitD PATH [FLAGS]')
    call gitTools#gitTools#CreateMenus('cn' , '.&DiffFilt'     , ':GitDD'   , 'Get (filtered) dir changes diff'                        , ':GitDD [FLAGS]')
    call gitTools#gitTools#CreateMenus('cn' , '.&DiffFilt'     , ':GitDA'   , 'Get (filtered) working dir diff'                        , ':GitDA [FLAGS]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Vimdiff'      , ':Gitvd'   , 'Get current file/path changes using vimdiff'            , ':Gitvd')
    call gitTools#gitTools#CreateMenus('cn' , '.&Vimdiff'      , ':Gitvdf'  , 'Get current file changes using vimdiff'                 , ':Gitvdf')
    call gitTools#gitTools#CreateMenus('cn' , '.&Vimdiff'      , ':Gitvdd'  , 'Get current dir changes using vimdiff'                  , ':Gitvdd')
    call gitTools#gitTools#CreateMenus('cn' , '.&Vimdiff'      , ':Gitvda'  , 'Get working dir with changes using vimdiff'             , ':Gitvda')
    call gitTools#gitTools#CreateMenus('cn' , '.&VimdiffFilt'  , ':GitvD'   , 'Get current (filtered) file/path changes using vimdiff' , ':GitvD PATH [FLAGS]')
    call gitTools#gitTools#CreateMenus('cn' , '.&VimdiffFilt'  , ':GitvDD'  , 'Get current (filtered) dir changes using vimdiff'       , ':GitvDD [FLAGS]')
    call gitTools#gitTools#CreateMenus('cn' , '.&VimdiffFilt'  , ':GitVDA'  , 'Get working (filtered) dir with changes using vimdiff'  , ':GitVDA [FLAGS]')
    "call gitTools#gitTools#CreateMenus('cn' , '.&DirCompare'   , ':Gitdc'   , 'Get diff between changes on both paths'                 , ':Gitdc PATH1 PATH2 [FLAGS]')
    "call gitTools#gitTools#CreateMenus('cn' , '.&DirCompare'   , ':Gitvdc'  , 'Get vimdiff between changes on both paths'              , ':Gitvdc PATH1 PATH2 [FLAGS]')
    "call gitTools#gitTools#CreateMenus('cn' , '.&MyDirCompare' , ':Gitdmc'  , 'Get diff with files changed on current path'            , ':Gitdc PATH [FLAGS]')
    "call gitTools#gitTools#CreateMenus('cn' , '.&MyDirCompare' , ':Gitvdmc' , 'Get vimdiff with files changed on current path'         , ':Gitvdmc PATH [FLAGS]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Revision'     , ':Gitr'    , 'Get revision log and diff'                              , ':Gitr REV')
    call gitTools#gitTools#CreateMenus('cn' , '.&Revision'     , ':Gitrsh'  , 'Get revision files'                                     , ':Gitcr REV')
    call gitTools#gitTools#CreateMenus('cn' , '.&Revision'     , ':Gitvdr'  , 'Get vimdiff on revision'                                , ':Gitvdr [REV1] [REV2]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Describe'     , ':Gitdesca', 'Git tags description of hash'                           , ':Gitdesca [HASH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&CherryPick'   , ':Gitcp'   , 'Git cherry-pick'                                        , ':Gitcp [HASH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&CherryPick'   , ':Gitcpe'  , 'Git cherry-pick and edit message'                       , ':Gitcpe [HASH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&CherryPick'   , ':GitcpNC' , 'Git cherry-pick, do not commit'                         , ':GitcpNC [HASH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Conflicts'    , ':Gitmc'   , 'Merge all files in conflict'                            , ':Gitmc [LAYOUT]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Conflicts'    , ':Gitmcf'  , 'Merge file in conflict'                                 , ':Gitmcf [LAYOUT]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Conflicts'    , ':Gitmcp'  , 'Merge file in conflict'                                 , ':Gitmcp PATH [LAYOUT]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Conflicts'    , ':Gitmch'  , 'Merge tool layout help'                                 , ':Gitmch')
    call gitTools#gitTools#CreateMenus('cn' , '.&Conflicts'    , ':Gitmcrm' , 'Merge files remove temporary files'                     , ':Gitmcrm')
    call gitTools#gitTools#CreateMenus('cn' , '.&Conflicts'    , ':Gitmcs'  , 'Search merge tags'                                      , ':Gitmcs')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitsta'  , 'Show git status for all files'                          , ':Gitsta')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitstd'  , 'Show git status for current directoty'                  , ':Gitstd')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitstf'  , 'Show git status for current file'                       , ':Gitstf')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitstf'  , 'Show git status for path'                               , ':Gitstp PATH')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitb'    , 'Add file to git stage'                                  , ':Gita [FILEPATH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitu'    , 'Unstage file'                                           , ':Gitu [FILEPATH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':GitR'    , 'Restore file'                                           , ':Gitr [FILEPATH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitrm'   , 'Remove file/dir'                                        , ':Gitrm [FILEPATH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':Gitmv'   , 'Move file/dir'                                          , ':Gitmv [FILEPATH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Status'       , ':GitRM'   , 'Remove file/dir from disk'                              , ':GitRM [FILEPATH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Stash'        , ':Gitsth'   , 'Show git stash list/diff'                               , ':Gitsh [NUM]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Stash'        , ':Gitsthmv' , 'Show git stash save'                                    , ':Gitsthmv [COMMENT]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Stash'        , ':Gitsthcp' , 'Show git stash save'                                    , ':Gitsthcp [COMMENT]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Stash'        , ':Gitstha'  , 'Show git stash apply'                                   , ':Gitstha [NUM]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Stash'        , ':Gitsthd'  , 'Show git stash delete'                                  , ':Gitsthd [NUM]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Checkout'     , ':Gitco'   , 'Perform git checkout from branch'                       , ':Gitco ')
    call gitTools#gitTools#CreateMenus('cn' , '.&Checkout'     , ':Gitcob'  , 'Perform git checkout from branch to new branch'         , ':Gitcob [NEW_BRANCH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Commit'       , ':Gitcm'   , 'Perform git commit'                                     , ':Gitcm [FILE/DESCRIPTION]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Commit'       , ':GitcmAll' , 'Perform git commit with all changed files'              , ':GitcmAll [FILE/DESCRIPTION]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Commit'       , ':GitcmAm'  , 'Perform amend on previous git commit'                   , ':GitcmAm [FILE/DESCRIPTION]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitpush'  , 'Perform git push'                                       , ':Gitpush [REMOTE_BRANCH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitpushd'  , 'Delete remote branch'                                  , ':Gitpush [REMOTE_BRANCH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitpull'   , 'Perform git pull from branch'                          , ':Gitpulld [REMOTE_BRANCH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitreme'   , 'Edit remote branch file'                               , ':Gitreme')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitmr'    , 'Merge current branch with remote branch'                , ':Gitmr [REMOTE_BRANCH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':GitmrS'   , 'Merge current branch with remote branch as a single commit', ':GitmrS [REMOTE_BRANCH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitrso'   , 'Show remote branch origin'                              , ':Gitrso [filter]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitrb'    , 'Show remote branches'                                   , ':Gitrb [pattern]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitro'    , 'Choose remote origin'                                   , ':Gitro [name]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Remote'       , ':Gitrov'   , 'Choose remote origin, show push/pull URL'               , ':Gitrov [name]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Reset'        , ':Gitreset' , 'Reset soft'                                             , ':Gitreset [HASH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Reset'        , ':Gitresetm', 'Reset medium'                                           , ':Gitresetm [HASH]')
    call gitTools#gitTools#CreateMenus('cn' , '.&Reset'        , ':Gitreseth', 'Reset hard'                                             , ':Gitreseth [HASH]')
    "call gitTools#gitTools#CreateMenus('cn' , '.&FileCompare'  , ':Vdf'     , 'Compare [current] file with same one on different dir'  , ':Vdf [PATH1] PATH2')
    "call gitTools#gitTools#CreateMenus('cn' , '.&FileCompare'  , ':Vdd'     , 'Compare all files between directories'                  , ':Vdd [PATH1] PATH2 [FLAGS]')
    "call gitTools#gitTools#CreateMenus('cn' , ''               , ':Gitpwd'  , 'Set git user and password'                              , ':Gitpwd')
    call gitTools#gitTools#CreateMenus('cn' , ''               , ':Gitbg'   , 'Run foreground/background'                              , ':Gitbg')
    call gitTools#gitTools#CreateMenus('cn' , ''               , ':Gith '   , 'Show command help'                                      , ':Gith')
endif


let &cpo = s:save_cpo
unlet s:save_cpo

