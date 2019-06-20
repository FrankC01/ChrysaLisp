;import settings
(import 'sys/lisp.inc)

(defun pii-output (_)
	(each (lambda (_) (pii-write-char 1 (code _))) _))

(defun terminal-output (c)
	(if (eq c 13) (setq c 10))
	(cond
		;print char
		((eq c 9)
			(pii-output "    "))
		(t
			(pii-output (char c)))))

(defun terminal-input (c)
	;echo char to terminal
	;(terminal-output c)
	(cond
		;send line ?
		((or (eq c 10) (eq c 13))
			;what state ?
			(cond
				(cmd
					;feed active pipe
					(pipe-write cmd (cat buffer (char 10))))
				(t
					;start new pipe
					(cond
						((ne (length buffer) 0)
							;new pipe
							(catch (setq cmd (pipe buffer)) (progn (setq cmd nil) t))
							(unless cmd (pii-output (cat "Pipe Error !" (char 10) ">"))))
						(t (pii-output ">")))))
			(setq buffer ""))
		((eq c 27)
			;esc
			(when cmd
				;feed active pipe, then EOF
				(when (ne (length buffer) 0)
					(pipe-write cmd buffer))
				(setq cmd nil buffer "")
				(pii-output (cat (char 10) ">"))))
		((and (eq c 8) (ne (length buffer) 0))
			;backspace
			(setq buffer (slice 0 -2 buffer)))
		((le 32 c 127)
			;buffer the char
			(setq buffer (cat buffer (char c))))))

;sign on msg
(pii-output (cat "ChrysaLisp Terminal 1.4" (char 10) ">"))

;create child and send args
(mail-send (list (task-mailbox)) (open-child "apps/terminal/tui_child.lisp" kn_call_open))

(defq cmd nil buffer "")
(while t
	(defq data t)
	(if cmd (setq data (pipe-read cmd t)))
	(cond
		((eql data t)
			;normal mailbox event
			(terminal-input (get-byte (mail-mymail) 0)))
		((eql data nil)
			;pipe is closed
			(setq cmd nil)
			(pii-output (cat (char 10) ">")))
		(t
			;string from pipe
			(pii-output data))))