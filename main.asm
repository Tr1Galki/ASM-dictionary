%include "lib.inc"
%include "dict.inc"
%include "words.inc"

%define BUFFER_SIZE 255
%define LIST_POINTER_OFFSET 8
%define ERR_LEN 46

section .bss
buff: resb BUFFER_SIZE    

section .rodata
no_key_error: db "Sorry, we don't have this key in dictionary", 10, 0


section .text

global _start

_start:
	mov rdi, buff
	mov rsi, BUFFER_SIZE
	call read_word
	
	mov rdi, rax
	lea rsi, [LIST_POINTER]
	call find_word

	cmp rax, 0
	jz .no_key_err

	lea rdi, [rax + LIST_POINTER_OFFSET]
	push rdi
	call string_length
	pop rdi

	lea rdi, [rdi+rax+1]
	call print_string
	call print_newline

	xor rdi, rdi
	jmp exit

.no_key_err:
	mov rax, 1
	mov rdi, 2
	mov rsi, no_key_error
	mov rdx, ERR_LEN
	syscall 
	jmp exit
