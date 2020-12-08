;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; pathnode - File System folder paths for ChyrsaLisp
; Implements a tree hierarchy using the named-xnode
; collection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(import "sys/lisp.inc")
(import "lib/clenv/clenv.inc")
(import "lib/date/date.inc")

(defq
  _pathseparator  "/"
  _pathnoderoot   nil
  _current_dir    nil)  ; default path separator

; File mode masks

(defmacro isfile? (mode)
  `(/= (logand ,mode 0x8000) 0))
(defmacro isdir? (mode)
  `(/= (logand ,mode 0x4000) 0))

(defmacro user-mask (mode)
  `(logand ,mode 0xe00))
(defmacro user-id-mask (mode)
  `(logand ,mode 0x800))
(defmacro group-id-mask (mode)
  `(logand ,mode 0x400))
(defmacro sticky-bit-mask (mode)
  `(logand ,mode 0x200))

; These generalize to first 3 bits
(defmacro owner-mask (mode)
  `(>> (logand ,mode 0x700) 8))
(defmacro group-mask (mode)
  `(>> (logand ,mode 0x070) 4))
(defmacro other-mask (mode)
  `(logand ,mode 0x007))

(defmacro noperm? (mode)
  `(= ,mode 0))
(defmacro read? (mode)
  `(/= (logand ,mode 4) 0))
(defmacro write? (mode)
  `(/= (logand ,mode 2) 0))
(defmacro exec? (mode)
  `(/= (logand ,mode 1) 0))

; Easy/default filters
(defq
    _pn-name-only    first
    _pn-all-filter   (#(t))
    _pn-file-filter  (#(eql (second %0) "8"))
    _pn-dir-filter   (#(eql (second %0) "4"))
    _pn_short-filter (lambda ((_fn _ft))
                            (when (and
                              (not (eql _fn "."))
                              (not (eql _fn ".."))
                              (not (eql (first _fn) "."))) t)))

(defclass path-node (name &optional parent)
  ; file-system path tree
  (def (defq this (named-xnode name parent))
    :path_node t
    :stat_res  nil)

  (defmethod :full_path (this)
    ; (. path-node :full_path) -> string
    ; Returns the full path string
    (. this :full_name))

  ; Set stats for node
  (when (not (get :stat_res this))
    (set this :stat_res (pii-fstat (. this :full_path))))

  (defmethod :date (this)
    ; (. path-node :date) -> date
    ; Returns node mod date from fstat
    (date (first (get :stat_res this))))

  (defmethod :size (this)
    ; (. path-node :size) -> number
    ; Returns node size from fstat
    (second (get :stat_res this)))

  (defmethod :mode (this)
    ; (. path-node :mode) -> number
    ; Returns node mode from fstat
    (last (get :stat_res this)))

  (defmethod :is_root? (this)
    ; (. path-node :is_root?) -> t | nil
    ; Tests whether this node is the root
    (not (. this :get_parent)))

  (defmethod :members (this)
    ; (. path-node :members) -> list
    ; Returns list of pairs from pii-dirlist
    (partition 2 (split (pii-dirlist (. this :full_path)) ",")))

  (defmethod :all-members (this &optional name-fn filter-fn)
    ; (. path-node :all-members [name-fn filter-fn])
    ; HOF
    ; Returns filtered members of path-node [filter-fn]
    ; then maps results using name function [name-fn]
    ; Defaults to all members with all names (including hidden dirs and files)
    (setd
      name-fn _pn-name-only
      filter-fn _pn-all-filter)
    (map name-fn (filter filter-fn (. this :members))))

  (defmethod :dir-members (this &optional name-fn filter-fn)
    ; (. path-node :dir-members [name-fn filter-fn])
    ; HOF
    ; Returns directory type members of path-node [filter-fn]
    ; then maps results using name function [name-fn]
    (setd
      name-fn _pn-name-only
      filter-fn _pn-dir-filter)
    (. this :all-members name-fn filter-fn))

  (defmethod :file-members (this &optional name-fn filter-fn)
    ; (. path-node :file-members [name-fn filter-fn])
    ; HOF
    ; Returns file type members of path-node [filter-fn]
    ; then maps results using name function [name-fn]
    (setd
      name-fn _pn-name-only
      filter-fn _pn-file-filter)
    (. this :all-members name-fn filter-fn))

  (defmethod :fqname (this filename)
    ; (. path-node filename) -> string
    ; Returns fully qualifed filename prefixed by pathname
    (defq pn (. this :full_path))
    (str pn (if (eql (last pn) _pathseparator) "" _pathseparator) filename))

  (defmethod :child_segment (this namestr)
    (cond
      ((. this :is_root?)
        (. this :child_for_node_name namestr))
      ((defq snode (. this :child_for_node_name _pathseparator))
        (. snode :child_for_node_name namestr))
      (t nil)))

  (defmethod :expandto (this strpathlist)
    ; (. path-node :expandto path-node pathlist) -> path-node
    ; Builds out children to path provided in strpathlist
    ; throws exception if any path element is invalid
    (defun index-of (etf elist)
      (reduced-reduce (lambda (acc el)
        (if (eql el etf) (reduced _) nil)) elist t))

    (defun prior-segment (this)
      (defq p1 (. this :get_parent))
      (cond
        ; Root where this = first sep
        ((nil? p1) this)
        ; Parent is root
        ((nil? (. p1 :get_parent)) p1)
        (t (. p1 :get_parent))))

    (defun new-segment (this node_name)
      (cond
        ; No need to add separator to root as it is already
        ((and (. this :is_root?) (eql node_name _pathseparator))
          this)
        ; No need to add separator of root, just add new
        ((. this :is_root?)
          (. this :add_node (path-node node_name)))
        ; Add a separator as child of this and then new to that
        (t
          (defq msep (opt
            (. this :has_child? _pathseparator)
            (. this :add_node (path-node _pathseparator))))
          (opt
            (. msep :has_child? node_name)
            (. msep :add_node (path-node node_name))))))

    (reduce (lambda (acc el)
      (defq cn (. acc :child_segment el))
      (cond
        ; Relative moves
        ((or (eql el ".") (eql el _pathseparator))
          acc)
        ; Back up
        ((eql el "..")
          (prior-segment acc))
        ; Child already exists
        (cn cn)
        ; Fall through, validate child and add
        (t
          (if (index-of el (. acc :dir-members))
              (new-segment acc el)
            (throw
              (str el " is invalid child of path " (. acc :full_path))
              (. acc :dir-members)))))) strpathlist this))
  )

(defun path-node? (this)
  ; (path-node? obj) -> t | nil
  (and (env? this) (get :path_node this)))

; Initializing routine

(when (not _pathnoderoot)
  (setq
    _pathseparator (gets-enval "PATH_SEP")
    _pathnoderoot  (path-node _pathseparator)
    _current_dir   _pathnoderoot))

; Path string utilities

(defun _path-tolist (pathname &optional sep)
  ; (_strpath-tolist pathname) -> list
  ; Parses a pathname string into a list of path elements
  ; example:
  ; (_path-tolist "/Users/bob/here") -> ("/" "Users") "/" "bob" "/" "here")
  ; (_path-tolist "/Users/bob/here" "\") -> ("\" "Users") "\" "bob" "\" "here")
  (setd sep _pathseparator)
  (defq
    seed (if (eql (first pathname) sep) (list sep) (list))
    prsd (split pathname sep)
    lng  (dec (length prsd)))
  (reduce
    (lambda (acc el)
      ; Expansion of '~'
      (when (eql el "~")
        (defq isp (split (gets-enval "HOME") sep))
        (each! 0 -2 (#(push acc sep %0 sep)) (list isp))
        (setq el (last isp)))
      (if (= _ lng)
        (push acc el)
        (push acc el sep)))
    prsd seed))

(defun node-for (pathname)
  ; (change-dir pathname ) -> path-node
  ; Returns the path-node for pathname
  ; Will expand tree by building valid path-nodes in pathname
  (defq
    path-el (_path-tolist pathname)
    frstel  (first path-el)
    plen    (length path-el))
  (cond
    ; Do nothing
    ((empty? path-el)
      _current_dir)
    ; Root
    ((and (eql frstel _pathseparator) (= plen 1))
      _pathnoderoot)
    ; Fully qualified from root
    ((and (eql frstel _pathseparator) (> plen 1))
      (. _pathnoderoot :expandto path-el))
    ; Relative current path
    (t
      (. _current_dir :expandto path-el))))

(defun change-dir (pathname)
  ; (change-cdir pathname ) -> path-node
  ; Returns the path-node for pathname
  ; Will expand tree by building valid path-nodes in pathname
  (setq _current_dir (node-for pathname)))