(local config (require :config))

(lambda make [x y dx dy]
  (let [b {: x : y : dx : dy :h 4 :w 4}]
    (fn b.draw [{: x : y : w : h}]
      (love.graphics.rectangle :fill x y w h))

    (fn b.update [b dt]
      (set b.x (+ b.x (* b.dx dt)))
      (set b.y (+ b.y (* b.dy dt))))

    (fn b.collides? [{: x : y : w : h} object]
      (not (or (> x (+ object.x object.w)) (> object.x (+ x w))
               (> y (+ object.y object.h)) (> object.y (+ y h)))))

    (fn b.reset [b serving-player]
      (set b.x (- (/ config.virtual-width 2) 2))
      (set b.y (- (/ config.virtual-height 2) 2))
      (set b.dx (* serving-player.direction (math.random 140 200)))
      (set b.dy (math.random -50 50)))

    b))

{: make}
