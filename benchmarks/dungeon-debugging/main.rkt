#lang racket

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
           (λ (_box val) val)
           (λ (_box val) val)
           box-prop-desc
           "Not much to see here..."))))]))

  (define-values (box-prop-desc box-prop? box-prop-access)
    (make-impersonator-property 'box))

  (define (test b)
    (displayln (format "Hello, am I a chaperone during test?\n ~a" (chaperone? b)))
    (displayln (format "And, do I have a chaperone property test?\n ~a" (box-prop? b)))
    (displayln (format "Oh, what is the property?\n ~a" (box-prop-access b))))

  (define my-box
    (box (new object%))))

(module client racket
  (require (submod ".." server))  (define b my-box)
  (displayln (format "Hello, am I a chaperone before test?\n ~a" (chaperone? b)))
  (test b)
  (displayln (format "Hello, am I a chaperone after test?\n ~a" (chaperone? b))))

(require 'client)
