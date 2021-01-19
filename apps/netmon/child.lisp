;imports
(import "sys/lisp.inc")

(structure 'sample_reply 0
	(nodeid 'node)
	(int 'task_count 'mem_used))

(structure '+select 0
	(byte 'main+ 'timeout+))

(defun main ()
	(defq select (list (task-mailbox) (mail-alloc-mbox)) id t +timeout+ 5000000)
	(mail-timeout (elem +select_timeout+ select) +timeout+)
	(while id
		(defq msg (mail-read (elem (defq idx (mail-select select)) select)))
		(cond
			((or (= idx +select_timeout+) (eql msg ""))
				;timeout or quit
				(setq id nil))
			((= idx +select_main+)
				;main mailbox, reset timeout and reply with stats
				(mail-timeout (elem +select_timeout+ select) 0)
				(mail-timeout (elem +select_timeout+ select) +timeout+)
				(bind '(task_count mem_used) (kernel-stats))
				(mail-send msg (cat
					(slice (const long_size) -1 (task-mailbox))
					(char task_count (const int_size))
					(char mem_used (const int_size)))))))
	(mail-free-mbox (pop select)))