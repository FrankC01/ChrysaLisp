%include 'inc/func.inc'
%include 'class/class_text.inc'
%include 'class/class_label.inc'

	fn_function class/label/set_text
		;inputs
		;r0 = label object
		;r1 = 0, else string pointer
		;trashes
		;all but r0, r4

		def_local
			def_local_long	inst
		def_local_end

		;save inputs
		vp_sub local_size, r4
		set_src r0
		set_dst .inst
		map_src_to_dst

		static_call text, set_text, {[r0 + label_text], r1}

		vp_cpy .inst, r0
		method_call label, layout, {[r0 + label_flow]}

		vp_cpy .inst, r0
		vp_add local_size, r4
		vp_ret

	fn_function_end
