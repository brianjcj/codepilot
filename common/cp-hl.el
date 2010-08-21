(require 'cp-mark)
(require 'cp-base)

(defun codepilot-highlight (range-beg range-end string regexp case-fold)
  (let ((isearch-string string)
        (isearch-regexp regexp)
        (search-whitespace-regexp nil)
        (isearch-case-fold-search case-fold))
    (isearch-lazy-highlight-new-loop range-beg range-end)))

(defun codepilot-highlight-2 (buf)
  (let ((codepilot-mark-tag 'codepilot-highlight-2))
    (condition-case nil
        (save-excursion
          (set-buffer buf)
          (when codepilot-hl-text-overlay
            (overlay-put codepilot-hl-text-overlay 'face 'codepilot-hl-text-face)
            (overlay-put codepilot-hl-text-overlay 'priority 1001))
          (save-excursion
            (save-restriction
              (widen)
              (codepilot-unmark-all)
              (unless (or (codepilot-string-all-space? codepilot-current-search-text)
                          (< (length codepilot-current-search-text) 2))
                (save-match-data
                  (goto-char (point-min))
                  (cond ((eq codepilot-current-search-type 'id)
                         (while (word-search-forward codepilot-current-search-text nil t)
                           (codepilot-mark-region (match-beginning 0) (match-end 0))
                           ))
                        ((eq codepilot-current-search-type 'part-id)
                         (while (re-search-forward codepilot-current-search-text nil t)
                           (codepilot-mark-region (match-beginning 0) (match-end 0))
                           ))
                        (t
                         (while (search-forward codepilot-current-search-text nil t)
                           (codepilot-mark-region (match-beginning 0) (match-end 0))
                           ))))))))
      (error
       (message "error in codepilot-highlight-2")
       nil
       ))))

(defun codepilot-highlight-3 (text type buf)
  (let ((codepilot-mark-tag 'codepilot-highlight-3)
        (codepilot-mark-face-var 'highlight))
    (save-excursion
      (set-buffer buf)
      (save-excursion
        (save-match-data
          (save-restriction
            (widen)
            (codepilot-unmark-all)

            (unless (or (codepilot-string-all-space? text)
                        (< (length text) 2))
              (goto-char (point-min))
              (cond ((eq type 'id)
                     (while (word-search-forward text nil t)
                       (codepilot-mark-region (match-beginning 0) (match-end 0))
                       ))
                    ((eq type 'part-id)
                     (while (re-search-forward text nil t)
                       (codepilot-mark-region (match-beginning 0) (match-end 0))
                       ))
                    (t
                     (while (search-forward text nil t)
                       (codepilot-mark-region (match-beginning 0) (match-end 0))
                       ))))))))))

(provide 'cp-hl)