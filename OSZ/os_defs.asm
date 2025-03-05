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


;короткие вызовы (именные RST) -------------------------

;печать символа в консоль (ускоренная)
	MACRO OS_PRINT_CHARF ;a=char
	rst #10
	ENDM
	

;передача управления ОС до следующего прерывания (когда придёт очередь процесса в следующий раз);
;все регистры сохраняются
;рекомендуется использовать вместо обычного halt
	MACRO OS_WAIT
	rst #18
	ENDM	

	; MACRO OS_
	; rst #28
	; ENDM	
	
	; MACRO OS_
	; rst #30
	; ENDM	
	
	
	
;вызовы через единую точку входа RST #20 ----------------

;вывод в консоль --------------------	
	
;очистить консоль
	macro OS_CLS ;clear visible area of terminal
    ld c,#00
    rst #20
    endm
	
;установить позицию курсора в консоли	
    macro OS_SET_XY ;de=yx ;SET CURSOR POSITION
    ld c,#01
    rst #20
    endm

;печать символа в консоль	
    macro OS_PRINT_CHAR ;a=char
    ld c,#02
    rst #20
    endm	
	
;заполнение строки одним символом	
    macro OS_FILL_LINE ;; H - line ; A - char
    ld c,#03
    rst #20
    endm	
	
;покрасить строку цветом
    macro OS_PAINT_LINE ;a - line, b - color
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
	
	
;прочитать байт из порта uart
;вх: 
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart или нет данных для приёма
;вых: A - считанный байт
    macro OS_UART_READ
    ld c,#0a
    rst #20
    endm
	
;записать байт в порт uart
;вх: A -байт
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart
    macro OS_UART_WRITE
    ld c,#0b
    rst #20
    endm

;закрыть соединение ESP
;вх: 
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart
    macro OS_ESP_CLOSE
    ld c,#0c
    rst #20
    endm

;установить соединение ESP (CIPSTART);
;вх: a - тип соединения 0-tcp, 1-udp, 2-ssl; 3-прямое соединение с портом; hl - строка адрес, de - строка порт
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart
;вых: ix - адрес в таблице соединений (ix+2 - флаг открытия =1 - открыто, 255 - ошибка); 
    macro OS_ESP_OPEN 
    ld c,#0d
    rst #20
    endm

;послать запрос ESP (CIPSEND);
;вх: hl - адрес данных, de - длина данных
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart
;вых: ix - адрес в таблице соединений (ix+4 - флаг =1 - отправлено, 255 - ошибка)
    macro OS_ESP_SEND 
    ld c,#0e
    rst #20
    endm

;получить пакет ESP (+IPD);
;вх: hl - адрес для данных
;вых: CY=0 - OK; CY=1 - занято другим процессом или нет uart
;вых: ix - адрес в таблице соединений (ix+6 - флаг =1 - принято, 255 - ошибка)
    macro OS_ESP_GET 
    ld c,#0f
    rst #20
    endm	
	
;ввод с консоли ----------------------

;получить код нажатой клавиши
    macro OS_GET_CHAR ;read char from stdin (out: A=char, 255-no char)
    ld c,#10
    rst #20
    endm


;процессы ----------------------------

;запустить процесс
;вх: hl - имя файла (заканчивается на 0)
    macro OS_PROC_RUN ;
    ld c,#11
    rst #20
    endm

;установить фокус
;вх: a - id процесса	
    macro OS_PROC_SET_FOCUS ;
    ld c,#12
    rst #20
    endm

;закрыть процесс
;вх: A - ID процесса. Если A=0, закрыть текущий (себя)
;останавливается процесс и освобождаются все его страницы памяти, файлы, соединения
    macro OS_PROC_CLOSE ;
    ld c,#13
    rst #20
    endm
	

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


;скопировать данные из страницы в страницу
;вх: hl - откуда (абсолютный адрес 0-ffff); de - куда; ix - длина; a - страница слот2; b - страница слот3; 
    macro OS_RAM_COPY
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
;вх: A - номер экрана (5, 7, #39, #3a; 0 = текстовый)
;переключать может только приложение в фокусе
;если режим не текстовый, то приложение работает только когда в фокусе. Иначе временно останавливается.
;при переключении процессов сохраняется только экран #39
    macro OS_SET_SCREEN ;
    ld c,#1d
    rst #20
    endm	
	
	
;получить номера страниц процесса;
;вх:
;вых: b, c - страницы в слотах 2, 3
    macro OS_GET_MAIN_PAGES ;
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
    macro OS_FILE_OPEN ;HL - File name (out: A - id file, bc, de - size)
    ld c,#21
    rst #20
    endm	

;создать файл
    macro OS_FILE_CREATE ;HL - File name  (out: A - id file)
    ld c,#22
    rst #20
    endm	
	
;прочитать из файла
    macro OS_FILE_READ ;HL - address, A - id file, DE - length (out: bc - size readed)
    ld c,#23
    rst #20
    endm	
	
;записать в файл
    macro OS_FILE_WRITE ;HL - address, A - id file, DE - length (out: bc - size writed)
    ld c,#24
    rst #20
    endm	

;закрыть файл
    macro OS_FILE_CLOSE ;A - id file
    ld c,#25
    rst #20
    endm	

;чтение секторов текущего каталога
; вх:
     ; hl - буфер для чтения
     ; de - относительный номер первого сектора каталога для чтения [0..nn]
     ; b - максимальное количество секторов для чтения
; вых: cy=1, если были ошибки, код ошибки возвращается в аккумуляторе
       ; a=errRWnum
       ; a=errInvalidPart
       ; a=errFileEmpty
     ; cy=0, a=errEoF - каталог закончился
       ; hl - следующий адрес в буфере
       ; de - номер первого непрочитанного сектора
       ; b - не прочитано секторов
     ; cy=0 - считано успешно
       ; hl - следующий адрес в буфере
       ; de - номер первого непрочитанного сектора
       ; b=#00
    macro OS_READ_DIR ;
    ld c,#26
    rst #20
    endm

;вход в каталог/выход в родительский каталог
	; Если путь не указан производится только настройка переменных драйвера,
	; при этом если передан дескриптор файла, текущий каталог не изменится)
	; Если пусть указан, в конец пути добавится название каталога (если это
	; переход в родительский, последнее имя в пути удалится).
	; Если передан дескриптор файла, текущий каталог не изменится, к пути
	; добавится имя файла
; вх: 
     ; hl - адрес пути (=#0000 - путь отсутствует)
     ; de - адрес дескриптора директории/файла
; вых: a - если путь был указан, новая длина пути
    macro OS_OPEN_DIR ;
    ld c,#27
    rst #20
    endm


    ; macro OS_ ;
    ; ld c,#28
    ; rst #20
    ; endm

    ; macro OS_ ;
    ; ld c,#29
    ; rst #20
    ; endm	


