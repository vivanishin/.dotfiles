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

(defvar-local osl--task-number nil)
(defvar-local osl--task-directory nil)
(defvar-local osl--task-file-name nil)
(defvar-local osl--move-warning nil)
(defvar osl--reconciling nil)
(defvar osl--selected-buffer nil)
(defvar osl-task-mode)

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
  (find-file (osl--resolve-for-visit number)))

(defun osl--reference-number (reference)
  "Return the canonical task number from REFERENCE."
  (unless (and (stringp reference)
               (string-match "\\`\\(?:osl:\\)?\\([1-9][0-9]*\\)\\'" reference))
    (user-error "Expected a positive OSL number or osl:<number> reference"))
  (match-string 1 reference))

(defun osl-open (reference)
  "Open canonical REFERENCE, either 1234 or osl:1234."
  (interactive "sOSL number or reference (1234 or osl:1234): ")
  (osl-follow (osl--reference-number reference) nil))

(defun osl--config ()
  "Read the shared board configuration through the OSL helper."
  (json-parse-string (osl--run "config") :object-type 'alist :array-type 'list))

(defun osl-capture (title space &optional state)
  "Capture TITLE in SPACE and optional STATE using the shared allocator.
STATE defaults to the configured capture column."
  (interactive
   (let ((config (osl--config)))
     (list (read-string "Task title: ")
           (completing-read "Space: " (alist-get 'spaces config) nil t nil nil
                            (alist-get 'defaultSpace config))
           (completing-read "Column: " (alist-get 'columns config) nil t nil nil
                            (alist-get 'captureColumn config)))))
  (let* ((result (json-parse-string
                  (apply #'osl--run
                         (append (list "capture" "--title" title "--space" space)
                                 (when state (list "--state" state))))
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
      (save-restriction
        (widen)
        (goto-char (point-min))
        (let ((limit (and (re-search-forward "^# " nil t) (line-beginning-position))))
          (goto-char (point-min))
          (when (and limit (re-search-forward "\\[id:\\([1-9][0-9]*\\)\\]" limit t))
            (let ((id (match-string-no-properties 1)))
              (goto-char limit)
              (when (looking-at "# \\(.+\\)$")
                (list id (match-string-no-properties 1))))))))))

(defun osl--remember-task ()
  "Remember a task's identity without replacing an already remembered ID."
  (when-let* ((task (osl--buffer-task)))
    (unless osl--task-number
      (setq osl--task-number (car task)
            osl--task-directory
            (file-name-as-directory (file-truename osl-directory))))
    (setq osl--task-file-name buffer-file-name)))

(defun osl--file-version (filename)
  "Return FILENAME's identity, size and modification time."
  (let ((attributes (file-attributes filename)))
    (list (file-attribute-file-identifier attributes)
          (file-attribute-size attributes)
          (file-attribute-modification-time attributes))))

(defun osl--reconcile-buffer (&optional filename)
  "Follow a verified external move to FILENAME, or resolve the remembered ID.
Signal a user error on conflicts; leave buffer text and unsaved edits intact."
  (when (and osl--task-number buffer-file-name
             (equal buffer-file-name osl--task-file-name)
             (not (file-exists-p buffer-file-name)))
    (let ((osl--reconciling t)
          (osl-directory osl--task-directory))
      (unless (equal osl--task-number (car (osl--buffer-task)))
        (user-error "OSL: task ID changed in this buffer; cannot follow the move"))
      (let ((target (or filename (osl-resolve osl--task-number))))
        (unless (and (file-regular-p target)
                     (file-in-directory-p target osl-directory))
          (user-error "OSL: moved task is missing or outside its task store"))
        (when (buffer-modified-p)
          (user-error "OSL osl:%s moved to %s; resolve unsaved edits before retrying"
                      osl--task-number target))
        (when-let* ((other (find-buffer-visiting target)))
          (unless (eq other (current-buffer))
            (user-error "OSL: %s already visits the destination; resolve both buffers"
                        (buffer-name other))))
        (let ((text (save-restriction
                      (widen)
                      (buffer-substring-no-properties (point-min) (point-max))))
              (version (osl--file-version target))
              (coding-system-for-read buffer-file-coding-system))
          (unless (with-temp-buffer
                    (insert-file-contents target)
                    (equal text (buffer-string)))
            (user-error "OSL osl:%s moved and changed on disk; compare with %s"
                        osl--task-number target))
          (unless (and (equal version (osl--file-version target))
                       (not (file-exists-p buffer-file-name)))
            (user-error "OSL: task files changed during reconciliation; retry"))
          (set-visited-file-name target nil t)
          (set-visited-file-modtime (nth 2 version))
          (setq osl--task-file-name buffer-file-name
                osl--move-warning nil)
          (message "OSL osl:%s now visits %s" osl--task-number target)
          t)))))

(defun osl-reconcile-buffer ()
  "Follow the current task's external move, reporting any conflict."
  (interactive)
  (unless osl-task-mode (user-error "This buffer is not an OSL task"))
  (osl--reconcile-buffer))

(defun osl--before-write ()
  "Reconcile before writing, allowing conflicts to abort the save."
  ;; Emacs demotes errors from before-save-hook and would save the old path.
  (osl--reconcile-buffer)
  nil)

(defun osl--resolve-for-visit (number)
  "Resolve NUMBER and reconcile its existing buffer before visiting it."
  (let ((filename (osl-resolve number))
        (directory (file-name-as-directory (file-truename osl-directory)))
        buffers)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and osl-task-mode (equal osl--task-number number)
                   (equal osl--task-directory directory))
          (push buffer buffers))))
    (when (cdr buffers)
      (user-error "OSL osl:%s has several open buffers; resolve them before opening"
                  number))
    (when buffers
      (with-current-buffer (car buffers)
        (osl--reconcile-buffer filename)))
    filename))

(defun osl--check-selected-buffer ()
  "Reconcile a newly selected task buffer without interrupting selection."
  (unless osl--reconciling
    (let ((buffer (window-buffer (selected-window))))
      (unless (eq buffer osl--selected-buffer)
        (setq osl--selected-buffer buffer)
        (with-current-buffer buffer
          (when osl-task-mode
            (condition-case err
                (osl--reconcile-buffer)
              (error
               (let ((warning (error-message-string err)))
                 (unless (equal warning osl--move-warning)
                   (setq osl--move-warning warning)
                   (message "%s" warning)))))))))))

(defun osl--focus-change ()
  "Check the selected task after Emacs regains focus."
  (when (frame-focus-state)
    (setq osl--selected-buffer nil)
    (run-with-idle-timer 0 nil #'osl--check-selected-buffer)))

(defun osl-store-link ()
  "Store an Org link to the current task, independent of its filename."
  (when-let* ((task (osl--buffer-task)))
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
  "Return the task file from org-protocol INFO for normal server display."
  (osl--resolve-for-visit (osl--reference-number (plist-get info :reference))))

(define-minor-mode osl-task-mode
  "Permanent OSL link commands in task buffers.
Bind commands in `osl-task-mode-map' in the user's configuration."
  :lighter " OSL"
  :keymap (make-sparse-keymap)
  (if osl-task-mode
      (progn
        (osl--remember-task)
        (add-hook 'write-contents-functions #'osl--before-write nil t)
        (add-hook 'after-save-hook #'osl--remember-task nil t))
    (remove-hook 'write-contents-functions #'osl--before-write t)
    (remove-hook 'after-save-hook #'osl--remember-task t)))

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
(add-hook 'buffer-list-update-hook #'osl--check-selected-buffer)
(add-function :after after-focus-change-function #'osl--focus-change)

(provide 'osl)
;;; osl.el ends here
