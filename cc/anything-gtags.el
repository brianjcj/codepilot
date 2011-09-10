
(require 'anything-config)

;; (defvar anything-c-global-command "global -iP %s")
;; (setq anything-c-global-command "global -iP %s")
(defvar anything-c-global-program "global")

(defvar anything-buffer-mode-map (make-sparse-keymap)
  "Keymap used in anything buffer.")
(define-key anything-buffer-mode-map [mouse-3] (lambda (e)
                                                 (interactive "e")
                                                 (mouse-set-point e)
                                                 (anything-mark-current-line)
                                                 (anything-exit-minibuffer)
                                                 ))


(defun anything-c-gtags-path-init ()
  "Initialize async global process for `anything-c-source-global'."

  (with-current-buffer anything-buffer
    (use-local-map anything-buffer-mode-map))
  
  (setq mode-line-format
        '(" " mode-line-buffer-identification " "
          (line-number-mode "%l") " "
          (:eval (propertize "(Global Process Running) "
                             'face '((:foreground "red"))))))
  (let ((default-directory anything-ff-default-directory))
    (prog1
        ;; (start-process-shell-command "global-process" nil (format anything-c-global-command anything-pattern))
        (start-process "global-process" nil anything-c-global-program "-iP" anything-pattern)
      (set-process-sentinel (get-process "global-process")
                            #'(lambda (process event)
                                (when t;; (or (string= event "finished\n") (ignore-errors  (string= (substring event 0 6) "exited")))
                                  (with-anything-window
                                    (setq mode-line-format
                                          '(" " mode-line-buffer-identification " "
                                            (line-number-mode "%l") " "
                                            (:eval (propertize "(Global Process Finished) "
                                                               'face '((:foreground "red"))))))
                                    (force-mode-line-update)
                                    (anything-update-move-first-line))))))))


(defvar anything-c-source-gtags-path
  '((name . "Gtags-path")
    (candidates . anything-c-gtags-path-init)
    (type . file)
    (properties-action . anything-ff-properties)
    (requires-pattern . 3)
    (mode-line . anything-generic-file-mode-line-string)
    (delayed))
  "Find files matching the current input pattern with gtags-path.")


(defun anything-gtags-path (input)
  ""
  (interactive "sFile path pattern: ")

  (multiple-value-bind (ret sidebar code-win bottom-win)
      (codepilot-window-layout-wise)
    (when code-win
      (select-window code-win)))
    
    
  (let ((buf-o (current-buffer))
        buf)
    (setq anything-ff-default-directory default-directory)
    (anything :sources 'anything-c-source-gtags-path
              :buffer "*anything global*"
              :input input
              :keymap anything-generic-files-map)

    (setq buf (current-buffer))
    (when (not (eq buf buf-o))
      (with-current-buffer buf-o
        (codepilot-push-marker)))))


(define-key anything-command-map (kbd "g") 'anything-gtags-path)
(define-key codepilot-ro-mode-map "p" 'anything-gtags-path)


(provide 'anything-gtags)


