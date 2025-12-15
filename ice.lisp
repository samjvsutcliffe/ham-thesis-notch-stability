(in-package :cl-mpm/examples/ice/cliff-stability)
(defun plot (sim)
  ;No plotting
  (format t "~A ~%" (local-time:now))
  )
(defun plot-domain ()
  ;No plotting
  (format t "~A ~%" (local-time:now))
  )
(setf lparallel:*debug-tasks-p* nil)

(let ((threads (parse-integer (if (uiop:getenv "OMP_NUM_THREADS") (uiop:getenv "OMP_NUM_THREADS") "16"))))
  (setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (format t "Thread count ~D~%" threads))

(defparameter *ref* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1")))
(defparameter *height* (parse-float:parse-float (if (uiop:getenv "HEIGHT") (uiop:getenv "HEIGHT") "400")))
(defparameter *cliff-height* (parse-float:parse-float (if (uiop:getenv "CLIFF_HEIGHT") (uiop:getenv "CLIFF_HEIGHT") "100")))
(defparameter *floatation* (parse-float:parse-float (if (uiop:getenv "FLOATATION") (uiop:getenv "FLOATATION") "0.9")))

(format t "Running~%")

(defparameter *top-dir* (merge-pathnames "/nobackup/rmvn14/thesis/ice-cliff-stability/"))

(let ((stability-dir (merge-pathnames (format nil "./data-cliff-stability/"))))
  (ensure-directories-exist stability-dir)
  (let* ((density 918d0)
         (water-density 1028d0)
         (height *height*)
         (flotation 
           ;(/ (- *height* *cliff-height*) (* *height* (/ density water-density)))
           *floatation*
                   ))
    (let ((res t))
      (let* ((mps 2)
             (output-dir (merge-pathnames  (format nil "./output-~f-~f/" height flotation) *top-dir*)))
        (format t "Outputting to ~A~%" output-dir)
        (format t "Problem ~f ~f~%" height flotation)
        (setup :refine 1d0
               :friction 0.5d0
               :bench-length 0d0
               :ice-height height
               :mps mps
               :hydro-static nil
               :cryo-static t
               :aspect 1d0
               :slope 0d0
               :floatation-ratio flotation)
        (plot-domain)
        (setf (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0)
        (setf (cl-mpm/damage::sim-enable-length-localisation *sim*) nil)
        (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) t
              ;; (cl-mpm::sim-ghost-factor *sim*) (* 1d9 1d-3)
              (cl-mpm::sim-ghost-factor *sim*) nil
              )
        (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-9)
        (let ((res (cl-mpm/dynamic-relaxation::run-quasi-time
                     *sim*
                     :output-dir output-dir
                     :dt 1d3
                     :total-time 1d6
                     ;; :steps 1000
                     :dt-scale 1d0
                     :conv-criteria 1d-3
                     :substeps 50
                     :enable-damage t
                     :enable-plastic nil
                     :min-adaptive-steps -6
                     :max-adaptive-steps 4
                     :save-vtk-dr nil
                     :save-vtk-loadstep nil
                     :elastic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-dr-ul
                     :plotter (lambda (sim) (plot-domain))
                     :post-conv-step (lambda (sim) (plot-domain)))))
          (format t "Stability:~E ~E ~A   ~%" height flotation res)
          (save-stabilty-data stability-dir *sim* res height flotation)
          (cl-mpm/dynamic-relaxation::save-vtks *sim* output-dir 1)
          )))))
