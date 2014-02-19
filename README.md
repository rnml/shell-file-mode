`shell-file.el` defines elisp code supporting a workflow whereby one
manages and runs shell scripts from within emacs rather than the
command line.  The benefits of this approach include

  1. no context switching between emacs and the command line,
  2. clean separation of input (code or data) and outputs, so your
     cursor stays put in the code or other input, and
  3. structured logs of both command and output history, for easy
     searching later on.

One thing all these points have in common is a more sophisticated 
way of interacting with command line history. 

## the shell file ##

The central feature of this way of working is a shell script called
the *shell file* containing blocks of code.  Here is an example shell
file:

    #!/bin/bash
    # -*- eval: (shell-file-mode t) -*-
    source ~/bin/shell-file-prelude.sh # lines above START get run every time

    ### START ##########################################################

    echo 'hello world'
    echo 'this message brought to you by shell-file'

    exit ###############################################################

    cd /home
    for user in *; do
      echo hello $user
    done

    exit ###############################################################

    cd ~/src/foo/
    make
    ./main.exe | head

    exit ###############################################################

Running this script from the command line will always run the topmost
block.  From within emacs, one runs the same (topmost) block using the
`shell-file-run` command.  This can be done from any buffer.  If run
in the shell file buffer itself, the block where the cursor is will be
the one that is run, just after bubbling it up to become the new
topmost block if it isn't already.

The output for the command will pop up in a new buffer named
`*shell-file.0.out*`.  If a previous command is still running, it will
likely be called `*shell-file.1.out*`.  In general, the number in the
output buffer name is the lowest one without any command still
running.

## global keybindings ##

Keybindings for the followin commands are installed in an arbitrary
`KEYMAP` after a given `PREFIX` by calling
`(shell-file-define-global-keys KEYMAP PREFIX)`:

  + `shell-file-find` (`PREFIX` + `f`) jumps to the shell file,
    creating a dummy one if it doesn't already exist.

    The path of the shell file is the value of the elisp variable
    `shell-file-path`, whose default value is `~/bin/shell-file.sh`.

  + `shell-file-run` (`PREFIX` + `r`) has been discussed already in
    the previous section.

  + `shell-file-insert-block` (`PREFIX` + `i`) adds a new block to the
    top of the shell file.  If any text is highlighted when this
    command is run, it will be copied into this new block.  Otherwise
    the new block is empty.

  + `shell-file-insert-cd` (`PREFIX` + `g`) does the same as
    `shell-file-insert`, but inserts the command `cd DIR` where `DIR`
    is the current working directory of the file being visited.

## shell-file minor mode ##

A special minor mode called `shell-file-mode` is available with 
the following commands.

  + `shell-file-bubble-block` (`PREFIX` + `b`) -- bubble the current block up to become
    topmost one.  If already at the topmost block, swap with the
    second topmost one.
  + `shell-file-delete-block` (`PREFIX` + `d`) -- delete the block at point
  + `shell-file-next-block` (`PREFIX` + `j`) -- move the cursor to the next block
  + `shell-file-prev-block` (`PREFIX` + `k`) -- move the cursor to the previos block
  + `shell-file-split-block` (`PREFIX` + `s`) -- split the current block into two blocks
    at the cursor

These keybindings can be installed after an arbitrary key prefix in
the `shell-file-mode` keymap by calling
`(shell-file-define-minor-mode-keys PREFIX)`.
