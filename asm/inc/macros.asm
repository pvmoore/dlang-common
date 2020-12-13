; MACRO OPERATORS:
; 	&	Text substitution operator
; 	< >	Literal text operator
; 	!	Literal character operator
; 	%	Expression operator
;	;;	Macro comment

MyPrologue macro procname, flags, argbytes, localbytes, reglist, userparms:vararg
		;; align stack on 16 byte boundary
		sub rsp, 8
		exitm <0>
endm
MyEpilogue macro procname, flags, argbytes, localbytes, reglist, userparms:vararg
		;; undo stack alignment
		add rsp, 8
endm

;option	prologue:PrologueDef
;option epilogue:EpilogueDef
option	prologue:MyPrologue
option 	epilogue:MyEpilogue

count_varargs macro args:vararg
	LOCAL count
	count = 0
	for arg,<args>
		count = count + 1
	endm
	exitm count
endm

isxmmreg macro reg
    if @InStr(1, <reg>, <xmm>) == 1
        exitm 1
    endif
    exitm 0
endm

isgeneralreg macro reg
    if @InStr(1, reg, rax) OR @InStr(1, reg, rbx) OR @InStr(1, reg, rcx) OR @InStr(1, reg, rdx) OR @InStr(1, reg, rbp) OR @InStr(1, reg, rsp) OR @InStr(1, reg, rsi) OR @InStr(1, reg, rdi) OR @InStr(1, reg, r8) OR @InStr(1, reg, r9) OR @InStr(1, reg, r10) OR @InStr(1, reg, r11) OR @InStr(1, reg, r12) OR @InStr(1, reg, r13) OR @InStr(1, reg, r14) OR @InStr(1, reg, r15)
        echo true
        exitm 1
    else
        echo false
        exitm 0
    endif
endm
