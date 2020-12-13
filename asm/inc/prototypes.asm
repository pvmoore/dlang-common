
; c library
printf			proto		:qword, :vararg	; int printf ( const char * format, ... );
puts 			proto 		:qword			; int puts ( const char * str );
putchar			proto		:dword			; int putchar ( int character );

; string
string_print_newline	proto
string_print_qword		proto :qword
string_print_real4		proto :real4, :dword
string_print_real8		proto :real8, :dword
string_print_bool		proto :qword

; dump
dumpGPRegs  proto
dumpXMM_PS	proto
dumpXMM_PD	proto
dumpYMM_PS	proto
dumpYMM_PD	proto
