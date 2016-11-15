%include 'inc/func.ninc'
%include 'inc/string.ninc'
%include 'inc/load.ninc'
%include 'class/class_string.ninc'

def_func class/string/create_from_long
	;inputs
	;r0 = number
	;r1 = base
	;outputs
	;r0 = 0 if error, else object
	;trashes
	;all but r4

	const char_minus, "-"

	ptr this
	pubyte buffer, reloc
	long num, base

	push_scope
	retire {r0, r1}, {num, base}

	func_path sys_load, statics
	assign {@_function_.ld_statics_reloc_buffer}, {reloc}
	assign {reloc}, {buffer}
	if {num < 0}
		assign {char_minus}, {*buffer}
		assign {buffer + 1}, {buffer}
		assign {-num}, {num}
	endif
	func_call sys_string, from_long, {num, buffer, base}
	func_call string, create_from_cstr, {reloc}, {this}

	expr {this}, {r0}
	pop_scope
	return

def_func_end
