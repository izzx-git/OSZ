COLOR=1
;; ZS GMX screen driver (izzx)
	;define LINE_LIMIT 80
    module TextMode
init:
    ; ld hl, font_file, b, Dos.FMODE_READ
    ; call Dos.fopen
    ; push af
    ; ld bc, 2048, hl, font
    ; call Dos.fread
    ; pop af
    ; call Dos.fclose
	; xor a : out (#fe), a
	; call cls
	; ret
cls:
	OS_CLS
	ret
    ; ld de, 0 : call gotoXY
    ; ;ld a, 7 : call Memory.setPage
	; ld a,#3b
	; call PageSlot3 ;включить страницу пикселей
    ; xor a : out (#fe), a
    ; ld hl, #c000, de, #c001, bc, 16000-1, (hl), a : ldir ;очистить
	; ld a,#7b
	; call PageSlot3 ;включить страницу атрибутов	
	; ld a,(attr_screen) ;цвет
	; ld hl, #c000, de, #c001, bc, 16000-1, (hl), a : ldir ;очистить
	; call gmxscron ;включить расширенный экран
	; xor a
	; jp PageSlot3 ;вернуть страницу 0
    ;jp Memory.setPage
    

; Set console coordinates
; d = row(0..23), e = column (0..79)
gotoXY:
	OS_SET_XY
	;rr e
	; ld a, 0
	; ld (half_tile_screen), a
    ;ld (col_screen), de
    ret    

disable:
    ; Nothing to disable
	;call gmxscroff ;выключить расширенный экран
    ret

; H - line 
; A - char
fillLine: ;заполнение строки одним символом
	OS_FILL_LINE
	ret
    ; push af
    ; ld d, h, e, 0 : call gotoXY
    ; pop af
    ; ld hl, fill_buff, de, fill_buff + 1, bc, 80-1, (hl), a : ldir
    ; ld hl, fill_buff : jp printZ

usualLine: ;на входе в A номер строки, которую надо покрасить обычным цветом
	ld b,#07 ;цвет
	OS_PAINT_LINE
	ret
    ; ld b, a
    ; ld c, 0
    ; call bc_to_attr
    ; ;ld a, 7 : call Memory.setPage
	; push hl
	; ld a,#7b ;атрибуты
	; call PageSlot3
	; pop hl
	; ld a,(attr_screen) ;цвет
    ; ld (hl), a
    ; ld de, hl
    ; inc de
    ; ld bc, (80*8)-1
    ; ldir
    ; xor a : ;jp Memory.setPage
	; jp PageSlot3 ;вернуть страницу 0

highlightLine: ;на входе в A номер строки, которую надо покрасить другим цветом 
	ld b,#0c ;цвет
	OS_PAINT_LINE
	ret
    ; ld b, a
    ; ld c, 0
    ; call bc_to_attr
    ; ;ld a, 7 : call Memory.setPage
	; push hl
	; ld a,#7b ;атрибуты
	; call PageSlot3
	; pop hl
	; ld a,(attr_screen2) ;цвет
    ; ld (hl), a
    ; ld de, hl
    ; inc de
    ; ld bc, (80*8)-1
    ; ldir
    ; xor a : ;jp Memory.setPage
	; jp PageSlot3 ;вернуть страницу 0

; mvCR ;каретка вниз
	; ld de, (col_screen)
	; inc d
	; ld e, 0
	; ; ld a, 0 
	; ; ld (half_tile_screen), a
	; jp gotoXY
	
; Print just one symbol
; A - symbol
putC
	OS_PRINT_CHARF
	ret
    ; cp 13 : jp z, mvCR

	; ld hl, single_symbol
	; ld (hl), a
	; ;ld a, 7 : call Memory.setPage
	; ld a,#3b ;пиксели
	; call PageSlot3
    ; ld hl, single_symbol_print
    ; call printL
    ; xor a : ;jp Memory.setPage
	; jp PageSlot3 ;вернуть страницу 0

; Put string
; hl - string pointer that's begins from symbol count
printZ
	OS_PRINTZ
	ret
    ; ld a, (hl) : and a : ret z
    ; push hl
    ; call putC
    ; pop hl
    ; inc hl
    ; jr printZ
    
; printL	
        ; ld	a, (hl)
		; and	a
		; ret	z

		; ; push	hl
		; ; call	calc_addr_scr
		; ; ld	a,(attr_screen)
		; ; ;ld	(hl),a ;покрасить символ
		; ; pop	hl

		; ;call	calc_addr_scr

		; ; ld	a,(half_tile_screen)
		; ; bit	0,a
		; ; ld	a,(hl)
		; ; jp	nz,print64_4
; ;print80_3 
        ; push    af
		; push	hl
		; ; ld a,#7b ;атрибуты
		; ; call PageSlot3
		; call	calc_addr_scr
		; ; ld	a,(attr_screen)
		; ; ld	(hl),a ;покрасить символ
		; ld d,h ;координаты экрана в DE
		; ld e,l
		; ; ld a,#3b ;пиксели
		; ; call PageSlot3
		; pop	hl
        
        ; inc     hl
        ; push    hl
        
        ; ld      a,(hl)
		; ld	l,a
		; ld	h,0
		; add	hl,hl
		; add	hl,hl
		; add	hl,hl
        ; ld      bc,font
        ; add     hl,bc

        ; ;push    de
        
        ; ld      b,8
		; ; xor	a
		; ; ld	(de),a
; print80_1   
	; ;inc     d
	
	; ld      a,(hl)
	; ;and	#f0
	; ld      (de),a
	; inc     hl
	
	; push hl ;на строку пикселей вниз
	; ld hl,80
	; add hl,de
	; ex de,hl
	; pop hl
	
	; djnz    print80_1

	; ;inc	d
	; ; push hl
	; ; ld hl,80
	; ; add hl,de
	; ; ex de,hl
	; ; pop hl
	
	; ; xor	a
	; ; ld	(de),a

	; ; ld	a,1
	; ; ld	(half_tile_screen),a

	; ;pop     de
	; pop     hl
	; pop     af

	; ;dec     a
	; ; ret     ;z

; ; print64_4	
	; ; push    af

	; ; inc     hl
	; ; push    hl

	; ; ld      a,(hl)
	; ; ld	l,a
	; ; ld	h,0
	; ; add	hl,hl
	; ; add	hl,hl
	; ; add	hl,hl
	; ; ld      bc,font
	; ; add     hl,bc

	; ; push    de

	; ; ld      b,6
	; ; xor	a
	; ; ld	(de),a
; ; print64_2       
	; ; ;inc     d
	; ; push hl
	; ; ld hl,80
	; ; add hl,de
	; ; ex de,hl
	; ; pop hl
	; ; ld      a,(hl)
	; ; ;and     #0f
	; ; ld      c,a
	; ; ld      a,(de)
	; ; or      c
	; ; ld      (de),a
	; ; inc     hl
	; ; djnz    print64_2

	; ; ;inc	d
	; ; push hl
	; ; ld hl,80
	; ; add hl,de
	; ; ex de,hl
	; ; pop hl
	; ; xor	a
	; ; ld	(de),a

	; ; ld	(half_tile_screen),a

	; ; pop     de

	; ; call	move_cr64

	; ; pop     hl
	; ; pop     af
	; ; dec     a
	
	; ; jp      nz,print64_3

	; ; ret

; ; move cursor на одну позицию вперёд
; move_cr80	
	; ;inc	de

	; ld	hl,col_screen
	; inc	(hl) ;увеличить столбец
	; ld	a,(hl)

	; cp	80
	; ret	c

	; xor	a
	; ;ld	(half_tile_screen),a
	; ld	(hl),a
	; ld	c,a

	; inc	hl ;на переменную row
	; inc	(hl)
	; ld	a,(hl)
	; ld	b,a

	; cp	24
	; jp	c,move_cr80_01

	; ld	a,23
	; ld	(hl),a
	; ld	b,a

	; ; push	bc
	; ; call	scroll_up8
	; ; pop	bc

; move_cr80_01	
	; ; call	calc_addr_scr
	; ; ret

; calc_addr_scr	;определение адреса экрана по координатам символа
	; ld	bc,(col_screen)
; bc_to_attr:
	; ld h,0
	; ld l,b ;строка
	; add hl,hl ;*2
	; ld de,table_addr_scr
	; add hl,de 
	; ld e,(hl)
	; inc hl
	; ld d,(hl) ;узнали координаты строки
	; ld h,0
	; ld l,c ;колонка
	; add hl,de ;узнали адрес символа
	; ; ld      a,b
	; ; ld      d,a
	; ; rrca
	; ; rrca
	; ; rrca
	; ; and     a,224
	; ; add     a,c
	; ; ld      e,a
	; ; ld      a,d
	; ; and     24
	; ; or      #c0
	; ; ld      d,a
	; ret

; ; calc_addr_attr		
	; ; ld	bc,(col_screen)
; ; bc_to_attr:
	; ; ld	a,b
	; ; rrca
	; ; rrca
	; ; rrca
	; ; ld	l,a
	; ; and	31
	; ; or	#d8
	; ; ld	h,a
	; ; ld	a,l
	; ; and	252
	; ; or	c
	; ; ld	l,a
	; ; ret

; ; scroll_up8	;
	; ; ld	hl,table_addr_scr
	; ; ld	b,184

; ; scroll_up8_01		
	; ; push	bc

	; ; ld	e,(hl)
	; ; inc	hl
	; ; ld	d,(hl)
	; ; inc	hl

	; ; push	hl

	; ; ld	bc,14
	; ; add	hl,bc
	; ; ld	c,(hl)
	; ; inc	hl
	; ; ld	b,(hl)

	; ; ld	h,b
	; ; ld	l,c

	; ; ld	bc,32
	; ; ldir

	; ; pop	hl
	; ; pop	bc
	; ; djnz	scroll_up8_01

	; ; ld	b,8

; ; scroll_up8_02		
	; ; push	bc

	; ; ld	e,(hl)
	; ; inc	hl
	; ; ld	d,(hl)
	; ; inc	hl

	; ; push	hl

	; ; ld	h,d
	; ; ld	l,e
	; ; inc	de
	; ; ld	(hl),0
	; ; ld	bc,31
	; ; ldir

	; ; pop	hl
	; ; pop	bc
	; ; djnz	scroll_up8_02
	; ; ld	de,#D800, hl,#D820, bc,736
	; ; ldir
	; ; ld	a,(de)
	; ; ld	hl,#dae0, de,#dae1, (hl),a, bc,31
	; ; ldir

	; ; ret


; gmxscron
            ; ld      bc,#7efd
            ; ld      a,#c8
            ; out     (c),a
            ; ; ld      bc,#7ffd
            ; ; ld      a,#10    ;5 screen
            ; ; out     (c),a
            ; ret
			
; ; gmxscron2
            ; ; ld      bc,#7efd
            ; ; ld      a,#c8
            ; ; out     (c),a
            ; ; ld      bc,#7ffd
            ; ; ld      a,#18    ;7 screen
            ; ; out     (c),a
            ; ; ret
			
; gmxscroff
            ; ld      bc,#7efd
            ; ld      a,#c0
            ; out     (c),a
            ; ; ld      bc,#7ffd
            ; ; ld      a,#10    ;5 screen
            ; ; out     (c),a
            ; ret
			

; PageSlot3 
; ; драйвер памяти для TR-DOS Navigator
; ; и Scorpion GMX 2Mb
         ; ; org  #5b00
         ; ; jr   pag_on
         ; ; jr   clock
         ; ; db   #00
         ; ; db   #00

         ; ;push hl
         ; ld   hl,table
         ; add  a,l
         ; jr   nc,PageSlot3_1
         ; inc  h          ;коррекция
; PageSlot3_1  ld   l,a
         ; ld   a,(hl)
         ; ;pop  hl
         ; ;cp   #ff
         ; ;scf
         ; ;ret  z
         ; ;push bc
         ; push af
         ; rlca
         ; and  #10 
         ; ld   bc,#1ffd
; PageSlot3DOS
		 ; ;or #00 ; #04 тут выбор ПЗУ TRDOS
         ; out  (c),a
         ; pop  af
         ; push af
         ; and  #07
; PageSlot3Scr ;тут выбор экрана и ПЗУ
         ; or   #18 ;#0 ;#18
         ; ld   b,#7f
         ; out  (c),a
         ; pop  af
         ; rrca
         ; rrca
         ; rrca
         ; rrca
         ; and  #07
         ; ld   b,#df
         ; out  (c),a
         ; ;pop  hl
         ; ret
; ; clock    ld   d,%00100000
         ; ; rst  8
         ; ; db   #89
         ; ; ret

         ; ; org  #5b5c ; здесь системная переменая
         ; ; db   #10
; ;все страницы
; table    db   #00,#01,#02,#03,#04,#05,#06,#07,#08,#09
         ; db   #0a,#0b,#0c,#0d,#0e
         ; db   #0f,#10,#11,#12,#13,#14
         ; db   #15,#16,#17,#18,#19,#1a
         ; db   #1b,#1c,#1d,#1e,#1f,#20
         ; db   #21,#22,#23,#24,#25,#26
         ; db   #27,#28,#29,#2a,#2b,#2c
         ; db   #2d,#2e,#2f,#30,#31,#32
         ; db   #33,#34,#35,#36,#37,#38,#39
         ; db   #3a,#3b,#3c,#3d,#3e,#3f,#40
         ; db   #41,#42,#43,#44,#45,#46
         ; db   #47,#48,#49,#4a,#4b,#4c

         ; db   #4d,#4e,#4f,#50,#51,#52
         ; db   #53,#54,#55,#56,#57,#58
         ; db   #59,#5a,#5b,#5c,#5d,#5e
         ; db   #5f,#60,#61,#62,#63,#64
         ; db   #65,#66,#67,#68,#69,#6a
         ; db   #6b,#6c,#6d,#6e,#6f,#70
         ; db   #71,#72,#73,#74,#75,#76
         ; db   #77,#78,#79,#7a,#7b,#7c,#7d,#7e
         ; db   #7f

         ; db   #ff ;конец таблицы
			
			

; font equ #4000 ; Using ZX-Spectrum screen as font buffer
; font_file db "data/font.bin", 0 


; table_addr_scr	;адреса строк текста	
	; defw	#c000 ;0
	; defw	#c280
	; defw	#c500
	; defw	#c780
	; defw	#ca00
	; defw	#cc80
	; defw	#cf00
	; defw	#d180

	; defw	#d400 ;8
	; defw	#d680
	; defw	#d900
	; defw	#db80
	; defw	#de00
	; defw	#e080
	; defw	#e300
	; defw	#e580
	
	; defw	#e800 ;16
	; defw	#ea80
	; defw	#ed00
	; defw	#ef80
	; defw	#f200
	; defw	#f480
	; defw	#f700
	; defw	#f980
	
	; defw	#fc00 ;24
	; defw	#fe80 ;25 вне экрана


; col_screen			db	0	;столбец
; row_screen			db	0	;строка				
; ;half_tile_screen	db	0					
; attr_screen			db	07	;основной цвет		
; attr_screen2		db	#c	;другой цвет		

; ;col_screen_temp			dw	0				
; ;half_tile_screen_temp	db	0				

; single_symbol_print db 1
; single_symbol 		db 0

; fill_buff ds 80+1

    endmodule