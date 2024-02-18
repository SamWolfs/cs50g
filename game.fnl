(local lume (require :lume.lume))
(local push (require :push.push))
(local player (require :player))
(local ai (require :ai))
(local b (require :ball))
(local config (require :config))

(var player1 nil)
(var player2 nil)
(var ball nil)
(var game-state :start)
(var serving-player player1)

(local font (partial love.graphics.newFont :assets/fonts/font.ttf))
(local fonts {:small (font 8) :large (font 16) :score (font 32)})

(local sounds {:paddle-hit (love.audio.newSource :assets/sounds/paddle_hit.wav
                                                 :static)
               :score (love.audio.newSource :assets/sounds/score.wav :static)
               :wall-hit (love.audio.newSource :assets/sounds/wall_hit.wav
                                               :static)})

(local bounds {:top {:x -1 :y 0 :w config.virtual-width :h 0}
               :bottom {:x -1
                        :y config.virtual-height
                        :w config.virtual-width
                        :h 0}
               :left {:x 0 :y -1 :w 0 :h config.virtual-height}
               :right {:x config.virtual-width
                       :y -1
                       :w 0
                       :h config.virtual-height}})

(local draw
       {:fps (lambda []
               (love.graphics.setFont fonts.small)
               (love.graphics.setColor 0 1 0 1)
               (love.graphics.print (.. "FPS: " (tostring (love.timer.getFPS)))
                                    10 10))
        :banner (lambda []
                  (love.graphics.setFont fonts.small)
                  (case game-state
                    :done (do
                            (love.graphics.setFont fonts.large)
                            (love.graphics.printf (.. "Player "
                                                      (if (player1:has-won?)
                                                          player1.name
                                                          player2.name)
                                                      " wins!")
                                                  0 10 config.virtual-width
                                                  :center)
                            (love.graphics.setFont fonts.small)
                            (love.graphics.printf "Press enter to restart!" 0
                                                  30 config.virtual-width
                                                  :center))
                    :start (do
                             (love.graphics.printf "Welcome to Pong!" 0 10
                                                   config.virtual-width :center)
                             (love.graphics.printf "Press Enter to begin!" 0 20
                                                   config.virtual-width :center))
                    :serve (do
                             (love.graphics.printf (.. "Player "
                                                       serving-player.name
                                                       "'s serve!")
                                                   0 10 config.virtual-width
                                                   :center)
                             (love.graphics.printf "Press Enter to serve!" 0 20
                                                   config.virtual-width :center))))
        :score (lambda []
                 (love.graphics.setFont fonts.score)
                 (love.graphics.print (tostring player1.score)
                                      (- (/ config.virtual-width 2) 50)
                                      (/ config.virtual-height 3))
                 (love.graphics.print (tostring player2.score)
                                      (+ (/ config.virtual-width 2) 30)
                                      (/ config.virtual-height 3)))})

(fn reset []
  (set game-state :start)
  (set player1 (player.make "player 1" 1 {:w -1 :s 1}))
  ;; (set player2 (player.make "player 2" -1 {:up -1 :down 1}))
  (set player2 (ai.make "ai 1" -1))

  (set serving-player player1)
  (set ball (b.make (- (/ config.virtual-width 2) 2)
                    (- (/ config.virtual-height 2) 2) (math.random 140 200)
                    (math.random (- 50) 50))))

(fn love.load []
  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)
  ;; SETUP
  (math.randomseed (os.time))
  ;; initialize game state
  (reset)
  ;; set graphics filter
  (love.graphics.setDefaultFilter :nearest :nearest)
  ;; create new font object and set as active font
  (love.graphics.setFont fonts.small)
  (push:setupScreen config.virtual-width config.virtual-height
                    config.window-width config.window-height
                    {:title :Pong!
                     :fullscreen false
                     :resizable false
                     :vsync true}))

(fn love.handlers.stdin [line]
  ;; evaluate lines read from stdin as fennel code
  (let [(ok val) (pcall fennel.eval line)]
    (print (if ok (fennel.view val) val))))

(fn love.update [dt]
  (case game-state
    ;; TODO: should give positive and negative values to left and right player
    ;; so it's easier to determine directions
    :serve
    (do
      (set ball.dy (math.random -50 50))
      (set ball.dx (if (= serving-player player1) 100 -100)))
    :play
    (do
      (if (ball:collides? player1)
          (do
            (set ball.dx (* (- ball.dx) 1.03))
            (set ball.x (+ player1.x 5))
            (set ball.dy (* (lume.sign ball.dy) (math.random 10 150)))
            (sounds.paddle-hit:play))
          (ball:collides? player2)
          (do
            (set ball.dx (* (- ball.dx) 1.03))
            (set ball.x (- player2.x 4))
            (set ball.dy (* (lume.sign ball.dy) (math.random 10 150)))
            (sounds.paddle-hit:play))
          (or (ball:collides? bounds.top) (ball:collides? bounds.bottom))
          (do
            (set ball.dy (- ball.dy))
            (sounds.wall-hit:play)))))
  (if (< ball.x (+ player1.x player1.w))
      (do
        (set serving-player player1)
        (set player2.score (+ player2.score 1))
        (sounds.score:play)
        (ball:reset serving-player)
        (if (player2:has-won?)
            (set game-state :done)
            (set game-state :serve)))
      (< player2.x (+ ball.x ball.w))
      (do
        (set serving-player player2)
        (set player1.score (+ player1.score 1))
        (sounds.score:play)
        (ball:reset serving-player)
        (if (player1:has-won?)
            (set game-state :done)
            (set game-state :serve))))
  (when (= game-state :play)
    (ball:update dt))
  (player1:update ball dt)
  (player2:update ball dt))

(fn love.draw []
  ;; begin rendering at virtual resolution
  (push:apply :start)
  ;; clear the screen with a specific color; in this case, a color similar
  ;; to some versions of the original pong
  (love.graphics.clear (/ 40 255) (/ 45 255) (/ 52 255) (/ 255 255))
  (draw.score)
  (draw.banner)
  (player1:draw)
  (player2:draw)
  (ball:draw)
  (draw.fps)
  ;; finish rendering at virtual resolution
  (push:apply :end))

(fn love.resize [w h]
  (push:resize w h))

(fn love.keypressed [key]
  (if (= key :escape) (love.event.quit) (or (= key :enter) (= key :return))
      (case game-state
        :start (set game-state :serve)
        :serve (set game-state :play)
        :done (do
                (reset)
                (set game-state :serve)))))
