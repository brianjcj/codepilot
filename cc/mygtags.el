(require 'cl)
(require 'gtags)
(require 'cp-cc)
(require 'hideshow)

(defvar find-gtag-history nil)

;; (defun mygtags-push-find-gtag-history (tagname)
;;   (let (ind ltail)
;;     (when tagname
;;       (setq ind (position tagname find-gtag-history :test #'string=))
;;       (cond ((null ind)
;;              (setq find-gtag-history (push tagname find-gtag-history))

;;              ;; update [GTags History List] in idlist
;;              (cplist-add-line-to-idlist "^@ GTags History List  "
;;                                           (concat "  = " tagname "\n"))
;;              )
;;             ((= ind 0))
;;             (t
;;              ))
;;       )))

(defun mygtags-add-attribute (tagname local-option option context)
  (save-excursion
    (goto-char (point-max))
    (insert "\n\n")
    (insert (concat " #+default-directory=" default-directory "\n"))
    (when local-option
      (insert " #+local-option=1\n"))
    (insert (concat " #+option=" option "\n"))
    (when context
      (insert " #+context=" context))
    (goto-char (point-min))
    ;; (add-text-properties (point-min) (1+ (point-min)) (list 'local-option local-option
    ;;                                                    'option option
    ;;                                                    'tagname tagname
    ;;                                                    ))
    ))

(defvar mygtags-goto-linenum nil)

(defun gtags-goto-tag (tagname flag &optional other-win)
  (let (option context save prefix buffer lines flag-char hl-type local-option buf-name linenum)
    (setq hl-type 'id)
    (setq save (current-buffer))
    (setq flag-char (string-to-char flag))
    (if (equal flag-char nil)
        (setq flag-char (string-to-char " ")))
    ; Use always ctags-x format.
    (setq option "-x")
    (if (gtags-ignore-casep)
        (setq option (concat option "i")))
    (if (equal 'nearness gtags-path-order)
        (setq option (concat option "N")))
    (if (char-equal flag-char ?C)
        ; replaces the Windows path delimiter (\\) by / which is understood by global.
        (setq context (concat "--from-here=" (number-to-string (gtags-current-lineno)) ":" (replace-in-string (gtags-strip-remote-prefix buffer-file-name) "\\\\" "/")))
      (setq option (concat option flag)))
    (cond
     ((char-equal flag-char ?C)
      (setq prefix "C) "))
     ((char-equal flag-char ?P)
      (setq prefix "F) ")
      (setq hl-type nil)
      (setq tagname (codepilot-trim tagname))
      (when (string-match "^\\(.+?\\):.*?\\([0-9]+\\)$" tagname)
        (setq linenum (string-to-number (match-string-no-properties 2 tagname)))
        (setq tagname (match-string-no-properties 1 tagname))))
     ((char-equal flag-char ?f)
      (setq tagname (expand-file-name tagname))
      (setq prefix "O) "))
     ((char-equal flag-char ?g)
      (setq prefix "G) ")
      (setq hl-type nil))
     ((char-equal flag-char ?I)
      (setq prefix "I) "))
     ((char-equal flag-char ?s)
      (setq prefix "S) "))
     ((char-equal flag-char ?r)
      (setq prefix "R) "))
     (t (setq prefix "D) ")))

    (when current-prefix-arg
      (setq local-option t)
      (setq option (concat option "l"))
      (cd (read-directory-name "-l option is on. Choose the local dir: ")))

    (setq buf-name (if local-option
                       (concat prefix tagname " [" default-directory "]")
                     (concat prefix tagname)))
    (setq buffer (get-buffer buf-name))
    (cond (buffer
           (codepilot-pop-or-switch-buffer buffer)

           (cond ((save-excursion
                    (save-match-data
                      (goto-char (point-min))
                      (not (re-search-forward "^ +[0-9]+|" nil t 2))))
                  ;; (mygtags-push-find-gtag-history tagname)
                  (message "Searching %s ... Done" tagname)
                  ;; (gtags-select-it t)
                  (goto-char (point-min))
                  (forward-line)
                  (let ((mygtags-goto-linenum linenum))
                    (gtags-select-it nil t)) ;; do not delete
                  )))
          (t
           ;; load tag
           (setq buffer (generate-new-buffer (generate-new-buffer-name buf-name)))
           (codepilot-pop-or-switch-buffer buffer)
           (set-buffer buffer)
           ;;
           ;; If project directory is specified, 'Gtags Select Mode' print paths using
           ;; the relative path name from the project directory else absolute path name.
           ;;
           (if (and gtags-rootdir local-option)
               (cd gtags-rootdir)
             (setq option (concat option "a")))
           (message "Searching %s ..." tagname)
           (let (status path-style)
             (setq path-style "--path-style=")
             ;
             ; Path style is defined in gtags-path-style:
             ;   root: relative from the root of the project (Default)
             ;   relative: relative from the current directory
             ;	  absolute: absolute from the root directory
             ; In TRAMP mode, 'root' is automatically converted to 'relative'.
             ;
             (cond
              ((equal gtags-path-style 'absolute)
               (setq path-style (concat path-style "absolute")))
              ((equal gtags-path-style 'relative)
               (setq path-style (concat path-style "relative")))
              ((equal gtags-path-style 'root)
               (setq path-style (concat path-style "relative"))
               (if (not (file-remote-p default-directory))
                   (let (rootdir)
                     (if gtags-rootdir
                         (setq rootdir gtags-rootdir)
                       (setq rootdir (gtags-get-rootpath)))
                     (if rootdir (cd rootdir))))))
             (if (equal flag "f")
                 (setq tagname (gtags-strip-remote-prefix tagname)))
             ;
             ; Since Emacs 25.1, let-bind additional environment variables to
             ; `process-environment' are sent to the remote process.
             ; 'gtags-visit-rootdir requires this facility.
             ;
             (let* ((gtagsroot (gtags-strip-remote-prefix (getenv "GTAGSROOT")))
                    (process-environment
                     (if gtagsroot
                         (cons (concat "GTAGSROOT=" gtagsroot) process-environment)
                       process-environment)))
               (setq status (if (equal flag "C")
                                (process-file gtags-global-command nil t nil option path-style "--encode-path=\" \t\"" context tagname)
                              (process-file gtags-global-command nil t nil option path-style "--encode-path=\" \t\"" tagname)))
               )
             (if (not (= 0 status))
                 (progn (message (buffer-substring (point-min)(1- (point-max))))
                        ;;(gtags-pop-context)
                        )
               (goto-char (point-min))
               (setq lines (count-lines (point-min) (point-max)))
               (cond
                ((= 0 lines)
                 (cond
                  ((char-equal flag-char ?P)
                   (message "%s: path not found" tagname))
                  ((char-equal flag-char ?g)
                   (message "%s: pattern not found" tagname))
                  ((char-equal flag-char ?I)
                   (message "%s: token not found" tagname))
                  ((char-equal flag-char ?s)
                   (message "%s: symbol not found" tagname))
                  (t
                   (message "%s: tag not found" tagname)))
                 ;; (gtags-pop-context)
                 (kill-buffer buffer)
                 (set-buffer save))
                (t
                 ;; (mygtags-push-find-gtag-history tagname)

                 (cplist-add-line-to-idlist "^@ GTags List  "
                                            (concat "  " (buffer-name buffer)  "\n"))
                 (gtags-select-mode)
                 (with-modify-in-readonly
                  (mygtags-refine-output)
                  (mygtags-add-attribute tagname local-option option context)
                  (run-hooks 'mygtags-output-done-hook)
                  (mygtags-next-file))
                 ;; serial number for sort by the create time.
                 (cptree-set-buffer-local-serial-number)))
               (when (= lines 1)
                 (message "Searching %s ... Done" tagname)
                 ;; (gtags-select-it t)
                 (let ((mygtags-goto-linenum linenum))
                   (gtags-select-it nil t)) ;; do not delete
                 )))))))



(defun mygtags-unfold ()
  (interactive)
  (let (ret str pos)
    (cond ((save-excursion
             (forward-line 0)
             (looking-at "^[^\s\n]+"))
           (setq pos (line-end-position)))
          (t
           (setq pos (point))))
    (dolist (o (overlays-at pos))
      (when (cptree-delete-overlay o 'cptree)
        (setq ret t)))
    ret))

(defun mygtags-fold ()
  (interactive)
  (let (b e str)
    (when (looking-at "^[ \t]*$")
      (skip-chars-backward " \t\n")
      (backward-char))
    (when (looking-at "\n")
      (backward-char))
    (save-excursion
      (save-match-data
        (forward-line 0)
        (unless (looking-at "^[^\s\n]+")
          (re-search-backward "^[^\s\n]+" nil t))
        (setq b (line-end-position))
        (forward-line)
        (if (re-search-forward "\\(^[ \t]*$\\|^[^\s\n]+\\)" nil t)
            (setq e (1- (line-beginning-position)))
          (setq e (point-max)))
        (cptree-hide-region b e 'cptree)))))


(defun mygtags-toggle-folding ()
  (interactive)
  (let ((case-fold-search t))
    (unless (mygtags-unfold)
      (mygtags-fold))))


(defun mygtags-fold-all ()
  ""
  (interactive)
  (let (pos-p)
    (save-excursion
      (save-match-data
        (cptree-unfold-all)
        (goto-char (point-min))
        (when (re-search-forward "^[^\s\n]+" nil t)
          (setq pos-p (line-end-position))
          (while (re-search-forward "^[^\s\n]+" nil t)
            (cptree-hide-region pos-p (1- (line-beginning-position)) 'cptree)
            (setq pos-p (line-end-position)))
          (when (re-search-forward "^$" nil t)
            (cptree-hide-region pos-p (point) 'cptree)))))))


(defun gtags-select-it (delete &optional not-mark)
  (let (line file sym valid goto-ln?)
    ;; get context from current tag line
    (beginning-of-line)

    (if (looking-at "\\([^ \t]+\\)[ \t]+\\([0-9]+\\)[ \t]\\([^ \t]+\\)[ \t]")
        (progn
          (setq sym (gtags-match-string 1))
          (setq line (string-to-number (gtags-match-string 2)))
          (setq file (gtags-match-string 3))
          (setq goto-ln? (eq ?F (aref (buffer-name) 0)))
          (setq valid t))
      (if (looking-at "^[^\s\n]+$")
          (progn
            (end-of-line)
            (mygtags-toggle-folding))

        (when (looking-at "^  *\\([0-9]+\\)|")
          (setq line (string-to-number (match-string-no-properties 1)))
          ;; (setq sym (get-text-property (point-min) 'tagname))
          (setq sym (second (split-string (buffer-name))))
          (setq file (save-excursion
                       (re-search-backward "^\\([^ ]+\\)$" nil t)
                       (match-string-no-properties 1)
                       ))
          (setq goto-ln? (eq ?F (aref (buffer-name) 0)))
          (setq valid t))))

    (if (not valid)
        (progn
          ;; (gtags-pop-context)
          nil)
      ;;
      ;; Why should we load new file before killing current-buffer?
      ;;
      ;; If you kill current-buffer before loading new file, current directory
      ;; will be changed. This might cause loading error, if you use relative
      ;; path in [GTAGS SELECT MODE], because emacs's buffer has its own
      ;; current directory.
      ;;
      (let ((prev-buffer (current-buffer)))
        ;; move to the context
        ;; (if gtags-read-only (find-file-read-only file) (find-file file))
        (let ((buf (find-file-noselect file)))
          (when buf
            (let ((inhibit-codepilot-pre-pop-or-switch-buffer-hook not-mark))
              (codepilot-pop-or-switch-buffer buf)
              (when not-mark
                (bury-buffer prev-buffer)))))

        (if delete (kill-buffer prev-buffer)))
      (setq gtags-current-buffer (current-buffer))

      (if (numberp mygtags-goto-linenum)
          (codepilot-goto-line mygtags-goto-linenum)
        (unless goto-ln?
          (codepilot-goto-line line)))

      (which-func-update)
      (codepilot-search-and-hl-text sym nil 'id)
      (gtags-mode 1))))

(defface mygtags-linenum-face
    '((default (:inherit region))
      (((class color) (background light)) (:background "darkseagreen2"))
      (((class color) (background dark)) (:background "DarkSlateGrey" :foreground "white"))
      )
  "Cpfilter edit entry face."
  :group 'coldpilot
  )

(defun mygtags-next-visible-file-line ()
  (let (s-res)
    (while (and (setq s-res (re-search-forward "^[^\s\n]+" nil t))
                (codepilot-at-tagged-overlay-p (point) 'mygtags)))
    s-res))

(defun mygtags-next-file ()
  (interactive)
  (let (pos)
    ;; (setq pos (next-property-change (point)))
    (save-excursion
      (save-match-data
        (forward-line 0)
        (when (mygtags-next-visible-file-line)
          (setq pos (point)))))
    (if pos
        (goto-char pos)
      (goto-char (point-min))
      (mygtags-next-visible-file-line)
      (message "Wrapped!"))
    (end-of-line)
    (when (cptree-point-at-fold-p (point))
      (mygtags-unfold))
    (forward-line)))


(defun mygtags-list-sort-by-create ()
  ""
  (interactive)

  (cplist-sort-frame
   "@ GTags List  "
   "^$"
   cptree-serial-number
   'gtags-select-mode
   m-list
   (when m-list
     (setq m-list (sort m-list (lambda (a b)
                                 (>  (car a)  (car b))
                                 )))

     (dolist (b1 m-list)
       (insert "  " (cdr b1) "\n"))))
  (setq cplist-query-sort-type 'create))

;; re-structure the global output
(defun mygtags-parse-output ()
  "Assume the point is at the beginning of the line"
  (save-excursion
    (save-match-data
      (let ((case-fold-search t)
            (ll (list))
            (last-fn "")
            (cur-fl (list))
            entry pos fn cur-fl
            )
        (while (re-search-forward "^\\([^ ]+\\) +\\([0-9]+\\) \\([^ ]+\\)" nil t)
          (setq fn (match-string-no-properties 3))
          (setq entry (list (match-string-no-properties 2)
                            (buffer-substring-no-properties (point) (line-end-position))
                            (match-string-no-properties 1)))
          (if (string= fn last-fn)
              (progn
                (push entry cur-fl))
            (push (list last-fn (nreverse cur-fl)) ll)
            (setq cur-fl (list entry))
            (setq last-fn fn)))
        (push (list last-fn (nreverse cur-fl)) ll)
        (nreverse ll)))))


(defun mygtags-refine-output ()
  (goto-char 0)

  (let ((ll (mygtags-parse-output)))
    (erase-buffer)
    (save-excursion
      (dolist (ff (cdr ll))
        (insert (car ff) "\n")
        (dolist (entry (second ff))
          (insert (format " %5d|" (string-to-number (car entry))))
          (insert (second entry) "\n")))
      (insert "\n"))))

;; make gtags select-mode
(defun gtags-select-mode ()
  "Major mode for choosing a tag from tags list.

Select a tag in tags list and move there.
	\\[gtags-select-tag]
Move to previous point on the stack.
	\\[gtags-pop-stack]

Key definitions:
\\{gtags-select-mode-map}
Turning on Gtags-Select mode calls the value of the variable
`gtags-select-mode-hook' with no args, if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (use-local-map gtags-select-mode-map)
  (setq buffer-read-only t
	truncate-lines t
        major-mode 'gtags-select-mode
        mode-name "Gtags-Select")
  (setq gtags-current-buffer (current-buffer))
  (goto-char (point-min))
  (modify-syntax-entry ?/ ".")
  (setq-local font-lock-defaults
            '(gtags-select-mode-font-lock-keywords nil t))
  (message "[GTAGS SELECT MODE] %d lines" (count-lines (point-min) (point-max)))
  (run-hooks 'gtags-select-mode-hook))

(defun gtags-current-token ()
  (thing-at-point 'symbol t))


(defun mygtags-insert-gtag ()
  ""
  (interactive)
  (let (input)
    (setq input (completing-read "GTag: " 'gtags-completing-gtags
                                 nil nil nil gtags-history-list))
    (insert input)))

(defun mygtags-insert-gsym ()
  ""
  (interactive)
  (let (input)
    (setq input (completing-read "GSym: " 'gtags-completing-gsyms
                                 nil nil nil gtags-history-list))
    (insert input)))


(defvar mygtags-auto-flush-regexp nil)
(defvar mygtags-auto-flush-on? nil)

(defvar mygtags-auto-show-only-regexp nil)
(defvar mygtags-auto-show-only-on? nil)

(require 'desktop)
(cl-pushnew 'mygtags-auto-flush-regexp desktop-globals-to-save)
(cl-pushnew 'mygtags-auto-flush-on? desktop-globals-to-save)
(cl-pushnew 'mygtags-auto-show-only-regexp desktop-globals-to-save)
(cl-pushnew 'mygtags-auto-show-only-on? desktop-globals-to-save)


(defun mygtags-show-all ()
  (interactive)
  (remove-overlays (point-min) (point-max) 'tag 'mygtags))

(defun mygtags-show-files-if (func)
  (save-excursion
    (save-match-data
      (let ((case-fold-search t)
            b e loo o)
        (remove-overlays (point-min) (point-max) 'tag 'mygtags)

        (setq o (make-overlay (point-min) (point-max)))
        (overlay-put o 'tag 'mygtags)
        (overlay-put o 'invisible t)

        (goto-char (point-min))
        (setq loo (re-search-forward "^[^\s\n]\\{1\\}" nil t))
        (while loo
          (forward-line 0)
          (setq b (point))

          (cond ((funcall func)
                 ;; show it
                 (forward-line)
                 (if (re-search-forward "^[^\s\n]\\{1\\}" nil t)
                     (progn
                       (setq e (1- (point))))
                   (setq e (progn (re-search-forward "^$") (point)))
                   (setq loo nil))
                 (remove-overlays b e 'tag 'mygtags)
                 )
                (t
                 (forward-line)
                 (setq loo (re-search-forward "^[^\s\n]\\{1\\}" nil t)))))))))

(defun mygtags-flush-files (ss)
  (interactive "sHide pathes contain (regex) : ")
  (save-excursion
    (save-match-data
      (let ((case-fold-search t)
            b e loo o)

        (goto-char (point-min))
        (setq loo (re-search-forward "^[^\s\n]\\{1\\}" nil t))
        (while loo
          (forward-line 0)
          (setq b (point))

          (cond ((re-search-forward
                  (if mygtags-auto-flush-on?
                      (concat ss "\\|" mygtags-auto-flush-regexp)
                    ss)
                  (line-end-position) t)
                 (forward-line)
                 (if (re-search-forward "^[^\s\n]\\{1\\}" nil t)
                     (progn
                       (setq e (1- (point))))
                   (setq e (progn (re-search-forward "^$") (point)))
                   (setq loo nil))
                 (setq o (make-overlay b e))
                 (overlay-put o 'tag 'mygtags)
                 (overlay-put o 'invisible t))
                (t
                 (forward-line)
                 (setq loo (re-search-forward "^[^\s\n]\\{1\\}" nil t)))))))))

(defun mygtags-keep-files (ss)
  (interactive "sShow only pathes contain (regex) : ")
  (mygtags-show-files-if (lambda ()
                           (let (pos)
                             (setq pos (point))
                             (and (re-search-forward
                                   ss
                                   (line-end-position) t)
                                  (or (not mygtags-auto-show-only-on?)
                                      (progn
                                        (goto-char pos)
                                        (re-search-forward
                                         mygtags-auto-show-only-regexp
                                         (line-end-position) t)))))))
  (mygtags-auto-flush))

(defun mygtags-auto-flush ()
  (interactive)
  (when (and mygtags-auto-flush-on? mygtags-auto-flush-regexp)
    (mygtags-flush-files mygtags-auto-flush-regexp)))

(add-hook 'mygtags-output-done-hook 'mygtags-auto-flush)

(defun mygtags-auto-show-only ()
  (interactive)
  (when (and mygtags-auto-show-only-on? mygtags-auto-show-only-regexp)
    (mygtags-keep-files mygtags-auto-show-only-regexp)))

(add-hook 'mygtags-output-done-hook 'mygtags-auto-show-only)


(defun mygtags-set-auto-flush-regexp (regex)
  (interactive
   (list
    (read-string "Regexp: " mygtags-auto-flush-regexp nil)))
  (if (string= regex "")
      (setq mygtags-auto-flush-regexp nil)
    (setq mygtags-auto-flush-regexp regex)))

(defun mygtags-set-auto-show-only-regexp (regex)
  (interactive
   (list
    (read-string "Regexp: " mygtags-auto-show-only-regexp nil)))
  (if (string= regex "")
      (setq mygtags-auto-show-only-regexp nil)
    (setq mygtags-auto-show-only-regexp regex)))


(defun mygtags-switch-to-gtags-buf ()
  (interactive)
  (let (input cands)
    (setq cands (mapcar (lambda (x) (buffer-name x))
                        (cplist-buffer-list-sort 'gtags-select-mode 'cptree-serial-number)))
    ;; (setq input (completing-read "Gtags Buffer: " cands nil t))  ; hard to turn off sort
    (setq input (consult--read cands :prompt "Gtags Buffer: " :sort nil))
    (codepilot-pop-or-switch-buffer input)))


(defvar mygtags-select-menu
  '("GtagSelect"
    ["Toggle fold" mygtags-toggle-folding t]
    ["Fold all" mygtags-fold-all t]
    ["Unfold all" cptree-unfold-all t]
    "-"
    ["Next file" mygtags-next-file t]
    "-"
    ["Flush files" mygtags-flush-files t]
    ["Keep files" mygtags-keep-files t]
    ["Show all files" mygtags-show-all t]
    "-"
    ["Auto flush" (lambda ()
                    (interactive)
                    (setq mygtags-auto-flush-on? (not mygtags-auto-flush-on?))
                    )
     :style toggle :selected mygtags-auto-flush-on?]
    ["Flush auto items" (lambda ()
                          (interactive)
                          (let ((mygtags-auto-flush-on? t))
                            (mygtags-auto-flush)))
     :active mygtags-auto-flush-regexp]
    ["Set auto flush regexp" mygtags-set-auto-flush-regexp t]

    "-"
    ["Show only" (lambda ()
                    (interactive)
                    (setq mygtags-auto-show-only-on? (not mygtags-auto-show-only-on?))
                    )
     :style toggle :selected mygtags-auto-show-only-on?]
    ["Show only auto items" (lambda ()
                          (interactive)
                          (let ((mygtags-auto-show-only-on? t))
                            (mygtags-auto-show-only)))
     :active mygtags-auto-show-only-regexp]
    ["Set auto show-only regexp" mygtags-set-auto-show-only-regexp t]

    ))

(easy-menu-define mygtags-select-menu-symbol
                  gtags-select-mode-map
                  "Mygtags-select menu"
                  mygtags-select-menu)



(define-key gtags-mode-map [mouse-3] 'gtags-find-tag-by-event)
(define-key gtags-mode-map [mouse-2] (lambda (e)
                                       (interactive "e")
                                       (mouse-set-point e)
                                       (hs-toggle-hiding)))

(define-key gtags-select-mode-map [mouse-3] 'gtags-select-tag-by-event)
(define-key gtags-select-mode-map [tab] 'mygtags-next-file)
(define-key gtags-select-mode-map "," 'codepilot-previous-buffer)
(define-key gtags-select-mode-map "." 'codepilot-forward-buffer)
(define-key gtags-select-mode-map "k" 'kill-buffer)
(define-key gtags-select-mode-map "`" 'cplist-minimize/restore-sidebar)
(define-key gtags-select-mode-map "1" 'delete-other-windows)

(define-key gtags-select-mode-map "z" 'mygtags-fold-all)
(define-key gtags-select-mode-map "u" 'cptree-unfold-all)

(define-key gtags-select-mode-map "\M-." 'gtags-find-tag)

(easy-menu-define mygtags-menu-symbol
  ;; (list gtags-mode-map codepilot-ro-mode-map)
  gtags-mode-map
  "Menu for Gtags!"
  '("Gtags"
    ["Find tag" gtags-find-tag t ]
    ["Find rtag" gtags-find-rtag t ]
    ["Find symbol" gtags-find-symbol t ]
    ["Parse file" gtags-parse-file t]
    "-"
    ["Find file" gtags-find-file t]
    ;; ["Find file (Anything)" anything-gtags-path t]
    "-"
    ["Find with grep" gtags-find-with-grep t]
    ["Find with idutils" gtags-find-with-idutils t]
    "-"
    ["Insert gtag" mygtags-insert-gtag t]
    ["Insert gsym" mygtags-insert-gsym t]
    "-"
    ["Visit-rootdir" gtags-visit-rootdir t]
    ))


(add-hook 'gtags-select-mode-hook (lambda()(interactive)(codepilot-ro-mode 1)))

;; (require 'desktop)
;; (cl-pushnew 'find-gtag-history desktop-globals-to-save)
;; (cl-pushnew 'find-tag-history desktop-globals-to-save)


(defun codepilot-gtags-save-list-to-file (file)
  (interactive "F")
  (let ((bufs (cplist-buffer-list-sort 'gtags-select-mode 'cptree-serial-number))
        jl)
    (dolist (buf bufs)
      (let ((jo (json-new-object)))
        (setq jo (json-add-to-object jo "name" (buffer-name buf)))
        (with-current-buffer buf
          (setq jo (json-add-to-object jo "dir" default-directory))
          (setq jo (json-add-to-object
                    jo "content"
                    (save-restriction
                      (widen)
                      (buffer-substring-no-properties (point-min) (point-max))))))
        (push jo jl)))
    (with-temp-file file
      (erase-buffer)
      (insert (json-encode jl)))))


(defun codepilot-gtags-restore-list (file)
  (interactive "f")
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((jl (json-read)))
      (seq-doseq (item jl)
        (let (name content dir buf)
          (dolist (info item)
            (set (car info) (cdr info)))
          (setq buf (get-buffer-create name))
          (with-current-buffer buf
            (insert content)
            (gtags-select-mode)
            (setq-local default-directory dir)
            (cptree-set-buffer-local-serial-number)
            (goto-char (point-min))
            (mygtags-next-file))))))
  (cplist-update))


(defvar gtags-select-mode-font-lock-keywords
  '(
    ("\\(^ +[0-9]+\\)" . 'mygtags-linenum-face)
    ("\\(^ #\\+[^\n]+\\)$" . 'font-lock-keyword-face)
    ("\\(^[^\s\n].+\\)$" . 'font-lock-warning-face))
  "Default expressions to highlight in gtags select mode mode.")


(provide 'mygtags)


