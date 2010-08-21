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


(defadvice semantic-complete-jump (before codepilot-history ())
  (run-hooks 'codepilot-pre-pop-or-switch-buffer-hook))

(ad-activate 'semantic-complete-jump)

(defsubst mysemantic-format-class-name (name)
  ;; v8::internal::Factory
  ;; => Factory [v8::internal]
  (if (string-match "^\\(.+?\\)::\\([^:]+\\)$" name)
      (concat  (match-string 2 name) " [" (match-string 1 name) "]")
    name))

(defun mysemantic-format-tag-canonical-name (tag &optional parent color)
  "Return a canonical name for TAG.
A canonical name includes the names of any parents or namespaces preceding
the tag with colons separating them.
Optional argument PARENT is the parent type if TAG is a detail.
Optional argument COLOR means highlight the prototype with font-lock colors."
  (let ((parent-input-str
	 (if (and parent
		  (semantic-tag-p parent)
		  (semantic-tag-of-class-p parent 'type))
	     (concat
	      ;; Choose a class of 'type as the default parent for something.
	      ;; Just a guess though.
	      (semantic-format-tag-name-from-anything parent nil color 'type)
	      ;; Default separator between class/namespace and others.
	      semantic-format-parent-separator)
	   ""))
	(tag-parent-str
	 (or (when (and (semantic-tag-of-class-p tag 'function)
			(semantic-tag-function-parent tag))
	       (concat " [" (semantic-tag-function-parent tag)
		       semantic-format-parent-separator "]"))
	     ""))
        name)
    (setq name (semantic-format-tag-name tag parent color))
    (when (semantic-tag-of-class-p tag 'variable)
      (setq name (mysemantic-format-class-name name)))
    (concat parent-input-str
	    ;; tag-parent-str
	    name
            tag-parent-str)))


(defun mysemantic-format-tag-abbreviate (tag &optional parent color)
  "Return an abbreviated string describing TAG.
Optional argument PARENT is a parent tag in the tag hierarchy.
In this case PARENT refers to containment, not inheritance.
Optional argument COLOR means highlight the prototype with font-lock colors.
This is a simple C like default."
  ;; Do lots of complex stuff here.
  (let ((class (semantic-tag-class tag))
	(name (mysemantic-format-tag-canonical-name tag parent color))
	(suffix "")
	(prefix "")
	str)
    (cond ((eq class 'function)
	   (setq suffix "()"))
	  ((eq class 'include)
	   (setq suffix "<>"))
	  ((eq class 'variable)
	   (setq suffix (if (semantic-tag-variable-default tag)
			    "=" "")))
	  ((eq class 'label)
	   (setq suffix ":"))
	  ((eq class 'code)
	   (setq prefix "{"
		 suffix "}"))
	  ((eq class 'type)
	   (setq suffix "{}"))
	  )
    (setq str (concat prefix name suffix))
    str))

(setq-default semantic-imenu-summary-function 'mysemantic-format-tag-abbreviate)

(provide 'mysemantic)