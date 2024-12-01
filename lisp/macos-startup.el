;;; macos-startup.el --- macOS specific startup actions  -*- lexical-binding: t -*-

;; Maintainer: Jim Myhrberg <contact@jimeh.me>
;; Keywords: macos, internal
;; Homepage: https://github.com/jimeh/build-emacs-for-macos

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file contains macOS specific startup actions for self-contained
;; macOS *.app bundles.  It enables native-compilation via a bundled
;; libgccjit, and for bundled C-sources to be found for documentation
;; purposes,

;;; Code:

(defun macos-startup--in-app-bundle-p ()
  "Check if invoked from a macOS .app bundle."
  (and (eq system-type 'darwin)
       invocation-directory
       (string-match-p ".+\\.app/Contents/MacOS/?$" invocation-directory)))

(defun macos-startup--set-source-directory ()
  "Set `source-directory' so that C-sources can be located."
  (let* ((src-dir (expand-file-name "../Resources/src" invocation-directory)))
    (when (file-directory-p src-dir)
      (setq source-directory (file-name-directory src-dir)))))

(defun macos-startup--setup-library-path ()
  "Configure LIBRARY_PATH env var for native compilation on macOS.

Ensures LIBRARY_PATH includes paths to the libgccjit and gcc libraries
which are bundled into the .app bundle.  This allows native compilation
to work without any external system dependencies aside from Xcode."
  (let* ((new-paths
          (list (expand-file-name "../Frameworks/gcc/lib" invocation-directory)
                (expand-file-name "../Frameworks/gcc/lib/apple-darwin" invocation-directory)
                "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"))
         (valid-paths (delq nil (mapcar (lambda (path)
                                          (when (file-directory-p path)
                                            path))
                                        new-paths)))
         (existing-paths (split-string (or (getenv "LIBRARY_PATH") "") ":" t))
         (unique-paths (delete-dups (append valid-paths existing-paths))))

    (when unique-paths
      (setenv "LIBRARY_PATH" (mapconcat 'identity unique-paths path-separator)))))

(defun macos-startup--init ()
  "Perform macOS specific startup operations."
  (when (macos-startup--in-app-bundle-p)
    (macos-startup--set-source-directory)
    (when (and (fboundp 'native-comp-available-p)
               (native-comp-available-p))
      (macos-startup--setup-library-path))))

(add-hook 'after-pdump-load-hook #'macos-startup--init)

;;; macos-startup.el ends here
