;;; smart-mark.el --- Smart Mark for GNU Emacs

;; Copyright (C) 2010  Brian Jiang

;; Author: Brian Jiang <brianjcj@gmail.com>
;; Keywords: convenience
;; Version: 0.1g

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


;;; Commentary:
;;
;; Simulate some vim command. Mark context in the (), <>, [], "", '', html tag,
;; mark line, mark....
;;
;;; Uage:
;; (require 'smart-mark)
;; type C-M-m and then following the prompt.
;;

;;; Code:


(provide 'smart-mark)

(require 'thingatpt)

(defvar smart-mark-chars-open  (list ?\( ?\< ?\{ ?\[ ))
(defvar smart-mark-chars-close (list ?\) ?\> ?\} ?\] ))
(defvar smart-mark-chars-quote (list ?\" ?\' ))
(defvar smart-mark-chars (append smart-mark-chars-open smart-mark-chars-close smart-mark-chars-quote))
(defvar smart-mark-chars-pairs (mapcar* 'cons smart-mark-chars-close smart-mark-chars-open))


(defvar smart-mark-temp-syntax-table (make-char-table 'syntax-table nil))
(modify-syntax-entry ?\' "\"" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\" "\"" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\{ "(" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\} ")" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\( "(" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\) ")" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\< "(" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\> ")" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\[ "(" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\] ")" smart-mark-temp-syntax-table)
(modify-syntax-entry ?\\ "\\" smart-mark-temp-syntax-table)


(defvar smart-mark-include-encloser nil)

(defun smart-mark-1 (&optional adjust pos)
  (let ((c (char-after))
        range b e start end)

    (if (memq c smart-mark-chars-quote)
        (and (setq range (bounds-of-thing-at-point 'sexp))
             (setq b (car range))
             (setq e (cdr range)))
      (and
       (setq range (mouse-start-end (point) (point) 1))
       (setq b (car range))
       (setq e (nth 1 range))))
    
    (unless (or (not range)
                (and (< pos b) (< pos e)) ;; out of range
                (and (> pos b) (> pos e)) ;; out of range
                )
      (when (and adjust
                 ;; (not (eq major-mode 'emacs-lisp-mode))
                 ;; (not (eq major-mode 'lisp-mode))
                 (not smart-mark-include-encloser)
                 (not current-prefix-arg))
        (cond ((< b e)
               (setq b (1+ b)
                     e (1- e)))
              (t
               (setq b (1- b)
                     e (1+ e))))
        (when (or (memq c smart-mark-chars-open)
                  (memq c smart-mark-chars-close))
          
          (goto-char (min b e))
          (when (looking-at "[\s\t]*$")
            (forward-line))
          (setq start (point))
          (goto-char (max b e))
          (skip-chars-backward "\s\t")
          (when (looking-at "^")
            (backward-char))
          (setq end (point))
          (cond ((< b e)
                 (setq b start
                       e end))
                (t
                 (setq e start
                       b end)))))
      (unless (= b e)
        (push-mark b nil t)
        (goto-char e)))))

(defun smart-mark-line ()
  (interactive)
  (push-mark (line-beginning-position) nil t)
  (goto-char (line-end-position)))

(defun smart-mark-to-line-start ()
  (interactive)
  (push-mark (point) nil  t)
  (goto-char (line-beginning-position)))

(defun smart-mark-to-line-end ()
  (interactive)
  (push-mark nil (point) t)
  (goto-char (line-end-position)))

(defun smart-mark-mark-current-list (&optional level)
  (interactive)
  (when (memq (char-after) smart-mark-chars-open)
    (forward-char))
  (ignore-errors
    (if (= level -1)
        (while t (backward-up-list 99999))
      (backward-up-list level)))
  (smart-mark-1 t (point)))

(defun smart-mark-find-real-quote (c)
  (let (not-q)
    (while (and (re-search-forward (concat "\\(\\s\\*\\)" (string c)) nil t)
                (setq not-q (/= 0 (mod (- (match-end 1) (match-beginning 1)) 2)))))
    (unless not-q
      (backward-char)
      t)))

(defvar smart-mark-just-find nil)

(defun smart-mark-find-char-1 (s-fn)
  (let (c pos
        (case-fold-search nil)
        (org-pos (point))
        (prompt "find char (type RET to finish) : "))
    (when smart-mark-just-find
      (setq prompt "find char (type RET to finish, type C-x to mark) : "))
    (catch 'loo
      (condition-case nil
        (while t
          (setq c (read-char prompt))
          (when (= c ?\r)
            (throw 'loo t))
          (when (and smart-mark-just-find
                     (= c 24) ;; C-x
                     )
            (setq pos (point))
            (push-mark org-pos nil t)
            (goto-char pos)
            (throw 'loo t))
          (unless mark-active
            (unless smart-mark-just-find
              (push-mark (point) nil t)))
          (funcall s-fn (string c) nil t))
        (error
         (let ((key-1 (this-command-keys))
               cmd)
           (and key-1
                (setq cmd (key-binding (substring key-1 (1- (length key-1)))))
                (call-interactively cmd))))))))

(defun smart-mark-whole-sexp ()
  "Mark whole sexp."
  (interactive)
  (let ((region (bounds-of-thing-at-point 'sexp)))
    (if (not region)
        (message "Can not found sexp.")
      (push-mark (car region) nil t)
      (forward-sexp))))

(defun smart-mark-up-list (c level)
  (let ((pos (point)))
    (catch 'loo
      (while t
        (condition-case nil
            (backward-up-list)
          (error
           (goto-char pos)
           (throw 'loo t)))
        (when (= c (char-after))
          (setq pos (point))
          (setq level (1- level)))
        (when (= level 0)
          (throw 'loo t))))
    (goto-char pos)))

(defvar smart-mark-help-text "()[]<>\"\'   as you know;
m   mark current list;
M   mark current list including enclosers;
n   mark according to the char under cursor;
t   mark tag content;
T   mark tag content as well as tag;
l   mark line;
s   mark sexp;
a   mark from current pos to beginning of the line;
e   mark from current pos to end of the line;
RET mark word;
w   mark word;
f   find a char forward and mark orig pos to new pos;
F   find a char backward and mark orig pos to new pos;
r   find a char forward;
R   find a char backward;
?   help

And you can type an optional number (0-9) before ()[]<>m.
Try it to see the effect :)
Type C-u before the command, the enclosers will be marked too.
")

(defun smart-mark (&optional c-arg num-arg)
  (interactive)
  (catch 'exit
    (let ((cc (char-after))
          (num 1)
          (prompt
           "Select a command (',\",(,),{,},[,],<,>,t,l,a,e,m,n,s,RET; type ? for help) : ")
          (pos (point))
          c c-t search? done? config async)

      (cond (c-arg
             (setq c c-arg
                   num num-arg))
            (t
             (setq c (read-char prompt))

             (when (= c ?\?)
               (save-window-excursion
                 (with-output-to-temp-buffer "*smart-mark*"
                   (princ smart-mark-help-text))
                 (setq c (setq c (read-char-exclusive prompt))))
               (setq async t))
    
             (when (and (>= c ?0) (<= c ?9))
               (setq num (- c ?0))
               (when (= num 0)
                 (setq num -1))
               (setq c (read-char prompt)))

             (when async
               (run-with-timer 0 nil 'smart-mark c num)
               (throw 'exit t))))
    
      (unless (and cc
                   (or (= c cc)
                       (= c ?n)
                       (and (setq c-t (cdr (assoc c  smart-mark-chars-pairs)))
                            (= cc c))))
        (setq search? t))

      (cond ((= c ?t)
             (unless (smart-mark-tag)
               (goto-char pos)))
            ((= c ?T)
             (unless (let ((smart-mark-include-encloser t))
                       (smart-mark-tag))
               (goto-char pos)))
            ((= c ?l)
             (smart-mark-line))
            ((= c ?a)
             (smart-mark-to-line-start))
            ((= c ?e)
             (smart-mark-to-line-end))
            ((or (= c ?\r) (= c ?w))
             (when (looking-at "[\n\t\s]")
               (skip-chars-backward "[\t\s]")
               (unless (looking-at "^")
                 (backward-char)))
             (smart-mark-1 nil (point)))
            ((= c ?m)
             (smart-mark-mark-current-list num))
            ((= c ?M)
             (let ((smart-mark-include-encloser t))
               (smart-mark-mark-current-list num)))
            ((= c ?f)
             (smart-mark-find-char-1 'search-forward))
            ((= c ?F)
             (smart-mark-find-char-1 'search-backward))
            ((= c ?r)
             (let ((smart-mark-just-find t))
               (smart-mark-find-char-1 'search-forward)))
            ((= c ?R)
             (let ((smart-mark-just-find t))
               (smart-mark-find-char-1 'search-backward)))
            ((= c ?s)
             (smart-mark-whole-sexp))
            (t
             (let ((cs (char-syntax c))
                   syntax-mod-need meta-char)
               (cond ((memq c smart-mark-chars-quote)
                      (setq syntax-mod-need (/= cs ?\")))
                     ((memq c smart-mark-chars-open)
                      (setq syntax-mod-need (/= cs ?\( )))
                     ((memq c smart-mark-chars-close)
                      (setq syntax-mod-need (/= cs ?\) )
                            c (cdr (assoc c smart-mark-chars-pairs)))))
               (flet ((s-n-m ()
                             (cond (search?
                                    (cond ((memq c smart-mark-chars-quote)
                                           (when (smart-mark-find-real-quote c)
                                             (let ((forward-sexp-function nil))
                                               (unless (smart-mark-1 t pos)
                                                 (goto-char pos)))))
                                          (t
                                           (ignore-errors
                                             (smart-mark-up-list c num)
                                             ;; (while (progn (backward-up-list) (/= c (char-after))))
                                             )
                                           (if (and (char-after) (= c (char-after)))
                                               (unless (smart-mark-1 t pos)
                                                 (goto-char pos))
                                             (goto-char pos)))))
                                   (t
                                    (let ((forward-sexp-function nil))
                                      (unless (smart-mark-1 t pos)
                                        (goto-char pos)))))))
                 (cond (syntax-mod-need
                        (set-char-table-parent smart-mark-temp-syntax-table (syntax-table))
                        (with-syntax-table
                            smart-mark-temp-syntax-table
                          (s-n-m)))
                       (t
                        (s-n-m))))))))))

(defun smart-mark-tag ()
  (interactive)
  (require 'sgml-mode)
  (ignore-errors
    (let ((pos (point)) s e tag rs re)
      (when (looking-at "<[^/]")
        (forward-char))
      (mysgml-goto-open-tag-backward-1 1)
      (setq s (point))
      (sgml-skip-tag-forward 1)
      (setq e (point))
      (goto-char s)
      (if (or smart-mark-include-encloser
              current-prefix-arg)
          (progn
            (push-mark s nil t)
            (goto-char e))
        (when (looking-at "<\\([^\s\t>]+\\)[^>]*>")
          (setq tag (match-string 1))
          (goto-char (match-end 0))
          (setq rs (point))
          (goto-char e)
          (when (re-search-backward "</\\([^\s\t>]+\\)[^>]*>" nil t)
            (when (string= tag (match-string 1))
              (setq re (match-beginning 0))
              (when (>= e pos)
                (push-mark rs nil t)
                (goto-char re)))))))))


(defun mysgml-goto-open-tag-backward-1 (arg)
  "Skip to beginning of tag or matching opening tag if present.
With prefix argument ARG, repeat this ARG times.
Return non-nil if we skipped over matched tags."
  (interactive "p")
  ;; FIXME: use sgml-get-context or something similar.
  (let ((return t)  (pos (point)) pos1)
    (when (search-backward "<")
        (cond ((= ?/ (char-after (1+ (point))))
               ;; end tags
               (setq pos1 (point))
               (forward-char)
               (when (search-forward ">")
                 (when (> (point) pos)
                   (goto-char pos1))))
              (t
               (setq arg (1- arg)))))
    (while (>= arg 1)
      (search-backward "<" nil t)
      (if (looking-at "</\\([^ \n\t>]+\\)")
          ;; end tag, skip any nested pairs
          ;; (setq level (1+ level))
          (let ((case-fold-search t)
                (re (concat "</?" (regexp-quote (match-string 1))
                            ;; Ignore empty tags like <foo/>.
                            "\\([^>]*[^/>]\\)?>")))
            (while (and (re-search-backward re nil t)
                        (eq (char-after (1+ (point))) ?/))
              (forward-char 1)
              (sgml-skip-tag-backward 1))
            (setq arg (1+ arg)))
        (setq return nil))
      (setq arg (1- arg)))
    return))


(global-set-key "\C-\M-m" 'smart-mark)

