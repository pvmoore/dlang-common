
include inc/includes.asm

_TEXT segment

string_print_newline proc
		invoke putchar, byte ptr 13
		invoke putchar, byte ptr 10
		ret 0
string_print_newline endp

string_print_qword	proc value:qword
			mov rdx, rcx
			invoke printf, offset printf_qword_str, rdx
			ret 0
string_print_qword	endp

string_print_bool	proc value:qword
			test rcx, rcx
			jz __false
				mov rdx, offset true_str
				jmp __printf
__false:	mov rdx, offset false_str
__printf:	invoke printf, offset printf_string_str, rdx
			ret 0
string_print_bool	endp

; eg 12345.54321
string_print_real4 proc value:real4, dps:dword
	; xmm0[0..31]	= value
	; edx			= dps
	cvtss2sd xmm0, xmm0
	invoke string_print_real8, xmm0, rdx
    ret 0
string_print_real4 endp

; 12345.54321
string_print_real8 proc value:real8, dps:dword
	; xmm0[0..63]	= value
	; edx 			= dps
@temp_qword	textequ <qword ptr [rsp+0]>
@temp_real8	textequ <real8 ptr [rsp+16]>
@LOCAL_SIZE = 16*2
			save_rdx
            sub rsp, @LOCAL_SIZE

            xorpd xmm1, xmm1	; xmm1 = (real8) [0, 0]
            movsd xmm1, xmm0	; xmm1 = (real8) [0, 12345.54321]

            movmskpd eax, xmm1
			test eax, 1
			jz __pos
				mulsd xmm1, _minus_1		; xmm1 = -xmm1
				movsd @temp_real8, xmm1
      			invoke putchar, byte ptr '-'
      			movsd xmm1, @temp_real8
__pos:
			; xmm1 = abs(value)

			; xmm0 = qword trunc(xmm1)
			cvttpd2dq xmm0, xmm1			; xmm0 = qword 12345
			movsd @temp_qword, xmm0

			cvtdq2pd xmm0, xmm0				; xmm0 = real8 12345
			subsd xmm1, xmm0				; xmm1 = (real8)[0, 0.54321]
			movsd @temp_real8, xmm1

            invoke printf, offset printf_qword_str, qword ptr @temp_qword

            restore_rdx
            test rdx, rdx
			jz __end

            invoke putchar, byte ptr '.'
			restore_rdx
@@:
			movsd xmm0, @temp_real8
			mulsd xmm0, _10
			movsd xmm1, xmm0

			; truncate xmm0
			cvttpd2dq xmm0, xmm0
			movq rax, xmm0
			cvtdq2pd xmm0, xmm0

			subpd xmm1, xmm0
			movsd @temp_real8, xmm1

			add rax, '0'

			push rdx
			invoke putchar, byte ptr al
			pop rdx
			dec rdx
			jne @b
__end:
            add rsp, @LOCAL_SIZE
            ret 0
string_print_real8 endp

_TEXT ends

CONST segment page read alias("local_const")
align 16
_minus_1			real8 -1.0
align 16
_10                 real8 10.0

align 8
printf_dword_str	byte "%d",0
align 8
printf_qword_str	byte "%I64d",0
align 8
printf_real4_str	byte "%f",0
align 8
printf_real8_str	byte "%g",0
align 8
printf_string_str	byte "%s",0
align 8
true_str			byte "true",0
align 8
false_str			byte "false",0
CONST ends

end