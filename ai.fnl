(local player (require :player))
(local config (require :config))
(local lume (require :lume.lume))

(lambda make [name direction]
  (let [ai (player.make name direction false)]
    (fn ai.update [ai ball dt]
      (when (and (not (= ai.direction (lume.sign ball.dx)))
                 (or (> ai.y (+ ball.y ball.h)) (> ball.y (+ ai.y ai.h))))
        (set ai.y (lume.clamp (+ ai.y
                                 (* (* (lume.sign (- ball.y ai.y)) ai.speed) dt))
                              0 (- config.virtual-height 20)))))

    ai))

{: make}
