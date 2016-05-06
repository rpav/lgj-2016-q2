(in-package :game)

(defclass hud (ui)
  (health p1 fs1 p2 fs2
   (text-cmds :initform nil)))

(defmethod initialize-instance ((hud hud) &key &allow-other-keys)
  (call-next-method)
  (with-slots (health p1 fs1 p2 fs2 text-cmds) hud
    (multiple-value-bind (w h) (window-size)
      (declare (ignorable w h))
      (let* ((m (* *scale* 2.0))
             (fsize (/ h 15.0)))
        ;; This is just a hack, we _could_ do this with multiple
        ;; commands and redraw the healthbar and shadow using the same
        ;; path command.  Or we could just draw it twice using 1.
        (setf health (cmd-path
                      (list
                       :begin
                       :tf-translate *scale* *scale*
                       :rect (* fsize 2) (* 1.5 m) (* *scale* 4) (* 4 *scale*)
                       :fill-color-rgba 0 0 0 255
                       :fill
                       :begin
                       :tf-identity
                       :rect (* fsize 2) (* 1.5 m) (* *scale* 4) (* 4 *scale*)
                       :fill-color-rgba 255 0 0 255
                       :fill)))

        (setf p1 (cmd-path
                  (list
                   :fill-color-rgba 0 0 0 255
                   :tf-translate *scale* *scale*))
              fs1 (cmd-font-style :size fsize)
              p2 (cmd-path (list
                            :fill-color-rgba 255 255 255 255
                            :tf-identity))
              fs2 (cmd-font-style :size fsize))
        (appendf text-cmds
                 (list
                  (cmd-text "Life" :x m :y (+ m (/ fsize 2.0)))))))))

(defun hud-update (hud)
  (with-slots (health) hud
    (let ((player-health (* *scale* (actor-life (current-char)))))
      (setf (cmd-path-elt health 7) player-health
            (cmd-path-elt health 20) player-health))))

(defmethod draw ((hud hud) lists m)
  (hud-update hud)
  (with-slots (ui-list) lists
    (with-slots (health p1 fs1 p2 fs2 text-cmds) hud
      (cmd-list-append ui-list p1 fs1)
      (apply #'cmd-list-append ui-list text-cmds)
      (cmd-list-append ui-list p2 fs2)
      (apply #'cmd-list-append ui-list text-cmds)

      (cmd-list-append ui-list health))))
