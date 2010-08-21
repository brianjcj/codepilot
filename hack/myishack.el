
;; hack isearch

(defun isearch-yank-current-word ()
  "Pull current word into search string."
  (interactive)
  (save-match-data
    (if isearch-forward
        (unless (looking-at "\\_<")
          (re-search-backward "\\_<"))
        (unless (looking-at "\\_>")
          (re-search-forward "\\_>"))))
  (isearch-yank-string (current-word)))

(define-key isearch-mode-map "\C-d" 'isearch-yank-current-word)
(define-key isearch-mode-map "\C-e" 'isearch-repeat-backward)
(define-key isearch-mode-map "\C-a" 'isearch-repeat-backward)
(define-key isearch-mode-map "\C-k" 'isearch-repeat-backward)
;; note: "\C-j" is bound to isearch-printing-char previously.
(define-key isearch-mode-map "\C-j" 'isearch-repeat-forward)

(provide 'myishack)
