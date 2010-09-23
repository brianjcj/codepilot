

(setq mydir
      (file-name-directory
       (or load-file-name (buffer-file-name))))

(setq myoptdir (concat mydir "../opt/"))


(defun my-hide/show-entry ()
  (interactive)
  (let ((ol (save-excursion
             (end-of-line)
             (overlays-at (point)))))
    (cond (ol
           (dolist (o ol)
             (cond ((eq 'outline (overlay-get o 'invisible))
                    (show-entry)
                    (return))
                   (t
                    (hide-entry)))))
          (t
           (hide-entry)))
   ))

(require 'outline)
(define-key outline-mode-map [(f7)] 'hide-body)
(define-key outline-mode-map [(f10)] 'my-hide/show-entry)
(define-key outline-minor-mode-map [(f7)] 'hide-body)
(define-key outline-minor-mode-map [(f10)] 'my-hide/show-entry)


;; (autoload 'flyspell-mode "flyspell" "On-the-fly spelling checking" t)
;; (autoload 'global-flyspell-mode "flyspell" "On-the-fly spelling" t)
;; (global-flyspell-mode t)


;; (add-hook 'text-mode-hook (lambda () (turn-on-auto-fill)))



;; Change the outline prefix command for C-c @ to C-o
(setq outline-minor-mode-prefix [(control o)])



;; htmlize
(require 'htmlize)


;; ;; =====CEDET============
(defun ce ()
  (interactive)

  ;; cvs version. 8-14-2009
  (load-file (concat myoptdir "cedet/common/cedet.el"))
  ;; (global-ede-mode t) ;; project support!
  (semantic-load-enable-excessive-code-helpers)
  (require 'semantic-ia)
  (require 'semantic-gcc)

  ;; (semantic-add-system-include "~/exp/include/boost_1_37" 'c++-mode)
  )


;; ;; ======ECB========

(defun lecb ()
  (interactive)
  ;; ecb
  (add-to-list 'load-path (concat myoptdir "ecb-2.32"))
  (require 'ecb-autoloads)
  )

;; (require 'ecb)
;; ;;(require 'ecb-autoloads)


;; Call "M-x ecb-activate" to activated ECB.

;; Call "M-x ecb-customize-most-important" to get a list of the most important
;; options of ECB. These are options you should at least know that they exist.

;; Call "M-x ecb-show-help" to get a detailed online-help for ECB. If you are
;; using ECB the first time you should read the online help accurately!

;; ;; =====End of ECB======


(defun s-serv ()
  ""
  (interactive)
  (server-start)
  ;; (setq frame-title-format "[%b@emacs]")
  ;; (setq global-hl-line-mode nil)
  )

;; (s-serv)


;; ispell
;; (add-to-list 'Info-default-directory-list "c:/usr/local/info/")


(defun w32-restore-frame ()
  "Restore a minimized frame"
  (interactive)
  (w32-send-sys-command 61728))

(defun w32-maximize-frame ()
  "Maximize the current frame"
  (interactive)
  (w32-send-sys-command 61488))


;; (add-hook 'after-make-frame-functions 'w32-maximize-frame)



(defalias 'bl 'emacs-lisp-byte-compile-and-load)
(defalias 'll 'longlines-mode)


;; clisp/slime
;; ==============================================================================================
(defun load-slime ()
  (interactive)
  (add-to-list 'load-path (concat myoptdir "slime-2.0"))  ; your SLIME directory
  (setq inferior-lisp-program "C:/clisp-2.41-win32-with-readline-and-gettext/clisp-2.41/clisp -K full") ; your Lisp system
  (require 'slime)
  (slime-setup)

  (define-key slime-mode-map (kbd "(") 'insert-parentheses)
  (define-key slime-mode-map (kbd ")") 'move-past-close-and-reindent)
  (define-key slime-mode-map (kbd ")") 'up-list)

  (define-key emacs-lisp-mode-map (kbd "C-c C-q") 'slime-close-parens-at-point)
  )

;; Common Lisp indentation.
(autoload 'common-lisp-indent-function "cl-indent")
;;(setq lisp-indent-function 'common-lisp-indent-function)

(add-hook 'lisp-mode-hook (lambda ()
                            (local-set-key "\r" 'newline-and-indent)
                            (setq lisp-indent-function 'common-lisp-indent-function)
                            (setq indent-tabs-mode nil)
                            (hs-minor-mode 1)
                            ))


;; Emacs Lisp mode, auto indent.
(add-hook 'emacs-lisp-mode-hook (lambda ()
                                  (local-set-key "\r" 'newline-and-indent)
                                  (hs-minor-mode 1)
                                  ))

;; Original value: "http://www.lispworks.com/reference/HyperSpec/"
(setq common-lisp-hyperspec-root "file:///E:/ftp/clisp/lispworks-box-4.0/lib/5-0-0-0/manual/online/web/CLHS/")


(define-key emacs-lisp-mode-map (kbd "(") 'insert-parentheses)
;;(define-key emacs-lisp-mode-map (kbd ")") 'move-past-close-and-reindent)
(define-key emacs-lisp-mode-map (kbd ")") 'up-list)


(modify-syntax-entry ?- "w" emacs-lisp-mode-syntax-table)
;; (modify-syntax-entry ?- "w" python-mode-syntax-table)


;; lisp: for convenient
(defun uplp ()
  "Close current block with addition paren"
  (interactive)
  (let (pip)
    (save-excursion
      (save-match-data
        (unless (looking-at "(")
          (backward-up-list))
        (setq pip (point))
        (insert "(")
        (forward-list)
        (insert ")")
        (goto-char pip)
        ;;(indent-pp-sexp)
        ))
    (when pip
      (goto-char (+ pip 1)))
    ))

(global-set-key "\M-`" 'uplp)

(defun inddefun ()
  "indent defun"
  (interactive)
  (save-excursion
    (beginning-of-defun)
    (indent-pp-sexp)
    ))

(defun preg ()
  "Paren the region"
  (interactive)
  (when (and transient-mark-mode mark-active)
    (let (b)
      (if (> (point)
             (mark))
          (exchange-point-and-mark))
      (goto-char (point))
      (lisp-indent-line)
      (setq b (point))
      (goto-char (mark))
      (skip-chars-backward "\n\t\s")
      (insert ")")
      (goto-char b)
      (insert "(")
      (goto-char (+ b 1))
      )))

(defun unpb ()
  "Un-paren block."
  (interactive)
  (let ((pos (point)))
    (save-excursion
      (backward-up-list)
      (delete-region (1+ (point)) pos)
      (delete-pair)
      (inddefun)
      )))

;; ======================================================

(defun ht ()
  "tag -> <tag> </tag>"
  (interactive)
  (let ((cw (current-word))
        (pos))
    (re-search-backward "\\_<")
    (kill-word 1)
    (insert (concat "<" cw ">\n"))
    (indent-according-to-mode)
    (setq pos (point))
    (insert "\n")
    (insert (concat "</" cw ">"))
    (indent-according-to-mode)
    (goto-char pos)
    ))

(defun hl ()
  "tag -> <tag> </tag>"
  (interactive)
  (let ((cw (current-word))
        (pos))
    (re-search-backward "\\_<")
    (kill-word 1)
    (insert (concat "<" cw ">"))
    (setq pos (point))
    (insert (concat "</" cw ">"))
    (goto-char pos)
    ))


(add-hook 'python-mode-hook (lambda () (local-set-key "\r" 'newline-and-indent)))


;; MUSE
;; ===========================================
(add-to-list 'load-path (concat myoptdir "muse-3.12/lisp"))

(require 'muse-mode)     ; load authoring mode

(require 'muse-html)     ; load publishing styles I use
;(require 'muse-latex)
;(require 'muse-texinfo)
;(require 'muse-docbook)
(require 'muse-colors)
(require 'muse-wiki)
;(setq muse-wiki-allow-nonexistent-wikiword t)

(require 'muse-project)  ; publish files in projects


;;(setq muse-html-style-sheet "d:/WiKi/core.css")
(setq muse-html-style-sheet "<link rel=\"stylesheet\" type=\"text/css\" charset=\"utf-8\" media=\"all\" href=\"./core.css\" />")

(setq muse-xhtml-style-sheet "<link rel=\"stylesheet\" type=\"text/css\" charset=\"utf-8\" media=\"all\" href=\"./core.css\" />")

(muse-derive-style "wiki-xhtml" "xhtml"
           ;;:header "~/.journal/header.html"
           ;;:footer "~/.journal/footer.html"
           :style-sheet "<link rel=\"stylesheet\" type=\"text/css\" charset=\"utf-8\" media=\"all\" href=\"./core.css\" />")
                                        ; Self-defined style
(setq muse-project-alist
      '(
;;         ("Wiki"
;;          ("/media/d/text/wiki" :default "index")
;;          (:base "wiki-xhtml"
;;           :path "/media/d/text/wiki/publish"
;;           :force-publish ("WikiIndex")))
        ("WiKi"
         ("d:/WiKi/" :default "index")
         (:base "wiki-xhtml"
          :path "d:/publish"))

;;      ("WikiPlanner"
;;              ("d:/plans"   ;; Or wherever you want your planner files to be
;;              :default "index"
;;              :major-mode planner-mode
;;           :visit-link planner-visit-link))
        ))

(defvar muse-css-file)
(setq muse-css-file "D:/publish/core.css")

(defun muse-publish-file-imbed-css ()
  ""
  (interactive)
  (let* ((sheet (concat "<STYLE TYPE=\"text/css\">\n<!--\n<lisp> (progn (insert-file-contents \""
                        muse-css-file
                        "\") nil)</lisp>\n-->\n</STYLE>"))
         (muse-html-style-sheet sheet)
         (muse-xhtml-style-sheet sheet))
    (muse-project-publish-this-file)
    ))

(add-hook 'muse-mode-hook 'outline-minor-mode)


;; support "DEFUN" in emacs source codes:
(require 'cc-menus)
(setq cc-imenu-c-generic-expression
      (append cc-imenu-c-generic-expression '(("Defun" "^DEFUN[ \t]*([ \t]*\"\\([a-zA-Z0-9-]+\\)\"" 1))))



;; ===Muse===Skeleton===
(define-skeleton exm
  "Muse <example> </example> make up"
  nil
  "<example>\n"
  _ "\n"
  "</example>\n"
  )

(define-skeleton src
  "Insert scr tag in Muse"
  nil
  "<src lang=\"" (skeleton-read "Lang name: " "lisp") "\">\n"
  _ "\n"
  "</src>\n"
  )

;; ====elisp skeleton====
(define-skeleton defi
  ""
  nil
  "(defun " (skeleton-read "Proc name: ") " ()\n"
  > "\"\"\n"
  > "(interactive)\n"
  > "(let ((case-fold-search t))\n"
  > "(save-excursion\n"
  > "(save-match-data\n"
  > _ "\n"
  > "))\n"
  > "))"
  )



;; ===snippet===
(require 'snippet)

(defun defk ()
  (interactive)
  (snippet-insert (concat "(defun $${proc-name} ($$)\n"
                          "$>\"$${Document string:}\"\n"
                          "$>(interactive$$)\n"
                          "$>(let ((case-fold-search t))\n"
                          "$>(save-excursion\n"
                          "$>(save-match-data\n"
                          "$>$.\n"
                          "$>))\n"
                          "$>))")))

(defun ss ()
  (interactive)
  (snippet-insert "\"$${string...}\"")
  )


(defun pse ()
  (interactive)
  (delete-char -1)
  (snippet-insert "(\"$${String....}\\n\"$$)$.")
  )


;; ;; (setq last-kbd-macro
;; ;;    [?\M-b ?\M-@ ?\M-w ?\C-s ?\M-y ?\C-s])
;; ;; [134217826 134217792 134217847 19 134217849 19]

;; (fset 'search-id
;;    (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([134217826 134217792 134217847 19 134217849 19] 0 "%d")) arg)))
;; (global-set-key [(f3)] 'search-id)


;** line-move-ignore-invisible now defaults to t.



;; Org mode
(require 'org-install)
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)
(setq org-hide-leading-stars t)

;; (setq org-agenda-files (list "d:/org/work.org"
;;                           "d:/org/school.org"
;;                           "d:/org/home.org"))

(setq org-directory "d:/org/")

;; (appt-activate 1)

(defun bzg-org-agenda-to-appt ()
  "Activate appointments found in `org-agenda-files'."
  (interactive)
  (require 'org)
  (let* ((today (org-date-to-gregorian
                 (time-to-days (current-time))))
         (files org-agenda-files)
         entries file)
    (while (setq file (pop files))
      (setq entries (append entries (org-agenda-get-day-entries
                                     file today :timestamp))))
    (mapc (lambda(x)
            (let* ((event (org-trim (get-text-property 1 'txt x)))
                   (time (number-to-string
                          (get-text-property 1 'time-of-day x)))
                   (time-st (concat (substring time 0 2) ":"
                                    (substring time 2 4))))
              (appt-add time-st event))) entries)))

(require 'appt)
(defun appt-list ()
  "List all the Appt"
  (interactive)
  (with-output-to-temp-buffer "*Appt-list*"
    (save-excursion
      (set-buffer standard-output)
      (dolist (el appt-time-msg-list)
        (insert (nth 1 el) "\n")))))

;; org and remember....
;; (setq org-default-notes-file "~/.notes")
;; (setq remember-annotation-functions '(org-remember-annotation))
;; (setq remember-handler-functions '(org-remember-handler))
;; (add-hook 'remember-mode-hook 'org-remember-apply-template)

;; (setq org-remember-templates
;;       '((?t "* TODO %?\n  %i\n  %a\n" "d:/org/MiscTask.org")
;;         (?j "* %?\n%i\n   %a   %U\n\n----" "c:/.notes")
;;         (?i "* %^{Title}\n   %i\n   %a   %U\n\n----" "c:/.notes" "Quick Notes")))



;; (windmove-default-keybindings)
;;(setq windmove-wrap-around t)


;; Remove the print-buffer button in the tool bar.
;; ===============================================
(delete-if (lambda (button)
             (and (consp button)
                  (eq (car button) 'print-buffer)))
           tool-bar-map)



;; Erlang
;; ---------------------

;; (add-to-list 'load-path "C:/Program Files/erl5.5.5/lib/tools-2.5.5/emacs")
;; (setq erlang-root-dir "C:/Program Files/erl5.5.5")
;; ;;(setq exec-path (cons "C:/Program Files/erl5.5.5/bin" exec-path))
;; (add-to-list 'exec-path "C:/Program Files/erl5.5.5/bin")
;; (require 'erlang-start)

(defun load-erl ()
  ""
  (interactive)
  (cond ((eq system-type 'gnu/linux)
         (add-to-list 'load-path "/usr/lib/erlang/lib/tools-2.6.4/emacs")
         ;; (setq erlang-root-dir "/usr/local/otp")
         ;; (setq exec-path (cons "/usr/local/otp/bin" exec-path))
         (require 'erlang-start))))


;; ;; ACL
;; ;; ------------------
;; ;;(load "C:/Program Files/acl81-express/eli/fi-site-init.el")
;; ; This is sample code for starting and specifying defaults to the
;; ; Emacs-Lisp interface. Uncomment this code if you want the ELI
;; ; to load automatically when you start emacs.
;; (push "C:/Program Files/acl81-express/eli" load-path)
;; (load "fi-site-init.el")
;; ;
;; ;; (setq fi:common-lisp-image-name "C:/Program Files/acl81-express/mlisp.exe")
;; ;; (setq fi:common-lisp-image-file "C:/Program Files/acl81-express/mlisp.dxl")
;; (setq fi:common-lisp-image-name "C:/Program Files/acl81-express/allegro-express.exe")
;; (setq fi:common-lisp-image-file "C:/Program Files/acl81-express/allegro-express.dxl")
;; (setq fi:common-lisp-directory "C:/Program Files/acl81-express")

;; (defun run-lisp ()
;;   (interactive)
;;   (fi:common-lisp "*common-lisp*"
;;                   "c:/program files/acl81-express/"
;;                   "c:/program files/acl81-express/allegro-express.exe"
;;                   '("+B" "+cn")
;;                   "localhost"
;;                   "c:/program files/acl81-express/allegro-express.dxl"))



(setq slime-multiprocessing t)
(setq *slime-lisp* "allegro-express.exe")
(setq *slime-port* 4006)

;; (add-to-list 'exec-path "C:/Program Files/acl81-express")
(setenv "PATH" (concat (getenv "PATH") ";C:\\Program Files\\acl81-express"))

(defun acl-slime ()
  (interactive)
  (shell-command
   (format "%s +B +cm -L c:/.slime.lisp -- -p %s --ef %s &"
           *slime-lisp* *slime-port*
           slime-net-coding-system))
  (delete-other-windows)
  (while (not (ignore-errors (slime-connect "localhost" *slime-port*)))
    (sleep-for 0.2)))

(add-to-list 'auto-mode-alist '("\\.cl$" . lisp-mode))


;; ;; Color Theme
;; (add-to-list 'load-path (concat myoptdir "color-theme-6.6.0"))
;; (require 'pink-bliss)

;; (require 'mycolor)

;; (defalias 'pink 'color-theme-pink-bliss)
;; (defalias 'cold 'color-theme-pok-wog)


;; Anything!!!!
;; ==================
(require 'anything)
(require 'anything-config)

(setq w32-pass-lwindow-to-system nil)
(setq w32-lwindow-modifier 'hyper)

(global-set-key [(hyper ?\h)] 'anything)

;; ----mark----
(global-set-key [(control f6)] 'push-mark-command)
(global-set-key [(meta f6)] 'pop-to-mark-command)

;; Regex-tool
;; ===========================
;; (load "regex-tool" t)    ; load regex-tool if it's available


;; Misc
;; ===============

;; (global-set-key "\C-x\C-m" 'execute-extended-command)

(define-key text-mode-map "\C-d" 'backward-kill-word)



;; Ruby
;; ================
(defun load-ruby ()
  ""
  (interactive)
  (require 'find-recursive)
  ;; (require 'snippet)
  (add-to-list 'load-path "F:/Ruby/misc")
  (add-to-list 'load-path (concat myoptdir "emacs-rails"))
  (require 'rails)

  (define-skeleton qq
    "<% -%>"
    nil
    "<%" _ " %>"
    )
  )


;;   nxhtml
;; =================
;; (load (concat myoptdir "nxhtml/autostart.el"))


(define-skeleton aa
  ""
  nil
  "{% " _ " %}"
  )

;; VI keys:
;; ===================
(global-set-key [(hyper ?j)] 'next-line)
(global-set-key [(hyper ?k)] 'previous-line)
(global-set-key [(hyper ?h)] 'backward-char)
;; (global-set-key [(hyper ?l)] 'forward-char)

(require 'callplot)

;; ciciles
;; ============

;; (add-to-list 'load-path (concat myoptdir "icicles"))

(defalias 'c 'calculator)



;; color
(when (eq system-type 'windows-nt)
  (w32-define-rgb-color 204 232 207 "Nice Green")
  (set-background-color "Nice Green")
  (push '(background-color . "Nice Green") default-frame-alist))


(when (eq system-type 'windows-nt)
  ;; (push '(font . "-outline-DejaVu Sans Mono-normal-r-normal-normal-13-97-96-96-c-*-iso8859-1")
  ;;       default-frame-alist)
  ;; (set-frame-font "-outline-DejaVu Sans Mono-normal-r-normal-normal-13-97-96-96-c-*-iso8859-1")

  ;; ÑÅºÚ
  ;; (set-default-font "YaHei Consolas Hybrid-13")
  (set-fontset-font (frame-parameter nil 'font)
                    'han '("Î¢ÈíÑÅºÚ". "unicode-bmp"))
  (set-fontset-font (frame-parameter nil 'font)
                    'cjk-misc '("Î¢ÈíÑÅºÚ" . "unicode-bmp"))
  (set-fontset-font (frame-parameter nil 'font)
                    'bopomofo '("Î¢ÈíÑÅºÚ" . "unicode-bmp"))
  (set-fontset-font (frame-parameter nil 'font)
                    'gb18030 '("Î¢ÈíÑÅºÚ". "unicode-bmp"))
  (set-fontset-font (frame-parameter nil 'font)
                    'symbol '("Î¢ÈíÑÅºÚ". "unicode-bmp")))





;; company mode:
(add-to-list 'load-path (concat myoptdir "company-0.5"))
(autoload 'company-mode "company" nil t)


;; js2-mode
(defun load-js2 ()
  (interactive)
  (when (> emacs-major-version 22)
    (provide 'js2-mode)
    (autoload 'js2-mode "js2" nil t)
    (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
    ))


(when (eq system-type 'windows-nt)
  (setq find-program "find1")
  )


;; haskell

(defun load-haskell ()
  (interactive)
  (add-to-list 'load-path (concat myoptdir "haskell-mode-2.4"))
  (load (concat myoptdir "haskell-mode-2.4/haskell-site-file"))
  (add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
  (add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
  ;;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)


  (add-hook 'haskell-mode-hook
            (lambda ()
              (interactive)
              (define-key haskell-mode-map "\C-c\C-f" 'haskell-hoogle)))
  )

(load-haskell)


;; javascript mode
(autoload #'espresso-mode "espresso" "Start espresso-mode" t)
(add-to-list 'auto-mode-alist '("\\.js$" . espresso-mode))
(add-to-list 'auto-mode-alist '("\\.json$" . espresso-mode))

(add-hook 'espresso-mode-hook 'hs-minor-mode)


;; php mode
(add-to-list 'load-path (concat myoptdir "php-mode-1.5.0"))
(require 'php-mode)
(add-to-list 'auto-mode-alist '("\\.module$" . php-mode))

;; Load the php-imenu index function
(autoload 'php-imenu-create-index "php-imenu" nil t)
;; Add the index creation function to the php-mode-hook
(add-hook 'php-mode-hook 'php-imenu-setup)
(defun php-imenu-setup ()
  (setq imenu-create-index-function (function php-imenu-create-index))
  ;; uncomment if you prefer speedbar:
  ;;(setq php-imenu-alist-postprocessor (function reverse))
  ;; (imenu-add-menubar-index)
  )


(pushnew 'php-mode codepilot-cc-major-modes)



;; desktop
;; M-x desktop-save
;; It's better put this near the end of the file so that the
;; desktop info will not be destroyed when the init file has problem.
;;
(load "desktop")
(desktop-save-mode)


