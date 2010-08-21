(require 'cp-hl)

(defvar occur-line-started-search nil)

(defun current-word-occur ()
  ""
  (interactive)
  (let ((occur-line-started-search (line-number-at-pos))
        (wd (concat "\\_<" (regexp-quote (downcase (current-word))) "\\_>")))
    (unless (looking-at "\\_<")
      (re-search-backward "\\_<"))
    (codepilot-highlight (point-min) (point-max) wd t t)
    (occur wd)))

(defun current-word-occur-1 ()
  ""
  (interactive)
  (let ((occur-line-started-search (line-number-at-pos))
        (wd (regexp-quote (downcase (current-word)))))
    (unless (looking-at "\\_<")
      (re-search-backward "\\_<"))
    (codepilot-highlight (point-min) (point-max) wd t t)
    (occur wd)))

(global-set-key [(f3)] 'current-word-occur)
(global-set-key [(shift f3)] 'current-word-occur-1)

(defun occur (regexp &optional nlines)
  (interactive (occur-read-primary-args))
  (codepilot-highlight (point-min) (point-max) regexp t t)
  (let ((occur-line-started-search (line-number-at-pos)))
    (occur-1 regexp nlines (list (current-buffer)))))


(defun occur-goto-line ()
  (save-selected-window
    (when occur-line-started-search
      (select-window (get-buffer-window (get-buffer "*Occur*")))
      (goto-char (point-min))
      ;; (re-search-forward (concat "^[ ]*" (int-to-string occur-line-started-search) ":") nil t)
      (save-match-data
        (catch 'loop
          (while (and (not (eobp))
                      (re-search-forward "^[ ]*\\([0-9]+\\):" nil t))
            (when (>= (string-to-number (match-string 1)) occur-line-started-search)
              (forward-line 0)
              (throw 'loop t)
              )))))))

(add-hook 'occur-hook 'occur-goto-line)

(defun occur-mode-goto-occurrence (&optional event)
  "Go to the occurrence the current line describes."
  (interactive (list last-nonmenu-event))
  (let* (regexp
         (pos
          (if (null event)
              ;; Actually `event-end' works correctly with a nil argument as
              ;; well, so we could dispense with this test, but let's not
              ;; rely on this undocumented behavior.
              (occur-mode-find-occurrence)
              (with-current-buffer (window-buffer (posn-window (event-end event)))
                (save-excursion
                  (goto-char (point-min))
                  (when (looking-at "[0-9]+ matches for \"\\(.+\\)\" in buffer:")
                    (setq regexp (match-string 1))))
                (save-excursion
                  (goto-char (posn-point (event-end event)))
                  (occur-mode-find-occurrence)))))
         same-window-buffer-names
         same-window-regexps)

    (mouse-set-point event) ;; brian:
                            ;; prevent it using the occur window to display buffer.
    (pop-to-buffer (marker-buffer pos))
    (goto-char pos)
    ;; brian: update func in mode line immediately.
    (which-func-update)
    (codepilot-highlight (point-min) (point-max) regexp t t)))


(define-key occur-mode-map "0" 'delete-window)
(define-key occur-mode-map "k" 'kill-this-buffer)
(define-key occur-mode-map "q" (lambda ()
                                 (interactive)
                                 (kill-this-buffer)
                                 (delete-window)))


;; Note: this hook shall be called before occur-rename-buffer.
(defun fit-occur-buf ()
  ""
  (interactive)
  ;(fit-window-to-buffer (get-buffer-window (get-buffer "*Occur*")) (/ (frame-height) 2))
  (shrink-window-if-larger-than-buffer (get-buffer-window (get-buffer "*Occur*"))))

(add-hook 'occur-hook 'fit-occur-buf)
(add-hook 'occur-hook 'occur-rename-buffer :append)

(provide 'myocchack)
