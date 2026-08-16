(in-package :cl-mpm/examples/ice/cliff-stability)
(defun plot (sim)
  ;No plotting
  (format t "~A ~%" (local-time:now))
  )
(defun plot-domain ()
  ;No plotting
  (format t "~A ~%" (local-time:now))
  )

(defmethod cl-mpm/damage::damage-model-calculate-y ((mp cl-mpm/particle::particle-ice-brittle) dt)
  (with-accessors ((undamaged-stress cl-mpm/particle::mp-undamaged-stress)
                   (y cl-mpm/particle::mp-damage-y-local)
                   (strain cl-mpm/particle::mp-strain)
                   (trial-strain cl-mpm/particle::mp-trial-strain)
                   (plastic-strain cl-mpm/particle::mp-strain-plastic)
                   (ps-vm cl-mpm/particle::mp-strain-plastic-vm)
                   (damage cl-mpm/particle:mp-damage)
                   (pressure cl-mpm/particle::mp-pressure)
                   (init-stress cl-mpm/particle::mp-initiation-stress)
                   (ybar cl-mpm/particle::mp-damage-ybar)
                   (angle cl-mpm/particle::mp-friction-angle)
                   (de cl-mpm/particle::mp-elastic-matrix)
                   (def cl-mpm/particle::mp-deformation-gradient)
                   (E cl-mpm/particle::mp-e)
                   (nu cl-mpm/particle::mp-nu)
                   (j cl-mpm/particle::mp-deformation-jacobian-strain)
                   (pd-inc cl-mpm/particle::mp-plastic-damage-evolution))
      mp
    (declare (double-float E ps-vm angle pressure))
    (progn
      (let* ((ps-y (sqrt (* E (expt ps-vm 2))))
             (stress (cl-mpm/constitutive:linear-elastic-mat strain de))
             (stress-pressure
               (cl-mpm/fastmaths:fast-.+
                stress
                (cl-mpm/utils:voigt-eye (*
                                         j
                                         (/ (- pressure) 3)
                                         )))))
        (setf y
              (*
               (+
                (if pd-inc ps-y 0d0)
                ;(cl-mpm/damage::tensile-energy-norm strain e de)
                (cl-mpm/damage::criterion-mohr-coloumb-rankine-stress-tensile stress-pressure angle)
                ;(cl-mpm/damage::criterion-mohr-coloumb-rankine-stress-tensile stress angle)
                )))))))

(let ((threads (parse-integer (if (uiop:getenv "OMP_NUM_THREADS") (uiop:getenv "OMP_NUM_THREADS") "16"))))
  (cl-mpm/utils::set-workers threads)
  ;(setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (format t "Thread count ~D~%" threads))

(defparameter *ref* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1")))
(defparameter *height* (parse-float:parse-float (if (uiop:getenv "HEIGHT") (uiop:getenv "HEIGHT") "400")))
(defparameter *cliff-height* (parse-float:parse-float (if (uiop:getenv "CLIFF_HEIGHT") (uiop:getenv "CLIFF_HEIGHT") "100")))
(defparameter *floatation* (parse-float:parse-float (if (uiop:getenv "FLOATATION") (uiop:getenv "FLOATATION") "0.9")))
(defparameter *notch-ratio* (parse-float:parse-float (if (uiop:getenv "NOTCH_RATIO") (uiop:getenv "NOTCH_RATIO") "1")))

(format t "Running~%")

(defparameter *top-dir* (merge-pathnames "/nobackup/rmvn14/thesis/notch-stability/"))


(defparameter *angle* 40d0)
(defparameter *angle-r* 10d0)
(defparameter *delay-time* 1d5)
(defparameter *delay-exponent* 4d0)
(defparameter *length-scaler* 2d0)
(defparameter *enable-plastic-damage* nil)
(defparameter *gf* 10000d0)

(defparameter *penalty-epsilon-scale* 1d-1)

(let ((stability-dir (merge-pathnames (format nil "./data-cliff-stability/"))))
  (ensure-directories-exist stability-dir)
  (let* ((density 918d0)
         (water-density 1028d0)
         (height *height*)
         (flotation *floatation*))
    (let ((res t))
      (let* ((mps 3)
             (output-dir (merge-pathnames  (format nil "./output-~f-~f-~f/" height flotation *notch-ratio*) *top-dir*)))
        (format t "Outputting to ~A~%" output-dir)
        (format t "Problem ~f ~f~%" height flotation)
        (setup :refine *ref*
               :multigrid-refines 0
               :friction 0.5d0
               :bench-length (float (* height *notch-ratio*) 0d0)
               ;:bench-extra-cut (float (* height 0.1d0) 0d0)

               :ice-height height
               :mps mps
               :hydro-static nil
               :cryo-static t
               :aspect 4d0
               :slope 0.00d0
               :floatation-ratio flotation
               :use-penalty t 
               )
            (push (list :SCALAR "water-pressure" #'cl-mpm/particle::mp-pressure) (cl-mpm::sim-output-list *sim*))

        (plot-domain)

        (setf (cl-mpm:sim-settings *sim*)
            (list :OCEAN-HEIGHT *water-height*
                  :OFFSET *offset*))
        (setf (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0)
        (setf (cl-mpm/damage::sim-enable-length-localisation *sim*) t)
        (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) t
              ;; (cl-mpm::sim-ghost-factor *sim*) (* 1d9 1d-3)
              (cl-mpm::sim-ghost-factor *sim*) nil
              )
        (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-15)
        (let ((res (cl-mpm/dynamic-relaxation::run-quasi-time
                     *sim*
                     :output-dir output-dir
                     :dt 1d3
                     :total-time 1d7
                     ;; :steps 1000
                     :damping-factor (float (sqrt 2d0) 0d0)
                     :dt-scale 0.9d0
                     :conv-criteria 1d-3
                     :substeps 50
                     :enable-damage t
                     :enable-plastic t
                     :max-damage-inc 10d0


                     :min-adaptive-steps -12
                     :max-adaptive-steps 12
                     :adaption-constant 4
                     :save-vtk-conv nil
                     :save-vtk-dr nil
                     :save-vtk-loadstep t
                     ;:elastic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-dr-ul
                     :plotter (lambda (sim) (plot-domain))
                     :post-conv-step (lambda (sim) (plot-domain)))))
          (format t "Stability:~E ~E ~A   ~%" height flotation res)
          (save-stabilty-data stability-dir *sim* res height flotation *notch-ratio*)
          (cl-mpm/dynamic-relaxation::save-vtks *sim* output-dir 1)
          )))))
