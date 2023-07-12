;; TODO: consider enabling lexical-binding for the file.
(require 'cl)

(defun balanced (command)
  "Retain window balance after operation."
  (lexical-let ((x command))
    (lambda ()
      (interactive)
      (funcall x)
      (balance-windows))))

(defun safe-delete-frame () (interactive)
  (if (yes-or-no-p "Delete this frame? ")
      (delete-frame)))

;; Robert Bost's solution taken from emacswiki.org/emacs/TransposeWindows
(defun rotate-windows (arg)
  "Rotate your windows; use the prefix argument to rotate the other direction"
  (interactive "P")
  (if (not (> (count-windows) 1))
      (message "You can't rotate a single window!")
    (let* ((rotate-times (prefix-numeric-value arg))
           (direction (if (or (< rotate-times 0) (equal arg '(4)))
                          'reverse 'identity)))
      (dotimes (_ (abs rotate-times))
        (dotimes (i (- (count-windows) 1))
          (let* ((w1 (elt (funcall direction (window-list)) i))
                 (w2 (elt (funcall direction (window-list)) (+ i 1)))
                 (b1 (window-buffer w1))
                 (b2 (window-buffer w2))
                 (s1 (window-start w1))
                 (s2 (window-start w2))
                 (p1 (window-point w1))
                 (p2 (window-point w2)))
            (set-window-buffer-start-and-point w1 b2 s2 p2)
            (set-window-buffer-start-and-point w2 b1 s1 p1)))))))

(provide 'vi--windows)
