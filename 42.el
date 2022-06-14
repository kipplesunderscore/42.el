;;; .local/straight/repos/42.el/42.el -*- lexical-binding: t; -*-

(eval-and-compile
  (require 'yasnippet))

(defvar 42-header-user nil
  "42 user name used in the header. if nil will use $USER instead.")

(defvar 42-header-mail nil
  "42 user email used in the header. if nil will use $MAIL instead.")

(defvar 42-header-max-info-width 50)

(defvar 42-header-updated-search-regexp "Updated:")

(defun 42-header-get-user ()
  "returns the 42 header user string."
  (if 42-header-user
      42-header-user
    (getenv "USER")))

(defun 42-header-get-mail ()
  "returns the 42 header mail string."
  (if 42-header-mail
      42-header-mail
    (getenv "MAIL")))

(defun 42-header-truncate-string (str max-len)
  "truncates string to max-len and adds ellipis. will always return a string >= 3 (...)."
  (if (> (length str) max-len)
      (if (<= max-len 3)
          "..."
        (let* ((max (- max-len 3))
               (new-str (substring str 0 max)))
          (concat new-str "...")))
    str))

(defun 42-header-pad-string (str len)
  (let ((str-len (length str)))
    (if (>= str-len len)
        str
      (format "%s%s" str (make-string (- len str-len) 32)))))


(defun 42-header-timestamp-info-line (label)
  "generate the timestamp info line with label (Created / Updated ...)"
  (let ((left-margin "/*   ")
        (date-time (format-time-string "%Y/%m/%d %H:%M:%S"))
        (login (42-header-get-user)))
    (42-header-pad-string
     (42-header-truncate-string
      (format "%s%s: %s by %s" left-margin label date-time login)
      42-header-max-info-width) 42-header-max-info-width)))

(defun 42-header-updated-line-string ()
  "generate the updated line stirng for the 42 header."
  (42-header-timestamp-info-line "Updated"))

(defun 42-header-created-line-string ()
  "genereate the created line string for the 42 header."
  (42-header-timestamp-info-line "Created"))

(defun 42-header-mail-line-string ()
  "generate the user mail line string for the 42 header."
  (let ((left-margin "/*   "))
    (42-header-pad-string
     (format "%s>"
             (42-header-truncate-string
              (format "%sBy: %s <%s"
                      left-margin
                      (42-header-get-user)
                      (42-header-get-mail))
              (1- 42-header-max-info-width)))
     42-header-max-info-width)))

(defun 42-header-file-name-line-string (&optional file-name)
  "generate the filename string for the 42 header."
  (let ((file-name (if file-name
                       file-name
                     (file-name-nondirectory (buffer-file-name))))
        (left-margin "/*   "))
    (42-header-pad-string
     (42-header-truncate-string
      (format "%s%s" left-margin file-name)
      42-header-max-info-width)
     42-header-max-info-width)))

(defun 42-header-update-header ()
  "updates the current header for the current buffer."
  (interactive)
  (if 42-mode
  (save-excursion
    (if (buffer-modified-p)
        (progn
          (goto-char (point-min))
          (if (search-forward-regexp 42-header-updated-search-regexp nil t)
              (progn
                (delete-region
                 (progn (beginning-of-line) (point))
                 (progn (forward-char 42-header-max-info-width) (point)))
                (insert (42-header-updated-line-string)))))))))

(defvar 42-el-root
  (file-name-directory
   (cond (load-in-progress load-file-name)
         ((bound-and-true-p byte-compile-current-file)
          byte-compile-current-file)
         (buffer-file-name)))
  "The base directory of the 42.el library.")

(defvar 42-el-snippet-dir (expand-file-name "snippets" 42-el-root))

(defun 42-header-insert-header ()
  "inserts the 42 header at the top of the file."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (yas-expand-snippet (yas-lookup-snippet "stdheader"))))

(defvar flycheck-norminette-compat-flags
  "List of compatability flags (-R) to pass to norminette. i.e. '(\"CheckDefine\")"
  '())

(flycheck-define-checker norminette
  "The 42 school checker using the norminette command."
  :command ("norminette"
	    source-inplace)
  :error-patterns ((error line-start "Error: " (zero-or-more anything) "line:" (0+ (any " ")) line ", col:" (0+ (any " ")) (0+ digit) "):" (0+ blank) (message) line-end))
  :modes c-mode
  :next-checkers ((error . c/c++-clang)
		  (warning . c/c++-cppcheck)))

;;;###autoload
(defun 42-snippet-initialize ()
  (add-to-list 'yas-snippet-dirs '42-el-snippet-dir)
  (yas-load-directory 42-el-snippet-dir t))

;;;###autoload
(eval-after-load 'yasnippet
  (lambda () (42-snippet-initialize)))

(define-minor-mode 42-mode
  "Toggles the 42-mode."
  :global nil
  :group '42
  :lighter " 42"
  :keymap (let ((map (make-sparse-keymap)))
	    (define-key map (kbd "C-<f1>") #'42-header-insert-header)
	    (define-key map (kbd "TAB") #'self-insert-command)
	    map)
  (add-hook 'write-file-functions #'42-header-update-header)
  (setq-default c-basic-offset 4
		tab-width 4
		tab-stop-list (number-sequence 4 80 4)
		indent-tabs-mode t)
  (add-to-list 'flycheck-checkers 'norminette))

(provide '42.el)
