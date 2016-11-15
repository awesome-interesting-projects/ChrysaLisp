%include 'inc/func.ninc'
%include 'class/class_stream_msg_in.ninc'
%include 'class/class_stream_msg_out.ninc'

def_func class/stream_msg_in/read_next
	;inputs
	;r0 = stream_msg_in object
	;outputs
	;r0 = stream_msg_in object
	;r1 = -1 for EOF, else more data
	;trashes
	;all but r0, r4

	ptr inst, msg, ack_msg

	push_scope
	retire {r0}, {inst}

	;while not stopped state
	loop_while {inst->stream_msg_in_state != stream_mail_state_stopped}
		;free any current msg
		func_call sys_mem, free, {inst->stream_buffer}

		;read next in sequence
		assign {0}, {msg}
		loop_start
			func_call stream_msg_out, next_seq, {&inst->stream_msg_in_list, msg, \
												inst->stream_msg_in_seqnum}, {msg}
			breakif {msg}
			func_call sys_mail, read, {inst->stream_msg_in_mailbox}, {msg}
		loop_end
		assign {inst->stream_msg_in_seqnum + 1}, {inst->stream_msg_in_seqnum}

		;save msg buffer details
		assign {msg}, {inst->stream_buffer}
		assign {&msg->stream_mail_data}, {inst->stream_bufp}
		assign {&(msg + msg->msg_length)}, {inst->stream_bufe}
		assign {msg->stream_mail_state}, {inst->stream_msg_in_state}

		;send ack if needed
		if {msg->stream_mail_seqnum >> stream_msg_out_ack_shift == inst->stream_msg_in_ack_seqnum}
			func_call sys_mail, alloc, {}, {ack_msg}
			assign {msg->stream_mail_ack_id.id_mbox}, {ack_msg->msg_dest.id_mbox}
			assign {msg->stream_mail_ack_id.id_cpu}, {ack_msg->msg_dest.id_cpu}
			func_call sys_mail, send, {ack_msg}
			assign {inst->stream_msg_in_ack_seqnum + 1}, {inst->stream_msg_in_ack_seqnum}
		endif

		breakif {inst->stream_msg_in_state != stream_mail_state_started}
	loop_until {inst->stream_bufp != inst->stream_bufe}

	;return -1 if not in started state
	expr {inst, (inst->stream_msg_in_state == stream_mail_state_started) - 1}, {r0, r1}
	pop_scope
	return

def_func_end
