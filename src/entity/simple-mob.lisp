(in-package :game)

(defparameter +motions+
  (list +motion-up+ +motion-down+ +motion-left+ +motion-right+))

(defclass simple-mob (actor)
  ((life :initform 3)
   (state :initform :starting)
   (act-start :initform 0)
   (name :initform nil)
   (hit-name :initform nil)
   (anim :initform nil)
   (anim-state :initform nil)))

(defmethod initialize-instance :after ((a simple-mob) &key name &allow-other-keys)
  (with-slots (anim anim-state sprite (_name name) hit-name) a
    (when name
      (setf _name name
            hit-name (string+ name "-hit"))
      (setf anim (make-instance 'anim-sprite :name name))
      (setf anim-state (animation-instance anim sprite))
      (anim-run *anim-manager* anim-state))))

(defmethod entity-attacked ((e simple-mob) a w)
  (with-slots (anim anim-state life hit-name) e
    (decf life)
    (if (actor-dead-p e)
        (unless (eq (entity-state e) :die)
          (setf (entity-state e) :die
                (entity-motion e) +motion-none+
                (anim-sprite-anim anim) (find-anim (asset-anims *assets*) "fx/splat")
                (anim-sprite-frame-length anim) (/ 100 1000.0)
                (anim-sprite-count anim) 1
                (anim-state-on-stop anim-state)
                (lambda (s)
                  (map-remove (current-map) e)))
          (anim-run *anim-manager* anim-state))
        (progn
          (setf (anim-sprite-anim anim) (find-anim (asset-anims *assets*) hit-name)
                (anim-sprite-frame-length anim) (/ 20 1000.0)
                (anim-sprite-debug anim) nil)
          (anim-run *anim-manager* anim-state)
          (call-next-method)))))

(defmethod actor-died ((a actor))
  (map-remove (current-map) a))

(defmethod actor-knockback-end :after ((a simple-mob))
  (with-slots (anim name) a
    (unless (actor-dead-p a)
      (setf (anim-sprite-anim anim) (find-anim (asset-anims *assets*) name)
            (anim-sprite-frame-length anim) (/ 180 1000.0)))))

(defun simple-mob-change-action (e)
  (with-slots (state) e
    (case state
      (:starting (setf (entity-state e) :waiting))
      (:waiting
       (setf (entity-motion e) (elt +motions+ (random 4)))
       (nv2* (entity-motion e) 0.5)
       (setf (entity-state e) :moving))
      (:moving
       (setf (entity-motion e) +motion-none+)
       (setf (entity-state e) :waiting))))
  (with-slots (act-start) e
    (setf act-start *time*)))

(defmethod entity-update ((e simple-mob))
  (call-next-method)
  (with-slots (act-start) e
    (let ((d (- *time* act-start)))
      (when (> d 1)
        (simple-mob-change-action e)))))
