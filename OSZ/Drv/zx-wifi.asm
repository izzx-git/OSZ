; This driver works with 16c550 uart that's support AFE
    module Uart
; Make init shorter and readable:-)
    macro outp port, value
	ld b, port
	ld c, #ef
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

chek: ;проверка есть ли карта
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
	
retry_rec_count_max equ 10 ;ждать данных максимум столько прерываний
    
; Flag C <- Data available
; isAvailable:
    ; ld a, LSR
    ; in a, (#ef)
    ; rrca
    ; ret

; Non-blocking read
; Flag C <- is byte was readen
; A <- byte
; read1:
    ; ld a, LSR
    ; in a, (#ef)
    ; rrca
    ; ret nc
    ; ld a, RBR_THR	
    ; in a, (#ef)
    ; scf 
    ; ret

; Tries read byte with timeout
; Flag C = 0 is byte read
; A <- byte
read:
	;xor a ;4
	;ld (#5C78),a ;обнулить счётчик ожидания ;13
;.wait
    ld a, LSR
    in a, (#ef)
    rrca
	jr nc, .readNo
    ld a, RBR_THR	
    in a, (#fe)
	or a ;есть данные
	ret	
.readNo ;нет данных
	xor a
	scf
	ret
; .readW	
	; ;ld a,(#5C78)
	; cp retry_rec_count_max
	; jr c, .wait ;ещё попытка
	; xor a ;выключим флаг переноса если время вышло
	; ret
	
	
	

; Blocking read
; A <- Byte
; readB:
    ; ld a, LSR
    ; in a, (#ef)
    ; rrca
    ; jr nc, readB
	; ld a, RBR_THR
    ; in a, (#ef)
    ; ret

; A -> byte to send
;Out: Flag C = 0 is byte writed
write:
    push af
;.wait
	ld a, LSR
    in a, (#ef)
    and #20
    jr z, .writeNo
    pop af
	ld b, RBR_THR
	ld c, #ef	
    out (c), a
	or a ;отправили
    ret
.writeNo
	pop af
	scf ;не отправили
	ret
    endmodule