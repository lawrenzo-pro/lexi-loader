org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;magic stuff
jmp short start
nop
;more magic
bdb_oem:    db 'MSWIN4.1' 
bdb_bytes_per_sector:   dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors:   dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0E0h
bdb_total_sectors:  dw 2880
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat:    dw 9
bdb_sectors_per_track:  dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sector_count:     dd 0
;the magic is almost ending
ebr_drive_number: db 0
                  db 0
ebr_signature: db 29h
ebr_volume_id: db 12h, 34h, 56h, 78h 
ebr_volume_label: db 'LEXI   '
ebr_system_id: db 'FAT12   '

;end magic
start:
    jmp main
;ds:si points to string
puts:
    push si
    push ax
    push bx
.loop:
    lodsb
    or al, al

    jz .done
    mov ah, 0x0E

    mov bh, 0
    int 0x10
    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret
main:
   ; setup data segments
   mov ax, 0
   mov ds, ax
   mov es, ax

   ; setup stack
   mov ss, ax
   mov sp, 0x7C00
   ;magic
   mov [ebr_drive_number], dl
   mov ax, 1
   mov cl, 1
   mov bx, 0x7E00
   call disk_read

   ;more magic
   mov si, message
   call puts

   ;halt
   cli ;ignore all interrupts
   hlt
;Messed up? what's next?
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot
wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0
;the computer shouldn't get here, but if it does let's make it stop
.halt:
    cli
    hlt

;magic routines
lba_to_chs:
    push ax
    push dx

    xor dx,dx
    div word [bdb_sectors_per_track]

    inc cx
    mov cx,dx

    xor dx,dx
    div word [bdb_heads]

    mov dh,dl
    mov ch,al
    shl ah,6
    or cl,ah

    pop ax
    mov dl,al
    pop ax
    ret
disk_read:
    ;lets push stuff
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call lba_to_chs
    pop ax

    mov ah, 02h
    mov di, 3
.retry:
    pusha
    stc
    int 13h
    jnc .done

    ;we failed? What's next?
    popa
    call dish_reset

    dec di
    test di,di
    jnz .retry
.fail:
    jmp floppy_error
.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dish_reset:
    pusha
    mov ah,0
    stc
    int 13h
    jc floppy_error
    popa
    ret
;strings
message: db 'Hi There !',ENDL ,0
msg_read_failed: db 'An error occured when trying to read the disk!', ENDL, 0
;the magic ends
times 510-($-$$) db 0
dw 0AA55h
