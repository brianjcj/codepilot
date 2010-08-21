
(defun codepilot-remember-annotation ()
  (interactive)
  (let ((file (buffer-file-name))
        str index)
    (condition-case nil
        (progn (setq index (which-function))
               (setq index (if (atom index) index (car index))))
      (error nil))
    (when index
      (setq str (concat "===> " index "\n")))
    (when file
      (setq str (concat str "[[" file "]<"
                        (int-to-string (line-number-at-pos)) "><" (int-to-string (point)) ">]")))
    str))

(setq remember-annotation-functions '(codepilot-remember-annotation))


(defun codepilot-remember-append-to-file ()
  "Remember, with description DESC, the given TEXT."
  (let ((text (buffer-substring (point-min) (point-max))))
    (setq text (concat (replace-regexp-in-string "\n" (concat "\n" "   ") text)))
    (with-temp-buffer
      (insert "\n" remember-leader-text text)
      (if (not (bolp))
          (insert "\n"))
      (if (find-buffer-visiting remember-data-file)
          (let ((remember-text (buffer-string)))
            (set-buffer (get-file-buffer remember-data-file))
            (save-excursion
              (goto-char (point-max))
              (insert remember-text)
              (when remember-save-after-remembering (save-buffer))))
        (append-to-file (point-min) (point-max) remember-data-file)))))

(setq remember-handler-functions '(codepilot-remember-append-to-file))

(defun re-1 (&optional initial)
  "Remember an arbitrary piece of data.
With a prefix, uses the region as INITIAL."
  (interactive
   (list (when current-prefix-arg
           (buffer-substring (point) (mark)))))
  (window-configuration-to-register remember-register)
  (let* ((annotation
          (if remember-run-all-annotation-functions-flag
              (mapconcat 'identity
                         (delq nil (mapcar 'funcall remember-annotation-functions))
                         "\n")
            (run-hook-with-args-until-success
             'remember-annotation-functions)))
         (buf (get-buffer-create remember-buffer)))
    (run-hooks 'remember-before-remember-hook)
    ;; (split-window)
    (switch-to-buffer-other-window buf)
    (remember-mode)
    (when (= (point-max) (point-min))
      (when initial (insert initial))
      (setq remember-annotation annotation)
      (when remember-initial-contents (insert remember-initial-contents))
      (when (and (stringp annotation)
                 (not (equal annotation "")))
        (insert "\n\n" annotation))
      (setq remember-initial-contents nil)
      (goto-char (point-min))
      (forward-line))
    (message "Use C-c C-c to remember the data.")))

(defun re ()
  ""
  (interactive)
  (let (index
        (text codepilot-current-search-text))
    (condition-case nil
        (progn (setq index (which-function))
               (setq index (if (atom index) index (car index))))
      (error nil))
    (when index
      (setq text (concat text " in " index)))
    (re-1 text)))

(defun re-r ()
  ""
  (interactive)
  (let (index
        (text codepilot-current-search-text))
    (condition-case nil
        (progn (setq index (which-function))
               (setq index (if (atom index) index (car index))))
      (error nil))
    (when index
      (setq text (concat text " in " index)))
    (re-1 (concat text "\n"
                (buffer-substring (point) (mark))))))


(provide 'myremember)

