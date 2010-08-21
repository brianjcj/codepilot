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

(defface codepilot-link-face
  '((((class color) (background light)) (:foreground "Purple" :underline t))
    (((class color) (background dark)) (:foreground "Cyan" :underline t))
    (t (:underline t)))
  "Face for links."
  :group 'codepilot)

(defvar cpnote-mouse-map (make-sparse-keymap))
(define-key cpnote-mouse-map [mouse-1] 'cpnote-click-link)

;; [[d:/pls-source/winstoui.ap04]<367><14910>]
(defun cpnote-activate-links (limit)
  "Run through the buffer and add overlays to target matches."
  (let ((case-fold-search t))
    (if (re-search-forward "\\[\\[.+\\][0-9<>]+\\]" limit t)
        (progn
          (add-text-properties (match-beginning 0) (match-end 0)
                               (list 'mouse-face 'codepilot-link-face
                                     'keymap cpnote-mouse-map))
          t))))

(defvar cpnote-font-lock-keywords-add
  (list
;;    (list "\\[\\[.+\\][0-9<>]+\\]"
;;          '(0 'codepilot-link-face)
;;          )
   '(cpnote-activate-links (0 'codepilot-link-face))))

(defun cpnote-syntax-modify ()
    (modify-syntax-entry ?_ "w" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\# "_" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\( "()" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\) ")(" cpnote-mode-syntax-table)
    (modify-syntax-entry ?$ "w" cpnote-mode-syntax-table)
    (modify-syntax-entry ?* "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?/ "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?+ "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?- "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?= "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?\& "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?\| "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?< "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?> "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?\[ "(]" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\] ")[" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\{ "(}" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\} "){" cpnote-mode-syntax-table)
    (modify-syntax-entry ?. "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?\\ "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?: "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?^ "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?% "<" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\n ">" cpnote-mode-syntax-table)
    (modify-syntax-entry ?@ "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?\; "." cpnote-mode-syntax-table)
    (modify-syntax-entry ?\' "\"" cpnote-mode-syntax-table)
    (modify-syntax-entry ?\" "\"" cpnote-mode-syntax-table))

(define-derived-mode
    cpnote-mode outline-mode "CP-Note"
    "Major mode for take notes for Protel codes."
    ;; (setq font-lock-defaults '(codepilot-font-lock-keywords t))
    (make-local-variable 'font-lock-keywords-case-fold-search)
    (setq font-lock-keywords-case-fold-search t)
    ;; (font-lock-add-keywords nil protel-font-lock-keywords)
    (font-lock-add-keywords nil cpnote-font-lock-keywords-add)
    (cpnote-syntax-modify)
    (auto-fill-mode -1))

(defun codepilot-open-remember-data-file ()
  ""
  (interactive)
  (if (find-buffer-visiting remember-data-file)
      (codepilot-switch-to-buffer (get-file-buffer remember-data-file))
    (codepilot-switch-to-buffer (find-file-noselect remember-data-file)))
  (cpnote-mode)
  (goto-char (point-max)))


(defun cpnote-click-link (event)
  ""
  (interactive "e")
  (mouse-set-point event)
  (let ((case-fold-search t)
        (click-pos (point))
        file line pos limit buf m-b m-e range ok)
    (save-excursion
      (save-match-data
        (skip-chars-forward "[")
        (when (re-search-backward "\\[\\[" (save-excursion (forward-line 0) (point)) t)
          (setq m-b (point))
          (when (re-search-forward "\\[\\[\\(.+\\)\\]<\\([0-9]+\\)>" (save-excursion (end-of-line) (point)) t)
            (setq file (match-string 1)
                  line (match-string 2))
            (when (looking-at "<\\([0-9]+\\)>")
              (setq pos (match-string 1)))
            (when (re-search-forward "\\]" nil t)
              (setq m-e (match-end 0))
              (when (and (>= click-pos m-b)
                         (<= click-pos m-e))
                (setq ok t)))))))
    (cond (ok
           (when (setq buf (find-file-noselect file))
             (let ((inhibit-codepilot-pre-pop-or-switch-buffer-hook nil))
               (codepilot-pop-or-switch-buffer buf :cpnote-click-link))
             (if pos
                 (goto-char (string-to-number pos))
               (codepilot-goto-line (string-to-number line)))))
          (t
           ;; (codepilot-ct-from-trap/swer/debug)
	   ))))

(define-key cpnote-mode-map [mouse-3] 'cpnote-click-link)


(provide 'cpnote)