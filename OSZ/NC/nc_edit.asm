edit_file
	;редактирование файла как текста, размер не больше #4000
	
	ld hl,(file_r_all)
	ld a,l
	or h
	jp z,edit_file_ex ;защита
	ld hl,(file_r_num_cur)
	call calc_deskr
	ld a,(ix+#0b) 
	cp #10 ;признак каталога
	jp z,edit_file_ex
	cp #30 ;признак каталога
	jp z,edit_file_ex
	
	call format_name ;обработать имя файла
	
	
	ld a,(page_ext01) ;доп страница для данных
	OS_SET_PAGE_SLOT3
	
	ld de,#0000
	OS_SET_XY
	
	;обнулить переменные
	;ld (edit_file_bot_flag),a  ;
	;ld hl,#ffff
	ld a,1
	ld (view_file_load_all),a ;флаг что файл весь прочитан
	ld hl,0
	ld (view_move_right_val),hl ;сдвиг вправо 0

	xor a
	ld (edit_file_save_flag),a ;флаг для сохранения

	ld hl,buffer_cat
	ld (view_file_pos_cur),hl ;позиция просмотра на начало	
	ld (view_file_pos_cur_focus),hl ;позиция фокуса
	ld (edit_file_pos_cur),hl ;позиция курсора
	ld (edit_file_pos_old),hl ;позиция курсора
	
	;push bc
	call clear_buf
	;pop bc 
	
	ld a,255
	ld (file_id_cur_r),a
	ld hl,file_name_cur		;строка с именем	
	call load_file ;загрузить целиком
	jp c,edit_file_ex
	
	ld (edit_file_size),hl ;размер
	ld bc,buffer_cat
	add hl,bc
	ld (view_file_end),hl ;конец файла тут
	
	;файл прочитан
	OS_CLS ;почистить экран	
	
	call print_file_text
	call print_file_cursor
	
	
	call print_menu_edit ;меню
	call print_menu_view_top ;инфо
	
	call release_key
	
edit_file_wait ;цикл ожидания клавиши
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z,edit_file_wait
	ld (key_pressed),a ;запомнить
	; cp "3"
	; jr z,edit_file_wait_ex
	cp 10 ;вниз
	jp z,edit_file_down 
	cp 11 ;вверх
	jp z,edit_file_up
	cp 09 ;вправо
	jp z,edit_right 
	cp 08 ;влево
	jp z,edit_left
	cp 04 ;страница вверх
	jp z,edit_page_up
	cp 05 ;страница вниз
	jp z,edit_page_down
	cp 12 ;backspace
	jp z,edit_file_backspace
	cp 24 ;break
	jp z,edit_file_wait_ex
	cp " " ;печатаем сиволы от пробела и выше
	call nc,edit_file_insert_sym ;вставить символ
	cp 13 ;enter
	call z,edit_file_insert_sym ;вставить символ
	jr edit_file_wait
	
edit_file_wait_ex
	call release_key
	
	ld a,(edit_file_save_flag)
	or a
	jr z,edit_file_wait_ex1
	;запрос на сохранение
	
	ld de,0
	OS_SET_XY
	ld hl,msg_menu_edit_save
	OS_PRINTZ
	
edit_file_wait_ex_wait	
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z,edit_file_wait_ex_wait
	cp "y" ;да
	jr z,edit_file_save
	cp "Y" ;да
	jr z,edit_file_save	
	; cp "н" ;да
	; jr z,edit_file_save
	; cp "Н" ;да
	; jr z,edit_file_save	
	cp "n" ;нет
	jr z,edit_file_wait_ex1
	cp "N" ;нет
	jr z,edit_file_wait_ex1
	; cp "т" ;нет
	; jr z,edit_file_wait_ex1
	; cp "Т" ;нет
	; jr z,edit_file_wait_ex1
	jr edit_file_wait_ex_wait
	
edit_file_wait_ex1
	ld a,(page_main) ;основная страница с каталогом
	OS_SET_PAGE_SLOT3
	;почистить экран
	OS_CLS
	jp start_nc_warm1 ;перезагрузить папку



edit_file_ex
	ld a,(page_main) ;основная страница с каталогом
	OS_SET_PAGE_SLOT3
	jp nc_wait
	
	
	
;сохранить файл
edit_file_save
	ld hl,file_name_cur		;строка с именем
	OS_FILE_OPEN ;HL - File name (out: A - id file, de hl - size, IX - fcb)
	jp c,load_file_error	

	ld hl,buffer_cat
	ld de,(edit_file_size)
	;ld a,(file_id_cur_r)
	OS_FILE_WRITE
	jp c,load_file_error
	jr edit_file_wait_ex1
	





;удалить символ слева
edit_file_backspace
	;проверить на начало
	ld hl,(edit_file_pos_cur)
	ld bc,buffer_cat
	and a
	sbc hl,bc
	jr z,edit_file_backspace_err
	;сдвинуть текст
	ld hl,(view_file_end)
	ld bc,(edit_file_pos_cur) ;позиция курсора
	and a
	sbc hl,bc
	jr z,edit_file_backspace_err
	ld bc,hl ;сколько сдвигать
	ld hl,(edit_file_pos_cur) ;позиция курсора
	ld de,hl
	dec de
	ldir
	xor a
	;dec de
	ld (de),a ;в конце 0



	;уменьшить размер и изменить окончание
	ld hl,(edit_file_size)
	dec hl
	ld (edit_file_size),hl
	
	ld hl,(view_file_end)
	dec hl
	ld (view_file_end),hl ;
	
	;флаг что изменён
	ld a,1
	ld (edit_file_save_flag),a ;флаг для сохранения
	
	call edit_move_left_cursor ;курсор влево
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl	
	
	call print_file_text ;напечатать всё
	call print_file_cursor ;курсор

	jp edit_file_wait


edit_file_backspace_err

	jp edit_file_wait












;вставка символа
edit_file_insert_sym
	;проверить есть ли место
	ld hl,(view_file_end)
	inc hl ;ffff?
	ld a,h
	or l
	jr z,edit_file_insert_sym_err
	inc hl ;fffe?
	ld a,h
	or l
	jr z,edit_file_insert_sym_err
	;сдвинуть текст
	dec hl
	dec hl
	ld bc,(edit_file_pos_cur) ;позиция курсора
	and a
	sbc hl,bc
	jr z,edit_file_insert_sym_err
	ld bc,hl ;сколько сдвигать
	ld de,(view_file_end) ;позиция курсора
	ld hl,de
	dec hl
	lddr
	
	;увеличить размер и изменить окончание
	ld hl,(edit_file_size)
	inc hl
	ld (edit_file_size),hl
	
	ld hl,(view_file_end)
	inc hl
	ld (view_file_end),hl ;увеличить
	
	;флаг что изменён
	ld a,1
	ld (edit_file_save_flag),a ;флаг для сохранения
	
	ld hl,(edit_file_pos_cur) ;позиция курсора	
	ld a,(key_pressed)
	ld (hl),a
	
	call edit_move_right_cursor ;курсор вправо
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl	
	
	call print_file_text ;напечатать всё
	call print_file_cursor ;курсор
	
	;
	ret

edit_file_insert_sym_err
	ld de,0
	OS_SET_XY

	ld a,color_error ;цвет ошибки
	ld b,#c
	OS_SET_COLOR

	ld hl,msg_mem_err ;нет памяти
	OS_PRINTZ ;печать
	
	ld a,color_backgr ;цвет основной
	ld b,#c
	OS_SET_COLOR
	scf
	ret










edit_file_down ;вниз на строчку	
	call next_line_cursor ;курсор вниз
	jp c,edit_file_down1
	
	ld a,(edit_file_pos_cur_xy+1) ;y
	inc a
	cp view_text_bot
	jr c,edit_file_down1

	;сдвинуть фокус
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	call next_line ;вперёд на строку
	jp c,edit_file_down1 ;если не удачно
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	call print_file_text ;напечатать всю страницу	
	
edit_file_down1
	call print_file_cursor ;напечатать курсор	
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl

	jp edit_file_wait






	
edit_file_up ;вверх на строчку
	call prev_line_cursor ;
	jr z,edit_file_up2
	jp c,edit_file_up1 ;если не удачно
edit_file_up2
	ld a,(edit_file_pos_cur_xy+1) ;y
	cp view_text_top
	jr nz,edit_file_up1

	;сдвинуть фокус
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	call prev_line ;
	jp c,edit_file_up1

	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	call print_file_text ;напечатать всю страницу

edit_file_up1
	call print_file_cursor ;напечатать курсор
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl
	jp edit_file_wait





edit_right ;вправо	
	call edit_move_right_cursor
	jr c,edit_right_ex
	;jr z,edit_right_ex
	ld a,(edit_file_pos_cur_xy) ;x
	inc a
	cp 80 ;ограничение справа
	jr c,edit_right1
	;тут надо промотать вправо весь текст
		
	ld hl,(view_move_right_val)
	inc hl
	ld a,h ;сдвиг вправо не больше 65535
	or l
	jp z,edit_right2
	ld (view_move_right_val),hl
	call print_file_text ;напечатать всю страницу
edit_right2
	;ld a,80-1 ;курсор остаётся на краю
edit_right1
	;ld (edit_file_pos_cur_xy),a ;x

edit_right_ex
	call print_file_cursor ;напечатать курсор	
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl
	jp edit_file_wait






	
edit_left ;влево
	call edit_move_left_cursor
	jr c,edit_left_ex
	;jr z,edit_left_ex
	ld a,(edit_file_pos_cur_xy) ;x
	or a ;ограничение слева
	jr z,edit_left1
	;тут надо промотать влево весь текст
	ld hl,(view_move_right_val)
	ld a,h
	or l
	jp z,edit_left2
	dec hl
	ld (view_move_right_val),hl
	call print_file_text ;напечатать всю страницу
edit_left2
	ld a,1 ;курсор остаётся на краю
edit_left1
	;dec a
	;ld (edit_file_pos_cur_xy),a ;x

edit_left_ex
	call print_file_cursor ;напечатать курсор	
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl
	jp edit_file_wait
	





	
	
edit_page_up ;на страницу назад
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	ld b,view_text_bot-2
edit_page_up_cl
	call prev_line ;
	;call prev_line_cursor ;
	jr c,edit_page_up_ex ;если не удачно
	jr z,edit_page_up_ex
	djnz edit_page_up_cl
edit_page_up_ex
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	ld (edit_file_pos_cur),hl ;курсор будет там же где фокус
	;ld (edit_file_pos_old),hl
	call edit_move_right_cursor ;ещё на символ
	
	call print_file_text ;напечатать всю страницу

	call print_file_cursor ;напечатать курсор
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl	
	jp edit_file_wait


	
edit_page_down ;на страницу вперёд
	ld hl,(view_file_pos_cur_focus) ;фокус
	ld (view_file_pos_cur),hl
	ld b,view_text_bot-2
edit_page_down_cl
	call next_line ;
	;call next_line_cursor ;
	jr c,edit_page_down_ex ;если не удачно
	jr z,edit_page_down_ex
	djnz edit_page_down_cl
edit_page_down_ex
	ld hl,(view_file_pos_cur) ;запомнить фокус
	ld (view_file_pos_cur_focus),hl
	ld (edit_file_pos_cur),hl ;курсор будет там же где фокус
	;ld (edit_file_pos_old),hl
	
	call edit_move_right_cursor ;ещё на символ
	
	call print_file_text ;напечатать всю страницу
	call print_file_cursor ;напечатать курсор
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_old),hl		
	jp edit_file_wait


	
print_menu_edit ;печать меню редактора
	ld a,#18
	ld b,color_backgr_hi ;цвет
	OS_PAINT_LINE ;линия внизу
	ld a,color_backgr_hi ;цвет
	ld b,#c
	OS_SET_COLOR
	ld de,#1800+0*8
	OS_SET_XY
	ld hl,msg_menu_edit
	OS_PRINTZ
	ret
	
; print_menu_edit_top ;печать меню просмотрщика верхнее
	; xor a
	; ld b,color_backgr_hi ;цвет
	; OS_PAINT_LINE ;линия вверху
	; ld a,color_backgr_hi ;цвет
	; ld b,#c
	; OS_SET_COLOR
	; ld de,#0024
	; OS_SET_XY
	; ld hl,file_name_cur
	; OS_PRINTZ
	; ret	
	
	
	
print_file_cursor	;печать только курсора, в основном пустой цикл по тексту
	xor a ;флаг выхода из цикла
	ld (print_line_cursor_flag),a
	ld a,color_edit_text ;цвет обычный
	ld b,#c	
	OS_SET_COLOR
	ld hl,(edit_file_pos_old)
	ld (edit_file_pos_tmp),hl
	call print_file_cursor_one ;"стереть" старый курсор

	xor a ;флаг выхода из цикла
	ld (print_line_cursor_flag),a	
	ld a,color_edit_cursor ;цвет курсор
	ld b,#c	
	OS_SET_COLOR
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_tmp),hl
	call print_file_cursor_one ;напечатать новый
	ret
	
print_file_cursor_one

	ld a,view_text_top ;первая строка
	ld (view_file_y_cur),a
	ld hl,(view_file_pos_cur_focus) ;печать видимой части
	ld (view_file_pos_cur),hl	
print_file_cursor_cl
	ld hl,(view_file_pos_cur)
	call print_line_cursor
	jr c,print_file_cursor_ex
	;если уже напечатали курсор
	ld a,(print_line_cursor_flag)
	or a
	ret nz
	; call next_line ;найти следующую строку
	; ret c
	
	ld a,(view_file_y_cur)
	inc a
	ld (view_file_y_cur),a
	cp view_text_bot
	jr c,print_file_cursor_cl
	ret
	
print_file_cursor_ex
	;тут очистить остальные строки
	; ld a,(view_file_y_cur)
	; inc a
	; cp edit_text_bot
	; jr nc,print_file_cursor_ex2
	; ld h,a
	; ld (view_file_y_cur),a
	; ld a," "
	; OS_FILL_LINE ;очистить строку
	; jr print_file_cursor_ex
; print_file_cursor_ex2
	scf
	ret



print_line_cursor ;печать только курсора в цикле одной строки до кода 13, или до правого края экрана, или до конца файла
;вх: hl - адрес строки
	call view_move_right ;промотать направо. если надо
	;установить позицию
	; ld a,(view_file_y_cur)
	; ld d,a
	xor a
	ld (view_file_x_cur),a
	; ld e,a
	; OS_SET_XY 	;yx
print_line_cursor_cl ;цикл
	ld a,(hl)
	cp 10 ;этот код не печатаем
	jr z,print_line_cursor_skip
	cp #ff ;этот код не печатаем
	jr z,print_line_cursor_skip
	cp 13
	jr z,print_line_cursor_ex_ok
	
	;push hl
	ld bc,(edit_file_pos_tmp)
	and a
	sbc hl,bc
	;pop hl
	jr nz,print_line_cursor_skip1
	;запомнить координаты
	push af
	ld a,(view_file_y_cur) 
	ld (edit_file_pos_cur_xy+1),a
	ld d,a	
	ld a,(view_file_x_cur)
	ld (edit_file_pos_cur_xy),a
	ld e,a	
	OS_SET_XY 	;yx
	pop af
	OS_PRINT_CHARF ;печать только курсора
	;флаг на выход цикла
	ld a,1
	ld (print_line_cursor_flag),a
	
print_line_cursor_skip1
	;на следующую позицию
	ld a,(view_file_x_cur)
	inc a
	cp 80 ;правый край экрана
	ld (view_file_x_cur),a
	jr nc,print_line_cursor_right ;дошли до правого края
	
print_line_cursor_skip
	call view_file_next_pos ;следующий
	jr c,print_line_cursor_ex_end ;на следующий символ
	jr print_line_cursor_cl
	
print_line_cursor_ex_ok ;выход норма по коду 13
	;ещё раз проверить курсор, когда он на коде 13
	ld bc,(edit_file_pos_tmp)
	and a
	sbc hl,bc
	;pop hl
	jp nz,view_file_next_pos
	;запомнить координаты
	ld a,(view_file_y_cur) 
	ld (edit_file_pos_cur_xy+1),a
	ld d,a	
	ld a,(view_file_x_cur)
	ld (edit_file_pos_cur_xy),a
	ld e,a	
	OS_SET_XY 	;yx
	ld a," " ;печатать пробел вместо 13
	OS_PRINT_CHARF ;печать только курсора
	;флаг на выход цикла
	ld a,1
	ld (print_line_cursor_flag),a	
	
	;ld a," "
	;OS_PRINT_CHARF ;печать
	;call printe_clear_end ;добить до конца строки
	jp view_file_next_pos ;следующий, чтобы пропустить код 13
	;ret
	
print_line_cursor_ex_end ;выход если кончился файл
	;call printe_clear_end
	scf
	ret	
	
print_line_cursor_right
	call next_line ;позицию  до конца строки
	ret


; printe_clear_end
	; ;добить строку пробелами
	; ld a,(edit_file_x_cur)
	; inc a
	; cp 80 ;правый край экрана
	; ld (edit_file_x_cur),a
	; ret nc
	; ;ld a," "
	; ;OS_PRINT_CHARF ;печать
	; jr printe_clear_end

print_line_cursor_flag db 0;флаг прерывания цикла






edit_move_right_cursor ;перемотка курсор направо
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_tmp),hl ;сохранить позицию
edit_move_right_cursor_cl
	call edit_file_next_pos_cursor
	jr c,edit_move_right_cursor_err
	ld a,(hl)
	cp 10 ;этот код пропускаем
	jr z,edit_move_right_cursor_cl
	cp #ff ;этот код пропускаем
	jr z,edit_move_right_cursor_cl
	; cp 13 ;
	; jr z,edit_move_right_cursor_cl
edit_move_right_cursor_ok
	xor a ;ok
	ret
edit_move_right_cursor_err
	ld hl,(edit_file_pos_tmp) ;вернуть, если попали на непечатный символ
	ld (edit_file_pos_cur),hl
	scf
	ret

	
;получение следующей позиции для курсора
edit_file_next_pos_cursor 
	; ld a,(edit_file_load_all) ;флаг что файл весь в памяти
	; or a
	; jr z,edit_file_next_pos_cursor_big 
	;если текст не большой
	ld hl,(view_file_end) ;конец текста известен
	ld de,(edit_file_pos_cur)
	inc de ;вперёд
	and a
	sbc hl,de
	jr c,edit_file_next_pos_cursor_end
	ld (edit_file_pos_cur),de
	ex de,hl ;на выходе адрес в HL
	or a
	ret


	
; edit_file_next_pos_cursor_big
	; ;если текст большой	
	; ld hl,(edit_file_pos_cur)	;текущая позиция
	; inc hl ;вперёд
	; ld a,h
	; cp #c0 ;если вышли за пределы окна
	; jr c,edit_file_next_pos_cursor_end
	; ld (edit_file_pos_cur),hl
	; or a
	; ret	
	
edit_file_next_pos_cursor_end
	;не смогли шагнуть вперёд
	; ; ld a,1 ;флаг что внизу
	; ; ld (edit_file_bot_flag),a
	scf ;ошибка
	ret
	






edit_move_left_cursor ;перемотка курсор направо
	; ld bc,(edit_move_left_cursor_val) ;на сколько символов вправо промотать
	; ld a,b
	; or c
	; ret z
	; ld hl,(edit_file_pos_cur)
	; ld (edit_file_pos_tmp),hl
edit_move_left_cursor_cl
	call edit_file_prev_pos_cursor
	jr c,edit_move_left_cursor_err
	;jr z,edit_move_left_cursor_ok ;если пришли в начало
	ld a,(hl)
	cp 10 ;этот код пропускаем
	jr z,edit_move_left_cursor_cl
	cp #ff ;этот код пропускаем
	jr z,edit_move_left_cursor_cl
	; cp 13 ;
	; jr z,edit_move_left_cursor_cl
edit_move_left_cursor_ok
	xor a ;ok
	ret
edit_move_left_cursor_err
	;ld hl,(edit_file_pos_tmp) ;вернуть, если попали на непечатный символ
	ld hl,buffer_cat ;в начало
	ld (edit_file_pos_cur),hl
	scf
	ret
	
	
	
	
	
;получение предыдущей позиции	
edit_file_prev_pos_cursor 
	; ld a,(edit_file_load_all) ;флаг что файл весь в памяти
	; or a
	; jr z,edit_file_prev_pos_cursor_big 
	;если текст не большой
	ld hl,buffer_cat ;тут лежит текст
	ld de,(edit_file_pos_cur) ;текущая позиция
	dec de ;назад
	and a
	sbc hl,de
	;jr z,edit_file_prev_pos_cursor_top ;если пришли в начало
	jr nc,edit_file_prev_pos_cursor_end
	;можно шагнуть назад
	ld (edit_file_pos_cur),de
	ex de,hl ;на выходе адрес в HL
	xor a
	;inc a ;a=1
	ret
; edit_file_prev_pos_cursor_top
	; ;если в начале
	; ld (edit_file_pos_cur),de
	; ex de,hl ;на выходе адрес в HL	
	; xor a ;a=0
	; ret

	
; edit_file_prev_pos_cursor_big
	; ;если текст большой	
	; ld hl,(edit_file_pos_cur)	;текущая позиция
	; dec hl ;назад
	; ld a,h
	; cp #c0 ;если вышли за пределы окна
	; jr c,edit_file_prev_pos_cursor_end
	; ld (edit_file_pos_cur),hl	
	; or a
	; ret	
	
edit_file_prev_pos_cursor_end
	;не смогли шагнуть назад
	;ld hl,buffer_cat ;тут лежит текст
	;ld (edit_file_pos_cur),hl ;текущая позиция в самом начале
	;вернулись в начало
	scf ;
	ret	
	
	
	
	
next_line_cursor ;поиск следующей строки для курсора
	ld hl,(edit_file_pos_cur)
	ld (edit_file_pos_tmp),hl ;сохранить позицию
next_line_cursor_cl	
	call edit_file_next_pos_cursor
	jr c,next_line_cursor_err
	;ret z
	ld a,(hl)
	cp 13
	jr nz,next_line_cursor_cl
	;тут нашли конец строки
next_line_cursor_cl1	
	;ещё пропустить лишнее
	call edit_file_next_pos_cursor
	jr c,next_line_cursor_err	
	ld a,(hl)
	cp 10
	jr z,next_line_cursor_cl1
	cp #ff
	jr z,next_line_cursor_cl1	
next_line_cursor_ok
	xor a
	ret
next_line_cursor_err
	ld hl,(edit_file_pos_tmp)
	ld (edit_file_pos_cur),hl ;восстановить позицию
	scf
	ret






prev_line_cursor ;поиск предыдущей строки для курсора
;если достигнуто начало файла - вернёт адрес начальный 
	;сначала в конец предыдущей
	; ld hl,(edit_file_pos_cur)
	; ld (edit_file_pos_tmp),hl ;сохранить позицию
prev_line_cursor_cl	
	call edit_file_prev_pos_cursor
	;jr z,prev_line_cursor_ok
	jr c,prev_line_cursor_err
	ld a,(hl)
	cp 13
	jr nz,prev_line_cursor_cl
	;теперь в начало предыдущей
prev_line_cursor_cl1
	call edit_file_prev_pos_cursor
	;jr z,prev_line_cursor_ok
	jr c,prev_line_cursor_err
	ld a,(hl)
	cp 13
	jr nz,prev_line_cursor_cl1
prev_line_cursor_cl2	
	call edit_file_next_pos_cursor ;ещё на символ обратно	
	ld a,(hl)
	cp 10
	jr z,prev_line_cursor_cl2
	cp #ff
	jr z,prev_line_cursor_cl2	

prev_line_cursor_ok
	xor a
	ret
prev_line_cursor_err
	; ld hl,(edit_file_pos_tmp)
	ld hl,buffer_cat ;в начало
	ld (edit_file_pos_cur),hl 
	scf
	ret	

; edit_text_bot equ 24 ;последняя строка для печати
; edit_text_top equ 1 ;первая строка
; edit_text_lines equ 25-2 ;видимых строк на экране


msg_menu_edit
	db "Break - Exit",0
	
msg_menu_edit_save
	db "Save file? Y/N",0

edit_file_size dw 0 ;размер текстак
edit_file_save_flag db 0 ;флаг что файл изменён	
edit_file_pos_cur dw 0 ;текущая позиция в файле
edit_file_pos_old dw 0 ;текущая позиция в файле
edit_file_pos_tmp dw 0 ;временно
edit_file_pos_cur_xy dw 0 ;текущая позиция координаты на экране
; ;edit_file_bot_flag db 0 ;флаг что домотали вниз до конца
; edit_move_right_val dw 0 ;сдвиг вправо
;edit_file_pos_cur dw 0;текущая позиция
;edit_file_pos_cur_focus dw 0 ;позиция фокуса
;edit_file_y_cur db 0;текущая строка
;edit_file_x_cur db 0;текущий столбец
; ;edit_file_load_all db 0 ;флаг что файл весь загружен
; edit_file_end dw 0 ;конец файлв, или текущего куска
 
	