;imports
(import "sys/lisp.inc")
(import "class/lisp.inc")
(import "gui/lisp.inc")

(structure '+event 0
	(byte 'close+)
	(byte 'file_button+ 'tree_button+)
	(byte 'exts_action+ 'ok_action+))

(ui-window mywindow nil
	(ui-flow _ (:flow_flags +flow_down_fill+)
		(ui-title-bar window_title "" (0xea19) +event_close+)
		(ui-flow _ (:flow_flags +flow_right_fill+)
			(ui-buttons (0xe93a) +event_ok_action+ (:font *env_toolbar_font*))
			(ui-label _ (:text "Filename:"))
			(component-connect (ui-textfield filename (:text "")) +event_ok_action+))
		(ui-flow _ (:flow_flags +flow_right_fill+)
			(ui-label _ (:text "Filter:"))
			(component-connect (ui-textfield ext_filter (:text "")) +event_exts_action+))
		(ui-flow _ (:flow_flags +flow_right_fill+ :font *env_terminal_font* :color +argb_white+ :border 1)
			(ui-flow _ (:flow_flags +flow_down_fill+)
				(ui-label _ (:text "Folders" :font *env_window_font*))
				(ui-scroll tree_scroll +scroll_flag_vertical+ nil
					(ui-flow tree_flow (:flow_flags +flow_down_fill+ :color +argb_white+
						:min_width 256))))
			(ui-flow _ (:flow_flags +flow_down_fill+)
				(ui-label _ (:text "Files" :font *env_window_font*))
				(ui-scroll files_scroll +scroll_flag_vertical+ nil
					(ui-flow files_flow (:flow_flags +flow_down_fill+ :color +argb_white+
						:min_width 256)))))))

(defun all-files (root)
	;all files from root downwards, none recursive
	;don't include "." folders
	(defq stack (list root) files (list))
	(while (setq root (pop stack))
		(each! 0 -1 (lambda (file type)
			(unless (starts-with "." file)
				(push (if (eql type "4") stack files) (cat root "/" file))))
			(unzip (split (pii-dirlist root) ",") (list (list) (list)))))
	files)

(defun populate-files (files dir exts)
	;filter files and dirs to only those that match and are unique
	(if (= (length (setq exts (split exts ", "))) 0) (setq exts '("")))
	(defq dirs_with_exts (list) files_within_dir (list))
	(each (lambda (_)
			(defq i (inc (find-rev "/" _)) d (slice 0 i _) f (slice i -1 _))
			(if (notany (lambda (_) (eql d _)) dirs_with_exts)
				(push dirs_with_exts d))
			(if (eql dir d)
				(push files_within_dir f)))
		(filter (lambda (f) (some (lambda (ext) (ends-with ext f)) exts)) files))
	(setq dirs_with_exts (sort cmp dirs_with_exts))
	;populate tree and files flows
	(each (# (. %0 :sub)) tree_buttons)
	(each (# (. %0 :sub)) file_buttons)
	(clear tree_buttons file_buttons)
	(each (lambda (_)
		(def (defq b (Button)) :text _)
		(if (eql _ dir) (def b :color +argb_grey14+))
		(. tree_flow :add_child (component-connect b +event_tree_button+))
		(push tree_buttons b)) dirs_with_exts)
	(each (lambda (_)
		(def (defq b (Button)) :text _)
		(. files_flow :add_child (component-connect b +event_file_button+))
		(push file_buttons b)) files_within_dir)
	;layout and size window
	(bind '(_ ch) (. tree_scroll :get_size))
	(bind '(w h) (. tree_flow :pref_size))
	(. tree_flow :set_size w h)
	(. tree_flow :layout)
	(def tree_scroll :min_width w :min_height (max ch 512))
	(bind '(w h) (. files_flow :pref_size))
	(. files_flow :set_size w h)
	(. files_flow :layout)
	(def files_scroll :min_width w :min_height (max ch 512))
	(. files_scroll :layout)
	(. tree_scroll :layout)
	(bind '(x y) (. mywindow :get_pos))
	(bind '(w h) (. mywindow :pref_size))
	(. mywindow :change_dirty x y w h)
	(def tree_scroll :min_height 0)
	(def files_scroll :min_height 0))

(defun main ()
	;read paramaters from parent
	(bind '(reply_mbox title dir exts) (mail-read (task-mailbox)))
	(def window_title :text title)
	(def ext_filter :text exts)
	(defq all_files (sort cmp (all-files dir)) tree_buttons (list) file_buttons (list) current_dir (cat dir "/"))
	(populate-files all_files current_dir exts)
	(bind '(x y w h) (apply view-locate (. mywindow :get_size)))
	(gui-add (. mywindow :change x y w h))
	(while (cond
		((eql (defq msg (mail-read (task-mailbox))) "")
			nil)
		((= (defq id (get-long msg ev_msg_target_id)) +event_close+)
			(mail-send "" reply_mbox))
		((= id +event_ok_action+)
			(mail-send (get :text filename) reply_mbox))
		((= id +event_file_button+)
			(defq old_filename (get :text filename) new_filename (cat current_dir
				(get :text (. mywindow :find_id (get-long msg ev_msg_action_source_id)))))
			(if (eql new_filename old_filename)
				(mail-send new_filename reply_mbox))
			(set filename :text new_filename)
			(. (. filename :layout) :dirty))
		((= id +event_tree_button+)
			(setq current_dir (get :text (. mywindow :find_id (get-long msg ev_msg_action_source_id))))
			(populate-files all_files current_dir exts))
		((= id +event_exts_action+)
			(setq exts (get :text ext_filter))
			(populate-files all_files current_dir exts))
		(t (. mywindow :event msg))))
	(. mywindow :hide))
