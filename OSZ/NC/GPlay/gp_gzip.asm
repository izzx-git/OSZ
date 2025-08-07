;тут часть плеера для распаковки zip в режиме моно
   device ZXSPECTRUM128
	include "../os_defs.asm"  
	org #4000
	
	macro memory_stream_write_byte src
	bit 6,h
	call nz,memorystreamnextpage
	ld (hl),src
	inc hl
	endm

start_gp_gzip
	xor a
	ld (memorystreampagecount),a ;количество занятых страниц памяти
	ld a,255
	ld (filehandle),a
	; ld (page8000),a ;переменная доп страница
	ld de,file_name
	ld bc,256
	ldir ;перенести имя файла
	
	;ld (file_name),hl
	ld hl,msg_unzip ;сообщение распаковка
	OS_PRINTZ ;печать

	;узнать свои страницы
	OS_GET_MAIN_PAGES ;вых: b, c - страницы в слотах 2, 3
	;jr c,get_page_error
	ld (page_main),bc ;тут страницы от командера
	ld a,c
	ld (pageC000),a ;верхняя страница для буфера unzip , там уже временная



	OS_GET_PAGE ;получить лишнюю страницу
	jr nc,get_page_ok
	
get_page_error
	ld a,color_error ;цвет ошибки
	ld b,#c
	OS_SET_COLOR
	ld hl,msg_mem_err ;нет памяти
	OS_PRINTZ ;печать
	ld a,color_backgr ;цвет основной
	ld b,#c
	OS_SET_COLOR	
	
	jr gp_gzip_ex_err
	
get_page_ok
	ld (page8000),a ;запомнить доп страницу, нижняя для буфера unzip 
	
	OS_GET_PAGE ;получить лишнюю страницу для подгрузки файла
	jr c,get_page_error
	ld (filedatapage),a

	ld a,(page8000)
	OS_SET_PAGE_SLOT2 ;здесь будет буфер upzip
	ld hl,file_name
	;di
	call decompressfiletomemorystream ;распаковать
	;ei
	jr c,gp_gzip_ex_err
	jr gp_gzip_ex_ok
	
gp_gzip_ex_err
	call gp_gzip_return_page
	ld a,(memorystreampagecount) ;количество занятых страниц памяти
	ld hl,memorystreampages ;адрес таблицы памяти
	scf ;ошибка
	ret



gp_gzip_ex_ok
	ld hl,msg_ok
	OS_PRINTZ
	call gp_gzip_return_page
	xor a ;нет ошибок
	ld a,(memorystreampagecount) ;количество занятых страниц памяти
	ld hl,memorystreampages ;адрес таблицы памяти
	ret
	
gp_gzip_return_page
	;вернуть страницы
	ld a,(page_main)
	OS_SET_PAGE_SLOT3
	ld a,(page_main+1)
	OS_SET_PAGE_SLOT2
	;освободить страницу
	ld a,(page8000)
	OS_DEL_PAGE
	ld a,(filedatapage)
	OS_DEL_PAGE
	ret



fileopenerror
	ld a,(filehandle)
	OS_FILE_CLOSE
	
	ld a,color_error ;цвет ошибки
	ld b,#c
	OS_SET_COLOR
	ld hl,msg_file_error
	OS_PRINTZ
	ld a,color_backgr ;цвет основной
	ld b,#c
	OS_SET_COLOR
	jr gp_gzip_ex_err


	
decompressfiletomemorystream
;de = input file name
;out: zf=1 is successful, zf=0 otherwise
	;call openstream_file
	OS_FILE_OPEN ;HL - File name (out: A - id file, de bc - size, IX - fcb)
		
    ;or a
    ;jp nz,fileopenerror
	jp c,fileopenerror	
	ld (filehandle),a
		
	; or a
	; ret nz
;read the last 4 bytes containing decompressed file size
;	ld a,(filehandle)
	;ld b,a
	;OS_GETFILESIZE ;b=handle, out: dehl=file size
	;размер мы уже знаем в de bc, надо положить в de hl
	ld h,b
	ld l,c
	
	ld bc,4
	sub hl,bc
	jr nc,$+3
	dec de
	ld a,(filehandle)
	;ld b,a
	;OS_SEEKHANDLE ;b=file handle, dehl=offset
	
	scf
	OS_FILE_POSITION ;на конец файла - 4
	jp c,fileopenerror	
;вх: CY = 1 - установка; CY = 0 - чтение
;вх: A - id файла
;вх: de, hl - значения старшие быйты, младшие
;вых: de, hl - значения старшие быйты, младшие
	
	ld hl,memorystreamsize
	ld de,4
	;call readstream_file ;de=buf ;hl=size
	ld a,(filehandle)
	OS_FILE_READ ;HL - address, A - id file, DE - length (out: hl - следующий адрес для чтения)
	jp c,fileopenerror	
	
	ld a,(filehandle)
	;ld b,a
	ld hl,0 ;обратно на начало файла
	ld de,hl
	;OS_SEEKHANDLE
	scf
	OS_FILE_POSITION
	jp c,fileopenerror	
	
	
;allocate memory
	ld hl,(memorystreamsize+0)
	ld de,(memorystreamsize+2)
	call memorystreamallocate
	jr nz,closefilewitherror
	call memorystreamstart
	
	ld a,(memorystreampages)
	ld (memorystreamcurrentpage),a ;первая страница для распакованного
;decompress
	call setsharedpages
	ld hl,0xffff
	ld (filedatasourceaddr),hl
	ld (savedSP),sp
	call GzipExtract
	;call closestream_file
	ld a,(filehandle)
	OS_FILE_CLOSE
	xor a
	ret

GzipThrowException
savedSP=$+1
	ld sp,0
GzipExitWithError
	call memorystreamfree
closefilewitherror
	;call closestream_file
	ld a,(filehandle)
	OS_FILE_CLOSE	
	
	ld a,color_error ;цвет ошибки
	ld b,#c
	OS_SET_COLOR
	ld hl,msg_mem_err
	OS_PRINTZ
	ld a,color_backgr ;цвет основной
	ld b,#c
	OS_SET_COLOR	
	
	;or 1
	scf ;ошибка
	ret

setsharedpages
page8000=$+1
	ld a,0
	;SETPG8000
	call OS_SET_PAGE_SLOT2_self
	
pageC000=$+1
	ld a,0
	;SETPGC000
	call OS_SET_PAGE_SLOT3_self
	ret

GzipReadInputBuffer
;de = InputBuffer
;hl = InputBufSize
filedatapage=$+1
	ld a,0
	;SETPG8000
	call OS_SET_PAGE_SLOT2_self
filedatasourceaddr=$+1
	ld hl,0
	bit 6,h
	call nz,loadfiledata
	ld bc,InputBufSize
	ldir
	ld (filedatasourceaddr),hl
	ld a,(page8000)
	;SETPG8000
	call OS_SET_PAGE_SLOT2_self
	ret

loadfiledata
	exx
	ex af,af'
	push af,bc,de,hl,ix,iy
	ld hl,0x8000
	ld de,0x4000
	;call readstream_file ;de=buf ;hl=size
	ld a,(filehandle)
	OS_FILE_READ ;HL - address, A - id file, DE - length (out: hl - следующий адрес для чтения)
	jr c,GzipThrowException
	
	pop iy,ix,hl,de,bc,af
	exx
	ex af,af'
	ld hl,0x8000
	ld de,InputBuffer
	ret

GzipWriteOutputBuffer
;de = OutputBuffer
;hl = size
	ld a,(memorystreamcurrentpage)
	;SETPG8000
	call OS_SET_PAGE_SLOT2_self
	ld bc,hl
	add hl,de
	bit 7,h
	jr z,.below8000
	push hl
	ld bc,0x8000-OutputBuffer
	call memorystreamwrite
	pop hl
	res 7,h
	push hl
	ld de,0x4000
	sub hl,de
	ld a,(page8000)
	jr c,.write8000
	jr z,.write8000
	ex (sp),hl
	;SETPGC000
	call OS_SET_PAGE_SLOT3_self
	ld de,0xc000
	ld bc,0x4000
	call memorystreamwrite
	ld a,(pageC000)
.write8000
	;SETPGC000
	call OS_SET_PAGE_SLOT3_self
	ld de,0xc000
	pop bc
.below8000
	call memorystreamwrite
	jp setsharedpages	
	
	
memorystreamallocate
;dehl = buffer size
;out: zf=1 if successful, zf=0 otherwise
	ld (memorystreamsize+0),hl
	ld (memorystreamsize+2),de
	ld a,e
	ld de,0x3fff
	add hl,de
	ld c,0
	adc a,c
	sla h
	rla
	sla h
	rla
	ld b,a
	ld a,MEMORYSTREAMMAXPAGES
	cp b
	ret c
	ld hl,memorystreampages
.loop
	push bc
	push hl
	;OS_NEWPAGE ;out: a=0 (OK)/!=0 (fail), e=page
	OS_GET_PAGE
	pop hl
	pop bc
	;or a
	jr nc,.pageallocated
	ld a,c
	ld (memorystreampagecount),a
	jp memorystreamfree

.pageallocated
	ld (hl),a
	inc hl
	inc c
	djnz .loop
	ld a,c
	ld (memorystreampagecount),a
	xor a
	ret

memorystreamfree ;страницы освободятся в другой части плеера
;out: zf=0 so that this function can be used to return error condition
memorystreampagecount=$+1
	ld a,0
	or a
	ret z
	; ld b,a
	; ld hl,memorystreampages
; .pagefreeloop
	; push bc
	; push hl
	; ld a,(hl)
	; ;OS_DELPAGE ;e=page ;GIVE SOME PAGE BACK TO THE OS
	; OS_DEL_PAGE ;вх: a - номер страницы
	; pop hl
	; pop bc
	; inc hl
	; djnz .pagefreeloop
	; inc b
	xor a ;zf=1
	ret

memorystreamstart
	ld hl,0xffff
	ld (memorystreamcurrentaddr),hl
	ld hl,memorystreampages
	ld (memorystreampageaddr),hl
	ret


memorystreamnextpage
memorystreampageaddr=$+1
	ld hl,0
	push af
	ld a,(hl)
	inc hl
	ld (memorystreamcurrentpage),a
	ld (memorystreampageaddr),hl
	push bc
	;SETPG8000
	call OS_SET_PAGE_SLOT2_self
	pop bc
	pop af
	ld hl,0x8000
	ret
	
	
memorystreamwrite
;bc = number of bytes
;de = src addr
	ld a,c
	dec bc
	inc b
	ld c,b
	ld b,a
	ld hl,(memorystreamcurrentaddr)
.writeloop
	ld a,(de)
	memory_stream_write_byte a
	inc de
	djnz .writeloop
	dec c
	jr nz,.writeloop
	ld (memorystreamcurrentaddr),hl
	ret	
	
	
OS_SET_PAGE_SLOT2_self	;вызов ОС с сохранением регистров кроме af
	push bc,de,hl
	exx
	ex af,af'
	push af,bc,de,hl,ix,iy
	ex af,af'
	OS_SET_PAGE_SLOT2
	ex af,af'
	pop iy,ix,hl,de,bc,af
	exx
	ex af,af'
	pop hl,de,bc
	ret
	
OS_SET_PAGE_SLOT3_self	;вызов ОС с сохранением регистров кроме af
	push bc,de,hl
	exx
	ex af,af'
	push af,bc,de,hl,ix,iy
	ex af,af'
	OS_SET_PAGE_SLOT3
	ex af,af'
	pop iy,ix,hl,de,bc,af
	exx
	ex af,af'
	pop hl,de,bc
	ret	
	
	
MEMORYSTREAMMAXPAGES = 128


color_backgr equ 1*8+7 ;цвет фона
color_error equ 1*8+2 ;цвет ошибки
	
page_main dw 0 ;временно страницы	
;page_ext02 db 0 ;временная страница для слота 2
filehandle db 0 ;временно
memorystreamcurrentaddr dw 0;
memorystreamcurrentpage db 0 ;

msg_mem_err
	db "Get memory error",13,0	
msg_file_error
	db "File error",13,0
msg_unzip db "Unzip...",0
msg_ok db "OK",0	
	
	
	
	
	
	
	
	
	include "GPlay/common/gunzip.asm"
end_gp_gzip

	savebin "gp_gzip.bin",start_gp_gzip,$-start_gp_gzip

;ниже не включается в файл

memorystreampages
	ds MEMORYSTREAMMAXPAGES
memorystreamsize
	ds 4
	
GzipBuffersStart = $

file_name ds 256 ;временно имя
	

