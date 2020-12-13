; MSVC 64bit calling convention:
;	Parameter passing:
;
;   arg1 arg2 arg3 arg4
;----------------------------------------
;	ecx	 rdx  r8   r9		 	for int
;	xmm0 xmm1 xmm2 xmm3			for float/double
;
; Parameters less than 64 bits long are not zero extended; the high bits contain garbage.
; rax or xmm0 hold return value
;
; Callee scratch registers:
;  	rax, rcx, rdx, r8, r9, r10, r11
;	xmm0 - xmm5
;
; NOTES:
; 	1) always use ret 0 instead of ret
;

include		defines.asm
include 	prototypes.asm
include 	macros.asm
include 	invoke.asm
