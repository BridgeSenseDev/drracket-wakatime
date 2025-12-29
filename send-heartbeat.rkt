#lang racket/base

(provide send-heartbeat)

(require racket/system
         racket/port
         racket/match
         racket/string
         racket/runtime-path
         setup/getinfo
         "path.rkt"
         "logger.rkt")

(define-runtime-path here ".")
(define get-project-info (get-info/full here))
(define version
  (if get-project-info
      (get-project-info 'version (lambda () "unknown"))
      "unknown"))

(define (get-exe-path)
  (define local-cli (get-cli-path))
  (cond
    [(file-exists? local-cli) (path->string local-cli)]
    [(find-executable-path "wakatime-cli") (path->string (find-executable-path "wakatime-cli"))]
    [else #f]))

(define (send-heartbeat #:file filename #:project [project #f] #:is-write? [is-write? #f])
  (define exe (get-exe-path))
  (cond
    [exe
     (define cmd
       (format "~a --entity ~a --language racket --plugin drracket-wakatime/~a --verbose" exe filename version))
     (set! cmd
           (if project
               (string-append cmd (format " --project ~a" project))
               cmd))
     (set! cmd (string-append cmd (if is-write? " --write" "")))
     (match-define (list stdout stdin pid stderr run) (process cmd))
     (run 'wait)
     (define exit-code (run 'exit-code))

     (close-input-port stdout)
     (close-input-port stderr)
     (close-output-port stdin)

     (unless (member exit-code '(0 102 112))
       (define msg
         (case exit-code
           [(103) "Config parsing error (fix your ~a file)" wakatime-cfg-path]
           [(104) "Invalid API Key (check your key at https://wakatime.com/settings)"]
           [(105) "Malformed heartbeat error"]
           [(106) "API timeout (will retry later)"]
           [else (format "Unknown error code ~a (check ~a)" exit-code wakatime-log-path)]))
       (log-wakatime msg))]
    [else (log-wakatime "wakatime-cli not found" #:popup? #f)]))

(module+ test
  (require rackunit)

  (when (find-executable-path "wakatime-cli")
    (check-eq? (send-heartbeat #:file "main.rkt" #:project "drracket-wakatime-test") (void))))
