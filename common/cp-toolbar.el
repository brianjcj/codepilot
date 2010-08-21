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

(defvar codepilot-toolbar-activated nil)


(defvar codepilot-toolbar-item-list nil)
(setq codepilot-toolbar-item-list
      (list

       (list "close" 'kill-this-buffer
             'kill-this-buffer
             :help "close. Hotkey: k or C-x k")

       (list "ppcmm/sidebar" 'cplist-side-window
             'cplist-side-window
             :help "Show or delete the sidebar window. Hotkey: F8")

       (list "ppcmm/refresh" 'cplist-update
             'cplist-update
             :help "Update the sidebar. Hotkey: g")

       (list "ppcmm/toggle-sidebar" 'cplist-minimize/restore-sidebar
             'cplist-minimize/restore-sidebar
             :help "Minimize or restore the sidebar. Hotkey: `")

       (list "ppcmm/search" 'codepilot-search-hi-string
             'codepilot-search-hi-string
             :help "Search Text. Hotkey: s")

       (list "ppcmm/search-id" 'codepilot-search-hi
             'codepilot-search-hi
             :help "Search Protel ID in the buffer. Hotkey: /")

       (list "ppcmm/search-b" 'codepilot-search-hl-again-b
             'codepilot-search-hl-again-b
             :help "Repeat search backward. Hotkey: b")

       (list "ppcmm/search-f" 'codepilot-search-hl-again-f
             'codepilot-search-hl-again-f
             :help "Repeat search forward. Hotkey: f")


       (list "ppcmm/which-procs" 'cp-pb-which-procs-i-in
             'cp-pb-which-procs-i-in
             :help "Which Procs I in. Hotkey: -")

       (list "ppcmm/search-id-and-which-procs" 'cp-pb-search-id-and-which-procs
             'cp-pb-search-id-and-which-procs
             :help "Search the id under point and show Which Procs it in. Hotkey: [")

       (list "ppcmm/which-blocks" 'cp-pb-where-we-are
             'cp-pb-where-we-are
             :help "Which Blocks. Hotkey: ]")

       (list "ppcmm/three-wins" 'cp-pb-blocktrace-and-procs-layout
             'cp-pb-blocktrace-and-procs-layout
             :help "3 windows layout. Hotkey: 2 or 3")

       (list "ppcmm/one-win" 'delete-other-windows
             'delete-other-windows
             :help "1 windows layout. Hotkey: 1")

       (list "ppcmm/del-win-2" 'delete-window
             'delete-window
             :help "Delete this window. Hotkey: 0 or C-x 0")

       (list "left-arrow" 'codepilot-previous-buffer
             'codepilot-previous
             :enable '(not (ring-empty-p codepilot-marker-ring))
             :help "Backward in the history. Hotkey: ,")
       
       (list "right-arrow" 'codepilot-forward-buffer
             'codepilot-forward
             :enable '(not (ring-empty-p codepilot-forward-marker-ring))
             :help "Forward in the history. Hotkey: \".\"")


       (list "left-arrow" 'pop-to-mark-command
             'pop-to-mark-command
             :help "Pop to mark. Hotkey: j or M-F6")

       (list "right-arrow" 'pop-to-mark-command-reverse
             'pop-to-mark-command-reverse
             :help "Pop to mark in the reverse direction")

       (list "copy" 'jump-to-h-c-file
             'jump-to-h-c-file
             :visible '(or (eq major-mode 'c-mode)
                           (eq major-mode 'c++-mode))
             :help "switch between .h/.hpp and .cpp/.cc/.c file. Hotkey: w")

       (list "ppcmm/linum" 'linum-mode
             'linum-mode
             :help "Toggle line number.")

       (list "ppcmm/toggle-cpimenu" 'cpimenu-toggle-cpimenu-win
             'cpimenu-toggle-cpimenu-win
             :help "Toggle CPImenu. (Procedure list). Hotkey: =")

       (list "ppcmm/foldunfold-3" 'hs-toggle-hiding
             'hs-toggle-hiding
             :visible '(or (eq major-mode 'c-mode)
                        (eq major-mode 'c++-mode)
                        (eq major-mode 'java-mode)
                        (eq major-mode 'emacs-lisp-mode))
             :help "Fold/Unfold a block. Hotkey: F10")

       (list "ppcmm/fcase" 'fold-c-switch
             'fold-c-switch
             :visible '(or (eq major-mode 'c-mode)
                        (eq major-mode 'c++-mode)
                        (eq major-mode 'java-mode))

             :help "Fold all switch branches.")

       (list "ppcmm/fcaseb" 'fold-c-switch-branch
             'fold-c-switch-branch
             :visible '(or (eq major-mode 'c-mode)
                        (eq major-mode 'c++-mode)
                        (eq major-mode 'java-mode))
             :help "Fold current switch branch.")

       (list "ppcmm/pif" 'myhif-toggle-hideshow-block
             'myhif-toggle-hideshow-block
             :visible '(or (eq major-mode 'c-mode)
                           (eq major-mode 'c++-mode))
             :help "Fold #ifdef. Hotkey: Shift F10")

       (list "bookmark_add" 'cpro
             'cpro
             :help "Toggle Codepilot Read only mode")

       (list "ppcmm/note" 're
             're
             :help "Hey, take a note. Hotkey: r")

       (list "ppcmm/check-note" 'codepilot-open-remember-data-file
             'codepilot-open-remember-data-file
             :help "Check the note file.")

       (list "save" 'remember-buffer
             'remember-buffer
             :visible '(eq major-mode 'remember-mode)
             :help "Save the note. Hotkey: C-c C-c or C-x C-s")

       (list "cancel" 'remember-destroy
             'remember-destroy
             :visible '(eq major-mode 'remember-mode)
             :help "Cancel the note. Destroy the note buffer. Hotkey: C-c C-k")))

(defun codepilot-toolbar-add-form-list (ll)
  (setcdr tool-bar-map nil)
  (dolist (i ll)
    (apply 'tool-bar-add-item i)))

(defun codepilot-toolbar-type-list-from-item-list (ll)
  (let (ll2)
    (dolist (i ll)
      (push (list 'const (third i)) ll2))
    (setq ll2 (nreverse ll2))
    (push 'set ll2)
    ll2))

(defvar codepilot-toolbar-type-list nil)
(setq codepilot-toolbar-type-list (codepilot-toolbar-type-list-from-item-list codepilot-toolbar-item-list))

(defun codepilot-toolbar-add-items-from-config (ll)
  (setcdr tool-bar-map nil)
  (let (item)
    (dolist (i ll)
      (setq item (find i codepilot-toolbar-item-list :key #'third))
      (when item
        (apply 'tool-bar-add-item item)))))

(defun codepilot-toolbar-config-list-set (symbol value)
  (cond (value
	 (set-default symbol value)
	 (when codepilot-toolbar-activated
	   (codepilot-toolbar-add-items-from-config value)))
	(t
	 (codepilot-toolbar-add-form-list codepilot-toolbar-item-list))))

(defun codepilot-toolbar-init-list-from-item-list (ll)
  (let (ll2)
    (dolist (i ll)
      (push (third i) ll2))
    (setq ll2 (nreverse ll2))
    ll2))

(defcustom codepilot-toolbar-config-list (codepilot-toolbar-init-list-from-item-list codepilot-toolbar-item-list)
  "Toolbar Configuration list."
  :type codepilot-toolbar-type-list
  :set 'codepilot-toolbar-config-list-set
  :group 'codepilot-convenience)


(defvar codepilot-toolbar-orignal-tool-bar (cdr tool-bar-map))

(defun codepilot-toolbar-activate ()
  (interactive)
  (setq codepilot-toolbar-activated t)
  (codepilot-toolbar-add-items-from-config codepilot-toolbar-config-list))

(defun codepilot-toolbar-deactivate ()
  (interactive)
  (setq codepilot-toolbar-activated nil)
  (setcdr tool-bar-map codepilot-toolbar-orignal-tool-bar))

(provide 'cp-toolbar)