(import "apps/clipboard/app.inc")

(defun main ()
	(defq clip_service (mail-declare (task-mailbox) "CLIPBOARD_SERVICE" "Clipboard Service 0.2")
		clipboard "")
	(while t
		(defq msg (mail-read (task-mailbox)))
		(cond
			((= (defq type (getf msg +clipboard_event_type)) +clip_type_put)
				;put string on clipboard
				(setq clipboard (slice +clipboard_put_data -1 msg)))
			((= type +clip_type_get)
				;get string from clipboard
				(mail-send (getf msg +clipboard_get_reply) clipboard))))
	(mail-forget clip_service))
