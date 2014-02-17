(defcustom shell-file-path "~/bin/shell-file.sh"
  "Path to the shell-file collection of shell scripts")

(defcustom shell-file-dir (format "/tmp/shell-file.%s" (user-login-name))
  "Where shell-file commands and output will be logged")

(setq shell-file-init-line-re "^### START #########################.*\n")
(setq shell-file-exit-line-re "^exit ##############################.*\n")

(setq shell-file-mode-map (make-sparse-keymap))

(define-minor-mode shell-file-mode
  "Minor mode for use within the shell-file"
  :lighter " shell-file"
  :keymap 'shell-file-mode-map)

(defun shell-file-find ()
  "Open the shell-file"
  (interactive)
  (when (not (file-exists-p shell-file-path))
    (find-file shell-file-path)
    (insert (format "\
#!%s
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
" shell-file-name) )
    (save-buffer)
    )
  (find-file shell-file-path))

(defun shell-file-search-text (re)
  (save-window-excursion
    (save-excursion
      (shell-file-find)
      (goto-char (point-min))
      (search-forward-regexp re)
      (buffer-substring-no-properties (match-beginning 0) (match-end 0))
      )))

(defun shell-file-init-line ()
  (shell-file-search-text shell-file-init-line-re))

(defun shell-file-exit-line ()
  (shell-file-search-text shell-file-exit-line-re))

(defun shell-file-insert-block (&optional block-text)
  "insert a new shell block on top of the shell-file"
  (interactive)
  (let* ((init-line (shell-file-init-line))
         (exit-line (shell-file-exit-line)))
    (shell-file-find)
    (goto-line 1)
    (search-forward init-line)
    (insert "\n\n\n" exit-line)
    (forward-line -3)
    (when block-text (insert block-text)))
  )

(defun shell-file-insert-cd ()
  "insert a new shell block on top of the shell-file"
  (interactive)
  (let* ((dir default-directory))
    (shell-file-insert-block (concat "cd " dir))))

(defun shell-file-delete-block (num-times)
  "delete a shell block off the top of the shell-file"
  (interactive "p")
  (let* ((init-line (shell-file-init-line))
         (exit-line (shell-file-exit-line)))
    (dotimes (_ num-times)
      (when (not (search-backward exit-line nil t)) (search-backward init-line))
      (forward-line)
      (let ((beg (point)))
        (search-forward exit-line)
        (delete-region beg (point)))
      )))

(defun shell-file-split-block ()
  "delete a shell block off the top of the shell-file"
  (interactive)
  (let* ((f (shell-file-exit-line)))
    (beginning-of-line)
    (insert "\n" f)
    (forward-line -2)
    ))

(defun shell-file-bubble-block (keep-top)
  "bubble a shell block up to the top of the shell-file"
  (interactive "P")
  (catch 'body
    (let* ((init-line (shell-file-init-line))
           (exit-line (shell-file-exit-line)))
      (when (not (search-backward exit-line nil t))
        (if keep-top (throw 'body nil)
          (progn
            (search-forward exit-line)
            (search-backward exit-line))))
      (forward-line)
      (let ((beg (point)))
        (search-forward exit-line)
        (kill-region beg (point)))
      (goto-line 1)
      (search-forward init-line)
      (yank)
      (goto-line 1)
      (search-forward init-line)
      (forward-line 1))))

(defun shell-file-next-block (num-times)
  "move one block down in the shell-file"
  (interactive "p")
  (let* ((init-line (shell-file-init-line))
         (exit-line (shell-file-exit-line)))
    (dotimes (_ num-times)
      (cond
       ((search-backward exit-line nil t) (search-forward exit-line) (search-forward exit-line))
       ((search-backward init-line nil t) (forward-line) (search-forward exit-line))
       (t (search-forward init-line))
       )
      (forward-line))))

(defun shell-file-prev-block (num-times)
  "move one block up in the shell-file"
  (interactive "p")
  (let* ((init-line (shell-file-init-line))
         (exit-line (shell-file-exit-line)))
    (dotimes (_ num-times)
      (cond
       ((not (search-backward exit-line nil t)) (search-backward init-line))
       ((search-backward exit-line nil t) (search-forward exit-line))
       (t (search-backward init-line) (forward-line))
       )
      (forward-line))))

(defun shell-file-current-buffer-is-block-buffer ()
  (let* ((cur-buf (current-buffer))
         (shell-file-buf (find-buffer-visiting shell-file-path)))
    (equal shell-file-buf cur-buf)))

(defun shell-file-output ()
  "open the first inactive *shell-file.NUM.out* output buffer"
  (catch 'body
    (let* ((slot 0))
      (while t
        (let* ((name (format "*shell-file.%d.out*" slot))
               (buf (get-buffer name)))
          (when (not buf) (throw 'body (switch-to-buffer name)))
          (when (not (save-window-excursion (get-buffer-process buf)))
            (throw 'body (switch-to-buffer name)))
          (setq slot (+ slot 1)))))))

(defun shell-file-run ()
  "run shell-file top block in the background"
  (interactive)
  (when (shell-file-current-buffer-is-block-buffer)
    (shell-file-bubble-block t))
  (let*
      (;; compute log files
       (dir shell-file-dir)
       (_   (mkdir dir t))
       (uid (format-time-string "%Y-%m-%d.%H:%M:%S"))
       (cmd (format "%s/%s.command" dir uid))
       (out (format "%s/%s.output" dir uid))
       ;; write out block
       (_
        (save-window-excursion
          (save-excursion
            (shell-file-find)
            (goto-char (point-min))
            (search-forward-regexp (shell-file-exit-line))
            (write-region (point-min) (match-end 0) cmd))))
       ;; execute block
       (_ (chmod cmd (file-modes-symbolic-to-number "u+x" (file-modes cmd))))
       (cmd (format "%s 2>&1 | tee %s" cmd out))
       (buf (save-window-excursion (shell-file-output)))
       (_ (async-shell-command cmd buf))
       (_ (display-buffer buf nil 'visible))
       )
    nil))

(defun shell-file-define-global-keys (map key-prefix)
  "add shell-file keybindings that should be available globally"
  (dolist
      (binding
       '(("f" shell-file-find)
         ("i" shell-file-insert-block)
         ("g" shell-file-insert-cd)
         ("r" shell-file-run)))
    (let* ((key (car binding))
           (key (concat key-prefix key))
           (def (cadr binding)))
      (define-key map key def))))

(defun shell-file-define-minor-mode-keys (key-prefix)
  "add shell-file keybindings that should be available in shell-file-mode"
  (dolist
      (binding
       '(("b" shell-file-bubble-block)
         ("d" shell-file-delete-block)
         ("j" shell-file-next-block)
         ("k" shell-file-prev-block)
         ("s" shell-file-split-block)))
    (let* ((key (car binding))
           (key (concat key-prefix key))
           (def (cadr binding)))
      (define-key shell-file-mode-map key def))))
