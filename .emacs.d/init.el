;; -*- lexical-binding: t -*-
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package auto-package-update
  :ensure t
  :config
  (setq auto-package-update-delete-old-versions t
        auto-package-update-interval 4)
  (auto-package-update-maybe))

(require 'server)

(when (and window-system
           (eq (cdr command-line-args) nil)
           (not (server-running-p)))
  (message "This is the main instance (%d). Starting emacs server." (emacs-pid))
  (server-start)
  (desktop-save-mode)
  (setq desktop-auto-save-timeout (* 60 20)))

;;; ------------------------------------------------------------
;;; Language, encoding, locale...
(define-coding-system-alias 'UTF-8 'utf-8)

;;; ------------------------------------------------------------
;;; Theme
(use-package solarized-theme
  :ensure t)

(when window-system
 (require 'solarized)
 (load-theme 'solarized-dark t) ;wombat; misterioso; wheatgrass
 (add-to-list 'default-frame-alist '(font . "Inconsolata LGC 11"))
 (setq x-pointer-shape x-pointer-arrow))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(set-face-bold-p 'bold nil)

;; Vim-like scrolling.
(setq scroll-step 1)
(setq scroll-margin 1)
(setq scroll-conservatively 9999) ; Never recenter point.

(setq-default fill-column 80)
(auto-fill-mode)

;;; ------------------------------------------------------------
;;; Window management.
(require 'vi--windows)

;;; ------------------------------------------------------------
;;; Packages.
(use-package default-text-scale
  :ensure t
  :config
  :bind (("C-M-=" . default-text-scale-increase)
         ("C-M--" . default-text-scale-decrease)))

(use-package recentf
  :ensure t
  :config
  (recentf-mode 1)
  :bind (("C-x f" . recentf-open-files)))

(use-package image+
  :ensure t)

(use-package highlight
  :ensure t)

(use-package python-mode
  :ensure t)

(use-package nasm-mode
  :ensure t)

(use-package ido
  :ensure t
  :config
  (ido-mode 1))

(use-package which-key
  :ensure t)

(require 'dired)
(define-key dired-mode-map (kbd "SPC") 'dired-up-directory)
(add-hook 'dired-mode-hook 'turn-on-gnus-dired-mode)
(add-hook 'dired-mode-hook 'dired-hide-details-mode)

(use-package magit
  :config
  (progn
    (setq evil-collection-magit-want-horizontal-movement t)
    (setq git-commit-summary-max-length 50)
    (add-hook 'magit-revision-mode-hook 'bug-reference-mode)
    (add-hook 'git-commit-mode-hook
              (lambda () (set-fill-column 72))))
  :ensure t)

(use-package projectile
  :ensure t
  :config
  (setq projectile-enable-caching t
        projectile-use-git-grep t)
  (add-to-list 'projectile-globally-ignored-directories ".vscode")
  (add-hook 'prog-mode-hook 'projectile-mode))

(require 'vlad-util)

(use-package eglot
  :ensure t
  :config
  (add-to-list 'eglot-server-programs
               '((c++-mode c-mode)
                 .
                 (lambda (arg)
                   (let ((os-release "/etc/os-release"))
                     (cond ((and
                             (file-exists-p os-release)
                             (string-match-p
                              "Ubuntu"
                              (car (read-lines os-release))))
                            '("clangd-14" "--background-index"))
                           (t '("clangd"))))))))

(use-package clang-format
  :ensure t)

(use-package pdf-tools
  :ensure t)

(use-package grep-a-lot
  :ensure t
  :config
  (grep-a-lot-setup-keys))

(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode))

(use-package yaml-mode
  :mode "\\.yml\\'"
  :ensure t)

(use-package evil
  :ensure t

  :init
  (progn
    (setq evil-undo-system 'undo-tree)
    (setq evil-want-keybinding nil))

  :config

  (use-package evil-collection
    :ensure t
    :config
    (evil-collection-init))

  (use-package evil-leader
    :ensure t
    :config
    (progn
      (require 'init-evil)
      (global-evil-leader-mode)
      (vi--config-evil-leader)))

  (add-hook 'evil-mode-hook 'vi--config-evil)

  (use-package evil-search-highlight-persist
    :ensure t
    :config
    (global-evil-search-highlight-persist)
    (evil-define-key 'normal global-map (kbd "C-l") 'evil-search-highlight-persist-remove-all))

  (use-package evil-surround
    :ensure t
    :config
    (global-evil-surround-mode 1))

  (evil-mode 1))


;;; ------------------------------------------------------------
;;; Build with make. https://emacswiki.org/emacs/CompileCommand#toc5
(require 'cl)

(defun* get-closest-pathname (&optional (file "Makefile"))
  "Determine the pathname of the first instance of FILE starting from
the current directory towards root.  This may not do the correct thing
in presence of links. If it does not find FILE, then it shall return
the name of FILE in the current directory, suitable for creation"
  (let ((root (expand-file-name "/")))
    (expand-file-name file
                      (cl-loop
                       for d = default-directory then (expand-file-name ".." d)
                       if (file-exists-p (expand-file-name file d))
                       return d
                       if (equal d root)
                       return nil))))

(require 'compile)
(add-hook 'c++-mode-hook
          (lambda ()
            (set (make-local-variable 'compile-command)
                 (format "make -f %s" (get-closest-pathname)))))

;;; ------------------------------------------------------------
;;; Giule Scheme debugging.
(require 'guile-interaction-mode)
;(require 'gds)

;(add-to-list 'load-path "~/.emacs.d/static_packages/")
;
;;____________________________________________________________
;; Make the keys work with russian layout
;(require 'my-misc) ;; 'requires' are idempotent, you know
;(reverse-input-method "russian-computer")

(setq browse-url-browser-function 'browse-url-xdg-open)
(setq tramp-default-method "scp")
(setq enable-remote-dir-locals t)
(setq column-number-mode t)
(setq initial-scratch-message nil)
(setq-default indent-tabs-mode nil)
(setq-default c-default-style "linux")
(setq-default comment-multi-line t)
(setq-default comment-style 'extra-line)
(c-set-offset 'case-label '+)
(c-set-offset 'access-label -1)
(c-set-offset 'innamespace 0)
(c-set-offset 'inline-open 0)

;; Treat underscore as a part of a word in C and C++ modes.
(require 'cc-mode)
(require 'python-mode)
(require 'tex-mode)
(require 'make-mode)
(require 'cmake-mode)
(require 'gn-mode)
(require 'llvm-mode)
(require 'tablegen-mode)
(require 'perl-mode)
(modify-syntax-entry ?_ "w" c-mode-syntax-table)
(modify-syntax-entry ?_ "w" c++-mode-syntax-table)
(modify-syntax-entry ?_ "w" makefile-mode-syntax-table)
(modify-syntax-entry ?_ "w" cmake-mode-syntax-table)
(modify-syntax-entry ?_ "w" python-mode-syntax-table)
(modify-syntax-entry ?_ "w" perl-mode-syntax-table)
(modify-syntax-entry ?_ "w" yaml-mode-syntax-table)
(with-eval-after-load 'asm-mode
  (modify-syntax-entry ?_ "w" asm-mode-syntax-table))
(with-eval-after-load 'llvm
  (modify-syntax-entry ?_ "w" llvm-mode-syntax-table))
(with-eval-after-load 'org
  (modify-syntax-entry ?_ "w" org-mode-syntax-table))

(add-hook 'sh-mode-hook
          (lambda () (modify-syntax-entry ?_ "w" sh-mode-syntax-table)))

(add-hook 'scheme-mode-hook
          (lambda () (modify-syntax-entry ?- "w"scheme-mode-syntax-table)))

;; Treat the dash symbol as a part of a word in emacs lisp.
(modify-syntax-entry ?- "w" emacs-lisp-mode-syntax-table)
(modify-syntax-entry ?- "w" tex-mode-syntax-table)

(dolist (char '(?- ?_))
  (add-hook 'magit-revision-mode-hook
            `(lambda () (modify-syntax-entry ,char "w" magit-revision-mode-syntax-table))))

(modify-syntax-entry ?- "w" makefile-mode-syntax-table)


(when (or
       (equal (system-name) "archbook")
       (equal (system-name) "vlad-optiplex")
       (equal (system-name) "mikes"))
  (require 'init-gnus))

;;; ------------------------------------------------------------
;;; The rest of my key mappings. Makes sense to put it after all package loads.
(require 'vi--global-bindings)
(require 'vi--org-mode)


;;; ------------------------------------------------------------
;;; Keep all backup files in one place.
(setq backup-directory-alist '(("." . "~/.emacs.d/backup"))
  backup-by-copying t    ; Don't delink hardlinks
  version-control t      ; Use version numbers on backups
  delete-old-versions t  ; Automatically delete excess backups
  kept-new-versions 20   ; how many of the newest versions to keep
  kept-old-versions 5    ; and how many of the old
  )

;;; ------------------------------------------------------------
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default))
 '(gnus-read-newsrc-file nil)
 '(gnus-save-newsrc-file nil)
 '(org-startup-truncated nil)
 '(package-archives
   '(("melpa" . "http://melpa.org/packages/")
     ("gnu" . "http://elpa.gnu.org/packages/")
     ("org" . "http://orgmode.org/elpa/")))
 '(package-selected-packages
   '(yaml-mode nasm-mode which-key projectile dired cquery auto-package-update flycheck lsp-mode ggtags wc-mode default-text-scale python-info bbdb grep-a-lot lispy dired-x paredit evil-paredit image+ evil-search-highlight-persist highlight evil-leader pdf-tools magit use-package solarized-theme evil))
 '(scheme-program-name "guile")
 '(scroll-bar-mode nil)
 '(show-paren-mode t)
 '(tramp-remote-path
   '("/usr/local/bin" "/usr/bin" "/bin" tramp-default-remote-path) nil (tramp))
 '(undo-tree-history-directory-alist '(("." . "~/.emacs.d/transient") ("" . "")))
 '(vc-follow-symlinks t)
 '(wc-modeline-format "WC[%c/%tc]"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(put 'narrow-to-region 'disabled nil)
