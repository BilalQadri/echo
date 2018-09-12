;;;; echo.lisp

(in-package #:echo)


(defvar background '())
(defvar script '())
(defvar misc '())

;;; "echo" goes here. Hacks and glory await!

(bordeaux-threads:make-thread (lambda ()
                                (run-server 1235))
                              :name "websockets server")

(defclass echo-resource (ws-resource)
  ())

(defmethod resource-client-connected ((res echo-resource) client)
  (format t "got connection on echo server from ~s : ~s~%" (client-host client) (client-port client))
  t)

(defmethod resource-client-disconnected ((resource echo-resource) client)
  
  (format t "Client disconnected from resource ~A: ~A~%" resource client))

(defmethod resource-received-text ((res echo-resource) client message)
  (set-client client message)
  (format t "got frame ~s from client ~s" message client))

(defmethod resource-received-binary((res echo-resource) client message)
  (format t "got binary frame ~s from client ~s" (length message) client)
  (write-to-client-binary client message))


(register-global-resource
 "/"
 (make-instance 'echo-resource)
 #'ws::any-origin)

;(register-global-resource "/echo"
;                          (make-instance 'echo-resource)
;			  (origin-prefix))
                       ;   (origin-prefix "http://127.0.0.1" "http://localhost"))

(bordeaux-threads:make-thread (lambda ()
                                (run-resource-listener
                                 (find-global-resource "/")))
                              :name "resource listener for /echo")


(defun set-client (client message)
  "Set client on Message received"
  (cond ((equal message "background")
	 (setf background client))
	((equal message "script")
	 (setf script client))
	(t
	 (setf misc client))))

(defun send-recursively (client msg)
  "send to client"
  (when (not (null client))
    (write-to-client-text client msg)))


;;;;;;;;;;;;;;;;;; Own Api

;(defmacro translate (body)
;  (let ((code (read-from-string body)))
;  `(ps ,code)))


(defun send (msg source)
  "send"
  (cond ((equal source "background")
	 (send-recursively background msg))
	((equal source "script")
	 (send-recursively script msg))
	(t
	 (send-recursively misc msg))))


; (send "alert('SiX')" "script")



;(write-to-client-text background "console.log(3)")
