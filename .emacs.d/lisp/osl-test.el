;;; osl-test.el --- Integration checks for OSL -*- lexical-binding: t; -*-
(require 'ert)
(require 'osl)
(require 'markdown-mode)

(ert-deftest osl-markdown-follows-links-from-their-labels ()
  (let ((osl-directory (make-temp-file "osl-markdown-" t)) task-buffer)
    (unwind-protect
        (progn
          (osl-test--init)
          (osl--run "capture" "--title" "Target")
          (with-temp-buffer
            (gfm-mode)
            (insert "[Arbitrary label](osl:1)")
            (goto-char 5)
            (markdown-follow-thing-at-point nil))
          (setq task-buffer (find-buffer-visiting (osl-resolve "1")))
          (should task-buffer)
          (should-not (osl--markdown-follow "https://example.org/"))
          (should-not (osl--markdown-follow "osl:01")))
      (when (buffer-live-p task-buffer) (kill-buffer task-buffer))
      (delete-directory osl-directory t))))

(ert-deftest osl-browser-protocol-resolves-only-canonical-references ()
  (let (opened)
    (cl-letf (((symbol-function 'osl-open) (lambda (reference) (setq opened reference))))
      (should-not (org-protocol-check-filename-for-protocol "org-protocol://osl?reference=osl%3A280" nil nil))
      (should (equal opened "osl:280")))
    (should-error (osl-protocol-open '(:reference "file:///etc/passwd")) :type 'user-error)
    (should-error (osl-protocol-open nil) :type 'user-error)))

(defun osl-test--init ()
  "Initialize a temporary store with a test board configuration."
  (with-temp-file (expand-file-name ".board.json" osl-directory)
    (insert "{\"columns\":[\"00-inbox\",\"10-next\",\"90-archive\"],"
            "\"spaces\":[\"home\",\"work\"],\"captureColumn\":\"00-inbox\","
            "\"defaultSpace\":\"home\",\"archiveColumn\":\"90-archive\"}"))
  (osl--run "init"))

(ert-deftest osl-emacs-capture-resolve-and-follow ()
  (let* ((osl-directory (make-temp-file "osl-emacs-" t))
         task-buffer filename)
    (unwind-protect
        (progn
          (osl-test--init)
          (osl-capture "Исходное название" "home")
          (setq task-buffer (current-buffer) filename buffer-file-name)
          (should osl-task-mode)
          (should-not (string-match-p "\\[\\(?:created\\|updated\\):" (buffer-string)))
          (should (equal (alist-get 'spaces (osl--config)) '("home" "work")))
          (save-excursion
            (goto-char (point-min))
            (search-forward "[id:1]\n")
            (replace-match "[id:1] " t t))
          (osl-copy-link)
          (should (string-match-p "\\[\\[osl:1\\]\\[Исходное название\\]\\]" (current-kill 0)))
          (insert "\nA source link: [other](https://example.invalid/)\n")
          (save-buffer)
          (should (string-match-p "0 validation issues" (osl--run "validate")))
          (let ((moved (expand-file-name "90-archive/renamed.md" osl-directory)))
            (rename-file filename moved)
            (with-temp-file moved
              (insert-file-contents moved)
              (goto-char (point-min))
              (while (search-forward "space::home" nil t) (replace-match "space::work" t t)))
            (set-buffer-modified-p nil)
            (kill-buffer task-buffer)
            (setq task-buffer nil)
            (should (equal (osl-resolve "1") moved))
            (with-temp-buffer
              (org-mode)
              (insert "[[osl:1][Arbitrary display text after a rename]]")
              (goto-char (point-min))
              (org-open-at-point))
            (setq task-buffer (find-buffer-visiting moved))
            (should task-buffer)
            (should-error (osl-resolve "01") :type 'user-error)
            (with-current-buffer task-buffer
              (goto-char (point-max))
              (insert "[self](osl:1)")
              (backward-char 3)
              (osl-open-link-at-point)
              (set-buffer-modified-p nil))))
      (when (buffer-live-p task-buffer)
        (with-current-buffer task-buffer (set-buffer-modified-p nil))
        (kill-buffer task-buffer))
      (delete-directory osl-directory t))))

(ert-deftest osl-emacs-reports-ambiguous-link ()
  (let ((osl-directory (make-temp-file "osl-emacs-duplicate-" t)))
    (unwind-protect
        (progn
          (osl-test--init)
          (osl--run "capture" "--title" "Duplicate test")
          (copy-file (expand-file-name "00-inbox/1.md" osl-directory)
                     (expand-file-name "90-archive/copy.md" osl-directory))
          (should-error (osl-resolve "1") :type 'user-error))
      (delete-directory osl-directory t))))
