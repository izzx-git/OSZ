    MODULE Wifi
bytes_avail dw 0
buffer_pointer dw 0
closed db 1
;link_id db 0;
wait_count equ 5*50 ; ожидание в кадрах
buffer_top equ #fa;ограничение буфера сверху #ffff - 1500
; ; Initialize Wifi chip to work
;init:
	;ld hl,uartGetID : call TextMode.printZ
; init1:
	; halt
	; xor a ;CY=0
	; OS_ESP_LINK_ID ;получить номер соединения
	; jr c,init1:
	; ld (link_id),a
	;ret
    ; ; ld hl, .uartIniting : call TextMode.printZ
    ; ; call Uart.init
    ; ld hl, .chipIniting : call TextMode.printZ
    ; EspCmdOkErr "ATE0"
    ; jr c, .initError

    ; EspCmdOkErr "AT+CIPSERVER=0" 
    ; EspCmdOkErr "AT+CIPCLOSE" ; Close if there some connection was. Don't care about result
    ; EspCmdOkErr "AT+CIPMUX=0" ; Single connection mode
    ; jr c, .initError
    
    ; EspCmdOkErr "AT+CIPDINFO=0" ; Disable additional info
    ; jr c, .initError

    ; ld hl, .doneInit : call TextMode.printZ
    
    ; or a
    ; ret
; .initError
    ; ld hl, .errMsg : call DialogBox.msgBox
    ; scf
    ; ret
; .errMsg db "WiFi chip init failed!",0
;.uartIniting db "Uart initing...",13,0
;uartGetID db "Get link ID...",13,0
; .chipIniting db "Chip initing...",13,0
; .doneInit    db "Done!",0
    ; IFNDEF PROXY   
; ; HL - host pointer in gopher row
; ; DE - port pointer in gopher row
openTCP:
	;ld a,(link_id)
	OS_ESP_CLOSE ;если уже пытались раньше, то закрыть
	
	ld b,wait_count ; пробуем открыть
openTCP_wait1
	OS_WAIT
	push bc
	xor a ;TCP
	OS_ESP_OPEN
	pop bc
	jr nc,openTCP_wait1_ok
	djnz openTCP_wait1
	ret ;не удалось, наверное очередь
openTCP_wait1_ok	
	
	;или подождём открытия
	ld b,wait_count ;
openTCP_wait
	OS_WAIT
	ld a,(ix+2) ;флаг
	rlca
	ret c ;если ошибка (=255)
	or a
	jr nz,openTCP_wait_skip
	djnz openTCP_wait
	scf
	ret
openTCP_wait_skip
	ld a,(ix+2) ;флаг
	xor 1 
	ld (closed), a
	or a ;успешно
	ret



    ; push de
    ; push hl
    ; EspCmdOkErr "AT+CIPCLOSE" ; Don't care about result. Just close if it didn't happens before
    ; EspSend 'AT+CIPSTART="TCP","'
    ; pop hl
    ; call espSendT
    ; EspSend '",'
    ; pop hl
    ; call espSendT
    ; ld a, 13 : call Uart.write
    ; ld a, 10 : call Uart.write
    ; xor a : ld (closed), a
    ; jp checkOkErr

; continue:
    ; ret
    ; ENDIF



; checkOkErr:
    ; call Uart.read
    ; cp 'O' : jr z, .okStart ; OK
    ; cp 'E' : jr z, .errStart ; ERROR
    ; cp 'F' : jr z, .failStart ; FAIL
    ; jr checkOkErr
; .okStart
    ; call Uart.read : cp 'K' : jr nz, checkOkErr
    ; call Uart.read : cp 13  : jr nz, checkOkErr
    ; call .flushToLF
    ; or a
    ; ret
; .errStart
    ; call Uart.read : cp 'R' : jr nz, checkOkErr
    ; call Uart.read : cp 'R' : jr nz, checkOkErr
    ; call Uart.read : cp 'O' : jr nz, checkOkErr
    ; call Uart.read : cp 'R' : jr nz, checkOkErr
    ; call .flushToLF
    ; scf 
    ; ret 
; .failStart
    ; call Uart.read : cp 'A' : jr nz, checkOkErr
    ; call Uart.read : cp 'I' : jr nz, checkOkErr
    ; call Uart.read : cp 'L' : jr nz, checkOkErr
    ; call .flushToLF
    ; scf
    ; ret
; .flushToLF
    ; call Uart.read
    ; cp 10 : jr nz, .flushToLF
    ; ret

; ; Send buffer to UART
; ; HL - buff
; ; E - count
; espSend:
    ; ld a, (hl) : call Uart.write
    ; inc hl 
    ; dec e
    ; jr nz, espSend
    ; ret

; ; HL - string that ends with one of the terminator(CR/LF/TAB/NULL)
; espSendT:
    ; ld a, (hl) 

    ; and a : ret z
    ; cp 9 : ret z 
    ; cp 13 : ret z
    ; cp 10 : ret z
    
    ; call Uart.write
    ; inc hl 
    ; jr espSendT

; ; HL - stringZ to send
; ; Adds CR LF
tcpSendZ:
	push hl
	ex de,hl
	call strLen ;узнать длину
	ex de,hl
	pop hl ;буфер
	push hl
	add hl,de ;добавить в конце 13 и 10
	ld (hl),13
	inc hl
	ld (hl),10
	pop hl
	inc de ;увеличить длину
	inc de
	
	;call Wifi.tcpSendZ ;послать запрос
	;ld a,(link_id)	
	OS_ESP_SEND 
	;ret c ;сразу не удалось (может, очередь)
	;ждём когда запрос пройдёт
	;ld b,wait_count ;
tcpSendZ_wait1 ;бесконечно ждём
	OS_WAIT
	ld a,(ix+4) ;флаг
	cp 1
	jr nz,tcpSendZ_wait1
	or a
	ret

	
    ; push hl
    ; EspSend "AT+CIPSEND="
    ; pop de : push de
    ; call strLen
    ; inc hl : inc hl ; +CRLF
    ; call hlToNumEsp
    ; ld a, 13 : call Uart.write
    ; ld a, 10 : call Uart.write
    ; call checkOkErr : ret c
; .wait
    ; call Uart.read : cp '>' : jr nz, .wait
    ; pop hl
; .loop
    ; ld a, (hl) : and a : jr z, .exit
    ; call Uart.write
    ; inc hl
    ; jp .loop
; .exit
    ; ld a, 13 : call Uart.write
    ; ld a, 10 : call Uart.write
    ; jp checkOkErr

;вх: hl - адрес буфера
getPacket:
	;переделано под ОС
	ld a,h
	cp buffer_top ;ограничение буфера
	jr c,getPacket_skip_over ; ниже ограничения грузим
	ld a,1 ;или прекращаем
	ld (closed),a ;флаг закрытия
	ld hl,0
	ld (bytes_avail), hl	
	OS_ESP_CLOSE ;освободить очередь
	scf
	ret
getPacket_skip_over

	;ld a,(link_id)	
	OS_ESP_GET
	; ret c ;сразу не удалось (может, очередь)
	; ld b,wait_count ;
getPacket_wait1
	OS_WAIT
	ld a,(ix+6) ;флаг результат приёма
	; rlca
	; ret c ;если ошибка (=255)
	cp 1
	jr nz,getPacket_wait1	


;getPacket_wait1_skip
	ld hl,(buffer_pointer)
	ld c,(ix+9) ; длина принятого
	ld b,(ix+10)
	ld (bytes_avail), bc	
	add hl,bc
	ld (buffer_pointer),hl ;продолжить загружать с этого места
	
	ld a,(ix+2) ;!!! closed
	xor 1
	ld (closed),a ;флаг закрытия
	jr z,getPacket_ex
	OS_ESP_CLOSE ;освободить очередь
getPacket_ex
	or a
	ret


    ; call Uart.read
    ; cp '+' : jr z, .ipdBegun    ; "+IPD," packet 
    ; cp 'O' : jr z, .closedBegun ; It enough to check "OSED\n" :-)
    ; jr getPacket
; .closedBegun
    ; call Uart.read : cp 'S' : jr nz, getPacket
    ; call Uart.read : cp 'E' : jr nz, getPacket
    ; call Uart.read : cp 'D' : jr nz, getPacket
    ; call Uart.read : cp 13 : jr nz, getPacket
    ; ld a, 1, (closed), a
    ; ret
; .ipdBegun
    ; call Uart.read : cp 'I' : jr nz, getPacket
    ; call Uart.read : cp 'P' : jr nz, getPacket
    ; call Uart.read : cp 'D' : jr nz, getPacket
    ; call Uart.read ; Comma
    ; call .count_ipd_lenght : ld (bytes_avail), hl 
    ; ld bc, hl
    ; ld hl, (buffer_pointer)
; .readp
    ; ld a, h : cp #ff : jr nc, .skipbuff
    ; push bc, hl
    ; call Uart.read
    ; pop hl, bc
    ; ld (hl), a
    ; dec bc : inc hl
    ; ld a, b : or c : jr nz, .readp
    ; ld (buffer_pointer), hl
    ; ret
; .skipbuff 
    ; push bc
    ; call Uart.read
    ; pop bc
    ; dec bc : ld a, b : or c : jr nz, .skipbuff
    ; ret
; .count_ipd_lenght
		; ld hl,0			; count lenght
; .cil1	push  hl
        ; call Uart.read
        ; pop hl 
		; cp ':' : ret z
		; sub 0x30 : ld c,l : ld b,h : add hl,hl : add hl,hl : add hl,bc : add hl,hl : ld c,a : ld b,0 : add hl,bc
		; jr .cil1

; ; Based on: https://wikiti.brandonw.net/index.php?title=Z80_Routines:Other:DispHL
; ; HL - number
; ; It will be written to UART
; hlToNumEsp:
	; ld	bc,-10000
	; call	.n1
	; ld	bc,-1000
	; call	.n1
	; ld	bc,-100
	; call	.n1
	; ld	c,-10
	; call	.n1
	; ld	c,-1
; .n1	ld	a,'0'-1
; .n2	inc	a
	; add	hl,bc
	; jr	c, .n2
	; sbc	hl,bc
    ; push bc
	; call Uart.write
    ; pop bc
    ; ret

    ENDMODULE