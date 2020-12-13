
_assert_stack_align16 macro
		ifdef CHECK_STACK_ALIGNMENT
		test rsp, 0fh
		jz @f
			;; the stack is unaligned at this point
			push rcx
			sub rsp, 32
			mov rcx, offset stack_align_msg
			call puts
			add rsp, 32
			pop rcx
@@:
		endif
endm

_invoke_arg macro bytereg, wordreg, dwordreg, qwordreg, xmmreg, ymmreg, arg

		ifnb <arg>
			if @InStr(1, &arg, <offset>)
				mov &qwordreg, arg
			elseif @InStr(1, &arg, <byte>)
				ifdif <%arg>, <%bytereg>
					mov &bytereg, arg
				endif
			elseif @InStr(1, &arg, <dword>)
				ifdif <%arg>, <%dwordreg>
					mov &dwordreg, arg
				endif
			elseif @InStr(1, &arg, <qword>)
				ifdif <%arg>, <%qwordreg>
					mov &qwordreg, arg
				endif
			elseif @InStr(1, &arg, <xmm>)
				ifdif <%arg>, <%xmmreg>
					movaps &xmmreg, arg
					;movdqa &xmmreg, arg
				endif
			elseif @InStr(1, &arg, <ymm>)
				ifdif <%arg>, <%ymmreg>
					movdqa &ymmreg, arg
				endif
			elseif @InStr(1, &arg, <word>)
				ifdif <%arg>, <%wordreg>
					mov &wordreg, arg
				endif
			else
				ifdif <%arg>, <%qwordreg>
					mov &qwordreg, arg
				endif
			endif
		endif
endm

invoke 	macro funcname:req, p1, p2, p3, p4, stackargs:vararg
		LOCAL count
		;; count stack args
		count = 0
		for stkarg,<stackargs>
			count = count + 1
		endm

		_invoke_arg cl, cx, ecx, rcx, xmm0, ymm0, p1
		_invoke_arg dl, dx, edx, rdx, xmm1, ymm1, p2
		_invoke_arg r8b, r8w, r8d, r8, xmm2, ymm2, p3
		_invoke_arg r9b, r9w, r9d, r9, xmm3, ymm3, p4

		;; if num stack args is odd then push an extra one to align the stack to 16 bytes
		if (count and 1)
			sub rsp, 8
			count = count + 1
		endif

		;; push remaining args on the stack (this won't work for literals or offsets > 32 bits)
		for stkarg,<stackargs>
			push stkarg
		endm

		;; allocate shadow space for rcx,rdx,r8,r9
		sub rsp, 32

		;; assert that the stack is aligned to 16 bytes before we call the function
		_assert_stack_align16

		;; call the function
		call &funcname&

		;; calculate stack adjustment
		count = 32 + (count*8)

		;; fix the stack
		add rsp, count
endm

CONST			segment page read alias("local_const")
stack_align_msg	byte "Stack alignment error",0
CONST			ends