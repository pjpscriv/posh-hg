Posh-Hg-Async
========

A fork of [Posh-Hg](https://github.com/JeremySkinner/posh-hg) with improved performance, particularly for large repositories. Fetches `hg status` in the background allowing the user to continue entering commands instead of locking up the whole terminal with every new line.

Original Posh-Hg:

![](https://github.com/pjpscriv/posh-hg-async/blob/master/gifs/posh-hg.gif?raw=true)

Posh-Hg-Async:

![](https://github.com/pjpscriv/posh-hg-async/blob/master/gifs/posh-hg-async.gif?raw=true)


## Posh-Hg Features

### Prompt

Provides a prompt for Mercurial repositories that shows the current branch and repo state (file additions, modifications, deletions).

### Tab Completion
Provides tab completion for common commands. E.g. `hg up<tab>` --> `hg update`

Usage
-----

See `profile.example.ps1` as to how you can integrate the tab completion and/or hg prompt into your own profile.
Prompt formatting, among other things, can be customized using the `$PoshHgSettings` variable. 

Installing
----------

0. Verify you have PowerShell 2.0 or better with `$PSVersionTable.PSVersion`
1. Verify execution of scripts is allowed with `Get-ExecutionPolicy` (should be `RemoteSigned` or `Unrestricted`). If scripts are not enabled, run PowerShell as Administrator and call `Set-ExecutionPolicy RemoteSigned -Confirm`.
2. Verify that `hg` can be run from PowerShell. If the command is not found, you will need to add a hg alias or add `%ProgramFiles%\TortoiseHg` to your PATH environment variable.
3. Clone the posh-hg repository to your local machine.
4. From the posh-hg repository directory, run `.\install.ps1`.
5. Enjoy!

The Prompt
----------

PowerShell generates its prompt by executing a `prompt` function, if one exists. posh-hg defines such a function in `profile.example.ps1` that outputs the current working directory followed by an abbreviated `hg status`:

    C:\Users\JSkinner [default]>

By default, the status summary has the following format:

    [{HEAD-name} +A ~B -C ?D !E ^F <G:H>]

* `{HEAD-name}` is the current branch, or the SHA of a detached HEAD
 * Cyan means the branch matches its remote
 * Red means the branch is behind its remote
* ABCDEFGH represent the working directory
 * `+` = Added files
 * `~` = Modified files
 * `-` = Removed files
 * `?` = Untracked files
 * `!` = Missing files
 * `^` = Renamed files
 * `<G:H>` = Current revision information matching the output of `hg log -r . --template '{rev}:{node|short}'`

Additionally, Posh-Hg can show any tags and bookmarks in the prompt as well as MQ patches if the MQ extension is enabled (disabled by default)

### Based on work by:

 - Jeremy Skinner, http://www.jeremyskinner.co.uk/
 - Keith Dahlby, http://solutionizing.net/
 - Mark Embling, http://www.markembling.info/
