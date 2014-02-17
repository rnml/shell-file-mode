`shell-file.el` defines elisp code supporting a workflow whereby one
manages and runs shell scripts from within emacs rather than the
command line.  The benefits of this approach include

  * no context switching between emacs and the command line,
  * separation of command output from the command itself, so 
    your cursor stays editing the command, and
  * structured logs of both command and output history

# The shell file #

The central feature of this way of working is a shell scrip called the
*shell file* containing blocks of shell script.  Here is an example
shell file:

    #!/bin/bash
    # -*- eval: (shell-file-mode t) -*-
    source ~/bin/shell-file-prelude.sh # lines above START get run every time

    ### START ##########################################################

    echo 'hello world'
    echo 'this message brought to you by shell-file'

    exit ###############################################################

    cd ~/src/foo/
    make

    exit ###############################################################

    cd /home
    for user in *; do
      echo hello $user
    done

    exit ###############################################################

The 

# Global Keybindings #

    (shell-file-define-global-keys evil-leader--default-map "z")

       '(("f" shell-file-find)
         ("i" shell-file-insert-block)
         ("g" shell-file-insert-cd)
         ("r" shell-file-run))

# Minor Mode Keybindings #

    (shell-file-define-minor-mode-keys KEY-PREFIX)

       KEY-PREFIX + b  shell-file-bubble-block)
       KEY-PREFIX + d  shell-file-delete-block)
       KEY-PREFIX + j  shell-file-next-block)
       KEY-PREFIX + k  shell-file-prev-block)
       KEY-PREFIX + s  shell-file-split-block))
