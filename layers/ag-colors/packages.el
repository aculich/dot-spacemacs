;;; packages.el --- ag-colors layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author: Ag Ibragimov <agzam.ibragimov@gmail.com>
;; URL: https://github.com/agzam/dot-spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defconst ag-colors-packages '(base16-theme))

(defun ag/decrease-powerline-fonts (&optional theme)
  "Slightly decrease elements of the powerline, which-key and minibuffer"
  (let ((faces '(powerline-active0
                 powerline-active1
                 powerline-active2
                 powerline-inactive0
                 powerline-inactive1
                 powerline-inactive2
                 mode-line
                 mode-line-inactive
                 mode-line-highlight
                 mode-line-buffer-id
                 mode-line-buffer-id-inactive
                 mode-line-emphasis
                 which-key-docstring-face
                 which-key-group-description-face
                 which-key-command-description-face
                 which-key-local-map-description-face

                 spacemacs-micro-state-header-face
                 spacemacs-micro-state-binding-face
                 spacemacs-transient-state-title-face

                 persp-face-lighter-buffer-not-in-persp
                 persp-face-lighter-default
                 persp-face-lighter-nil-persp)))
    (dolist (f faces)
      (when (facep f)
        (set-face-attribute f nil :height 0.9))))

  (dolist (buf (list " *Minibuf-0*" " *Minibuf-1*" " *Echo Area 0*" " *Echo Area 1*" " *which-key*"))
    (when (get-buffer buf)
      (with-current-buffer buf
        (setq-local face-remapping-alist '((default (:height 0.85))))))))

(defun ag/set-faces-attributes (faces)
  "Sets face attributes for given alist of FACES"
  (dolist (f faces)
    (let* ((face (car f))
           (attribs (cdr f))
           (params (cons face (cons nil attribs))))
      (when (facep face)
        (set-face-attribute face nil :background nil :foreground nil)
        (apply 'set-face-attribute params)))))

(defun ag/adjust-base16-ocean-colors ()
  (let* ((base00 "#252933")
         (base01 "#343d46")
         (base02 "#4f5b66")
         (base03 "#65737e")
         (base04 "#a7adba")
         (base05 "#c0c5ce")
         (base06 "#dfe1e8")
         (base07 "#eff1f5")
         (base08 "#bf616a")
         (base09 "#d08770")
         (base0A "#ebcb8b")
         (base0B "#a3be8c")
         (base0C "#96b5b4")
         (base0D "#8fa1b3")
         (base0E "#b48ead")
         (base0F "#ab7967")
         (base10 "#7090af")
         (faces `(;; magit
                  (magit-popup-disabled-argument . (:foreground ,base02))
                  (magit-popup-option-value . (:foreground ,base08))
                  (magit-popup-argument . (:foreground ,base08))

                  (magit-diff-context-highlight . (:background ,base00))
                  (magit-diff-removed . (:foreground ,base08))
                  (magit-diff-added . (:foreground ,base0B))
                  (magit-diff-removed-highlight . (:foreground "#ef6160"))
                  (magit-diff-added-highlight . (:foreground "#a3be70"))
                  (magit-section-highlight . (:background "#2f343f"))
                  (magit-diff-hunk-heading . (:background "#2f343f"))
                  (magit-diff-hunk-heading-highlight . (:background "#2f363f"))
                  (diff-refine-added . (:foreground "#a3be70" :background "#2b3b34"))
                  (diff-refine-removed . (:foreground "#ef6160" :background "#3b2c2b"))
                  (smerge-refined-added . (:foreground "#a3be70" :background "#2b3b34"))
                  (smerge-refined-removed . (:foreground "#ef6160" :background "#3b2c2b"))

                  (ediff-current-diff-A . (:foreground "#dd828b" :background "#443238"))
                  (ediff-fine-diff-A . (:foreground "#db5e6c" :background "#603238"))
                  (ediff-current-diff-B . (:foreground ,base0B :background "#2a3a2c"))
                  (ediff-fine-diff-B . (:foreground "#aadd7e" :background "#2e4431"))

                  ;; diff-hl
                  (diff-hl-change . (:foreground ,base03 :background ,base0D))
                  (diff-hl-delete . (:foreground ,base03 :background ,base08))
                  (diff-hl-insert . (:foreground ,base03 :background ,base0B))
                  (diff-hl-unknown . (:foreground ,base03 :background ,base0A))

                  (ahs-plugin-whole-buffer-face . (:foreground ,base0B :background ,base00))
                  (ahs-face . (:foreground ,base0A :background ,base02))

                  ;; avy
                  (aw-leading-char-face . (:height 5.0 :foreground "Orange"))
                  (avy-lead-face . (:height 1.3 :foreground ,base0A))
                  (avy-lead-face-0 . (:height 1.3 :foreground ,base09))
                  (avy-lead-face-1 . (:height 1.3 :foreground ,base0C))
                  (avy-lead-face-2 . (:height 1.3 :foreground ,base10))

                  ;; helm
                  (helm-swoop-target-line-face . (:foreground ,base04 :background ,base02))
                  (helm-swoop-target-word-face . (:foreground ,base0A :background ,base02 :weight bold))
                  (helm-swoop-target-line-block-face . (:background ,base0B :foreground ,base01))

                  ;; org-mode
                  (org-link . (:underline t :foreground ,base0B))
                  (org-todo . (:weight bold :foreground ,base0A))
                  (org-done . (:strike-through ,base0D))
                  (org-block-begin-line . (:underline ,base02 :foreground ,base04 :height 0.9 :weight ultra-light))
                  (org-block-end-line . (:overline ,base02 :foreground ,base04 :height 0.9 :weight ultra-light))
                  (org-level-1 . (:foreground ,base0D :bold t :height 1.3))
                  (org-level-2 . (:foreground ,base09 :bold t :height 1.2))
                  (org-level-3 . (:foreground ,base0B :height 1.1))
                  (org-level-4 . (:foreground ,base10 :height 1.0))
                  (org-level-5 . (:foreground ,base0E :height 1.0))
                  (org-level-6 . (:foreground ,base0C :height 1.0))
                  (org-level-7 . (:foreground ,base07 :height 1.0))
                  (org-level-8 . (:foreground ,base0D :height 1.0))

                  ;; code
                  (font-lock-doc-face . (:foreground ,base02))

                  ;; misc
                  (hl-line . (:background "#2f3440"))
                  (trailing-whitespace . (:background ,base01))
                  (mode-line . (:underline (:color ,base01)))
                  (mode-line-inactive . (:underline (:color ,base01)))
                  (default . (:background ,base00 :foreground ,base05)))))
    (ag/set-faces-attributes faces)
    (setq pdf-view-midnight-colors `(,base04 . ,base00))))

(defun ag/adjust-themes ()
  (ag/decrease-powerline-fonts)
  (pcase spacemacs--cur-theme
    ('spacemacs-light
     (let ((faces `((magit-diff-hunk-heading . (:background "#efeae9"))
                    (magit-diff-hunk-heading-highlight . (:background "#efeae9"))
                    (magit-diff-context-highlight . (:background "#fbf8ef"))
                    (magit-diff-added . (:foreground "#67963d" :background "#e6ffed"))
                    (magit-diff-added-highlight . (:foreground "#325e0b" :background "#e6ffed"))
                    (magit-diff-removed . (:foreground "#ef6160" :background "#ffeef0"))
                    (magit-diff-removed-highlight . (:foreground "#d80d0d" :background "#ffeef0"))
                    (diff-refine-added . (:foreground "#325e0b" :background "#acf2bd"))
                    (diff-refine-removed . (:foreground "#d80d0d" :background "#fdb8c0"))
                    (trailing-whitespace . (:background "#e5e1e0"))
                    (ahs-definition-face . (:background "#e6ffed"))
                    (ahs-plugin-whole-buffer-face . (:background "#e5e1e0"))
                    (aw-leading-char-face . (:height 5.0))
                    (mode-line . (:underline (:color "#b2b2b2")))
                    (mode-line-inactive . (:underline (:color "#d3d3e7"))))))
       (ag/set-faces-attributes faces)))

    ('base16-ocean (ag/adjust-base16-ocean-colors))))

(defun ag-colors/init-base16-theme ()
  (use-package base16-theme))

;; this is a workaround the bug where Emacs doesn't correctly use the current
;; theme with new frames
;; https://github.com/syl20bnr/spacemacs/issues/11916
(defun ag/new-frame-init (frame)
  (run-at-time "0.002 sec" nil
               (lambda ()
                 (enable-theme spacemacs--cur-theme)
                 (ag/adjust-themes))))

(with-eval-after-load 'core-themes-support
  (add-hook 'spacemacs-post-theme-change-hook 'ag/adjust-themes t)
  (add-hook 'after-make-frame-functions 'ag/new-frame-init))

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; eval: (when (require 'rainbow-mode nil t) (rainbow-mode 1))
;; End:
