
include inc/includes.asm

saveGPRegs macro
	mov dump_rax, rax
	mov dump_rbx, rbx
	mov dump_rcx, rcx
	mov dump_rdx, rdx
	mov dump_rsi, rsi
	mov dump_rdi, rdi
	mov dump_rbp, rbp
	mov dump_rsp, rsp
	mov dump_r8,  r8
	mov dump_r9,  r9
	mov dump_r10, r10
	mov dump_r11, r11
	mov dump_r12, r12
	mov dump_r13, r13
	mov dump_r14, r14
	mov dump_r15, r15
endm

restoreGPRegs macro
	; Note: Does not restore rsp
	mov rax, dump_rax
	mov rbx, dump_rbx
	mov rcx, dump_rcx
	mov rdx, dump_rdx
	mov rsi, dump_rsi
	mov rdi, dump_rdi
	mov rbp, dump_rbp
	mov r8,  dump_r8
	mov r9,  dump_r9
	mov r10, dump_r10
	mov r11, dump_r11
	mov r12, dump_r12
	mov r13, dump_r13
	mov r14, dump_r14
	mov r15, dump_r15
endm

saveXMMRegs macro from:req, to:req
	LOCAL off, num
	off = from*10h
	num = from
	repeat 16
		if (num GE from) AND (num LE to)
			vmovaps dump_xmm + &off, @CatStr(<xmm>, %num)
		endif
		off = off + 10h
		num = num + 1
	endm
endm

saveYMMRegs macro from:req, to:req
	LOCAL off, num
	off = from*20h
	num = from
	repeat 16
		if (num GE from) AND (num LE to)
			vmovaps dump_ymm + &off, @CatStr(<ymm>, %num)
		endif
		off = off + 20h
		num = num + 1
	endm
endm

restoreXMMRegs macro from:req, to:req
	LOCAL off, num
	off = from*10h
	num = from
	repeat 16
		if (num GE from) AND (num LE to)
			vmovaps @CatStr(<xmm>, %num), dump_xmm + &off
		endif
		off = off + 10h
		num = num + 1
	endm
endm

restoreYMMRegs macro from:req, to:req
	LOCAL off, num
	off = from*20h
	num = from
	repeat 16
		if (num GE from) AND (num LE to)
			vmovaps @CatStr(<ymm>, %num), dump_ymm + &off
		endif
		off = off + 20h
		num = num + 1
	endm
endm

_TEXT segment para readonly

_dump_reg proc
	mov r8d, edx	; lower 32 bits
	shr rdx, 32		; upper 32 bits
	invoke printf   ; rcx, rdx, r8
	ret 0
_dump_reg endp

dumpGPRegs proc
		@LOCAL_SIZE = 0
		saveGPRegs

		add dump_rsp, 16

		invoke _dump_reg, offset dump_rax_str, dump_rax, dump_rax, dump_rax
		invoke _dump_reg, offset dump_rbx_str, dump_rbx, dump_rbx, dump_rbx
		invoke _dump_reg, offset dump_rcx_str, dump_rcx, dump_rcx, dump_rcx
		invoke _dump_reg, offset dump_rdx_str, dump_rdx, dump_rdx, dump_rdx
		invoke _dump_reg, offset dump_rsi_str, dump_rsi, dump_rsi, dump_rsi
		invoke _dump_reg, offset dump_rdi_str, dump_rdi, dump_rdi, dump_rdi
		invoke _dump_reg, offset dump_rbp_str, dump_rbp, dump_rbp, dump_rbp
		invoke _dump_reg, offset dump_rsp_str, dump_rsp, dump_rsp, dump_rsp
		invoke _dump_reg, offset dump_r8_str,  dump_r8,  dump_r8,  dump_r8
		invoke _dump_reg, offset dump_r9_str,  dump_r9,  dump_r9,  dump_r9
		invoke _dump_reg, offset dump_r10_str, dump_r10, dump_r10, dump_r10
		invoke _dump_reg, offset dump_r11_str, dump_r11, dump_r11, dump_r11
		invoke _dump_reg, offset dump_r12_str, dump_r12, dump_r12, dump_r12
		invoke _dump_reg, offset dump_r13_str, dump_r13, dump_r13, dump_r13
		invoke _dump_reg, offset dump_r14_str, dump_r14, dump_r14, dump_r14
		invoke _dump_reg, offset dump_r15_str, dump_r15, dump_r15, dump_r15

		restoreGPRegs
		ret 0
dumpGPRegs endp

dumpXMM_PS proc
		@LOCAL_SIZE = 0
		saveXMMRegs 0, 15

		invoke puts, offset dump_xmm_ps_pre_str

		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0, qword ptr 0
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+10h, qword ptr 1
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+20h, qword ptr 2
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+30h, qword ptr 3
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+40h, qword ptr 4
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+50h, qword ptr 5
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+60h, qword ptr 6
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+70h, qword ptr 7
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+80h, qword ptr 8
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+90h, qword ptr 9
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0a0h, qword ptr 10
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0b0h, qword ptr 11
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0c0h, qword ptr 12
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0d0h, qword ptr 13
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0e0h, qword ptr 14
		invoke string_print_newline
		invoke _dump_xmm_ps, xmmword ptr dump_xmm+0f0h, qword ptr 15
		invoke string_print_newline

		restoreXMMRegs 0, 15
		ret 0
dumpXMM_PS endp

dumpXMM_PD proc
		@LOCAL_SIZE = 0
		saveXMMRegs 0, 15

		invoke puts, offset dump_xmm_pd_pre_str

		invoke _dump_xmm_pd, xmmword ptr dump_xmm, qword ptr 0
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+10h, qword ptr 1
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+20h, qword ptr 2
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+30h, qword ptr 3
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+40h, qword ptr 4
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+50h, qword ptr 5
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+60h, qword ptr 6
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+70h, qword ptr 7
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+80h, qword ptr 8
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+90h, qword ptr 9
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+0a0h, qword ptr 10
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+0b0h, qword ptr 11
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+0c0h, qword ptr 12
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+0d0h, qword ptr 13
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+0e0h, qword ptr 14
		invoke string_print_newline
		invoke _dump_xmm_pd, xmmword ptr dump_xmm+0f0h, qword ptr 15
		invoke string_print_newline

		restoreXMMRegs 0, 15
		ret 0
dumpXMM_PD endp

dumpYMM_PS proc
		ret 0
dumpYMM_PS endp

dumpYMM_PD proc
		ret 0
dumpYMM_PD endp

_dump_xmm_ps proc
		@temp0	textequ <xmmword ptr [rsp+0]>
		@LOCAL_SIZE = 1*16
        sub rsp, @LOCAL_SIZE

		movaps @temp0, xmm0

		invoke printf, offset dump_xmm_str, rdx

		movaps xmm0, @temp0
		invoke string_print_real4, xmm0, 5
		repeat 3
			invoke putchar, ' '
		endm

		movaps xmm0, @temp0
		movshdup xmm0, xmm0
		invoke string_print_real4, xmm0, 5
		repeat 3
			invoke putchar, ' '
		endm

		movaps xmm0, @temp0
		movhlps xmm0, xmm0
		invoke string_print_real4, xmm0, 5
		repeat 3
			invoke putchar, ' '
		endm

		movaps xmm0, @temp0
		shufps xmm0, xmm0, 0ffh
		invoke string_print_real4, xmm0, 5

		add rsp, @LOCAL_SIZE
		ret 0
_dump_xmm_ps endp

_dump_xmm_pd proc
		@temp0	textequ <xmmword ptr [rsp+0]>
		@LOCAL_SIZE = 1*16
        sub rsp, @LOCAL_SIZE

		movapd @temp0, xmm0

		mov rcx, offset dump_xmm_str
		invoke printf, rcx, rdx

		movapd xmm0, @temp0
		invoke string_print_real8, xmm0, 7

		invoke putchar, ' '
		invoke putchar, ' '

		movapd xmm0, @temp0
		unpckhpd xmm0, xmm0
		invoke string_print_real8, xmm0, 7

		add rsp, @LOCAL_SIZE
		ret 0
_dump_xmm_pd endp

_TEXT ends

DATA segment page read write alias("local_data")
align 32
dump_ymm	ymmword 32 dup(?)
align 16
dump_xmm	xmmword 32 dup(?)
align 8
dump_reg	qword ?
dump_rax	qword ?
dump_rbx	qword ?
dump_rcx	qword ?
dump_rdx	qword ?
dump_rsi	qword ?
dump_rdi	qword ?
dump_rbp	qword ?
dump_rsp	qword ?
dump_r8		qword ?
dump_r9		qword ?
dump_r10	qword ?
dump_r11	qword ?
dump_r12	qword ?
dump_r13	qword ?
dump_r14	qword ?
dump_r15	qword ?
DATA ends
;-----------------------------------------------------------------------------------------------------------------------
CONST segment page read alias("local_const")
dump_rax_str		byte "RAX: %08I64x %08I64x (%I64d)",13,10,0
dump_rbx_str		byte "RBX: %08I64x %08I64x (%I64d)",13,10,0
dump_rcx_str		byte "RCX: %08I64x %08I64x (%I64d)",13,10,0
dump_rdx_str		byte "RDX: %08I64x %08I64x (%I64d)",13,10,0
dump_rsi_str		byte "RSI: %08I64x %08I64x (%I64d)",13,10,0
dump_rdi_str		byte "RDI: %08I64x %08I64x (%I64d)",13,10,0
dump_rbp_str		byte "RBP: %08I64x %08I64x (%I64d)",13,10,0
dump_rsp_str		byte "RSP: %08I64x %08I64x (%I64d)",13,10,0
dump_r8_str			byte "R8:  %08I64x %08I64x (%I64d)",13,10,0
dump_r9_str			byte "R9:  %08I64x %08I64x (%I64d)",13,10,0
dump_r10_str		byte "R10: %08I64x %08I64x (%I64d)",13,10,0
dump_r11_str		byte "R11: %08I64x %08I64x (%I64d)",13,10,0
dump_r12_str		byte "R12: %08I64x %08I64x (%I64d)",13,10,0
dump_r13_str		byte "R13: %08I64x %08I64x (%I64d)",13,10,0
dump_r14_str		byte "R14: %08I64x %08I64x (%I64d)",13,10,0
dump_r15_str		byte "R15: %08I64x %08I64x (%I64d)",13,10,0
dump_xmm_ps_pre_str	byte "#######[0..31] [32..63] [64..95] [96..127]",0
dump_xmm_pd_pre_str	byte "#######[0..63] [64..127]",0
dump_ymm_ps_pre_str	byte "#######[0..31] [32..63] [64..95] [96..127]"
				    byte "[128..159] [160..191] [192..223] [224..255]",0
dump_xmm_str   		byte "[XMM%-2d] ",0
dump_ymm_str   		byte "[YMM%-2d] ",0
dump_float_str      byte "%f", 0;"%5.2f",0

CONST ends

end