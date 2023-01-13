section .text
 
global exit
global string_length
global print_string
global print_error
global print_newline
global print_char
global print_int
global print_uint
global string_equals
global read_char
global read_word
global parse_uint
global parse_int
global string_copy

%define SYS_EXIT 60
 
; Принимает код возврата и завершает текущий процесс
exit:
    mov rax, SYS_EXIT
    syscall
    ret 


; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax

    .loop:
        cmp byte[rdi], 0
        jz .exit
        inc rax
        inc rdi
        jmp .loop

    .exit:
        ret


; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    mov rax, 1
    mov rdx, 1
    mov rsi, rdi
    mov rdi, 1

    .loop:
        cmp byte[rsi], 0
        jz .exit
        syscall
        inc rsi
        jmp .loop

    .exit:
        ret


; Принимает код символа и выводит его в stdout
print_char:
    mov rax, 1
    push rdi
    mov rsi, rsp
    pop rdi
    mov rdi, 1
    mov rdx, 1
    syscall
    ret


; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, '\n'
    jmp print_char



; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    mov rax, rdi
    mov rcx, 0xA
    mov r9, 1
    .dec_loop:
        cmp rax, 0xA
        jb .to_out_loop
        inc r9
        xor rdx, rdx
        div rcx
        push rdx
        jmp .dec_loop
    
    .to_out_loop:
        push rax
    
    .out_loop:
        dec r9
        pop rdi
        add rdi, 0x30
        call print_char
        cmp r9, 0
        jz .exit
        jmp .out_loop
    
    .exit:
        ret



; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    cmp rdi, 0
    jl .if_sign
    
    .exit:
        jmp print_uint

    .if_sign:
        push rdi
        mov rdi, 0x2D
        call print_char
        pop rdi
        neg rdi
        jmp .exit



; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    .loop:
        mov al, [rsi]
        cmp [rdi], al
        jnz .strNotEqual
        cmp byte[rdi], 0x0
        jz  .strEqual
        inc rdi
        inc rsi
        jmp .loop

    .strEqual:
        mov rax, 1
        ret

    .strNotEqual:
        mov rax, 0
        ret


; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    xor rax, rax
    xor rdi, rdi
    mov rdx, 1
    push 0
    mov rsi, rsp
    syscall
    pop rax
    ret 


; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При   успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор


read_word:
    push rdi
    xor rcx, rcx

    .loop:
        push rdi;   аддрес
        push rsi;   размер
        push rcx
        call read_char
        pop rcx
        pop rsi
        pop rdi
        cmp rax, 0
        jz .exit_end
        cmp rcx, 0 
        jnz  .middle

        .first:
            cmp rax, ' '
            jz  .loop
            cmp rax, '	'
            jz  .loop
            cmp rax, '\n'
            jz  .loop

        .middle:
            cmp rax, ' '
            jz  .exit_end
            cmp rax, '	'
            jz  .exit_end
            cmp rax, '\n'
            jz  .exit_end

        .length:
            cmp rcx, rsi
            jz .exit_len
            mov [rdi+rcx], rax
            inc rcx
            jmp .loop

    .exit_end:
        mov byte[rdi+rcx], 0
        mov rdx, rcx
        pop rax
        ret

    .exit_len:
        pop rax
        mov rdx, rcx
        xor rax, rax
        ret
 

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax
    xor rcx, rcx
    mov r8, 10

    .loop:
        movzx r9, byte[rdi+rcx]
        cmp r9, '0'
        jb .exit
        cmp r9, '9'
        ja .exit
        mul r8
        add rax, r9
        sub rax, 0x30
        inc rcx
        jmp .loop

    .exit:
        mov rdx, rcx
        ret



; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rax, rax
    xor rdx, rdx
    cmp byte[rdi], '-'
    jnz parse_uint 
    inc rdi
    call parse_uint
    neg rax
    inc rdx
    ret


; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    xor rcx, rcx
    .loop:
        cmp rcx, rdx
        jge .len_problem
        mov al, [rdi+rcx]
        mov [rsi+rcx], al
        test al, al
        jz .exit
        inc rcx
        jmp .loop

    .len_problem:
        xor rcx, rcx
    .exit:
        mov rax, rcx
        ret

