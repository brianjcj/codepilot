
(defvar codepilot-dir
  (file-name-directory
   (or load-file-name (buffer-file-name))))


(add-to-list 'load-path (expand-file-name "common" codepilot-dir))
(add-to-list 'load-path (expand-file-name "cc" codepilot-dir))
(add-to-list 'load-path (expand-file-name "hack" codepilot-dir))
(add-to-list 'load-path (expand-file-name "misc" codepilot-dir))
(add-to-list 'load-path (expand-file-name "import" codepilot-dir))

(add-to-list 'exec-path (expand-file-name "bin" codepilot-dir))


(load (concat codepilot-dir "misc/mymisc.elc"))


(require 'cp-layout)
(require 'cp-toolbar)
(require 'cplist)
(require 'cphistory)
(require 'cpnote)
(require 'cp-mark)
(require 'cpfilter)
(require 'cp-hl)
(require 'myocchack)
(require 'mytbhack)
(require 'myremember)
(require 'cpimenu)
(require 'cp-toolbar)
(require 'myishack)


(require 'myhshack)
(require 'mytbhack)

(require 'smart-hl)
(require 'mycutil)
(require 'myctagsmenu)
(require 'mypython)
(require 'cp-cc)
(require 'mysemantic)



;; VS and UtraEdit style bookmark:
;; (require 'bm)

;; (global-set-key (kbd "<C-f2>") 'bm-toggle)
;; (global-set-key (kbd "<f2>")   'bm-next)
;; (global-set-key (kbd "<M-f2>") 'bm-previous)
;; (global-set-key (kbd "<S-f2>") 'bm-show)

;; (define-key bm-show-mode-map [mouse-3] (lambda (e)
;;                                          (interactive "e")
;;                                          (mouse-set-point e)
;;                                          (bm-show-goto-bookmark)
;;                                          ))

;; cscope
;; ===============================
(require 'xcscope)

;; Global
;; =================================
(autoload 'gtags-mode "gtags" "" t)



;; config

;; (global-set-key "\M-n" 'ido-goto-symbol)
;; (global-set-key "\M-n" 'cpimenu-go)

(codepilot-ro-toggle-globally)




(add-hook 'c-mode-hook (lambda () (gtags-mode 1)
                         (hs-minor-mode 1)
                         (hide-ifdef-mode 1)
                         (local-set-key "\r" 'newline-and-indent)
                         (local-set-key "\C-ci" 'mygtags-insert-gtag)
                         (local-set-key "\C-co" 'mygtags-insert-gsym)
                         ))

(add-hook 'c++-mode-hook (lambda () (gtags-mode 1)
                           (hs-minor-mode 1)
                           (hide-ifdef-mode 1)
                           (local-set-key "\r" 'newline-and-indent)
                           (local-set-key "\C-ci" 'mygtags-insert-gtag)
                           (local-set-key "\C-co" 'mygtags-insert-gsym)
                           ))


;; (add-hook 'gtags-mode-hook (lambda () (local-set-key "\er" 'gtags-find-rtag)))




(add-hook 'java-mode-hook (function cscope:hook))
(add-hook 'java-mode-hook (lambda ()
                            (gtags-mode 1)
                            (local-set-key "\r" 'newline-and-indent)
                            (local-set-key "\C-ci" 'mygtags-insert-gtag)
                            (local-set-key "\C-co" 'mygtags-insert-gsym)
                            (hs-minor-mode 1)))

(require 'which-func)
(when (listp which-func-modes)
  (cl-pushnew 'objc-mode which-func-modes))

(require 'cplist-cc)
(add-hook 'find-file-hook 'cplist-update-buffer-list)
(add-hook 'dired-mode-hook 'cplist-update-dired-list)
(add-hook 'cplist-fill-contents-hook 'cplist-cc-fill-cplist)
(add-hook 'cplist-action-hook 'cplist-cc-for-cplist-action)
(add-hook 'cplist-delete-history-entry 'tag-delete-in-tag-history)

(define-key cplist-mode-map "\r" 'cplist-action)
(define-key cplist-mode-map "\t" 'cplist-cc-tab)
;; (define-key cplist-mode-map "\M-n" 'cpfilter-erase)



(defun brian-activate-codepilot-cc ()
  (interactive)

  (codepilot-layout-activate)
  (codepilot-toolbar-activate)
  (cpimenu-activate)

  ;; (setq lazy-highlight-cleanup nil)
  )

(defun brian-deactivate-codepilot-cc ()
  (interactive)
  (codepilot-layout-deactivate)
  (codepilot-toolbar-deactivate)
  (cpimenu-activate)
  )

(face-spec-set 'bm-face '((((class color)
                            (background light))
                           (:background "yellow"))))


(global-set-key [(f12)] 'smart-hl-current-word)
(defalias 'st 'smart-hl-text)

(global-set-key "\C-xw" 'jump-to-h-c-file)
(global-set-key "\C-x," 'codepilot-previous-buffer)
(global-set-key "\C-x." 'codepilot-forward-buffer)


;; codepilot-ro-mode-map key mapping

(define-key codepilot-ro-mode-map "s" 'cscope-find-this-symbol)
(define-key codepilot-ro-mode-map "d" 'cscope-find-global-definition)
(define-key codepilot-ro-mode-map "g" 'cplist-update)  ;; brian
(define-key codepilot-ro-mode-map "G" 'cscope-find-global-definition-no-prompting)
(define-key codepilot-ro-mode-map "c" 'cscope-find-functions-calling-this-function)
(define-key codepilot-ro-mode-map "C" 'cscope-find-called-functions)
(define-key codepilot-ro-mode-map "t" 'cscope-find-this-text-string)
(define-key codepilot-ro-mode-map "e" 'cscope-find-egrep-pattern)
;; (define-key codepilot-ro-mode-map "f" 'cscope-find-this-file)
;; (define-key codepilot-ro-mode-map "i" 'cscope-find-files-including-file)
(define-key codepilot-ro-mode-map "-" 'cp-pb-which-procs-i-in)
(define-key codepilot-ro-mode-map "[" 'cp-pb-search-id-and-which-procs)
(define-key codepilot-ro-mode-map "]" 'mycutil-cp-pb-where-we-are)
(define-key codepilot-ro-mode-map [(f6)] 'mycutil-which-block)
(define-key codepilot-ro-mode-map "/" 'codepilot-search-hi)
;; (define-key codepilot-ro-mode-map "n" 'codepilot-search-hl-again-f)
;; (define-key codepilot-ro-mode-map "N" 'codepilot-search-hl-again-b)
;; (define-key codepilot-ro-mode-map "v" 'find-tag)
(define-key codepilot-ro-mode-map "7" 'gtags-find-tag)
(define-key codepilot-ro-mode-map "8" 'gtags-find-rtag)
(define-key codepilot-ro-mode-map "9" 'gtags-find-symbol)
(define-key codepilot-ro-mode-map "i" 'gtags-find-rtag)
(define-key codepilot-ro-mode-map "o" 'gtags-find-symbol)
(define-key codepilot-ro-mode-map "j" 'gtags-find-tag)
(define-key codepilot-ro-mode-map "l" 'gtags-find-file)
(define-key codepilot-ro-mode-map "p" 'gtags-find-with-grep)
(define-key codepilot-ro-mode-map "hg" 'mygtags-switch-to-gtags-buf)
(define-key codepilot-ro-mode-map "hh" 'codepilot-nav-history)
(define-key codepilot-ro-mode-map "hm" 'codepilot-push-marker)
(define-key codepilot-ro-mode-map "`" 'cplist-minimize/restore-sidebar)
(define-key codepilot-ro-mode-map "w" 'jump-to-h-c-file)
(define-key codepilot-ro-mode-map "\M-j" 'semantic-complete-jump)
(define-key codepilot-ro-mode-map "u" 'cptree-unfold-all)
(define-key codepilot-ro-mode-map "v" (lambda ()
                                        (interactive)
                                        (cond ((eq major-mode 'gtags-select-mode)
                                               (mygtags-toggle-folding))
                                              (t
                                               (hs-toggle-hiding)))))
(define-key codepilot-ro-mode-map "a" 'ffap)
(define-key codepilot-ro-mode-map ";" (lambda ()
                                        (interactive)
                                        (switch-to-buffer (other-buffer))
                                        ))
(define-key codepilot-ro-mode-map ":" 'goto-line)
(define-key codepilot-ro-mode-map "r" 're)
(define-key codepilot-ro-mode-map "R" 're-r)
(define-key codepilot-ro-mode-map "m" 'cpimenu-go)


;; misc key mapping

(define-key cplist-mode-map "v" 'cplist-toggle-folding)
(define-key cplist-mode-map "z" 'cplist-fold-all)
(define-key cplist-mode-map "o" 'cplist-unfold-all)


;; (brian-activate-codepilot-cc)
