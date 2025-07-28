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

;; mutate `grid` to add `room`
(define (commit-room grid room)
  (for ([pos+cell% (in-list (room-poss->cells room))])
    (match-define (cons pos cell%) pos+cell%)
    (array-set! grid pos (new cell%))))


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
  ;;
  ;(printf "encounters: ~a\n" encounters)
  ;(printf "length of encounters: ~a\n" (length encounters))
  (define n-rooms (max (length encounters) (random-between 6 9)))
  ;(printf "N-rooms: ~a\n" n-rooms)
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
        ;(printf "rooms: ~a\n" rooms)
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
  (require typed/rackunit)

  (define (render-grid g) (string-join g "\n" #:after-last "\n"))

  (define (empty-grid)
    (build-array #(6 6) (lambda _ (new void-cell%))))
  (define g1 (empty-grid))
  (check-equal? (show-grid g1)
                (render-grid '("......"
                               "......"
                               "......"
                               "......"
                               "......"
                               "......")))
  (check-false (try-add-rectangle g1 #(10 10) 3 3 right)) ; out of bounds
  (commit-room g1 (or (try-add-rectangle g1 #(2 1) 3 3 right) (error 'commit)))
  (check-equal? (show-grid g1)
                (render-grid '("......"
                               ".XXX.."
                               ".X X.."
                               ".XXX.."
                               "......"
                               "......")))
  ;(check-equal? (room-counter g1) 1)
  (check-false (try-add-rectangle g1 #(2 2) 3 3 up))
  (commit-room g1 (or (try-add-rectangle g1 #(3 3) 3 3 down) (error 'commit)))
  (check-equal? (show-grid g1)
                (render-grid '("......"
                               ".XXX.."
                               ".X X.."
                               ".XXXX."
                               "..X X."
                               "..XXX.")))
  (define g2 (empty-grid))
  (commit-room g2 (or (try-add-rectangle g2 #(1 1) 3 4 right) (error 'commit)))
  (check-equal? (show-grid g2)
                (render-grid '(".XXXX."
                               ".X  X."
                               ".XXXX."
                               "......"
                               "......"
                               "......")))


  (define (empty-grid1)
    (build-array #(20 40) (lambda _ (new void-cell%))))
  (define g11 (empty-grid1))
  (check-equal? (show-grid g11)
                (render-grid '("........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................"
                               "........................................")))

  ;; ============================================================================================
  ;; room counter function


  (define (room-counter grid)
      
      (define num-corr (corridor-counter grid))
      (define num-door (door-counter grid))
      (if (equal? num-corr 0)
          (+ 1 num-door)
          (- (+ 1 num-door) num-corr)
          )
      )
  

  
  ;; ============================================================================================
  ;; corridor counter function

  
  (define (corridor_helper grid-split index-lst curr-index counted num-pairs)
    (define num_pairs (- (length index-lst) 1))
    ;(printf "in the corridor helper\n")
    ;(printf "num_pairs: ~a\n" num_pairs)
    (cond [(< num_pairs 1)
           ;(printf "Done iterating. Returning counted as the following: ~a\n" counted)
           counted]
          [else
           ;(define indecies (take (drop index-lst index) 2) ) ;; get a pair indicies
           (define front (list-ref index-lst 0))
           (define back (list-ref index-lst 1))
           ;(printf "front: ~a\n" front)
           ;(printf "back: ~a\n" back)
           (define prev-line (vector-ref grid-split (- curr-index 1))) ;; get the previous line
           ;(define prev-line-lst (string->list prev-line)) ;; get the string as a list
           (define sectioned-prev-lst (vector-copy prev-line front (+ back 1)))
           (define next-line (vector-ref grid-split (+ curr-index 1))) ;; get the next line
           ;(define next-line-lst (string->list next-line)) ;; get the string as a list
           (define sectioned-next-lst (vector-copy next-line front (+ back 1)))
           (cond
             [(>= (- back front) 3) ;; need to determine how long a corridor is supposed to be
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

               (equal? (vector-ref (vector-ref grid-split (- curr-index 1)) (+ front 2)) (new wall%))
               (equal? (vector-ref (vector-ref grid-split (+ curr-index 1)) (+ front 2)) (new wall%))
                ;;index 0, walls
               
               )
              ;(printf "Found a corridor!\n")     
              (set! counted (+ counted 1))
              ;(printf "updated counted: ~a\n" counted)
              (corridor_helper grid-split (rest index-lst) curr-index counted (- num-pairs 1))]
             [else (corridor_helper grid-split (rest index-lst) curr-index counted (- num-pairs 1))
                   ]
             )]))
  (define (corridor-counter grid)
    (define len (vector-length grid))
    ;(printf "in the function corrdior \n")
    ;(define grid-split (string-split grid "\n"))
    (define curr-index 0)
    (define count 0)
    (define index1 0) ;; does the horizontal lines
    (define vert-lst '())
    ;; count the horizontal corridors and count the horizontal doors
    ;(printf "entering inital for loop \n")
    (for ([line grid])
      (define index-lst '())
      (define index2 0) ;; does the vertical lines
      (for ([i line]) ;; loop through line, collect indexs of all possible corridor locations
        ;(printf "i: ~a\n" i)
        (cond [(equal? i (new vertical-door%))
               ;(printf "found a vertical door\n")
               (set! index-lst (cons index2 index-lst))
               ;(printf "current: index-lst: ~a\n" index-lst)
               ]
              [(equal? i (new horizontal-door%))
               ;(printf "found a horizontal door\n")
               (set! vert-lst (cons (list index1 index2) vert-lst))
               ;(printf "current: vert-lst: ~a\n" vert-lst)
               ]
              )
        (set! index2 (+ index2 1)))
      (set! index-lst (reverse index-lst))
      (set! vert-lst (reverse vert-lst))
      (cond [(or (equal? 1 (length index-lst)) (equal? 0 (length index-lst)))
             ;(printf "we only have one or zero doors\n ")
             void] ;; if there is just one or zero record position, then it is a door, ignore
            [else
             ;(printf "we have more than one door that is vertical")
             (define num_pairs (- (length index-lst) 1)) ;; otherwise, call helper function to match pair and determin if a corridor exists
             ;(printf "number of pairs: ~a\n" num_pairs)
             (define new_found_corr (corridor_helper grid index-lst curr-index 0 num_pairs))
             ;(printf "new_found_corr: ~a\n" new_found_corr)
             (set! count (+ count new_found_corr))
             ]
            )
        
      (set! curr-index (+ curr-index 1))
      (set! index1 (+ 1 index1)))
    ;; now take the horizontal doors, and determine if they are composing any vertical corridors
    ;(printf "into vertical corridor territory\n")
    (define vert-index 1)
    (for ([loc vert-lst])
      ;(printf "curr first comparision point: ~a\n" loc)
      (define x1 (first loc))
      (define y1 (last loc))
      (define other_pairs (take vert-lst vert-index))
      ;(printf "other_pairs: ~a\n" other_pairs)
      (set! vert-index (+ 1 vert-index))
      (for ([i other_pairs])
        (unless (equal? i loc)
          ;(printf "curr second comparision point: ~a\n" i)
          (define x2 (first i))
          (define y2 (last i))
          (define dist (- x2 x1))
          ;(printf "x1: ~a\n" x1)
          ;(printf "y1: ~a\n" y1)
          ;(printf "x2: ~a\n" x2)
          ;(printf "y2: ~a\n" y2)
          (cond
            [(and (equal? y1 y2) (< dist 3)) ;; possible vertical corridor match!
             ;(printf "we have possible vertical match!\n")
              ;; the horizontal lines
             ;; y1 and y2 are the vertical locations
             ;; test to make sure the distance between these two is doors is 3 
             ;(check-equal? #t (< dist 3))
             ;(printf "dist between doors: ~a\n" dist)
             (define indicator #t)
             (cond [(not
                     (and
                      (and
                       (or
                        (equal? (vector-ref (vector-ref grid (+ x1 0)) (- y1 1)) (new wall%))
                        )
                       (or
                        (equal? (vector-ref (vector-ref grid (+ x1 0)) (+ y1 1)) (new wall%))           
                        ))
                      (and
                       (and 
                        (or
                         (equal? (vector-ref (vector-ref grid (+ x1 1)) (- y1 1)) (new wall%))
                         (equal? (vector-ref (vector-ref grid (+ x1 1)) (- y1 1)) (new vertical-door%))
                         (equal? (vector-ref (vector-ref grid (+ x1 1)) (- y1 1)) (new empty-cell%)))
                        (or
                         (equal? (vector-ref (vector-ref grid (+ x1 1)) (+ y1 1)) (new wall%))
                         (equal? (vector-ref (vector-ref grid (+ x1 1)) (+ y1 1)) (new vertical-door%))
                         (equal? (vector-ref (vector-ref grid (+ x1 1)) (+ y1 1)) (new empty-cell%))))
                       (and
                        (or
                         (equal? (vector-ref (vector-ref grid (+ x1 2)) (+ y1 1)) (new wall%))
                         )
                        (or
                         (equal? (vector-ref (vector-ref grid (+ x1 2)) (- y1 1)) (new wall%))
                         ))
                       )
                      ))
                    (set! indicator #f)])
             (cond [(equal? indicator #t)
                    ;(printf "indicator is true, successful find!\n")
                    (set! count (+ count 1))
                    #;(printf "updated count: ~a\n" count)])]))))
    count
    )
  
  ;; ============================================================================================
  ;; door counter function

  (define (door-counter grid)
    ;(define grid-split (string-split grid "\n"))
    ;(printf "grid: ~a\n" grid)
    (define count 0)
    (for ([line grid])
      ;; fix line
      (for ([i line])
        ;(printf "object: ~a\n" i)
        (cond [(or (equal? i (new horizontal-door%))
                   (equal? i (new vertical-door%)))
               ;(printf "found a door!!!!!!!!!!!!!!!!!!!!!!!!!\n")
               (set! count (+ count 1))
               ])
        )
      )
    count
    )

  ;; ============================================================================================
  ;; basic functionality test of testing functions above


  (define g5 (empty-grid))

  (commit-room g5 (or (try-add-rectangle g5 #(2 1) 3 3 right) (error 'commit)))
  (check-equal? (show-grid g5)
                (render-grid '("......"
                               ".XXX.."
                               ".X X.."
                               ".XXX.."
                               "......"
                               "......")))
  ;(printf "g5: ~a\n" g5)
  (check-equal? (door-counter g5) 0)
  (check-equal? (corridor-counter g5) 0)
  (check-equal? (room-counter g5) 1)

  

  

  ;; ============================================================================================  
  ;; helper function to gather the borders different rooms/corridors put into the grid
  (define (dimensions-calc rooms)
    ;(printf  "rooms: ~a\n" (room-poss->cells rooms))
    (define beginning (first (room-poss->cells rooms)))
    (match-define (cons pos1 cell1%) beginning)
    (define end (last (room-poss->cells rooms)))
    (match-define (cons pos2 cell2%) end)
    (set! room_boundaries (cons (list pos1 pos2) room_boundaries))
    ;(printf "room_boundaries: ~a\n" room_boundaries)
    
    )
  ;; ============================================================================================  
  ;; testing function meant to test that cell objects are correctly overwritting specific cells 
  (define (grid-replace-checks grid pos cell)
    ;(printf "in grid replacement\n")
    (define curr-cell (grid-ref grid pos))
    ;(printf "pos: ~a\n" pos)
    ;(printf "curr-cell: ~a\n" curr-cell)
    (define x (vector-ref pos 0))
    ;(printf "x: ~a\n" x)
    (define y (vector-ref pos 1))
    ;(printf "y: ~a\n" y)
    ;; vertical
    ;; (+ y 1)
    ;; (- y 1)
    ;; keep x 

    ;; horizontal
    ;; (+ x 1)
    ;; (- x 1)
    ;; keep y
    (cond
      
      [(equal? cell (new empty-cell%))
       (check-equal? curr-cell (new void-cell%))]
      [(equal? cell (new wall%))
       (check-equal? #t
                     (or
                      (equal? curr-cell (new wall%))
                      (equal? curr-cell (new void-cell%))))] 
      [(equal? cell (new vertical-door%))
       ;; adding walls above or on the sides, based on the type of doors
       (check-equal? #t
                     (and
                      (and
                       (check-equal? (grid-ref grid (vector (+ x 1) y)) (new wall%))
                       (check-equal? (grid-ref grid (vector (- x 1) y)) (new wall%))
                       (check-equal? (grid-ref grid (vector x (+ y 1))) (new empty-cell%)) 
                       (check-equal? (grid-ref grid (vector x (- y 1))) (new empty-cell%)))
                      (equal? curr-cell (new wall%))))] 
      [(equal? cell (new horizontal-door%))
       ;(printf "found a horizontal door!\n")
       (check-equal? #t
                     (and
                      (and
                       (check-equal? (grid-ref grid (vector x (+ y 1))) (new wall%))
                       (check-equal? (grid-ref grid (vector x (- y 1))) (new wall%))
                       (check-equal? (grid-ref grid (vector (+ x 1) y)) (new empty-cell%)) 
                       (check-equal? (grid-ref grid (vector (- x 1) y)) (new empty-cell%)))
                      (equal? curr-cell (new wall%))))] 
      )
    )

  ;; ============================================================================================  


  (define (commit-room1 grid room)
    (dimensions-calc room)
    ;(printf "room: ~a\n" (room-poss->cells room))
    (for ([pos+cell% (in-list (room-poss->cells room))])
      (match-define (cons pos cell%) pos+cell%)
      (grid-replace-checks grid pos cell%)
      (array-set! grid pos (new cell%))
      ;(printf "pos: ~a\n" pos)
      ;(set! room_boundaries (cons room_boundaries pos))
      ))

  ;; ============================================================================================  
  ;; modified version of generate-dungeon
  ;; -- includes tracker variables such as room_boundaries, corridor, count, etc in order to track specific components, and ensure they operate together correctly
  ;; -- this version is also broken apart into several helper functions
  
  (define connections-loc '())
  (define room-count 0)
  (define door-count 0)
  (define corridor-count 0)
  (define room_boundaries '())
  (define (generate-dungeon-loc encounters)
    (define n-rooms (max (length encounters) (random-between 6 9)))
    (set! room-count 0)
    (set! connections-loc '())
    (set! door-count 0)
    (set! corridor-count 0)
    (set! room_boundaries '())
    (define grid
      (build-array (vector dungeon-height dungeon-width)
                   (lambda _ (new void-cell%)))) ;; new cell created 
  
    (define first-room
      (let loop  ()
        (define starting-point
          (vector (assert (random dungeon-height) index?)
                  (assert (random dungeon-width) index?)))
        ;(printf "starting-point: ~a\n" starting-point)
        (define first-room
          (new-room grid starting-point (random-direction)))
        (or first-room (loop))
        
        )) ; if it doesn't fit, try again
    (commit-room1 grid first-room)
    (when animate-generation? (display (show-grid grid)))
  

    (adding-loop grid n-rooms first-room encounters)
    )
  ;; ============================================================================================  
  (define (extension-points/room-loc room)
    (for/list  ([e (in-list (room-extension-points room))])
      (cons e room)))

  ;; ============================================================================================  
  (define (add-room-loc grid dir n-rooms-to-go rooms extension-points origin-room room ext [corridor #f] [new-ext #f])
    (when corridor
      (commit-room1 grid corridor)
      (set! corridor-count (+ 1 corridor-count))
      ;;;;;;;;;;;
      ;(check-equal? corridor-count (corridor-counter grid))
      (check-equal? (is-between? room_boundaries #t) #t))
    ;(printf "origin-room: ~a\n" origin-room)
    ;(printf "room: ~a\n" room)
    ;(printf "rooms: ~a\n" rooms)
    (commit-room1 grid room)
    
    (set! room-count (+ 1 room-count))
    ;;;;;;;;;;;;
    ;(check-equal? room-count (room-counter grid))
    ;;;; checks the addition of rooms as we go, to make sure they are being added correctly
    (check-equal? (is-between? room_boundaries #t) #t)
    ;; add doors-found
    (define door-kind
      (if (horizontal? dir) vertical-door% horizontal-door%))
    (array-set! grid ext     (new door-kind))
    (set! door-count (+ 1 door-count))
    (check-equal? door-count (door-counter grid))
    (when new-ext
      (array-set! grid new-ext (new door-kind))
      (set! door-count (+ 1 door-count))
      (check-equal? door-count (door-counter grid)))
    (set! connections-loc (cons (cons origin-room room) connections-loc))
    (when animate-generation? (display (show-grid grid)))
    (values (sub1 n-rooms-to-go)
            (cons room rooms) ; corridors don't count
            (append (if corridor
                        (extension-points/room-loc corridor)
                        '())
                    (extension-points/room-loc room)
                    extension-points)))

  ;; ============================================================================================  
  (define (adding-doors-loc grid all-rooms)
    (define potential-connections
               (for*/fold
                ([potential-connections '()])
                ([r1 (in-list all-rooms)]
                 [r2 (in-list all-rooms)]
                 #:unless (or (eq? r1 r2)
                              (member (cons r1 r2) connections-loc)
                              (member (cons r2 r1) connections-loc)
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
                 (set! door-count (+ 1 door-count))
                 (check-equal? door-count (door-counter grid))))


    )
  ;; ============================================================================================  
  (define (adding-loop grid n-rooms first-room encounters)
    (set! room-count (+ 1 room-count))
    (check-equal? room-count (room-counter grid))
    (let loop  ()
      (define-values (n all-rooms _2)
        (for/fold
         ([n-rooms-to-go    (sub1 n-rooms)]
          [rooms             (list first-room)]
          [extension-points  (extension-points/room-loc first-room)])
         ([i (in-range ITERS)])
          (cond
            ((= n-rooms-to-go 0) ;; no rooms left to add
             (values n-rooms-to-go rooms extension-points))
            (else ;; else
        
             ;; pick an extension point at random
             (match-define `(,ext . ,origin-room) (random-from extension-points))
             ;; first, try branching a corridor at random
             (define dir (random-direction))
             (cond [(and (zero? (random 4)) ; maybe add a room directly, no corridor
                         (new-room grid ext dir)) =>
                                                  (lambda (room) (add-room-loc grid dir n-rooms-to-go rooms extension-points origin-room room ext))]
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
                                                                                       (add-room-loc grid dir n-rooms-to-go rooms extension-points origin-room room ext corridor new-ext))]
                                                        [else ; didn't fit, try again
                                                         (values n-rooms-to-go rooms extension-points)]))]
                   [else ; didn't fit, try again
                    (values n-rooms-to-go rooms extension-points) 
                    ])
             
             ))))
      (cond [(not (= n 0)) ; we got stuck, try again
             ;(log-error "generate-dungeon: had to restart")
             ;; may have gotten too ambitious with n of rooms, back off
             (set! n-rooms (max (length encounters) (sub1 n-rooms)))
             (loop)]
            
            [else ; we did it
             ;; try adding more doors
             ;(printf "all-rooms: ~a\n" all-rooms)
             ;(printf "extension point: ~a\n" _2)
             (adding-doors-loc grid all-rooms) 
             grid]))

    )
  ;; ============================================================================================
  ;; is-between?: takes all the rooms/corridors and determines if they overlap
  ;; NOTE: having borders of rooms in the same place does not count, that is expected
  
  (define (is-between? pos-lst indicator)
    ;(printf "pos-lst: ~a\n" pos-lst)
    ;(printf "indicator: ~a\n" indicator)
    ;(printf "length of pos-lst: ~a\n" (length pos-lst))
    (cond [(equal? (length (rest pos-lst)) 0) indicator]
          [else 
           (define curr-front (first (first pos-lst)))
           (define curr-end (last (first pos-lst)))
           ;(printf "curr-front: ~a\n" curr-front)
           ;(printf "curr-end: ~a\n" curr-end)
           (define p1 curr-front)
           (define x1 (vector-ref p1 0))
           ;(printf "x1: ~a\n" x1)
           (define y1 (vector-ref p1 1))
           ;(printf "y1: ~a\n" y1)
           (define p4 curr-end)
           (define x2 (vector-ref p4 0))
           (define y2 (vector-ref p4 1))
           ;(printf "x2: ~a\n" x2)
           ;(printf "y2: ~a\n" y2)
           (define p2 (list x1 y2))
           ;(printf "p2: ~a\n" p2)
           (define p3 (list x2 y1))
           ;(printf "p3: ~a\n" p3)
           (for ([remain (rest pos-lst)])
             (define look-f (first remain))
             (define x-start (vector-ref look-f 0))
             ;(printf "x-start: ~a\n" x-start)
             (define y-start (vector-ref look-f 1))
             ;(printf "y-start: ~a\n" y-start)
             (define look-b (last remain))
             (define x-end (vector-ref look-b 0))
             (define y-end (vector-ref look-b 1))
             ;(printf "x-end: ~a\n" x-end)
             ;(printf "y-end: ~a\n" y-end)
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
                    (< y-end y2))
                   ))
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
                    (< y2 y-end))))
                 )
                (set! indicator #f)
                ;(printf "updated indicator: ~a\n" indicator)
                ]))
           (cond [(equal? indicator #f)
                  ;(printf "something went wrong this is not passing?\n")
                  indicator]
                 [else
                  (is-between? (rest pos-lst) indicator)])])
    indicator)
  ;; 

  ;; ============================================================================================  
  ;(display (show-grid  (generate-dungeon (range N))))
  ;; randomized testing; simulation created a different set of rooms each time
  (define gridout (generate-dungeon-loc (range N)))
  ;(printf "grid: ~a\n" gridout)
  (display (show-grid gridout))
  (printf "room-count: ~a\n" room-count)
  (printf "door-count: ~a\n" door-count)
  (printf "corridor-count: ~a\n" corridor-count)
  (check-equal? (corridor-counter gridout) corridor-count)
  (check-equal? (door-counter gridout) door-count)
  (check-equal? (room-counter gridout) room-count)
  (check-equal? (is-between? room_boundaries #t) #t)
   ;; rooms are a minimum of 6 by 6
  ;; perhaps write test confirming such property

  ;; ============================================================================================  
  ;; door -- corridor -- room calculation test demostration

  ;; door counting
  ;; basic testing, one test with correct input, one with missing a door, one an extra
  
  
  
  ;(display (show-grid tst-grid1)) 
  
  ;; corridor counting ;; review

  ;; room -- room counting algorithm
  ;; example of correct outputs
  ;; example of incorrect output, say wrong extra doors


  ;; ============================================================================================
  ;; grid-replace-checks/object-replacement test demostration -- expand on, if it has doors, the door sides need to be empty cells
  ;; basic passing tests
  ;; 18 x 70
  (define grid-ex1
      (build-array (vector dungeon-height dungeon-width)
                   (lambda _ (new void-cell%))))
  ;(grid-replace-checks grid pos cell)
  
  (for ([i (in-range 6)])
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
             ])


      )
    )
  
  ;(display (show-grid grid-ex1))

  (for ([i (in-range 7)])
    (for ([j (in-range 7)])
      (cond [(or (equal? i 0) (equal? i 6))
             (grid-replace-checks grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))
             (array-set! grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))]
            [(or (equal? j 0) (equal? j 6))
             (grid-replace-checks grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))
             (array-set! grid-ex1 (vector (+ i 5) (+ j 7)) (new wall%))]
            [else
             (grid-replace-checks grid-ex1 (vector (+ i 5) (+ j 7)) (new empty-cell%))
             (array-set! grid-ex1 (vector (+ i 5) (+ j 7)) (new empty-cell%))
             ])
      )
    )
  ;(display (show-grid grid-ex1))
  ;(grid-replace-checks grid-ex1 (vector 6 7) (new horizontal-door%))
  ;(display (show-grid grid-ex1))
  ;(grid-replace-checks grid-ex1 (vector 5 7) (new horizontal-door%))
  ;(display (show-grid grid-ex1))
  ;(grid-replace-checks grid-ex1 (vector 5 7) (new vertical-door%))
  ;(grid-replace-checks grid-ex1 (vector 6 7) (new vertical-door%))
  ;(array-set! grid-ex1 (vector 6 7) (new vertical-door%))
  ;(display (show-grid grid-ex1))

  ;;
  ;;
  ;;  XXXXXX 
  ;;  X    X
  ;;  X    X
  ;;  X    XXXXXXX
  ;;  X    _     X
  ;;  XXXXXX     X
  ;;       X     X 
  ;;       X   XXXXXX 
  ;;       X   X    X 
  ;;       XXXXX    X
  ;;           X    X
  ;;           X    X
  ;;           XXXXXX
  ;;
  ;;
  ;;
  #;(for ([i (in-range 6)])
    (for ([j (in-range 6)])
      (cond [(or (equal? i 0) (equal? i 6))
             (grid-replace-checks grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))
             (array-set! grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))]
            [(or (equal? j 0) (equal? j 6))
             (grid-replace-checks grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))
             (array-set! grid-ex1 (vector (+ i 9) (+ j 11)) (new wall%))]
            [else
             (grid-replace-checks grid-ex1 (vector (+ i 9) (+ j 11)) (new empty-cell%))
             (array-set! grid-ex1 (vector (+ i 9) (+ j 11)) (new empty-cell%))
             ])
      )
    )


  ;; replacing objects that are not supposed to be replaced (do through function calls)



  ;; application of intersecting rooms, i.e empty-cells being overwritten
  ;; empty cell on both sides of doors 
  
  ;;


  

  
  
  ;; ============================================================================================  
  ;; is-between/intersecting or overlapping room test demostration
  
  
  ;; standard expectation of rooms 
  ;(define test-lst '(( #(5 0) #(14 8)) ( #(5 8) #(13 17)) ( #(1 17) #(7 25))))
  ;(check-equal? (is-between? test-lst #t) #t)
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
  ;(define test-lst2 '(( #(5 0) #(14 8))  ( #(6 4) #(12 12))))
  ;(check-equal? (is-between? test-lst2 #t) #t)
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
  ;(define test-lst3 '(( #(5 0) #(19 14))  ( #(9 3) #(14 9))))
  ;(define test-lst4 '( ( #(9 3) #(14 9))  ( #(5 0) #(19 14))))
  ;(check-equal? (is-between? test-lst3 #t) #f)
  ;(check-equal? (is-between? test-lst4 #t) #f)

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


  




  )
