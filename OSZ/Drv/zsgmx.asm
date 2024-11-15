COLOR=1
;; ZS GMX screen driver (izzx)
	define LINE_LIMIT 80
    module drvgmx
hsize   equ 25 ;всего строк
scraddr equ #c000 ;адрес экрана
scrsize equ 16000  ;размер экрана
scrline equ 80*8   ;размер строки в байтах

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
	call set_scr39 ;включить экран
cls:
    ld de, 0 :
	ld (curscrl),de ;скролл выключить
	call gmxscroll
    ld de, 0 :	
	call gotoXY
    ;ld a, 7 : call Memory.setPage
	ld a,(con_scr_cur) ;пиксели
	call PageSlot3 ;включить страницу пикселей
    xor a :; out (#fe), a
    ld hl, #c000, de, #c001, bc, 16000-1, (hl), a : ldir ;очистить
	ld a,(con_atr_cur) ;атрибуты
	call PageSlot3 ;включить страницу атрибутов	
	ld a,(attr_screen) ;цвет
	ld hl, #c000, de, #c001, bc, 16000-1, (hl), a : ldir ;очистить
	;call gmxscron ;включить расширенный экран
	ld a,(page_slot3_cur)
	jp PageSlot3 ;вернуть страницу
    ;jp Memory.setPage
    

; Set console coordinates
; d = row(0..23), e = column (0..79)
gotoXY:
	;rr e
	; ld a, 0
	; ld (half_tile_screen), a
	ld a,d ;проверка координаты строки
	cp hsize
	ret nc
	ld a,e ;проверка координаты столбца
	cp LINE_LIMIT
	ret nc	
    ld (col_screen), de
    ret    

disable:
    ; Nothing to disable
	call gmxscroff ;выключить расширенный экран
    ret

; H - line 
; A - char
fillLine: ;заполнение строки одним символом
    push af
    ld d, h, e, 0 : call gotoXY
    pop af
    ld hl, fill_buff, de, fill_buff + 1, bc, 80-1, (hl), a : ldir
    ld hl, fill_buff : jp printZ

paintLine: ;на входе в A номер строки, которую надо покрасить, B - цвет
	push bc
    ld b, a
    ld c, 0
    call bc_to_attr
	push hl
	ld a,(con_atr_cur) ;атрибуты
	call PageSlot3
	pop hl
	pop bc
	ld a,b;цвет
    ld (hl), a
    ld de, hl
    inc de
    ld bc, (80*8)-1
    ldir
    ld a,(page_slot3_cur)
	jp PageSlot3 ;вернуть страницу


mvCR ;каретка вниз (по коду 13)
	ld de, (col_screen)
	inc d ;row++
	ld a,d
	cp hsize ;последняя строка
	jr c,mvCR1
	ld a,(con_scr_cur) ;пиксели
	call PageSlot3 ;включить страницу пикселей
	call scroll 
	ld a,(page_slot3_cur)
	call PageSlot3 ;вернуть страницу
	ld d,hsize-1 ;остаться на последне строке
mvCR1
	ld e, 0
	; ld a, 0 
	; ld (half_tile_screen), a
	jp gotoXY
	
; Print just one symbol
; A - symbol
; putC
 	; ld hl, single_symbol_print ;single_symbol
	; ld (hl), a
	; ;ld a, 7 : call Memory.setPage
	; ; ld a,(con_scr_cur) ;пиксели
	; ; call PageSlot3
    ; ld hl, single_symbol_print
    ; call printL
    ; ld a,(page_slot3_cur)
	; jp PageSlot3 ;вернуть страницу

; Put string
; hl - string pointer that's begins from symbol count
printZ
    ld a, (hl) : and a : ret z
    push hl
    call putC
    pop hl
    inc hl
    jr printZ
    
; printL	
        ; ld	a, (hl)
		; and	a
		; ret	z
putC
		cp 13 : jp z, mvCR
		cp 10 :ret z ;пропустить символ

		call calc_addr_scr
		ld d,h ;координаты экрана в DE
		ld e,l
		ld	l,a
		ld	h,0
		add	hl,hl
		add	hl,hl
		add	hl,hl
        ld      bc,font
        add     hl,bc ;hl - адрес шрифта буквы

        ;push    de
		
	ld a,(con_scr_cur) ;страница пиксели
	exx
	call PageSlot3      
	exx
	push de ;сохранить адрес символа на экране
	
    ld  bc,#08ff
print80_1   
	ldi ;один байт
	
	push hl ;на строку пикселей вниз
	ld hl,80-1
	add hl,de
	ex de,hl
	pop hl

	djnz    print80_1


	ld a,(con_atr_cur) ;страница атрибуты
	call PageSlot3 

	pop hl ;адрес символа на экране

    ld      b,8
	ld a,(attr_screen)
	ld de,80	
print80_1_attr ;теперь так же атрибуты  
		
	ld (hl),a
	add hl,de
	
	djnz    print80_1_attr
	
	
	
; move cursor на одну позицию вперёд
move_cr80	
	;inc	de

	ld	hl,col_screen
	inc	(hl) ;увеличить столбец
	ld	a,(hl)

	cp	LINE_LIMIT
	ret	c

	xor	a
	;ld	(half_tile_screen),a
	ld	(hl),a
	;ld	c,a

	inc	hl ;на переменную row
	inc	(hl)
	ld	a,(hl)
	;ld	b,a

	cp	hsize ;всего строк
	jp	c,move_cr80_01

	ld	a,hsize-1
	ld	(hl),a
	;ld	b,a

	call scroll ;сдвиг вверх
	; push	bc
	; call	scroll_up8
	; pop	bc

move_cr80_01	
	; call	calc_addr_scr
	ld a,(page_slot3_cur)
	jp PageSlot3 ;вернуть страницу
	ret

calc_addr_scr	;определение адреса экрана по координатам символа
	ld	bc,(col_screen)
bc_to_attr:
	ld h,0
	ld l,b ;строка
	add hl,hl ;*2
	ld de,table_addr_scr
	add hl,de 
	ld e,(hl)
	inc hl
	ld d,(hl) ;узнали координаты строки
	ld h,0
	ld l,c ;колонка
	add hl,de ;узнали адрес символа
	
	ld de,(curscrl) ;добавить аппаратный скрол
	add hl,de
	ld de,scrsize
	and a		;check over
	sbc hl,de
	jr nc,calc02
	add hl,de
calc02:
	ld de,scraddr  ;screen
	add hl,de

	; ld      a,b
	; ld      d,a
	; rrca
	; rrca
	; rrca
	; and     a,224
	; add     a,c
	; ld      e,a
	; ld      a,d
	; and     24
	; or      #c0
	; ld      d,a
	ret



clear_line ;очистить строку
    ;ld b, hsize-1 ;последняя
    ;ld c, 0
    call bc_to_attr ;узнать адрес
	ld d,h
	ld e,l
	inc de
	ld bc,scrline-1
	ld (hl),0
	ldir
	ret

gmxscron
            ld      bc,#7efd
            ld      a,#c8
            out     (c),a
            ; ld      bc,#7ffd
            ; ld      a,#10    ;5 screen
            ; out     (c),a
            ret
			
; gmxscron2
            ; ld      bc,#7efd
            ; ld      a,#c8
            ; out     (c),a
            ; ld      bc,#7ffd
            ; ld      a,#18    ;7 screen
            ; out     (c),a
            ; ret
			
gmxscroff
            ld      bc,#7efd
            ld      a,#c0
            out     (c),a
            ; ld      bc,#7ffd
            ; ld      a,#10    ;5 screen
            ; out     (c),a
            ret
	





scroll: ;push hl         ; скpолл экpана на стpоку ввеpх
	ld hl,(curscrl)	;hard scroll
	ld de,scrline
	add hl,de	;next line
	ld de,scrsize	;chek over 16000
	and a
	sbc hl,de
	jr nc,scrollchek
	add hl,de
	jr scrollchek1
scrollchek:
	ld hl,0
scrollchek1:
	ld (curscrl),hl
	call gmxscroll

    ld b,hsize-1    ;last line
	ld c,0
    ;ld a,(attr_screen) ;цвет
    jp clear_line      ; очистка последней стpоки
    ;ret	
 ;аппаратный скрол вверх
gmxscroll:
;set hard scroll
;in: 
;out: 
	;push af
	;push bc
	;push de
	ld hl,proc_id_cur
	ld a,(proc_id_focus)
	cp (hl)
	ret nz ;скрол меняем только когда в фокусе
	
	ld de,0
curscrl equ $-2 ;current hard scroll (0-15999)
	ld bc,07AFDh
	ld a,e
	out (c),a
	ld bc,07CFDh
	ld a,d
	out (c),a
	;pop de
	;pop bc
	;pop af
	ret





PageSlot3 
; драйвер памяти Scorpion GMX 2Mb

         ;push hl
         ; ld   hl,page_table
         ; add  a,l
         ; jr   nc,PageSlot3_1
         ; inc  h          ;коррекция
; PageSlot3_1  ld   l,a
         ; ld   a,(hl)
         ;pop  hl
         ;cp   #ff
         ;scf
         ;ret  z
         ;push bc
         push af
         rlca
		 and #10
         or  #01  ;выбор ОЗУ вместо ПЗУ
         ld   bc,#1ffd
PageSlot3DOS
		 ;or #00 ; #04 тут выбор ПЗУ TRDOS
         out  (c),a
         pop  af
         push af
         and  #07
PageSlot3Scr ;тут выбор экрана и ПЗУ
         or   #10 ;#0 ;#18
         ld   b,#7f
         out  (c),a
         pop  af
         rrca
         rrca
         rrca
         rrca
         and  #07
         ld   b,#df
         out  (c),a
         ;pop  hl
         ret

set_color
		ld (attr_screen),a
		ld a,b
		ld (attr_screen2),a		
		ret
		 
set_scr5 ;включить экран 5
		call gmxscroff ;выключить расширенный
		ld a,#10
		ld (PageSlot3Scr+1),a
		ld a,(page_slot3_cur)
		jp PageSlot3
		
		
set_scr7 ;включить экран 7
		call gmxscroff ;выключить расширенный
		ld a,#18
		ld (PageSlot3Scr+1),a
		ld a,(page_slot3_cur)
		jp PageSlot3
		
		
set_scr39 ;включить экран 39
		call gmxscron ;выключить расширенный
		ld a,#10
		ld (PageSlot3Scr+1),a
		ld a,(page_slot3_cur)
		jp PageSlot3
		
		
set_scr3a ;включить экран 3b
		call gmxscron ;выключить расширенный
		ld a,#18
		ld (PageSlot3Scr+1),a
		ld a,(page_slot3_cur)
		jp PageSlot3






;Таблица страниц кроме #00-#07, #39, #3a, #77-7F
page_table    ;db   #00,#01,#02,#03,#04,#05,#06,#07,
		 db	  #08,#09
         db   #0a,#0b,#0c,#0d,#0e
         db   #0f,#10,#11,#12,#13,#14
         db   #15,#16,#17,#18,#19,#1a
         db   #1b,#1c,#1d,#1e,#1f,#20
         db   #21,#22,#23,#24,#25,#26
         db   #27,#28,#29,#2a,#2b,#2c
         db   #2d,#2e,#2f,#30,#31,#32
         db   #33,#34,#35,#36,#37,#38
         db   #3b,#3c,#3d,#3e,#3f,#40
         db   #41,#42,#43,#44,#45,#46
         db   #47,#48,#49,#4a,#4b,#4c

         db   #4d,#4e,#4f,#50,#51,#52
         db   #53,#54,#55,#56,#57,#58
         db   #59,#5a,#5b,#5c,#5d,#5e
         db   #5f,#60,#61,#62,#63,#64
         db   #65,#66,#67,#68,#69,#6a
         db   #6b,#6c,#6d,#6e,#6f,#70
         db   #71,#72,#73,#74,#75,#76
         ;db   #77,#78,#79,#7a,#7b,#7c,#7d,#7e
         ;db   #7f
page_table_end		 
         ds 128-(page_table_end-page_table) ;забить остаток нулями
			
			

;font equ #4000 ; Using ZX-Spectrum screen as font buffer
;font_file db "data/font.bin", 0 

PageSlot2 ;включение банка из A в слот памяти 2
	xor 2
	ld bc,#78fd
	out (c),a	
	ret


table_addr_scr	;адреса строк текста	
	defw	00000h ;0	
	defw	00280h
	defw	00500h
	defw	00780h
	defw	00a00h
	defw	00c80h
	defw	00f00h
	defw	01180h

	defw	01400h ;8
	defw	01680h
	defw	01900h
	defw	01b80h
	defw	01e00h
	defw	02080h
	defw	02300h
	defw	02580h
	
	defw	02800h ;16
	defw	02a80h
	defw	02d00h
	defw	02f80h
	defw	03200h
	defw	03480h
	defw	03700h
	defw	03980h
	
	defw	03c00h ;24
	defw	03e80h ;25 вне экрана


col_screen			db	0	;столбец
row_screen			db	0	;строка				
;half_tile_screen	db	0					
attr_screen			db	07	;основной цвет		
attr_screen2		db	#c	;второй цвет		


;col_screen_temp			dw	0				
;half_tile_screen_temp	db	0				

single_symbol_print db 1
single_symbol 		db 0

fill_buff ds 80+1

    endmodule