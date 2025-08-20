#lang racket/base

(require
 racket/set
 racket/contract
 trace-contract
 "../../../ctcs/precision-config.rkt"
 "../../../ctcs/common.rkt"
 "../../../ctcs/configurable.rkt")

;; representing the deck of STACKS stack on the table

(provide/configurable-contract
 ;; CardPool -> Deck 
 [create-deck ([trace create-deck-trace/c]
               [max (-> any/c any/c)]
               [types (-> any/c any/c)])])

;; trace contract to validate that a single card can't be seen multiple times
;; in a given round
;; IDEA: also validate the number of cards played in a given round. although
;; this might not be possible: deck.rkt can't see the number of players,
;; but the number of cards is calculated as (+ STACKS (* HAND n-players))
(define create-deck-trace/c
  (trace/c ([reset-marker any/c]
            [c card?])
           ;; NOTE: We can't put a collector contract on the cards0 field of
           ;; deck%, since the field is defined on the server side. Instead,
           ;; the collector is attached to card-pool%, since we know those
           ;; drawn within create-deck will be added to the deck.

           ((and/c reset-marker ;; requesting a new deck resets the trace
                   (object/c ;; card-pool%
                    (draw-card (-> any/c c))))
            . -> .
            (object/c ;; deck%
             (push (-> any/c c void?))
             (replace (any/c (listof card?) c . -> . natural-number/c))))
           (accumulate (set)
                       [(reset-marker) (λ (_tr _val)
                                         (displayln "resetting trace")
                                         (set))]
                       [(c) (λ (tr card)
                              (displayln card)
                              (if (set-member? tr card)
                                  (fail)
                                  (set-add tr card)))])))

;; -----------------------------------------------------------------------------

(require
  racket/class
  racket/list
  "../base/untyped.rkt"
  "card.rkt"
)

(require (only-in "basics.rkt"
  FACE
  STACKS
))
(require (only-in "stack.rkt"
  bulls
))

;; For the assert
(define (stack? s)
  (and (list? s)
    (for/and ((x (in-list s))) (card? x))
    (let ((l (length s)))
      (and (< 0 l) (< l 6)))))

;; ---------------------------------------------------------------------------------------------------

(define (create-deck card-pool)
  (define deck% (for-player (for-dealer base-deck%)))
  (define cards (build-list STACKS (lambda (_) (send card-pool draw-card))))
  (new deck% [cards0 cards]))

;; Class[my-stacks field] -> Class[my-stacks field and fewest-bulls method]
(define (for-player deck%)
  (class deck%
    (inherit-field my-stacks)
    (super-new)

    (define/public (fewest-bulls)
      (define stacks-with-bulls
        (for/list
                  ((s my-stacks))
          (list s (bulls s))))
      (first (argmin (lambda (l) (second l)) stacks-with-bulls)))))

;; Class[cards0 field] -> Class[fit, push, replace & larger-than-some-top-of-stacks? methods]
(define (for-dealer deck%)
  (class deck%
    (inherit-field cards0)
    (inherit-field my-stacks)
    (super-new)

    ;; [Listof Stack]
    (set-field! my-stacks this (map (lambda (c) (list c)) cards0))
    ;(field [my-stacks

    ;; Return the stack for which the top card has the nearest value below `c`
    (define/public (fit c)
      (define (distance stack)
        (define d (first stack))
        (if (>-face c d) (--face c d) (+ FACE 1)))
      (argmin distance my-stacks))

    ;; Add `c` to the proper stack, as determined by `fit`
    (define/public (push c)
      (define s0 (fit c))
      (void (replace-stack (first s0) c)))

    ;; Replaces the stack `s` with a single card `c`
    (define/public (replace s c)
      (replace-stack (first s) (list c)))

    ;; If `c` is a list (other than null), replaces the stack with top card
    ;; `top0` with `c`. Otherwise, appends `c` to that stack
    (define/public (replace-stack top0 c)
      (define result  0)
      (set! my-stacks 
            (for/list  ((s  my-stacks))
              (cond
                [(equal? (first s) top0)
                 (set! result (bulls s))
                 (if (cons? c)
                  c
                  (if (null? c) (error 'invalid-input) (cons c s)))]
                [else s])))
      result)

    ;; Is the card larger than the top card of any stack?
    (define/public (larger-than-some-top-of-stacks? c)
      (for/or ((s my-stacks))
        (>-face c (first s))))))

;; Class[cards0 field]
(define base-deck%
  (class object%
    (init-field
     ;; [Listof Card]
     ;; the tops of the initial stacks (for a round)
     cards0)

    (field (my-stacks '()))

    (super-new)))
