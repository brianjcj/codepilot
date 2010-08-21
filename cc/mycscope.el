;; Copyright (C) 2010  Brian Jiang

;; Author: Brian Jiang <brianjcj@gmail.com>
;; Keywords: Programming
;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(eval-when-compile
  (require 'cl))

(require 'cp-cc)
(require 'xcscope)


(defun mycscope-cplist-sort-query-by-create ()
  ""
  (interactive)

  (cplist-sort-frame
   "@ CScope Query List  "
   "^$"
   cptree-serial-number
   'cscope-list-entry-mode
   m-list
   (when m-list
     (setq m-list (sort m-list (lambda (a b)
                                 (>  (car a)  (car b)))))
     
     (dolist (b1 m-list)
       (insert "  " (cdr b1) "\n"))))
  (setq cplist-query-sort-type 'create))

(defvar cscope-jump-single-match nil)

;; may need to update later.
(defun cscope-single-match? ()
  (let (pos)
    (save-excursion
      (save-match-data
        (codepilot-goto-line 7)
        (when (looking-at "^---------------")
          (unless (save-excursion
                    (forward-line)
                    (re-search-forward "^-------------" nil t))
            (forward-line -1)
            (setq pos (point))))))
    pos))


(defun cscope-mouse-select-entry-other-window (event)
  "Display the entry over which the mouse event occurred, select the window."
  (interactive "e")
  (let ((ep (cscope-event-point event))
	(win (cscope-event-window event))
	buffer file line-number window)
    (if ep
        (cond ((progn ;; save-selected-window
                 (select-window win)
                 (progn ;;save-excursion
                   (goto-char ep)
                   (forward-line 0)
                   (cond
                    ((looking-at "^\\*\\*\\* ")
                     (let (b e pos ret)
                       (end-of-line)
                       (setq pos (point))
                       (dolist (o (overlays-at pos))
                         (cptree-delete-overlay o 'cptree)
                         (setq ret t))
                            
                       (unless ret
                         (save-excursion
                           (end-of-line)
                           (setq b (point))
                           (cond ((or (re-search-forward "^\\*\\*\\* " nil t)
                                      (re-search-forward "^---------------" nil t))
                                  (forward-line 0)
                                  (setq e (1- (point))))
                                 (t
                                  (setq e (point-max))))
                           (cptree-hide-region b e 'cptree))))
                     t)
                    (t nil)))))
              (t
               (progn
                 (setq buffer (window-buffer win)
                       file (get-text-property ep 'cscope-file buffer)
                       line-number (get-text-property ep 'cscope-line-number buffer))
                 (select-window win)
                 (setq window (cscope-show-entry-internal file line-number t))
                 (if (windowp window)
                     (select-window window)))))
      (message "No entry found at point."))))

(defun cscope-rename-buffer (&optional unique-p interactive-p)
  (interactive "P\np")
  ;; (with-current-buffer
  ;;     (if (eq major-mode 'cscope-list-entry-mode) (current-buffer) (get-buffer "*cscope*"))
  ;;  
  ;;   ;; serial number for sort by the create time.
  ;;   (make-local-variable 'cptree-serial-number)
  ;;   (setq cptree-serial-number cptree-serial-no-last)
  ;;   (setq cptree-serial-no-last (1+ cptree-serial-no-last))
  ;;  
  ;;   (let (name
  ;;         b e killed)
  ;;     (save-excursion
  ;;       (goto-char (point-min))
  ;;       (move-to-column 8)
  ;;       (setq b (point))
  ;;       (end-of-line)
  ;;       (setq e (point))
  ;;       (setq name (buffer-substring-no-properties b e)))
  ;;  
  ;;     ;;   symbol: Fprocess_send_string
  ;;     ;;   global definition: fprocess_send_string
  ;;     ;;   functions called by: STRING_INTERVALS
  ;;     ;;   functions calling: STRING_INTERVALS
  ;;     ;;   text string: STRING_INTERVALS
  ;;     ;;   files #including file: lisp.h
  ;;     ;;   symbol: STRING_INTERVALS
  ;;     ;;   egrep pattern: STRING_INTERVALS
  ;;     ;;   file: lisp.h
  ;;  
  ;;     (cond ((string-match "^symbol" name)
  ;;            (setq name (replace-match "s" nil nil name)))
  ;;           ((string-match "^global definition" name)
  ;;            (setq name (replace-match "g" nil nil name)))
  ;;           ((string-match "^functions called by" name)
  ;;            (setq name (replace-match "n" nil nil name)))
  ;;           ((string-match "^functions calling" name)
  ;;            (setq name (replace-match "u" nil nil name)))
  ;;           ((string-match "^text string" name)
  ;;            (setq name (replace-match "t" nil nil name)))
  ;;           ((string-match "^file:" name)
  ;;            (setq name (replace-match "f" nil nil name)))
  ;;           ((string-match "^files #including file" name)
  ;;            (setq name (replace-match "i" nil nil name)))
  ;;           ((string-match "^egrep pattern" name)
  ;;            (setq name (replace-match "e" nil nil name)))
  ;;           )
  ;;     (when (get-buffer name)
  ;;       (kill-buffer name)
  ;;       (setq killed t))
  ;;     
  ;;     (rename-buffer name (or unique-p (not interactive-p)))
  ;;  
  ;;     (when (get-buffer-window cplist-buf-name)
  ;;       (with-current-buffer (get-buffer cplist-buf-name)
  ;;         (with-modify-in-readonly
  ;;          (goto-char (point-min))
  ;;          (forward-line)
  ;;          (when killed
  ;;            (save-match-data
  ;;              (when (re-search-forward (concat "  " (regexp-quote name) "\n") nil t)
  ;;                (forward-line -1)
  ;;                (kill-line 1))))
  ;;          (goto-char (point-min))
  ;;          (forward-line 2)
  ;;          (insert "  " name "\n")
  ;;          
  ;;          )))
  ;;     ))
  
  )

;; (add-hook 'cscope-list-entry-hook 'cscope-rename-buffer)

(defun cscope-process-sentinel (process event)
  "Sentinel for when the cscope process dies."
  (let* ( (buffer (process-buffer process)) window update-window
         (done t) (old-buffer (current-buffer))
	 (old-buffer-window (get-buffer-window old-buffer)) )
    (set-buffer buffer)
    (save-window-excursion
      (save-excursion
	(if (or (and (setq window (get-buffer-window buffer))
		     (= (window-point window) (point-max)))
		(= (point) (point-max)))
	    (progn
	      (setq update-window t)))
	(delete-process process)
	(let (buffer-read-only continue)
	  (goto-char (point-max))
	  (if (and cscope-suppress-empty-matches
		   (= cscope-output-start (point)))
	      (delete-region cscope-item-start (point-max))
	    (progn
	      (if (not cscope-start-directory)
		  (setq cscope-start-directory default-directory))
	      (insert cscope-separator-line)))
	  (setq continue
		(and cscope-search-list
		     (not (and cscope-first-match
			       cscope-stop-at-first-match-dir
			       (not cscope-stop-at-first-match-dir-meta)))))
	  (if continue
	      (setq continue (cscope-search-one-database)))
	  (if continue
	      (progn
		(setq done nil))
	    (progn
	      (insert "\nSearch complete.")
	      (if cscope-display-times
		  (let ( (times (current-time)) cscope-stop elapsed-time )
		    (setq cscope-stop (+ (* (car times) 65536.0)
					 (car (cdr times))
					 (* (car (cdr (cdr times))) 1.0E-6)))
		    (setq elapsed-time (- cscope-stop cscope-start-time))
		    (insert (format "  Search time = %.2f seconds."
				    elapsed-time))))
	      (setq cscope-process nil)
	      ;; (if cscope-running-in-xemacs  ;; brian
	      ;;     (setq modeline-process ": Search complete"))
	      (if cscope-start-directory
		  (setq default-directory cscope-start-directory))
	      (if (not cscope-first-match)
		  (message "No matches were found.")))))
	(set-buffer-modified-p nil)))
    (if (and done cscope-first-match-point update-window)
	(if window
	    (set-window-point window cscope-first-match-point)
	  (goto-char cscope-first-match-point)))
    (cond
     ( (not done)		;; we're not done -- do nothing for now
       (if update-window
	   (if window
	       (set-window-point window (point-max))
	     (goto-char (point-max)))))
     ( cscope-first-match
       (if cscope-display-cscope-buffer
           (if (and cscope-edit-single-match (not cscope-matched-multiple))
               (let ((cscope-jump-single-match t))
                 (cscope-show-entry-internal(car cscope-first-match)
                                            (cdr cscope-first-match) t)))
         (cscope-select-entry-specified-window old-buffer-window))))
    (if (and done (eq old-buffer buffer) cscope-first-match)
	(cscope-help))
    (set-buffer old-buffer)))


;; deal with windows layout
(defun cscope-show-entry-internal (file line-number 
					&optional save-mark-p window arrow-p)
  "Display the buffer corresponding to FILE and LINE-NUMBER
in some window.  If optional argument WINDOW is given,
display the buffer in that WINDOW instead.  The window is
not selected.  Save point on mark ring before goto
LINE-NUMBER if optional argument SAVE-MARK-P is non-nil.
Put `overlay-arrow-string' if arrow-p is non-nil.
Returns the window displaying BUFFER."
  (let (buffer old-pos old-point new-point forward-point backward-point
	       line-end line-length cscope-symbol-local old-buf)

    ;; brian
    (setq cscope-symbol-local (substring (buffer-name) 3))
    (setq old-buf (current-buffer))
    
    (if (and (stringp file)
	     (integerp line-number))
	(progn
	  (unless (file-readable-p file)
	    (error "%s is not readable or exists" file))
	  (setq buffer (find-file-noselect file))
	  (if (windowp window)
	      (set-window-buffer window buffer)
	    ;; (setq window (display-buffer buffer))
            (multiple-value-bind (ret sidebar code-win bottom-win)
                (codepilot-window-layout-wise)

              ;;                 (save-selected-window
              ;;                   (select-window code-win)
              ;;                   (unless inhibit-codepilot-pre-pop-or-switch-buffer-hook
              ;;                     (run-hooks 'codepilot-pre-pop-or-switch-buffer-hook)))

              (cond ((or cscope-jump-single-match
                         (cscope-single-match?))
                     (when code-win
                       (select-window code-win))
                     (switch-to-buffer buffer))
                    (t
                     (case ret
                       ((:window-layout-1 :window-layout-1&1)
                        (split-window-vertically)
                        (switch-to-buffer buffer)
                        (save-selected-window
                          (other-window 1)
                          (fit-window-to-buffer bottom-win (/ (frame-height) 2))))
                       ((:window-layout-1&2+ :window-layout-3+ :window-layout-2)
                        (select-window code-win)
                        (switch-to-buffer buffer)
                        (save-selected-window
                          (select-window bottom-win)
                          (switch-to-buffer old-buf)
                          (fit-window-to-buffer bottom-win (/ (frame-height) 2))))
                       (otherwise
                        (select-window code-win)
                        (switch-to-buffer buffer)))))))
	  (set-buffer buffer)
	  (if (> line-number 0)
	      (progn
		(setq old-pos (point))
		(codepilot-goto-line line-number)
		(setq old-point (point))
		(if nil ;; (and cscope-adjust cscope-adjust-range)  ;; brian!!!
		    (progn
		      ;; Calculate the length of the line specified by cscope.
		      (end-of-line)
		      (setq line-end (point))
		      (goto-char old-point)
		      (setq line-length (- line-end old-point))

		      ;; Search forward and backward for the pattern.
		      (setq forward-point (search-forward
					   cscope-symbol-local
					   (+ old-point
					      cscope-adjust-range) t))
		      (goto-char old-point)
		      (setq backward-point (search-backward
					    cscope-symbol-local
					    (- old-point
					       cscope-adjust-range) t))
		      (if forward-point
			  (progn
			    (if backward-point
				(setq new-point
				      ;; Use whichever of forward-point or
				      ;; backward-point is closest to old-point.
				      ;; Give forward-point a line-length advantage
				      ;; so that if the symbol is on the current
				      ;; line the current line is chosen.
				      (if (<= (- (- forward-point line-length)
						 old-point)
					      (- old-point backward-point))
					  forward-point
					backward-point))
			      (setq new-point forward-point)))
			(if backward-point
			    (setq new-point backward-point)
			  (setq new-point old-point)))
		      (goto-char new-point)
		      (beginning-of-line)
		      (setq new-point (point)))
		  (setq new-point old-point))
		(set-window-point window new-point)
		(if (and cscope-allow-arrow-overlays arrow-p)
		    (set-marker overlay-arrow-position (point))
                  ;; brian: inv!!!
		  ;;(set-marker overlay-arrow-position nil)
                  )
		(or (not save-mark-p)
		    (= old-pos (point))
		    (push-mark old-pos))))

	  (if cscope-marker
	      (progn ;; The search was successful.  Save the marker so it
                ;; can be returned to by cscope-pop-mark.
		(ring-insert cscope-marker-ring cscope-marker)
		;; Unset cscope-marker so that moving between matches
		;; (cscope-next-symbol, etc.) does not fill
		;; cscope-marker-ring.
		(setq cscope-marker nil)))
          (setq cscope-marker-window window)
          ;; brian
          (codepilot-highlight-one-line)
          (save-excursion (codepilot-search-and-hl-text cscope-symbol-local nil 'id))
          )
      (message "No entry found at point.")))
  window)

(defvar mycscope-option-to-char-list
  '(("-0" . "s")
    ("-1" . "g")
    ("-2" . "n")
    ("-3" . "u")
    ("-4" . "t")
    ("-6" . "e")
    ("-7" . "f")
    ("-8" . "i")))

(defun cscope-call (msg args &optional directory filter-func sentinel-func)
  "Generic function to call to process cscope requests.
ARGS is a list of command-line arguments to pass to the cscope
process.  DIRECTORY is the current working directory to use (generally,
the directory in which the cscope database is located, but not
necessarily), if different that the current one.  FILTER-FUNC and
SENTINEL-FUNC are optional process filter and sentinel, respectively."

  (let ((type (car args))
        (sym (second args))
        buf-name)

    (setq buf-name (concat (cdr (assoc type mycscope-option-to-char-list))
                           ": " sym))

    (cond ((get-buffer buf-name)
           (codepilot-switch-to-buffer buf-name))
          (t

           (let ((outbuf (get-buffer-create cscope-output-buffer-name))
                 ;; (outbuf (get-buffer-create buf-name))
                 (old-buffer (current-buffer)) )
             (if cscope-process
                 (error "A cscope search is still in progress -- only one at a time is allowed"))
             (setq directory (cscope-canonicalize-directory
                              (or cscope-initial-directory directory)))
             (if (eq outbuf old-buffer) ;; In the *cscope* buffer.
                 (if cscope-marker-window
                     (progn
                       ;; Assume that cscope-marker-window is the window, from the
                       ;; users perspective, from which the search was launched and the
                       ;; window that should be returned to upon cscope-pop-mark.
                       (set-buffer (window-buffer cscope-marker-window))
                       (setq cscope-marker (point-marker))
                       (set-buffer old-buffer)))
               (progn ;; Not in the *cscope buffer.
                 ;; Set the cscope-marker-window to whichever window this search
                 ;; was launched from.
                 (setq cscope-marker-window (get-buffer-window old-buffer))
                 (setq cscope-marker (point-marker))))
             (save-excursion
               (set-buffer outbuf)
               (if cscope-display-times
                   (let ( (times (current-time)) )
                     (setq cscope-start-time (+ (* (car times) 65536.0) (car (cdr times))
                                                (* (car (cdr (cdr times))) 1.0E-6)))))
               (setq default-directory directory
                     cscope-start-directory nil
                     cscope-search-list (cscope-find-info directory)
                     cscope-searched-dirs nil
                     cscope-command-args args
                     cscope-filter-func filter-func
                     cscope-sentinel-func sentinel-func
                     cscope-first-match nil
                     cscope-first-match-point nil
                     cscope-stop-at-first-match-dir-meta (memq t cscope-search-list)
                     cscope-matched-multiple nil
                     buffer-read-only nil)
               (buffer-disable-undo)
               (erase-buffer)
               (setq truncate-lines cscope-truncate-lines)
               (if msg
                   (insert msg "\n"))
               (cscope-search-one-database))
             (if cscope-display-cscope-buffer
                 (progn
                   ;; (pop-to-buffer outbuf)
                   ;; brian
                   (unless inhibit-codepilot-pre-pop-or-switch-buffer-hook
                     (run-hooks 'codepilot-pre-pop-or-switch-buffer-hook))
                   (codepilot-switch-to-buffer outbuf)
                   (cscope-help))
               (set-buffer outbuf))
             (goto-char (point-max))
             (cscope-list-entry-mode)

             ;; rename buffer
             (rename-buffer buf-name)
             
             ;; serial number for sort by the create time.
             (make-local-variable 'cptree-serial-number)
             (setq cptree-serial-number cptree-serial-no-last)
             (setq cptree-serial-no-last (1+ cptree-serial-no-last))

             (toggle-truncate-lines 1)

             ;; update the [CScope Query List]
             (cplist-add-line-to-idlist "^@ CScope Query List  " (concat "  " buf-name "\n")))))))

(define-key codepilot-ro-mode-map "s" 'cscope-find-this-symbol)
(define-key codepilot-ro-mode-map "d" 'cscope-find-global-definition)
(define-key codepilot-ro-mode-map "g" 'cplist-update)  ;; brian
(define-key codepilot-ro-mode-map "G" 'cscope-find-global-definition-no-prompting)
(define-key codepilot-ro-mode-map "c" 'cscope-find-functions-calling-this-function)
(define-key codepilot-ro-mode-map "C" 'cscope-find-called-functions)
(define-key codepilot-ro-mode-map "t" 'cscope-find-this-text-string)
(define-key codepilot-ro-mode-map "e" 'cscope-find-egrep-pattern)
;; (define-key codepilot-ro-mode-map "f" 'cscope-find-this-file)
;; (define-key codepilot-ro-mode-map "i" 'cscope-find-files-including-file)


(define-key cscope-list-entry-keymap [mouse-3] 'cscope-mouse-select-entry-other-window)
(define-key cscope-list-entry-keymap [mouse-1] 'cscope-mouse-select-entry-other-window)
(define-key cscope-list-entry-keymap "0" 'delete-window)

(define-key cscope-list-entry-keymap "," 'codepilot-previous-buffer)
(define-key cscope-list-entry-keymap "." 'codepilot-forward-buffer)

(define-key cscope-list-entry-keymap "g" 'cplist-update)
(define-key cscope-list-entry-keymap "1" 'delete-other-windows)
(define-key cscope-list-entry-keymap "0" 'delete-window)

(provide 'mycscope)

