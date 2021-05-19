(import "class/lisp.inc")
(import "gui/lisp.inc")
(import "apps/debug/app.inc")

(enums +event 0
	(enum hvalue)
	(enum play pause step clear)
	(enum play_all pause_all step_all clear_all)
	(enum close))

(enums +debug_rec 0
	(enum buf state reply_id))

(defq vdu_width 60 vdu_height 40 buf_keys (list) buf_list (list) buf_index nil id t
	select (list (task-mailbox) (mail-alloc-mbox))
	entry (mail-declare (elem -2 select) "DEBUG_SERVICE" "Debug Service 0.4"))

(ui-window mywindow (:color 0xc0000000)
	(ui-flow _ (:flow_flags +flow_down_fill)
		(ui-title-bar _ "Debug" (0xea19) +event_close)
		(ui-tool-bar _ ()
			(ui-buttons (0xe95e 0xe95d 0xe95c 0xe960) +event_play)
			(ui-buttons (0xe95e 0xe95d 0xe95c 0xe960) +event_play_all (:color (const *env_toolbar2_col*))))
		(. (ui-slider hslider (:value 0)) :connect +event_hvalue)
		(ui-vdu vdu (:vdu_width vdu_width :vdu_height vdu_height :ink_color +argb_yellow))))

(defun vdu-print (vdu buf s)
	(each (lambda (c)
		(cond
			((eql c (ascii-char 10))
				;line feed and truncate
				(if (> (length (push buf "")) (const vdu_height))
					(setq buf (slice (const (dec (neg vdu_height))) -1 buf))))
			(t	;char
				(elem-set -2 buf (cat (elem -2 buf) c))))) s)
	(if vdu (. vdu :load buf 0 0 (length (elem -2 buf)) (dec (length buf)))) buf)

(defun set-slider-values ()
	(defq val (get :value hslider) mho (max 0 (dec (length buf_list))))
	(def hslider :maximum mho :portion 1 :value (min val mho))
	(. hslider :dirty))

(defun play (_)
	(unless (elem +debug_rec_state _)
		(step _))
	(elem-set +debug_rec_state _ t))

(defun pause (_)
	(elem-set +debug_rec_state _ nil))

(defun step (_)
	(when (elem +debug_rec_reply_id _)
		(mail-send (elem +debug_rec_reply_id _) "")
		(elem-set +debug_rec_reply_id _ nil)))

(defun reset (&optional _)
	(setd _ -1)
	(if (<= 0 _ (dec (length buf_list)))
		(progn
			(def hslider :value _)
			(setq buf_index _)
			(vdu-print vdu (elem +debug_rec_buf (elem buf_index buf_list)) ""))
		(progn
			(clear buf_list)
			(clear buf_keys)
			(setq buf_index nil)
			(. vdu :load '(
				{ChrysaLisp Debug 0.4}
				{Toolbar1 buttons act on a single task.}
				{Toolbar2 buttons act on all tasks.}
				{Slider to switch between tasks.}
				{}
				{In Lisp files:}
				{}
				{add (import "lib/debug/debug.inc")}
				{to debug all functions.}
				{}
				{Or:}
				{}
				{add (import "apps/debug/app.inc")}
				{then use}
				{(debug-send xxx yyy zzz ...)}
				{as a single stepping debug print.}) 0 0 0 1000)))
	(set-slider-values))

(defun main ()
	(bind '(x y w h) (apply view-locate (. mywindow :pref_size)))
	(gui-add (. mywindow :change x y w h))
	(reset)
	(while id
		(defq idx (mail-select select) msg (mail-read (elem idx select)))
		(cond
			;new debug msg
			((/= idx 0)
				(defq reply_id (getf msg +debug_reply)
					key (sym (getf msg +debug_origin))
					data (slice +debug_data -1 msg)
					index (find-rev key buf_keys))
				(unless index
					(push buf_keys key)
					(push buf_list (list (list "") nil nil))
					(reset (setq index (dec (length buf_list)))))
				(elem-set +debug_rec_buf (defq buf_rec (elem index buf_list))
					(vdu-print (if (= index buf_index) vdu) (elem +debug_rec_buf buf_rec) data))
				(if (elem +debug_rec_state buf_rec)
					(mail-send reply_id "")
					(elem-set +debug_rec_reply_id buf_rec reply_id)))
			;close ?
			((= (setq id (getf msg +ev_msg_target_id)) +event_close)
				(setq id nil))
			;moved task slider
			((= id +event_hvalue)
				(reset (get :value hslider)))
			;pressed play button
			((= id +event_play)
				(when buf_index
					(play (elem buf_index buf_list))))
			;pressed pause button
			((= id +event_pause)
				(when buf_index
					(pause (elem buf_index buf_list))))
			;pressed step button
			((= id +event_step)
				(when buf_index
					(step (elem buf_index buf_list))))
			;pressed clear button
			((= id +event_clear)
				(when buf_index
					(step (elem buf_index buf_list))
					(setq buf_keys (cat (slice 0 buf_index buf_keys) (slice (inc buf_index) -1 buf_keys)))
					(setq buf_list (cat (slice 0 buf_index buf_list) (slice (inc buf_index) -1 buf_list)))
					(reset (min buf_index (dec (length buf_list))))))
			;pressed play all button
			((= id +event_play_all)
				(each play buf_list))
			;pressed pause all button
			((= id +event_pause_all)
				(each pause buf_list))
			;pressed step all button
			((= id +event_step_all)
				(each step buf_list))
			;pressed clear all button
			((= id +event_clear_all)
				(each step buf_list)
				(reset))
			;otherwise
			(t (. mywindow :event msg))))
	(mail-forget entry)
	(mail-free-mbox (pop select))
	(. mywindow :hide))
