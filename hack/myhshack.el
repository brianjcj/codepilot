

;; hack on hideshow.el
;; Remember update it when upgrade to new Emacs vesion (new hideshow.el)
;; ============================

(require 'hideshow)

(setq hs-allow-nesting t)

(defalias 'hs-match-data 'match-data)

(defun hs-hide-block-at-point (&optional end comment-reg)
  "Hide block iff on block beginning.
Optional arg END means reposition at end.
Optional arg COMMENT-REG is a list of the form (BEGIN END) and
specifies the limits of the comment, or nil if the block is not
a comment.

The block beginning is adjusted by `hs-adjust-block-beginning'
and then further adjusted to be at the end of the line."
  (if comment-reg
      (hs-hide-comment-region (car comment-reg) (cadr comment-reg) end)
    (when (looking-at hs-block-start-regexp)
      (let* ((mdata (hs-match-data t))
             (pure-p (match-end 0))
             (p
              ;; `p' is the point at the end of the block beginning,
              ;; which may need to be adjusted
              (save-excursion
                (goto-char (funcall (or hs-adjust-block-beginning
                                        'identity)
                                    pure-p))
                ;; whatever the adjustment, we move to eol
                (end-of-line)
                (point)))
             (q
              ;; `q' is the point at the end of the block
              (progn (hs-forward-sexp mdata 1)
                     (end-of-line)
                     (point)
                     ))
             ;; Brian----part 1 of 2-----
             (m
              (if (or (eq major-mode 'emacs-lisp-mode)
                      (eq major-mode 'lisp-mode))
                  q
                (save-excursion
                  (forward-line -1)
                  (end-of-line)
                  ;; (backward-char)
                  (point)
                  )))
             ;; --end of hack----part 1 of 2-----
             ov)
        (when (and (< p (point)) (> (count-lines p q) 1))
          (cond ((and hs-allow-nesting (setq ov (hs-overlay-at p)))
                 (delete-overlay ov))
                ((not hs-allow-nesting)
                 (hs-discard-overlays p q)))
          (hs-make-overlay p m 'code (- pure-p p))) ;;Brian ---part 2 of 2--- change q to m---
        (goto-char (if end q (min p pure-p)))))))


(defun hs-hide-level-recursive (arg minp maxp)
  "Recursively hide blocks ARG levels below point in region (MINP MAXP)."
  (when (hs-find-block-beginning)
    (setq minp (1+ (point)))
    (funcall hs-forward-sexp-func 1)
    (setq maxp (1- (point))))
  (unless hs-allow-nesting
    (hs-discard-overlays minp maxp))
  (goto-char minp)
  (while (progn
           (forward-comment (buffer-size))
           (and (< (point) maxp)
                ;; (re-search-forward hs-block-start-regexp maxp t)
                ;; brian: hack here, to avoid the { in the string or comments.
                (let ((con t))
                  (while (and con (not (eobp)))
                    (down-list)
                    (cond ((char-equal ?{ (char-before (point)))
                           (backward-char)
                           (setq con nil))
                          (t
                           (up-list)))
                    )
                  (not con))
                ))
    (if (> arg 1)
        (hs-hide-level-recursive (1- arg) minp maxp)
      ;; (goto-char (match-beginning hs-block-start-mdata-select)) ;; brian
      (hs-hide-block-at-point t)))
  (goto-char maxp))


;; I don't like hs-c-like-adjust-block-beginning. Change ADJUST-BEG-FUNC to nil.
(setq hs-special-modes-alist
  '((c-mode "{" "}" "/[*/]" nil nil)  ; hs-c-like-adjust-block-beginning)
    (c++-mode "{" "}" "/[*/]" nil nil) ; hs-c-like-adjust-block-beginning)
    (bibtex-mode ("^@\\S(*\\(\\s(\\)" 1))
    (java-mode "{" "}" "/[*/]" nil nil))) ; hs-c-like-adjust-block-beginning))


(defvar hs--overlay-keymap nil "keymap for folding overlay")

(let ((map (make-sparse-keymap)))
  (define-key map [mouse-1] 'hs-show-block)
  (setq hs--overlay-keymap map)
  )

(setq hs-set-up-overlay
      (defun my-display-code-line-counts (ov)
        (when (eq 'code (overlay-get ov 'hs))
          (overlay-put ov 'display
                       (propertize
                        (format "%s<%d lines>%s"
                                my-hide-region-before-string
                                (1- (count-lines (overlay-start ov)
                                                 (overlay-end ov)))
                                my-hide-region-after-string
                                )))
          (overlay-put ov 'face 'codepilot-folding-overlay)
          (overlay-put ov 'priority (overlay-end ov))
          (overlay-put ov 'keymap hs--overlay-keymap)
          (overlay-put ov 'pointer 'hand)
          )))

(define-key hs-minor-mode-map [(f10)] 'hs-toggle-hiding)
(define-key hs-minor-mode-map [mouse-2] (lambda (e)
                                          (interactive "e")
                                          (mouse-set-point e)
                                          (hs-toggle-hiding)
                                          ))


(defun hs-toggle-hiding ()
  "Toggle hiding/showing of a block.
See `hs-hide-block' and `hs-show-block'."
  (interactive)
  (save-excursion  ;; brian: pertain the orginal point!
    (hs-life-goes-on
     (if (hs-already-hidden-p)
         (hs-show-block)
       (hs-hide-block)))))

(require 'hideif)


(defun myhif-toggle-hideshow-block ()
  (interactive)
  (let ((o-list (overlays-at (point))))
    (cond ((and o-list
                (some #'(lambda (o)
                          (eq (overlay-get o 'hide-ifdef) t)
                          )
                      o-list
                      ))
           (show-ifdef-block)
           )
          (t
           (hide-ifdef-block)
           ))
    ))


(defvar hif--overlay-keymap nil "keymap for folding overlay")

(let ((map (make-sparse-keymap)))
  (define-key map [mouse-1] 'show-ifdef-block)
  (define-key map "\r" 'show-ifdef-block)
  (setq hif--overlay-keymap map)
  )


(defun hide-ifdef-region-internal (start end)
  (remove-overlays start end 'hide-ifdef t)
  (let ((o (make-overlay start end)))
    (overlay-put o 'hide-ifdef t)
    (if hide-ifdef-shadow
	(overlay-put o 'face 'hide-ifdef-shadow)
      (overlay-put o 'invisible 'hide-ifdef))

    ;; brian:
    (overlay-put o 'display
                 (propertize
                  (format "%s<%d lines>%s"
                          my-hide-region-before-string
                          (1- (count-lines (overlay-start o)
                                           (overlay-end o)))
                          my-hide-region-after-string
                          )))
    (overlay-put o 'face 'codepilot-folding-overlay)
    (overlay-put o 'priority (overlay-end o))
    (overlay-put o 'keymap hif--overlay-keymap)
    (overlay-put o 'pointer 'hand)
    ))

(define-key hide-ifdef-mode-map [(shift f10)] 'myhif-toggle-hideshow-block)


(provide 'myhshack)
