(import "sys/lisp.inc")
(import "class/lisp.inc")
(import "gui/lisp.inc")

(defq id t index 0 xv 4 yv 0 i 512
	frames (map (lambda (_) (Canvas-from-file (cat "apps/freeball/staoball_" (str _) ".cpm") +load_flag_shared)) (range 1 12))
	sframes (map (lambda (_) (Canvas-from-file (cat "apps/freeball/staoball_s_" (str _) ".cpm") +load_flag_shared)) (range 1 12)))

(ui-root view (View) (:color 0)
	(ui-element frame (elem 0 frames))
	(ui-element sframe (elem 0 sframes)))

(defun main ()
	(defq screen (penv (gui-add view)))
	(while id
		(bind '(_ _ screen_width screen_height) (. screen :get_bounds))
		(defq index (% (inc index) (length frames))
			old_frame frame frame (elem index frames)
			old_sframe sframe sframe (elem index sframes))
		(bind '(ox oy w h) (. view :get_bounds))
		(bind '(_ _ fw fh) (. old_frame :get_bounds))
		(bind '(_ _ sw sh) (. old_sframe :get_bounds))
		(defq x (+ ox xv) y (+ oy yv) yv (inc yv))
		(if (> y (- screen_height fh)) (setq y (- screen_height fh) yv (neg (/ (* yv 8) 10))))
		(if (< x 0) (setq x 0 xv (abs xv)))
		(if (> x (- screen_width fw)) (setq x (- screen_width fw) xv (neg (abs xv))))
		(. frame :set_bounds 0 0 fw fh)
		(. sframe :set_bounds 8 32 sw sh)
		(. old_sframe :sub)
		(. old_frame :sub)
		(.-> view (:add_back sframe) (:add_front frame)
			(:change_dirty x y (+ 8 sw) (+ 32 sh)))
		(setq id (/= 0 (setq i (dec i))))
		(while (mail-poll (list (task-mailbox)))
			(and (< (getf (defq msg (mail-read (task-mailbox))) +ev_msg_target_id) 0)
				(= (getf msg +ev_msg_type) +ev_type_mouse)
				(setq id nil)))
		(task-sleep 40000))
	(. view :hide))
