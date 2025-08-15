;trdos & fat32 driver (izzx)
    MODULE Dos
; API methods - для всех процессов
;ESX_GETSETDRV = #89
;ESX_FOPEN = #9A
;ESX_FCLOSE = #9B
;ESX_FSYNC = #9C
;ESX_FREAD = #9D
;ESX_FWRITE = #9E

; File modes
FMODE_READ = #01
;FMODE_WRITE = #06
FMODE_CREATE = #0E

    ; MACRO esxCall func
    ; rst #8 : db func
    ; ENDM
	
;макросы только для внутренней работы самого модуля через BIOS
;
;R8DOS			вызов функции R8DOS
;R8FAT			вызов функции R8FAT
;R8DOSc			вызов функции R8DOS
;
;------------------------------------------------------------------------------
;вызов функции R8DOS
;вх: =0 номер функции
;
	MACRO	R8DOS nFunc
	ld	c,nFunc
	rst	#08
	db	#81
	ENDM

;------------------------------------------------------------------------------
;вызов функции R8FAT
;вх: =0 номер функции
;
	MACRO	R8FAT nFunc
	ld	c,nFunc
	rst	#08
	db	#91
	ENDM

;------------------------------------------------------------------------------
;вызов функции R8DOS
;вх: c - номер функции
;
	MACRO	R8DOSc
	rst	#08
	db	#81
	ENDM

;------------------------------------------------------------------------------
;вызов функции #02 (FileMan) R8CONF
;вх: =#00 - номер функции файл менеджера
;
	MACRO	R8C02FM nFunct
	ld	bc,#100*nFunct+#02
	rst	#08
	db	#8E
	ENDM

;==============================================================================
r8f00_DeinitFAT		equ #00 ;деинициализация переменных раздела FAT
r8f01_InitFAT		equ #01 ;инициализация переменных раздела FAT, если он еще не инициализирован
r8f02_ReadDIR		equ #02 ;чтение секторов текущего каталога
r8f03_SetRoot		equ #03 ;установка корневого каталога текущим
r8f04_FindPath		equ #04 ;поиск файла по заданному пути в текущем каталоге со входом в подкаталоги с проверкой синтаксиса (с установкой найденного каталога текущим)
r8f05_OpenDir		equ #05 ;вход в каталог/выход в родительский каталог

r8f07_FileOpen		equ #07 ;открыть файл для последующих операций с ним
r8f08_FileRead		equ #08	;чтение данных из файла в память
r8f09_FileWrite		equ #09	;запись данных из памяти в файл

r8f0E_CreateFileLFN	equ #0E ;создание файла с длинным именем в текущем каталоге
r8f0F_CreateFileSFN	equ #0F ;создание файла с именем 8+3 в текущем каталоге	в fcb должны быть установлены: fcbName, fcbExt, fcbSize
r8f13_GetPath 		equ #13 ;получение текущего пути
r8f14_GetLFN		equ #14 ;получение длинного имени файла

r8d2D_FindPart		equ #2D ;поиск разделов FAT32 и MFS на текущем винчестере
r8d2E_CngHDD		equ #2E ;смена текущего винчестера

;конец макросов BIOS

files_fat_max equ 8 ;максимальное число открытых файлов fat
files_trd_max equ 8 ;максимальное число открытых файлов trd
fcb_fat_size equ 32 ;размер дискриптора fcb



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
; DE, HL - File size 
; IX - fcb
; fopen:
    ; ; push bc : push hl 
    ; ; call getDefaultDrive
    ; ; pop ix : pop bc
    ; ; esxCall ESX_FOPEN
    ; ; ret
	; ld a,b
	; cp FMODE_READ ;если режим открытие файла
	; jr z,fopen_r
	; cp FMODE_CREATE
	; jr z,fopen_c ;если режим создание файла
	; jp file_error ;иначе выход
	
	
fopen_r	;открытие существующего файла на чтение

	call fopen_prep
	jp 	c,file_error

	ld (file_fat_id_cur),a
	
	;сначала сделаем текущей папку активного приложения
	exx
	ld a,(proc_id_cur)
	call calc_dir_deskr
	ex de,hl
	ld hl,0
    ; hl - адрес пути (=#0000 - путь отсутствует)
    ; de - адрес дескриптора директории/файла	
	R8FAT r8f05_OpenDir	;открыть текущий каталог
	exx
	
	;ld a,(file_fat_id_cur)
	R8FAT r8f07_FileOpen ;открыть
	jp 	c,file_error

	
	jp fopen_ex


fopen_c	;создание нового файла

	call fopen_prep
	jp 	c,file_error


	ld (file_fat_id_cur),a
	
	;сначала сделаем текущей папку активного приложения
	exx
	ld a,(proc_id_cur)
	call calc_dir_deskr
	ex de,hl
	ld hl,0
    ; hl - адрес пути (=#0000 - путь отсутствует)
    ; de - адрес дескриптора директории/файла	
	R8FAT r8f05_OpenDir	;открыть текущий каталог
	exx	
	
	;ld a,(file_fat_id_cur)
	R8FAT	r8f0E_CreateFileLFN	;создание файла
	jp 	c,file_error
	
	jp fopen_ex


fopen_prep ;проверка перед открытием файла
	ld a,(fs_fat_init_flag)
	or a
	scf
	ret z
	
	push hl
	call find_empty_fcb_fat ;какой fcb свободен?
	ex de,hl ;fcb in de
	pop hl
	ret ;выйти с флагом
	

fopen_ex
	;успешно создали/открыли
	push de
	pop ix ;вернуть fcb
	ld hl,fcb_fat_table
	ld a,(file_fat_id_cur)
	ld c,a
	ld b,0
	add hl,bc
	ld a,(proc_id_cur)
	ld (hl),a ;флаг что файл открыт (id текущего процесса)

	;вернуть размер файла
	ld	l,(ix+#14) ;младшие байты длины
	ld	h,(ix+#15)

	ld	e,(ix+#16) ;старшие байты длины
	ld  d,(ix+#17) 	
	
	ld a,(file_fat_id_cur) ;вернуть id
	or a
	ret




init_fs_fat	;инициализация файловой системы
	; ld a,(fs_fat_init_flag) ;если в первый раз
	; or a
	; jr nz,init_fs_fat2
	xor a
	ld (fs_fat_init_flag),a ;сбросить флаг инициализации
	ld a,4 ;номер дисковода по умолчанию E
	ld (fs_drive_number_cur),a
	call GetNumPart ;узнаем какая буква последняя, сколько разделов FAT	
	jr nc,init_fs_fat_prn2
	or a
	jr nz,init_fs_fat_prn2
	ld hl,msg_fat_not_found
	call drvgmx.printZ	
	scf ;ошибка
	ret
	
	
init_fs_fat_prn2	
	;печать списка разделов
	ld hl,msg_fat_found
	call drvgmx.printZ
	ld hl,typeDrive
	ld a,(numDrives)
	ld b,a ;цикл по количеству разделов
	ld c,"E" ;первая буква диска FAT
init_fs_fat_prn1
	push bc
	push hl
	ld a,c ;имя диска
	call drvgmx.putC
	ld a,":" ;
	call drvgmx.putC	
	;тип S или H
	ld a,"H"
	pop hl
	push hl
	bit 3,(hl) ;SD?
	jr z,init_fs_fat_prn3
	ld a,"S"	
init_fs_fat_prn3
	call drvgmx.putC ;первая буква
	ld a,"D"	
	call drvgmx.putC ;вторая буква
	;номер диска
	pop hl
	push hl
	ld a,(hl)
	and %00000100
	rrca
	rrca
	add "0"
	call drvgmx.putC ;номер диска
	;номер раздела
	ld a,","
	call drvgmx.putC ;разделитель
	pop hl
	push hl
	ld a,(hl)
	and %00000011
	add "0"
	call drvgmx.putC ;номер раздела
	ld a,13 ;новая строка
	call drvgmx.putC
	pop hl
	inc hl
	pop bc
	inc c
	djnz init_fs_fat_prn1

	
	;поиск системы и выбор диска
	ld a,(numDrives)
	ld ixl,a ;цикл по количеству разделов
	ld a,(fs_drive_number_cur)
init_fs_fat_find_os_cl
	ld bc,typeDrive-4
	ld l,a
	ld h,0
	add hl,bc
	ld a,(hl) ;получили код раздела из списка

	call init_fs_fat_warm ;выбрать раздел
	ret c
	
	;поиск пути в разделе
	ld	hl,OS_PathFAT		;путь к каталогу системы
	ld	de,dir_fat_deskr ;будет дескриптор системной папки
	xor	a
	dec	a ;установить текущим
	R8FAT	r8f04_FindPath
	jr nc,init_fs_fat_find_os_ok
	
	ld a,(fs_drive_number_cur)	
	inc a
	ld (fs_drive_number_cur),a
	dec ixl
	jr nz,init_fs_fat_find_os_cl
	
	
	;не нашли ОС
    call   file_error_print_dir_not_found ;если не нашли, файл будет в корне	
	scf
	ret
init_fs_fat_find_os_ok
	;нашли раздел с ОС
	ld hl,msg_fat_found_os
	call drvgmx.printZ
	ld a,(fs_drive_number_cur)
	add a,"A"
	call drvgmx.putC
	ld a,13
	call drvgmx.putC
	or a
	ret

	
init_fs_fat_warm	
;переинициализация FAT раздела, когда разделы-диски уже найдены
;вх: a - код раздела
	ld (fs_fat_part_code_cur),a ;запомнить текущий раздел
	xor a
	ld (fs_fat_init_flag),a ;сбросить флаг инициализации
	ld a,(fs_fat_part_code_cur)
	
	; R8FAT	r8f00_DeinitFAT
	; jp 		c,file_error	
	
					   
	R8FAT	r8f01_InitFAT ;инициализация
    jp      nc,init_fs_fat3
	ld hl,msg_fat_init_error
	call drvgmx.printZ
	scf
	ret

init_fs_fat3


;получить текущий путь
	; ld	hl,#4000		;адрес буфера для размещения текущего пути (256 байт)
	; R8FAT	r8f13_GetPath ;получить путь

;init_fs_fat_ex ;выход
	ld a,1
	ld (fs_fat_init_flag),a
	or a
	ret






file_error ;выход с ошибкой
	ld de,0
	ld bc,0 ;длина 0 
	scf ;ошибка
	ret
	
file_error_general_print ;выход с общей ошибкой и сообщением
	ld hl,msg_file_error_general
	call drvgmx.printZ
	scf ;ошибка
	ret	
	
file_error_print_dir_not_found ;выход с ошибкой и сообщением 
	ld hl,msg_dir_not_found
	call drvgmx.printZ
	scf ;ошибка
	ret	
	
file_error_print_file_too_big ;выход с ошибкой и сообщением 
	ld hl,msg_file_too_big
	call drvgmx.printZ
	scf ;ошибка
	ret	
	
file_error_print_file_not_found ;выход с ошибкой и сообщением 
	ld hl,msg_file_not_found
	call drvgmx.printZ
	scf ;ошибка
	ret	

file_error_print_file_open_error ;выход с ошибкой и сообщением 
	ld hl,msg_file_open_error
	call drvgmx.printZ
	scf ;ошибка
	ret	

file_error_print_file_read_error ;выход с ошибкой и сообщением 
	ld hl,msg_file_read_error
	call drvgmx.printZ
	scf ;ошибка
	ret	




; A - file stream id
fclose:
    ;esxCall ESX_FCLOSE
	; push af
; WAITKEY2	XOR A:IN A,(#FE):CPL:AND #1F:JR Z,WAITKEY2
	; pop af
	; cp 2 ;если обычный файл 
	; jp nz,fclose_scl
	
close_fcb_fat ;закрытие fcb файла по номеру 
;вх: a - id файла
	;выход hl - fcb;
	ld hl,fcb_fat
	or a
	jr z,close_fcb_fat_ex
	ld b,a	
	ld de,fcb_fat_size	
close_fcb_fat_cl
	;вычислить адрес fcb
	add hl,de
	djnz close_fcb_fat_cl
close_fcb_fat_ex
	push hl
	ld d,h ;почистить fcb
	ld e,l
	inc de
	ld bc,fcb_fat_size-1
	ld (hl),0
	ldir
	ld hl,fcb_fat_table
	ld c,a
	ld b,0
	add hl,bc
	ld (hl),0 ;и флаг открытия fcb_fat_table
	pop hl
	ret



;закрытие всех файлов процесса
;вх: A - id процесса
fclose_proc_all
	ld hl,fcb_fat_table
	ld b,files_fat_max
	ld c,0 ;id файла
fclose_proc_all_cl
	cp (hl) ;совпадает с id процесса?
	jr nz,fclose_proc_all_skip
	push af
	ld a,c ;id файла
	exx
	call close_fcb_fat ;закрыть
	exx
	pop af
fclose_proc_all_skip
	inc hl
	inc c
	djnz fclose_proc_all_cl
	ret
	
	
	
	
	

; A - file stream id
; DE - length
; HL - buffer
; Returns
;  BC - length(how much was actually read) 
fread: ;(id=1)
    ; push hl : pop ix
    ; esxCall ESX_FREAD

	ld (file_size_tmp),de
	
	call file_check_act ;проверка
	jp c,file_error
	
	ld bc,(file_size_tmp) ;размер	
	ld a,c ;ba - количество байт для чтения
	
	R8FAT r8f08_FileRead	;читать файл
	jp c,file_error

	;ld bc,(file_size_tmp) ;размер
	or a
	ret


; A - file stream id
; DE - length
; HL - buffer
; Returns:
;   BC - actually written bytes
fwrite: ;
    ; push hl : pop ix
    ; esxCall ESX_FWRITE
	
 ;запись файла fat
 	ld (file_size_tmp),de
 
	call file_check_act ;проверка
	jp c,file_error

	ld bc,(file_size_tmp) ;размер	
	ld a,c ;ba - количество байт для записи
	
	R8FAT r8f09_FileWrite	;записать в файл
	jp c,file_error

	;ld bc,(file_size_tmp) ;размер
	or a
	ret
;---------------------------------------

file_check_act
;проверка файла на актуальность
;вых: A - id, DE - fcb
	ld (file_fat_id_cur),a ;сохранить id
	
	ld a,(fs_fat_init_flag)
	or a
	scf
	ret z ;выход если не инициализирована ФС

	push hl
	push bc
	ld a,(file_fat_id_cur)
	call find_fcb_fat ;найти fcb
	ex de,hl ;fcb в de
	push de
	pop ix ;fcb
	pop bc
	ld hl,proc_id_cur ;сравнить с кодом текущего процесса, чтобы имел доступ только к своему файлу
	cp (hl)
	pop hl
	scf
	ret nz	
	
	or a
	scf
	ret z ;выход если файл не открыт


	
	ld a,(fs_fat_part_code_cur) ;сравнить какой раздел у файла и какой активный
	cp (ix+#1f)
	call nz,init_fs_fat_warm ;переинициировать
	ret
	

	
;чтение секторов текущего каталога
; вх:
     ; hl - буфер для чтения
     ; de - относительный номер первого сектора каталога для чтения [0..nn]
     ; b - максимальное количество секторов для чтения
read_dir
	;сначала сделаем текущей папку активного приложения
	exx
	ld a,(proc_id_cur)
	call calc_dir_deskr
	ex de,hl
	ld hl,0
    ; hl - адрес пути (=#0000 - путь отсутствует)
    ; de - адрес дескриптора директории/файла	
	R8FAT r8f05_OpenDir	;открыть текущий каталог
	exx
	
	;теперь запрос
	R8FAT r8f02_ReadDIR	;читать
    ret
	


;вход в каталог/выход в родительский каталог
; вх: hl - адрес пути (=#0000 - путь отсутствует)
; de - адрес дескриптора директории/файла
; вых: a - если путь был указан, новая длина пути
open_dir
	push de ;дескриптор

	R8FAT r8f05_OpenDir	;открыть
	
	;скопировать дескриптор приложения
	push af
	ld a,(proc_id_cur)
	call calc_dir_deskr ;узнать дескриптор
	pop af
	ex de,hl
	pop hl ;дескриптор, отправленный приложеием
	ld bc,32
	ldir
	ret






calc_dir_deskr ;определяет адрес дескриптора каталога
	ld hl,dir_fat_deskr
	or a 
	jr z,calc_dir_deskr_ex ;на выход если 0
	cp proc_max+1
	jr nc,calc_dir_deskr_ex ;защита
	ld de,fcb_fat_size
	ld b,a
calc_dir_deskr_cl
	add hl,de
	djnz calc_dir_deskr_cl
calc_dir_deskr_ex
	ret




; A - file stream id
; DE - position hi
; HL - position low
; Returns:
; 
file_position: ;
;установка/чтение указателя в файле (Переменная +#18-#1b fcb)
	jr c,file_position_set
	;чтение
	call file_check_act ;проверка
	jp c,file_error
	;прочитаем позицию
	ld l,(ix+#18)
	ld h,(ix+#19)
	ld e,(ix+#1a)
	ld d,(ix+#1b)
	or a
	ret	
	
	
file_position_set
	;установка
	push de
	call file_check_act ;проверка
	pop de
	jp c,file_error
	;установим позицию
	ld (ix+#18),l
	ld (ix+#19),h
	ld (ix+#1a),e
	ld (ix+#1b),d
	or a
	ret




; поиск файла или каталога по заданному пути, начиная от корневого, со входом в подкаталоги
;вх:   hl - путь к файлу в формате ASCIZ (не более 250 байт, заканчивается нулем)
;	  формат пути: \[DIR\DIR\..\DIR\]filename.ext
find_path
	;сначала сделаем текущей папку активного приложения
	push af
	push hl
	ld a,(proc_id_cur)
	call calc_dir_deskr
	ex de,hl
	ld hl,0
    ; hl - адрес пути (=#0000 - путь отсутствует)
    ; de - адрес дескриптора директории/файла	
	R8FAT r8f05_OpenDir	;открыть текущий каталог
	
	R8FAT r8f03_SetRoot ;перейти в корень диска
	
	pop hl
	pop af
	;поиск пути в разделе
	; xor	a
	; dec	a ;установить текущим
	R8FAT	r8f04_FindPath

; #04(04) (FindPath) поиск файла по заданному пути в текущем каталоге со входом в
	; подкаталоги с проверкой синтаксиса (с установкой найденного каталога
	; текущим)
; вх:  c=#04(04)
     ; hl - путь к файлу в формате ASCIZ (не более 250 байт, заканчивается нулем)
	  ; формат пути: \[DIR\DIR\..\DIR\]filename.ext
     ; de - адрес буфера (#20 байт) для дескриптора найденного файла/каталога
     ; a=#00/#FF - без установки каталога/с установкой найденного каталога текущим
	 
	ret








; получение длинного имени файла
;вх: hl - адрес буфера для имени
;    de - номер записи в текущем каталоге
;вых: hl - в буфере имя в формате ASCIZ (если длинное имя отсутсвует, то возвращается короткое имя)
; 	a - длина имени, с учетом нуля
get_LFN


	R8FAT r8f14_GetLFN
; #14(20) (GetLFN) получение длинного имени файла
; вх:  c=#14(20)
     ; hl - адрес буфера для имени
     ; de - номер записи в текущем каталоге
; вых: cy=1 ошибка чтения -> a - код ошибки 
     ; hl - в буфере имя в формате ASCIZ (если длинное имя отсутсвует, то
          ; возвращается короткое имя)
     ; a - длина имени, с учетом нуля
     ; de,bc - не определены
	 
	 ret







	
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

; DE - trk/sec
; B - sectors step
; Returns:
; DE - trk/sec	
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
			

;testt db "123.trd"
; write_ima db "Select disk "
; write_ima_d db "A: (E-" ;текущая буква
; write_ima_e	db "D)> " ;последняя буква
		; db 13,10,0
;prev_drive db 0 ;предыдущий номер дисковода
fs_drive_number_cur db 0 ;текущий диск/раздел
		
; ; trdExt1 db ".trd", 0
; ; trdExt2 db ".TRD", 0

; ; sclExt1 db ".scl", 0
; ; sclExt2 db ".SCL", 0

; f_name ds 16 ;имя файла
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
; temp_hl dw 0 ;хранение регистра 
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
;com_file_err_flag db 0 ;общая ошибка




;Раздел SMUC и SD ------------------------------------
	

;список доступных разделов на винчестерах
;7,=0/1 тип раздела MFS/FAT
;6,=1 раздел есть
;3,=0/1 Hdd/SD card
;2,=0/1 для HDD master/slave
;0..1,=?? номер раздела
;
typeDrive	ds 3*4+1
;typeDriveFAT	ds 3*4+1 ;список всех разделов FAT
numDrives db 0 ;количество устройств
;numDrivesFAT db 0 ;количество устройств FAT
next_lett db 0 ;следующая свободная буква диска

;подсчет количества доступных разделов на всех устройствах
;вых: hl,a - количество устройств
;     typeDrives - сформированная таблица
;     cy=1 не обнаружено ни одного устройства
;
GetNumPart
;
	push	de
	push	bc
	ld	hl,typeDrive
	push	hl
	xor	a
	call	proc_01			;HDD master
	ld	a,#01
	call	proc_01			;HDD slave
	ld	a,#02
	call	proc_01			;SD card
	pop	de
	or	a
	sbc	hl,de			;количество разделов на HDD
	IFDEF	useTRD
	 ld	a,l
	 add	a,#04
	 ld	l,a
	ELSE
	 ld	a,l
	ENDIF
	pop	bc
	pop	de
	ld	(numDrives),a
	cp	1
	ret

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;формирование таблицы с доступными разделами на винчестере
;вх:  a =#00 выбрать master
;       =#01 выбрать slave
;       =#02 выбрать SD card
;     hl - адрес в таблице разделов typeDrives
;вых: hl - новый адрес в таблице разделов typeDrives
;
proc_01	ld	c,a
	push	hl
	push	bc
	R8DOS	r8d2E_CngHDD
	jr	c,goto001		;на текущем канале нет винчестера
	R8DOS	r8d2D_FindPart
goto001	pop	bc
	pop	hl
	ret	c			;на текущем винчестере нет разделов
	ld	b,a
	ld	a,c
	add	a,a
	add	a,a
	ld	c,a			;номер винчестера и первого раздела
	ld	a,b
	ld	b,#04
loop001	ld	(hl),#00
	rra
	jr	nc,goto002		;нет раздела
	IFDEF	useMFS
	 ld	(hl),c
	 set	6,(hl)			;=%01???hpp MFS
	 rra
	 jr	nc,goto003		;это MFS
	 set	7,(hl)			;=%11???hpp это FAT
	ELSE
	 rra
	 jr	nc,goto004		;это MFS
	 ld	(hl),c
	 set	6,(hl)			;раздел есть
	 set	7,(hl)			;=%11???hpp это FAT
	ENDIF
goto003	inc	hl
	rla
goto002	rra
goto004	inc	c
	djnz	loop001
	ret



;конец секции SMUC и SD ----------------------------


find_empty_fcb_fat ;поиск свободного fcb для файла
	;выход hl - fcb; a - file_id
	ld hl,fcb_fat_table
	ld c,0 ;номер файла
	ld b,files_fat_max ;цикл
find_empty_fcb_fat_cl	
	ld a,(hl)
	or a
	jr z,find_empty_fcb_fat_ex
	inc hl
	inc c
	djnz find_empty_fcb_fat_cl
	;не нашли свободного
	scf
	ret
find_empty_fcb_fat_ex
	;вычислить адрес fcb
	ld hl,fcb_fat
	inc c
	dec c
	jr z,find_empty_fcb_fat_ex1
	ld de,fcb_fat_size
	ld b,c
find_empty_fcb_fat_cl2	
	add hl,de
	djnz find_empty_fcb_fat_cl2
find_empty_fcb_fat_ex1
	ld a,c ;file-id
	or a
	ret
	

find_fcb_fat ;поиск fcb файла по номеру 
	;вх: a - id файла
	;вых: hl - fcb; a - значение из fcb_fat_table
	ld hl,fcb_fat
	or a
	jr z,find_fcb_fat_ex
	ld b,a	
	ld de,fcb_fat_size	
find_fcb_fat_cl
	;вычислить адрес fcb
	add hl,de
	djnz find_fcb_fat_cl
find_fcb_fat_ex
	push hl
	ld hl,fcb_fat_table	
	ld c,a
	ld b,0
	add hl,bc
	ld a,(hl) ;вернуть флаг
	pop hl
	ret
	
	



file_fat_id_cur db 0 ;текущий файл id
fs_fat_part_code_cur db 0 ;текущий раздел
msg_fat_found db "Found FAT:",13,10,0
msg_fat_found_os db "Found OS on disk: ",0	
msg_fat_not_found db "FAT not found",13,10,0
msg_fat_init_error db "FAT init_error",13,10,0
msg_file_error_general db "File error",13,10,0
msg_file_too_big db "File too_big",13,10,0
msg_file_not_found db "File not found",13,10,0
msg_file_open_error db "File open error",13,10,0
msg_file_read_error db "File read error",13,10,0
msg_dir_not_found db "Directory not found",13,10,0
file_size_tmp dw 0 ;временно

fs_fat_init_flag: db 0 ;флаг инициализации	
OS_PathFAT db "\\OSZ",0 ;папка ОС

	db "fat_dir_descr:" ;дескрипторы открытых папок fat по одной на приложение
dir_fat_deskr ds fcb_fat_size*(proc_max+1)	;дескрипторы папок

	
	db "fat_files_table:"
fcb_fat_table ds files_fat_max ;флаги открытия файлов
fcb_trd_table ds files_trd_max ;флаги открытия файлов

	db "fat_files_fcb:"
fcb_fat ds fcb_fat_size*files_fat_max ;для файлов fat
fcb_trd ds fcb_fat_size*files_trd_max ;для файлов trd



    ENDMODULE