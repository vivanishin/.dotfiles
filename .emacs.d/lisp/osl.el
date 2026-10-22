;;; osl.el --- Emacs capture and permanent OSL links -*- lexical-binding: t; -*-

(require 'org)
(require 'org-protocol)
(require 'json)
(require 'subr-x)

(defgroup osl nil "Obligation/status list." :group 'org)
(defcustom osl-directory "/mnt/co/notes/planning/osl/tasks/"
  "The primary OSL task directory, including the archive."
  :type 'directory)
(defcustom osl-command "/mnt/co/notes/planning/osl/osl.sh"
  "The OSL command-line helper." :type 'file)
(defcustom osl-web-url "http://127.0.0.1:8088/"
  "Read-only Web board URL." :type 'string)

(defun osl--run (&rest args)
  "Run the OSL helper with ARGS, returning its output."
  (let ((process-environment (copy-sequence process-environment)))
    (setenv "OSL_TASKS" (expand-file-name osl-directory))
    (with-temp-buffer
      (let ((status (apply #'call-process osl-command nil '(t t) nil args)))
        (unless (and (integerp status) (zerop status))
          (user-error "OSL: %s" (string-trim (buffer-string))))
        (string-trim-right (buffer-string))))))

(defun osl-resolve (number)
  "Resolve canonical positive NUMBER to its task file."
  (unless (string-match-p "\\`[1-9][0-9]*\\'" number)
    (user-error "Expected a canonical positive OSL number"))
  (osl--run "lookup" (concat "osl:" number)))

(defun osl-follow (number _argument)
  "Open the task with NUMBER, independent of its title or directory."
  (find-file (osl-resolve number)))

(defun osl-open (reference)
  "Open canonical REFERENCE, either 1234 or osl:1234."
  (interactive "sOSL number or reference (1234 or osl:1234): ")
  (unless (string-match "\\`\\(?:osl:\\)?\\([1-9][0-9]*\\)\\'" reference)
    (user-error "Expected a positive OSL number or osl:<number> reference"))
  (osl-follow (match-string 1 reference) nil))

(defun osl--config ()
  "Read the shared board configuration through the OSL helper."
  (json-parse-string (osl--run "config") :object-type 'alist :array-type 'list))

(defun osl-capture (title space)
  "Capture TITLE in SPACE using the shared numeric allocator."
  (interactive
   (let ((config (osl--config)))
     (list (read-string "Task title: ")
           (completing-read "Space: " (alist-get 'spaces config) nil t nil nil
                            (alist-get 'defaultSpace config)))))
  (let* ((result (json-parse-string
                  (osl--run "capture" "--title" title "--space" space)
                  :object-type 'alist))
         (filename (alist-get 'path result))
         (reference (alist-get 'reference result)))
    (find-file filename)
    (goto-char (point-max))
    (message "Captured %s; edit and save normally" reference)))

(defun osl--buffer-task ()
  "Return the current task's ID and title, or nil outside the task store."
  (when (and buffer-file-name
             (file-in-directory-p buffer-file-name osl-directory)
             (string-match-p "\\.md\\'" buffer-file-name))
    (save-excursion
      (goto-char (point-min))
      (let ((limit (and (re-search-forward "^# " nil t) (line-beginning-position))))
        (goto-char (point-min))
        (when (and limit (re-search-forward "\\[id:\\([1-9][0-9]*\\)\\]" limit t))
          (let ((id (match-string-no-properties 1)))
            (goto-char limit)
            (when (looking-at "# \\(.+\\)$")
              (list id (match-string-no-properties 1)))))))))

(defun osl-store-link ()
  "Store an Org link to the current task, independent of its filename."
  (when-let ((task (osl--buffer-task)))
    (org-link-store-props :type "osl" :link (concat "osl:" (car task))
                          :description (cadr task))))

(defun osl-copy-link ()
  "Copy a complete Org link to the current task."
  (interactive)
  (let ((task (osl--buffer-task)))
    (unless task (user-error "This buffer is not an OSL task"))
    (let ((link (org-link-make-string (concat "osl:" (car task)) (cadr task))))
      (kill-new link)
      (message "%s" link))))

(defun osl-open-link-at-point ()
  "Follow an explicit osl: reference in a Markdown task."
  (interactive)
  (let ((position (point)) reference)
    (save-excursion
      (beginning-of-line)
      (while (and (not reference) (re-search-forward "\\bosl:[1-9][0-9]*\\b" (line-end-position) t))
        (when (and (<= (match-beginning 0) position) (<= position (match-end 0)))
          (setq reference (match-string-no-properties 0)))))
    (unless reference (user-error "No osl: reference at point"))
    (osl-open reference)))

(defun osl--markdown-follow (url)
  "Resolve canonical OSL URL locally, leaving other Markdown links alone."
  (when (string-match-p "\\`osl:[1-9][0-9]*\\'" url)
    (osl-open url)
    t))

(defun osl-protocol-open (info)
  "Open the canonical OSL reference supplied by org-protocol INFO."
  (osl-open (or (plist-get info :reference) ""))
  nil)

(define-minor-mode osl-task-mode
  "Permanent OSL link commands in task buffers.
Bind commands in `osl-task-mode-map' in the user's configuration."
  :lighter " OSL"
  :keymap (make-sparse-keymap))

(defun osl--enable-task-mode ()
  "Enable OSL integration only for canonical task files."
  (when (and buffer-file-name
             (file-in-directory-p buffer-file-name osl-directory)
             (string-match-p "\\.md\\'" buffer-file-name))
    (osl-task-mode 1)))

(defun osl-validate ()
  "Validate all active and archived task files."
  (interactive)
  (message "%s" (osl--run "validate")))

(defun osl-browse (reference)
  "Open the read-only Web view for REFERENCE."
  (interactive "sOSL reference (osl:1234): ")
  (unless (string-match-p "\\`osl:[1-9][0-9]*\\'" reference)
    (user-error "Expected an exact osl:<number> reference"))
  (browse-url (concat (string-remove-suffix "/" osl-web-url) "/#" reference)))

(org-link-set-parameters "osl" :follow #'osl-follow :store #'osl-store-link)
(with-eval-after-load 'markdown-mode
  (add-hook 'markdown-follow-link-functions #'osl--markdown-follow))
(add-to-list 'org-protocol-protocol-alist
             '("OSL" :protocol "osl" :function osl-protocol-open))
(add-hook 'find-file-hook #'osl--enable-task-mode)
(dolist (buffer (buffer-list))
  (with-current-buffer buffer (osl--enable-task-mode)))

(provide 'osl)
;;; osl.el ends here
