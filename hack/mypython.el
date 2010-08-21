
(require 'python)

(defun python-which-func ()
  (cpimenu-which-func)
  (let ((function-name (python-current-defun python-which-func-length-limit)))
    (set-text-properties 0 (length function-name) nil function-name)
    function-name))

;; only one line is modified. search brian
(defun python-imenu-create-index ()
  "`imenu-create-index-function' for Python.

Makes nested Imenu menus from nested `class' and `def' statements.
The nested menus are headed by an item referencing the outer
definition; it has a space prepended to the name so that it sorts
first with `imenu--sort-by-name' (though, unfortunately, sub-menus
precede it)."
  (unless (boundp 'python-recursing)	; dynamically bound below
    ;; Normal call from Imenu.
    (goto-char (point-min))
    ;; Without this, we can get an infloop if the buffer isn't all
    ;; fontified.  I guess this is really a bug in syntax.el.  OTOH,
    ;; _with_ this, imenu doesn't immediately work; I can't figure out
    ;; what's going on, but it must be something to do with timers in
    ;; font-lock.
    ;; This can't be right, especially not when jit-lock is not used.  --Stef
    ;; (unless (get-text-property (1- (point-max)) 'fontified)
    ;;   (font-lock-fontify-region (point-min) (point-max)))
    )
  (let (index-alist)			; accumulated value to return
    (while (re-search-forward
	    (rx line-start (0+ space)	; leading space
		(or (group "def") (group "class"))	   ; type
		(1+ space) (group (1+ (or word ?_))))	   ; name
	    nil t)
      (unless (python-in-string/comment)
	(let ((pos (match-beginning 0))
	      (name (match-string-no-properties 3)))
	  (if (match-beginning 2)	; def or class?
	      (setq name (concat "class " name)))
	  (save-restriction
	    (narrow-to-defun)
	    (let* ((python-recursing t)
		   (sublist (python-imenu-create-index)))
	      (if sublist
		  (progn
                    (setq sublist (nreverse sublist)) ;; brian
                    (push (cons (concat " " name) pos) sublist)
                    (push (cons name sublist) index-alist))
		(push (cons name pos) index-alist)))))))
    (unless (boundp 'python-recursing)
      ;; Look for module variables.
      (let (vars)
	(goto-char (point-min))
	(while (re-search-forward
		(rx line-start (group (1+ (or word ?_))) (0+ space) "=")
		nil t)
	  (unless (python-in-string/comment)
	    (push (cons (match-string 1) (match-beginning 1))
		  vars)))
	(setq index-alist (nreverse index-alist))
	(if vars
	    (push (cons "Module variables"
			(nreverse vars))
		  index-alist))))
    index-alist))


(defun mypython-fold/unfold-block ()
  "fold the block"
  (interactive)
  (let (ret b e)
    (dolist (o (overlays-at (if (python-open-block-statement-p)
                                (save-excursion
                                  (python-end-of-statement)
                                  (point)
                                  )
                                (point))))
      (when (cptree-delete-overlay o 'cptree)
        (setq ret t)
        ))
    (unless ret
      (save-excursion
        (unless (python-open-block-statement-p)
          (python-beginning-of-block))
        (python-end-of-statement)
        (setq b (point))
        (python-end-of-block)
        (setq e (1- (point)))
        (cptree-hide-region b e 'cptree)
        )))
  )

(define-key python-mode-map [(f10)] 'mypython-fold/unfold-block)

(provide 'mypython)