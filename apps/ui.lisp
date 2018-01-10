;import ui settings
(bind '(
	flow_flag_left flow_flag_right flow_flag_up flow_flag_down
	flow_flag_fillw flow_flag_fillh flow_flag_lastw flow_flag_lasth
	flow_flag_align_hcenter flow_flag_align_hleft flow_flag_align_hright
	flow_flag_align_vcenter flow_flag_align_vtop flow_flag_align_vbottom
	window_flag_close window_flag_min window_flag_max
	ev_msg_target_id ev_msg_action_source_id
	kn_call_open slot_find_id
	slot_gui_add slot_event
	slot_add_child slot_change
	slot_pref_size slot_connect_click
	slot_set_title slot_set_status
	slot_create_label slot_create_button
	slot_create_flow slot_create_grid
	slot_create_window slot_create_font
	slot_create_progress slot_create_canvas
	slot_create_text slot_connect_close
	slot_connect_min slot_connect_max)
	(within-compile-env (lambda ()
		(import 'gui/gui.inc)
		(import 'sys/kernel/kernel.inc)
		(import 'class/flow/flow.inc)
		(import 'class/button/button.inc)
		(import 'class/window/window.inc)
		(list flow_flag_left flow_flag_right flow_flag_up flow_flag_down
			flow_flag_fillw flow_flag_fillh flow_flag_lastw flow_flag_lasth
			flow_flag_align_hcenter flow_flag_align_hleft flow_flag_align_hright
			flow_flag_align_vcenter flow_flag_align_vtop flow_flag_align_vbottom
			window_flag_close window_flag_min window_flag_max
			ev_msg_target_id ev_msg_action_source_id
			kn_call_open (method-slot 'view 'find_id)
			(method-slot 'gui_gui 'add) (method-slot 'view 'event)
			(method-slot 'view 'add_child) (method-slot 'view 'change)
			(method-slot 'view 'pref_size) (method-slot 'button 'connect_click)
			(method-slot 'window 'set_title) (method-slot 'window 'set_status)
			(method-slot 'component 'create_label) (method-slot 'component 'create_button)
			(method-slot 'component 'create_flow) (method-slot 'component 'create_grid)
			(method-slot 'component 'create_window) (method-slot 'component 'create_font)
			(method-slot 'component 'create_progress) (method-slot 'component 'create_canvas)
			(method-slot 'component 'create_text) (method-slot 'window 'connect_close)
			(method-slot 'window 'connect_min) (method-slot 'window 'connect_max)
			))))

;some helpful ui properties macros
(defmacro def-props (_ &rest b) `(eval (list defq ~b) ,_))
(defmacro set-props (_ &rest b) `(eval (list setq ~b) ,_))
(defmacro get-prop (_ b) `(eval ,b ,_))
