#lang racket/base

(provide find-project-name)

(define (basename path)
  (define-values (base file dir?) (split-path path))
  base)

;; return just the name of the project folder
(define (get-dir-name path)
  (define-values (base file dir?) (split-path path))
  (if (path? file)
      (path->string file)
      (path->string path)))

; return where we find `info.rkt` or `.git/`, else `#f`
(define (find-project-name dir)
  (cond
    [(or (file-exists? (build-path dir "info.rkt"))
         (directory-exists? (build-path dir ".git")))
     (get-dir-name dir)]
    [else (define parent-dir (basename dir))
          (if parent-dir
              (find-project-name parent-dir)
              #f)]))

(module+ test
  (require rackunit)

  (check-equal? (find-project-name (current-directory))
                (get-dir-name (current-directory))))
