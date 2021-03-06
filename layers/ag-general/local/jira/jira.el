;;; jira.el --- Jira wrapper around go-jira -*- lexical-binding: t; -*-
;;
;; Author: Ag Ibragimov
;; URL: https://github.com/agzam/dot-spacemacs/tree/master/layers/ag-general/local/jira/jira.el
;; Created: 2019-08
;; Keywords: jira, project
;; License: GPL v3
;; Version: 0.0.1

;;; Commentary:
(require 'a)
(defvar jira-base-url "" "Jira base url, e.g: https://jira.mycompany.com.")
(defvar jira-project "scrum-" "Default Jira project prefix.")

(defvar go-jira-mode-map (make-sparse-keymap)
  "Keymap for minor mode variable `go-jira-mode'.")

;; (define-key go-jira-mode-map (kbd "q") #'go-jira-quit)
;; (evil-make-overriding-map go-jira-mode-map)
;; (evil-define-minor-mode-key 'normal 'go-jira-mode-map "q" #'go-jira-quit)
(define-key go-jira-mode-map [remap org-todo] #'go-jira-transition-current)

(define-minor-mode go-jira-mode
  "Jira tickets view minor mode
\\{go-jira-mode-map}"
  :group 'jira
  :lighter " Jira"
  :init-value nil
  :keymap go-jira-mode-map)

(defun go-jira--get-ticket-details (ticket-number)
  "Attempts to run go-jira cli for given TICKET-NUMBER.
If successful, returns hashmap.

Returns nil, if Jira CLI fails for any reason: auth error,
non-existent ticket, etc."
  (ignore-errors
    (json-read-from-string
     (shell-command-to-string
      (concat "jira view " ticket-number " --template=debug")))))

(defun go-jira-query (jira-query)
  (ignore-errors
    (json-read-from-string
     (shell-command-to-string
      (concat
       "jira list "
       (concat "--query " jira-query " ")
       "--queryfields='status,assignee,subtasks,description,issuetype,labels,customfield_10002,customfield_10004' "
       "--template=debug")))))

(defun go-jira--mine ()
  (let ((query "'project = SCRUM and resolution = unresolved and assignee=currentuser() and issuetype != Sub-task ORDER BY updatedDate DESC'"))
    (go-jira-query query)))

(defun go-jira--backlog ()
  (let ((query
         (concat
          "'project = SCRUM "
          "and resolution = unresolved and issuetype != Sub-task "
          "and labels in (CCC, burndown4watt)"
          "and updated > \"-5d\"'")))
    (go-jira-query query)))

(defvar go-jira--status->todo
  '(("To Do"                          . "TODO")
    ("In Progress"                    . "INPROGRESS")
    ("Code Review"                    . "CODEREVIEW")
    ("Ready to Test in Dev"           . "DEVTEST")
    ("Ready to Push to Stage"         . "STAGEPUSH")
    ("Ready to Test in Stage"         . "STAGETEST")
    ("Ready to Release to Production" . "RELEASEREADY")
    ("Ready to Smoke test"            . "SMOKEREADY")
    ("Blocked"                        . "BLOCKED")
    ("Done"                           . "DONE")))

(defun go-jira--issue-status->todo (issue)
  (a-get go-jira--status->todo
         (aget-in issue 'fields 'status 'name)))

(defun go-jira--issue->properties (issue)
  "Takes ISSUE - org-element data tree element and adds a bunch
of relevant properties to it."
  (cl-flet ((parse-sprintname
             (s)
             (string-match "name=[^,]*" s)
             (replace-regexp-in-string "name=" "" (match-string 0 s)))

            (node-fn
             (a)
             (let ((title (car a))
                   (value (cdr a)))
               (when value
                 `(node-property
                   (:key ,title :value ,value))))))
    (let ((nodes `(("Summary"  . ,(aget-in issue 'fields 'summary))
                   ("Ticket"   . ,(aget-in issue 'key))
                   ("Assignee" . ,(aget-in issue 'fields 'assignee 'name))
                   ("Status"   . ,(aget-in issue 'fields 'status 'name))
                   ("Type"     . ,(aget-in issue 'fields 'issuetype 'name))
                   ("Points"   . ,(aget-in issue 'fields 'customfield_10002))
                   ("Labels"   . ,(aget-in issue 'fields 'labels))
                   ("Sprint"   . ,(-some-> issue
                                           (aget-in 'fields 'customfield_10004)
                                           (elt 0)
                                           (parse-sprintname))))))
      (mapcar #'node-fn nodes))))

(defun go-jira--issue->org-element (issue)
  (let* ((summary (aget-in issue 'fields 'summary))
         (ticket (aget-in issue 'key)))
    `(headline
      (:level 1
              :title ,(concat ticket ": " summary)
              :todo-keyword ,(go-jira--issue-status->todo issue)
              )
      (section
       nil
       (property-drawer
        nil
        ,(go-jira--issue->properties issue))))))

(defun go-jira-list (data)
  "Using json data from go-jira list type of request, displays it in an Org-mode buffer."
  (interactive)
  (when data
    (let* ((headers
            (concat
             "#+TODO: TODO(t) INPROGRESS(i) CODEREVIEW(c) DEVTEST(d) | STAGEPUSH(s) STAGETEST RELEASEREADY BLOCKED DONE \n"
             "#+COLUMNS: %0( ) %10Ticket %50Summary %12TODO %20Assignee %1Points( ) %Labels %Sprint\n"))

           (org-text (org-element-interpret-data
                      (mapcar 'go-jira--issue->org-element
                              (alist-get 'issues data))))
           (temp-buf (get-buffer-create "go-jira-list")))
      (switch-to-buffer-other-window temp-buf)
      (set-buffer temp-buf)
      (with-current-buffer temp-buf
        (erase-buffer)
        (insert headers)
        (insert org-text)
        (funcall 'org-mode)
        (funcall 'go-jira-mode)
        (setq after-change-functions nil)
        (org-indent-region (point-min) (point-max))
        (org-columns t)))))

(defun go-jira--valid-transitions (ticket-n)
  "Returns list of valid status transitions for a given Jira
ticket."
  (let ((json
         (ignore-errors
           (json-read-from-string
            (shell-command-to-string
             (concat "jira transitions " ticket-n " --template=debug"))))))
    (mapcar (lambda (x) (a-get x 'name))
            (a-get json 'transitions))))

(defun go-jira-transition (ticket-n)
  "Change status of Jira issue with ticket number TICKET-N.
Returns `t` if successful."
  (interactive)
  (when-let* ((valid-trans (go-jira--valid-transitions ticket-n))
              (current-status
               (car (set-difference
                     (mapcar 'car go-jira--status->todo)
                     valid-trans :test #'equal)))
              (new-status (helm-comp-read
                           (concat "Change " ticket-n " status from \"" current-status "\" => ")
                           valid-trans)))
    (= 0 (call-process
          "jira" nil (get-buffer "*Messages*") nil
          "transition"
          new-status
          ticket-n
          "--noedit"))))

(defun go-jira-transition-current ()
  "Change status of Jira ticket at the point."
  (interactive)
  (let* ((context (org-element-context))
         (lnk (org-element-property :raw-link context))
         (m (string-match "\\w*-[0-9]*" lnk))
         (jira-ticket (when m (match-string 0 lnk))))
    (go-jira-transition jira-ticket))
  ;; (when-let ((ticket (org-entry-get nil "Ticket")))
  ;;   (go-jira-transition ticket))
  )

;; (go-jira-list (go-jira--mine))
;; (go-jira-list (go-jira--backlog))

;; (mapcar 'go-jira--issue->org-element
;;         (alist-get 'issues (go-jira--mine)))

;; (alist-get 'issues (go-jira--mine))

(defun go-jira--get-ticket-summary (ticket-number)
  "Try to retrieve summary for a given Jira TICKET-NUMBER.

Returns nil, if Jira CLI fails for any reason: auth error,
non-existent ticket, etc."
  (->> ticket-number
       go-jira--get-ticket-details
       (alist-get 'fields)
       (alist-get 'summary)))

(defun go-jira-quit ()
  "Kill go-jira buffer"
  (interactive)
  (when-let* ((buffer (get-buffer "go-jira-list")))
    (quit-window)
    (kill-buffer buffer)))

;; https://emacs.stackexchange.com/questions/10707/in-org-mode-how-to-remove-a-link
(defun org-kill-link ()
  "Deletes whole link, if the thing-at-point is a proper Org-link"
  (interactive)
  (when (org-in-regexp org-bracket-link-regexp 1)
    (let ((remove (list (match-beginning 0) (match-end 0)))
          (description (if (match-end 3)
                           (org-match-string-no-properties 3)
                         (org-match-string-no-properties 1))))
      (apply 'delete-region remove))))

(defun markdown-kill-link ()
  "Deletes whole link, if the thing-at-point is a proper Markdown-link"
  (interactive)
  (when (org-in-regexp markdown-regex-link-inline 1)
    (let ((remove (list (match-beginning 0) (match-end 0)))
          (description (if (match-end 3)
                           (org-match-string-no-properties 3)
                         (org-match-string-no-properties 1))))
      (apply 'delete-region remove))))

(defun jira--convert-number-to-ticket-key (ticket-number)
  (let* ((ticket (string-to-number (replace-regexp-in-string "[^0-9]" "" ticket-number)))
         (prefix (replace-regexp-in-string "[0-9]" "" ticket-number))
         (jira-project-prefix (if (string-empty-p prefix)
                                  jira-project
                                prefix)))
    (concat jira-project-prefix (number-to-string ticket))))

(defun convert-to-jira-link ()
  "Converts a word (simple number or a JIRA ticket with prefix) to a proper JIRA link."
  (interactive)
  (let* ((w (symbol-at-point))
         (bounds (bounds-of-thing-at-point 'symbol))
         (ticket (string-to-number (replace-regexp-in-string "[^0-9]" ""
                                                             (symbol-name w))))
         (prefix (replace-regexp-in-string "[0-9]" "" (symbol-name w)))
         (jira-project-prefix (if (string-empty-p prefix)
                                  jira-project
                                prefix))
         (uri (concat
               jira-base-url
               "/browse/"
               (concat jira-project-prefix (number-to-string ticket))))
         (label (string-trim
                 (if (string-match-p jira-project-prefix (downcase (symbol-name w)))
                     (upcase (symbol-name w))
                   (upcase (concat jira-project-prefix (number-to-string ticket))))))
         (summary (string-trim (go-jira--get-ticket-summary label)))
         (summary-lbl (when summary (concat ": " summary))))

    (cond ((eq major-mode 'org-mode)
           (progn
             (if (org-in-regexp org-bracket-link-regexp 1)
                 (org-kill-link)
               (delete-region (car bounds) (cdr bounds)))
             (insert (concat "[[" uri "][" label summary-lbl "]]"))))

          ((eq major-mode 'markdown-mode)
           (progn
             (if (org-in-regexp markdown-regex-link-inline 1)
                 (markdown-kill-link)
               (delete-region (car bounds) (cdr bounds)))
             (insert (concat "[" label summary-lbl "](" uri ")"))))

          ((string-match-p "COMMIT_EDITMSG" (or buffer-file-name ""))
           (progn
             (delete-region (car bounds) (cdr bounds))
             (insert (concat "[" label summary-lbl "]\n" uri))))

          (t
           (progn
             (delete-region (car bounds) (cdr bounds))
             (insert (concat uri "\n" summary)))))))

(defun jira-generate-git-branch-name (&optional ticket-number)
  "Generates readable branch name base on given TICKET-NUMBER"
  (interactive)
  (let* ((w (symbol-name (symbol-at-point)))
         (ticket-key (if (s-blank? (replace-regexp-in-string "[^0-9]" "" w))
                         (jira--convert-number-to-ticket-key (read-string "Enter Jira ticket number: "))
                       (jira--convert-number-to-ticket-key w)))

         (summary (go-jira--get-ticket-summary ticket-key))
         (norm-summary
          (-some->>
           summary
           downcase
           string-trim
           (replace-regexp-in-string " \\|\\-" "_" )
           (replace-regexp-in-string "[^a-zA-Z0-9_-]" "")))
         (branch-name (concat norm-summary "--" ticket-key)))
    (kill-new branch-name)
    (message branch-name)
    branch-name))



(provide 'jira)
