;;; -*- lexical-binding: t -*-

;; TODO: Help mode, Magit log mode, MagitPopup mode. 
(require 'vi--helpers)

(defun vi--config-evil ()
  "Configure evil mode."

  (delete 'term-mode evil-insert-state-modes)

  ;; Use Emacs state in these modes.
  (dolist (mode '(dired-mode
                  term-mode
                  flycheck-error-list-mode))
    (add-to-list 'evil-emacs-state-modes mode))

  (delete 'term-mode evil-insert-state-modes)

  (dolist (mode-name '("grep-mode"
                       "gnus-browse-mode"))
    ;; Use visual state in these modes.
    (add-to-list 'evil-motion-state-modes (intern mode-name))
    ;; Despite the above, 'h' keeps calling describe-mode. Fix that:
    (add-hook (intern (concat mode-name "-hook"))
              (lambda () (local-set-key (kbd "h") 'evil-backward-char))))

  ;; Use insert state in these additional modes.
  (dolist (mode '(magit-log-edit-mode))
    (add-to-list 'evil-insert-state-modes mode))


  (evil-add-hjkl-bindings occur-mode-map 'emacs
    (kbd "/")       'evil-search-forward
    (kbd "n")       'evil-search-next
    (kbd "N")       'evil-search-previous
    (kbd "C-f")     'evil-scroll-down
    (kbd "C-u")     'evil-scroll-up
    (kbd "C-w C-w") 'other-window)

  ;; Global bindings.
  (evil-define-key 'normal global-map (kbd "C-f")  'evil-scroll-down)
  (evil-define-key 'normal global-map (kbd "C-u")  'evil-scroll-up)
  (evil-define-key 'normal global-map (kbd "z z")  'evil-write)
  (evil-define-key 'normal global-map (kbd "C-t")  'find-tag)
  ; TODO: depending on the minor mode we might want to
  ; xref-find-references instead.
  (evil-define-key 'normal global-map (kbd "C-g")  'cscope-find-this-symbol)
  (evil-define-key 'normal global-map (kbd "<f3>") 'xref-find-definitions)
  (evil-define-key 'insert global-map (kbd "C-u")  'backward-kill-line))


(defun vi--config-evil-leader ()
  "Configure evil leader mode."
  (evil-leader/set-leader "<SPC>")
  (evil-leader/set-key
    "w" 'evil-write
    "q" 'auto-fill-mode
    "e" 'evil-append-line
    "t" 'find-tag
    "rs" 'rm-eol-whitespace
    "gs" 'magit-status
    "gl" 'magit-log-all
    "gd" 'magit-diff
    "bl" 'toggle-blame-mode
    "3" 'evil-search-word-backward
    "8" 'evil-search-word-forward))


(provide 'init-evil)
