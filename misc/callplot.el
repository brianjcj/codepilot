;; Brian Jiang
;; 2007-12-30

(defface callplot-msg-face
  '((default (:foreground "blue")) (((class color)) nil))
  "*Font used by folding overlay."
  :group 'callplot)

(defface callplot-mouse-face
  '((default (:foreground "blue" :underline t)) (((class color)) nil))
  "*Font used by folding overlay."
  :group 'callplot)

(defface callplot-nodeline-face
  '((default (:background "blue" :foreground "white")) (((class color)) nil))
  "*Font used by folding overlay."
  :group 'callplot)

(defcustom callplot-column-width 15 "" :type 'integer :group 'callplot)
(defcustom callplot-column-start 3 "" :type 'integer :group 'callplot)
(defcustom callplot-display-timestamp nil "" :type 'boolean :group 'callplot)
(defcustom callplot-display-msgid t "" :type 'boolean :group 'callplot)
(defcustom callplot-display-callstat nil "" :type 'boolean :group 'callplot)
(defcustom callplot-display-help-echo t "" :type 'boolean :group 'callplot)
(defcustom callplot-padded-line 0 "" :type 'integer :group 'callplot)
(defcustom callplot-note-numbering nil "" :type 'integer :group 'callplot)
(defcustom callplot-java-jar "D:/callplot/callplot-0.1/lib/callplot.jar" "" :type 'string :group 'callplot)

(defun get-msg-pos-list ()
  (save-match-data
    (save-excursion
      (goto-char (point-max))
      (let (ll)
        (catch 'loop
          (while (not (bobp))
            (cond ((re-search-backward "^TIMESTAMP: " nil t)
                   (push (point-marker) ll))
                  (t
                   (throw 'loop nil)
                   ))))
        ll))))

(defun parse-msgs (msg-marker-list)
  (let (msg-list node-list pos ts msg snode dnode callstat append-msg)
    (save-match-data
      (save-excursion
        (dolist (m msg-marker-list)
          (goto-char m)
          (setq pos (point))
          (setq ts (buffer-substring-no-properties (+ pos 25) (+ pos 37)))
          (forward-line)
          (setq pos (point))
          (end-of-line)
          (skip-chars-backward " \t")
          (setq msg (buffer-substring-no-properties (+ pos 14) (point)))
          (forward-line 2)
          (end-of-line)
          (setq snode (current-word))
          (forward-line)
          (end-of-line)
          (setq dnode (current-word))
          (forward-line)
          (end-of-line)
          (setq callstat (current-word))
          (setq append-msg nil)
          (when callplot-display-timestamp
            (setq append-msg ts))
          (if callplot-display-callstat
              (if append-msg
                  (setq append-msg (concat append-msg "; " callstat))
                (setq append-msg callstat)))
          (push (list :-> m msg append-msg snode dnode (if callplot-display-help-echo (concat ts "\n" callstat) nil)) msg-list)
          (pushnew snode node-list :test #'string=)
          (pushnew dnode node-list :test #'string=)
          )))
    (when msg-list
      (setq msg-list (nreverse msg-list)))
    (setq node-list (arrange-nodes node-list))
    (values msg-list node-list)
    ))

(defun arrange-nodes (node-list)
  ""
  (let (friu-list cau-list rmu-list mist-list cm-list ace-list liu7-list len ss ll)
    (dolist (node node-list)
      (setq len (length node))
      (cond
        ((= len 2)
         (if (string= node "CM")
             (push node cm-list)
             ;;else
             (push node mist-list)))
        ((>= len 3)
         (cond
           ((and (>= len 4)
                 (string= (substring node 0 4) "FRIU"))
            (push node friu-list))
           (t
            (setq ss (substring node 0 3))
            (cond
              ((string= ss "CAU")
               (push node cau-list))
              ((string= ss "RMU")
               (push node rmu-list))
              ((string= ss "ACE")
               (push node ace-list))
              ((string= ss "LIU")
               (push node liu7-list))
              (t
               (push node mist-list))))))
        (t
         (push node mist-list))
        ))
    (setq ll (append mist-list friu-list cau-list rmu-list liu7-list ace-list cm-list))
    (unless (= (length ll) (length node-list))
      (error "Something wrong!!!"))
    ll))

(defun node-column (node-ind)
  (+ callplot-column-start (* node-ind callplot-column-width)))

(defun make-blank-line (number-of-node)
  (make-string (+ callplot-column-start
                              (* callplot-column-width
                                 (1- number-of-node))
                              100)
                           ?\s))

(defun put-str-to-line% (str line start)
  (loop for c across str do
        (aset line start c)
        (incf start))
  start)

(defun draw-nodes (node-list line &optional draw-headline-p)
  (let (col
        (ind 0)
        len fs start)
    (dolist (node node-list)
      (setq col (node-column ind))
      (setq len (length node))
      (setq fs (- col (/ len 2)))
      (when (< fs 0)
        (setq fs 0))
      (setq fs (put-str-to-line% node line fs))
      (incf ind)
      )
    (insert (substring line 0 fs))
    (save-excursion
      (forward-line 0)
      (setq start (point)))
    (add-text-properties start (+ start fs) '(face callplot-nodeline-face))
    (insert "\n")
    (when draw-headline-p
      (setq header-line-format (concat " " (substring line 0 fs))))
    ))

(defun draw-nodes-mult (node-list line &optional draw-headline-p)
  (let ((ll (loop for node in node-list collect (split-string node "\\^")))
        max-line-no
        lines-list)
    (setq max-line-no (loop for lines in ll maximize (length lines)))
    (loop for i from 0 below max-line-no do
          (setq lines-list
                (loop for lines in ll collect (if (> (length lines) i) (elt lines i) "")))
          (fillarray line ?\s)
          (draw-nodes lines-list line (= i 0))
          )))

(defun fill-| (number-of-node line)
  (loop for i from 0 below number-of-node do
       (aset line (node-column i) ?|)))


(defun asu-file-p ()
  (save-match-data
    (save-excursion
      (goto-char (point-min))
      (re-search-forward "^TIMESTAMP:" nil t))))


(defun draw-plot-asu ()
  (cond ((asu-file-p)
         (multiple-value-bind (msg-list node-list) (parse-msgs (get-msg-pos-list))
           (draw-plot-1 msg-list node-list node-list #'draw-nodes))
         t)
        (t nil)))

(defun draw-plot-script ()
  (multiple-value-bind (msg-list guy-list option-alist) (parse-callplot-script)
      (let ((callplot-display-msgid callplot-display-msgid)
            (callplot-padded-line callplot-padded-line)
            (callplot-column-width callplot-column-width)
            (callplot-column-start callplot-column-start)
            (callplot-note-numbering callplot-note-numbering))
        (loop for (opt . opt-val) in option-alist do
              (cond ((string= "messageNumbering" opt)
                     (cond ((string= "on" opt-val)
                            (setq callplot-display-msgid t))
                           ((string= "off" opt-val)
                            (setq callplot-display-msgid nil))
                           ))
                    ((string= "linePitch" opt)
                     (setq callplot-padded-line (- (string-to-number opt-val) 2))
                     (if (< callplot-padded-line 0)
                         (setq callplot-padded-line 0)))
                    ((string= "columnPitch" opt)
                     (setq callplot-column-width (string-to-number opt-val)))
                    ((string= "startColumn" opt)
                     (setq callplot-column-start (string-to-number opt-val)))
                    ((string= "noteNumbering" opt)
                     (cond ((string= "on" opt-val)
                            (setq callplot-note-numbering t))
                           ((string= "off" opt-val)
                            (setq callplot-note-numbering nil))
                           ))
                    ))
        (multiple-value-bind (g1 g2)
            (loop for (a . b) in guy-list collect a into l1 collect b into l2
                  finally (return (values l1 l2)))
          (draw-plot-1 msg-list g1 g2 #'draw-nodes-mult))))
  t)
  
(defun draw-plot ()
  (interactive)
  (cond ((draw-plot-asu))
        ((draw-plot-ss7))
        (t
         (draw-plot-script))))

(defun draw-plot-1 (msg-list node-list node-full-name-list draw-nodes-func)
  (let ((callplot-buffer-name (concat "*CallPlot-" (buffer-name) "*"))
        line line-fill node-num len-of-bline)
        
    (setq node-num (length node-list))
    (setq line (make-blank-line node-num))
    (setq len-of-bline (+ 1 callplot-column-start (* callplot-column-width (1- node-num))))
    
    (with-output-to-temp-buffer callplot-buffer-name
      (save-excursion
        (set-buffer standard-output)
        (toggle-truncate-lines 1)
        (funcall draw-nodes-func node-full-name-list line t)
        
        (fillarray line ?\s)
        (fill-| node-num line)
        (setq line-fill (copy-seq line))
            
        (insert (substring line-fill 0 len-of-bline) "\n")

        (let (snode-ind dnode-ind s-col e-col dir (msg-id 1) ch)
          (dolist (msg msg-list)
            (destructuring-bind (cat msg-mark msg append-msg snode dnode help-echo)
                msg
              (flet ((draw-msg%
                         (start)
                       (let ((msg-lines (split-string msg "\\^"))
                             (start-col start)
                             msg-start)

                         (put-str-to-line% line-fill line 0)
                         (when callplot-display-msgid
                           (setq start (put-str-to-line% (concat "(" (int-to-string msg-id) ") ") line start)))

                         (setq msg-start start)
                         (setq start (put-str-to-line% (car msg-lines) line start))
                         (when append-msg
                           (setq start (put-str-to-line% (concat " [" append-msg "]") line start)))
                         (insert (substring line 0 (max start len-of-bline)))
                         (save-excursion
                           (forward-line 0)
                           (setq msg-start (+ msg-start (point))))
                         (add-text-properties msg-start (+ msg-start (length (car msg-lines)))
                                              `(face callplot-msg-face mouse-face callplot-mouse-face
                                                     help-echo ,(if (string= help-echo "") nil help-echo)
                                                     callplot-msg-target ,msg-mark))
                         (insert "\n")

                         (dolist (m (cdr msg-lines))
                           (put-str-to-line% line-fill line 0)
                           (setq start (put-str-to-line% m line start-col))
                           (insert (substring line 0 (max start len-of-bline)) "\n")
                           )))
                     (draw-loop-arrow% ()
                       (let* ((len-half (/ (1+ callplot-column-width) 2))
                              (start (1+ s-col))
                              (end (+ start len-half))
                              (end-ln (max (1+ end) len-of-bline))
                              c)
                         (put-str-to-line% line-fill line 0)
                         (loop for i from start below end do (aset line i ?-))
                         (setq c (aref line end))
                         (aset line end ?,)
                         (insert (substring line 0 end-ln) "\n")
                         (aset line end c)
                         (aset line (1- end) ?/)
                         (aset line start ?<)
                         (insert (substring line 0 end-ln) "\n")))
                     (draw-arrow% ()
                       (put-str-to-line% line-fill line 0)
                       (if (eq cat :dot)
                           (setq ch ?\.)
                           (setq ch ?-))
                       (loop for i from (1+ s-col) below e-col do (aset line i ch))
                       (if (eq cat :->)
                           (if (eq :b dir)
                               (aset line (1+ s-col) ?<)
                               (aset line (1- e-col) ?>)))                  
                       (insert (substring line 0 len-of-bline) "\n")))
                
                (setq snode-ind (position snode node-list :test #'string=))
                (unless snode-ind
                  (error "Node %s is undefined!" snode)
                  )
                (setq s-col (node-column snode-ind))
              
                (cond
                  ((eq cat :note)
                   (let ((callplot-display-msgid (and callplot-display-msgid callplot-note-numbering)))
                     (draw-msg% (1+ s-col)))
                   (when callplot-note-numbering
                     (incf msg-id)))
                  (t            
                   (setq dnode-ind (position dnode node-list :test #'string=))
                   (unless dnode-ind
                     (error "Node %s is undefined!" dnode)
                     )
                   (if (> snode-ind dnode-ind)
                       (setq dir :b)
                       (setq dir :f))
                   (cond ((> snode-ind dnode-ind)
                          (setq dir :b))
                         ((= snode-ind dnode-ind)
                          (setq dir :=))
                         (t
                          (setq dir :f)))
                   (setq e-col (node-column dnode-ind))
                   (when (eq :b dir)
                     (rotatef s-col e-col))

                   (draw-msg% (1+ s-col))
                
                   (cond ((eq dir :=)
                          (draw-loop-arrow%))
                         (t
                          (draw-arrow%)
                          ))
                   
                   (incf msg-id)))
                (dotimes (i callplot-padded-line)
                  (insert (substring line-fill 0 len-of-bline) "\n")))
              ))
          (insert (substring line-fill 0 len-of-bline) "\n"))
        (callplot-mode)
        ))
    (delete-other-windows)
    (switch-to-buffer callplot-buffer-name)
    ))

(defvar callplot-mode-keymap nil)

(unless callplot-mode-keymap
  (let ((map (make-sparse-keymap)))
    (setq callplot-mode-keymap map)))

(defun callplot-mode ()
  (use-local-map callplot-mode-keymap)
  (setq buffer-read-only t
	mode-name "CallPlot"
	major-mode 'callplot-mode)
  (run-hooks 'callplot-mode-hook))

(defun callplot-mode-mouse-goto (event)
  (interactive "e")
  (mouse-set-point event)
  (let ((m (get-text-property (point) 'callplot-msg-target)))
    (when m
      (pop-to-buffer (marker-buffer m))
      (goto-char m))
    ))

(define-key callplot-mode-keymap [mouse-1] 'callplot-mode-mouse-goto)

(defun parse-callplot-script ()
  (let (line ll cmd guy-alist msg-list option-alist opt opt-val snode msg-marker msg dnode nodes cat)
    (save-match-data
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (setq msg-marker (point-marker))
          (setq line (buffer-substring-no-properties (point) (progn (end-of-line) (point))))
          (cond
           ((string= line ""))
           ((char-equal (aref line 0) ?!))
           (t
            (setq ll (split-string line "/"))
            (setq cmd (car ll))
            ;; (list cat msg-marker msg append-msg snode dnode help-echo)
            (cond ((string= "opt" cmd)
                   (push (cons (second ll) (third ll)) option-alist))
                  ((string= "guy" cmd)
                   (push (cons (second ll) (third ll)) guy-alist))
                  ((string= "note" cmd)
                   (push (list :note msg-marker (third ll) nil (second ll) nil nil) msg-list))
                  ((>= (length (setq nodes (split-string cmd "->"))) 2)
                   (push (list :-> msg-marker (second ll) nil (first nodes) (second nodes) nil) msg-list)
                   (when (= 3 (length ll))
                     (push (list :-> msg-marker (third ll) nil (second nodes) (first nodes) nil) msg-list)))
                  ((>= (length (setq nodes (split-string cmd "\\.\\."))) 2)
                   (push (list :dot msg-marker (second ll) nil (first nodes) (second nodes) nil) msg-list))
                  )))
            
          (forward-line))
        ))
    (values (nreverse msg-list) (nreverse guy-alist) option-alist)))


(defun draw-plot-via-java ()
  (interactive)
  (let (buf-name style buf)
    (setq style (completing-read "Style (valid options: [pic|vml|xml|svg]; Press Enter for text only): "
                     '("pic" "vml" "xml" "svg") nil t))
    (if (string= style "")
        (setq buf-name (concat "*CallPlot-" (buffer-name) "-java-txt*"))
      (setq buf-name (concat "*CallPlot-" (buffer-name) "-java-" style "*")))

    (setq buf (get-buffer-create buf-name))
    (with-current-buffer buf
      (let ((inhibit-read-only t)
	    (buffer-undo-list t))
        (setq buffer-read-only nil)
	(erase-buffer)
        ))

    (if (string= style "")
            (call-process-region (point-min) (point-max) "java" nil buf nil "-jar" callplot-java-jar "-")
          (call-process-region (point-min) (point-max) "java" nil buf nil "-jar" callplot-java-jar (concat "-" style) "-"))

    (delete-other-windows)
    (switch-to-buffer buf)
    (goto-char (point-min))
    (setq buffer-read-only t)
    (set-buffer-modified-p nil)
    (toggle-truncate-lines 1)
    ))

(defun write-customize-to-opt ()
  (interactive)
  (insert "opt/messageNumbering/" (if callplot-display-msgid "on" "off") "\n")
  (insert "opt/noteNumbering/" (if callplot-note-numbering "on" "off") "\n")
  (insert "opt/linePitch/" (int-to-string (+ 2 callplot-padded-line)) "\n")
  (insert "opt/columnPitch/" (int-to-string callplot-column-width) "\n")
  (insert "opt/startColumn/" (int-to-string callplot-column-start) "\n"))

(defun asu-to-callplot-script ()
  ""
  (interactive)
  (multiple-value-bind (msg-list node-list) (parse-msgs (get-msg-pos-list))
    (with-output-to-temp-buffer (concat "*CallPlot Script-" (buffer-name) "*")
      (save-excursion
        (set-buffer standard-output)
        (write-customize-to-opt)
        (dolist (node node-list)
          (insert "guy/" node "/" node "\n"))
        (dolist (msg-item msg-list)
          (destructuring-bind (cat msg-mark msg append-msg snode dnode help-echo)
              msg-item
            (insert snode "->" dnode "/" msg "\n")
            ))))))

;; (global-set-key [(f12)] 'draw-plot)

(provide 'callplot)




;; ss7

(defun get-msg-pos-list-ss7 ()
  (save-match-data
    (save-excursion
      (goto-char (point-max))
      (let (ll)
        (catch 'loop
          (while (not (bobp))
            (cond ((re-search-backward "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\\." nil t)
                   (forward-line 0)
                   (push (point-marker) ll))
                  (t
                   (throw 'loop nil)
                   ))))
        ll))))

(defun parse-msgs-ss7 (msg-marker-list)
  (let ((limit (point-max))
        msg-list node-list pos ts msg snode dnode tt tl ms trid)
    (save-match-data
      (save-excursion
        (dolist (m (nreverse msg-marker-list))
          (goto-char m)
          (setq pos (point))
          (end-of-line)
          (setq  tt (buffer-substring-no-properties (+ pos 23) (point)))
          (setq tl (split-string tt "[<> ]"))
          
          (cond ((find ?> tt)
                 (setq snode (first tl)
                       dnode (third tl)))
                ((find ?< tt)
                 (setq dnode (first tl)
                       snode (third tl))
                 ))

          (re-search-forward "\\(^    Responding Transaction ID: \\)\\|\\(^  INVOKE (last)\\)" limit t)
          (setq ms (match-string 0))

          (cond ((match-string 1)
                 ;;(string= "    Responding Transaction ID: " ms)
                 (setq trid (current-word))
                 (if (re-search-backward (concat "Original Transaction ID: " trid) nil t)
                     (progn
                       (re-search-forward "^  Operation Code Specifier: " nil t)
                       (setq msg (concat "[RR]: " (buffer-substring-no-properties (point)
                                                                                  (progn
                                                                                    (end-of-line)
                                                                                    (re-search-backward "[^ ]" nil t)
                                                                                    (1+ (point)))))))
                     ;; else
                     (setq msg "RETURN RESULT")
                     ))
                ((match-string 2)
                 ;;(string= "  INVOKE (last)" ms)
                 (re-search-forward "^  Operation Code Specifier: " nil t)
                 (setq msg (buffer-substring-no-properties (point) (progn
                                                                     (end-of-line)
                                                                     (re-search-backward "[^ ]" nil t)
                                                                     (1+ (point))))))
                (t
                 (setq msg "Unknown msg")
                 ))
          
          (push (list :-> m msg nil snode dnode nil) msg-list)
          (pushnew snode node-list :test #'string=)
          (pushnew dnode node-list :test #'string=)

          (setq limit (marker-position m))
          )))
    (when msg-list
      (setq msg-list msg-list))
    (when node-list
      (setq node-list (nreverse node-list)))
    (values msg-list node-list)
    ))


(defun ss7-file-p ()
  (save-match-data
    (save-excursion
      (goto-char (point-min))
      (re-search-forward "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\\.[0-9]\\{3\\} \\(PM\\|AM\\)  Link: " nil t))))

(defun draw-plot-ss7 ()
  (cond ((ss7-file-p)
         (multiple-value-bind (msg-list node-list) (parse-msgs-ss7 (get-msg-pos-list-ss7))
           (draw-plot-1 msg-list node-list node-list #'draw-nodes))
         t)
        (t nil)))