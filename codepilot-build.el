
(defvar codepilot-dir
  (file-name-directory
   (or load-file-name (buffer-file-name))))

(add-to-list 'load-path (expand-file-name "common" codepilot-dir))
(add-to-list 'load-path (expand-file-name "cc" codepilot-dir))
(add-to-list 'load-path (expand-file-name "hack" codepilot-dir))
(add-to-list 'load-path (expand-file-name "misc" codepilot-dir))
(add-to-list 'load-path (expand-file-name "import" codepilot-dir))


(defvar codepilot-el-files)
(setq  codepilot-el-files '(
                            ("import" . 
                             ("xcscope.el"
                              "tabbar.el"
                              "gtags.el"
                              "bm.el"
                              "misccollect.el"
                              ))

                            ("common" .
                             (
                              "cp-layout.el"
                              "cphistory.el"
                              "cp-base.el"
                              "cp-hl.el"
                              "cplist.el"
                              "cp-pb.el"
                              "cp-mark.el"
                              "cpfilter.el"
                              "cpimenu.el"
                              "cp-toolbar.el"
                              "cpnote.el"
                              "myremember.el"
                              ))

                            ("cc" .
                             (
                              "mycscope.el"
                              "mygtags.el"
                              "myetags.el"
                              "myctagsmenu.el"
                              "mycutil.el"
                              "cp-cc.el"
                              "cplist-cc.el"
                              ))

                            ("hack" .
                             ("mypython.el"
                              "myhshack.el"
                              "myishack.el"
                              "mytbhack.el"
                              "myocchack.el"
                              ))

                            ("misc" .
                             ("smart-hl.el"
                              "mymisc.el"
                              ))
                            ))


(defun codepilot-compile (parent files)
  (dolist (f files)
    (cond ((atom f)
           (byte-compile-file (concat parent "/" f))
           )
          (t
           (codepilot-compile (concat parent "/" (car f)) (cdr f))
           ))))

(codepilot-compile (directory-file-name codepilot-dir) codepilot-el-files)
