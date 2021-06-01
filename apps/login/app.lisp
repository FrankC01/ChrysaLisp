(defq *env_user* "Guest")
(import "sys/lisp.inc")
(import "class/lisp.inc")
(import "gui/lisp.inc")

(enums +event 0
	(enum login create))

(ui-window mywindow ()
	(ui-title-bar _ "Login Manager" () ())
	(ui-flow _ (:flow_flags +flow_right_fill)
		(ui-grid _ (:grid_width 1 :grid_height 2)
			(ui-label _ (:text "Username:"))
			(ui-label _ (:text "Password:")))
		(ui-grid _ (:grid_width 1 :grid_height 2 :color +argb_white)
			(ui-textfield username (:hint_text "username"
				:clear_text (if (defq old (load "apps/login/current")) old "Guest")))
			(ui-textfield password (:hint_text "password" :mode t :min_width 192))))
	(ui-grid _ (:grid_width 2 :grid_height 1)
		(ui-buttons ("Login" "Create") +event_login)))

(defun position-window ()
	(bind '(w h) (. mywindow :pref_size))
	(bind '(pw ph) (. (penv mywindow) :get_size))
	(. mywindow :change_dirty (/ (- pw w) 2) (/ (- ph h) 2) w h))

(defun get-username ()
	(if (eql (defq user (get :clear_text username)) "") "Guest" user))

(defun main ()
	;add centered, wait a little for GUI to get going...
	(task-sleep 10000)
	(gui-add mywindow)
	(position-window)
	(while (cond
		((and (< (defq id (getf (defq msg (mail-read (task-mailbox))) +ev_msg_target_id)) 0)
			(= (getf msg +ev_msg_type) +ev_type_gui))
			;resized GUI
			(position-window))
		((= id +event_login)
			;login button
			(cond
				((/= (age (cat "apps/login/" (defq user (get-username)) "/pupa.inc")) 0)
					;login user
					(save user "apps/login/current")
					(open-child "apps/wallpaper/app.lisp" +kn_call_open)
					nil)
				(t	t)))
		((= id +event_create)
			;create button
			(cond
				((and (/= (age "apps/login/Guest/pupa.inc") 0)
					(= (age (cat (defq home (cat "apps/login/" (defq user (get-username)) "/")) "pupa.inc")) 0))
					;copy initial user files from Guest
					(save (load "apps/login/Guest/pupa.inc") (cat home "pupa.inc"))
					;login new user
					(save user "apps/login/current")
					(open-child "apps/wallpaper/app.lisp" +kn_call_open)
					nil)
				(t	t)))
		(t (. mywindow :event msg))))
	(. mywindow :hide))
