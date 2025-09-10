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
get_page_error1
	call delay
	jp exit
	
get_page_ok
	ld (page_ext01),a ;запомнить


	OS_GET_PAGE ;получить лишнюю страницу для gzip
	jr c,get_page_error
	ld (page_ext02_gzip),a ;запомнить

	ld hl,msg_load_gzip
	OS_PRINTZ
	
	ld a,(page_ext02_gzip) ;доп страница для данных плеера
	OS_SET_PAGE_SLOT3
	
	ld hl,gp_gzip_file_name
	call load_file
	jr c,get_page_error1
	ld (gp_gzip_file_size),hl ;запомнить размер
	
	
	ld a,(page_main) ;основная страница с каталогом
	OS_SET_PAGE_SLOT3
	
	;почистить начало истории
	xor a ;в историю курсора , начинаем не с корневой папки
	; ld (file_r_num_hyst_cur),a
	ld h,a
	ld l,a
	ld (file_r_num_hyst_tabl),hl
	ld (file_r_num_hyst_tabl+2),hl ;для корневой папки почистим
	
	call file_r_num_hyst_add ;запись в историю с номером 1
	
start_nc_warm ;тёплый старт
	ld hl,0 ;обнулить переменные
	ld (file_r_num_cur),hl
	ld (file_r_num_old),hl
	ld (file_r_cur_focus),hl
	
start_nc_warm1

	ld hl,0 ;обнулить переменные
	ld (file_r_all),hl	
	
	;очистка буфера
	call clear_buf
	
	;загрузка каталога
	ld hl,buffer_cat ;куда
	ld de,0 ;начиная с 0 сектора
	ld b,32 ; секторов = 16384 = 512 файлов макс
	OS_DIR_READ

	call sort_dir
	
	ld a,(key_enter_dir_flag) ;
	or a
	jr z,start_nc_warm2
	call file_r_num_hyst_get ;вспомнить позицию курсора
	xor a
	ld (key_enter_dir_flag),a
start_nc_warm2	
	
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
	cp "4" ;редактор файла
	jp z,edit_file
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
	ld b,50*2 ;
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
	jp c,key_enter_ex
	
	ld a,(ix)
	OS_PROC_SET_FOCUS ;на передний план
	jp key_enter_ex



key_enter_1
	;проверка расширения VGZ
	call check_vgz
	jp nz,key_enter_2_1
	
	ld a,"z" ;код формата
	call start_gplay
	
	jr key_enter_ex	
	
	
key_enter_2_1
	;проверка расширения VGM
	call check_vgm
	jp nz,key_enter_2
	
	ld a,"v" ;код формата
	call start_gplay
	
	jr key_enter_ex


key_enter_2
	;проверка расширения SCR
	call check_scr
	jp nz,key_enter_3
	
	call display ;показать

	jr key_enter_ex


key_enter_3
	;проверка расширения MOD
	call check_mod
	jp nz,key_enter_4
	
	ld a,"m" ;код формата
	call start_gplay
	
	jr key_enter_ex


key_enter_4
	;проверка расширения PT2
	call check_pt2
	jp nz,key_enter_5
	
	ld a,"2" ;код формата
	call start_gplay
	
	jr key_enter_ex


key_enter_5
	;проверка расширения PT3
	call check_pt3
	jp nz,key_enter_6
	
	ld a,"3" ;код формата
	call start_gplay
	
	jr key_enter_ex

	

key_enter_6




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
	
	ld a,"v"
	call start_gplay

nc_play_1_next

	cp "s"
	jr z,nc_play_ex
	cp "S"
	jr z,nc_play_ex
	cp 24 ;break
	jr z,nc_play_ex
	
	jr nc_play_all_down

nc_play_2
	;проверка расширения ;VGZ
	call check_vgz
	jp nz,nc_play_3
	
	ld a,"z"
	call start_gplay

	jr nc_play_1_next


nc_play_3
	;проверка расширения MOD
	call check_mod
	jp nz,nc_play_4
	
	ld a,"m"
	call start_gplay

	jr nc_play_1_next


nc_play_4
	;проверка расширения pt2
	call check_pt2
	jp nz,nc_play_5
	
	ld a,"2"
	call start_gplay

	jr nc_play_1_next
	
nc_play_5
	;проверка расширения pt3
	call check_pt3
	jp nz,nc_play_6
	
	ld a,"3"
	call start_gplay

	jr nc_play_1_next
	

nc_play_6
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
	
	;определить идём вглубь (вперёд) или наверх (назад) 
	xor a
	ld (key_enter_dir_flag),a 
	
	ld a,(ix+#00)
	cp "."
	jr nz,key_enter_dir1
	ld a,(ix+#01)
	cp "."
	jr nz,key_enter_dir1
	;идём назад
	ld a,1
	ld (key_enter_dir_flag),a
	
key_enter_dir1
	;call format_name_dir
	ex de,hl ;de - дескриптор для открытия
	ld hl,dir_name_cur
	OS_DIR_OPEN
	jp c,key_enter_ex ;если ошибка, ничего не делаем
	
	pop hl ;отменить возврат
	ld a,0
key_enter_dir_flag equ $-1
	or a
	jp nz,start_nc_warm
	call file_r_num_hyst_add ;запомнить позицию курсора в истории
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
	ld (file_r_num_old),bc ;запомнить что было
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

	ld a,1
	ld (print_panel_r_flag),a ;напечатать всё снова
	
	ld a,(key_pressed)
	ret
	
key_down_change_focus_no	

	;call print_panel_r ;обновить каталог

	call print_panel_r_cursor ;обновить только курсор
	
key_down_ex
	
key_down_skip
	ld a,(key_pressed)
	ret
	
	
	
key_up ;вверх
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,key_up_ex ;защита
	
	ld hl,(file_r_num_cur)
	ld (file_r_num_old),hl
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
	
	ld a,1
	ld (print_panel_r_flag),a	;напечатать снова всё
	
	ld a,(key_pressed)
	ret
	
key_up_change_foces_no	
	
	;call print_panel_r ;обновить каталог
	call print_panel_r_cursor ;обновить только курсор
	
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
	
check_vgz ;проверка на расширение VGZ
	ld a,(ix+8)
	cp "v"
	jr z,check_vgz1
	cp "V"
	ret nz
check_vgz1
	ld a,(ix+9)
	cp "g"
	jr z,check_vgz2
	cp "G"
	ret nz
check_vgz2
	ld a,(ix+10)
	cp "z"
	ret z
	cp "Z"
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
	
check_mod ;проверка на расширение MOD
	ld a,(ix+8)
	cp "m"
	jr z,check_mod1
	cp "M"
	ret nz
check_mod1
	ld a,(ix+9)
	cp "o"
	jr z,check_mod2
	cp "O"
	ret nz
check_mod2
	ld a,(ix+10)
	cp "d"
	ret z
	cp "D"
	ret nz
	xor a ;равен
	ret
	

check_pt2 ;проверка на расширение pt2
	ld a,(ix+8)
	cp "p"
	jr z,check_pt21
	cp "P"
	ret nz
check_pt21
	ld a,(ix+9)
	cp "t"
	jr z,check_pt22
	cp "T"
	ret nz
check_pt22
	ld a,(ix+10)
	cp "2"
	ret z
	cp "2"
	ret nz
	xor a ;равен
	ret

check_pt3 ;проверка на расширение pt3
	ld a,(ix+8)
	cp "p"
	jr z,check_pt31
	cp "P"
	ret nz
check_pt31
	ld a,(ix+9)
	cp "t"
	jr z,check_pt32
	cp "T"
	ret nz
check_pt32
	ld a,(ix+10)
	cp "3"
	ret z
	cp "3"
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
;print_panel_r_skip
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








print_panel_r_cursor ;печать только строки с курсором в правой панели, для скорости навигации
	ld bc,(file_r_num_old) ;старая позиция
	ld (file_r_num_tmp),bc ;позиция курсора для печати
	call print_panel_r_cursor_one ;"стереть" предыдущее
	ld bc,(file_r_num_cur) ;позиция текущая
	ld (file_r_num_tmp),bc ;позиция курсора для печати
	call print_panel_r_cursor_one ;напечатать новое
	ret


print_panel_r_cursor_one
	;ld ix,buffer_cat	
	ld iy,(file_r_all) ;всего файлов
	ld a,iyl
	or iyh
	ret z ;защита если 0
	ld de,panel_r_xy ;координаты yx
	ld b,panel_hight ;высота панели
	ld iy,(file_r_cur_focus) ;номер файла первый видимый
print_panel_r_cursor_cl ;цикл
	push bc
	push de
	;проверить дошли ли до курсора
	ld bc,(file_r_num_tmp) ;позиция курсора справа
	push iy
	pop hl
	and a
	sbc hl,bc ;сравнить
	jr nz,print_panel_r_cursor_skip
	;напечатать курсор
	;push bc
	;push de ;xy
	OS_SET_XY
	
	;получить адрес элемента
	push iy
	pop hl
	call calc_deskr
		
	call print_file_info ;напечатать строку
print_panel_r_cursor_skip
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
	jr c,print_panel_r_cursor_ex2
	jr z,print_panel_r_cursor_ex2
	djnz print_panel_r_cursor_cl
	ret
print_panel_r_cursor_ex
	pop de
	pop bc
print_panel_r_cursor_ex2	
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
	ld iy,0 ;счётчик всего файлов


	ld a,(sort_enable_flag)
	or a
	jp z,sort_dir_no ;если без сортировки
	
	ld hl,cat_index
	ld (sort_item_adr_end),hl
	
	ld hl,cat_index_2 ;таблица - индекс 2
	call sort_dir_one ;проход по папкам

	ld a,iyh
	or iyl
	jr z,sort_dir_skip ;если не было папок
	
	ld ix,cat_index_2
	call sort_index ;отсортировать по алфавиту	
	;перенести индекс в основной
	push iy
	pop hl ;сколько
	add hl,hl ;*2 по 2 байта на элемент
	push hl
	pop bc
	ld hl,cat_index_2
	ld de,cat_index
	ldir
	ld (sort_item_adr_end),de ;запомнить адрес последнего
	
sort_dir_skip
	ld (sort_item_count),iy
	ld iy,0 ;счётчик всего файлов
	ld hl,cat_index_2 ;таблица - индекс 2
	call sort_file_one ;проход по файлам
	ld a,iyh
	or iyl
	jr z,sort_file_skip ;если не было файлов
	
	ld ix,cat_index_2
	call sort_index ;отсортировать по алфавиту		
	;добавить индекс к основному
	push iy
	pop hl ;сколько
	add hl,hl ;*2 по 2 байта на элемент
	push hl
	pop bc
	ld hl,cat_index_2	
	ld de,(sort_item_adr_end)
	ldir
	
sort_file_skip	
	;скорректировать количество
	ld bc,(sort_item_count)
	add iy,bc
	ld (file_r_all),iy	
	ret
	
sort_item_adr_end dw 0; временно
sort_item_count dw 0; временно



;без сортировки
sort_dir_no
	ld hl,cat_index ;таблица - индекс
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
	;ld (file_r_all),iy
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
	;ld (file_r_all),iy
	ret



;сортировка индекса методом пузырька
;вх: iy - сколько (>1)
;вх: ix - адрес таблицы
sort_index
	ld a,iyh ;проверка, число элементов должно быть > 1
	or a
	jr nz,sort_index1
	ld a,iyl
	cp 2
	ret c
sort_index1	
	push iy 
	pop bc ;цикл проходов общий
	dec bc ;-1
	
sort_index_cl_gen ;цикл основной
	push bc
	push ix

	push iy
	pop bc ;внутренний цикл столько же
	dec bc ;-1
	
	xor a ;флаг
	ld (sort_index_flag),a 	
	
sort_index_cl ;цикл внутренний
	;первый элемент узнать адрес записи в каталоге
	ld e,(ix+00)
	ld d,(ix+01)
	ld a,(de) ;первая буква имени
	;второй элемент узнать адрес записи в каталоге	
	ld l,(ix+02)
	ld h,(ix+03)
	;сравнить с другой первой буквой
	cp (hl) 
	jr c,sort_index_cl_skip
	
	ld a,1
	ld (sort_index_flag),a ;флаг были изменения
	;поменять местами элементы индекса
	ld (ix+00),l
	ld (ix+01),h
	ld (ix+02),e
	ld (ix+03),d
	
sort_index_cl_skip
	;следующий
	inc ix
	inc ix
	
	dec bc
	ld a,b
	or c
	jr nz,sort_index_cl
	
	pop ix
	pop bc
	dec bc
	
	ld a,(sort_index_flag)
	or a
	ret z ;если не было изменений за проход, можно выходить
	
	ld a,b
	or c
	jr nz,sort_index_cl_gen	
	
	ret

sort_index_flag db 0;


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
	ld de,#1800+3*8
	OS_SET_XY
	ld a,"4" ;пункт 4
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
	ld de,#1800+3*8+1
	OS_SET_XY
	ld hl,msg_menu_main4
	OS_PRINTZ
	ret
	
	
	
;прочитать файл не больше #4000 байт
;вх: hl - имя файла 
;вых: CY = 1 = ошибка, hl - размер прочитанного
load_file 
	;ld hl,file_name_cur
	OS_FILE_OPEN ;HL - File name (out: A - id file, de hl - size, IX - fcb)
	jp c,load_file_error	
	ld (load_file_size),hl ;размер
;load_file_ok
	ld (file_id_cur_r),a
	;проверка длины файла не больше #4000
	ld	a,d ;самые старшие байты длины
	or e
	jr z,load_file_size_ok ;если не слищком большой
load_file_too_big
	;файл больше буфера
	ld a,color_error ;цвет ошибки
	ld b,#c
	OS_SET_COLOR

	ld hl,msg_file_too_big
	OS_PRINTZ
	
	ld a,color_backgr ;цвет основной
	ld b,#c
	OS_SET_COLOR
	
	;call delay
	scf
	ret


load_file_size_ok	
	ld	a,h ;младший старший байт длины
	cp #40
	jr c,load_file_size_ok_small
	jr nz,load_file_too_big
	inc l
	dec l
	jr nz,load_file_too_big
	
	
load_file_size_ok_small
	;проверка на 0
	ld a,h
	or l
	jp z,load_file_error
	ld d,h ;размер
	ld e,l
	ld hl,buffer_cat ;куда
	ld a,(file_id_cur_r)
	OS_FILE_READ ;загрузить
	jr c,load_file_error
	
	ld a,(file_id_cur_r)
	OS_FILE_CLOSE ;A - id file
	
	ld hl,(load_file_size)
	xor a
	ret


	
load_file_error
	ld a,color_error ;цвет ошибки
	ld b,#c
	OS_SET_COLOR
		ld hl,msg_file_error
		OS_PRINTZ
	ld a,color_backgr ;цвет основной
	ld b,#c
	OS_SET_COLOR	
		
		ld a,(file_id_cur_r)
		cp 255
		jr z,load_file_error1
		OS_FILE_CLOSE ;A - id file
load_file_error1

	;call delay
		scf ;ошибка
		ret
load_file_size dw 0 ;временно







;добавить в историю положение курсора
file_r_num_hyst_add
	ld a,(file_r_num_hyst_cur)
	inc a
	ld (file_r_num_hyst_cur),a
	cp file_r_num_hyst_tabl_max
	jr nc,file_r_num_hyst_add_err
	;узнать адрес в таблице
	ld l,a
	ld h,0
	add hl,hl ;по 4 байта на запись
	add hl,hl
	ld bc,file_r_num_hyst_tabl
	add hl,bc
	;записать
	ld bc,(file_r_num_cur)
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ld bc,(file_r_cur_focus)
	ld (hl),c
	inc hl
	ld (hl),b
	; ld (file_r_num_old),hl
	ret
	
file_r_num_hyst_add_err
	;место для истории кончилось
	ret


	
;взять из истории положение курсора 
file_r_num_hyst_get
	ld a,(file_r_num_hyst_cur)
	or a
	jr z,file_r_num_hyst_get_err
	dec a
	ld (file_r_num_hyst_cur),a ;будет следующий 
	inc a
	cp file_r_num_hyst_tabl_max
	jr nc,file_r_num_hyst_get_err
	;узнать адрес в таблице
	ld l,a
	ld h,0
	add hl,hl ;по 4 байта на запись
	add hl,hl
	ld bc,file_r_num_hyst_tabl
	add hl,bc
	;считать
	;ld bc,(file_r_num_cur)
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	;ld bc,(file_r_cur_focus)
	ld e,(hl)
	inc hl
	ld d,(hl)
	;сравнить. а вдруг в этой папке уже нет столько файлов
	ld hl,(file_r_all)	
	and a
	sbc hl,bc
	jr c,file_r_num_hyst_get_err
	;восстановить
	ld (file_r_num_cur),bc
	ld (file_r_num_old),bc
	ld (file_r_cur_focus),de
	ret



file_r_num_hyst_get_err
	;если в истории не нашли
	ld hl,0
	ld (file_r_num_cur),hl
	ld (file_r_num_old),hl
	ld (file_r_cur_focus),hl
	ret





	include nc_view.asm ;просмотрщик
	include nc_edit.asm ;редактор
	include GPlay/gplay.asm ;плеер
	include nc_pic_view.asm ;просмотр картинок

color_error equ 1*8+2 ;цвет ошибка
color_default equ 0*8+7 ;цвет обычный системный
color_view_text equ 4 ;цвет текста в просмотрщике
color_edit_text equ 4 ;цвет текста в редакторе
color_edit_cursor equ 4*8+0 ;цвет курсора в редакторе текста

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

file_r_num_hyst_tabl_max equ 10 ;максимальная глубина истории положения курсора

file_r_all dw 0;всего файлов справа
file_r_cur_focus dw 0;первый видимый
file_name_cur ds 256 ;имя файла текущее
dir_name_cur ds 256 ;имя файла текущее
file_info_clear db "            ",0 ;для очистки
buffer_cat_page_r db 0 ;страница буфера каталога правый

file_r_num_cur dw 0 ;текущий файл справа
file_r_num_old dw 0 ;текущий файл справа
file_r_num_tmp dw 0 ;временно
key_pressed db 0 ;последняя клавиша	
file_id_cur_r db 0 ;id файла справа
file_r_num_hyst_cur db 0 ;позиция в истории о номере текущего файла


page_ext01 db 0 ;номер дополнительной страницы
page_ext02_gzip db 0 ;номер дополнительной страницы

gp_gzip_file_name db "gp_gzip.bin",0 ;часть плеера для режима моно, переносится в резервную страницу
gp_gzip_file_size dw 0 ;размер части плеера

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
	db " View ",0
msg_menu_main4	
	db " Edit ",0
msg_file_error
	db "File error",13,0
msg_file_too_big
	db "File too big",13,0
msg_mem_err
	db "Get memory error",13,0
msg_mono_err
	db "Get mono mode error",13,0
msg_load_gzip
	db "Load gzip",13,0
	
msg_title_nc
	db "None Commander ver 2025.09.10",13,0
	

start_gp_gzip equ #4000 ;рабочий адрес модуля для распаковки
start_gp_gzip_ext equ #c000 ;временный адрес модуля для распаковки



end_nc
	savebin "nc.apg",start_nc,$-start_nc

;ниже не включается в файл

cat_index ds 1024 ;буфер для индекса (вектора) сортировки
cat_index_2 ds 1024 ;буфер для индекса (вектора) сортировки 2
file_info_string ds file_info_lenght+1 ;буфер инфо
file_r_num_hyst_tabl ds file_r_num_hyst_tabl_max*4 ;таблица истории положения курсора справа
	ds 4

free equ $ ;тут условно свободно



end_nc_all



	org 0xb800 ;
;ещё тут буферы плеера VGM до адреса #bf00
	
