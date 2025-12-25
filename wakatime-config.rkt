#lang racket/base
(provide has-wakatime-api-key?
         get-wakatime-api-key
         set-wakatime-api-key)
(require racket/file
         racket/string)

(define wakatime-path (build-path (find-system-path 'home-dir) ".wakatime.cfg"))

(define (read-config)
  (if (file-exists? wakatime-path)
      (file->string wakatime-path)
      ""))

;; Parse INI to find api_key under [settings]
(define (get-wakatime-api-key)
  (define content (read-config))
  (define lines (string-split content "\n"))
  (define in-settings? #f)
  (for/or ([line (in-list lines)])
    (define trimmed (string-trim line))
    (cond
      [(string-prefix? trimmed "[")
       (set! in-settings? (equal? trimmed "[settings]")) #f]
      [(and in-settings? (regexp-match #px"^api_key\\s*=\\s*(.+)$" trimmed))
       => (lambda (m) (string-trim (cadr m)))]
      [else #f])))

(define (has-wakatime-api-key?)
  (define key (get-wakatime-api-key))
  (and key (non-empty-string? key)))

(define (set-wakatime-api-key key)
  (define content (read-config))
  (define lines (string-split content "\n"))
  
  (define in-settings? #f)
  (define found-key? #f)
  (define added-key? #f)
  
  (define new-lines
    (for/fold ([result '()])
              ([line (in-list lines)])
      (define trimmed (string-trim line))
      (cond
        [(string-prefix? trimmed "[")
         ;; leaving [settings] without finding api_key
         (define should-insert? (and in-settings? (not found-key?) (not added-key?)))
         (set! in-settings? (equal? trimmed "[settings]"))
         (if should-insert?
             (append result (list (string-append "api_key = " key) line))
             (append result (list line)))]
        ;; reached api_key line in [settings]
        [(and in-settings? (regexp-match? #px"^api_key\\s*=" trimmed))
         (set! found-key? #t)
         (set! added-key? #t)
         (append result (list (string-append "api_key = " key)))]
        [else (append result (list line))])))
  
  (define final-lines
    (if added-key?
        new-lines
        (cond
          ;; in [settings] at end of file
          [(and in-settings? (not found-key?))
           (append new-lines (list (string-append "api_key = " key)))]
          ;; no [settings] exists
          [(not (for/or ([line (in-list lines)]) (equal? (string-trim line) "[settings]")))
           (if (null? new-lines)
               (list "[settings]" (string-append "api_key = " key))
               (append new-lines (list "" "[settings]" (string-append "api_key = " key))))]
          [else new-lines])))
  
  (with-handlers ([exn:fail:filesystem?
                   (lambda (e)
                     (error 'set-wakatime-api-key
                            "Cannot write to ~a: ~a"
                            wakatime-path
                            (exn-message e)))])
    (call-with-output-file wakatime-path
      (lambda (out)
        (display (string-join final-lines "\n") out))
      #:exists 'replace)))