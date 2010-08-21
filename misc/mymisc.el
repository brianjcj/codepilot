
;; some usefull functions. Not directly related to codepilot.

(defun pop-to-mark-command-reverse ()
  "Jump to mark, and pop a new position for mark off the ring.
\(Does not affect global mark ring\)."
  (interactive)
  (if (null (mark t))
      (error "No mark set in this buffer")
    (if (= (point) (mark t))
	(message "Mark popped"))

    (when mark-ring
      (push (copy-marker (mark-marker)) mark-ring)
      (setq mark-ring (nreverse mark-ring))
      (set-marker (mark-marker) (+ 0 (pop mark-ring)) (current-buffer))
      (goto-char (car mark-ring))
      (setq mark-ring (nreverse mark-ring))
      )))

