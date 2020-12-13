
save_rcx	textequ <mov [rsp+16], rcx>
save_rdx	textequ <mov [rsp+24], rdx>
save_r8		textequ <mov [rsp+32], r8>
save_r9		textequ <mov [rsp+48], r9>
restore_rcx textequ <mov rcx, [rsp+@LOCAL_SIZE+16]>
restore_rdx textequ <mov rdx, [rsp+@LOCAL_SIZE+24]>
restore_r8	textequ <mov r8, [rsp+@LOCAL_SIZE+32]>
restore_r9 	textequ <mov r9, [rsp+@LOCAL_SIZE+48]>

save_temps  macro
			save_rcx
			save_rdx
			save_r8
			save_r9
endm
restore_temps macro
			restore_rcx
			restore_rdx
			restore_r8
			restore_r9
endm
