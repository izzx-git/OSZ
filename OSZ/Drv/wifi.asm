    MODULE Wifi
bytes_avail dw 0 ;байт для приёма
buffer_pointer dw 0 ;указатель на адрес буфера
closed db 1 ;флаг "соединение закрыто"
;link_id db 0 ;текущий id соединения
buffer_end equ #40 ;ограничение буфера адрес #4000

; Initialize Wifi chip to work
init:
    ld hl, .uartIniting : call drvgmx.printZ
    call Uart.init ;
    ld hl, .chipIniting : call drvgmx.printZ
    ;EspCmdOkErr "ATE0"
	ld hl,cmd_ATE0
	call espSendZ
	call checkOkErr
    jr c, .initError

    ;EspCmdOkErr "AT+CIPSERVER=0" 
	ld hl,cmd_CIPSERVER
	call espSendZ
	call checkOkErr
    ;jr c, .initError ;не проверяем ошибку
    ;EspCmdOkErr "AT+CIPCLOSE" ;  Close if there some connection was. Don't care about result
	ld hl,cmd_CIPCLOSE
	call espSendZ
	ld a,'5' ;закрыть все соединения
	call Uart.write
    ld a, 13 : call Uart.write
    ld a, 10 : call Uart.write
	call checkOkErr	
    ;jr c, .initError ;не проверяем ошибку
    ;EspCmdOkErr "AT+CIPMUX=0" ; Single connection mode
	ld hl,cmd_CIPMUX
	call espSendZ
	call checkOkErr	
    jr c, .initError
    
    ;EspCmdOkErr "AT+CIPDINFO=0" ; Disable additional info
	ld hl,cmd_CIPDINFO
	call espSendZ
	call checkOkErr		
    jr c, .initError

    ld hl, .doneInit : call drvgmx.printZ
    
    or a
    ret
.initError
    ld hl, .errMsg : call drvgmx.printZ
    scf
    ret
.errMsg db "WiFi chip init failed!",13,0
.uartIniting db "Uart initing...",13,0
.chipIniting db "Chip initing...",13,0
.doneInit    db "Done!",13,0
    IFNDEF PROXY   
; HL - host pointer in gopher row
; DE - port pointer in gopher row
openTCP:
    push de
    push hl
    ;EspCmdOkErr "AT+CIPCLOSE" ; Don't care about result. Just close if it didn't happens before
	ld hl,cmd_CIPCLOSE
	call espSendZ
	; ld a,(link_id)
	; call Uart.write	
    ld a, 13 : call Uart.write
    ld a, 10 : call Uart.write
	call checkOkErr	
	
    ;EspSend 'AT+CIPSTART,"TCP","' ;
	ld hl,cmd_CIPSTART
	call espSendZ
	; ld a,(link_id)
	; call Uart.write	
	; ld hl,cmd_CIPSTART2
	; call espSendZ

	
    pop hl
    call espSendT
    ;EspSend '",'
    ld a, '"' : call Uart.write
    ld a, ',' : call Uart.write	
    pop hl
    call espSendT
    ld a, 13 : call Uart.write
    ld a, 10 : call Uart.write
    xor a : ld (closed), a
    jp checkOkErr

continue:
    ret
    ENDIF



checkOkErr:
    call Uart.read
    cp 'O' : jr z, .okStart ; OK
    cp 'E' : jr z, .errStart ; ERROR
    cp 'F' : jr z, .failStart ; FAIL
    jr checkOkErr
.okStart
    call Uart.read : cp 'K' : jr nz, checkOkErr
    call Uart.read : cp 13  : jr nz, checkOkErr
    call .flushToLF
    or a
    ret
.errStart
    call Uart.read : cp 'R' : jr nz, checkOkErr
    call Uart.read : cp 'R' : jr nz, checkOkErr
    call Uart.read : cp 'O' : jr nz, checkOkErr
    call Uart.read : cp 'R' : jr nz, checkOkErr
    call .flushToLF
    scf 
    ret 
.failStart
    call Uart.read : cp 'A' : jr nz, checkOkErr
    call Uart.read : cp 'I' : jr nz, checkOkErr
    call Uart.read : cp 'L' : jr nz, checkOkErr
    call .flushToLF
    scf
    ret
.flushToLF
    call Uart.read
    cp 10 : jr nz, .flushToLF
    ret

; Send buffer to UART
; HL - buff
; E - count
; espSend:
    ; ld a, (hl) : call Uart.write
    ; inc hl 
    ; dec e
    ; jr nz, espSend
    ; ret
	
; Send buffer to UART
; HL - buff (0 - end!)
espSendZ:
    ld a, (hl) 
	or a
	ret z
	call Uart.write
    inc hl 
    jr espSendZ


; HL - string that ends with one of the terminator(CR/LF/TAB/NULL)
espSendT:
    ld a, (hl) 

    and a : ret z
    cp 9 : ret z 
    cp 13 : ret z
    cp 10 : ret z
    
    call Uart.write
    inc hl 
    jr espSendT

; HL - stringZ to send
; Adds CR LF
; tcpSendZ:
    ; push hl
    ; ;EspSend "AT+CIPSEND=" ;
	; ld hl,cmd_CIPSEND
	; call espSendZ
	; ; ld a,(link_id)
	; ; call Uart.write	
    ; ;ld a, ',' : call Uart.write
	
    ; pop de : push de
    ; call strLen
    ; inc hl : inc hl ; +CRLF
    ; call hlToNumEsp
    ; ld a, 13 : call Uart.write
    ; ld a, 10 : call Uart.write
    ; call checkOkErr : jr c,.exit_err
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
; .exit_err
	; pop hl
	; ret



; HL - string to send
; DE - lenght
; Adds CR LF
tcpSend:
    push hl
	push de ;
    ;EspSend "AT+CIPSEND=" ;
	ld hl,cmd_CIPSEND
	call espSendZ
	; ld a,(link_id)
	; call Uart.write	
    ;ld a, ',' : call Uart.write
	
    pop hl : push hl ;длина
    ;call strLen
    inc hl : inc hl ; +CRLF
    call hlToNumEsp
    ld a, 13 : call Uart.write
    ld a, 10 : call Uart.write
    call checkOkErr : jr c,.exit_err2
.wait2
    call Uart.read : cp '>' : jr nz, .wait2
	pop de ;длина
    pop hl
.loop2
    ld a, (hl)
    call Uart.write
    inc hl
	dec de
	ld a,d
	or e
    jp nz, .loop2
.exit2
    ld a, 13 : call Uart.write
    ld a, 10 : call Uart.write
    jp checkOkErr
.exit_err2
	pop de
	pop hl
	ret
	
	
	

getPacket:
    call Uart.read
    cp '+' : jr z, .ipdBegun    ; "+IPD," packet 
    cp 'O' : jr z, .closedBegun ; It enough to check "OSED\n" :-)
    jr getPacket
.closedBegun
    call Uart.read : cp 'S' : jr nz, getPacket
    call Uart.read : cp 'E' : jr nz, getPacket
    call Uart.read : cp 'D' : jr nz, getPacket
    call Uart.read : cp 13 : jr nz, getPacket
    ld a, 1, (closed), a
    ret
.ipdBegun
    call Uart.read : cp 'I' : jr nz, getPacket
    call Uart.read : cp 'P' : jr nz, getPacket
    call Uart.read : cp 'D' : jr nz, getPacket
    call Uart.read ; Comma 
	; call Uart.read ; link ID
	; ld (link_id),a ;запомнить
	;call Uart.read ; Comma
    call .count_ipd_lenght : ld (bytes_avail), hl 
    ld bc, hl
    ld hl, (buffer_pointer)
.readp
    ld a, h : cp buffer_end : jr nc, .skipbuff ;
    push bc, hl
    call Uart.read
    pop hl, bc
    ld (hl), a
    dec bc : inc hl
    ld a, b : or c : jr nz, .readp
    ld (buffer_pointer), hl
    ret
.skipbuff 
    push bc
    call Uart.read
    pop bc
    dec bc : ld a, b : or c : jr nz, .skipbuff
    ret
.count_ipd_lenght
		ld hl,0			; count lenght
.cil1	push  hl
        call Uart.read
        pop hl 
		cp ':' : ret z
		sub 0x30 : ld c,l : ld b,h : add hl,hl : add hl,hl : add hl,bc : add hl,hl : ld c,a : ld b,0 : add hl,bc
		jr .cil1

; Based on: https://wikiti.brandonw.net/index.php?title=Z80_Routines:Other:DispHL
; HL - number
; It will be written to UART
hlToNumEsp:
	ld	bc,-10000
	call	.n1
	ld	bc,-1000
	call	.n1
	ld	bc,-100
	call	.n1
	ld	c,-10
	call	.n1
	ld	c,-1
.n1	ld	a,'0'-1
.n2	inc	a
	add	hl,bc
	jr	c, .n2
	sbc	hl,bc
    push bc
	call Uart.write
    pop bc
    ret
	

;команды	
cmd_ATE0 db "ATE0",13,10,0 ;эхо?
cmd_CIPSERVER db "AT+CIPSERVER=0",13,10,0 ;удалить сервер
cmd_CIPSTART db 'AT+CIPSTART="' ;продолжение
	;тут тип
cmd_CIPSTART2 db 'TCP","',0 ;продолжение
cmd_CIPSEND db "AT+CIPSEND=",0 ;отправить данные
	;тут ID
cmd_CIPCLOSE db "AT+CIPCLOSE",0 ;закрыть соединение
	;тут ID
cmd_CIPMUX db "AT+CIPMUX=0",13,10,0 ; Single connection mode
cmd_CIPDINFO db "AT+CIPDINFO=0",13,10,0 ; Disable additional info

    ENDMODULE