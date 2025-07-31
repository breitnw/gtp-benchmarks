#lang racket

;; -----------------------------------------------------------------------------

(module server racket
  (require trace-contract)

  (provide
   (contract-out
    [test
     ;; changing object/c to any other contract (tried flat, arrow, box/c, etc)
     ;; seems to fix the issue
     (trace/c ([g (box/c (object/c))])
              ;; Problem only arises when the collector intercepts the value.
              ;; Fixed by replacing g with any/c
              (g . -> . void?)
              (full (g) (λ (_tr) #t)))]
    [my-box
     (make-chaperone-contract
      #:name 'test-chaperone/c
      #:projection
      (λ (_b)
        (λ (bx)
          (chaperone-box
           bx
           (λ (_box val)
             (displayln "chaperone unboxed!")
             val)
           (λ (_box val) val)))))]))

  (define (test b)
    (displayln (format "(server, during test) -> chaperone?: ~a" (chaperone? b)))
    (unbox b)
    (void))

  (define my-box
    (box (new object%))))

;; -----------------------------------------------------------------------------

(module client racket
  (require (submod ".." server))

  (define b my-box)
  (displayln (format "(client, before test) -> chaperone?: ~a" (chaperone? b)))
  (unbox b)
  (test b)
  (displayln (format "(client, after test) -> chaperone?: ~a" (chaperone? b)))
  (unbox b))

;; -----------------------------------------------------------------------------

(require 'client)
