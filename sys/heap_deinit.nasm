%include 'inc/func.inc'
%include 'inc/heap.inc'
%include 'inc/syscall.inc'

def_func sys/heap_deinit
	;inputs
	;r0 = heap
	;outputs
	;r0 = heap
	;trashes
	;r0-r3

	vp_cpy r0, r1
	loop_flist_forward r0 + hp_heap_block_flist, r2, r3
		vp_cpy r2, r0
		ln_remove_fnode r2, r3
		vp_cpy [r1 + hp_heap_blocksize], r3
		vp_add ln_fnode_size, r3
		sys_munmap r0, r3
		f_bind sys_mem, statics, r0
		vp_sub r3, [r0]
	loop_end
	vp_ret

def_func_end
