;Список всех вызовов (функций) ОС GMX

;Включить в свой код (в начале файла):
	; include os_defs.asm
	
;Использовать только имена функций, коды могут поменяться

;например: 
	; org PROGSTART
	; ../include os_defs.asm
	; ld hl,text
	; OS_PRINTZ ;печать	до кода 0
	
;сохранность регистров не гарантируется
;на выходе обычно (но не всегда) CY=1 = ошибка

PROGSTART equ #8000 ;адрес старта приложений


;вывод в консоль --------------------	

;печать символа в консоль (ускоренная)
	MACRO OS_PRCHARF ;a=char
	rst #10
	ENDM
	
;очистить консоль
	macro OS_CLS ;clear visible area of terminal
    ld c,#00
    rst #20
    endm
	
;установить позицию курсора в консоли	
    macro OS_SETXY ;de=yx ;SET CURSOR POSITION
    ld c,#01
    rst #20
    endm

;печать символа в консоль	
    macro OS_PRCHAR ;a=char
    ld c,#02
    rst #20
    endm	
	
;заполнение строки одним символом	
    macro OS_FLINE ;; H - line ; A - char
    ld c,#03
    rst #20
    endm	
	
;покрасить строку цветом
    macro OS_PLINE ;a - line, b - color
    ld c,#04
    rst #20
    endm	
	

    ; macro OS_ ;
    ; ld c,#05
    ; rst #20
    ; endm		
	
;установить цвет текста в консоли;
    macro OS_SET_COLOR ;a = color, b = color 2 (highlight)
    ld c,#06
    rst #20
    endm	
	
    ; macro OS_ ;
    ; ld c,#07
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#08
    ; rst #20
    ; endm	
	
	
	
;печать в консоль до кода 0
    macro OS_PRINTZ ;hl=text ;PRINT to 0
    ld c,#09
    rst #20
    endm	
	
;прочитать байт из uart порта;
    macro OS_UART_READ ; A - byte (Out: CY=1 Not Readed)
    ld c,#0a
    rst #20
    endm
	
;записать байт в uart порт;
    macro OS_UART_WRITE ; A - byte (Out: CY=1 Not Writed)
    ld c,#0b
    rst #20
    endm

    ; macro OS_ ;
    ; ld c,#0c
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#0d
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#0e
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#0f
    ; rst #20
    ; endm	
	
;ввод с консоли ----------------------

;получить код нажатой клавиши
    macro OS_GETCHAR ;read char from stdin (out: A=char, 255-no char)
    ld c,#10
    rst #20
    endm


    ; macro OS_ ;
    ; ld c,#11
    ; rst #20
    ; endm
	
    ; macro OS_ ;
    ; ld c,#12
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#13
    ; rst #20
    ; endm
	

;прерывания --------------------------

;установка адреса обработчика прерываний процесса;
    ; macro OS_SET_INTER ;(HL - address, A = 1 - On, A = 0 - Off)
    ; ld c,#14
    ; rst #20
    ; endm
	

;плеер AY ----------------------------

;инициализация плеера AY;
    macro OS_VTPL_INIT ;(HL - address music)
    ld c,#15
    rst #20
    endm

;запустить плеер AY (система будет сама вызывать его каждое прерывание);
    macro OS_VTPL_PLAY ;()
    ld c,#16
    rst #20
    endm

;заглушить плеер AY;
    macro OS_VTPL_MUTE ;()
    ld c,#17
    rst #20
    endm

;получить значение переменной плеера;
    macro OS_GET_VTPL_SETUP ;(out: HL - setup address)
    ld c,#18
    rst #20
    endm	
	
	
;прочие ------------------------------


;скопировать страницу в страницу
    macro OS_PAGE_COPY ;(A- page from, B - page to)
    ld c,#19
    rst #20
    endm
	
;получить дополнительную страницу памяти;	
    macro OS_GET_PAGE ;(out A - number page)
    ld c,#1a
    rst #20
    endm

;включить страницу в слот 2 (#8000); предварительно зарезервировать страницу OS_GET_PAGE	
    macro OS_SET_PAGE_SLOT2 ;(A - page number)
    ld c,#1b
    rst #20
    endm

;включить страницу в слот 3 (#C000); предварительно зарезервировать страницу OS_GET_PAGE
    macro OS_SET_PAGE_SLOT3 ;(A - page number)
    ld c,#1c
    rst #20
    endm

;включить экран N;	
    macro OS_SET_SCR ;(A - number screen 5, 7, 39, 3a)
    ld c,#1d
    rst #20
    endm	
	
	
;получить номера страниц процесса;
    macro OS_GET_MAIN_PAGES ;(b, c - pages in slot2, 3)
    ld c,#1e
    rst #20
    endm	
	
;получить значение системного таймера
    macro OS_GET_TIMER ;(out: HL, DE - timer)
    ld c,#1F
    rst #20
    endm	
	
	
	
    ; macro OS_ ;
    ; ld c,#20
    ; rst #20
    ; endm
	
	
;дисковые операции -------------------

;открыть файл для чтения или записи
    macro OS_FOPENRW ;HL - File name (out: A - id file, bc, de - size)
    ld c,#21
    rst #20
    endm	

;создать файл
    macro OS_FOPENC ;HL - File name  (out: A - id file)
    ld c,#22
    rst #20
    endm	
	
;прочитать из файла
    macro OS_FREAD ;HL - address, A - id file, DE - length (out: bc - size readed)
    ld c,#23
    rst #20
    endm	
	
;записать в файл
    macro OS_FWRITE ;HL - address, A - id file, DE - length (out: bc - size writed)
    ld c,#24
    rst #20
    endm	

;закрыть файл
    macro OS_FCLOSE ;A - id file
    ld c,#25
    rst #20
    endm	

    ; macro OS_ ;
    ; ld c,#26
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#27
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#28
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#29
    ; rst #20
    ; endm	

