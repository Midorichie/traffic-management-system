;; traffic-data.clar
;; Manages IoT sensor data and traffic patterns

;; Data structures
(define-map sensor-data
    uint  ;; sensor-id
    {
        intersection: principal,
        vehicle-count: uint,
        average-speed: uint,
        timestamp: uint,
        last-updated: uint
    }
)

(define-map traffic-patterns
    {intersection: principal, time-slot: uint}  ;; time-slot is hour of day (0-23)
    {
        avg-vehicle-count: uint,
        avg-speed: uint,
        samples: uint,
        last-updated: uint
    }
)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-SENSOR (err u101))
(define-constant ERR-INVALID-DATA (err u102))
(define-constant ERR-INVALID-TIME (err u103))
(define-constant ERR-INVALID-INTERSECTION (err u104))
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-SPEED u200)  ;; Maximum realistic speed in km/h
(define-constant MAX-VEHICLES u1000)  ;; Maximum vehicles per reading

;; Valid intersections map
(define-map valid-intersections
    principal
    bool
)

;; Public functions
(define-public (register-intersection (intersection principal))
    (begin
        ;; Ensure the caller is authorized (contract owner)
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

        ;; Validate that the principal is not the contract owner (to prevent accidental misuse)
        (asserts! (not (is-eq intersection CONTRACT-OWNER)) ERR-INVALID-INTERSECTION)

        ;; Register the intersection
        (ok (map-set valid-intersections intersection true))
    )
)

(define-public (submit-sensor-data (sensor-id uint) 
                                 (vehicle-count uint)
                                 (speed uint)
                                 (intersection principal))
    (begin
        (asserts! (is-authorized-sensor sensor-id tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-data vehicle-count speed) ERR-INVALID-DATA)
        (asserts! (is-valid-intersection intersection) ERR-INVALID-INTERSECTION)
        
        ;; Update sensor data
        (map-set sensor-data
            sensor-id
            {
                intersection: intersection,
                vehicle-count: vehicle-count,
                average-speed: speed,
                timestamp: block-height,
                last-updated: (get-current-time)
            }
        )
        
        ;; Update traffic pattern
        (update-traffic-pattern intersection vehicle-count speed)
    )
)

(define-read-only (get-sensor-reading (sensor-id uint))
    (map-get? sensor-data sensor-id)
)

(define-read-only (get-traffic-pattern (intersection principal) (time-slot uint))
    (begin
        (if (not (is-valid-intersection intersection))
            ERR-INVALID-INTERSECTION
            (ok (map-get? traffic-patterns {intersection: intersection, time-slot: time-slot}))
        )
    )
)

;; Private functions
(define-private (is-valid-intersection (intersection principal))
    (and
        (not (is-eq intersection CONTRACT-OWNER))
        (is-some (map-get? valid-intersections intersection))
    )
)

(define-private (is-authorized-sensor (sensor-id uint) (sender principal))
    (or
        (is-eq sender CONTRACT-OWNER)
        (is-some (map-get? sensor-data sensor-id))  ;; Existing sensors are authorized
    )
)

(define-private (is-valid-data (vehicle-count uint) (speed uint))
    (and
        (<= vehicle-count MAX-VEHICLES)
        (<= speed MAX-SPEED)
        (> speed u0)
    )
)

(define-private (get-current-time)
    (unwrap-panic (get-block-info? time (- block-height u1)))
)

(define-private (get-hour-slot (timestamp uint))
    (mod (/ timestamp u3600) u24)  ;; Convert to hours and get 0-23 slot
)

(define-private (update-traffic-pattern (intersection principal) 
                                      (vehicle-count uint)
                                      (speed uint))
    (let
        (
            (time-slot (get-hour-slot (get-current-time)))
            (current-pattern (default-to
                {
                    avg-vehicle-count: u0,
                    avg-speed: u0,
                    samples: u0,
                    last-updated: u0
                }
                (map-get? traffic-patterns {intersection: intersection, time-slot: time-slot})))
            (new-samples (+ (get samples current-pattern) u1))
        )
        (map-set traffic-patterns
            {intersection: intersection, time-slot: time-slot}
            {
                avg-vehicle-count: (/ (+ (* (get avg-vehicle-count current-pattern) 
                                          (get samples current-pattern)) 
                                       vehicle-count)
                                    new-samples),
                avg-speed: (/ (+ (* (get avg-speed current-pattern) 
                                  (get samples current-pattern)) 
                               speed)
                            new-samples),
                samples: new-samples,
                last-updated: (get-current-time)
            }
        )
        (ok true)
    )
)
