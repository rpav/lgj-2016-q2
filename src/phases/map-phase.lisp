(in-package :game)

(defclass map-phase (game-phase)
  ((map-screen :initform (make-instance 'map-screen))))

(defmethod initialize-instance :after ((p map-phase) &key &allow-other-keys)
  (with-slots ((ms map-screen)) p
    (let* ((sprite
             (make-instance 'sprite
               :pos (gk-vec4 0 0 0 1)
               :sheet (asset-sheet *assets*)
               :key 1
               :index (find-anim-frame (asset-anims *assets*) "ranger-f/walk-down" 1))))
      (setf (game-window-map-screen *window*) ms)
      (setf (current-char)
            (make-instance 'game-char :sprite sprite)))))

(defmethod phase-start ((p map-phase))
  (phase-resume p))

(defmethod phase-resume ((p map-phase))
  (ps-incref *ps*)
  (with-slots (map-screen) p
    (setf (ui-visible map-screen) t))
  (unless (current-map)
    (map-change *default-map*)))

(defmethod phase-pause ((p map-phase))
  (clear-motion-bits (current-char)))

(defmethod phase-finish ((p map-phase))
  (with-slots (map-screen) p
    (setf (ui-visible map-screen) nil)))

(defmethod phase-show-textbox ((phase map-phase) text)
  (ps-interrupt (make-instance 'text-phase :text text)))

(defun show-textbox (text)
  (phase-show-textbox (ps-cur-phase) text))

(defun game-over ()
  (ps-push (make-instance 'game-over-phase))
  (ps-decref))

;;; huge hack, yes
(defun update-spell (id)
  (let ((map-screen (game-window-map-screen *window*)))
    (with-slots (hud) map-screen
      (hud-set-spell hud id))))

(defun phase-to-endgame ()
  (ps-replace (make-instance 'end-game-phase)))
