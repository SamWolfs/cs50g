(local config (require :config))
(local lume (require :lume.lume))

(lambda make [name direction controls]
  (let [p {: name
           :x (% (+ config.virtual-width (* direction 10)
                    (if (= direction 1) 0 -5))
                 config.virtual-width)
           :y (% (+ config.virtual-height (* direction 30)
                    (if (= direction 1) 0 -20))
                 config.virtual-height)
           : direction
           : controls
           :w 5
           :h 20
           :score 0
           :speed 200}]
    (fn p.draw [{: x : y : w : h}]
      (love.graphics.rectangle :fill x y w h))

    (fn p.update [p _ball dt]
      (each [key direction (pairs p.controls)]
        (when (love.keyboard.isDown key)
          (set p.y (lume.clamp (+ p.y (* (* direction p.speed) dt)) 0
                               (- config.virtual-height 20))))))

    (fn p.has-won? [p] (= p.score 10))

    p))

{: make}
