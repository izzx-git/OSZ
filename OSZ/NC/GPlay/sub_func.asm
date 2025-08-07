		
fileopenerror
		ld a,c
		ld c,$FF
        ld (bc),a ;запомнить сколько заняли страниц
		
		ld hl,txt_fopenerror
		OS_PRINTZ
		
		ld a,(file_id_cur_r)
		cp 255
		jr z,fileopenerror1
		OS_FILE_CLOSE ;A - id file
fileopenerror1
		scf ;ошибка
		ret


; memoryerror
        ; OS_CLOSEHANDLE
        ; ld e,6+0x80
        ; OS_SETGFX
        ; ld e,0
        ; OS_CLS
        ; ld hl,txt_memoryerror
        ; call print_hl
        ; YIELDGETKEYLOOP
        ; jp cmd_quit
		
memoryerror
		ld a,c
		ld c,$FF
        ld (bc),a ;запомнить сколько заняли страниц
		
		ld hl,txt_memoryerror
		OS_PRINTZ
		
		ld a,(file_id_cur_r)
		cp 255
		jr z,memoryerror1
		OS_FILE_CLOSE ;A - id file
memoryerror1
		scf ;ошибка
		ret

    

;----------------------------------------        
load_mus

        ; ld b,0
; old_mus EQU $-1
        ; cp b
        ; ret z
        ; ld (old_mus),a

        ; and a
        ; jp z,no_mus

        
        ; call calc_mus

        ; call no_mus
        ; ld hl,t_s98_file00_pages_list+$FF 
        ; call free_s98_file ;освободить страницы
        
        ;generate path to music file in 'buf'
        ; ld hl,mus_path1
        ; ld de,buf
        ; call copystr_hlde ;'copy path  'mus/' '
        
        ; ld a,(mus_mode)
        ; ld hl,mus_modes
        ; call sel_word
        ; call copystr_hlde ;copy "aym / s98 path"
        ; ld hl,mus_path2
        ; call copystr_hlde ;copy name without ext
        
        ; ld a,(mus_mode)
        ; ld hl,plr_ext
        ; call sel_word
        ; call copystr_hlde  ;copy file ext
        ; xor a
        ; ld (de),a  ;string terminator

        ; ld de,buf ;имя файла
        ; call openstream_file
		
		ld hl,file_name_cur
		OS_FILE_OPEN ;HL - File name (out: A - id file, bc, de - size, IX - fcb)
		
        ;or a
        ;jp nz,fileopenerror
		jp c,fileopenerror	
		ld (file_id_cur_r),a

        ld hl,memorystreampages ;t_s98_file00_pages_list
        ld (load_s98_file_number),hl


/////------        call load_s98_file      ;de=drive/path/file

; загружаем файл в память
; и создаем таблицу

                ;заполняем таблицу страниц файла
                
                
load_s98_file_number_haddr = $+2 :
load_s98_file_number = $+1 :
                ld bc,memorystreampages ;t_s98_file00_pages_list
                push bc
                                
read_file_loop:
                ;OS_NEWPAGE              ;out: a=0 (OK)/!=0 (fail), e=page
				OS_GET_PAGE ;*
                
                pop bc ;file tab
                                
                ;or a
                ;jp nz,memory_error
				jp c,memory_error
                ;ld a,e
                                        ;НУЖНО СЧИТАТЬ КОЛИЧЕСТВО СТРАНИЦ !!!!
                                        ;ЧТОБЫ ПОТОМ ОСВОБОЖДАТЬ ТАБЛИЦУ !!!!

1               ld (bc),a
                inc c           ;теперь нет проверки на файлы больше 4М !!!!!
                        
                push bc ;file tab
                ;SETPGC000
				OS_SET_PAGE_SLOT3
        
                ;ld de,$C000
                ;ld hl,$4000
        
                ;call readstream_file    ;DE = Buffer address, HL = Number of bytes to read
                                ;hl=actual size
				
				ld a,(file_id_cur_r)			
				ld hl,$C000
                ld de,$4000
				OS_FILE_READ ;HL - address, A - id file, DE - length (out: hl - следующий адрес для чтения)
				jr nc,read_file_loop1 
				
				;ошибка чтения
                pop bc ;file tab
                jp fileopenerror
				
				
read_file_loop1		;продолжить		
                ld a,h
                ; cp $40
                ; jr nc,read_file_loop    ;>= $40
				cp $c0
                jr c,read_file_loop    ;>= $c0, значит остаток файла

        
read_file_exit

                pop bc ;file tab
                ;тут можно достать количество страниц
                ld a,c

               // sub 16   ; !!!!! помним что счётчик расроркается не с 0 а с+16

                ld c,$FF
                ld (bc),a
                                
;-------------------------------------------------------
; загрузили все куски музыки.
;теперь нужно  скопировать првый банк в plr_page3 и прести инициаоищацию плеера
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                ;call closestream_file
				ld a,(file_id_cur_r)
				OS_FILE_CLOSE ;A - id file

read_file_ok
                ;call store8000c000 ;*
;подключаем в 8000  пераую страницу загруженной музыки
                ld hl,memorystreampages ;t_s98_file00_pages_list
                ld a,(hl)
                ;SETPG8000
				OS_SET_PAGE_SLOT3 
                ; ld a,(plr_page3)
                ; SETPGC000

;копируем эту страницу в plr_page3. Это нужно для начальной инициализации трека.
                ; ld hl,0x8000
                ; ld de,module
                ; ld bc,16384
                ; ldir

; в  plrpage  помещаем список страниц с музыкой. 
                ; ld a,(plr_page)
                ; SETPGC000
                ; ld hl,t_s98_file00_pages_list
                ; ld de,0xc100         ;0x5000
                ; ld bc,256
                ; ldir

         ;       DI

;инициалbизируем музыку. 
                ;call restore8000c000

                ;call set_music_pages

                ld hl,module
                ;ld (0x4001),hl * адрес модуля для инициализации
				ld (START+1),hl 
                call PLR_INIT        ;init music

          ;      EI
;----------------
;eloop           halt ;YIELD
;                call PLR_PLAY
;                jr eloop
;----------------


;!!!!!!!!!!

;запускаем плеер. 
                ;ld a,(plr_page)
                ld hl,PLR_PLAY
                ;OS_SETMUSIC         ;**** тут установить обработчик на плеер
				OS_SET_INTER
				xor a ;OK
				ret
                ;jp unset_music_pages
                

memory_error: 
        jp memoryerror
