;Tetris - приложение для OS GMX
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org PROGSTART	
	
start_tetris
	; ld a,13 ;новая строка
	; OS_PRINT_CHARF	
	ld hl,msg_title_tetris ;имя приложения
	OS_PRINTZ ;печать

start_tetris_wait
	ld a,page_pix ;основной экран
	OS_SET_SCREEN ;включит граф режим
	jr nc,start_tetris_warm
	OS_WAIT
	jr start_tetris_wait ;ждать когда дадут граф экран
	
start_tetris_warm
	ld a,page_pix ;страница пикселей
	OS_SET_PAGE_SLOT3
	
	ld hl,#c000
	ld de,#c001
	ld bc,16000-1
	ld (hl),0
	ldir
	
	
	ld a,page_attr ;страница атрибутов
	OS_SET_PAGE_SLOT3
	
	ld hl,#c000
	ld de,#c001
	ld bc,16000-1
	ld (hl),0 ;пока чорный
	ldir


	
	xor a
	ld (figure_fell_flag),a ;флаг 
	ld (figure_fall_count),a
	ld (speed_count),a
	
	;почистить базу
	ld hl,base_orig
	ld de,base
	ld bc,base_orig_end-base_orig
	ldir
	
	ld hl,0 ;очки
	ld (score_x1),hl
	ld (score_x2),hl
	ld (score_x3),hl
	ld (score_x4),hl
	ld (score_total),hl
	
	ld a,figure_fall_count_target_start ;скорость
	ld (figure_fall_count_target),a
	

	ld a,1
	ld (print_square_pix_flag+1),a ;включить пиксели
	call print_cupe ;печатать весь стакан с пикселями
	xor a
	ld (print_square_pix_flag+1),a ;выключить пиксели


	call get_next_figure ;узнать текущую фигуру и сразу следующую
	
	call get_next_figure
	
	ld 	hl,figure_pos_start ;стартовая позиция
	ld (figure_pos_cur),hl

	ld de,msg_help_pos ;надпись
	OS_SET_XY
	ld hl,msg_help
	OS_PRINTZ
	
	ld de,msg_next_pos ;надпись
	OS_SET_XY
	ld hl,msg_next
	OS_PRINTZ

	ld bc,figure_pos_next ;напечатать следующую
	ld hl,(figure_next) ;фигура
	ld a,1
	ld (print_square_pix_flag+1),a ;включить пиксели
	call print_figure
	xor a
	ld (print_square_pix_flag+1),a ;выключить пиксели
	
	call print_score
	
	; ld a,(figure_color_cur) ;текущий цвет
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция
	call print_figure
	
tetris_loop ;основной цикл игры
	OS_WAIT
	; ld a,4
	; out (254),a
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция		
	call clear_figure	;стереть
	;ld a,0
	;out (254),a
	
	call figure_fall ;падение
	jr z,tetris_loop_next2 ;можно продолжить, ещё нет столкновения
	
	;тут обработка после падения
	ld a,1
	ld (figure_fell_flag),a ;флаг что уже упала
	
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция	
	call print_figure	;напечатать	опять	

	call speed ;проверить скорость игры
	
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция		
	call figure_join ;поместить в базу
	
	call line_check ;проверить линию и убрать, если надо
	jr z,tetris_loop_next3
	call score_add ;добавить очки
	call print_score ;напечатать очки
	
tetris_loop_next3
	ld a,(figure_fell_flag)
	or a
	jp nz,figure_get_next ;пора показать следующую или закончить игру	
	
	
tetris_loop_next2

	;проверка управления
	OS_GET_CHAR
	cp 9
	jp z,right ;вправо
	cp 8
	jp z,left ;влево
	cp 11
	jp z,rotation ;вверх
	cp 10
	jp z,down ;вниз
	cp " "
	jp z,rotation ;вниз
	cp "h"
	jp z,pause ;пауза
	cp 24 ;break
	jp z,tetris_exit
	
tetris_loop_next 
	;показать на новых координатах
	; ld a,4
	; out (254),a
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция	
	call print_figure	;напечатать	
	; ld a,0
	; out (254),a	
	jp tetris_loop



;увеличение скорости игры
speed
	ld a,(speed_count)
	inc a
	cp speed_target ;конечная скорость
	jr c,tetris_loop_speed_count
	;здесь надо увеличить скорость
	ld a,(figure_fall_count_target)
	dec a
	jr nz,tetris_loop_speed_count1
	inc a ;не меньше 1
tetris_loop_speed_count1	
	ld (figure_fall_count_target),a
	xor a
tetris_loop_speed_count	
	ld (speed_count),a
	ret


;проверка и удаление линии
line_check
	ld iyl,0 ;счётчик
line_check_warm
	ld ix,base+4 ;база верхняя строка
	ld iyh,0 ;верхняя строка
	;цикл  20 строк
	ld b,20 ;цикл по строкам
line_check_cl_line
	push ix
	pop hl ;начало строки

line_check_cl_row ;цикл по столбцам
	ld a,(hl) ;цвет фигуры
	or a
	jr z,line_check_skip
	;проверка остальной строки
	ld c,10-1
line_check_cl_row2
	inc hl ;дальше по базе
	ld a,(hl)
	or a
	jr z,line_check_skip
	dec c
	jr nz,line_check_cl_row2
	;тут узнали что строка заполнена
	inc iyl
	call line_remove
	jr line_check_warm ;снова проверяем таблицу
	
line_check_skip
	inc iyh ;строка ++
	push bc
	ld bc,base_x_size
	add ix,bc ;след строка
	pop bc
	djnz line_check_cl_line
	

	ld a,iyl ;сколько наши
	or a
	ret





;убрать строку
line_remove
	push ix
	pop hl ;начало строки
	ld (hl),2+64 ;заполнить ярко красным
	ld d,h
	ld e,l
	inc de
	ld bc,10-1
	ldir
	
	push iy
	push ix
	call print_cupe ;напечатать весь стакан
	pop ix
	pop iy
	OS_WAIT ;пауза
	;OS_WAIT
	
	;теперь сдвинуть базу вниз
	ld a,iyh ; строка
	or a
	jr z,line_remove_ex ;если верхняя строка, то на выход
	
	push ix
	pop hl
line_remove1
	ld bc,18
	ld d,h
	ld e,l ;куда
	and a
	sbc hl,bc ;на строку вверх

	ld bc,10
	ldir ;перенести
	
	dec iyh
	ld a,iyh
	or a
	jr z,line_remove_ex
	
	ld bc,10 ;ещё назад
	and a
	sbc hl,bc
	
	jr line_remove1
	
	
	
	
line_remove_ex
	;почистить верхнюю строку
	ld hl,base+4
	ld de,base+4+1
	ld (hl),0
	ld bc,10-1
	ldir
	
	push iy
	push ix
	call print_cupe ;напечатать весь стакан
	pop ix
	pop iy	
	ret


;добавить очки
;вх: A - количество линий
score_add 
	or a
	ret z
	cp 5
	ret nc ;защита
	cp 1
	jr nz,score_add_skip_1
	ld hl,(score_x1)
	inc hl
	ld (score_x1),hl
	jr score_add_ex
score_add_skip_1	

	cp 2
	jr nz,score_add_skip_2
	ld hl,(score_x2)
	inc hl
	ld (score_x2),hl
	jr score_add_ex
score_add_skip_2

	cp 3
	jr nz,score_add_skip_3
	ld hl,(score_x3)
	inc hl
	ld (score_x3),hl
	jr score_add_ex
score_add_skip_3

	cp 4
	jr nz,score_add_skip_4
	ld hl,(score_x4)
	inc hl
	ld (score_x4),hl
	jr score_add_ex
score_add_skip_4


score_add_ex
	ld hl,(score_total)
	ld c,a
	ld b,0
	add hl,bc
	ld (score_total),hl
	ret

;пауза
pause
	call release_key
pause1	
	OS_WAIT
	OS_GET_CHAR
	cp 255 ;ждём любой клавиши
	jr z,pause1	
	jp tetris_loop



;печать очков
print_score 
	ld de,msg_score_pos
	OS_SET_XY
	ld hl,msg_score
	OS_PRINTZ

	ld a,(figure_fall_count_target)
	ld l,a
	ld h,0
	call toDecimal
	ld de,msg_speed_pos
	OS_SET_XY
	ld hl,decimalS+2
	OS_PRINTZ

	ld hl,(score_x1)
	call toDecimal
	ld de,msg_score_pos_x1
	OS_SET_XY
	ld hl,decimalS
	OS_PRINTZ
	
	ld hl,(score_x2)
	call toDecimal
	ld de,msg_score_pos_x2
	OS_SET_XY
	ld hl,decimalS
	OS_PRINTZ
	
	ld hl,(score_x3)
	call toDecimal
	ld de,msg_score_pos_x3
	OS_SET_XY
	ld hl,decimalS
	OS_PRINTZ
	
	ld hl,(score_x4)
	call toDecimal
	ld de,msg_score_pos_x4
	OS_SET_XY
	ld hl,decimalS
	OS_PRINTZ
	
	ld hl,(score_total)
	call toDecimal
	ld de,msg_score_pos_total
	OS_SET_XY
	ld hl,decimalS
	OS_PRINTZ
	ret
	

figure_get_next ;начало следующей
	ld bc,figure_pos_next ;стереть следующую
	ld hl,(figure_next) ;фигура
	call clear_figure


	call get_next_figure
	
	ld 	bc,figure_pos_start ;стартовая позиция
	ld (figure_pos_cur),bc


	ld bc,figure_pos_next ;напечатать следующую
	ld hl,(figure_next) ;фигура
	ld a,1
	ld (print_square_pix_flag+1),a ;включить пиксели
	call print_figure
	xor a
	ld (print_square_pix_flag+1),a ;выключить пиксели
	

	xor a
	ld (figure_fell_flag),a ;флаг 

	;проверить влезает ли
	ld bc,(figure_pos_cur) 
	ld hl,(figure_cur) ;фигура
	call figure_check_pos
	jp z,figure_get_next_ok	;
	
	;иначе конец игры
	ld de,msg_game_over_pos
	OS_SET_XY
	ld hl,msg_game_over
	OS_PRINTZ
	call release_key
figure_get_wait
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr z,figure_get_wait
	
	jp start_tetris_warm ;сначала

figure_get_next_ok	

	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция	
	call print_figure	;напечатать	
	
	jp tetris_loop


;ждать отпускания клавиши
release_key 
	OS_WAIT
	OS_GET_CHAR
	cp 255
	jr nz,release_key
	ret


right
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция	
	inc c ;вправо
	inc c
	call figure_check_pos ;
	jp nz,tetris_loop_next	;не вмещается
	ld bc,(figure_pos_cur) ;позиция		
	inc c ;вправо
	inc c	
	ld (figure_pos_cur),bc
	jp tetris_loop_next
	
left
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция	
	dec c ;влево
	dec c
	call figure_check_pos ;
	jp nz,tetris_loop_next	;не вмещается
	ld bc,(figure_pos_cur) ;позиция		
	dec c ;влево
	dec c	
	ld (figure_pos_cur),bc
	jp tetris_loop_next
	
	
	
; up
	; jp tetris_loop_next
	
	
down ;ускоренное падение
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция	
	inc b ;вниз
	call figure_check_pos ;
	jp nz,tetris_loop_next	;не вмещается
	
	OS_WAIT
	
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция		
	call clear_figure	;стереть	
	
	ld bc,(figure_pos_cur) ;позиция		
	inc b ;y++
	ld (figure_pos_cur),bc
	
	ld hl,(figure_cur) ;фигура
	ld bc,(figure_pos_cur) ;позиция		
	call print_figure	;печатать	
	jr down ;снова
	
	
	
rotation
	ld a,(figure_fase_cur)
	inc a
	cp 4 ;максимум 3 фазы
	jp c,rotation1
	xor a
rotation1
	call figure_calc_fase

	ld bc,(figure_pos_cur) ;позиция	
	call figure_check_pos ;
	jp nz,tetris_loop_next	;не вмещается
	ld a,(figure_fase_cur)
	inc a
	cp 4 ;максимум 3 фазы
	jp c,rotation2
	xor a
rotation2
	ld (figure_fase_cur),a
	call figure_calc_fase
	ld (figure_cur),hl ;новая фаза

	jp tetris_loop_next



figure_calc_fase ;определить адрес аписания фазы
	rlca ;*2
	rlca ;*4
	ld c,a
	ld b,0
	ld hl,(figure_cur_first_fase)
	add hl,bc ;узнали адрес фазы
	ret

;падение
figure_fall
	ld a,(figure_fall_count)
	inc a
	ld (figure_fall_count),a
	ld hl,figure_fall_count_target
	cp (hl)
	jr c,figure_fall_ex
	xor a
	ld (figure_fall_count),a

	ld bc,(figure_pos_cur) ;позиция	
	inc b
	ld hl,(figure_cur)
	call figure_check_pos ;проверить можно ли
	ret nz ;нет
	ld bc,(figure_pos_cur) ;позиция	
	inc b ;вниз
	ld (figure_pos_cur),bc
figure_fall_ex
	xor a ;нормально
	ret
	



;слияние фигуры с базой
;HL - описание фигуры
;BC- позиция (b>=1)
figure_join	
	ld a,c
	sub cup_pos_x ;
	rrca ;/2 узнать позицию x по базе
	push hl
	ld hl,base ;база
	dec b ;коррекция
	jr z,figure_join_pos_cl2_skip
	ld e,base_x_size
	ld d,0
figure_join_pos_cl2
	add hl,de
	djnz figure_join_pos_cl2
figure_join_pos_cl2_skip
	ld b,0
	ld c,a
	add hl,bc ;брибавить x
	ex de,hl ;de - адрес в базе
	pop hl
	;цикл построения 4*4
	ld bc,#0404 ;xy
figure_join_pos_cl1
	push bc
	ld a,(hl) ;цвет фигуры
	or a
	jr z,figure_join_pos_skip
	ld (de),a ;элемент базы
figure_join_pos_skip
	inc hl ;вперёд по описателю фигуры
	inc de ;дальше по базе
	pop bc
	djnz figure_join_pos_cl1
	push de
	ld de,16-4 ;на след строку описания фигуры
	add hl,de
	pop de
	
	push hl
	ex de,hl
	ld de,base_x_size-4 ;на след строку базы
	add hl,de
	ex de,hl
	pop hl
		
	ld b,#04 ;новый цикл строки
	dec c
	jr nz,figure_join_pos_cl1
	ret ;нормально

	
	
;проверка помещается ли фигура
;HL - описание фигуры
;BC- позиция (b>=1)
figure_check_pos
	ld a,c
	sub cup_pos_x ;
	rrca ;/2 узнать позицию x по базе
	push hl
	ld hl,base ;база
	dec b ;коррекция
	jr z,figure_check_pos_cl2_skip
	ld e,base_x_size
	ld d,0
figure_check_pos_cl2
	add hl,de
	djnz figure_check_pos_cl2
figure_check_pos_cl2_skip
	ld b,0
	ld c,a
	add hl,bc ;брибавить x
	ex de,hl ;de - адрес в базе
	pop hl
	;цикл построения 4*4
	ld bc,#0404 ;xy
figure_check_pos_cl1
	push bc
	ld a,(hl) ;цвет фигуры
	or a
	jr z,figure_check_pos_skip
	ld a,(de) ;элемент базы
	or a
	jr nz,figure_check_pos_ex ;вернуться если столкновение
figure_check_pos_skip
	inc hl ;вперёд по описателю фигуры
	inc de ;дальше по базе
	pop bc
	djnz figure_check_pos_cl1
	push de
	ld de,16-4 ;на след строку описания фигуры
	add hl,de
	pop de
	
	push hl
	ex de,hl
	ld de,base_x_size-4 ;на след строку базы
	add hl,de
	ex de,hl
	pop hl
	
	ld b,#04 ;новый цикл строки
	dec c
	jr nz,figure_check_pos_cl1
	xor a
	ret ;нормально
figure_check_pos_ex
	;стокновение
	pop bc
	ret


;нарисовать один квадрат
;вх: BC - адрес на экране (xy)
;вх: A - цвет
print_square 
	ld (square_color_cur),a ;запомнить цвет
	call calc_addr_scr
	ld d,h ;координаты экрана в DE
	ld e,l
	push de ;сохранить адрес символа на экране
	
print_square_pix_flag		
	ld a,0 ;флаг печатать пиксели
	or a
	jr z,print_square_pix_skip
		
	ld a,page_pix ;страница пиксели
	push de
	OS_SET_PAGE_SLOT3      
	pop de

	ld hl,square_one ;рисунок квадрата
    ld  bc,#08ff
print80_1   
	ldi ;один байт
	ldi ;второй
	
	push hl ;на строку пикселей вниз
	ld hl,80-2
	add hl,de
	ex de,hl
	pop hl

	djnz    print80_1


print_square_pix_skip
	;атрибуты
	ld a,page_attr ;страница атрибуты
	OS_SET_PAGE_SLOT3 

	pop hl ;адрес символа на экране

    ld   b,8
	ld a,(square_color_cur)
	ld de,80-1	
print80_1_attr ;теперь так же атрибуты  
		
	ld (hl),a
	inc hl
	ld (hl),a
	add hl,de
	
	djnz    print80_1_attr
	
	ret



calc_addr_scr	;определение адреса экрана по координатам символа
	;ld	bc,(col_screen)
bc_to_attr:
	ld h,0
	ld l,b ;строка (y)
	add hl,hl ;*2
	ld de,table_addr_scr
	add hl,de 
	ld e,(hl)
	inc hl
	ld d,(hl) ;узнали координаты строки
	ld h,0
	ld l,c ;колонка
	add hl,de ;узнали адрес символа
	
	; ld de,(curscrl) ;добавить аппаратный скрол
	; add hl,de
	; ld de,scrsize
	; and a		;check over
	; sbc hl,de
	; jr nc,calc02
	; add hl,de
; calc02:
	ld de,scraddr  ;screen
	add hl,de
	ret
	



;получить следующую фигуру
;вых: HL - адрес фигуры
get_next_figure
	;сначала перенести переменные от следующего в текущий
	ld hl,(figure_next)
	ld (figure_cur),hl
	ld hl,(figure_next_first_fase)
	ld (figure_cur_first_fase),hl
	ld a,(figure_fase_next)
	ld (figure_fase_cur),a
	;теперь найти следующую
	ld a,r ;случайное
	and 7
	cp 7 ;не больше 7 вариантов
	jr nc,get_next_figure
	ld l,a
	;ld e,a ;запомнить
	ld h,0
	add hl,hl ;*2
	add hl,hl ;*4
	add hl,hl ;*8
	add hl,hl ;*16
	add hl,hl ;*32
	add hl,hl ;*64
	ld bc,tetrominos
	add hl,bc ;определили фигуру
	ld (figure_next_first_fase),hl ;запомнить первую фазу
	;ld a,(figure_fase_cur)
	ld a,r
	and 3 ;не больше 4 вариантов
	ld (figure_fase_next),a ;фаза
	rlca ;*2
	rlca ;*4
	; rlca ;*8
	; rlca ;*16
	ld c,a
	ld b,0
	add hl,bc
	ld (figure_next),hl
	;определить цвет
	; ld d,0
	; ex de,hl
	; ld bc,figure_color
	; add hl,bc
	; ld a,(hl) ;цвет
	; ex de,hl
	ret
	


;печать фигурки
;вх: HL - адрес описания фигуры
;вх: BC - координаты yx
print_figure
	ld (print_figure_pos_cur),bc
	ld a,c
	ld (print_figure_pos_cur_x),a
	;цикл построения 4*4
	ld bc,#0404 ;xy
print_figure_cl1
	push bc
	ld a,(hl) ;цвет
	or a
	jr z,print_figure_skip
	ld bc,(print_figure_pos_cur) ;текущая позиция
	push hl
	call print_square ;печать элемента
	pop hl
print_figure_skip
	ld bc,(print_figure_pos_cur) ;увеличить позицию
	inc c ;один квадрат из двух знакомест
	inc c
	ld (print_figure_pos_cur),bc
	inc hl ;вперёд по описанию фигуры
	pop bc
	djnz print_figure_cl1
	ld de,16-4 ;на след строку описания фигуры
	add hl,de
	ld a,(print_figure_pos_cur+1)
	inc a ;y++
	ld (print_figure_pos_cur+1),a
	ld a,(print_figure_pos_cur_x) ;вернуть позицию x
	ld (print_figure_pos_cur),a		
	ld b,#04 ;новый цикл строки
	dec c
	jr nz,print_figure_cl1
	ret

;стирание фигурки
;вх: HL - адрес описания фигуры
;вх: BC - координаты yx
clear_figure
	ld (print_figure_pos_cur),bc
	ld a,c
	ld (print_figure_pos_cur_x),a
	;цикл построения 4*4
	ld bc,#0404 ;xy
clear_figure_cl1
	push bc
	ld a,(hl) ;цвет
	or a
	jr z,clear_figure_skip
	xor a ;закрасить чорным
	ld bc,(print_figure_pos_cur) ;текущая позиция
	push hl
	call print_square ;печать элемента
	pop hl
clear_figure_skip
	ld bc,(print_figure_pos_cur) ;увеличить позицию
	inc c
	inc c
	ld (print_figure_pos_cur),bc
	inc hl
	pop bc
	djnz clear_figure_cl1
	ld de,16-4 ;на след строку
	add hl,de
	ld a,(print_figure_pos_cur+1)
	inc a ;y++
	ld (print_figure_pos_cur+1),a
	ld a,(print_figure_pos_cur_x) ;вернуть позицию x
	ld (print_figure_pos_cur),a	
	ld b,#04 ;новый цикл строки
	dec c
	jr nz,clear_figure_cl1
	ret


;печать всего стакана
print_cupe 
	ld bc,cup_pos
	ld (print_figure_pos_cur),bc
	;цикл построения
	ld bc,#1218 ;24*18 xy
	ld hl,base ;база
print_cube_cl1
	push bc
	ld a,(hl) ;цвет
	;or a
	;jr z,print_cube_skip
	ld bc,(print_figure_pos_cur) ;текущая позиция
	push hl
	call print_square ;печать элемента
	pop hl
print_cube_skip
	ld bc,(print_figure_pos_cur) ;увеличить позицию
	inc c ;x++
	inc c
	ld (print_figure_pos_cur),bc
	inc hl
	pop bc
	djnz print_cube_cl1
	ld a,(print_figure_pos_cur+1)
	inc a ;y++
	ld (print_figure_pos_cur+1),a
	ld a,cup_pos_x
	ld (print_figure_pos_cur),a	
	ld b,#12 ;новый цикл строки *20
	dec c
	jr nz,print_cube_cl1
	ret



tetris_exit ;выход в DOS
	xor a
	OS_PROC_CLOSE
	
toDecimal		;конвертирует 2 байта в 5 десятичных цифр
				;на входе в HL число
			ld de,10000 ;десятки тысяч
			ld a,255
toDecimal10k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal10k
			add hl,de
			add a,48
			ld (decimalS),a
			ld de,1000 ;тысячи
			ld a,255
toDecimal1k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal1k
			add hl,de
			add a,48
			ld (decimalS+1),a
			ld de,100 ;сотни
			ld a,255
toDecimal01k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal01k
			add hl,de
			add a,48
			ld (decimalS+2),a
			ld de,10 ;десятки
			ld a,255
toDecimal001k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal001k
			add hl,de
			add a,48
			ld (decimalS+3),a
			ld de,1 ;единицы
			ld a,255
toDecimal0001k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal0001k
			add hl,de
			add a,48
			ld (decimalS+4),a		
			
			ret	
decimalS ds 6 ;здесь будет цифра	
	
;


scraddr equ #c000 ;адрес экрана
page_pix equ #39 ;страница пикселей
page_attr equ #79 ;страница атрибутов
cup_pos equ #0116 ;позиция стакана yx
cup_pos_x equ #16 ;позиция стакана x
figure_pos_start equ #0124 ;позиция фигуры начальная
figure_pos_next equ #0a44 ;позиция фигуры слудующая
base_x_size equ 10+4+4 ;ширина базы
base_y_size equ 20+4 ;высота базы
msg_next_pos equ #0844 ;позиция надписи
msg_score_pos equ #0000 ;позиция надписи
msg_score_pos_x1 equ #0104 ;позиция надписи
msg_score_pos_x2 equ #0204 ;позиция надписи
msg_score_pos_x3 equ #0304 ;позиция надписи
msg_score_pos_x4 equ #0404 ;позиция надписи
msg_score_pos_total equ #0607 ;позиция надписи
msg_help_pos equ #0800 ;позиция подскази
msg_speed_pos equ #0807 ;позиция скорости
msg_game_over_pos equ #0c23 ;позиция
figure_fall_count_target_start equ 20 ;скорость падения начальная
speed_target equ 20 ;через столько фигурок увеличить скорость


speed_count db 0 ;счётчик скорости 
figure_fall_count_target db 0 ;скорость падения
figure_fall_count db 0 ;счётчик падения
figure_fell_flag db 0 ;флаг что что-то упало совсем
print_figure_pos_cur dw 0;временно координаты
print_figure_pos_cur_x dw 0;временно координаты x
figure_fase_cur db 0 ;фаза фигурки
figure_fase_next db 0 ;фаза фигурки для следующей
figure_cur_first_fase dw 0 ;фаза фигурки первая
figure_next_first_fase dw 0 ;фаза фигурки первая для следующей
figure_cur dw 0 ;адрес текущей фигуры
figure_next dw 0 ;следующая фигура
figure_color_cur db 0 ;текущий цвет
figure_pos_cur dw 0 ;текущая позиция
score_x1 dw 0 ;очки
score_x2 dw 0
score_x3 dw 0
score_x4 dw 0
score_total dw 0


msg_game_over db " Game over ",0

msg_help db "Speed:",13,13
	db "Cursor -",13
	db "left, right, down",13
	db "Sp, up - rotate",13
	db "h - pause",13
	db "Break - exit",0
	

msg_next db "Next:",0
msg_score db "Score:",13
	db "x1:",13
	db "x2:",13
	db "x3:",13
	db "x4:",13,13
	db "Total:",0
	

square_color_cur db 0; текущий цвет квадрата
square_one ;один квадрат
	db %11111111, %11111110 
	db %10001111, %11111110
	db %10111111, %11111110
	db %11111111, %11111110
	db %11111111, %11111110
	db %11111111, %11111110
	db %11111111, %11111110
	db %00000000, %00000000
	

;фигурки во всех ракурсах
tetrominos 
;'I': 
    db 0,0,0,0, 0,5,0,0, 0,0,0,0, 0,5,0,0 ;4*4*4=64 на элемент
    db 5,5,5,5, 0,5,0,0, 5,5,5,5, 0,5,0,0
    db 0,0,0,0, 0,5,0,0, 0,0,0,0, 0,5,0,0
    db 0,0,0,0, 0,5,0,0, 0,0,0,0, 0,5,0,0
; 'J': 
    db 6,0,0,0,	0,6,0,0, 6,6,6,0, 6,6,0,0
    db 6,6,6,0,	0,6,0,0, 0,0,6,0, 6,0,0,0
    db 0,0,0,0,	6,6,0,0, 0,0,0,0, 6,0,0,0
	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
; 'L': 
    db 0,0,3,0,	3,3,0,0, 3,3,3,0, 3,0,0,0
    db 3,3,3,0,	0,3,0,0, 3,0,0,0, 3,0,0,0
    db 0,0,0,0,	0,3,0,0, 0,0,0,0, 3,3,0,0
	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0	
; 'O': 
    db 4,4,0,0,	4,4,0,0, 4,4,0,0, 4,4,0,0
    db 4,4,0,0,	4,4,0,0, 4,4,0,0, 4,4,0,0
    db 0,0,0,0,	0,0,0,0, 0,0,0,0, 0,0,0,0
	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
; 'S': 
    db 0,2,2,0,	2,0,0,0, 0,2,2,0, 2,0,0,0
    db 2,2,0,0,	2,2,0,0, 2,2,0,0, 2,2,0,0
    db 0,0,0,0,	0,2,0,0, 0,0,0,0, 0,2,0,0
	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
; 'Z': 
    db 1,1,0,0,	0,1,0,0, 1,1,0,0, 0,1,0,0
    db 0,1,1,0,	1,1,0,0, 0,1,1,0, 1,1,0,0
    db 0,0,0,0,	1,0,0,0, 0,0,0,0, 1,0,0,0
	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0

; 'T': 
    db 0,7,0,0,	0,7,0,0, 7,7,7,0, 7,0,0,0
    db 7,7,7,0,	7,7,0,0, 0,7,0,0, 7,7,0,0
    db 0,0,0,0,	0,7,0,0, 0,0,0,0, 7,0,0,0
	db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
	
;цвета
;figure_color db 5,6,3,4,2,1,7

	
base_orig ;база игрового поля, со стенками стакана
	dup 20
	db 4,4,4,4,0,0,0,0,0,0,0,0,0,0,4,4,4,4
	edup
	dup 4
	db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	edup
base_orig_end
	


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

base ds base_x_size*base_y_size ;база рабочая
	
msg_title_tetris
	db "Tetris ver 2025.02.12",10,13,0
	

end_tetris
	savebin "tetris.apg",start_tetris,$-start_tetris