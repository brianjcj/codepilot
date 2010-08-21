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


;; Misc function
;; temp function

(provide 'test)

;; (dolist (i (delete-duplicates find-tag-history :from-end t))
;;   (print i))


(defun revert-all-buffers ()
  (interactive)
  (save-current-buffer
    (dolist (buf (buffer-list))
      (set-buffer buf)
      (condition-case nil
          (revert-buffer nil t)
        (error nil)))))


(defun del-dup-lines ()
  (interactive)
  (let (line ll rstart rend)
    (if (and transient-mark-mode mark-active)
	(setq rstart (region-beginning)
	      rend (progn
		     (goto-char (region-end))
		     (unless (or (bolp) (eobp))
		       (forward-line 0))
		     (point-marker)))
      (setq rstart (point)
	    rend (point-max-marker)))
    (save-excursion
      (goto-char rstart)
      (while (and (not (eobp))
                  (< (point) rend))
        (pushnew (buffer-substring-no-properties (line-beginning-position) (line-end-position))
                 ll
                 :test #'string=)
        (forward-line))
      (with-output-to-temp-buffer "*temp*"
        (set-buffer standard-output)
        (dolist (i (nreverse ll))
          (insert i "\n"))))))

(defadvice newline-and-indent (after newline-and-indent ())
  (when (eq (char-after) ?\))
    (save-excursion
      (newline)
      (indent-according-to-mode))))

(ad-activate 'newline-and-indent)

;;(defun delete-indentation (&optional arg)

(defadvice delete-indentation (before delete-indentation (&optional arg))
  (forward-line))

(ad-activate 'delete-indentation)


(defvar mydiary-title-regex "* [0-9]\\{4\\}-[0-9]\\{1,2\\}-[0-9]\\{1,2\\}")

(defun mydiary-go-to-title-f ()
  "MyDiary"
  (interactive)
  (if (not(re-search-forward mydiary-title-regex nil t))
      (progn
        (goto-char (point-min))
        (re-search-forward mydiary-title-regex nil t))))

(defun mydiary-go-to-title-b ()
  "MyDiary"
  (interactive)
  (if (not(re-search-backward mydiary-title-regex nil t))
      (progn
        (goto-char (point-max))
        (re-search-backward mydiary-title-regex nil t))))

(defun mydiary-occur ()
  ""
  (interactive)
  (occur mydiary-title-regex))


(global-set-key [f12] 'mydiary-go-to-title-f)
(global-set-key [(shift f12)] 'mydiary-go-to-title-b)

;; (global-set-key [f11] 'mydiary-occur)

(defun mydiary-add-title ()
  "Add * yyyy-mm-dd w string"
  (interactive)
  (insert (concat "* " (format-time-string "%Y-%m-%d %A") " Çç")))

(global-set-key [(f11)] 'mydiary-add-title)


(require 'xml)

(defun my-display-xml-tree ()
  (interactive)

  (let ((str "")
        (start (point-min))
        (end (point-max)))

    (if (and transient-mark-mode mark-active)
        (setq start (region-beginning)))

    (if (and transient-mark-mode mark-active)
        (setq end (region-end)))

    (setq str (xml-parse-region start end))

    (with-output-to-temp-buffer "*XML*"
      (save-excursion
        (set-buffer standard-output)
        (pp str)
        (emacs-lisp-mode)
        (hs-minor-mode 1)))))


(defun del-bufs-of-major-mode (maj-mode)
  (dolist (buf (buffer-list))
    (when (eq (with-current-buffer buf major-mode) maj-mode)
      (dolist (win (get-buffer-window-list buf))
        (delete-window win))
      (kill-buffer buf))))

(defun del-occur-bufs ()
  (interactive)
  (del-bufs-of-major-mode 'occur-mode))


(defun pop-occur-buf ()
  ""
  (interactive)
  (catch 'loop
    (dolist (buf (buffer-list))
      (if (eq (with-current-buffer buf major-mode) 'occur-mode)
          (progn
            (pop-to-buffer buf)
            ;(fit-window-to-buffer (get-buffer-window buf) (/ (frame-height) 2))
            (shrink-window-if-larger-than-buffer (get-buffer-window buf))
            (throw 'loop t))))))




(if (eq system-type 'windows-nt)
    (defvar my-temp-dir "D:/brian-temp/")
  (defvar my-temp-dir "~/.brian-temp/"))

;; open a new temp file for easily edit something temporarily.

(defun open-a-temp-file ()
  ""
  (interactive)
  (unless (file-directory-p my-temp-dir)
    (make-directory my-temp-dir))
  (find-file (let ((temporary-file-directory my-temp-dir)) (make-temp-file "brian"))))

(global-set-key [f9] 'open-a-temp-file)

(defun my-ediff-temp-files ()
  ""
  (interactive)

  (let (file-A file-B)
    (unless (file-directory-p my-temp-dir)
      (make-directory my-temp-dir))
    (let ((temporary-file-directory my-temp-dir))
      (setq file-A (make-temp-file "brian"))
      (setq file-B (make-temp-file "brian")))

    (ediff-files file-A file-B)))


(defun my-close-temp-files ()
  (interactive)
  (let ((temp-dir (file-name-as-directory (expand-file-name my-temp-dir)))
        (fname ""))
    (dolist (buf (buffer-list))
      (when (and (setq fname (buffer-file-name buf))
                 (string= (file-name-directory fname)
                          temp-dir
                          ))
        (dolist (win (get-buffer-window-list buf))
          (ignore-errors
            (delete-window win)))
        (kill-buffer buf)))))



