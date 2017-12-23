;;; I chose to refer to myself as vi in elisp code since these two
;;; letters happen to be an abbreviation of my name.

(defun toggle-blame-mode ()
  (interactive)
  (cond ((bound-and-true-p magit-blame-mode)
         (call-interactively 'magit-blame-mode))
        (t
         (call-interactively 'magit-blame))))

(defun backward-kill-line (arg)
  "Kill ARG lines backward."
  (interactive "p")
  (kill-line (- 1 arg)))

(defun rm-eol-whitespace ()
  "Kill whitespace before ends of lines in current buffer."
  (interactive)
  (while (re-search-forward "[ \t]+$" nil t)
    (replace-match ""))
  (while (re-search-backward "[ \t]+$" nil t)
    (replace-match "")))

(defun notify-compilation-result (buffer msg)
  "Notify that the compilation is finished,
    close the *compilation* buffer if the compilation is successful,
    and set the focus back to Emacs frame"
  (if (not (string-match "*grep*" (buffer-name buffer)))
      (if (string-match "^finished" msg)
          (progn
            (delete-windows-on buffer)
            (message "Compilation Successful :-)"))
        (message "Compilation Failed :-("))
    (setq current-frame (car (car (cdr (current-frame-configuration)))))
    (select-frame-set-input-focus current-frame)))

(setq compilation-always-kill t)
(add-to-list 'compilation-finish-functions
	     'notify-compilation-result)


(provide 'vi--helpers)
