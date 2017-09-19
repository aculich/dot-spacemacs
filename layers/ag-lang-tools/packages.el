(defconst ag-lang-tools-packages
  '((mw-thesaurus :location (recipe
                             :fetcher github
                             :repo "agzam/mw-thesaurus.el"))

    ;; sdcv-mode is for browsing Stardict format dictionaries in Emacs
    ;;
    ;; to get Webster’s Revised Unabridged Dictionary
    ;; 1) download it from https://s3.amazonaws.com/jsomers/dictionary.zip
    ;; 2) unzip it twice and put into ~/.stardict/dic
    ;; 3) Install sdcv, a command-line utility for accessing StarDict dictionaries
    ;;
    ;; you can find more dicts in stardict format here: http://download.huzheng.org/dict.org/
    ;; don't get the package from MELPA - it's been reported broken
    (sdcv-mode :location (recipe
                          :fetcher github
                          :repo "gucong/emacs-sdcv"))))

(defun ag-lang-tools/init-mw-thesaurus ()
  (use-package mw-thesaurus
    :ensure t))

(defun ag-lang-tools/init-sdcv-mode ()
  (use-package sdcv-mode
    :ensure t
    :config
    (add-hook 'sdcv-mode-hook 'spacemacs/toggle-visual-line-navigation-on)))
