
(require 'etags)

(defun find-tag-noselect (tagname &optional next-p regexp-p)
  "Find tag (in current tags table) whose name contains TAGNAME.
Returns the buffer containing the tag's definition and moves its point there,
but does not select the buffer.
The default for TAGNAME is the expression in the buffer near point.

If second arg NEXT-P is t (interactively, with prefix arg), search for
another tag that matches the last tagname or regexp used.  When there are
multiple matches for a tag, more exact matches are found first.  If NEXT-P
is the atom `-' (interactively, with prefix arg that is a negative number
or just \\[negative-argument]), pop back to the previous tag gone to.

If third arg REGEXP-P is non-nil, treat TAGNAME as a regexp.

A marker representing the point when this command is invoked is pushed
onto a ring and may be popped back to with \\[pop-tag-mark].
Contrast this with the ring of marks gone to by the command.

See documentation of variable `tags-file-name'."
  (interactive (find-tag-interactive "Find tag: "))

  ;; brian
  ;; (setq find-tag-history (cons tagname find-tag-history))
  ;; Save the current buffer's value of `find-tag-hook' before
  ;; selecting the tags table buffer.  For the same reason, save value
  ;; of `tags-file-name' in case it has a buffer-local value.
  (let ((local-find-tag-hook find-tag-hook))
    (if (eq '- next-p)
	;; Pop back to a previous location.
	(if (ring-empty-p tags-location-ring)
	    (error "No previous tag locations")
	  (let ((marker (ring-remove tags-location-ring 0)))
	    (prog1
		;; Move to the saved location.
		(set-buffer (or (marker-buffer marker)
                                (error "The marked buffer has been deleted")))
	      (goto-char (marker-position marker))
	      ;; Kill that marker so it doesn't slow down editing.
	      (set-marker marker nil nil)
	      ;; Run the user's hook.  Do we really want to do this for pop?
	      (run-hooks 'local-find-tag-hook))))
      ;; Record whence we came.
      (ring-insert find-tag-marker-ring (point-marker))
      (if (and next-p last-tag)
	  ;; Find the same table we last used.
	  (visit-tags-table-buffer 'same)
	;; Pick a table to use.
	(visit-tags-table-buffer)
	;; Record TAGNAME for a future call with NEXT-P non-nil.
	(setq last-tag tagname))
      ;; Record the location so we can pop back to it later.
      (let ((marker (make-marker)))
	(save-excursion
	  (set-buffer
	   ;; find-tag-in-order does the real work.
	   (find-tag-in-order
	    (if (and next-p last-tag) last-tag tagname)
	    (if regexp-p
		find-tag-regexp-search-function
	      find-tag-search-function)
	    (if regexp-p
		find-tag-regexp-tag-order
	      find-tag-tag-order)
	    (if regexp-p
		find-tag-regexp-next-line-after-failure-p
	      find-tag-next-line-after-failure-p)
	    (if regexp-p "matching" "containing")
	    (or (not next-p) (not last-tag))))
	  (set-marker marker (point))
          ;; brian
          (when tagname
            (setq find-tag-history (cons tagname find-tag-history)))
	  (run-hooks 'local-find-tag-hook)
	  (ring-insert tags-location-ring marker)

          (when tagname
            (let (ltail ind item)
              (setq item (pop find-tag-history))
              (when item
                (setq ind (position item find-tag-history :test #'string=))
                (cond ((null ind)
                       (setq find-tag-history (push item find-tag-history))
                       (cplist-add-line-to-idlist "^\\[ETags History List\\]"
                                                    (concat "  > " tagname "\n"))
                       )
                      ((= ind 0))
                      (t
                       (setq ltail (nthcdr (1- ind) find-tag-history))
                       (setcdr ltail (cdr (cdr ltail)))
                       (setq find-tag-history (push item find-tag-history))
                       ))))
          
            (codepilot-search-and-hl-text tagname nil 'id))
          
	  (current-buffer))))))

(defun find-tag (tagname &optional next-p regexp-p)
  "Find tag (in current tags table) whose name contains TAGNAME.
Select the buffer containing the tag's definition, and move point there.
The default for TAGNAME is the expression in the buffer around or before point.

If second arg NEXT-P is t (interactively, with prefix arg), search for
another tag that matches the last tagname or regexp used.  When there are
multiple matches for a tag, more exact matches are found first.  If NEXT-P
is the atom `-' (interactively, with prefix arg that is a negative number
or just \\[negative-argument]), pop back to the previous tag gone to.

If third arg REGEXP-P is non-nil, treat TAGNAME as a regexp.

A marker representing the point when this command is invoked is pushed
onto a ring and may be popped back to with \\[pop-tag-mark].
Contrast this with the ring of marks gone to by the command.

See documentation of variable `tags-file-name'."
  (interactive (find-tag-interactive "Find tag: "))

  (let (buf
        pos
        (pos-o (point))
        )
    (save-current-buffer
      (setq buf (find-tag-noselect tagname next-p regexp-p))
      (setq pos (with-current-buffer buf (point)))
      )
    (goto-char pos-o)
    (condition-case nil
	(codepilot-pop-or-switch-buffer buf) ;; brian
      (error (pop-to-buffer buf)))
    (goto-char pos) 
    ))

(provide 'myetags)
