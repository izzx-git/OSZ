;trdos driver (izzx)
    MODULE Dos
; API methods
ESX_GETSETDRV = #89
ESX_FOPEN = #9A
ESX_FCLOSE = #9B
ESX_FSYNC = #9C
ESX_FREAD = #9D
ESX_FWRITE = #9E

; File modes
FMODE_READ = #01
FMODE_WRITE = #06
FMODE_CREATE = #0E

    ; MACRO esxCall func
    ; rst #8 : db func
    ; ENDM
	
;макросы модуля
;
;R8DOS			вызов функции R8DOS
;R8FAT			вызов функции R8FAT
;R8DOSc			вызов функции R8DOS
;
;------------------------------------------------------------------------------
;вызов функции R8DOS
;вх: =0 номер функции
;
	; MACRO	R8DOS nFunc
	; ld	c,nFunc
	; rst	#08
	; db	#81
	; ENDM

; ;------------------------------------------------------------------------------
; ;вызов функции R8FAT
; ;вх: =0 номер функции
; ;
	; MACRO	R8FAT nFunc
	; ld	c,nFunc
	; rst	#08
	; db	#91
	; ENDM

; ;------------------------------------------------------------------------------
; ;вызов функции R8DOS
; ;вх: c - номер функции
; ;
	; MACRO	R8DOSc
	; rst	#08
	; db	#81
	; ENDM

; ;------------------------------------------------------------------------------
; ;вызов функции #02 (FileMan) R8CONF
; ;вх: =#00 - номер функции файл менеджера
; ;
	; MACRO	R8C02FM nFunct
	; ld	bc,#100*nFunct+#02
	; rst	#08
	; db	#8E
	; ENDM

;==============================================================================
; r8f00_DeinitFAT		equ #00
; r8f01_InitFAT		equ #01
; r8f04_FindPath		equ #04
; r8f07_FileOpen		equ #07 ;открыть файл для последующих операций с ним
; r8f09_FileWrite		equ #09	;запись данных из памяти в файл
; r8f0E_CreateFileLFN	equ #0E ;создание файла с длинным именем в текущем каталоге
; r8f0F_CreateFileSFN	equ #0F

; r8d2D_FindPart		equ #2D
; r8d2E_CngHDD		equ #2E

	
;id = 0 файл не открыт
;id = 1 файл для чтения trdos
;id = 2 файл для записи trdos
;id = 3 файл для записи тип TRD trdos
;id = 4 файл для записи тип SCL trdos
;id = 5 файл для чтения fat32 (пока не сделано)
;id = 6 файл для записи fat32

; HL - filename in ASCIIZ
loadBuffer:
    ld b, Dos.FMODE_READ: call Dos.fopen
    push af
        ld hl, outputBuffer, bc, #ffff - outputBuffer : call Dos.fread
        ld hl, outputBuffer : add hl, bc : xor a : ld (hl), a : inc hl : ld (hl), a
    pop af
    call Dos.fclose
    ret


; Returns: 
;  A - current drive
; getDefaultDrive: ;нигде не используется
    ; ld a, 0 : esxCall ESX_GETSETDRV
    ; ret



; Opens file on default drive
; B - File mode
; HL - File name
; Returns:
;  A - file stream id
fopen:
    ; push bc : push hl 
    ; call getDefaultDrive
    ; pop ix : pop bc
    ; esxCall ESX_FOPEN
    ; ret
	ld a,b
	cp FMODE_READ ;если режим открытие файла
	jr z,fopen_r
	cp FMODE_CREATE
	jr z,fopen_c ;если режим создание файла
	jr fopen_err ;иначе выход
	
fopen_r	;открытие существующего файла на чтение (id=1)

	;call format_name ;
	
	;открыть папку системы по умолчанию
	push hl ;сохранить имя файла
	ld hl,path_os ;папка системы
	xor	a
	dec	a ;установить текущим
	OS_FIND_PATH ;найти папку
	pop hl
	
	OS_FILE_OPEN
	ret
	; ld a,(#5D19) ;номер дисковода по умолчанию
	; ld 	(prev_drive),a ;запомним
			;call format_name ;
			; ld      c,#13 ;move file info to syst var
            ; call    call3d13
            ; ld      c,#0a ;find file
            ; call    call3d13
            ; ld      a,c
			; cp 		#ff
			; jr 		z,fopen_err ;если не нашли файла
            ; ld      c,#08 ;read file title
            ; call    call3d13
            ; ;ld      hl,loadadr ;куда
            ; ld      de,(#5ceb) ;начало файла сектор дорожка
            ; ld      (f_r_cur_trk),de

            ; ld      a,(#5cea)
            ; ld      (f_r_len_sec),a ;длина в секторах
            ; ;or      a
            ; ;ret     z    ;выход если пустой
			
			; ld de,(#5CE8) ; длина файла или программной части для BASIC
			; ld      (f_r_len),de

            ; ; ld      de,(fcurtrk) ;текущие сектор дорожка
            ; ; ld      (#5cf4),de ;восстановим
			; xor a
			; ld (com_file_err_flag),a ;флаг что пока ошибок нет
			; ld 		a,1
			; ld (f_r_flag),a ;флаг что файл для чтения открыт
			; ;id канала будет 1
	;ret
	
fopen_err
	; ld a,1
	; ld (com_file_err_flag),a
	; xor a ;если никакой файл не открыли, то id = 0
	scf ;флаг ошибки
	ret


fopen_c	;создание нового файла (id=2-4,6)
	; ld a,(#5D19) ;номер дисковода по умолчанию
	; ld 	(prev_drive),a ;запомним

	;открыть папку загрузок, если есть
	push hl ;сохранить имя файла
	ld hl,path_download
	xor	a
	dec	a ;установить текущим
	OS_FIND_PATH ;найти папку
	pop hl

	;call format_name ;
	OS_FILE_OPEN ;если есть, откроем
	ret nc
	
	OS_FILE_CREATE ;или создадим
	ret
	
	; call select_drive
	; cp "y"
	; jr nz,fopen_err
	
	; ld a,(curr_drive)
	; cp 4
	; jp nc,fopen_c_fat ;если выбран FAT
	
	; ;выясним, не образ ли это для разворачивания
    ; ld hl, trdExt1 : call CompareBuff.search : and a : jr nz, fopen_c_trd
    ; ld hl, trdExt2 : call CompareBuff.search : and a : jr nz, fopen_c_trd
	; ld hl, sclExt1 : call CompareBuff.search : and a : jp nz, fopen_c_scl
    ; ld hl, sclExt2 : call CompareBuff.search : and a : jp nz, fopen_c_scl

	
	; ;создание произвольного файла (id=2)
	; call cat_buf_cls

	; ld hl,cat_buf ;считаем каталог диска
	; ld de,0
    ; ld      bc,#0905 ;
    ; call    call3d13
	
	; ld a,(cat_buf+8*256+#e4) ; общее количество файлов
	; cp 128
	; jp c,fopen_c2 ;если уже максимум
    ; ld hl, file_err
    ; call DialogBox.msgBox ;предуреждение			
	; jr fopen_err	
	
; fopen_c2	
	; ld hl,(cat_buf+8*256+#e5) ; количество свободных секторов на диске
	; ld a,h
	; or l
	; jr nz,fopen_c3 ;если ещё есть место
    ; ld hl, file_err
    ; call DialogBox.msgBox ;предуреждение			
	; jr fopen_err

; fopen_c3	
	; ld de,(cat_buf+8*256+#e1) ;первые свободные сектор-дорожка 
    ; ld   (#5cf4),de ;отсюда будем писать файл	
	
	; xor a 
	; ld (com_file_err_flag),a ;флаг что пока ошибок нет
	; ld (sec_shift),a ;переменная
	; ld hl,0
	; ld (f_w_len+0),hl
	; ld (f_w_len+2),hl
	; ld a,2 ;id канала
	; ld (f_w_flag),a ;флаг что файл для записи открыт	
	; ret
	
	
; cat_buf_cls ;очистка буфера каталога
	; ld hl,cat_buf ;очистить место для каталога дискеты
	; ld de,cat_buf+1
	; ld (hl),0
	; ld bc,9*256-1
	; ldir
	; ret



; fopen_c_trd	;открытие файла для разворачивания образа trd (id=3)
	; call select_drive
	; cp "y"
	; jp nz,fopen_err
	
	; ld      de,0 ;начало сектор дорожка
    ; ld      (#5cf4),de
	
	; xor a 
	; ld (com_file_err_flag),a ;флаг что пока ошибок нет
	; ld (sec_shift),a ;переменная
	; ld hl,0
	; ld (f_w_len+0),hl
	; ld (f_w_len+2),hl
	; ld a,3 ;id канала
	; ld (f_w_flag),a ;флаг что trd для записи открыт
	; ret
	


; fopen_c_scl	;открытие файла для разворачивания образа scl (id=4)
	; call select_drive
	; cp "y"
	; jp nz,fopen_err
	
	; ld      de,0 ;начало сектор дорожка
    ; ld      (#5cf4),de
	
	; call cat_buf_cls ;почистить место
	
	; call scl_parse ;запуск цикла сборки образа
	
	; xor a 
	; ld (com_file_err_flag),a ;флаг что пока ошибок нет
	; ld (sec_shift),a ;переменная
	; ;ld (scl_que),a
	; ld hl,0
	; ld (f_w_len+0),hl
	; ld (f_w_len+2),hl
	; ld a,4 ;id канала
	; ld (f_w_flag),a ;флаг что scl для записи открыт
	; ret	




; fopen_c_fat	;создание файла FAT (id=6)

; ;переинициализация FAT раздела
	; R8FAT	r8f00_DeinitFAT
	; jp 		c,fopen_err	
	
	; ld a,(curr_drive)
	; ld bc,typeDrive-4
	; ld l,a
	; ld h,0
	; add hl,bc
	; ld a,(hl) ;получили код раздела из списка
	; rlca
	; rlca
	; rlca
	; rlca
	; and %11110000
    ; ;         ld      a,%0000????
                       ; ; ││└┴─── номер раздела
                       ; ; │└───── master/slave для Hdd
                       ; ; └────── SD/Hdd
	; R8FAT	r8f01_InitFAT
    ; jp      c,fopen_err

; ;поиск пути в разделе
	; ld	hl,ActPathFAT		;путь к каталогу Download
	; ld	de,fcb
	; xor	a
	; dec	a
	; R8FAT	r8f04_FindPath
    ; ;jp      c,fopen_err ;если не нашли, файл будет в корне

	; ld	hl,(temp_hl)		;строка с именем
	; ld	de,fcb	
	; R8FAT r8f07_FileOpen
	; jp 	nc,fopen_c_fat2 ;если файл есть, откроем
	
; ;создание файла, если нет
	; ld	hl,(temp_hl)		;строка с именем
	; xor	a
	; ld	(fcb+#14+0),a
	; ld	(fcb+#14+1),a
	; ld	(fcb+#14+2),a	;установим размер
	; ld	(fcb+#14+3),a
	; ld	de,fcb
	; R8FAT	r8f0E_CreateFileLFN	;создание файла
	; jp 	c,fopen_err	

; fopen_c_fat2

	; ld hl,0
	; ld (f_w_len+0),hl
	; ld (f_w_len+2),hl
	; xor a
	; ld (com_file_err_flag),a ;флаг что пока ошибок нет
	; ld a,6 ;id канала
	; ld (f_w_flag),a ;флаг что файл для записи открыт	
	; ret





; select_drive	;запрос номера дисковода
	; ld a,(hdd_init_flag) ;если в первый раз
	; or a
	; jr nz,select_drive2
	; ld a,(#5D19) ;номер дисковода по умолчанию
	; ld (curr_drive),a
	; call GetNumPart ;узнаем какая буква последняя, сколько разделов ФАТ	
	; add "D"
	; ld (write_ima_e),a	;выбор до этой буквы
	; sub "D"
	; inc a
	; add "d"
	; ld (next_lett),a ;эта буква первая свободная
	; ld a,1
	; ld (hdd_init_flag),a
; select_drive2
	; ld a,(curr_drive) ;номер дисковода по умолчанию
	; add a,"A"
	; ld (write_ima_d),a ;подставим букву в запросе
    ; ld hl, write_ima
    ; call DialogBox.msgNoWait ;текст запроса
; select_drive_wait
	; ;halt
	; call Console.getC
	; cp 255
	; JR Z,select_drive_wait	;ждём любую клавишу
	; cp "y"
	; jr z,select_drive_ex
	; cp "n"
	; ret z
	; cp "a" ;от буквы A
	; jr c,select_drive_wait
	; ld hl,next_lett
	; cp (hl) ;до первой свободной буквы
	; jr nc,select_drive_wait
	; sub "a"
	; ld (curr_drive),a ;новый номер диска
	; jr select_drive2 ;обновить строку
; select_drive_ex ;выход
	; ld a,(curr_drive)
	; cp 4 ;начиная с буквы E идёт HDD
	; jr nc,select_drive3
    ; ld      (#5d19) ,a ;если дискета, настроим trdos
    ; ld      c,1
    ; call    call3d13
    ; ld      c,#18
    ; call    call3d13
; select_drive3
	; ld a,"y"
	; ret


; ; restore_drive ;восстановить дисковод по умолчанию
	; ; ld 	a,(prev_drive)
    ; ; ld      (#5d19) ,a
    ; ; ld      c,1
    ; ; call    call3d13
    ; ; ld      c,#18
    ; ; call    call3d13
	; ; ret


; call3d13 ;фикс для GMX
	; ifndef ZSGMX
    ; jp    #3d13
	; endif
	
	; ; ifdef ZSGMX
    ; ; call    #3d13
	; ; exx
	; ; call TextMode.gmxscron
	; ; exx
	; ; endif
	; ret
	
	

; A - file stream id
fclose:
	OS_FILE_CLOSE
	ret

    ; ;esxCall ESX_FCLOSE
	; ; push af
	; ; pop af
	; cp 2 ;если обычный файл 
	; jp nz,fclose_scl

	; ;дописать остаток файла
	; ld a,(write_end_flag) ;нужно записывать остаток?
	; or a
	; jr nz,fclose_f ;не нужно

	; ld hl,sec_buf
	; ld bc,#0106
	; ld de,(#5cf4)
	; call call3d13
	
	; ld a,"0" ;номер части файла
	; ld (file_num),a
	
; fclose_f ;поправить каталог
	; ld a,(f_w_len+2) ;самый старший байт длины файла
	; ld hl,(f_w_len+0)
	; or h
	; or l
	; jp z,fclose_ex ;выход если длина 0 
	
	; ;проверки на заполнение
	; ld a,(cat_buf+8*256+#e4) ; общее количество файлов
	; cp 128
	; jp nc,fclose_ex ;если уже максимум
	; ld hl,(cat_buf+8*256+#e5) ; количество свободных секторов на диске
	; ld a,h
	; or l
	; jp z,fclose_ex ;если места нет	
	
	; ld a,(f_w_len+2) ;самый старший байт длины файла
	; or a
	; jr nz,fclose_f_multi ;если файл больше 255 секторов (65280)
	; ld a,(f_w_len+1)
	; cp 255
	; jr nz,fclose_f1
	; ld a,(f_w_len+0)
	; jr nz,fclose_f_multi ;если файл больше 255 секторов (65280)
; fclose_f1
	; ;файл не превышает максимальный размер для trdos 
	; ld de,(f_w_len+0)	
	; ld hl,f_name+11 ;длина файла
	; ld (hl),e
	; inc hl
	; ld (hl),d
	; inc hl
	; ld a,(f_w_len+1) ;длина секторов
	; ld (hl),a
	; ld a,(f_w_len+0) ;длина младший
	; or a
	; jr z,fclose_f2
	; inc (hl) ;коррекция секторов
; fclose_f2
	; call fclose_f_one ;записать информацию
	; jp fclose_ex ;готово
	
; fclose_f_multi ;файл большой, будет несколько записей в каталоге	
	; ld a,(file_num)
	; ld (f_name+7),a ;в конце имени номер
	
	; ld hl,f_name+11 ;длина файла
	; ld (hl),0
	; inc hl
	; ld (hl),#ff ;65280
	; inc hl
	; ;длина секторов
	; ld (hl),#ff
	; call fclose_f_one ;записать информацию
	
	; ;вычесть длину записанного
	; ld hl,(f_w_len+1) ;старший и средний байт	
	; ld bc,255
	; and a
	; sbc hl,bc ;вычесть 255 секторов
	; ld (f_w_len+1),hl
	
	; ld a,(file_num)
	; inc a
	; ld (file_num),a
	; ld (f_name+7),a ;в конце имени номер

	; jr fclose_f ;сначала

	
; fclose_f_one ;запись об одном файле
			; ld a,(cat_buf+8*256+#e4) ; общее количество файлов
			; ld l,a ;узнать в каком секторе будет запись о файле
			; ld h,0
			; add hl,hl ;*2
			; add hl,hl ;*4
			; add hl,hl ;*8
			; add hl,hl ;*16
			; ld a,h ;запомнить номер сетора в каталоге
			; ld (sec_cat),a
			; ld bc,cat_buf
			; add hl,bc ;здесь будет запись о новом файле
			; ex de,hl
			
			; ld hl,f_name ;запись о файле
			; ld bc,16
			; ldir ;скопировать
			; ex de,hl
			; dec hl
			; ld de,(cat_buf+8*256+#e1) ;первые свободные сектор-дорожка назначения
			; ld (hl),d ;дорожка
			; dec hl
			; ld (hl),e ;сектор
			
			; ld l,0 ;записать сектор целиком по ровному адресу
			; ld d,0
			; ld a,(sec_cat)
			; ld e,a ;номер сектора
			; ld bc,#0106 ;1 сектор записать
			; call call3d13			
			
			; ;служебный сектор
			; ld de,(cat_buf+8*256+#e1) ;первые свободные сектор-дорожка 
			; ld a,(f_name+13) ;размер файла в секторах
			; ld b,a
			; call calc_next_pos2
			; ld (cat_buf+8*256+#e1),de

			; ld hl,(cat_buf+8*256+#e5) ; количество свободных секторов на диске
			; ld a,(f_name+13) ;размер файла в секторах
			; ld c,a
			; ld b,0
			; and a
			; sbc hl,bc
			; jr nc,fclose_f_one2
			; ld hl,0 ;если было отрицательное
; fclose_f_one2
			; ld (cat_buf+8*256+#e5),hl
			
			; ld hl,cat_buf+8*256+#e4 ; общее количество файлов			
			; inc (hl)
			
			; ld hl,cat_buf+8*256
			; ld de,#0008
			; ld bc,#0106 ;1 сектор записать
			; call call3d13
			; ret
	
	
; fclose_scl	
	; cp 4 ;если scl
	; jr nz,fclose_ex
	; ld hl,sec_buf ;
	; ld b,1
	; call scl_write_buf ;допишем остаток scl, если есть
	
; fclose_ex	
	; xor a ;закрываем все файлы
	; ld (f_r_flag),a
	; ld (f_w_flag),a
	
	; ld a,(com_file_err_flag) ;была ли ошибка
	; or a
	; ret z
	; ld a,2 ;если была
	; out (254),a ;бордюр красный
    ; ld hl, com_file_err ;общая ошибка
    ; call DialogBox.msgBox ;предуреждение
	; xor a ;
	; out (254),a
	; ;call restore_drive ;вернуть диск, какой был
    ; ret




; A - file stream id
; BC - length
; HL - buffer
; Returns
;  BC - length(how much was actually read) 
fread: ;(id=1)
	ld e,c ;сохранить длину
	ld d,b
	OS_FILE_READ
	ret
	
    ; push hl : pop ix
    ; esxCall ESX_FREAD
	; push af
	; ld a,4
	; out (254),a
	; xor a
	; out (254),a
	; pop af

	; cp 1 ;id = 1?
	; jr nz,fread_no_chek ;выход если номер потока не = 1
	; ld a,(f_r_flag)
	; or a
	; jr nz,fread_chek ;файл уже открыт?
; fread_no_chek ;выход с ошибкой
	; xor a
	; scf ;флаг ошибки
	; ld bc,0 ;ничего мы не считали
	; ret
	
; fread_chek
	; ld bc,(f_r_len_sec-1) ;загружаем файл целиком, не смотря на то, сколько байт было запрошено
    ; ld      c,5 ;read читаем целыми секторами
	; ld de,(f_r_cur_trk)
    ; call    call3d13	
	; ld bc,(f_r_len) ;возвратим сколько считали байт (длину файла)
	; xor a ;флаги сбросим
    ; ret

; A - file stream id
; BC - length
; HL - buffer
; Returns:
;   BC - actually written bytes
fwrite: ;
	ld e,c ;сохранить длину
	ld d,b
	OS_FILE_WRITE
	ret

    ; push hl : pop ix
    ; esxCall ESX_FWRITE
	
	; push af
	; ld a,2
	; out (254),a

	; xor a
	; out (254),a
	; pop af

	; cp 2 ;id = 2?
	; jr z,fwrite_chek ;проверка id потока
	; cp 3 ;id = 3?
	; jr z,fwrite_chek_trd ;проверка id потока
	; cp 4 ;id = 4?
	; jp z,fwrite_chek_scl ;проверка id потока
	; cp 6 ;id = 6?
	; jp z,fwrite_chek_fat ;проверка id потока

	
; fwrite_no_chek ;выход с ошибкой
	; ld a,1
	; ld (com_file_err_flag),a
	; xor a
	; scf ;флаг ошибки
	; ld bc,0 ;ничего мы не записали
	; ret
	
; fwrite_chek ;запись произвольного типа файла (id=2)

	; ;не отличается от записи trd, пишется входящий поток на диск, отличия при открытии и закрытии файла





; fwrite_chek_trd ;запись trd файла (разворачивание образа, id=3)
	; ; ld a,2
	; ; out (254),a

	; ; xor a
	; ; out (254),a
	; ld a,(f_w_flag)
	; or a
	; jr z,fwrite_no_chek ;файл уже открыт?
	; ld (temp_bc),bc ;длина
	; ld (temp_hl),hl ;адрес данных
	; ld a,b
	; or c
	; jr z,fwrite_no_chek ; если длина 0, то выход
	
	; ;защита от переполнения диска
	; ld de,(#5cf4)
	; ld a,d
	; cp #a0 ;последняя дорожка 160
	; jr nc,fwrite_no_chek
	
	; xor a
	; ld (sec_part),a ;обнулить переменные
	; ld (sec_shift2),a
	; ld (sec_shift2+1),a
	; ld (sec_shift_flag),a
	; ld (write_end_flag),a ;
	

	; ld a,(sec_shift)
	; or a
	; jr z,fwrite_trd3 ;если смещения нет, то первую часть пропустим
	

	; ld c,a
	; ld b,0
	; ld hl,(temp_bc) ;проверка заполнится ли целый сектор
	; add hl,bc
	
	; ld a,1
	; ld (write_end_flag),a ;флаг что не нужно дописывать остаток
	
	; ld a,h
	; or a
	; jr nz,fwrite_trd4
	; ld a,1
	; ld (sec_shift_flag),a ;флаг что не заполнен сектор
	
; fwrite_trd4	
	; ld hl,sec_buf ;буфер последнего сектора	
	; add hl,bc ;на этой точке остановились
	; ex de,hl
	; ld hl,(temp_hl) ;присоединим начало данных в конец предыдущих
	; ; ld a,c
	; ; or a
	; ; jr nz,fwrite_trd2
	; ; inc b ;коррекция
; ; fwrite_trd2		
	; ; ld c,a
	; xor a
	; sub c
	; ld c,a ;сколько осталось перенести до заполнения сектора
	; ld (sec_shift2),bc ;сохраним сколько добавили байт
	; ldir

	; ld a,(sec_shift_flag)
	; or a
	; jr nz,fwrite_trd3 ;если сектор ещё не заполнен писать не будем

	; ld hl,sec_buf
	; ld de,(#5cf4)
	; ;ld (f_w_cur_trk),de	;запомним позицию
    ; ld      bc,#0106 ;пишем 1 сектор из буфера
    ; call    call3d13	
	; ld a,c
	; cp 255
	; jp z,fwrite_no_chek ;выход если ошибка	

	; xor a
	; ld (write_end_flag),a ;флаг что нужно дописывать остаток	
	; ; ld de,(f_w_cur_trk) ;если сектор ещё не заполнен, останемся на старой позиции
	; ; ld (#5cf4),de
	; ; ld b,1 ;на сектор вперёд
	; ; ld de,(f_w_cur_trk)
	; ; call calc_next_pos
	; ; ld (f_w_cur_trk),de	

; fwrite_trd3	
	; ld hl,(temp_hl) ;запишем остаток данных
	; ;ld a,(sec_shift)
	; ;ld c,a
	; ;ld b,0
	; ld bc,(sec_shift2)
	; add hl,bc ;с этой точки пишем
	; ld (temp_hl2),hl ;сохраним начало записи второго сектора
	
	; ld hl,(temp_bc) ;вычисление на чём остановимся в этот раз
	; and a
	; sbc hl,bc ;вычтем то, что добавили к первому сектору
	; ld c,l
	; ld b,h
	; jr nc,fwrite_trd5
	; ld b,0 ;коррекция если вышел минус
; fwrite_trd5
	; ld hl,(temp_hl)
	; add hl,bc 
	
	; ld de,outputBuffer
	; and a
	; sbc hl,de
	
	; ld a,l
	; ld (sec_shift),a ;смещение на следующий раз
	; ;ld hl,(temp_hl)	
	

	; ; or a
	; ; jr z,fwrite_trd1
	; ; inc b  ;коррекция количества секторов
	
	; ld a,b ;нужна проверка на количество секторов!!!
	; ld (sec_part),a ;запомним сколько секторов во второй части
	
	; ;ld a,b	
	; or a
	; jr z,fwrite_trd1 ;если размер данных меньше сектора, то пропустим запись
	
	; ld hl,(temp_hl2)
	; ;push bc
	; ld de,(#5cf4)
    ; ld      c,6 ;пишем целыми секторами
    ; call    call3d13	
	; ld a,c
	; ;pop bc
	; cp 255
	; jp z,fwrite_no_chek ;выход если ошибка
	; ; ld de,(f_w_cur_trk)
	; ; call calc_next_pos
	; ; ld (f_w_cur_trk),de
	
	; xor a
	; ld (write_end_flag),a ;флаг что нужно дописывать остаток	
	
; fwrite_trd1	
	; ld a,(write_end_flag) ;нужно записывать остаток?
	; or a
	; jr nz,fwrite_trd_ex ;не нужно

	; ld hl,(temp_hl2) ;сохраним незаписанный остаток
	; ld a,(sec_part)
	; ld b,a
	; ld c,0
	; add hl,bc
	; ld de,sec_buf
	; ld bc,256
	; ldir
; ;fwrite_trd2	

	
; fwrite_trd_ex	
	; ld bc,(temp_bc) ;возвратим, что сколько запрашивали, столько и записали байт
	; ;посчитаем общую длину записанного
	; ld hl,(f_w_len)
	; add hl,bc
	; ld (f_w_len),hl
	; jr nc,fwrite_trd_ex1
	; ld hl,(f_w_len+2)
	; inc hl
	; ld (f_w_len+2),hl
	
; fwrite_trd_ex1
	; xor a ;флаги сбросим
    ; ret





; ;------------------scl----------------------
; fwrite_chek_scl ;запись scl файла (разворачивание образа, id=4)
	; ; ld a,2
	; ; out (254),a

	; ; xor a
	; ; out (254),a
	; ld a,(f_w_flag)
	; or a
	; jp z,fwrite_no_chek ;файл уже открыт?
	; ld (temp_bc),bc ;длина
	; ld (temp_hl),hl ;адрес данных
	; ld a,b
	; or c
	; jp z,fwrite_no_chek ; если длина 0, то выход
	
	; ; ld a,b
	; ; or a
	; ; jr nz,testt1
	; ; nop
	
; ; testt1
	
	; xor a
	; ld (sec_part),a ;обнулить переменные
	; ld (sec_shift2),a
	; ld (sec_shift2+1),a
	; ld (sec_shift_flag),a
	; ld (write_end_flag),a ;
	

	; ld a,(sec_shift)
	; or a
	; jr z,fwrite_scl3 ;если смещения нет, то первую часть пропустим
	

	; ld c,a
	; ld b,0
	; ld hl,(temp_bc) ;проверка заполнится ли целый сектор
	; add hl,bc
	
	; ld a,1
	; ld (write_end_flag),a ;флаг что не нужно дописывать остаток
	
	; ld a,h
	; or a
	; jr nz,fwrite_scl4
	; ld a,1
	; ld (sec_shift_flag),a ;флаг что не заполнен сектор
	
; fwrite_scl4	
	; ld hl,sec_buf ;буфер последнего сектора	
	; add hl,bc ;на этой точке остановились
	; ex de,hl
	; ld hl,(temp_hl) ;присоединим начало данных в конец предыдущих
	; ; ld a,c
	; ; or a
	; ; jr nz,fwrite_scl2
	; ; inc b ;коррекция
; ; fwrite_scl2		
	; ; ld c,a
	; xor a
	; sub c
	; ld c,a ;сколько осталось перенести до заполнения сектора
	; ld (sec_shift2),bc ;сохраним сколько добавили байт
	; ldir

	; ld a,(sec_shift_flag)
	; or a
	; jr nz,fwrite_scl3 ;если сектор ещё не заполнен писать не будем

	; ld hl,sec_buf
	; ;ld de,(#5cf4)
	; ;ld (f_w_cur_trk),de	;запомним позицию
    ; ld      b,#01 ;пишем 1 сектор из буфера
    ; call    scl_write_buf	
	; ; ld a,c
	; ; cp 255
	; ; jp z,fwrite_no_chek ;выход если ошибка	

	; xor a
	; ld (write_end_flag),a ;флаг что нужно дописывать остаток	
	; ; ld de,(f_w_cur_trk) ;если сектор ещё не заполнен, останемся на старой позиции
	; ; ld (#5cf4),de
	; ; ld b,1 ;на сектор вперёд
	; ; ld de,(f_w_cur_trk)
	; ; call calc_next_pos
	; ; ld (f_w_cur_trk),de	

; fwrite_scl3	
	; ld hl,(temp_hl) ;запишем остаток данных
	; ;ld a,(sec_shift)
	; ;ld c,a
	; ;ld b,0
	; ld bc,(sec_shift2)
	; add hl,bc ;с этой точки пишем
	; ld (temp_hl2),hl ;сохраним начало записи второго сектора
	
	; ld hl,(temp_bc) ;вычисление на чём остановимся в этот раз
	; and a
	; sbc hl,bc ;вычтем то, что добавили к первому сектору
	; ld c,l
	; ld b,h
	; jr nc,fwrite_scl5
	; ld b,0 ;коррекция если вышел минус
; fwrite_scl5
	; ld hl,(temp_hl)
	; add hl,bc 
	
	; ld de,outputBuffer
	; and a
	; sbc hl,de
	
	; ld a,l
	; ld (sec_shift),a ;смещение на следующий раз
	; ;ld hl,(temp_hl)	
	

	; ; or a
	; ; jr z,fwrite_scl1
	; ; inc b  ;коррекция количества секторов
	
	; ld a,b ;нужна проверка на количество секторов!!!
	; ld (sec_part),a ;запомним сколько секторов во второй части
	
	; ;ld a,b	
	; or a
	; jr z,fwrite_scl1 ;если размер данных меньше сектора, то пропустим запись
	
	; ld hl,(temp_hl2)
	; ;push bc
	; ;ld de,(#5cf4)
    ; ;ld      c,6 ;пишем целыми секторами
    ; call    scl_write_buf	
	; ;ld a,c
	; ;pop bc
	; ; cp 255
	; ; jp z,fwrite_no_chek ;выход если ошибка
	; ; ld de,(f_w_cur_trk)
	; ; call calc_next_pos
	; ; ld (f_w_cur_trk),de
	
	; xor a
	; ld (write_end_flag),a ;флаг что нужно дописывать остаток	
	
; fwrite_scl1	
	; ld a,(write_end_flag) ;нужно записывать остаток?
	; or a
	; jr nz,fwrite_scl_ex ;не нужно

	; ld hl,(temp_hl2) ;сохраним незаписанный остаток
	; ld a,(sec_part)
	; ld b,a
	; ld c,0
	; add hl,bc
	; ld de,sec_buf
	; ld bc,256
	; ldir
; ;fwrite_scl2	

	
; fwrite_scl_ex	
	; ld bc,(temp_bc) ;возвратим, что сколько запрашивали, столько и записали байт
	; ;посчитаем общую длину записанного
	; ld hl,(f_w_len)
	; add hl,bc
	; ld (f_w_len),hl
	; jr nc,fwrite_scl_ex1
	; ld hl,(f_w_len+2)
	; inc hl
	; ld (f_w_len+2),hl
	
; fwrite_scl_ex1
	; xor a ;флаги сбросим
    ; ret






; scl_write_buf ;заполнение промежуточного буфера
	; push bc ;сколько пакетов указано в b
	; ld de,scl_buf ;перенесём сектор во временный буфер
	; ld bc,256
	; ldir
	; ld (scl_temp_hl2),hl ;сохраним адрес данных
	; ld a,(scl_que) ;проверим флаг что нужны данные
	; or a
	; jr z,scl_write_buf_ret ;не будем вызывать парсер если не нужны
	; ld hl,scl_write_buf_ret ;адрес возврата
	; push hl
	; ld hl,(scl_parse_ret_adr) ;адрес для продолжения основного цикла сборки
	; jp (hl) ;отдадим пакет 256 байт парсеру
; scl_write_buf_ret
	; ld hl,(scl_temp_hl2)
	; pop bc
	; djnz scl_write_buf

	; ret
	
	
	
; scl_parse ;разбор образа scl в trd, основной цикл
	; ;получить первый сектор
; ;запрос порции данных по 256 байт
	; ld (scl_temp_hl),hl
	; ld (scl_temp_de),de
	; ld (scl_temp_bc),bc
	; ld a,1
	; ld (scl_que),a ;включим флаг что нужны данные
	; ld hl,scl_parse_ret ;сохраним адрес возврата
	; ld (scl_parse_ret_adr),hl
	; ret ;вернёмся для ожидания данных
; scl_parse_ret	
	; xor a
	; ld (scl_que),a
	; ld hl,(scl_temp_hl)
	; ld de,(scl_temp_de)
	; ld bc,(scl_temp_bc)
	
	; ld de,scl_buf ;проверка метки образа
	; ld hl,scl_sign
	; ld b,8
; scl_parse_chk
	; ld a,(de)
	; cp (hl)
	; jr nz,scl_parse_chk_no
	; inc hl
	; inc de
	; djnz scl_parse_chk
	; jr scl_parse_chk_ok
; scl_parse_chk_no ;если не совпало, значит плохой образ
    ; ld hl, scl_err
    ; call DialogBox.msgBox ;предуреждение
	; xor a
	; ld (scl_que),a ;выключим флаг что нужны данные
	; ld a,4 ;закроем файл
	; call fclose
	; ret
; scl_parse_chk_ok ;сигнатура правильная

; ;формирование каталога
	; ld a,(scl_buf+8)
	; ld (scl_files),a ;всего файлов
	; ld (scl_cat_cycl),a ;цикл
	; ld hl,scl_buf+9 ;адрес первого заголовка
	; ld de,cat_buf ;адрес формируемого каталога trd
; scl_parse_cat2	
	; ld b,14 ;14 байт одна запись
; scl_parse_cat	
	; ld a,(hl)
	; ld (de),a
	; inc de
	; inc l ;адрес увеличиваем только в пределах младшего регистра
	; jr nz,scl_parse_cat1
	; ;тут пора запросить следующий сектор
; ;запрос порции данных по 256 байт
	; ld (scl_temp_hl),hl
	; ld (scl_temp_de),de
	; ld (scl_temp_bc),bc
	; ld a,1
	; ld (scl_que),a ;включим флаг что нужны данные
	; ld hl,scl_parse_ret1 ;сохраним адрес возврата
	; ld (scl_parse_ret_adr),hl
	; ret ;вернёмся для ожидания данных
; scl_parse_ret1
	; xor a
	; ld (scl_que),a
	; ld hl,(scl_temp_hl)
	; ld de,(scl_temp_de)
	; ld bc,(scl_temp_bc)
	
; scl_parse_cat1
	; djnz scl_parse_cat
	; inc de
	; inc de
	; ld a,(scl_cat_cycl)
	; dec a
	; ld (scl_cat_cycl),a
	; jr nz,scl_parse_cat2
	
	; ld (scl_temp_hl),hl ;запомнить где остановились
	
; ;подсчёт секторов и дорожек
	; push ix
	; ld a,(scl_files)
	; ld de,#0100 ;данные с первой дорожки
	; ld ix,cat_buf
	; ld (ix+14),e
	; ld (ix+15),d
	; ld hl,0 ;общее количество секторов
; scl_cacl
	; ld (scl_cat_cycl),a ;цикл
	; ld a,(ix+13) ;длина файла в секторах
	; ld c,a
	; ld b,0
	; add hl,bc ;секторов
	
	; ld bc,16
	; add ix,bc
	; ld b,a
	; call calc_next_pos
	; ld a,(scl_cat_cycl)
	; cp 1
	; jr z,scl_cacl2 ;в последний раз пропусим
	; ld (ix+14),e 
	; ld (ix+15),d
; scl_cacl2
	; dec a
	; jr nz,scl_cacl
	; ;теперь узнаем первый свободный сектор
	; ld a,(ix+13) ;длина файла в секторах
	; ld c,a
	; ld b,0
	; add hl,bc
	; ; ld b,a
	; ; call calc_next_pos
	; ld (cat_buf+8*256+#e1),de ;Первый свободный сектор и дорожка на дискете
	; ld de,16*159
	; ex de,hl
	; and a
	; sbc hl,de
	; ld (cat_buf+8*256+#e5),hl ;Число свободных секторов на диске
	; pop ix


	
; ;запись содержимого файлов
	; ld a,(scl_files) ;всего файлов
	; ld (scl_cat_cycl),a ;цикл
	; ld hl,cat_buf+13 ;адрес размер секторов файла
	; ld (cat_cur_adr),hl

	; ld hl,#0100 ;начиная с первой дорожки
	; ld (#5cf4),hl
; scl_parse_file2	
	; ld hl,(scl_temp_hl) ;адрес данных
	; ld de,(cat_cur_adr) ;адрес сектор дорожка файла
	; ;dec de
	; ld a,(de) ;количество секторов, цикл
	; ld c,a
; scl_parse_file3
	; ld de,scl_buf2 ;адрес ещё одного буфера
	; ld b,0 ;256 байт один сектор, цикл
; scl_parse_file	
	; ld a,(hl)
	; ld (de),a
	; inc de
	; inc l ;адрес увеличиваем только в пределах младшего регистра
	; jr nz,scl_parse_file1
	; ;тут пора запросить следующий сектор
; ;запрос порции данных по 256 байт
	; ld (scl_temp_hl),hl
	; ld (scl_temp_de),de
	; ld (scl_temp_bc),bc
	; ld a,1
	; ld (scl_que),a ;включим флаг что нужны данные
	; ld hl,scl_parse_ret2 ;сохраним адрес возврата
	; ld (scl_parse_ret_adr),hl
	; ret ;вернёмся для ожидания данных
; scl_parse_ret2
	; xor a
	; ld (scl_que),a
	; ld hl,(scl_temp_hl)
	; ld de,(scl_temp_de)
	; ld bc,(scl_temp_bc)
	
; scl_parse_file1
	; djnz scl_parse_file
	; ld (scl_temp_hl),hl	
	; ld (scl_temp_bc),bc
	
	; ld hl,scl_buf2 ;;запишем один сектор
	; ld  de,(#5cf4)
    ; ld      bc,#0106 ;
    ; call    call3d13	
	; ; ld a,c
	; ; cp 255
	; ; jp z,fwrite_no_chek ;выход если ошибка	
	; ld hl,(scl_temp_hl)
	; ld bc,(scl_temp_bc)
	
	; dec c
	; jr nz,scl_parse_file3
	
	; ld hl,(cat_cur_adr) ;адрес сектор дорожка файла
	; ; ld e,(hl)
	; ; inc hl
	; ; ld d,(hl)
	; ld bc,16
	; add hl,bc ;на следующий файл
	; ld (cat_cur_adr),hl	
	
	
	; ld a,(scl_cat_cycl)
	; dec a
	; ld (scl_cat_cycl),a
	; jr nz,scl_parse_file2	;на следующий файл
	
	

; ;формирование системного сектора №9 (8)
	; ;
	; ;ld (cat_buf+8*256+#e1),a ;// #E1 Первый свободный сектор на дискете
	; ;
	; ;ld (cat_buf+8*256+#e2),a ;// #E2 Первый свободный трек
	; ld a,#16
	; ld (cat_buf+8*256+#e3),a ;// #E3 16 80 дорожек, 2 стороны
	; ld a,(scl_files)
	; ld (cat_buf+8*256+#e4),a ;// #E4 Общее количество файлов записанных на диск
	; ;
	; ;ld (cat_buf+8*256+#e5),a ;// #Е5,Е6 Число свободных секторов на диске
	; ;ld (cat_buf+8*256+#e6),a
	; ld a,#10
	; ld (cat_buf+8*256+#e7),a ;// #E7 Код  #10,определяющий принадлежность к TR-DOS	

	; ld hl,f_name ;запишем имя диска, взяв для этого имя файла
	; ld de,cat_buf+8*256+#f5 ;// #F5-#FC Имя диска в ASCII формате
	; ld bc,8
	; ldir
	
	; ld hl,cat_buf ;запишем каталог на диск
	; ld de,0
    ; ld      bc,#0906 ;
    ; call    call3d13	
	; ; ld a,c
	; ; cp 255
	; ; jp z,fwrite_no_chek ;выход если ошибка	
	; ret


; ;-----------scl end --------------------



; ;---------------------------------------
; fwrite_chek_fat ;запись файла fat
	; ld (temp_bc),bc ;длина
	; ld a,c ;младший байт длины
	; ld	de,fcb		
	; R8FAT r8f09_FileWrite	;записать в файл
	; jp 	c,fwrite_no_chek 	
	
	; ld bc,(temp_bc) ;возвратим, что сколько запрашивали, столько и записали байт
	; ;посчитаем общую длину записанного
	; ld hl,(f_w_len)
	; add hl,bc
	; ld (f_w_len),hl
	; jr nc,fwrite_fat_ex1
	; ld hl,(f_w_len+2)
	; inc hl
	; ld (f_w_len+2),hl
; fwrite_fat_ex1	
	; xor a ;флаги сбросим
	; ret
;---------------------------------------


    
; A - file stream id
; fsync:
;     esxCall ESX_FSYNC
    ; ret


; ; HL - name (name.ext)
; ; Returns:
; ; HL - name (name    e)	
; format_name ;подгоняет имя файла под стандарт trdos (8+1)

	; ;сначала попробуем убрать из пути подпапку, если она есть
	; ld (temp_hl),hl ;сохраним адрес исходного имени
	; ld b,#00 ;не больше 255 символов	
; format_name5	
	; ld a,(hl)
	; cp "/" ;если есть подпапка
	; jr z,format_name_path_yep
	; ld a,(hl)
	; cp "." ;если ещё не дошли до расширения
	; jr nz,format_name6
	; ld hl,(temp_hl) ;если дошли до расширения, то путей нет, вернёмся на начало имени
	; jr format_name_7 ;на выход
; format_name6
	; inc hl
	; djnz format_name5
	
; format_name_path_yep ;нашли
	; inc hl ;пропустим знак "/"
	
; format_name_7	

	; push hl ;очистим место для нового имени
	; ld hl,f_name
	; ld de,f_name+1
	; ld (hl)," "
	; ld bc,8+1
	; ldir
	; ld (hl),0
	; ld bc,16-8-1-1
	; ldir
	; pop hl

	; ld bc,#09ff ;длина имени 9 символов
	; ld de,f_name ;куда
; format_name2	
	; ld a,(hl)
	; cp "."
	; jr nz,format_name1
	; ld de,f_name+8
	; inc hl
	; ldi ; и в конце расширение 3 буквы
	; ldi
	; ldi
	; ;ex de,hl ;сохраним адрес исходного расширения
	; jr format_name_e
; format_name1
	; ldi
	; djnz format_name2
	
	; ;если имя длинное, пропустим лишнее до расширения
	; ld b,#00 ;не больше 255 символов	
; format_name3	
	; ld a,(hl)
	; cp "."
	; jr nz,format_name4
	; ld de,f_name+8
	; inc hl
	; ldi ; и в конце расширение 3 буквы
	; ldi
	; ldi
	; ;ex de,hl ;сохраним адрес исходного расширения
	; jr format_name_e
; format_name4
	; inc hl
	; djnz format_name3
	
; format_name_e ;выход
	; ld hl,f_name ;вернём результат
	; ret

; ; DE - trk/sec
; ; B - sectors step
; ; Returns:
; ; DE - trk/sec	
; calc_next_pos		;вперёд на N секторов	
			; ;ld b,4 
			; ;ld  de,(#5ceb) 
; calc_next_pos2		
			; inc e
			; ld a,e
			; cp 16
			; jr c,calc_next_pos1
			; inc d
			; ld e,0
; calc_next_pos1
			; ;ld (#5ceb),de
			; djnz calc_next_pos2
			; ret
			

; ;testt db "123.trd"
; write_ima db "Select disk "
; write_ima_d db "A: (A-" ;текущая буква
; write_ima_e	db "D). " ;последняя буква
		; db "All data may be lost! Press Y or N.",0
; ;prev_drive db 0 ;предыдущий номер дисковода
; curr_drive db 0 ;текущий диск
		
; trdExt1 db ".trd", 0
; trdExt2 db ".TRD", 0

; sclExt1 db ".scl", 0
; sclExt2 db ".SCL", 0

;f_name ds 16 ;имя файла
; f_r_cur_trk dw 	 0 ;текущие сектор-дорожка файла на чтение
; f_r_len_sec db 0 ;длина файла на чтение в секторах
; f_r_len dw 0;длина файла в байтах
; f_r_flag db 0 ;флаг что открыт файл на чтение

; f_w_cur_trk dw 	 0 ;текущие сектор-дорожка файла на запись
; f_w_len_sec db 0 ;длина файла на запись в секторах
; f_w_flag db 0 ;флаг что открыт файл на запись
; f_w_len ds 4 ;длина записанных данных
; write_end_flag db 0 ;флаг что нужно записать остаток

; temp_bc dw 0 ;хранение регистра 
;temp_hl dw 0 ;хранение регистра 
; temp_hl2 dw 0 ;хранение регистра 

; sec_shift db 0 ;указатель на каком байте остановлена запись
; sec_shift2 db 0 ;указатель на каком байте остановлена запись (остаток)
; sec_part db 0 ;сколько секторов во второй порции для записи
; sec_shift_flag db 0 ;флаг что буфер сектора не заполнен

; ;секция scl
; scl_sign db "SINCLAIR" ;метка
; scl_que db 0 ;флаг запроса порции данных
; scl_err db "SCL image error!",0
; scl_parse_ret_adr dw 0; адрес возврата в цикл
; scl_cat_cycl db 0 ;переменная цикла
; scl_files db 0 ;всего файлов
; scl_temp_hl dw 0;;хранение регистра
; scl_temp_hl2 dw 0;
; scl_temp_de dw 0;
; scl_temp_bc dw 0;
; cat_cur_adr dw 0;
; ;scl end

; ;секция сохранения любого файла
; file_err db "Not enough space!",0
; sec_cat db 0 ;сектор каталога
; file_num db "0" ;номер части для больших файлов

	; ;по адресу #4000 шрифт
; cat_buf equ #4800 ;буфер для кататога диска 9*256
; sec_buf equ cat_buf + 9*256 ;буфер сектора для записи 256
; scl_buf equ sec_buf + 512 ;промежуточный буфер 256
; scl_buf2 equ scl_buf + 512 ;промежуточный буфер 256
; ;общая ошибка с файлами
; com_file_err db "File error!",0
; com_file_err_flag db 0 ;общая ошибка




; ;Раздел SMUC и SD ------------------------------------
	

; ;список доступных разделов на винчестерах
; ;7,=0/1 тип раздела MFS/FAT
; ;6,=1 раздел есть
; ;3,=0/1 Hdd/SD card
; ;2,=0/1 для HDD master/slave
; ;0..1,=?? номер раздела
; ;
; typeDrive	ds 3*4+1
; ;typeDriveFAT	ds 3*4+1 ;список всех разделов FAT
; numDrives db 0 ;количество устройств
; ;numDrivesFAT db 0 ;количество устройств FAT
; next_lett db 0 ;следующая свободная буква диска

; ;подсчет количества доступных разделов на всех устройствах
; ;вых: hl,a - количество устройств
; ;     typeDrives - сформированная таблица
; ;     cy=1 не обнаружено ни одного устройства
; ;
; GetNumPart
; ;
	; push	de
	; push	bc
	; ld	hl,typeDrive
	; push	hl
	; xor	a
	; call	proc_01			;HDD master
	; ld	a,#01
	; call	proc_01			;HDD slave
	; ld	a,#02
	; call	proc_01			;SD card
	; pop	de
	; or	a
	; sbc	hl,de			;количество разделов на HDD
	; IFDEF	useTRD
	 ; ld	a,l
	 ; add	a,#04
	 ; ld	l,a
	; ELSE
	 ; ld	a,l
	; ENDIF
	; pop	bc
	; pop	de
	; ld	(numDrives),a
	; cp	1
	; ret

; ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; ;формирование таблицы с доступными разделами на винчестере
; ;вх:  a =#00 выбрать master
; ;       =#01 выбрать slave
; ;       =#02 выбрать SD card
; ;     hl - адрес в таблице разделов typeDrives
; ;вых: hl - новый адрес в таблице разделов typeDrives
; ;
; proc_01	ld	c,a
	; push	hl
	; push	bc
	; R8DOS	r8d2E_CngHDD
	; jr	c,goto001		;на текущем канале нет винчестера
	; R8DOS	r8d2D_FindPart
; goto001	pop	bc
	; pop	hl
	; ret	c			;на текущем винчестере нет разделов
	; ld	b,a
	; ld	a,c
	; add	a,a
	; add	a,a
	; ld	c,a			;номер винчестера и первого раздела
	; ld	a,b
	; ld	b,#04
; loop001	ld	(hl),#00
	; rra
	; jr	nc,goto002		;нет раздела
	; IFDEF	useMFS
	 ; ld	(hl),c
	 ; set	6,(hl)			;=%01???hpp MFS
	 ; rra
	 ; jr	nc,goto003		;это MFS
	 ; set	7,(hl)			;=%11???hpp это FAT
	; ELSE
	 ; rra
	 ; jr	nc,goto004		;это MFS
	 ; ld	(hl),c
	 ; set	6,(hl)			;раздел есть
	 ; set	7,(hl)			;=%11???hpp это FAT
	; ENDIF
; goto003	inc	hl
	; rla
; goto002	rra
; goto004	inc	c
	; djnz	loop001
	; ret



; hdd_init_flag: db 0 ;флаг инициализации
; ;fcb_tmp ds 32 ;буфер fcb временно
; ActPathFAT db "\\Download",0 ;папка для сохранений
; fcb ds 32	;буфер fcb	
	; nop
; ;конец секции SMUC и SD ----------------------------
path_os db "\\OSZ",0
path_download db "\\OSZ\\Download\\MoonR",0
;path_deskr ds 32 ;дескриптор каталога
	

    ENDMODULE