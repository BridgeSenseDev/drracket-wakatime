#lang racket/base

(provide get-wakatime-dir
         get-cli-path
         wakatime-cfg-path
         wakatime-log-path
         os-name
         arch-name)

(require racket/system
         racket/string)

(define os-name
  (case (system-type 'os)
    [(macosx) "darwin"]
    [(windows) "windows"]
    [(unix)   "linux"]))

(define arch-name
  (case (system-type 'arch)
    [(x86_64) "amd64"]
    [(aarch64) "arm64"]
    [(arm) "arm"]
    [(i386) "386"]))

(define (get-wakatime-dir)
  (define env-home (getenv "WAKATIME_HOME"))
  (cond
    [(and env-home (directory-exists? env-home)) (string->path env-home)]
    [else (build-path (find-system-path 'home-dir) ".wakatime")]))

(define (get-cli-path)
  (define ext (if (eq? (system-type) 'windows) ".exe" ""))
  (build-path (get-wakatime-dir) (string-append "wakatime-cli" ext)))

(define wakatime-log-path
  (build-path (get-wakatime-dir) "wakatime.log"))

(define wakatime-cfg-path
  (build-path (find-system-path 'home-dir) ".wakatime.cfg"))

