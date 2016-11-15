%include 'inc/func.ninc'
%include 'class/class_stream.ninc'

def_func class/stream/skip
	;inputs
	;r0 = stream object
	;r1 = char to skip
	;trashes
	;all but r0, r4

	ptr inst
	ulong skip_char
	long state

	push_scope
	retire {r0, r1}, {inst, skip_char}

	loop_start
		loop_while {inst->stream_bufp == inst->stream_bufe}
			virt_call stream, read_next, {inst}, {state}
			gotoif {state == -1}, exit
		loop_end
		breakif {*inst->stream_bufp != skip_char}
		assign {inst->stream_bufp + 1}, {inst->stream_bufp}
	loop_end
exit:
	expr {inst}, {r0}
	pop_scope
	return

def_func_end
