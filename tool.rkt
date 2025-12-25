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

  (define (phase1)
    (unless (has-wakatime-api-key?)
      (set-wakatime-api-key (get-text-from-user "wakatime api-key" "enter key:"))))
  (define (phase2) (void))

  (define drracket-editor-mixin
    (mixin (drracket:unit:definitions-text<%> racket:text<%>) ()
      (super-new)

      (define (local-send-heartbeat)
        (thread
         (lambda ()
           (define filename (send this get-filename))
           (if filename
               (let ([project (find-project-name (path-only filename))])
                 (send-heartbeat #:file filename #:project project))
               (send-heartbeat #:file "Untitled.rkt")))))

      (define/augment (on-change)
        (local-send-heartbeat))))

  (drracket:get/extend:extend-definitions-text drracket-editor-mixin))
