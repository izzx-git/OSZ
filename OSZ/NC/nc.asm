;None Commander - приложение для OS GMX
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org PROG_START	

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
	ld b,32 ; секторов = 16384 = 512 файлов макс
	OS_DIR_READ

	ld hl,0 ;обнулить переменные
	ld (file_r_num_cur),hl
	ld (file_r_all),hl
	ld (file_r_cur_focus),hl
	
	call sort_dir
	
	ld a,color_backgr
	ld b,#c	
	OS_SET_COLOR
	
	call print_rect_r ;рамка
	call print_panel_r
	call print_menu_main
	
	ld de,#0100
	OS_SET_XY
	
	ld hl,msg_menu_info
	OS_PRINTZ
	


nc_wait
	OS_WAIT ;ждать прерывание
	
	OS_GET_CHAR ;клавиша
	ld (key_pressed),a ;запомнить
	cp 13
	jp z,key_enter ;
	cp 10 ;вниз
	call z,key_down 
	cp 11 ;вверх
	call z,key_up 
	cp 09 ;вправо
	call z,key_right 
	cp 08 ;влево
	call z,key_left
	cp 04 ;страница вверх
	call z,key_left
	cp 05 ;страница вниз
	call z,key_right
	cp "1" ;переключение длинных имён (LFN)
	jp z,LFN_toggle
	cp "2" ;переключение сортировки
	jp z,sort_toggle
	cp "3" ;просмотр файла
	jp z,view_file	
	cp 25 ;CS+Enter
	jp z,nc_play_all 
	cp 24 ;break
	jp z,exit

	
	ld a,(print_panel_r_flag)
	or a
	call nz,print_panel_r ;обновить каталог
	xor a
	ld (print_panel_r_flag),a
	
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


;очистить левую панель
clear_left_panel
	ld a,color_backgr ;цвет
	ld b,#c
	OS_SET_COLOR
	ld b,panel_hight+2 ;высота
	ld de,0
	OS_SET_XY
clear_left_panel_cl
	push bc
	ld hl,txt_clear_panel
	OS_PRINTZ
	pop bc
	djnz clear_left_panel_cl
	ld de,0
	OS_SET_XY
	ret
txt_clear_panel db "                                        ",13,0 ;40 пробелов


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
	ld hl,(file_r_num_cur)
	call calc_deskr
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jp z,key_enter_dir
	
	cp #30 ;признак каталога
	jp z,key_enter_dir


	call format_name
	
	;проверка расширения APG
	call check_apg
	jp nz,key_enter_1
	;тут запуск приложения
	ld hl,file_name_cur		;строка с именем
	OS_PROC_RUN ;запустить прогу
	;обработка ошибки
	jr c,key_enter_ex
	
	ld a,(ix)
	OS_PROC_SET_FOCUS ;на передний план
	jr key_enter_ex



key_enter_1
	;проверка расширения VGM
	call check_vgm
	jp nz,key_enter_2
	
	call clear_left_panel ;почистить часть экрана
	
	ld a,(page_ext01) ;доп страница для данных плеера
	OS_SET_PAGE_SLOT3
	
	call start_gplay
	
	ld a,(page_main) ;основная страница
	OS_SET_PAGE_SLOT3
	
	jr key_enter_ex


key_enter_2
	;проверка расширения SCR
	call check_scr
	jp nz,key_enter_3
	
	
	ld a,(page_ext01) ;доп страница для данных плеера
	OS_SET_PAGE_SLOT3
	
	ld hl,file_name_cur		;строка с именем	
	OS_FILE_OPEN
	jr nc,key_enter_2_file_open_ok
key_enter_2_file_error
	ld hl,msg_file_error
	OS_PRINTZ	
	; ld b,2*50
	; call delay1
	jp key_enter_ex
	
key_enter_2_file_open_ok
	ld (file_id_cur_r),a
	ld de,6912
	ld hl,#c000
	;ld a,(file_id_cur_r)
	OS_FILE_READ ;загрузить
	jr c,key_enter_2_file_error	
	ld a,(file_id_cur_r)
	OS_FILE_CLOSE
	
	call display ;показать
	
	ld a,(page_main) ;основная страница
	OS_SET_PAGE_SLOT3
	
	jr key_enter_ex


key_enter_3



	
key_enter_ex
	jp nc_wait
	
	




	
nc_play_all
	;Воспроизведение всего по порядку
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,nc_play_ex ;защита
	ld hl,(file_r_num_cur)
	call calc_deskr
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jr z,nc_play_all_down
	
	cp #30 ;признак каталога
	jr z,nc_play_all_down


	call format_name

nc_play_1
	;проверка расширения ;VGM
	call check_vgm
	jp nz,nc_play_2
	
	call clear_left_panel ;почистить часть экрана
	
	ld a,(page_ext01) ;доп страница для данных плеера
	OS_SET_PAGE_SLOT3
	
	call start_gplay
	
	push af
	ld a,(page_main) ;основная страница
	OS_SET_PAGE_SLOT3
	pop af
	cp "s"
	jr z,nc_play_ex
	cp "S"
	jr z,nc_play_ex
	cp 24 ;break
	jr z,nc_play_ex
	
	jr nc_play_all_down


nc_play_2
	jr nc_play_all_down


	
nc_play_ex
	jp nc_wait
	
	
nc_play_all_down ;вниз по списку
	ld bc,(file_r_num_cur)
	push bc
	call key_down
	call print_panel_r ;обновить каталог
	pop bc
	ld hl,(file_r_num_cur)
	and a
	sbc hl,bc ;если не сдвинулась позиция, то всё
	jr z,nc_play_ex
	jp nc_play_all
	
	
	
	
	
	
	

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

 ;вычислить дескриптор текущего элемента справа
calc_deskr
	add hl,hl ;*2
	ld bc,cat_index
	add hl,bc
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl ;hl - адрес элемента
	push hl
	pop ix ;ix- адрес элемента
	ret
	



key_down
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,key_down_ex ;защита
	
	ld bc,(file_r_num_cur)
	inc bc	
	ld hl,(file_r_all)
	;если не больше чем всего
	and a
	sbc hl,bc
	jr c,key_down_skip
	jr z,key_down_skip
	;прибавить
	ld (file_r_num_cur),bc
	
	;теперь передвинуть фокус, если надо
	ld hl,(file_r_cur_focus)	
	ld bc,panel_hight
	add hl,bc ;прибавить количество видимых	
	ld bc,(file_r_num_cur)
	and a
	sbc hl,bc ;вычесть положение курсора
	jr z,key_down_change_focus_yes
	jr nc,key_down_change_focus_no
key_down_change_focus_yes
	;передвинуть фокус
	ld hl,(file_r_cur_focus)
	inc hl
	ld (file_r_cur_focus),hl	
	
key_down_change_focus_no	
	ld a,1
	ld (print_panel_r_flag),a
	;call print_panel_r ;обновить каталог
key_down_skip

key_down_ex
	ld a,(key_pressed)
	ret
	
	
	
key_up ;вверх
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
	
	;теперь передвинуть фокус, если надо
	ld hl,(file_r_num_cur)	
	; ld bc,panel_hight
	; add hl,bc ;прибавить количество видимых	
	ld bc,(file_r_cur_focus)
	and a
	sbc hl,bc ;вычесть положение курсора
	;jr z,key_up_change_foces_yes
	jr nc,key_up_change_foces_no
key_up_change_foces_yes	
	;передвинуть фокус
	ld hl,(file_r_cur_focus)
	ld a,h
	or l
	jr z,key_up_change_foces_no ;защита
	dec hl
	ld (file_r_cur_focus),hl	
	
key_up_change_foces_no	
	
	ld a,1
	ld (print_panel_r_flag),a
	;call print_panel_r ;обновить каталог
key_up_skip

key_up_ex
	ld a,(key_pressed)
	ret
	
	
key_left ;на страницу назад
	ld b,panel_hight-1
key_left_cl
	push bc
	call key_up
	pop bc
	djnz key_left_cl
	ld a,1
	ld (print_panel_r_flag),a
	ld a,(key_pressed)
	ret
	
	
	
key_right ;на страницу вперёд
	ld b,panel_hight-1
key_right_cl
	push bc
	call key_down
	pop bc
	djnz key_right_cl
	ld a,1
	ld (print_panel_r_flag),a
	ld a,(key_pressed)
	ret


	
exit ;выход в DOS
	xor a
	OS_PROC_CLOSE
	


check_apg ;проверка на расширение APG
	ld a,(ix+8)
	cp "a"
	jr z,check_apg1
	cp "A"
	ret nz
check_apg1
	ld a,(ix+9)
	cp "p"
	jr z,check_apg2
	cp "P"
	ret nz
check_apg2
	ld a,(ix+10)
	cp "g"
	ret z
	cp "G"
	ret nz
	xor a ;равен
	ret
	
	
check_vgm ;проверка на расширение VGM
	ld a,(ix+8)
	cp "v"
	jr z,check_vgm1
	cp "V"
	ret nz
check_vgm1
	ld a,(ix+9)
	cp "g"
	jr z,check_vgm2
	cp "G"
	ret nz
check_vgm2
	ld a,(ix+10)
	cp "m"
	ret z
	cp "M"
	ret nz
	xor a ;равен
	ret

	
check_scr ;проверка на расширение SCR
	ld a,(ix+8)
	cp "s"
	jr z,check_scr1
	cp "S"
	ret nz
check_scr1
	ld a,(ix+9)
	cp "c"
	jr z,check_scr2
	cp "C"
	ret nz
check_scr2
	ld a,(ix+10)
	cp "r"
	ret z
	cp "R"
	ret nz
	xor a ;равен
	ret
	

	
print_panel_r ;печать правой панели
	;ld ix,buffer_cat	
	ld iy,(file_r_all) ;всего файлов
	ld a,iyl
	or iyh
	ret z ;защита если 0
	ld de,panel_r_xy ;координаты yx
	ld b,panel_hight ;высота панели
	ld iy,(file_r_cur_focus) ;номер файла первый видимый
print_panel_r_cl ;цикл
	push bc
	push de ;xy
	OS_SET_XY
	
	;получить адрес элемента
	push iy
	pop hl
	call calc_deskr
		
	call print_file_info ;напечатать строку
print_panel_r_skip
	pop de
	inc d ;y++
	inc iy ;текущий файл
	;проверка на конец каталога
	ld hl,(file_r_all)
	push iy
	pop bc
	and a
	sbc hl,bc
	pop bc
	jr c,print_panel_r_ex2
	jr z,print_panel_r_ex2
	djnz print_panel_r_cl
	ret
print_panel_r_ex
	pop de
	pop bc
print_panel_r_ex2	
	;тут, возможно, надо допечатать пустые строки
	ret


	
	
	
print_file_info ;печать строки о файле
	ld a,(LFN_enable_flag)
	or a
	jr z,print_file_info_SFN
	


print_file_info_LFN ;печать длинного имени
	;узнать номер записи
	ld bc,#c000
	and a
	sbc hl,bc
;разделить на 32
	srl h ; младший бит придёт на флаг C , на старший бит придёт 0
	rr l ; младший бит придёт на флаг C, на старший флаг C
	srl h ; /4
	rr l ; 
	srl h ; /8
	rr l ; 
	srl h ; /16
	rr l ; 
	srl h ; /32
	rr l ; 


	ex de,hl ;de - порядковый номер записи
	
	ld hl,file_info_string ;куда
	OS_GET_LFN ;получить длинное имя
	
	call get_color_item
	
	ld b,#c	
	OS_SET_COLOR	
	
	;печать не длиннее 80/2 символов
	ld hl,file_info_string
	ld b,80/2-2
	ld c,40 ;колонка
print_file_info_LFN_cl
	push hl
	push bc
	ld a,(hl)
	or a
	jr z,print_file_info_LFN_cl_ex
	OS_PRINT_CHARF
	pop bc
	inc c
	pop hl
	inc hl
	djnz print_file_info_LFN_cl
	jr print_file_info_LFN_ex
print_file_info_LFN_cl_ex
	pop bc
	pop hl
print_file_info_LFN_ex
	;допечатать пробелы до правого края, зависит от длины имени
print_file_info_LFN_cl2
	ld a,c
	cp 80-2
	ret nc
	push bc
	ld a,' '
	OS_PRINT_CHARF
	pop bc
	inc c
	jr print_file_info_LFN_cl2



print_file_info_SFN ;печать короткого имени
	ld de,file_info_string ;скопировать
	ld bc,8 ;file_info_lenght
	ldir
	ld a,' '
	ld (de),a
	inc de
	ld bc,3
	ldir
	xor a
	ld (de),a

	call get_color_item
	
	ld b,#c	
	OS_SET_COLOR	
	ld hl,file_info_string
	OS_PRINTZ
	;допечатать пробелы до правого края, длина имени постоянная
	ld hl,file_info_string_SFN_end
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
	jr z,get_color_item_dir
	cp #30 ;признак каталога
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

	
	
; format_dir ;подготовить каталог, убрать лишнее
	; ; ld a,2
	; ; out (254),a
	; ld iy,0 ;счётчик файлов	
	; ;найти конец каталога
	; ld hl,buffer_cat
	; ld a,(hl)
	; or a
	; ret z ;защита
	; ld bc,32
; format_dir_prep_cl
	; ld a,(hl)
	; or a
	; jr z,format_dir_prep_ex
	; add hl,bc
	; ld a,h
	; or a ;если вышли за границу	
	; jr z,format_dir_prep_ex
	; jr format_dir_prep_cl
; format_dir_prep_ex
	; ld bc,32
	; and a
	; sbc hl,bc
	; ld (format_dir_top),hl ;конец каталога



	; ld ix,buffer_cat	
	; ;ld b,panel_hight ;высота панели
; format_dir_cl ;цикл
	; ld a,(ix)
	; or a ;конец каталога
	; jr z,format_dir_ex
	; cp #e5 ;удалённый
	; jr z,format_dir_skip
	; cp #05 ;удалённый	
	; jr z,format_dir_skip	
	; ld a,(ix+#0b)
	; cp #0f ;длинный	
	; jr z,format_dir_skip
	
	; ;проверка на папку "." (этот же каталог)
	; ld a,(ix+#00)
	; cp "." ;	
	; jr nz,format_dir_add
	; ld a,(ix+#01)
	; cp " " ;
	; jr z,format_dir_skip	
	
	
; format_dir_add	
	; inc iy ;++
	; ld bc,32 ;на другой элемент каталога
	; add ix,bc
	; ld a,ixh
	; or a ;если вышли за границу
	; jr z,format_dir_ex	
	; jr format_dir_cl
; format_dir_skip
	; ;сдвинуть элементы вниз
	; push ix
	; push ix
	; pop hl 
	; pop de ;куда
	; ld hl,(format_dir_top) ;0-32
	; and a
	; sbc hl,de
	; ld b,h
	; ld c,l ;длина
	; push bc
	
	; push ix
	; pop hl ;откуда
	; ld bc,32 ;на другой элемент каталога
	; add hl,bc ;откуда

	; pop bc
	; ldir
	
	; xor a
	; ld (de),a ;очистить ненужный элемент
	
	; jr format_dir_cl

; format_dir_ex
	; ld (file_r_all),iy
	; ;здесь почистить остаток каталога
	; ; ld a,0
	; ; out (254),a
	; ret
; format_dir_top	dw 0 ;временно конец гаталога
	
	
	
	
	
sort_dir ;сортировка каталога с помощью построения индекса
	ld ix,buffer_cat	;каталог тут
	ld a,(ix)
	or a
	ret z ;если пусто, выход
	ld iy,0 ;счётчик
	ld hl,cat_index ;таблица - индекс
	
	ld a,(sort_enable_flag)
	or a
	jp z,sort_dir_no
	
	xor a
	ld (sort_item),a ;образец для сравнения
sort_dir_cl
	call sort_dir_one ;один проход по папкам
	ld a,(sort_item)
	inc a ;следующий образец
	ld (sort_item),a
	jr nz,sort_dir_cl
	
	; xor a
	; ld (sort_item),a ;образец для сравнения
sort_file_cl
	call sort_file_one ;один проход по файлам
	ld a,(sort_item)
	inc a ;следующий образец
	ld (sort_item),a
	jr nz,sort_file_cl
	
	ret
	
sort_item db 0; текущий образец



;без сортировки
sort_dir_no
	ld ix,buffer_cat	;каталог тут
sort_dir_no_cl ;цикл по каталогам
	ld a,(ix)
	or a ;конец каталога
	jr z,sort_dir_no_ex
	cp #e5 ;удалённый
	jr z,sort_dir_no_skip
	cp #05 ;удалённый	
	jr z,sort_dir_no_skip	
	ld a,(ix+#0b)
	cp #0f ;длинный	
	jr z,sort_dir_no_skip
	
	;проверка на папку "." (этот же каталог)
	ld a,(ix+#00)
	cp "." ;	
	jr nz,sort_dir_no_add
	ld a,(ix+#01)
	cp " " ;
	jr z,sort_dir_no_skip	
	
sort_dir_no_add	
	inc iy ;++
	;записать в таблицу (индекс)
	push ix
	pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	
	
sort_dir_no_skip
	ld bc,32
	add ix,bc ;на следующий
	ld a,ixh ;проверка на конец буфера
	cp #c0
	jr nc,sort_dir_no_cl

sort_dir_no_ex
	ld (file_r_all),iy
	ret


;сортировка файлов
sort_file_one
	ld ix,buffer_cat	;каталог тут
sort_file_one_cl ;цикл по каталогам
	ld a,(ix)
	or a ;конец каталога
	jr z,sort_file_one_ex
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jr z,sort_file_one_skip
	cp #30 ;признак каталога
	jr z,sort_file_one_skip
	ld a,(ix)
	cp #e5 ;удалённый
	jr z,sort_file_one_skip
	cp #05 ;удалённый	
	jr z,sort_file_one_skip	
	ld a,(ix+#0b)
	cp #0f ;длинный	
	jr z,sort_file_one_skip
	
	; ;проверка на папку "." (этот же каталог)
	; ld a,(ix+#00)
	; cp "." ;	
	; jr nz,sort_file_one_add
	; ld a,(ix+#01)
	; cp " " ;
	; jr z,sort_file_one_skip	
	
	
sort_file_one_add	
	ld a,(sort_item)
	cp (ix+#00) ;первая буква имени
	jr nz,sort_file_one_skip ;пока не подошла
	
	inc iy ;++
	;записать в таблицу (индекс)
	push ix
	pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	
	
sort_file_one_skip
	ld bc,32
	add ix,bc ;на следующий
	ld a,ixh ;проверка на конец буфера
	cp #c0
	jr nc,sort_file_one_cl

sort_file_one_ex
	ld (file_r_all),iy
	ret
	
	
	
	
	
;сортировка папок
sort_dir_one
	ld ix,buffer_cat	;каталог тут
sort_dir_one_cl ;цикл по каталогам
	ld a,(ix)
	or a ;конец каталога
	jr z,sort_dir_one_ex
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jr z,sort_dir_one_skip_no
	cp #30 ;признак каталога
	jr nz,sort_dir_one_skip
sort_dir_one_skip_no
	ld a,(ix)	
	cp #e5 ;удалённый
	jr z,sort_dir_one_skip
	cp #05 ;удалённый	
	jr z,sort_dir_one_skip	
	ld a,(ix+#0b)
	cp #0f ;длинный	
	jr z,sort_dir_one_skip
	
	;проверка на папку "." (этот же каталог)
	ld a,(ix+#00)
	cp "." ;	
	jr nz,sort_dir_one_add
	ld a,(ix+#01)
	cp " " ;
	jr z,sort_dir_one_skip	
	
sort_dir_one_add	
	ld a,(sort_item)
	cp (ix+#00) ;первая буква имени
	jr nz,sort_dir_one_skip ;пока не подошла
	
	inc iy ;++
	;записать в таблицу (индекс)
	push ix
	pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	
	
sort_dir_one_skip
	ld bc,32
	add ix,bc ;на следующий
	ld a,ixh ;проверка на конец буфера
	cp #c0
	jr nc,sort_dir_one_cl

sort_dir_one_ex
	ld (file_r_all),iy
	ret







sort_toggle ;переключение сортировки
	ld a,(sort_enable_flag)
	xor 1
	ld (sort_enable_flag),a
	ld a,"f" ;вкл
	jr nz,sort_toggle1
	ld a,"N";выкл
sort_toggle1	
	ld (msg_menu_main2+5),a
	
	call sort_dir
	call print_menu_main
	ld a,1
	ld (print_panel_r_flag),a
	
	jp nc_wait
sort_enable_flag db 0 ;флаг сортировки




LFN_toggle ;переключение сортировки
	ld a,(LFN_enable_flag)
	xor 1
	ld (LFN_enable_flag),a
	ld a,"f" ;вкл
	jr nz,LFN_toggle1
	ld a,"N";выкл
LFN_toggle1	
	ld (msg_menu_main1+5),a
	
	;call sort_dir
	call print_menu_main
	ld a,1
	ld (print_panel_r_flag),a
	
	jp nc_wait
LFN_enable_flag db 0 ;флаг сортировки



	
	
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
	ld a,color_default ;цвет
	ld b,#c
	OS_SET_COLOR
	
	ld de,#1800+0*8
	OS_SET_XY
	ld a,"1" ;пункт 1
	OS_PRINT_CHARF
	ld de,#1800+1*8
	OS_SET_XY
	ld a,"2" ;пункт 2
	OS_PRINT_CHARF
	ld de,#1800+2*8
	OS_SET_XY
	ld a,"3" ;пункт 3
	OS_PRINT_CHARF


	ld a,color_backgr_hi ;цвет
	ld b,#c
	OS_SET_COLOR
	
	ld de,#1800+0*8+1
	OS_SET_XY
	ld hl,msg_menu_main1
	OS_PRINTZ	
	ld de,#1800+1*8+1
	OS_SET_XY
	ld hl,msg_menu_main2
	OS_PRINTZ
	ld de,#1800+2*8+1
	OS_SET_XY
	ld hl,msg_menu_main3
	OS_PRINTZ
	ret
	
	
	include nc_view.asm ;просмотрщик
	include GPlay/gplay.asm ;плеер
	include nc_pic_view.asm ;просмотр картинок

color_default equ 0*8+7 ;цвет обычный системный
color_view_text equ 4 ;цвет текста в просмотрщике

color_backgr equ 1*8+7 ;цвет фона
color_apg equ 1*8+4 ;цвет приложений
color_dir equ 1*8+6 ;цвет папок

color_backgr_hi equ 5*8+0 ;цвет фона курсор
color_apg_hi equ 5*8+0 ;цвет приложений курсор
color_dir_hi equ 5*8+0 ;цвет папок курсор

file_info_lenght equ 255 ;длина инфо о файле
panel_hight equ 22;высота панели	
panel_r_xy equ #0129	
buffer_cat equ #c000 ;адрес буфера каталога

file_r_all dw 0;всего файлов справа
file_r_cur_focus dw 0;первый видимый
file_name_cur ds 256 ;имя файла текущее
dir_name_cur ds 256 ;имя файла текущее
file_info_clear db "            ",0 ;для очистки
buffer_cat_page_r db 0 ;страница буфера каталога правый

file_r_num_cur dw 0 ;текущий файл справа
key_pressed db 0 ;последняя клавиша	
file_id_cur_r db 0 ;id файла справа


page_ext01 db 0 ;номер дополнительной страницы
page_main dw 0 ;основные номера страниц слота 2,3
print_panel_r_flag db 0 ;флаг что надо обновить правую панель
file_info_string_SFN_end db '                          ',0 ;пробелы для забоя конца строки


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

;file_name_test db '486 HEART ON FIRE.vgm',0
msg_menu_info
	db 13,"CS+Enter - Play all",0
msg_menu_main1
	db " LF On",0
msg_menu_main2
	db " AZ On",0
msg_menu_main3	
	db " View",0
msg_file_error
	db "File error",10,13,0
msg_file_too_big
	db "File too big",10,13,0
msg_mem_err
	db "Get memory error",10,13,0
msg_title_nc
	db "None Commander ver 2025.07.24",10,13,0

end_nc
;ниже не включается в файл
cat_index ds 1024 ;буфер для индекса (вектора) сортировки
file_info_string ds file_info_lenght+1 ;буфер инфо
;ещё тут буферы плеера

	savebin "nc.apg",start_nc,$-start_nc