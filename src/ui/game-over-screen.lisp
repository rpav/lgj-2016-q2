(in-package :game)

(defclass game-over-screen (screen)
  (text style))

(defmethod initialize-instance ((s game-over-screen) &key &allow-other-keys)
  (with-slots (text style) s
    (multiple-value-bind (w h) (window-size)
      (setf text (cmd-text "Game Over"
                           :x (/ w 2.0)
                           :y (/ h 2.0))
            style (cmd-font-style :size (/ h 5.0)
                                  :align '(:middle :center))))))

(defmethod draw ((s game-over-screen) lists m)
  (with-slots (ui-list) lists
    (with-slots (text style) s
      (cmd-list-append ui-list style text))))

(defmethod key-event ((s game-over-screen) key state)
  (when (eq state :keydown)
    (case key
      (:scancode-z (ps-back))
      (:scancode-a (ps-back))
      (:scancode-x (ps-back))
      (:scancode-s (ps-back)))))

(defclass the-end-screen (game-over-screen) ())

(defmethod initialize-instance :after ((s the-end-screen) &key &allow-other-keys)
  (with-slots (text) s
    (setf (text-string text) "End...")))
