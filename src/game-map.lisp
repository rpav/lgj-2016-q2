(in-package :game)

(defclass game-map ()
  ((tilemap :initform nil)
   (gktm :initform nil)
   (physics :initform (make-instance 'physics))))

(defmethod initialize-instance :after ((gm game-map) &key map)
  (with-slots (tilemap physics gktm) gm
    (let* ((tm (load-tilemap map))
           (size (tilemap-size tm))
           (max (* 16.0 (max (vx size) (vy size)))))
      (setf tilemap tm
            physics (make-instance 'physics
                      :quadtree (make-instance 'quadtree
                                  :key #'entity-box
                                  :size max))
            gktm (make-instance 'gk-tilemap :tilemap tm))
      (gm-setup-physics gm)
      (physics-start physics))))

(defun map-find-start (map &optional target)
  (with-slots (tilemap) map
    ;; This should probably be done via GF, but
    (typecase target
      (gk-vec2 target)
      (gk-vec3 target)
      (t (let* ((ob (tilemap-find-object tilemap "objects" (or target "start"))))
           (values (let ((x (or (aval :x ob) 0))
                         (y (or (aval :y ob) 0)))
                     (gk-vec2 x y))
                   (aval :properties ob)))))))

(defun map-add (map &rest objects)
  (with-slots (physics) map
    (apply 'physics-add physics objects)
    (apply 'entity-added-to-map map objects)))

(defun map-remove (map &rest objects)
  (with-slots (physics) map
    (apply 'physics-remove physics objects)))

(defun map-move (map object new-pos)
  (with-slots (physics) map
    (physics-remove physics object)
    (setf (entity-pos object) new-pos)
    (physics-add physics object)))

(defun map-update (map)
  (with-slots (physics) map
    (physics-update physics)))

(defun map-find-in-box (map box &optional offs)
  (with-slots (physics) map
    (physics-find physics box offs)))

(defmethod draw ((gm game-map) lists m)
  (with-slots (gktm physics) gm
    (draw gktm lists m)
    (physics-map (lambda (ob) (draw ob lists m))
                 physics)))

 ;;

(defun gm-object-type (ob)
  (let ((type (aval :type ob)))
    (if (or (not type) (string= "" type))
        'simple-blocker
        (intern (string-upcase type) :game))))

(defun gm-make-instance (gm tm ob)
  (let* ((type (gm-object-type ob))
         (pos (gk-vec3 (aval :x ob) (aval :y ob) 0))
         (size (gk-vec2 (aval :width ob) (aval :height ob)))
         (sprite-name
           (when-let (tile (tilemap-find-gid tm (aval :gid ob)))
             (tile-image tile))))
    (and type
         (make-instance type
           :name (aval :name ob)
           :sprite-name sprite-name
           :pos pos :size size
           :props (aval :properties ob)))))

(defun gm-add-object (gm tm ob)
  (with-slots (physics) gm
    (when-let (instance (gm-make-instance gm tm ob))
      (physics-add physics instance))))

(defun gm-setup-physics (gm)
  (with-slots ((tm tilemap) physics) gm
    ;; Really just need to iterate all object layers...
    (map-tilemap-objects (lambda (x) (gm-add-object gm tm x)) tm "collision")
    (map-tilemap-objects (lambda (x) (gm-add-object gm tm x)) tm "objects")
    (map-tilemap-objects (lambda (x) (gm-add-object gm tm x)) tm "interacts")
    (map-tilemap-objects (lambda (x) (gm-add-object gm tm x)) tm "spawners")
    (map-tilemap-objects (lambda (x) (gm-add-object gm tm x)) tm "npcs")

    ;; Map boundaries .. we should fill map/target props in from map props
    (physics-add physics (make-instance 'map-link
                           :map (tilemap-property tm :s)
                           :direction :s
                           :pos (gk-vec3 -1 -1 0) :size (gk-vec2 256 1)))
    (physics-add physics (make-instance 'map-link
                           :map (tilemap-property tm :w)
                           :direction :w
                           :pos (gk-vec3 -1 -1 0) :size (gk-vec2 1 144)))
    (physics-add physics (make-instance 'map-link
                           :map (tilemap-property tm :n)
                           :direction :n
                           :pos (gk-vec3 -1 144 0) :size (gk-vec2 256 1)))
    (physics-add physics (make-instance 'map-link
                           :map (tilemap-property tm :e)
                           :direction :e
                           :pos (gk-vec3 256 -1 0) :size (gk-vec2 1 144)))))
