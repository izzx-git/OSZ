; This driver works with 16c550 uart that's support AFE
    module Uart
; Make init shorter and readable:-)
    macro outp port, value
	ld b, port
	ld c, #EF
    ld a, value
    out (c), a
    endm

; Internal port constants
RBR_THR = #F8
IER     = RBR_THR + 1
IIR_FCR = RBR_THR + 2
LCR     = RBR_THR + 3
MCR     = RBR_THR + 4
LSR     = RBR_THR + 5
MSR     = RBR_THR + 6
SR      = RBR_THR + 7


;out: a=255 - no UART
check: ;проверка есть ли карта
	ld a, RBR_THR	
    in a, (#fe)
	cp #ff
	ret nz ;если читает 255, то нет карты
	ld a, RBR_THR	
    in a, (#fe) ;второй раз для надёжности
	cp #ff
	ret
	
	
init:
    outp MCR,     #0d  // Assert RTS
    outp IIR_FCR, #87  // Enable fifo 8 level, and clear it
    outp LCR,     #83  // 8n1, DLAB=1
    outp RBR_THR, #01  // 115200 (divider 1)
    outp IER,     #00  // (divider 0). Divider is 16 bit, so we get (#0002 divider)

    outp LCR,     #03 // 8n1, DLAB=0
    outp IER,     #00 // Disable int
    outp MCR,     #2f // Enable AFE
    ret
	
;retry_rec_count_max equ %00011111 ;ждать столько прерываний
    
; Flag C <- Data available
; isAvailable:
    ; ld a, LSR
    ; in a, (#EF)
    ; rrca
    ; ret

; Non-blocking read
; Flag C <- is byte was readen
; A <- byte
; read1:
    ; ld a, LSR
    ; in a, (#EF)
    ; rrca
    ; ret nc
    ; ld a, RBR_THR	
    ; in a, (#EF)
    ; scf 
    ; ret

; Tries read byte with timeout
; Flag C <- is byte read
; A <- byte
read:
	;xor a ;4
	;ld (#5C78),a ;обнулить счётчик ожидания ;13
.wait
    ld a, LSR
    in a, (#EF)
    rrca
	jr nc, .wait
    ld a, RBR_THR	
    in a, (#EF)
	ret	
; .readW	
	; OS_GETTIMER
	; ld a,e
	; and retry_rec_count_max
	; ;ld a,(#5C78)
	; ;cp retry_rec_count_max
	; jr nz, .wait ;ещё попытка
	; xor a ;выключим флаг переноса если время вышло
	; ret
	
	
	

; Blocking read
; A <- Byte
; readB:
    ; ld a, LSR
    ; in a, (#EF)
    ; rrca
    ; jr nc, readB
	; ld a, RBR_THR
    ; in a, (#EF)
    ; ret

; A -> byte to send
write:
    push af
.wait
	ld a, LSR
    in a, (#EF)
    and #20
    jr z, .wait
    pop af
	ld b, RBR_THR
	ld c, #EF	
    out (c), a
    ret

    endmodule