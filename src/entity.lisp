(in-package :game)

(defvar +motion-none+  (gk-vec2  0  0))
(defvar +motion-up+    (gk-vec2  0  1))
(defvar +motion-down+  (gk-vec2  0 -1))
(defvar +motion-left+  (gk-vec2 -1  0))
(defvar +motion-right+ (gk-vec2  1  0))

(defparameter +reverse-motion+
  `((,+motion-none+ . ,+motion-none+)
    (,+motion-up+ . ,+motion-down+)
    (,+motion-down+ . ,+motion-up+)
    (,+motion-left+ . ,+motion-right+)
    (,+motion-right+ . ,+motion-left+)))

(defparameter +default-box+ (cons (gk-vec2 0 0) (gk-vec2 16 16)))

;;; May convert this to be prototypey later
(defclass entity ()
  ((name :initform nil :initarg :name :accessor entity-name)
   (pos :initform (gk-vec3 0 0 0) :initarg :pos :reader entity-pos)
   (size :initform (gk-vec2 16 16) :initarg :size :reader entity-size)
   (motion :initform (gk-vec2 0 0) :reader entity-motion)
   (state :initform nil :accessor entity-state)
   (sprite :initform nil :initarg :sprite :accessor entity-sprite)
   (props :initform nil :initarg :props :reader entity-props)))

(defmethod print-object ((e entity) s)
  (with-slots (name pos size) e
    (print-unreadable-object (e s :type t :identity t)
      (when name (format s "~A " name))
      (format s "[~S ~S ~S ~S]"
              (vx pos) (vy pos) (vx size) (vy size)))))

(defmethod (setf entity-pos) ((v gk-vec2) (e entity))
  (with-slots (pos) e
    (set-vec2 pos v)))

(defmethod (setf entity-motion) ((v gk-vec2) (e entity))
  (with-slots (motion) e
    (set-vec2 motion v)))

(defgeneric entity-box (entity)
  (:documentation "Return a `BOX` or `(values BOX OFFSET)` for `ENTITY`")
  (:method ((e entity))
    (with-slots (pos) e
      (values +default-box+ pos))))

(defgeneric entity-update (entity)
  (:method (e)
    (with-slots (pos sprite) e
      (when sprite
        (setf (sprite-pos sprite) pos)))))

(defgeneric entity-action (entity action)
  (:method (e a)))

(defgeneric entity-interact (entity actor)
  (:method (e a))
  (:documentation "Called when `ACTOR` interacts with `ENTITY`."))

(defgeneric entity-attacked (entity actor weapon)
  (:method (e a w))
  (:documentation "Called when `ACTOR` attacks `ENTITY` with `WEAPON`"))

(defgeneric entity-collide (e1 e2)
  (:documentation "Called when `E1` moves and collides with `E2`.")
  (:method (e1 e2)))

(defgeneric entity-property (e name)
  (:method ((e entity) name)
    (aval name (slot-value e 'props))))

(defmethod draw ((e entity) lists m)
  (with-slots (sprite) e
    (when sprite (draw sprite lists m))))

;;; A more complex system would allow channels or entity-entity tests
;;; or whatnot.  For now this is a simple boolean.  Default is T,
;;; because it it seems there are more solid than non-solid entities.
(defgeneric entity-solid-p (entity)
  (:documentation "Specialize to determine if `ENTITY` can be passed.")
  (:method (e) t))

(defmacro define-entity-solid-p (type val)
  `(defmethod entity-solid-p ((e ,type)) ,val))
