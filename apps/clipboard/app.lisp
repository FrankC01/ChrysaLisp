(import "sys/lisp.inc")

;single instance per node only
(if (= 0 (length
		(filter (# (eql (slice +long_size -1 (task-mailbox)) (slice +long_size -1 %0)))
		(map (# (to-net-id (elem 1 (split %0 ",")))) (mail-enquire "CLIPBOARD_SERVICE")))))
	(import "apps/clipboard/app_impl.lisp"))
