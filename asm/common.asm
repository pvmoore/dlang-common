

;CHECK_STACK_ALIGNMENT = 1

include inc/includes.asm

_TEXT segment

asm_test proc
    invoke puts, offset blahStr
    ; push rcx
    ; sub rsp, 32
    ; mov rcx, offset blahStr
    ; call puts
    ; add rsp, 32
    ; pop rcx

    movss xmm3, _7
    movss xmm0, _err
    invoke dumpXMM_PS

    movapd xmm2, _8_pd
    invoke dumpXMM_PD

    mov rcx, 123456
    invoke dumpGPRegs

    ret 0
asm_test endp

_TEXT	ENDS


CONST	segment page read alias("local_const")
dd_false	dd 0
dd_true		dd 1
blahStr     byte "hello there4", 0
CONST	ends


DATA 	segment page read write alias("local_data")
;monitor_mem dq 0
;caps		Blah <0,0>
;vendorStr	byte 12 dup(?), 0


align 16
_7	        real4 -567.123, 2.0, 3.0, 4.0
_8          real4 0.33333,  -0.66666,  0.66666,  0.0
_err        real4 -0.0015
align 16
_8_pd       real8 8.0, 123.321
DATA	ends

end