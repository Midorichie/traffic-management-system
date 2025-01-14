;; traffic-signals.clar
;; Manages traffic signal states and timing

(define-data-var signal-state (string-ascii 20) "RED")
(define-data-var last-update uint u0)
(define-map intersection-signals
    principal
    {
        status: (string-ascii 20),
        duration: uint,
        last-modified: uint
    }
)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-STATE (err u101))
(define-constant ERR-INVALID-DURATION (err u102))
(define-constant ERR-INVALID-INTERSECTION (err u103))
(define-constant CONTRACT-OWNER tx-sender)

;; Public functions
(define-public (update-signal (intersection principal) (new-state (string-ascii 20)) (duration uint))
    (let
        (
            (is-valid-duration (validate-timing duration))
            (is-valid-intersection (validate-intersection intersection))
        )
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-state new-state) ERR-INVALID-STATE)
        (asserts! is-valid-duration ERR-INVALID-DURATION)
        (asserts! is-valid-intersection ERR-INVALID-INTERSECTION)
        (ok (map-set intersection-signals 
            intersection
            {
                status: new-state,
                duration: duration,
                last-modified: block-height
            }
        ))
    )
)

;; Read-only functions
(define-read-only (get-signal-state (intersection principal))
    (map-get? intersection-signals intersection)
)

(define-read-only (is-valid-state (state (string-ascii 20)))
    (or
        (is-eq state "RED")
        (is-eq state "YELLOW")
        (is-eq state "GREEN")
    )
)

;; Private functions
(define-private (validate-timing (duration uint))
    (and
        (>= duration u5)  ;; Minimum 5 seconds
        (<= duration u300) ;; Maximum 5 minutes
    )
)

(define-private (validate-intersection (intersection principal))
    (and
        (not (is-eq intersection CONTRACT-OWNER))  ;; Prevent using contract owner as intersection
        (not (is-eq intersection (as-contract tx-sender)))  ;; Prevent using contract itself
    )
)
