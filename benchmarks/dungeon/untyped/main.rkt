#lang racket

;; -----------------------------------------------------------------------------

(require
  require-typed-check
  racket/class
  "../base/un-types.rkt"
  racket/match
  racket/contract
  (only-in "../../../ctcs/common.rkt" or-#f/c)
  "../../../ctcs/precision-config.rkt"
  "../../../ctcs/configurable.rkt"
  )
(require (only-in racket/set
                  set-intersect
                  ))
(require (only-in racket/dict
                  dict-set
                  ))
(require (only-in "cell.rkt"
                  ;;   void-cell%
                  ;;   wall%
                  ;;   door%
                  ;;   vertical-door%
                  ;;   horizontal-door%
                  ;;   horizontal-wall%
                  ;;   four-corner-wall%
                  ;;   pillar%
                  ;;   vertical-wall%
                  ;;   north-west-wall%
                  ;;   north-east-wall%
                  ;;   south-west-wall%
                  ;;   south-east-wall%
                  ;;   north-tee-wall%
                  ;;   west-tee-wall%
                  ;;   east-tee-wall%
                  ;;   south-tee-wall%
                  ;;   empty-cell%
                  cell%?
                  cell%/c
                  ;;   cell%
                  ))
(require/configurable-contract "cell.rkt" cell% empty-cell% south-tee-wall% east-tee-wall% west-tee-wall% north-tee-wall% south-east-wall% south-west-wall% north-east-wall% north-west-wall% vertical-wall% pillar% four-corner-wall% horizontal-wall% horizontal-door% vertical-door% door% wall% void-cell% )
(require (only-in "grid.rkt"
                  ;;   left
                  ;;   right
                  ;;   up
                  ;;   down
                  ;;   grid-ref
                  ;;   grid-height
                  ;;   grid-width
                  ;;   show-grid
                  ;;   array-set!
                  ;;   build-array
                  array-coord?
                  arrayof
                  grid?
                  ;;   within-grid?
                  within-grid/c
                  direction?
                  ))
(require/configurable-contract "grid.rkt" within-grid? build-array array-set! show-grid grid-width grid-height grid-ref down up right left )
(require (only-in "utils.rkt"
                  ;;   random-between
                  ;;   random-from
                  ;;   random
                  ;;   reset!
                  random-result-between/c
                  ))
(require/configurable-contract "utils.rkt" reset! #;random random-from random-between random-upto)

;; (provide/configurable-contract
;;  [N exact-nonnegative-integer?]
;;  [wall-cache ([max (hash/c array-coord? boolean?)]
;;               [types hash?])]
;;  [free-cache ([max (hash/c array-coord? boolean?)]
;;               [types hash?])]
;;  [animate-generation? boolean?]
;;  [ITERS exact-nonnegative-integer?]
;;  [dungeon-height exact-nonnegative-integer?]
;;  [dungeon-width exact-nonnegative-integer?]
;;  [try-add-rectangle ([max (->i ([grid grid?]
;;                                 [pos (grid) (and/c array-coord?
;;                                                    (within-grid/c grid))]
;;                                 [height index?]
;;                                 [width index?]
;;                                 [direction direction?])
;;                                [result (pos height width direction)
;;                                        (or-#f/c
;;                                         (room-with/c
;;                                          (=/c height)
;;                                          (=/c width)
;;                                          (alistof (and/c array-coord?
;;                                                          (coord-within-box/c pos
;;                                                                              height
;;                                                                              width
;;                                                                              direction))
;;                                                   cell%/c)
;;                                          ;; ll: I don't think these can (reasonably) be
;;                                          ;; refined (note that they still have the default
;;                                          ;; room contract, see definition of room-with/c)
;;                                          any/c
;;                                          any/c))])]
;;                      [types (grid? array-coord? index? index? direction? 
;;                                    . -> .
;;                                    (or-#f/c any-room?))])]
;;  [commit-room ([max (->i ([grid grid?]
;;                           [room any-room?])
;;                          [result void?]
;;                          #:post (grid room)
;;                          (for/and ([pos+cell% (in-list (room-poss->cells room))])
;;                            (match-define (cons pos poss-cell%) pos+cell%)
;;                            (is-a? (grid-ref grid pos)
;;                                   poss-cell%)))]
;;                [types (grid? any-room? . -> . void?)])]
;;  [random-direction ([max (-> (curryr member (list left right up down)))]
;;                     [types (-> direction?)])]
;;  [horizontal? ([max (->i ([dir direction?])
;;                          [result (dir) (if (member dir (list left right))
;;                                            #t
;;                                            #f)])]
;;                [types (direction? . -> . boolean?)])]
;;  [vertical? ([max (->i ([dir direction?])
;;                        [result (dir) (if (member dir (list up down))
;;                                          #t
;;                                          #f)])]
;;              [types (direction? . -> . boolean?)])]
;;  [new-room ([max (->i ([grid grid?]
;;                        [pos (grid) (and/c array-coord?
;;                                           (within-grid/c grid))]
;;                        [dir direction?])
;;                       [result (pos dir)
;;                               (or-#f/c
;;                                (room-with/c
;;                                 (random-result-between/c 7 11)
;;                                 (random-result-between/c 7 11)
;;                                 (alistof (and/c array-coord?
;;                                                 ;; ll: Just make sure it's within the max
;;                                                 (coord-within-box/c pos
;;                                                                     11
;;                                                                     11
;;                                                                     dir))
;;                                          cell%/c)
;;                                 any/c
;;                                 any/c))])]
;;             [types (grid? array-coord? direction? . -> . (or-#f/c any-room?))])]
;;  [new-corridor ([max (->i ([grid grid?]
;;                            [pos array-coord?]
;;                            [dir direction?])
;;                           [result (pos dir)
;;                                   (let* ([h? (horizontal? dir)]
;;                                          [h (if h? 3 8)]
;;                                          [w (if h? 10 3)])
;;                                     (or-#f/c
;;                                      (room-with/c
;;                                       (random-result-between/c 3 8)
;;                                       (random-result-between/c 3 10)
;;                                       (alistof (and/c array-coord?
;;                                                       ;; ll: Just make sure it's within
;;                                                       ;; the max
;;                                                       (coord-within-box/c pos
;;                                                                           h
;;                                                                           w
;;                                                                           dir))
;;                                                cell%/c)
;;                                       any/c
;;                                       any/c)))])]
;;                 [types (grid? array-coord? direction? . -> . (or-#f/c any-room?))])]
;;  [generate-dungeon ([max (->i ([encounters (listof exact-nonnegative-integer?)])
;;                               [result
;;                                (encounters)
;;                                (and/c grid?
;;                                       (room-count>=/c (length encounters)))])]
;;                     [types ((listof exact-nonnegative-integer?) . -> . grid?)])]
;;  [counts-as-free? ([max (->i ([grid grid?]
;;                               [pos array-coord?])
;;                              [result boolean?]
;;                              #:post (grid pos result) (let ([c (grid-ref grid pos)])
;;                                                         (or (false? result)
;;                                                             (is-a? c empty-cell%)
;;                                                             (is-a? c door%))))]
;;                    [types (grid? array-coord? . -> . boolean?)])]
;;  [hash-clear! any/c]
;;  [smooth-walls ([max (grid? . -> . grid?)]
;;                 [types (grid? . -> . grid?)])]
;;  [smooth-single-wall ([max (grid? array-coord? . -> . void?)]
;;                       [types (grid? array-coord? . -> . void?)])]
;;  [LOOPS exact-nonnegative-integer?]
;;  [main any/c])

;; =============================================================================
;(define-type Poss->Cells (Listof (Pairof Pos Cell%)))
;(define-type Direction (->* (Pos) (Index) Pos))
;(define-type Cache (HashTable Pos Boolean))
;(define-type ExtPoints (Listof (Pairof Pos Room)))
;; dungeon generation

(define/ctc-helper (alistof key/c val/c)
  (listof (cons/c key/c val/c)))

(struct room
  (height
   width
   poss->cells ; maps positions to cell constructors
   ;;            (so that we can construct the room later when we commit to it)
   free-cells   ; where monsters or treasure could go
   extension-points) ; where a corridor could sprout
  #:mutable)

(define/ctc-helper (room-with/c height/c
                                width/c
                                poss->cells/c
                                free-cells/c
                                extension-points/c)
  (struct/c room
            (and/c index?
                   height/c)
            (and/c index?
                   width/c)
            (and/c (alistof array-coord? cell%/c)
                   poss->cells/c)
            (and/c (listof array-coord?)
                   free-cells/c)
            (and/c (listof array-coord?)
                   extension-points/c)))
(define/ctc-helper any-room? (room-with/c any/c any/c any/c any/c any/c))


;; -----------------------------------------------------------------------------

(define N 1)
    
(define wall-cache
  ;; #:mutable
  (make-hash))

(define free-cache
  ;; #:mutable
  (make-hash))

(define animate-generation? #f) ; to see intermediate steps
(define ITERS 10)
(define dungeon-height 18) ; to be easy to display in 80x24, with other stuff
(define dungeon-width  60)

;; -----------------------------------------------------------------------------

(define/ctc-helper (room-bounds x y height width direction)
  (define-values (min-x max-x)
    (match direction
      [(== down) (values x (+ x (sub1 height)))]
      [(== up) (values (add1 (- x height)) x)]
      ;; Could be any window between down and up, allow them all
      [else    (values (add1 (- x height)) (+ x (sub1 height)))]))
  (define-values (min-y max-y)
    (match direction
      [(== right) (values y (+ y width))]
      [(== left)  (values (add1 (- y width)) y)]
      ;; Could be any window between left and right, allow them all
      [else       (values (add1 (- y width)) (+ y width))]))
  (values min-x max-x
          min-y max-y))

(define/ctc-helper ((coord-within-box/c start-pos height width direction) cell-coord)
  (match-define (vector start-x start-y) start-pos)
  (match-define (vector cell-x cell-y) cell-coord)
  (define-values (min-x max-x min-y max-y)
    (room-bounds start-x start-y height width direction))
  (and (>= cell-x min-x)
       (<= cell-x max-x)
       (>= cell-y min-y)
       (<= cell-y max-y)))

(define (try-add-rectangle grid pos height width direction)
  ;; height and width include a wall of one cell wide on each side
  (match-define (vector x y) pos)
  (define min-x (match direction
                  [(== down) x]
                  ;; expanding north, we have to move the top of the room
                  ;; up so the bottom reaches the starting point
                  [(== up) (+ (- x height) 1)]
                  ;; have the entrance be at a random position on the
                  ;; entrance-side wall
                  [else    (sub1 (- x (random-upto (- height 2))))]))
  (define min-y (match direction
                  ;; same idea as for x
                  [(== right) y]
                  [(== left)  (+ (- y width) 1)]
                  [else       (sub1 (- y (random-upto (- width 2))))]))
  (define max-x (+ min-x height))
  (define max-y (+ min-y width))
  (define-values (success? poss->cells free-cells extension-points)
    (for*/fold
     ([success?         #t]
      [poss->cells       '()]
      [free-cells        '()]
      [extension-points  '()])
     ([x (in-range min-x max-x)]
      [y (in-range min-y max-y)])
      ;#:break (not success?)
      (cond
        [(not success?)
         (values success? poss->cells free-cells extension-points)]
        [success?
         (define c (and (index? x) (index? y) (grid-ref grid (vector x y))))

         (cond [(and c ; not out of bounds
                     (or (is-a? c void-cell%) ; unused yet
                         (is-a? c wall%)))    ; neighboring room, can abut
                (define p (vector (assert x index?) (assert y index?)))
                ;; tentatively add stuff
                (define x-wall? (or (= x min-x) (= x (sub1 max-x))))
                (define y-wall? (or (= y min-y) (= y (sub1 max-y))))
                (if (or x-wall? y-wall?)
                    ;; add a wall
                    (values #t ; still succeeding
                            (dict-set poss->cells p wall%)
                            free-cells
                            (if (and x-wall? y-wall?)
                                ;; don't extend from corners
                                extension-points
                                (cons p extension-points)))
                    (values #t
                            (dict-set poss->cells p empty-cell%)
                            (cons p free-cells)
                            extension-points))]
               [else ; hit something, give up
                (values #f '() '() '() )])])))
  (and success?
       (room height width poss->cells free-cells extension-points)))





(define (random-direction)
  (random-from (list left right up down)))

(define (horizontal? dir)
  (or (eq? dir right)  (eq? dir left)))

(define (vertical? dir)
  (or (eq? dir up) (eq? dir down)))

(define (new-room grid pos dir)
  ; higher than that (7 11) is hard to fit
  (define w (assert (random-between 7 11) index?)) ;; rooms 
  (define h (assert (random-between 7 11) index?))
  (let [ (r (try-add-rectangle grid pos w h dir)) ]
    ;(displayln (format "w/h: (~a ~a), room: ~a" w h r))
    r))

(define (new-corridor grid pos dir)
  (define h? (horizontal? dir))
  (define len
    ;; given map proportions (terminal window), horizontal corridors are
    ;; easier to fit
    ;; horizontal:: 3 horizontally, 6-9 vertically
    ;; vertical:: 5-7 horizontally, 3 vertically
    (assert
     (if h?
         (random-between 6 10)
         (random-between 5 8)) index?))
  (define h (if h? 3   len))
  (define w (if h? len 3))
  (let [ (r (try-add-rectangle grid pos w h dir)) ]
    ;(displayln (format "w/h: (~a ~a), corr: ~a" w h r))
    r))


(define/ctc-helper (door-count grid)
  (define height (grid-height grid))
  (define width (grid-width grid))
  (for/fold ([doors 0])
            ([row-index (in-range height)])
    ;; lltodo: test
    (+ doors
       (vector-count (curryr is-a? door%)
                     (vector-ref grid row-index)))))

(define/ctc-helper (room-count grid)
  (add1 (door-count grid)))

(define/ctc-helper ((room-count>=/c n) grid)
  (>= (room-count grid) n))



;; mutate `grid` to add `room`
(define (commit-room grid room)
  (for ([pos+cell% (in-list (room-poss->cells room))])
    (match-define (cons pos cell%) pos+cell%)
    (array-set! grid pos (new cell%))))

;; ll: temporal: this should display things IF `animate-generation?`
(define (generate-dungeon encounters)
  ;; lltodo: This could be more specific: returned grid should contain
  ;; at least (length encounters) rooms.
  ;; But this requires reverse-engineering rooms from a finished grid.
  ;;
  ;; It could potentially be checked by counting the number of times
  ;; commit-room is called (or add-room)
  ;; Or maybe by *counting the number of door cells and quartering it?*
  ;; Simple version:
  ;; ((listof exact-nonnegative-integer?) . -> .
  ;;                                      grid?)

  ;; a room for each encounter, and a few empty ones
  (define n-rooms (max (length encounters) (random-between 6 9)))
  (define grid
     (build-array (vector dungeon-height dungeon-width)
                  (lambda _ (new void-cell%))))
  (define first-room
    (let loop  ()
      (define starting-point
        (vector (assert (random dungeon-height) index?)
                (assert (random dungeon-width) index?)))
      (define first-room
        (new-room grid starting-point (random-direction)))
      (or first-room (loop)))) ; if it doesn't fit, try again
  (commit-room grid first-room)
  (when animate-generation? (display (show-grid grid)))
  (define connections '()) ; keep track of pairs of connected rooms
  (define (extension-points/room room)
    (for/list  ([e (in-list (room-extension-points room))])
      (cons e room)))
  ;; for the rest of the rooms, try sprouting a corridor, with a room at the end
  ;; try until it works
  (let loop  ()
    (define-values (n all-rooms _2)
      (for/fold
                ([n-rooms-to-go    (sub1 n-rooms)]
                 [rooms             (list first-room)]
                 [extension-points  (extension-points/room first-room)])
          ([i (in-range ITERS)])
        (cond
         ((= n-rooms-to-go 0)
          (values n-rooms-to-go rooms extension-points))
         (else
        (define (add-room origin-room room ext [corridor #f] [new-ext #f])
          (when corridor
            (commit-room grid corridor))
          (commit-room grid room)
          ;; add doors
          (define door-kind
            (if (horizontal? dir) vertical-door% horizontal-door%))
          (array-set! grid ext     (new door-kind))
          (when new-ext
            (array-set! grid new-ext (new door-kind)))
          (set! connections (cons (cons origin-room room) connections))
          (when animate-generation? (display (show-grid grid)))
          (values (sub1 n-rooms-to-go)
                  (cons room rooms) ; corridors don't count
                  (append (if corridor
                              (extension-points/room corridor)
                              '())
                          (extension-points/room room)
                          extension-points)))
        ;; pick an extension point at random
        (match-define `(,ext . ,origin-room) (random-from extension-points))
        ;; first, try branching a corridor at random
        (define dir (random-direction))
        (cond [(and (zero? (random 4)) ; maybe add a room directly, no corridor
                    (new-room grid ext dir)) =>
               (lambda (room) (add-room origin-room room ext))]
              [(new-corridor grid ext dir) =>
               (lambda (corridor)
                 ;; now try adding a room at the end
                 ;; Note: we don't commit the corridor until we know the room
                 ;;   fits. This means that `try-add-rectangle` can't check
                 ;;   whether the two collide. It so happens that, since we're
                 ;;   putting the room at the far end of the corridor (and
                 ;;   extending from it), then that can't happen. We rely on
                 ;;   that invariant.
                 (define new-ext
                   (dir ext (if (horizontal? dir)
                                (assert (sub1 (room-width corridor)) index?) ; sub1 to make abut
                                (assert (sub1 (room-height corridor)) index?))))
                 (cond [(new-room grid new-ext dir) =>
                        (lambda (room) ; worked, commit both and keep going
                          (add-room origin-room room ext corridor new-ext))]
                       [else ; didn't fit, try again
                        (values n-rooms-to-go rooms extension-points)]))]
              [else ; didn't fit, try again
               (values n-rooms-to-go rooms extension-points)])))))
    (cond [(not (= n 0)) ; we got stuck, try again
           ;(log-error "generate-dungeon: had to restart")
           ;; may have gotten too ambitious with n of rooms, back off
           (set! n-rooms (max (length encounters) (sub1 n-rooms)))
           (loop)]
          [else ; we did it
           ;; try adding more doors
           (define potential-connections
             (for*/fold
                 ([potential-connections '()])
                 ([r1 (in-list all-rooms)]
                  [r2 (in-list all-rooms)]
                  #:unless (or (eq? r1 r2)
                               (member (cons r1 r2) connections)
                               (member (cons r2 r1) connections)
                               (member (cons r2 r1) potential-connections)))
               (cons (cons r1 r2) potential-connections)))
           ;; if the two in a pair share a wall, put a door through it
           (for ([r1+r2 (in-list potential-connections)])
             (match-define (cons r1 r2) r1+r2)
             (define common
               ;(set->list
               ;  (set-intersect (list->set (room-extension-points r1))
               ;                 (list->set (room-extension-points r2)))))
                 (set-intersect (room-extension-points r1)
                                (room-extension-points r2)))
             (define possible-doors
               (filter (lambda (x) x)
                       (for/list
                                 ([pos (in-list common)])
                         (cond [(and (counts-as-free? grid (up   pos))
                                     (counts-as-free? grid (down pos)))
                                (cons pos horizontal-door%)]
                               [(and (counts-as-free? grid (left  pos))
                                     (counts-as-free? grid (right pos)))
                                (cons pos vertical-door%)]
                               [else #f]))))
             (when (not (empty? possible-doors))
               (match-define (cons pos door-kind) (random-from possible-doors))
               (array-set! grid pos (new door-kind))))
           grid])))


(define (counts-as-free? grid pos) ; i.e., player could be there
  (cond [(hash-ref free-cache pos #f) => (lambda (x) x)]
        [else
         (define c   (grid-ref grid pos))
         (define res (or (is-a? c empty-cell%) (is-a? c door%)))
         (hash-set! free-cache pos res)
         res]))

(define (hash-clear! h)
  (void))

;; wall smoothing, for aesthetic reasons
(define (smooth-walls grid)
  (for* ([x (in-range (grid-height grid))]
         [y (in-range (grid-width  grid))])
    (smooth-single-wall grid (vector (assert x index?) (assert y index?))))
  (set! wall-cache (make-hash)) ; reset caches
  (set! free-cache (make-hash))
  grid)


;; ll: not worth coming up with a specification of "smooth walls" for now. 
(define (smooth-single-wall grid pos)
  (define (wall-or-door? pos)
    (cond [(hash-ref wall-cache pos #f) => (lambda (x) x)]
          [else
           (define c   (grid-ref grid pos))
           (define res (or (is-a? c wall%) (is-a? c door%)))
           (hash-set! wall-cache pos res)
           res]))
  (when (is-a? (grid-ref grid pos) wall%)
    (define u   (wall-or-door? (up    pos)))
    (define d   (wall-or-door? (down  pos)))
    (define l   (wall-or-door? (left  pos)))
    (define r   (wall-or-door? (right pos)))
    (define fu  (delay (counts-as-free? grid (up    pos))))
    (define fd  (delay (counts-as-free? grid (down  pos))))
    (define fl  (delay (counts-as-free? grid (left  pos))))
    (define fr  (delay (counts-as-free? grid (right pos))))
    (define ful (delay (counts-as-free? grid (up    (left  pos)))))
    (define fur (delay (counts-as-free? grid (up    (right pos)))))
    (define fdl (delay (counts-as-free? grid (down  (left  pos)))))
    (define fdr (delay (counts-as-free? grid (down  (right pos)))))
    (define (2-of-3? a b c) (or (and a b #t) (and a c #t) (and b c #t)))
    (array-set!
     grid pos
     (new
      (match* ( u d l r)
        [(#F #F #F #F) pillar%]
        [(#F #F #F #T) horizontal-wall%]
        [(#F #F #T #F) horizontal-wall%]
        [(#F #F #T #T) horizontal-wall%]
        [(#F #T #F #F) vertical-wall%]
        [( #F #T #F #T) north-west-wall%]
        [( #F #T #T #F) north-east-wall%]
        ;; only have tees if enough corners are "inside"
        [( #F #T #T #T) (cond [(2-of-3? (force fu) (force fdl) (force fdr))
                               north-tee-wall%]
                              [(force fu)  horizontal-wall%]
                              [(force fdl) north-east-wall%]
                              [(force fdr) north-west-wall%]
                              [else (raise-user-error 'cond)])]
        [(#T #F #F #F) vertical-wall%]
        [(#T #F #F #T) south-west-wall%]
        [(#T #F #T #F) south-east-wall%]
        [(#T #F #T #T) (cond [(2-of-3? (force fd) (force ful) (force fur))
                              south-tee-wall%]
                             [(force fd)  horizontal-wall%]
                             [(force ful) south-east-wall%]
                             [(force fur) south-west-wall%]
                             [else (raise-user-error 'cond)])]
        [(#T #T #F #F) vertical-wall%]
        [(#T #T #F #T) (cond [(2-of-3? (force fl) (force fur) (force fdr))
                              west-tee-wall%]
                             [(force fl)  vertical-wall%]
                             [(force fur) south-west-wall%]
                             [(force fdr) north-west-wall%]
                             [else (raise-user-error 'cond)])]
        [(#T #T #T #F) (cond [(2-of-3? (force fr) (force ful) (force fdl))
                              east-tee-wall%]
                             [(force fr)  vertical-wall%]
                             [(force ful) south-east-wall%]
                             [(force fdl) north-east-wall%]
                             [else (raise-user-error 'nocd)])]
        [(#T #T #T #T) (cond ; similar to the tee cases
                         [(or (and (force ful) (force fdr))
                              (and (force fur) (force fdl)))
                          ;; if diagonals are free, need a four-corner wall
                          four-corner-wall%]
                         [(and (force ful) (force fur)) south-tee-wall%]
                         [(and (force fdl) (force fdr)) north-tee-wall%]
                         [(and (force ful) (force fdl)) east-tee-wall%]
                         [(and (force fur) (force fdr)) west-tee-wall%]
                         [(force ful)                   south-east-wall%]
                         [(force fur)                   south-west-wall%]
                         [(force fdl)                   north-east-wall%]
                         [(force fdr)                   north-west-wall%]
                         [else (raise-user-error 'cond)])]
        [(_ _ _ _) (raise-user-error 'voidcase)])))))


(define LOOPS 1)

#;(define (main)
    ;(for ((_i (in-range LOOPS)))
    (show-grid  (generate-dungeon (range N)))
  
    ;(reset!)
    ; )
    )

#;(define (main)
  (show-grid (generate-dungeon (range N))))

;(time (display (main)))
;; Change `void` to `display` to test. Should see:
;;............................................................
;;............................................................
;;............................................................
;;............................................................
;;............................................................
;;...................................╔═════╗......╔═══════╗...
;;...................................║     ║......║       ║...
;;...................................║     ║......║       ║...
;;......................╔═════╗......║     ║......║       ║...
;;......................║     ║......║     ╠══════╣       ║...
;;......................║     ╠══════╣     _      _       ║...
;;......................║     _      _     ╠══════╣       ║...
;;......................║     ╠══════╣     ║......║       ║...
;;......................║     ║......╚═════╝......║       ║...
;;......................╚═════╝...................╚═══════╝...
;;............................................................
;;............................................................
;;............................................................
;;cpu time: 8177 real time: 8175 gc time: 3379   



(module+ test
  (require rackunit)
  ;(require rackunit/text-ui)
  ;(define (render-grid g) (string-join g "\n" #:after-last "\n"))
  #;(define (empty-grid)
    (build-array #(6 6) (lambda _ (new void-cell%))))
  ;(define g1 (empty-grid))
  ;(define g2 (empty-grid))
  #;(define suite-1
    (test-suite
     "Basic Suite"
     (check-equal? (show-grid g1)
                   (render-grid '("......"
                                  "......"
                                  "......"
                                  "......"
                                  "......"
                                  "......")));)
     (check-false (try-add-rectangle g1 #(10 10) 3 3 right)) ; out of bounds
     (commit-room g1 (or (try-add-rectangle g1 #(2 1) 3 3 right) (error 'commit)))
     (check-equal? (show-grid g1)
                   (render-grid '("......"
                                  ".XXX.."
                                  ".X X.."
                                  ".XXX.."
                                  "......"
                                  "......")))
     (check-false (try-add-rectangle g1 #(2 2) 3 3 up))
     (commit-room g1 (or (try-add-rectangle g1 #(3 3) 3 3 down) (error 'commit)))
     (check-equal? (show-grid g1)
                   (render-grid '("......"
                                  ".XXX.."
                                  ".X X.."
                                  ".XXXX."
                                  "..X X."
                                  "..XXX.")))
                
     (commit-room g2 (or (try-add-rectangle g2 #(1 1) 3 4 right) (error 'commit)))
     (check-equal? (show-grid g2)
                   (render-grid '(".XXXX."
                                  ".X  X."
                                  ".XXXX."
                                  "......"
                                  "......"
                                  "......"))) ))
  
  ;; ============================================================================================
  ;; random testing


  (define room_count (box 0))
  (define corridor_count (box 0))
  (define door_count (box 0))
  (define room-boundaries (box '()))

  (define (room-budding-detecting rooms-bounds)
    (printf "")
    (define it 0)
    (for* ([loc rooms-bounds]
           ;[]
           ;[]
           ;[]
           ;[]
           ;[]
           )
      (printf "")
      )
    )
  (define (room-budding-detection pos1 pos2)
    (match-define (vector x1 y1) pos1)
    (match-define (vector x2 y2) pos2)
    (define indi #f)
    (for* ([i (in-range x1 (+ x2 1))]
           [j (in-range y1 (+ y2 1))]
           [curr-room (unbox room-boundaries)]
           [k (in-range (vector-ref (first curr-room) 0) (+ (vector-ref (last curr-room) 0) 1))]
           [l (in-range (vector-ref (first curr-room) 1) (+ (vector-ref (last curr-room) 1) 1))])
      (cond [(and (equal? i k)
                  (equal? j l))
             (set! indi #t)]))
    (cond [(not indi)
           (error "This room is not being added to a place that is connected to the dungeon environment!")])
    )

  ;; mutate `grid` to add `room`
  (define (commit-room1 grid room)
    (match-define (cons pos1 cell1%) (first (room-poss->cells room)))
    (match-define (cons pos2 cell2%) (last (room-poss->cells room)))
    (cond [(< 0 (length (unbox room-boundaries)))
           (room-budding-detection pos1 pos2)])
    (set-box! room-boundaries (cons (list pos1 pos2) (unbox room-boundaries)))
    (for ([pos+cell% (in-list (room-poss->cells room))])
      (match-define (cons pos cell%) pos+cell%)
      (grid-replace-checks grid pos cell%)
      (array-set! grid pos (new cell%))))
  ;; ============================================================================================  
  (define (room-counter grid rooms-bounds)
    (for/fold ([count 0]) ([i rooms-bounds])
      (match-define (vector x1 y1) (first i))
      (match-define (vector x2 y2) (second i))
      (cond [(<= 36 (* (- x2 x1) (- y2 y1))) (+ count 1)]
            [else (+ count 0)])))
  ;; ============================================================================================  
  (define (corridor-counter-backup grid rooms-bounds)
    (for/fold ([count 0]) ([i rooms-bounds])
      (match-define (vector x1 y1) (first i))
      (match-define (vector x2 y2) (second i))
      (cond [(> 36 (* (- x2 x1) (- y2 y1))) (+ count 1)]
            [else (+ count 0)])))
  ;; ============================================================================================  
  (define (corridor_helper grid-split index-lst curr-index counted num-pairs)
    (define num_pairs (- (length index-lst) 1))
    (cond [(< num_pairs 1)
           counted]
          [else
           (define front (list-ref index-lst 0))
           (define back (list-ref index-lst 1))
           (cond
             [(>= (- back front) 3) 
              (corridor_helper grid-split (rest index-lst) curr-index counted (- num-pairs 1))]
             [(and
               (equal? (vector-ref (vector-ref grid-split (+ curr-index 1)) front) (new wall%))
               (equal? (vector-ref (vector-ref grid-split (- curr-index 1)) front) (new wall%))
               (or (equal? (vector-ref (vector-ref grid-split (+ curr-index 1)) (+ front 1)) (new wall%))
                   (equal? (vector-ref (vector-ref grid-split (+ curr-index 1)) (+ front 1)) (new empty-cell%))
                   (equal? (vector-ref (vector-ref grid-split (+ curr-index 1)) (+ front 1)) (new horizontal-door%)))
               (or (equal? (vector-ref (vector-ref grid-split (- curr-index 1)) (+ front 1)) (new wall%))
                   (equal? (vector-ref (vector-ref grid-split (- curr-index 1)) (+ front 1)) (new empty-cell%))
                   (equal? (vector-ref (vector-ref grid-split (- curr-index 1)) (+ front 1)) (new horizontal-door%)))
               (equal? (vector-ref (vector-ref grid-split curr-index) (+ front 1)) (new empty-cell%))
               (equal? (vector-ref (vector-ref grid-split (- curr-index 1)) (+ front 2)) (new wall%))
               (equal? (vector-ref (vector-ref grid-split (+ curr-index 1)) (+ front 2)) (new wall%)))     
              (set! counted (+ counted 1))
              (corridor_helper grid-split (rest index-lst) curr-index counted (- num-pairs 1))]
             [else (corridor_helper grid-split (rest index-lst) curr-index counted (- num-pairs 1))])]))

  (define (corridor-counter grid)
    (define curr-index 0)
    (define count 0)
    (define index1 0)
    (define vert-lst '())
    (for ([line grid])
      (define index-lst '())
      (define index2 0)
      (for ([i line]) 
        (cond [(equal? i (new vertical-door%)) 
               (set! index-lst (cons index2 index-lst))]
              [(equal? i (new horizontal-door%))
               (set! vert-lst (cons (list index1 index2) vert-lst))])
        (set! index2 (+ index2 1)))
      (set! index-lst (reverse index-lst))
      (cond [(< 1 (length index-lst)) 
             (set! count (+ count (corridor_helper grid index-lst curr-index 0 (- (length index-lst) 1))))])
      (set! curr-index (+ curr-index 1))
      (set! index1 (+ 1 index1)))
    (set! vert-lst (reverse vert-lst))
    (for ([loc vert-lst])
      (match-define (list x1 y1) loc)
      (for ([i (rest vert-lst)])
        (unless (equal? i loc)
          (match-define (list x2 y2) i)
          (cond
            [(and
              (and (equal? y1 y2) (< (- x2 x1) 3) (not (<= (- x2 x1) 0)))
              (equal? (vector-ref (vector-ref grid (+ x1 0)) (- y1 1)) (new wall%))
              (equal? (vector-ref (vector-ref grid (+ x1 0)) (+ y1 1)) (new wall%))
              (or
               (equal? (vector-ref (vector-ref grid (+ x1 1)) (- y1 1)) (new wall%))
               (equal? (vector-ref (vector-ref grid (+ x1 1)) (- y1 1)) (new vertical-door%))
               (equal? (vector-ref (vector-ref grid (+ x1 1)) (- y1 1)) (new empty-cell%)))
              (or
               (equal? (vector-ref (vector-ref grid (+ x1 1)) (+ y1 1)) (new wall%))
               (equal? (vector-ref (vector-ref grid (+ x1 1)) (+ y1 1)) (new vertical-door%))
               (equal? (vector-ref (vector-ref grid (+ x1 1)) (+ y1 1)) (new empty-cell%)))
              (equal? (vector-ref (vector-ref grid (+ x1 1)) y1) (new empty-cell%))
              (equal? (vector-ref (vector-ref grid (+ x1 2)) (+ y1 1)) (new wall%))
              (equal? (vector-ref (vector-ref grid (+ x1 2)) (- y1 1)) (new wall%)))
             (set! count (+ count 1))]))))
    count)
  ;; ============================================================================================
  (define (x-depth grid x-pos y-pos)
    ;(printf "x-pos: ~a\n" x-pos)
    (cond
      [(and
        (equal? (grid-ref grid (vector (+ 1 x-pos) y-pos)) (new wall%))
        (or (equal? (grid-ref grid (vector (+ 1 x-pos) (+ y-pos 1))) (new wall%))
            (equal? (grid-ref grid (vector (+ 1 x-pos) (+ y-pos 1))) (new horizontal-door%))))
       (+ 1 x-pos)]
      [(or
        (equal? (grid-ref grid (vector (+ 1 x-pos) y-pos)) (new vertical-door%))
        (equal? (grid-ref grid (vector (+ 1 x-pos) y-pos)) (new wall%)))
       (x-depth grid (+ x-pos 1) y-pos)
       ]
      [else
       x-pos]))
  ;; ============================================================================================
  (define (y-depth grid x-pos y-pos)
    ;(printf "y-pos: ~a\n" y-pos)
    (cond
      [(and
        (equal? (grid-ref grid (vector  x-pos (+ 1 y-pos))) (new wall%))
        (or
         (equal? (grid-ref grid (vector (+ 1 x-pos) (+ y-pos 1))) (new vertical-door%))
         (equal? (grid-ref grid (vector (+ 1 x-pos) (+ y-pos 1))) (new wall%))))
       (+ 1 y-pos)]
      [(or
        (equal? (grid-ref grid (vector x-pos (+ 1 y-pos))) (new wall%))
        (equal? (grid-ref grid (vector x-pos (+ 1 y-pos))) (new horizontal-door%)))
       (y-depth grid x-pos (+ 1 y-pos))
       ] 
      [else
       y-pos]))
  ;; ============================================================================================
  (define (room&corridor-counter-contd grid)
    ;(define counted-areas 0)
    (define areas '())
    (for ([i (in-range (- (vector-length grid) 2))])
      (for ([j (in-range (- (vector-length (vector-ref grid i)) 2))])
        (cond [(and
                (equal? (new wall%)(grid-ref grid (vector (- i 1) (- j 1))))
                (or (equal? (new wall%)(grid-ref grid (vector (- i 1) j)))
                    (equal? (new horizontal-door%)(grid-ref grid (vector (- i 1) j))))
                
                (or (equal? (new vertical-door%) (grid-ref grid (vector i (- j 1))))
                    (equal? (new wall%)(grid-ref grid (vector i (- j 1)))))
                
                (equal? (new empty-cell%)(grid-ref grid (vector i j))))
               (define offic-x (- i 1))
               (define offic-y (- j 1))
               (define back-x (x-depth grid offic-x offic-y))
               (define back-y (y-depth grid offic-x offic-y))
               (set! areas (cons (list (vector offic-x offic-y) (vector back-x back-y)) areas))])))
    areas)
  ;; ============================================================================================  
  (define (door-counter grid)
    (for/fold ([total 0]) ([line grid])
      (+ total
         (for/fold ([sub-total 0]) ([i line])
           (cond [(or (equal? i (new horizontal-door%))
                      (equal? i (new vertical-door%)))
                  (+ sub-total 1)]
                 [else
                  (+ 0 sub-total)])))))
  ;; ============================================================================================  
  (define (is-all-empty? grid1 rooms-bounds)
    ;(printf "\n")
    ;(display (show-grid grid1))
    ;(printf "\n")
    (define indi #t)
    (for ([loc rooms-bounds])
      ;(printf "printing loc: ~a\n" loc)
      (match-define (list (vector x1 y1) (vector x2 y2)) loc)
      (for ([i (in-range (+ x1 1) x2)])
        ;(printf "printing i: ~a\n" i)
        (for ([j (in-range (+ y1 1) y2)])
          ;(printf "printing i ~a j: ~a\n" i j)
          ;(printf "printing grid cell: ~a\n" (grid-ref grid1 (vector i j))) 
          (cond [(not (equal? (new empty-cell%) (grid-ref grid1 (vector i j)))) 
                 (set! indi #f)])
          )      
        )
      )
    indi
    )
  ;; ============================================================================================  
  ;; grid-replace-checks: takes a replacement cell, and tests whether if can be place over the existing cell
  (define (grid-replace-checks grid pos cell)
    (define curr-cell (grid-ref grid pos))
    (match-define (vector x y) pos)
    (cond
      [(equal? cell (new empty-cell%))
       (when
           (not
            (equal? curr-cell (new void-cell%)))
         (error "Not a valid placement for an empty-cell!\n")
         )]
      [(equal? cell (new wall%))
       ;; every value is true except false, rack-unit, test suite, negative tests, expecting error from tests, tells you how many succeed and failed, test/error, groups of tests to run 
       (when
           (not
            (or 
             (equal? curr-cell (new wall%))
             (equal? curr-cell (new void-cell%))))
         (error "Not a valid placement for a wall!\n")
         )] 
      [(equal? cell (new vertical-door%))
       (when
           (not
            (and
             (equal? curr-cell (new wall%))
             (equal? (grid-ref grid (vector (+ x 1) y)) (new wall%))
             (equal? (grid-ref grid (vector (- x 1) y)) (new wall%))
             (equal? (grid-ref grid (vector x (+ y 1))) (new empty-cell%)) 
             (equal? (grid-ref grid (vector x (- y 1))) (new empty-cell%))))
         (error "Not a valid placement for a vertical-door!\n"))] 
      [(equal? cell (new horizontal-door%))
       (when
           (not
            (and
             (equal? curr-cell (new wall%))
             (equal? (grid-ref grid (vector x (+ y 1))) (new wall%))
             (equal? (grid-ref grid (vector x (- y 1))) (new wall%))
             (equal? (grid-ref grid (vector (+ x 1) y)) (new empty-cell%)) 
             (equal? (grid-ref grid (vector (- x 1) y)) (new empty-cell%))))
         (error "not a valid placement for a horizontal door!\n"))]))
  ;; ============================================================================================  
  (define (is-between? pos-lst indicator) ;; determine how to have no return
    (cond
      [(empty? pos-lst) indicator]
      [(empty? (rest pos-lst)) indicator]
      [else 
       (match-define (vector x1 y1) (first (first pos-lst)))
       (match-define (vector x2 y2) (last (first pos-lst)))
       (for ([remain (rest pos-lst)])
         (match-define (vector x-start y-start) (first remain))
         (match-define (vector x-end y-end) (last remain))
         (cond
           [(or
             (and
              (or
               (and
                (< x1 x-start)
                (< x-start x2)) 
               (and
                (< x1 x-end)
                (< x-end x2)))
              (or
               (and
                (< y1 y-start)
                (< y-start y2))
               (and
                (< y1 y-start)
                (< y-end y2))))
             (and
              (or
               (and
                (< x-start x1)
                (< x1 x-end))
               (and
                (< x-start x2)
                (< x2 x-end)))
              (or
               (and
                (< y-start y1)
                (< y1 y-end))
               (and
                (< y-start y2)
                (< y2 y-end)))))
            (error "This grid is not set up correctly! There are rooms that overlap/intersect\n")]
           [(and
             (equal? y1 y-start)
             (equal? y2 y-end)
             (and 
              (or
               (and
                (< x1 x-start)
                (< x-start x2))
               (and
                (< x1 x-end)
                (< x-end x2))
               )
              (or
               (and
                (< x-start x1)
                (< x1 x-end))
               (and
                (< x-start x2)
                (< x2 x-end)))))
            (error "This grid is not set up correctly! There are rooms that overlap/intersect\n")]
           [(and
             (equal? x1 x-start)
             (equal? x2 x-end)
             (and 
              (or
               (and
                (< y1 y-start)
                (< y-start y2))
               (and
                (< y1 y-end)
                (< y-end y2))
               )
              (or
               (and
                (< y-start y1)
                (< y1 y-end))
               (and
                (< y-start y2)
                (< y2 y-end)))))
            (error "This grid is not set up correctly! There are rooms that overlap/intersect\n")]
           [else
            (is-between? (rest pos-lst) indicator)]))])
    indicator)
  ;; ============================================================================================  

  (define (share-sublists? lst1 lst2)
    (ormap (λ (x) (member x lst1)) lst2))
  ;; ============================================================================================  
  (define (room-connection-seeker grid rooms-bounds)
    ;(define indexs (build-list (length rooms-bounds) (lambda (i) i)))
    (define matrix
      (for/vector ([i (in-range (length rooms-bounds))])
        (make-vector (length rooms-bounds) #f)))
    (define a-m matrix)
    ;(printf "matrix: ~a\n" a-m)
    (for ([i (in-range (length rooms-bounds))])
      (for ([j (in-range (length rooms-bounds))])
        (unless (equal? i j)
          ;(printf "room1: ~a\nroom2: ~a\n" (list-ref rooms-bounds i) (list-ref rooms-bounds j))
          (define i-doors (door-finder grid (list-ref rooms-bounds i)))
          ;(printf "i-doors: ~a\n" i-doors)
          (define j-doors (door-finder grid (list-ref rooms-bounds j)))
          ;(printf "j-doors: ~a\n" j-doors)
          (cond [(share-sublists? i-doors j-doors)
                 ;(printf "found a connection\n")
                 (vector-set! (vector-ref a-m i) j 1)
                 #;(printf "matrix: ~a\n" a-m)]) 
          )
        )
      )
    ;(printf "rooms-bounds: ~a\n" rooms-bounds)
    ;(printf "matrix: ~a\n" a-m)
    (define reached (make-vector (length rooms-bounds) #f))
    (define (visit pos)
      (vector-set! reached pos #t)
      (for ([i (in-range (length rooms-bounds))])
        (cond [(and (not (vector-ref reached i))
                    (equal? (vector-ref (vector-ref a-m pos) i) 1))
               (visit i)])
        )
      )
    
    (visit 0)
    ;(printf "reached: ~a\n" reached)
    (for/and ([v (in-vector reached)])
      v)
    )
  ;; ============================================================================================
  (define (door-finder grid poses)
    ;(printf "in door finder \n")
    (match-define (list (vector x1 y1) (vector x2 y2)) poses)
    ;(printf "x1: ~a\n" x1)
    ;(printf "x2: ~a\n" x2)
    ;(printf "y1: ~a\n" y1)
    ;(printf "y2: ~a\n" y2)
    (define door-poses '())
    (for ([i (in-range y1 y2)])
      ;(printf "checking cell at (~a, ~a): ~a\n" x1 i (grid-ref grid (vector x1 i)))
      ;(printf "checking cell at (~a, ~a): ~a\n" x2 i (grid-ref grid (vector x2 i)))
      (cond [
             (equal? (new horizontal-door%) (grid-ref grid (vector x1 i)))
              
             ;(printf "found a door \n")
             (set! door-poses (cons (list x1 i) door-poses))
             #;(printf "updated door-poses: ~a\n" door-poses)])
      (cond 
        [
         (equal? (new horizontal-door%) (grid-ref grid (vector x2 i)))
              
         ;(printf "found a door: \n")
         (set! door-poses (cons (list x2 i) door-poses))
         #;(printf "updated door-poses: ~a\n" door-poses)])
      )
      
    (for ([i (in-range x1 x2)])
      ;(printf "checking cell at (~a, ~a): ~a\n" i y1 (grid-ref grid (vector i y1)))
      ;(printf "checking cell at (~a, ~a): ~a\n" i y2 (grid-ref grid (vector i y2)))
      (cond [
             (equal? (new vertical-door%) (grid-ref grid (vector i y1)))
              
             ;(printf "found a door: \n")
             (set! door-poses (cons (list i y1) door-poses))
             #;(printf "updated door-poses: ~a\n" door-poses)])
      (cond  [(equal? (new vertical-door%) (grid-ref grid (vector i y2)))
              ;(printf "found a door: \n")
              (set! door-poses (cons (list i y2) door-poses))
              #;(printf "updated door-poses: ~a\n" door-poses)])
      )
    ;(printf "updated door-poses: ~a\n" door-poses)
    door-poses
    )
  ;; ============================================================================================  
  ;; ll: temporal: this should display things IF `animate-generation?`
  (define (generate-dungeon-loc encounters)
    ;; lltodo: This could be more specific: returned grid should contain
    ;; at least (length encounters) rooms.
    ;; But this requires reverse-engineering rooms from a finished grid.
    ;;
    ;; It could potentially be checked by counting the number of times
    ;; commit-room is called (or add-room)
    ;; Or maybe by *counting the number of door cells and quartering it?*
    ;; Simple version:
    ;; ((listof exact-nonnegative-integer?) . -> .
    ;;                                      grid?)

    ;; a room for each encounter, and a few empty ones 
    ;;
    ;(printf "encounters: ~a\n" encounters)
    ;(printf "length of encounters: ~a\n" (length encounters))
    (define n-rooms (max (length encounters) (random-between 6 9)))
    (set-box! corridor_count 0)
    (set-box! door_count 0)
    (set-box! room_count 0)
    (set-box! room-boundaries '())
  
    (define grid
      (build-array (vector dungeon-height dungeon-width)
                   (lambda _ (new void-cell%)))) ;; new cell created : call to void-cell%
  
    (define first-room
      (let loop  ()
        (define starting-point
          (vector (assert (random-upto dungeon-height) index?)
                  (assert (random-upto dungeon-width) index?)))
        (define first-room
          (new-room grid starting-point (random-direction)))
        (or first-room (loop)))) ; if it doesn't fit, try again
    (commit-room1 grid first-room)
    (set-box! room_count (+ 1 (unbox room_count)))
    (cond [(not (equal? (unbox room_count) (room-counter grid (unbox room-boundaries))))
           (error "The room count does not match what is currently in the grid!\n")])
    (when animate-generation? (display (show-grid grid)))
    (define connections '()) ; keep track of pairs of connected rooms
    (define (extension-points/room room)
      (for/list  ([e (in-list (room-extension-points room))])
        (cons e room)))
    ;; for the rest of the rooms, try sprouting a corridor, with a room at the end
    ;; try until it works
    (let loop  ()
      (define-values (n all-rooms _2)
        (for/fold
         ([n-rooms-to-go    (sub1 n-rooms)]
          [rooms             (list first-room)]
          [extension-points  (extension-points/room first-room)])
         ([i (in-range ITERS)])
          (cond
            ((= n-rooms-to-go 0)
             (values n-rooms-to-go rooms extension-points))
            (else
             (define (add-room origin-room room ext [corridor #f] [new-ext #f])
               (when corridor 
                 (commit-room1 grid corridor)
                 (define a (is-between? (unbox room-boundaries) #t))
                 (set-box! corridor_count (+ 1 (unbox corridor_count))))
               (commit-room1 grid room)
               (define b (is-between? (unbox room-boundaries) #t))
               (set-box! room_count (+ 1 (unbox room_count)))
               (cond [(not (equal? (unbox room_count) (room-counter grid (unbox room-boundaries))))
                      (error "The room count does not match what is currently in the grid!\n")])
               (define door-kind
                 (if (horizontal? dir) vertical-door% horizontal-door%))
               (array-set! grid ext     (new door-kind))
               (set-box! door_count (+ 1 (unbox door_count)))
               (cond [(not (equal? (unbox door_count) (door-counter grid)))
                      (error "The door count does not match what is currently in the grid!\n")])
               (when new-ext
                 (array-set! grid new-ext (new door-kind))
                 (set-box! door_count (+ 1 (unbox door_count))))
               (cond [(not (equal? (unbox door_count) (door-counter grid)))
                      (error "The door count does not match what is currently in the grid!\n")])
               (cond [(not (and (equal? (unbox corridor_count) (corridor-counter grid))
                                (equal? (unbox corridor_count) (corridor-counter-backup grid (unbox room-boundaries)))))
                      (error "The corridor count does not match what is currently in the grid!\n")])
               (cond [(not (equal? (unbox room_count) (room-counter grid (unbox room-boundaries))))
                      (error "The room count does not match what is currently in the grid!\n")])
               (cond [(not (equal? #t (room-connection-seeker grid (unbox room-boundaries))))
                    (error "The rooms and or corridors are not boarding eachother!\n")])
               ;(define a1 (room-connection-detector grid (unbox room-boundaries)))
               (define c (is-between? (unbox room-boundaries) #t))
               (set! connections (cons (cons origin-room room) connections))
               (when animate-generation? (display (show-grid grid)))
               (values (sub1 n-rooms-to-go)
                       (cons room rooms) ; corridors don't count
                       (append (if corridor
                                   (extension-points/room corridor)
                                   '())
                               (extension-points/room room)
                               extension-points)))
             ;; pick an extension point at random
             (match-define `(,ext . ,origin-room) (random-from extension-points))
             ;; first, try branching a corridor at random
             (define dir (random-direction))
             (cond [(and (zero? (random-upto 4)) ; maybe add a room directly, no corridor
                         (new-room grid ext dir)) =>
                                                  (lambda (room) (add-room origin-room room ext))]
                   [(new-corridor grid ext dir) =>
                                                (lambda (corridor)
                                                  ;; now try adding a room at the end
                                                  ;; Note: we don't commit the corridor until we know the room
                                                  ;;   fits. This means that `try-add-rectangle` can't check
                                                  ;;   whether the two collide. It so happens that, since we're
                                                  ;;   putting the room at the far end of the corridor (and
                                                  ;;   extending from it), then that can't happen. We rely on
                                                  ;;   that invariant.
                                                  (define new-ext
                                                    (dir ext (if (horizontal? dir)
                                                                 (assert (sub1 (room-width corridor)) index?) ; sub1 to make abut
                                                                 (assert (sub1 (room-height corridor)) index?))))
                                                  (cond [(new-room grid new-ext dir) =>
                                                                                     (lambda (room) ; worked, commit both and keep going
                                                                                       (add-room origin-room room ext corridor new-ext))]
                                                        [else ; didn't fit, try again
                                                         (values n-rooms-to-go rooms extension-points)]))]
                   [else ; didn't fit, try again
                    (values n-rooms-to-go rooms extension-points)])))))
      (cond [(not (= n 0)) ; we got stuck, try again 
             ;(log-error "generate-dungeon: had to restart")
             ;; may have gotten too ambitious with n of rooms, back off
             (set! n-rooms (max (length encounters) (sub1 n-rooms)))
             (loop)]
            [else ; we did it
             ;; try adding more doors
             (define potential-connections
               (for*/fold
                ([potential-connections '()])
                ([r1 (in-list all-rooms)]
                 [r2 (in-list all-rooms)]
                 #:unless (or (eq? r1 r2)
                              (member (cons r1 r2) connections)
                              (member (cons r2 r1) connections)
                              (member (cons r2 r1) potential-connections)))
                 (cons (cons r1 r2) potential-connections)))
             ;; if the two in a pair share a wall, put a door through it
             (for ([r1+r2 (in-list potential-connections)])
               (match-define (cons r1 r2) r1+r2)
               (define common
                 ;(set->list
                 ;  (set-intersect (list->set (room-extension-points r1))
                 ;                 (list->set (room-extension-points r2)))))
                 (set-intersect (room-extension-points r1)
                                (room-extension-points r2)))
               (define possible-doors
                 (filter (lambda (x) x)
                         (for/list
                             ([pos (in-list common)])
                           (cond [(and (counts-as-free? grid (up   pos))
                                       (counts-as-free? grid (down pos)))
                                  (cons pos horizontal-door%)]
                                 [(and (counts-as-free? grid (left  pos))
                                       (counts-as-free? grid (right pos)))
                                  (cons pos vertical-door%)]
                                 [else #f]))))
               (when (not (empty? possible-doors))
                 (match-define (cons pos door-kind) (random-from possible-doors))
                 (array-set! grid pos (new door-kind))
                 (set-box! door_count (+ 1 (unbox door_count)))
                 (cond [(not (equal? (unbox door_count) (door-counter grid)))
                        (error "The door count does not match what is currently in the grid!\n")])))
             (cond [(not (equal? (unbox door_count) (door-counter grid)))
                    (error "The door count does not match what is currently in the grid!\n" )])
             (cond [(not (equal? (unbox corridor_count) (corridor-counter grid)))
                    (error "The corridor count does not match what is currently in the grid!\n")])
             (cond [(not (equal? (unbox room_count) (room-counter grid (unbox room-boundaries))))
                    (error "The room count does not match what is currently in the grid!\n")])
             (cond [(not (equal? #t (room-connection-seeker grid (unbox room-boundaries))))
                    (error "The rooms and or corridors are not boarding eachother!\n")])
             ;(define a55 (room-connection-detector grid (unbox room-boundaries)))
             (define c55 (is-between? (unbox room-boundaries) #t))
             grid])))

  (define suite-6
    (test-suite "Real Generate Dungeon Testing Suite"
                (for ([i (in-range 1)])
                  (define grid-real (generate-dungeon (range N)))
                  (display (show-grid grid-real))
                  ;(printf "\n")
                  (define room-corridor-lst (room&corridor-counter-contd grid-real))
                  (define corridor1-out (corridor-counter-backup grid-real room-corridor-lst))
                  (define corridor2-out (corridor-counter grid-real))
                  (define door-out (door-counter grid-real)) 
                  (define room-out (room-counter grid-real room-corridor-lst))
                  
                  (check-true (is-between? room-corridor-lst #t))
                  (check-equal? corridor1-out corridor2-out)
                  (check-equal? (length room-corridor-lst) (+ room-out corridor2-out))
                  (check-equal? (length room-corridor-lst) (+ room-out corridor1-out))
                  (check-true (room-connection-seeker grid-real room-corridor-lst))
                  (cond [(equal? 1 (- room-out
                                      corridor1-out))
                         (check-equal? door-out (* 2 corridor1-out))])
                  (cond [(< 1 room-out)
                         ;(printf "p1: ~a\n" (<= 1 door-out))
                         #;(printf "p2: ~a\n" (<= door-out
                                                  (* 2 (- room-out 1))))
                         (check-true (and
                                      (<= 1 door-out)
                                      (<= door-out
                                          (* 2 (- room-out 1)))))]
                        [else
                         (check-equal? door-out 0)])
                  ;(printf "output 3: ~a\n" (is-all-empty? grid-real room-corridor-lst))
                  (check-true (is-all-empty? grid-real room-corridor-lst))
                  
                  )))
  (define suite-2
    (test-suite "Randomized Testing Suite"
                (for ([i (in-range 1)])
                  (define gridout (generate-dungeon-loc (range N)))
                  (display (show-grid gridout))
                  (define room-count (unbox room_count))
                  (define corridor-count (unbox corridor_count))
                  (define door-count (unbox door_count))
                  (define room+corridorattempt (room&corridor-counter-contd gridout))
                  (check-equal? corridor-count (corridor-counter-backup gridout room+corridorattempt))
                  (check-equal? (length room+corridorattempt) (+ room-count corridor-count))
                  (check-true (room-connection-seeker gridout room+corridorattempt))
                  ;(printf "room+corridor attempt counter: ~a\n" room+corridorattempt)
                  ;(printf "number of rooms and corridors from attempt: ~a\n" (length room+corridorattempt))
                  ;(printf "expected room-count: ~a\n" room-count)
                  ;(printf "expected door-count: ~a\n" door-count)
                  ;(printf "expected corridor-count: ~a\n" corridor-count)
                  ;(printf "actual room-count: ~a\n" (room-counter gridout (unbox room-boundaries)))
                  ;(printf "actual door-count: ~a\n" (door-counter gridout))
                  ;(printf "actual corridor-count: ~a\n" (corridor-counter gridout))
                  (check-equal? (length room+corridorattempt) (+ room-count corridor-count))
                  (check-equal? door-count (door-counter gridout))
                  (check-equal? corridor-count (corridor-counter gridout))
                  (check-equal? corridor-count (corridor-counter-backup gridout (unbox room-boundaries)))
                  (check-equal? room-count (room-counter gridout (unbox room-boundaries)))
                  (check-equal? (is-between? (unbox room-boundaries) #t) #t)
                  (check-equal? (is-between? room+corridorattempt #t) #t)
                  #;(check-equal? (room-connection-detector gridout (unbox room-boundaries)) #t))))
  ;; ============================================================================================
  ;; door -- corridor -- room calculation test demostration
  ;; Counting doors, corridors, & rooms works the use of variables and helper functions
  ;; In this testing suite's generate_dungeon, I include variables whose purpose is the count the number of times a room, etc is added
  ;; We also have helper functions, one each for doors, corridors, and rooms, that takes an output grid and determines how many of each exist in a given environment
  ;; These two process are used as for a comparison; as we tally the number of rooms, etc, we check that this number is reflected correctly on the grid
  #;(define grid0 (vector
                ;; Row 0
                (vector (new void-cell%) (new void-cell%) (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)
                        (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 1
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new void-cell%)
                        (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 2
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)
                        (new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%))
                ;; Row 3
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new wall%)
                        (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 4
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new empty-cell%)
                        (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 5
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new empty-cell%)
                        (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 6
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new empty-cell%)
                        (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 7
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new vertical-door%)(new empty-cell%)
                        (new vertical-door%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 8
                (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new wall%)(new wall%)(new wall%)(new horizontal-door%)(new wall%)(new wall%)(new wall%)(new wall%)(new empty-cell%)
                        (new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                ;; Row 9
                (vector 
                 (new void-cell%) (new void-cell%)(new void-cell%) (new void-cell%) (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%) 
                 (new wall%) (new void-cell%) (new void-cell%) (new wall%) (new empty-cell%) (new wall%) (new void-cell%) 
                 (new void-cell%) (new void-cell%) (new void-cell%) (new void-cell%) (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%) (new void-cell%) (new void-cell%))
                ;; Row 10
                (vector 
                 (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new horizontal-door%) 
                 (new wall%) (new void-cell%) (new void-cell%) (new wall%) (new wall%) (new wall%) (new  void-cell%) (new  void-cell%) 
                 (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 11
                (vector
                 (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                 (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 12
                (vector
                 (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                 (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 13
                (vector
                 (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                 (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 14
                (vector
                 (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                 (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 15
                (vector
                 (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                 (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%)(new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 16
                (vector
                 (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                 (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                ;; Row 17
                (vector
                 (new wall%) (new wall%) (new wall%) (new wall%) 
                 (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                 )))
  
 #; (define grid1 (vector
                 ;; Row 0
                 (vector (new void-cell%) (new void-cell%) (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)
                         (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 1
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new void-cell%)
                         (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 2
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)
                         (new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%))
                 ;; Row 3
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new wall%)
                         (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new  void-cell%)(new  void-cell%)(new  void-cell%))
                 ;; Row 4
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new empty-cell%)
                         (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 5
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new empty-cell%)
                         (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 6
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new empty-cell%)
                         (new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 7
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new vertical-door%)(new empty-cell%)
                         (new vertical-door%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new empty-cell%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 8
                 (vector (new void-cell%)(new void-cell%)(new void-cell%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new empty-cell%)
                         (new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new wall%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%))
                 ;; Row 9
                 (vector 
                  (new void-cell%) (new void-cell%)(new void-cell%) (new void-cell%) (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%) 
                  (new wall%) (new void-cell%) (new void-cell%) (new wall%) (new empty-cell%) (new wall%) (new void-cell%) 
                  (new void-cell%) (new void-cell%) (new void-cell%) (new void-cell%) (new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%)(new void-cell%) (new void-cell%) (new void-cell%))
                 ;; Row 10
                 (vector 
                  (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) 
                  (new wall%) (new void-cell%) (new void-cell%) (new wall%) (new wall%) (new wall%) (new  void-cell%) (new  void-cell%) 
                  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 11
                 (vector
                  (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                  (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 12
                 (vector
                  (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                  (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                  (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 13
                 (vector
                  (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                  (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 14
                 (vector
                  (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                  (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 15
                 (vector
                  (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                  (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%)(new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 16
                 (vector
                  (new wall%) (new empty-cell%) (new empty-cell%) (new empty-cell%)
                  (new empty-cell%) (new empty-cell%) (new empty-cell%) (new empty-cell%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))
                 ;; Row 17
                 (vector
                  (new wall%) (new wall%) (new wall%) (new wall%) 
                  (new wall%) (new wall%) (new wall%) (new wall%) (new wall%) (new  void-cell%) (new  void-cell%) (new  void-cell%)
                  (new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%)(new  void-cell%)(new  void-cell%) (new  void-cell%) (new  void-cell%) (new  void-cell%))))
  #;(define suite-3
    (test-suite "Door-Corridor-Room Suite"
                (set-box! room-boundaries '( (#(1 3) #(8 11)) (#(10 0) #(17 8)) (#(8 4) #(10 8)) (#(2 13) #(8 21)) (#(3 11) #(10 13))))
                (check-equal? 4 (door-counter grid0))
                (check-equal? 2 (corridor-counter grid0))
                (check-equal? 3 (room-counter grid0 (unbox room-boundaries)))
                ;(check-equal? #t (room-connection-detector grid (unbox room-boundaries)))
                (check-equal? 2 (door-counter grid1))
                (check-equal? 1 (corridor-counter grid1))
                (check-equal? 3 (room-counter grid1 (unbox room-boundaries)))
                #;(check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "This room is not connected to the bigger dungeon!")))
                 (λ ()
                   (room-connection-detector grid1 (unbox room-boundaries))))
                (set-box! room-boundaries  '())))
  
  ;; ============================================================================================
  ;; grid-replace-checks/object-replacement test demostration 
  #;(define grid-ex1
    (build-array (vector dungeon-height dungeon-width)
                 (lambda _ (new void-cell%))))
  #;(define suite-4
    (test-suite "Grid-Replacement Suite"
                (check-equal? (for ([i (in-range 6)])
                                (for ([j (in-range 6)])
                                  (cond [(or (equal? i 0) (equal? i 5))
                                         (grid-replace-checks grid-ex1 (vector (+ i 2) (+ j 2)) (new wall%))
                                         (array-set! grid-ex1 (vector (+ i 2) (+ j 2)) (new wall%))]
                                        [(or (equal? j 0) (equal? j 5))
                                         (grid-replace-checks grid-ex1 (vector (+ i 2) (+ j 2)) (new wall%))
                                         (array-set! grid-ex1 (vector (+ i 2) (+ j 2)) (new wall%))]
                                        [else
                                         (grid-replace-checks grid-ex1 (vector (+ i 2) (+ j 2)) (new empty-cell%))
                                         (array-set! grid-ex1 (vector (+ i 2) (+ j 2)) (new empty-cell%))
                                         ])))
                              (void))
                (check-equal? (for ([i (in-range 7)])
                                (for ([j (in-range 7)])
                                  (cond [(or (equal? i 0) (equal? i 6))
                                         (grid-replace-checks grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))
                                         (array-set! grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))]
                                        [(or (equal? j 0) (equal? j 6))
                                         (grid-replace-checks grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))
                                         (array-set! grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))]
                                        [else
                                         (grid-replace-checks grid-ex1 (vector (+ i 5) (+ j 7)) (new empty-cell%))
                                         (array-set! grid-ex1 (vector (+ i 5) (+ j 7)) (new empty-cell%))])))
                              (void))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "not a valid placement for a horizontal door!")))
                 (λ ()
                   (grid-replace-checks grid-ex1 (vector 6 7) (new horizontal-door%))))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "Not a valid placement for an empty-cell")))
                 (λ ()
                   (grid-replace-checks grid-ex1 (vector 6 7) (new empty-cell%))))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "not a valid placement for a horizontal door!")))
                 (λ ()
                   (grid-replace-checks grid-ex1 (vector 5 7) (new horizontal-door%))))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "Not a valid placement for a vertical-door!")))
                 (λ ()
                   (grid-replace-checks grid-ex1 (vector 5 7) (new vertical-door%))))
                
                
                
                (check-equal? (grid-replace-checks grid-ex1 (vector 6 7) (new vertical-door%)) (void))
                (array-set! grid-ex1 (vector 6 7) (new vertical-door%))
                (check-equal? (for ([i (in-range 6)])
                                (for ([j (in-range 6)])
                                  (cond [(or (equal? i 0) (equal? i 6))
                                         (grid-replace-checks grid-ex1 (vector (+ i 11) (+ j 7)) (new wall%))
                                         (array-set! grid-ex1 (vector (+ i 11) (+ j 7)) (new wall%))]
                                        [(or (equal? j 0) (equal? j 6))
                                         (grid-replace-checks grid-ex1 (vector (+ i 11) (+ j 7)) (new wall%))
                                         (array-set! grid-ex1 (vector (+ i 11) (+ j 7)) (new wall%))]
                                        [else
                                         (grid-replace-checks grid-ex1 (vector (+ i 11) (+ j 7)) (new empty-cell%))
                                         (array-set! grid-ex1 (vector (+ i 11) (+ j 7)) (new empty-cell%))])))
                              (void))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "Not a valid placement for a vertical-door!")))
                 (λ ()
                   (grid-replace-checks grid-ex1 (vector 11 11) (new vertical-door%))))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "not a valid placement for a horizontal door!")))
                 (λ ()
                   (grid-replace-checks grid-ex1 (vector 10 11) (new horizontal-door%))))
                
                (check-equal? (grid-replace-checks grid-ex1 (vector 11 12) (new horizontal-door%)) (void))
                (array-set! grid-ex1 (vector 11 12) (new vertical-door%))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "Not a valid placement for a wall!")))
                 (λ ()
                   (for ([i (in-range 6)])
                     (for ([j (in-range 6)])
                       (cond [(or (equal? i 0) (equal? i 6))
                              (grid-replace-checks grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))
                              (array-set! grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))]
                             [(or (equal? j 0) (equal? j 6))
                              (grid-replace-checks grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))
                              (array-set! grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))]
                             [else
                              (grid-replace-checks grid-ex1 (vector (+ i 9) (+ j 11)) (new empty-cell%))
                              (array-set! grid-ex1 (vector (+ i 9) (+ j 11)) (new empty-cell%))])))))
                
                ))
  ;; ============================================================================================  
  ;; is-between/intersecting or overlapping room test demostration
  ;(define test-lst '(( #(5 0) #(14 8)) ( #(5 8) #(13 17)) ( #(1 17) #(7 25))))
  ;(define test-lst2 '(( #(5 0) #(14 8))  ( #(6 4) #(12 12))))
  ;(define test-lst3 '(( #(5 0) #(19 14))  ( #(9 3) #(14 9))))
  ;(define test-lst4 '(( #(9 3) #(14 9))  ( #(5 0) #(19 14))))
  ;(define test-lst5 '(( #(2 0) #(8 6))   ( #(8 0) #(15 6))))
  ;(define test-lst6 '(( #(2 0) #(8 6))   ( #(9 0) #(16 6))))
  ;(define test-lst7 '(( #(2 0) #(9 6))   ( #(8 0) #(15 6))))
  ;(define test-lst8 '(( #(2 0) #(8 6))   ( #(2 6) #(8 12))))
  ;(define test-lst9 '(( #(2 0) #(8 6))   ( #(2 7) #(8 13))))
  ;(define test-lst10 '(( #(2 0) #(8 7))   ( #(2 6) #(8 13))))
  
  #;(define suite-5
    (test-suite "Room Intersection Suite"
                ;; standard expectation of rooms 
                
                (check-equal? (is-between? test-lst #t) #t)
                ;;
                ;;                 XXXXXXXXX
                ;;                 X       X
                ;;                 X       X 
                ;;                 X       X
                ;;XXXXXXXXXXXXXXXXXX       X
                ;;X       X        X       X 
                ;;X       X        XXXXXXXXX
                ;;X       X        X
                ;;X       X        X
                ;;X       X        X
                ;;X       X        X
                ;;X       X        X
                ;;X       XXXXXXXXXX
                ;;XXXXXXXXX
                ;;
                ;;
                ;;
                ;;

                ;; overlapping rooms/corridors
                
                
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "This grid is not set up correctly! There are rooms that overlap/intersect")))
                 (λ ()
                   (is-between? test-lst2 #t)))
                
                ;;
                ;;
                ;;
                ;;
                ;;
                ;;XXXXXXXX
                ;;X   XXXXXXXXX
                ;;X   X  X    X
                ;;X   X  X    X
                ;;X   X  X    X
                ;;X   X  X    X
                ;;X   X  X    X
                ;;X   XXXXXXXXX
                ;;X      X
                ;;XXXXXXXX
                ;;

                ;; rooms or corridors placed inside of eachother
                
                
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "This grid is not set up correctly! There are rooms that overlap/intersect")))
                 (λ ()
                   (is-between? test-lst3 #t)))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "This grid is not set up correctly! There are rooms that overlap/intersect")))
                 (λ ()
                   (is-between? test-lst4 #t)))
                
                

                ;;
                ;;
                ;;
                ;;
                ;;(5 0) (19 14) + (9 3) (14 9)
                ;;XXXXXXXXXXXXXX
                ;;X            X
                ;;X            X
                ;;X            X
                ;;X  XXXXXXX   X
                ;;X  X     X   X
                ;;X  X     X   X
                ;;X  X     X   X
                ;;X  X     X   X
                ;;X  XXXXXXX   X
                ;;X            X
                ;;X            X
                ;;X            X
                ;;X            X
                ;;XXXXXXXXXXXXXX




                ;;
                ;;
                ;;XXXXXXX
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;XXXXXXX
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;XXXXXXX
                ;;
                ;;
                ;;
                ;;
                ;;
                ;;
                
                (check-equal? (is-between? test-lst5 #t) #t)

                ;;
                ;;
                ;;XXXXXXX
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;XXXXXXX
                ;;XXXXXXX
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;XXXXXXX
                ;;
                ;;
                ;;
                ;;
                ;;
                ;;
                (check-equal? (is-between? test-lst6 #t) #t)


                ;;
                ;;
                ;;XXXXXXX
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;XXXXXXX // top of one
                ;;XXXXXXX // bottom of one
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;X     X
                ;;XXXXXXX
                ;;
                ;;
                ;;
                ;;
                ;;(define test-lst7 '(( #(2 0) #(9 6))   ( #(8 0) #(15 6))))
                ;;
                ;(printf "test-lst7 results: ~a\n" (is-between? test-lst7 #t))
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "This grid is not set up correctly! There are rooms that overlap/intersect")))
                 (λ ()
                   (is-between? test-lst7 #t)))

                ;;
                ;;
                ;;XXXXXXXXXXXXX
                ;;X     X     X
                ;;X     X     X
                ;;X     X     X
                ;;X     X     X
                ;;X     X     X
                ;;XXXXXXXXXXXXX
                ;;
                ;;
                ;;
                ;;
                (check-equal? (is-between? test-lst8 #t) #t)

                ;;
                ;;
                ;;XXXXXXXXXXXXXX
                ;;X     XX     X
                ;;X     XX     X
                ;;X     XX     X
                ;;X     XX     X
                ;;X     XX     X
                ;;XXXXXXXXXXXXXX
                ;;
                ;;
                ;;
                ;;
                (check-equal? (is-between? test-lst9 #t) #t)

                ;;
                ;;       | back of one room 
                ;;XXXXXXXXXXXXXX
                ;;X     XX     X
                ;;X     XX     X
                ;;X     XX     X
                ;;X     XX     X
                ;;X     XX     X
                ;;XXXXXXXXXXXXXX
                ;;      | front of other room
                ;;
                ;;
                ;;
                (check-exn
                 (λ (e)
                   (and (exn:fail? e)
                        (string-contains? (exn-message e) "This grid is not set up correctly! There are rooms that overlap/intersect")))
                 (λ ()
                   (is-between? test-lst10 #t)))))
  
  (define (summarize results num)
    (define successes (count test-success? results))
    (define failures (count test-failure? results))
    (define errors   (count test-error? results))
    (printf "Test Suite ~a Results: ~a success(es), ~a failure(s), ~a error(s)\n" num successes failures errors))
  
  ;(define results1 (run-test suite-1))
  (define results2 (run-test suite-2))
  ;(define results3 (run-test suite-3))
  ;(define results4 (run-test suite-4))
  ;(define results5 (run-test suite-5))
  (define results6 (run-test suite-6))
  ;(summarize results1 1)
  (summarize results2 2)
  ;(summarize results3 3)
  ;(summarize results4 4)
  ;(summarize results5 5)
  (summarize results6 6)
  )
