#lang formatted-string racket/base
(provide send-heartbeat)
(require racket/system
         racket/port
         racket/match
         racket/string
         racket/runtime-path
         setup/getinfo)

(define-runtime-path here ".")
(define get-project-info (get-info/full here))
(define version (if get-project-info
                    (get-project-info 'version (lambda () "unknown"))
                    "unknown"))

(define wakatime-log-path
  (build-path (find-system-path 'home-dir) ".wakatime" "wakatime.log"))
(define wakatime-cfg-path
  (build-path (find-system-path 'home-dir) ".wakatime.cfg"))

(define (send-heartbeat #:file filename #:project [project #f])
  (define exe (find-executable-path "wakatime-cli"))
  (unless exe
    (error 'executable "cannot find executable in \$PATH, please check your environment setup"))
  (define cmd "$exe --entity $filename --language racket --plugin drracket-wakatime/$version --write --verbose")
  (set! cmd (if project (string-append cmd " --project $project") cmd))
  (match-define (list stdout stdin pid stderr run)
    (process cmd))
  (run 'wait)
  (define exit-code (run 'exit-code))

  (close-input-port stdout)
  (close-input-port stderr)
  (close-output-port stdin)

  (define (raise-waka-error code)
    (define msg
      (case code
        [(0 102 112) (void)]
        [(103) (format "Config parsing error (fix your ~a file)" wakatime-cfg-path)]
        [(104) "Invalid API Key (check your key at https://wakatime.com/settings)"]
        [(105) "Malformed heartbeat error"]
        [(106) "API timeout (will retry later)"]
        [else  (format "Unknown error code ~a (check ~a)" exit-code wakatime-log-path)]))
    (error 'wakatime msg))

  (raise-waka-error exit-code))

(module+ test
  (require rackunit)

  (when (find-executable-path "wakatime-cli")
    (check-eq? (send-heartbeat #:file "main.rkt" #:project "drracket-wakatime-test")
               (void))))

