
;; tabbar
(require 'tabbar)
(tabbar-mode)


(defun tabbar-buffer-kill-buffer-hook ()
  "Hook run just before actually killing a buffer.
In tab bar mode, try to switch to a buffer in the current tab bar,
after the current buffer has been killed.  Try first the buffer in tab
after the current one, then the buffer in tab before.  On success, put
the sibling buffer in front of the buffer list, so it will be selected
first."
  (when (eq major-mode 'occur-mode)
    (and tabbar-mode
         (eq tabbar-current-tabset-function 'tabbar-buffer-tabs)
         (eq (current-buffer) (window-buffer (selected-window)))
         (let ((bl (tabbar-tab-values (tabbar-current-tabset)))
               (bn (buffer-name))
               found sibling)
           (while (and bl (not found))
             (if (equal bn (car bl))
                 (setq found t)
               (setq sibling (car bl)))
             (setq bl (cdr bl)))
           (when (setq sibling (or (car bl) sibling))
             ;; Move sibling buffer in front of the buffer list.
             (save-current-buffer
               (switch-to-buffer sibling)))))))

(add-hook 'kill-buffer-hook 'tabbar-buffer-kill-buffer-hook)

(provide 'mytbhack)
