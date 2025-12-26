#lang racket
(provide tool@)
(require drracket/tool
         framework
         racket/gui/base
         "send-heartbeat.rkt"
         "find-project.rkt"
         "wakatime-config.rkt")

(define-unit tool@
  (import drracket:tool^)
  (export drracket:tool-exports^)

  (define last-heartbeat-time 0)
  (define last-heartbeat-file "")
  (define heartbeat-interval 120)

  (define (phase1)
    (unless (has-wakatime-api-key?)
      (set-wakatime-api-key (get-text-from-user "wakatime api-key" "enter key:"))))
  (define (phase2) (void))

  (define drracket-editor-mixin
    (mixin (drracket:unit:definitions-text<%> racket:text<%>) ()
      (super-new)

      (define (wakatime-update #:is-write? [is-write? #f])
        (define filename (send this get-filename))
        (define file (if filename
                         (path->string (simple-form-path filename))
                         "Untitled.rkt"))
        (define current-time (current-seconds))
        (define should-send? (or is-write?
                                 (not (string=? file last-heartbeat-file))
                                 (> (- current-time last-heartbeat-time) heartbeat-interval)))

        (when should-send?
          (set! last-heartbeat-time current-time)
          (set! last-heartbeat-file file)
          (thread
           (lambda ()
             (define project (if filename
                                 (find-project-name (path-only filename))
                                 #f))
             (send-heartbeat #:file file
                             #:project project
                             #:is-write? is-write?)))))

      (define/augment (on-change)
        (wakatime-update #:is-write? #f)
        (inner (void) on-change))

      (define/augment (after-save-file success?)
        (when success?
          (wakatime-update #:is-write? #t))
        (inner (void) after-save-file success?))

      (define/override (on-focus on?)
        (when on?
          (wakatime-update #:is-write? #f))
        (super on-focus on?))
      ))

  (drracket:get/extend:extend-definitions-text drracket-editor-mixin))
