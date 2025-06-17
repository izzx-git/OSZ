;None Commander - приложение для OS GMX
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org PROGSTART	

start_nc
	ld hl,msg_title_nc ;имя приложения
	OS_PRINTZ ;печать


	;узнать свои страницы
	OS_GET_MAIN_PAGES
	jr c,get_page_error

	ld (page_main),bc


	OS_GET_PAGE ;получить лишнюю страницу
	jr nc,get_page_ok
get_page_error
	ld hl,msg_mem_err ;нет памяти
	OS_PRINTZ ;печать
	
	call delay
	jp exit
	
get_page_ok
	ld (page_ext01),a ;запомнить

	
	
start_nc_warm ;тёплый старт

	;очистка буфера
	call clear_buf
	
	;загрузка каталога
	ld hl,buffer_cat ;куда
	ld de,0 ;начиная с 0 сектора
	ld b,32 ; секторов
	OS_DIR_READ

	ld hl,0 ;обнулить переменные
	ld (file_r_num_cur),hl
	ld (file_r_all),hl
	
	call format_dir
	
	ld a,color_backgr
	ld b,#c	
	OS_SET_COLOR
	
	call print_rect_r ;рамка
	call print_panel_r
	call print_menu_main
	
	ld de,#0100
	OS_SET_XY
	


nc_wait
	OS_WAIT ;ждать прерывание
	
	OS_GET_CHAR ;клавиша
	ld (key_pressed),a ;запомнить
	cp 13
	jp z,key_enter ;
	cp 10 ;вниз
	jp z,key_down 
	cp 11 ;вверх
	jp z,key_up 
	cp 24 ;break
	jp z,exit
	cp "3" ;просмотр файла
	jp z,view_file	
	
	jp nc_wait ;на цикл ожидания


delay ;задержка
	ld b,50*3 ;
delay1
	OS_WAIT
	djnz delay1
	ret


clear_buf
	ld hl,buffer_cat
	ld de,buffer_cat+1
	ld bc,#4000-1
	ld (hl),0
	ldir
	ret




release_key ;ждать отпускания клавиши
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr nz,release_key
	ret


key_enter
	;нажата Enter
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,key_enter_ex ;защита
	call calc_deskr
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jr z,key_enter_dir
	
	;проверка расширения ;APG
	call check_apg
	jp nz,key_enter_ex
	;тут запуск приложения
	call format_name
	
	ld hl,file_name_cur		;строка с именем
	OS_PROC_RUN ;запустить прогу
	;обработка ошибки
	jr c,key_enter_ex
	
	ld a,(ix)
	OS_PROC_SET_FOCUS ;на передний план
	
key_enter_ex
	jp nc_wait

key_enter_dir
	;тут открытие папки

	;call format_name_dir
	ex de,hl ;de - дескриптор для открытия
	ld hl,dir_name_cur
	OS_DIR_OPEN
	jr c,key_enter_ex ;если ошибка, ничего не делаем
	
	pop hl ;отменить возврат
	jp start_nc_warm ;перезагрузить папку


; format_name_dir
	; push hl
	; ld hl,file_name_cur
	; ld de,file_name_cur+1 ;почистить
	; ld bc,256-1
	; ld (hl),0
	; ldir
	
	; pop hl
	
	; ld de,file_name_cur ;куда 
	; ld bc,#08ff 
; format_name_dir_cl
	; ld a,(hl)
	; cp " "+1
	; jr c,format_name_dir_skip
	; ldi
	; djnz format_name_dir_cl
; format_name_dir_skip
	; ld a,'/'
	; ld (de),a
	; ret

calc_deskr ;вычислить дескриптор текущего элемента справа
	ld de,buffer_cat
	ld hl,(file_r_num_cur)
	add hl,hl ;*2
	add hl,hl ;*4
	add hl,hl ;*8
	add hl,hl ;*16
	add hl,hl ;*32
	add hl,de
	push hl
	pop ix ;указатель на файл в каталоге
	ret


key_down
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,key_down_ex ;защита
	ld hl,(file_r_num_cur)
	inc hl	
	ld bc,(file_r_all)
	;если не больше чем всего
	push hl
	and a
	sbc hl,bc
	pop hl
	jr nc,key_down_skip
	ld (file_r_num_cur),hl
	call print_panel_r ;обновить каталог
key_down_skip
	ld a,(key_pressed)
key_down_ex
	jp nc_wait
	
	
	
key_up
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,key_up_ex ;защита
	ld hl,(file_r_num_cur)
	ld a,l
	or h
	jr z,key_up_skip
	dec hl
	ld (file_r_num_cur),hl
	call print_panel_r ;обновить каталог
key_up_skip

key_up_ex
	jp nc_wait

	
exit ;выход в DOS
	xor a
	OS_PROC_CLOSE
	


check_apg ;проверка на расширение APG
	ld a,(ix+8)
	cp "A"
	ret nz
	ld a,(ix+9)
	cp "P"
	ret nz
	ld a,(ix+10)
	cp "G"
	ret nz
	xor a ;равен
	ret
	

	
print_panel_r ;печать правой панели
	ld ix,buffer_cat	
	ld de,panel_r_xy ;координаты yx
	ld b,panel_hight ;высота панели
	ld iy,0
print_panel_r_cl ;цикл
	push bc
	push de ;xy
	OS_SET_XY
	push ix ;адрес элемента
	pop hl
	ld a,(hl)
	or a ;конец каталога
	jr z,print_panel_r_ex
	call print_file_info
print_panel_r_skip
	pop de
	inc d ;y++
	inc iy ;текущий файл
	ld bc,32 ;на другой элемент каталога
	add ix,bc
	pop bc
	djnz print_panel_r_cl
	ret
print_panel_r_ex
	pop de
	pop bc
	
	;здесь почистить остаток каталога
	ret


	
print_file_info ;печать строчки о файле
	ld de,file_info_string ;скопировать
	ld bc,file_info_lenght
	ldir

	call get_color_item
	
	ld b,#c	
	OS_SET_COLOR	
	ld hl,file_info_string
	OS_PRINTZ
	ret
	


get_color_item ;получить цвет элемента
;вх: IX - адрес в каталоге, IY - порядковый номер (0-511)
;вых: A - цвет
	ld bc,(file_r_num_cur) ;позиция курсора справа
	push iy
	pop hl
	and a
	sbc hl,bc ;сравнить
	jr z,get_color_item_no_cursor
	;цвета курсора
	ld a,color_dir ;простая 
	ld (get_color_item_dir+1),a
	ld a,color_apg ;простая 
	ld (get_color_item_apg+1),a
	ld a,color_backgr ;простая 
	ld (get_color_item_backgr+1),a	
	jr get_color_item_set
	
get_color_item_no_cursor
	;цвета обычные
	ld a,color_dir_hi ;под курсором
	ld (get_color_item_dir+1),a
	ld a,color_apg_hi ;под курсором
	ld (get_color_item_apg+1),a
	ld a,color_backgr_hi ;под курсором
	ld (get_color_item_backgr+1),a

get_color_item_set
	;задать цвет	
	ld a,(ix+#0b)
	cp #10 ;признак каталога
	jr nz,get_color_item_no_dir
	;если папка
get_color_item_dir	
	ld a,0
	ret
	
get_color_item_no_dir
	call check_apg ;расширение apg
	jr nz,get_color_item_no_apg
	;если приложение
get_color_item_apg
	ld a,0
	ret
	
get_color_item_no_apg
	;если обычный файл
get_color_item_backgr	
	ld a,0
	ret

	
	
format_dir ;подготовить каталог, убрать лишнее
	; ld a,2
	; out (254),a
	ld iy,0 ;счётчик файлов	
	;найти конец каталога
	ld hl,buffer_cat
	ld a,(hl)
	or a
	ret z ;защита
	ld bc,32
format_dir_prep_cl
	ld a,(hl)
	or a
	jr z,format_dir_prep_ex
	add hl,bc
	ld a,h
	or a ;если вышли за границу	
	jr z,format_dir_prep_ex
	jr format_dir_prep_cl
format_dir_prep_ex
	ld bc,32
	and a
	sbc hl,bc
	ld (format_dir_top),hl ;конец каталога



	ld ix,buffer_cat	
	;ld b,panel_hight ;высота панели
format_dir_cl ;цикл
	ld a,(ix)
	or a ;конец каталога
	jr z,format_dir_ex
	cp #e5 ;удалённый
	jr z,format_dir_skip
	cp #05 ;удалённый	
	jr z,format_dir_skip	
	ld a,(ix+#0b)
	cp #0f ;длинный	
	jr z,format_dir_skip
	
	;проверка на папку "." (этот же каталог)
	ld a,(ix+#00)
	cp "." ;	
	jr nz,format_dir_add
	ld a,(ix+#01)
	cp " " ;
	jr z,format_dir_skip	
	
	
format_dir_add	
	inc iy ;++
	ld bc,32 ;на другой элемент каталога
	add ix,bc
	ld a,ixh
	or a ;если вышли за границу
	jr z,format_dir_ex	
	jr format_dir_cl
format_dir_skip
	;сдвинуть элементы вниз
	push ix
	push ix
	pop hl 
	pop de ;куда
	ld hl,(format_dir_top) ;0-32
	and a
	sbc hl,de
	ld b,h
	ld c,l ;длина
	push bc
	
	push ix
	pop hl ;откуда
	ld bc,32 ;на другой элемент каталога
	add hl,bc ;откуда

	pop bc
	ldir
	
	xor a
	ld (de),a ;очистить ненужный элемент
	
	jr format_dir_cl

format_dir_ex
	ld (file_r_all),iy
	;здесь почистить остаток каталога
	; ld a,0
	; out (254),a
	ret
format_dir_top	dw 0 ;временно конец гаталога
	
	
format_name ;подогнать имя под стандарт filename.ext
;вх: HL - имя в каталоге
	push hl
	ld hl,file_name_cur
	ld de,file_name_cur+1 ;почистить
	ld bc,256-1
	ld (hl),0
	ldir
	
	pop hl
	push hl
	
	ld de,file_name_cur ;куда 
	ld bc,#08ff 
format_name_cl
	ld a,(hl)
	cp " "+1
	jr c,format_name_skip
	ldi
	djnz format_name_cl
format_name_skip
	ld a,"."
	ld (de),a
	
	inc de
	pop hl
	ld bc,8 ;перейти на расширение
	add hl,bc
	
	ld bc,#03ff
format_name_cl2
	ld a,(hl)
	cp " "+1
	jr c,format_name_skip2
	ldi
	djnz format_name_cl2
format_name_skip2
	ret

print_rect_r ;печать рамки правой
	ld a,color_backgr ;цвет
	ld b,#c
	OS_SET_COLOR
	ld de,#0028 ;xy
	OS_SET_XY
	ld hl,rect_1
	OS_PRINTZ
	
	ld de,#0128 ;xy
	ld b,24-2 ;цикл
print_rect_r_cl
	push bc
	push de
	OS_SET_XY
	ld hl,rect_2
	OS_PRINTZ
	pop de
	inc d
	pop bc
	djnz print_rect_r_cl
	
	
	ld de,#1728 ;xy
	OS_SET_XY
	ld hl,rect_3
	OS_PRINTZ
	ret

print_menu_main ;печать основного меню
	ld a,color_backgr_hi ;цвет
	ld b,#c
	OS_SET_COLOR
	ld de,#1800+3*8
	OS_SET_XY
	ld hl,msg_menu_main
	OS_PRINTZ
	ret
	
	
	include nc_view.asm ;просмотрщик


color_backgr equ 1*8+7 ;цвет фона
color_apg equ 1*8+4 ;цвет приложений
color_dir equ 1*8+6 ;цвет папок

color_backgr_hi equ 5*8+0 ;цвет фона курсор
color_apg_hi equ 5*8+0 ;цвет приложений курсор
color_dir_hi equ 5*8+0 ;цвет папок курсор

file_info_lenght equ 11 ;длина инфо о файле
panel_hight equ 22;высота панели	
panel_r_xy equ #0129	
buffer_cat equ #c000 ;адрес буфера каталога

file_r_all dw 0;всего файлов справа
file_name_cur ds 256 ;имя файла текущее
dir_name_cur ds 256 ;имя файла текущее
file_info_string ds file_info_lenght+1 ;буфер инфо
file_info_clear db "            ",0 ;для очистки
buffer_cat_page_r db 0 ;страница буфера каталога правый

file_r_num_cur dw 0 ;текущий файл справа
key_pressed db 0 ;последняя клавиша	
file_id_cur_r db 0 ;id файла справа


page_ext01 db 0 ;номер дополнительной страницы
page_main dw 0 ;основные номера страниц слота 2,3

rect_1 
	db #c9
	dup 40-2
	db #cd
	edup
	db #bb,0
	
rect_2 
	db #ba
	dup 40-2
	db " "
	edup
	db #ba,0

rect_3 
	db #c8
	dup 40-2
	db #cd
	edup
	db #bc,0	

msg_menu_main
	db "3 View",0
msg_file_error
	db "File error",10,13,0
msg_file_too_big
	db "File too big",10,13,0
msg_mem_err
	db "Get memory error",10,13,0
msg_title_nc
	db "None Commander ver 2025.06.17",10,13,0

end_nc
	savebin "nc.apg",start_nc,$-start_nc