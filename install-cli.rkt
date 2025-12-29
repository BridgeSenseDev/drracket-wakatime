#lang racket/base

(provide ensure-wakatime-cli)

(require racket/file
         racket/port
         racket/string
         net/url
         file/unzip
         "path.rkt"
         "logger.rkt")

(define (get-download-url)
  (format "https://github.com/wakatime/wakatime-cli/releases/latest/download/wakatime-cli-~a-~a.zip"
          os-name
          arch-name))

(define (download-file url-string dest-path)
  (define in (get-pure-port (string->url url-string) #:redirections 5))

  (call-with-output-file dest-path (lambda (out) (copy-port in out)) #:exists 'replace)

  (close-input-port in))

(define (install-cli)
  (define dir (get-wakatime-dir))
  (define target-path (get-cli-path))
  (define zip-path (build-path dir "wakatime-cli.zip"))

  (make-directory* dir)

  (with-handlers
      ([exn:fail?
        (lambda (e)
          (when (file-exists? zip-path)
            (delete-file zip-path))
          (log-wakatime
           (format "Failed to download wakatime-cli.\nError: ~a" (exn-message e))))])

    (download-file (get-download-url) zip-path)

    (call-with-input-file zip-path
                          (lambda (in)
                            (unzip in
                                   (lambda (entry-name is-dir? entry-in)
                                     (unless is-dir?
                                       (define temp-dest
                                         (build-path dir (bytes->path-element entry-name)))
                                       (call-with-output-file temp-dest
                                                              (lambda (out) (copy-port entry-in out))
                                                              #:exists 'replace))))))
    (delete-file zip-path)

    (for ([f (directory-list dir)])
      (define fname (path->string f))
      (define full-path (build-path dir f))
      (when (and (string-prefix? fname "wakatime-cli")
                 (not (equal? full-path target-path))
                 (not (string-suffix? fname ".zip")))
        (rename-file-or-directory full-path target-path #t)))

    (unless (eq? (system-type) 'windows)
      (file-or-directory-permissions target-path #o755))

    (log-wakatime "Installed wakatime-cli" #:popup? #f)))

(define (ensure-wakatime-cli)
  (unless (file-exists? (get-cli-path))
    (install-cli)))
