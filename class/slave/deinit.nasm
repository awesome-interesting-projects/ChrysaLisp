%include 'inc/func.ninc'
%include 'class/class_slave.ninc'
%include 'class/class_stream_msg_out.ninc'
%include 'class/class_stream_msg_in.ninc'
%include 'class/class_vector.ninc'

def_func class/slave/deinit
	;inputs
	;r0 = slave object
	;trashes
	;all but r0, r4

	ptr inst, msg

	push_scope
	retire {r0}, {inst}

	;flush remaining
	virt_call stream_msg_out, write_flush, {inst->slave_stderr}
	virt_call stream_msg_out, write_flush, {inst->slave_stdout}

	;send stopping on stdout
	func_call stream_msg_out, set_state, {inst->slave_stdout, stream_mail_state_stopping}
	virt_call stream_msg_out, write_next, {inst->slave_stdout}
	virt_call stream_msg_out, write_flush, {inst->slave_stdout}

	;wait for stopped
	loop_start
		virt_call stream_msg_in, read_next, {inst->slave_stdin}, {_}
	loop_until {inst->slave_stdin->stream_msg_in_state == stream_mail_state_stopped}

	;send stopped on stdout and stderr
	func_call stream_msg_out, set_state, {inst->slave_stdout, stream_mail_state_stopped}
	func_call stream_msg_out, set_state, {inst->slave_stderr, stream_mail_state_stopped}
	virt_call stream_msg_out, write_next, {inst->slave_stdout}
	virt_call stream_msg_out, write_flush, {inst->slave_stdout}
	virt_call stream_msg_out, write_next, {inst->slave_stderr}
	virt_call stream_msg_out, write_flush, {inst->slave_stderr}

	;free stdin, stdout and stderr
	func_call stream_msg_in, deref, {inst->slave_stdin}
	func_call stream_msg_out, deref, {inst->slave_stdout}
	func_call stream_msg_out, deref, {inst->slave_stderr}

	;free args
	func_call vector, deref, {inst->slave_args}

	expr {inst}, {r0}
	pop_scope

	;deinit parent
	s_jmp slave, deinit, {r0}

def_func_end
