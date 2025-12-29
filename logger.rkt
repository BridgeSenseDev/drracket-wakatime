#lang racket/base

(provide log-wakatime)

(require racket/gui/base)

(define session-suppressed? #f)

(define (log-wakatime msg #:popup? [popup? #t])
  (eprintf "[~a] ~a\n" "WakaTime" msg)

  (when (and popup? (not session-suppressed?))
    (define result
      (message-box/custom
       "WakaTime"
       msg
       "OK"
       "Don't show again this session"
       #f
       #f
       '(stop default=1)))

    (when (equal? result 2)
      (set! session-suppressed? #t))))
