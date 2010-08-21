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

(require 'cl)
(require 'cp-cc)
(require 'mycscope)
(require 'mygtags)
(require 'myetags)

(defun cplist-update-buffer-list ()
  ;; (message "find file hook hit")

  (let ((b (get-buffer cplist-buf-name))
        ;;(b-name (file-name-nondirectory buffer-file-name))
        (b-name (buffer-name)))
    
    (when (and b
               (in-codepilot-cc-major-modes? major-mode)
               b-name)
      (cplist-add-line-to-idlist "^\\@ Buffer List  "
                                 (concat "  " b-name "\n")))))

(defun cplist-update-dired-list ()
  (message "find file hook hit")

  (let ((b (get-buffer cplist-buf-name))
        (b-name (buffer-name)))
    
    (when (and b
               (eq major-mode 'dired-mode)
               b-name)
      (cplist-add-line-to-idlist "^\\@ Dired List  "
                                 (concat "  " b-name "\n")))))


(defun cplist-cc-fill-cplist ()

  (insert "[All] [CScope] [GTags]\n")
  (insert "[Buffer] [Dired] [Speedbar]\n")
  
  (when (or (eq cplist-type 'all)
            (eq cplist-type 'cscope))
    (insert-image codepilot-image-bucket-1 "@")
    (insert " CScope Query List  \n")
    (if (not (eq cplist-query-sort-type 'create))
        (progn
          (dolist (b (buffer-list))
            (if (eq (with-current-buffer b  major-mode) 'cscope-list-entry-mode)
                (insert "  " (concat (buffer-name b) "\n"))))
          (cond ((eq cplist-query-sort-type 'name)
                 (cplist-sort-query-list-by-name))
                ((eq cplist-query-sort-type 'id-name)
                 (cplist-sort-query-by-id-name)))
          (insert "\n"))
      (insert "\n")
      (mycscope-cplist-sort-query-by-create)))

  (when (or (eq cplist-type 'all)
            (eq cplist-type 'gtags))
    (insert-image codepilot-image-bucket-1 "@")
    (insert " GTags List  \n")
    (cond ((eq cplist-query-sort-type 'create)
           (insert "\n")
           (mygtags-list-sort-by-create))
          (t
           (cplist-list-buffer 'gtags-select-mode))))

  (when (or (eq cplist-type 'all)
            (eq cplist-type 'buffer))
    (insert-image codepilot-image-bucket-1 "@")
    (insert " Buffer List  \n")
    (let (mm)
      (dolist (b (buffer-list))
        (setq mm (with-current-buffer b major-mode))
        (when (in-codepilot-cc-major-modes? mm)
          (insert "  " (concat (buffer-name b) "\n")))))
    (insert "\n"))


  (when (or (eq cplist-type 'all)
            (eq cplist-type 'dired))
    (insert-image codepilot-image-bucket-1 "@")
    (insert " Dired List  \n")
    (let (mm)
      (dolist (b (buffer-list))
        (setq mm (with-current-buffer b major-mode))
        (when (eq mm 'dired-mode)
          (insert "  " (concat (buffer-name b) "\n")))))
    (insert "\n"))
  
  ;; (insert-image codepilot-image-bucket-1 "@")
  ;; (insert " GTags History List  \n")
  ;; ;; (dolist (i (delete-duplicates find-tag-history :from-end t :test #'string=))
  ;; (dolist (i find-gtag-history)
  ;;   (when i
  ;;     (insert "  = " i "\n")))
  ;; (insert "\n")

  ;; (insert-image codepilot-image-bucket-1 "@")
  ;; (insert " ETags History List  \n")
  ;; ;; (dolist (i (delete-duplicates find-tag-history :from-end t :test #'string=))
  ;; (dolist (i find-tag-history)
  ;;   (when i
  ;;     (insert "  > " i "\n")))
  ;; (insert "\n")
  
  )

(defun cplist-cc-for-cplist-action ()
  (cond ((eq major-mode 'cscope-list-entry-mode)
         (let (pos)
           (setq pos (cscope-single-match?))
           (when pos
             (goto-char pos)
            (let ((cscope-jump-single-match t))
              (cscope-select-entry-other-window)))))
        ((eq major-mode 'gtags-select-mode)
         (cond (;; (= 1 (count-lines (point-min) (point-max)))
                (save-excursion
                  (save-match-data
                    (goto-char (point-min))
                    (not (re-search-forward "^  +[0-9]+|" nil t 2))))
                (goto-char (point-min))
                (forward-line)
                (gtags-select-it nil t) ;; do not delete
                )))))

(defun tag-delete-in-tag-history (str)
  (let (tagname ind ltail)
    (cond ((eq ?= (aref str 0))
           (setq tagname (subseq str 2))
           (setq ind (position tagname find-gtag-history :test #'string=))
           (cond ((null ind))
                 ((= ind 0)
                  (pop find-gtag-history))
                 (t
                  (setq ltail (nthcdr (1- ind) find-gtag-history))
                  (setcdr ltail (cdr (cdr ltail)))))
           )
          ((eq ?> (aref str 0))
           (setq tagname (subseq str 2))
           (setq ind (position tagname find-tag-history :test #'string=))
           (cond ((null ind))
                 ((= ind 0)
                  (pop find-tag-history))
                 (t
                  (setq ltail (nthcdr (1- ind) find-tag-history))
                  (setcdr ltail (cdr (cdr ltail)))))))))

(defun cplist-cc-goto-next-visible-tagline ()
  (forward-line)
  (while (and (not (eobp))
              (or (looking-at "^@") ;; head line
                  (looking-at "^$") ;; blank line
                  (looking-at "^\\[")
                  (let ((ol (overlays-at (point)))) ;; in overlay. invisible.
                    (and ol
                         (some #'(lambda (o)
                                   (eq 'cpfilter (overlay-get o 'tag)))
                               ol)))))
    (forward-line))
  (unless (eobp)
    t))

(defun cplist-cc-tab ()
  (interactive)
  (let (pos)
    (save-excursion
      (when (cplist-cc-goto-next-visible-tagline)
        (setq pos (point))
        ))
    (cond (pos
           (goto-char pos)
           t)
          (t
           (save-excursion
             (goto-char (point-min))
             (forward-line) ;; skip the cpfilter line
             (when (cplist-cc-goto-next-visible-tagline)
               (setq pos (point))))
           (when pos
             (goto-char pos)
             t)))))

(provide 'cplist-cc)