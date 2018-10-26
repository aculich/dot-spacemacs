;;; packages.el --- ag-clojure layer packages.
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author: Ag Ibragimov <agzam.ibragimov@gmail.com>
;; URL: https://github.com/agzam/dot-spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defconst ag-clojure-packages
  '(ac-cider
    clojure-mode-extra-font-locking
    helm-clojuredocs
    clojars
    helm-cider
    flycheck-joker))

(defun ag-clojure/init-ac-cider ())
(defun ag-clojure/init-clojure-mode-extra-font-locking ())
(defun ag-clojure/init-helm-clojuredocs ())
(defun ag-clojure/init-clojars ())
(defun ag-clojure/init-helm-cider ())
(defun ag-clojure/init-cider-hydra ())
(defun ag-clojure/init-flycheck-joker ()
  (require 'flycheck-joker))

(with-eval-after-load 'clojure-mode
  (setq clojure-enable-fancify-symbols nil
        ;; clojure-indent-style :align-arguments
        clojure-align-forms-automatically nil
        cider-overlays-use-font-lock nil
        cider-repl-use-clojure-font-lock nil
        cider-font-lock-dynamically nil
        cider-repl-display-in-current-window nil
        nrepl-log-messages nil
        cider-comment-prefix  " \n;; => "
        clojure-align-binding-forms '("binding" "loop" "doseq" "for" "with-open" "with-local-vars" "with-redefs"))

  (dolist (form '(re-frame.core/reg-sub
                  re-frame.core/reg-fx
                  re-frame.core/reg-sub
                  re-frame.core/reg-event-fx
                  re-frame.core/reg-event-db
                  rf/reg-sub
                  rf/reg-event-fx
                  rf/reg-event-db
                  clojure.spec.alpha/fdef
                  cljs.spec.alpha/fdef
                  prop/for-all))
    (put-clojure-indent form 1))

  ;; annoying Java Cup icon - no longer will bother you
  (setenv "JAVA_TOOL_OPTIONS" "-Dapple.awt.UIElement=true")

  (defun before-eval-print-advice (old-f &rest args)
    (if (thing-at-point 'list)
        (end-of-thing 'list)
      (end-of-thing 'symbol))
    (insert "\n")
    (apply old-f args)
    (run-at-time "0.05 sec" nil
                 (lambda ()
                   (backward-sexp)
                   (cider-format-edn-last-sexp))))

  (advice-add 'cider-eval-print-last-sexp :around #'before-eval-print-advice))

;;; packages.el ends here
