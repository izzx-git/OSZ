view_file
	;просмотр файла как текста
	
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,view_file_ex ;защита
	ld hl,(file_r_num_cur)
	call calc_deskr
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jp z,view_file_ex
	
	call format_name ;обработать имя файла
	
	
	
	OS_CLS ;почистить экран
	
	;обнулить переменные
	xor a
	ld (view_file_load_all),a ;флаг что файл весь прочитан
	;ld (view_file_bot_flag),a  ;
	ld hl,#ffff
	ld (view_file_end),hl ;конец файла тут
	inc hl
	ld (view_move_right_val),hl
	
	push bc
	call clear_buf
	pop bc
	
	ld hl,file_name_cur		;строка с именем	
	OS_FILE_OPEN
	jr nc,view_file_open_ok
view_file_file_error
	ld hl,msg_file_error
	OS_PRINTZ	
	ld b,2*50
	call delay1
	jp view_file_wait_ex
	
view_file_open_ok
	ld (file_id_cur_r),a
	;проверка длины файла не больше #4000
	ld	a,d ;самые старшие байты длины
	or e
	jr z,view_file_size_ok ;если не слищком большой
view_file_too_big
	;файл больше буфера
	ld de,#4000 ;размер одной первой части
	ld hl,buffer_cat
	ld a,(file_id_cur_r)
	OS_FILE_READ ;загрузить
	jr c,view_file_file_error	
	
	jp view_file_readed
	
view_file_size_ok	
	ld	a,b ;младший старший байт длины
	cp #40
	jr c,view_file_size_ok_small
	jr nz,view_file_too_big
	inc c
	dec c
	jr nz,view_file_too_big
	
	
view_file_size_ok_small
	;проверка на 0
	ld a,b
	or c
	jp z,view_file_file_error
	;узнать где конец файла
	ld hl,buffer_cat
	add hl,bc
	ld (view_file_end),hl ;конец файла тут
	;размер не большой, прочитаем
	ld d,b ;размер
	ld e,c
	ld hl,buffer_cat
	ld a,(file_id_cur_r)
	OS_FILE_READ ;загрузить
	jr c,view_file_file_error

	ld a,1
	ld (view_file_load_all),a ;флаг что файл весь прочитан
	
view_file_readed
	;файл прочитан
	
	ld hl,buffer_cat
	ld (view_file_pos_cur),hl ;позиция просмотра на начало	
	ld (view_file_pos_cur_focus),hl ;позиция фокуса

	call print_file_text
	
	
	call print_menu_view ;меню
	call print_menu_view_top ;инфо
	
	call release_key
	
view_file_wait ;цикл ожидания клавиши
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z,view_file_wait
	cp "3"
	jr z,view_file_wait_ex
	cp 10 ;вниз
	jp z,view_line_down 
	cp 11 ;вверх
	jp z,view_line_up
	cp 09 ;вправо
	jp z,view_right 
	cp 08 ;влево
	jp z,view_left
	cp 04 ;страница вверх
	jp z,view_page_up
	cp 05 ;страница вниз
	jp z,view_page_down
	cp 24 ;break
	jp z,exit
	jr view_file_wait
	
view_file_wait_ex
	;почистить экран
	OS_CLS
	jp start_nc_warm ;перезагрузить папку

view_file_ex
	jp nc_wait
	
	

view_line_down ;вниз на строчку	
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	call next_line ;вперёд на строку
	jr c,view_file_wait ;если не удачно
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	call print_file_text ;напечатать всю страницу
	jr view_file_wait
	
view_line_up ;вверх на строчку
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	call prev_line ;
	jr c,view_file_wait ;если не удачно
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	call print_file_text ;напечатать всю страницу
	jr view_file_wait


view_right ;вправо	
	ld hl,(view_move_right_val)
	inc hl
	ld a,h
	or l
	jr z,view_file_wait
	ld (view_move_right_val),hl
	call print_file_text ;напечатать всю страницу
	jr view_file_wait
	
view_left ;влево
	ld hl,(view_move_right_val)
	ld a,h
	or l
	jr z,view_file_wait
	dec hl
	ld (view_move_right_val),hl
	call print_file_text ;напечатать всю страницу
	jp view_file_wait
	
	
	
view_page_up ;на страницу назад
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	ld b,view_text_bot-2
view_page_up_cl
	call prev_line ;
	jr c,view_page_up_ex ;если не удачно
	jr z,view_page_up_ex
	djnz view_page_up_cl
view_page_up_ex
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	call print_file_text ;напечатать всю страницу	
	jp view_file_wait


	
view_page_down ;на страницу вперёд
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	ld b,view_text_bot-2
view_page_down_cl
	call next_line ;
	jr c,view_page_down_ex ;если не удачно
	jr z,view_page_down_ex
	djnz view_page_down_cl
view_page_down_ex
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	call print_file_text ;напечатать всю страницу
	jp view_file_wait


	
print_menu_view ;печать меню просмотрщика
	ld a,#18
	ld b,color_backgr_hi ;цвет
	OS_PAINT_LINE ;линия внизу
	ld a,color_backgr_hi ;цвет
	ld b,#c
	OS_SET_COLOR
	ld de,#1800+3*8
	OS_SET_XY
	ld hl,msg_menu_view
	OS_PRINTZ
	ret
	
print_menu_view_top ;печать меню просмотрщика верхнее
	xor a
	ld b,color_backgr_hi ;цвет
	OS_PAINT_LINE ;линия вверху
	ld a,color_backgr_hi ;цвет
	ld b,#c
	OS_SET_COLOR
	ld de,#0024
	OS_SET_XY
	ld hl,file_name_cur
	OS_PRINTZ
	ret	
	
	
	
print_file_text	;печать текущей части файла в консоль
	ld a,4 ;цвет
	ld b,#c	
	OS_SET_COLOR

	ld a,view_text_top ;первая строка
	ld (view_file_y_cur),a
	ld hl,(view_file_pos_cur_focus) ;печать видимой части
	ld (view_file_pos_cur),hl	
print_file_text_cl
	ld hl,(view_file_pos_cur)
	call print_line_text
	jr c,print_file_text_ex
	
	; call next_line ;найти следующую строку
	; ret c
	
	ld a,(view_file_y_cur)
	inc a
	ld (view_file_y_cur),a
	cp view_text_bot
	jr c,print_file_text_cl
	ret
	
print_file_text_ex
	;тут очистить остальные строки
	ld a,(view_file_y_cur)
	cp view_text_bot
	jr nc,print_file_text_ex2
	ld h,a
	inc a
	ld (view_file_y_cur),a
	ld a," "
	OS_FILL_LINE ;очистить строку
	jr print_file_text_ex
print_file_text_ex2
	scf
	ret



print_line_text ;печать одной строки до кода 13, или до правого края экрана, или до конца файла
;вх: hl - адрес строки
	call view_move_right ;промотать направо. если надо
	;установить позицию
	ld a,(view_file_y_cur)
	ld d,a
	xor a
	ld (view_file_x_cur),a
	ld e,a
	OS_SET_XY 	;yx
print_line_text_cl ;цикл
	
	ld a,(hl)
	cp 10 ;этот код не печатаем
	jr z,print_line_text_skip
	cp #ff ;этот код не печатаем
	jr z,print_line_text_skip
	cp 13
	jr z,print_line_text_ex_ok
	OS_PRINT_CHARF ;печать
	
	;на следующую позицию
	ld a,(view_file_x_cur)
	inc a
	cp 80 ;правый край экрана
	ld (view_file_x_cur),a
	jr nc,print_line_text_right ;дошли до правого края
	
print_line_text_skip
	call view_file_next_pos ;следующий
	jr nc,print_line_text_cl ;на следующий символ
	ret

	
print_line_text_ex_ok ;выход норма
	;тут надо добить строку пробелами
	ld a," "
	OS_PRINT_CHARF ;печать
	ld a,(view_file_x_cur)
	inc a
	cp 80 ;правый край экрана
	ld (view_file_x_cur),a
	jr c,print_line_text_ex_ok	

	
	call view_file_next_pos ;следующий
	
	ret
; print_line_text_ex_end ;выход если кончился файл
	; scf
	; ret	
	
print_line_text_right
	call next_line ;позицию  до конца строки
	ret



view_move_right ;перемотка строки направо
	ld bc,(view_move_right_val) ;на сколько символов вправо промотать
	ld a,b
	or c
	ret z
	ld hl,(view_file_pos_cur)
view_move_right1
	ld a,(hl)
	cp 10 ;этот код пропускаем
	jr nz,view_move_right2
	call view_file_next_pos
	ret c
	ret z
	jr view_move_right1
view_move_right2
	cp #ff ;этот код пропускаем
	jr nz,view_move_right3
	call view_file_next_pos
	ret c
	ret z
	jr view_move_right1
view_move_right3
	ld a,(hl)
	cp 13 ;
	ret z
view_move_right_cl
	call view_file_next_pos
	ret c
	ret z
	ld a,(hl)
	cp 13
	ret z
	cp 10 ;этот код пропускаем
	jr z,view_move_right_cl 
	dec bc
	ld a,b
	or c
	jr nz,view_move_right_cl
	;call view_file_next_pos ;следующий
	ret


	
;получение следующей позиции
view_file_next_pos 
	ld a,(view_file_load_all) ;флаг что файл весь в памяти
	or a
	jr z,view_file_next_pos_big 
	;если текст не большой
	ld hl,(view_file_end) ;конец текста известен
	ld de,(view_file_pos_cur)
	inc de ;вперёд
	and a
	sbc hl,de
	jr c,view_file_next_pos_end
	ld (view_file_pos_cur),de
	ex de,hl ;на выходе адрес в HL
	or a
	ret


	
view_file_next_pos_big
	;если текст большой	
	ld hl,(view_file_pos_cur)	;текущая позиция
	inc hl ;вперёд
	ld a,h
	cp #c0 ;если вышли за пределы окна
	jr c,view_file_next_pos_end
	ld (view_file_pos_cur),hl
	or a
	ret	
	
view_file_next_pos_end
	;не смогли шагнуть вперёд
	; ld a,1 ;флаг что внизу
	; ld (view_file_bot_flag),a
	scf ;ошибка
	ret
	




	
;получение предыдущей позиции	
view_file_prev_pos 
	ld a,(view_file_load_all) ;флаг что файл весь в памяти
	or a
	jr z,view_file_prev_pos_big 
	;если текст не большой
	ld hl,buffer_cat ;тут лежит текст
	ld de,(view_file_pos_cur) ;текущая позиция
	dec de ;назад
	and a
	sbc hl,de
	jr z,view_file_prev_pos_top ;если пришли в начало
	jr nc,view_file_prev_pos_end
	;можно шагнуть назад
	ld (view_file_pos_cur),de
	ex de,hl ;на выходе адрес в HL
	xor a
	inc a ;a=1
	ret
view_file_prev_pos_top
	;если в начале
	ld (view_file_pos_cur),de
	ex de,hl ;на выходе адрес в HL	
	xor a ;a=0
	ret

	
view_file_prev_pos_big
	;если текст большой	
	ld hl,(view_file_pos_cur)	;текущая позиция
	dec hl ;назад
	ld a,h
	cp #c0 ;если вышли за пределы окна
	jr c,view_file_prev_pos_end
	ld (view_file_pos_cur),hl	
	or a
	ret	
	
view_file_prev_pos_end
	;не смогли шагнуть назад
	; ld hl,buffer_cat ;тут лежит текст
	; ld (view_file_pos_cur),hl ;текущая позиция в самом начале
	scf ;ошибка
	ret	
	
	
	
	
next_line ;поиск следующей строки
	call view_file_next_pos
	ret c
	ret z
	ld a,(hl)
	cp 13
	jr nz,next_line
	call view_file_next_pos ;ещё на символ
	ret
	


prev_line ;поиск предыдущей строки
	;сначала в конец предыдущей
	call view_file_prev_pos
	ret z
	ret c
	ld a,(hl)
	cp 13
	jr nz,prev_line
	;теперь в начало предыдущей
prev_line1	
	call view_file_prev_pos
	ret z
	ret c
	ld a,(hl)
	cp 13
	jr nz,prev_line1
	call view_file_next_pos ;ещё на символ обратно	
	ret
	
	
	
view_text_bot equ 24 ;последняя строка для печати
view_text_top equ 1 ;первая строка
view_text_lines equ 25-2 ;видимых строк на экране

msg_menu_view
	db "3 Exit",0
	
;view_file_position ds 4 ;текущая позиция в файле
;view_file_bot_flag db 0 ;флаг что домотали вниз до конца
view_move_right_val dw 0 ;сдвиг вправо
view_file_pos_cur dw 0;текущая позиция
view_file_pos_cur_focus dw 0 ;позиция фокуса
view_file_y_cur db 0;текущая строка
view_file_x_cur db 0;текущий столбец
view_file_load_all db 0 ;флаг что файл весь загружен
view_file_end dw 0 ;конец файлв, или текущего куска
 
	