%include "lib.inc"

%define LIST_POINTER_OFFSET 8

global find_word

section .text

; rdi: null-terminated string's pointer
; rsi: dict's beggining pointer
; return addres of entrence or 0 if fail
find_word:
	.loop:
		mov r10, rdi
		mov r9, rsi

		add rsi, LIST_POINTER_OFFSET
		call string_equals

		mov rsi, r9
		mov rdi, r10

		cmp rax, 1
		jz .found

		mov rsi, qword [rsi]
		cmp rsi, 0
		jz .not_found

		jmp .loop

	.found:
		mov rax, rsi
		ret

	.not_found:
		xor rax, rax
		ret
