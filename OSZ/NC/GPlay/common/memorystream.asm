memorystreamstart
        IF AREA_C000_FFFF=1
	ld hl,0x0000
        ELSE
        ld hl,0xffff
        ENDIF
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
        IF AREA_C000_FFFF=1
	;SETPGC000
	OS_SET_PAGE_SLOT3
	pop bc
	pop af
	ld hl,0xC000
        ELSE
        SETPG8000
        pop bc
        pop af
        ld hl,0x8000
        ENDIF
	ret

memorystreamskip
;b = byte count
	ld hl,(memorystreamcurrentaddr)
.loop
	bit 6,h
        IF AREA_C000_FFFF=1
	call z,memorystreamnextpage   
        ELSE
 	call nz,memorystreamnextpage
        ENDIF
	inc hl
	djnz .loop
	ld (memorystreamcurrentaddr),hl
	ret

	macro memory_stream_write_byte src
	bit 6,h
        IF AREA_C000_FFFF=1
	call z,memorystreamnextpage   
        ELSE
 	call nz,memorystreamnextpage
        ENDIF
	ld (hl),src
	inc hl
	endm

	macro memory_stream_read_byte dest
	bit 6,h
        IF AREA_C000_FFFF=1
	call z,memorystreamnextpage   
        ELSE
 	call nz,memorystreamnextpage
        ENDIF
	ld dest,(hl)
	inc hl
	endm

	macro memory_stream_read_1 dst
	ld hl,(memorystreamcurrentaddr)
	memory_stream_read_byte dst
	ld (memorystreamcurrentaddr),hl
	endm

	macro memory_stream_read_2 dst1,dst2
	ld hl,(memorystreamcurrentaddr)
	memory_stream_read_byte dst1
	memory_stream_read_byte dst2
	ld (memorystreamcurrentaddr),hl
	endm

	macro memory_stream_read_3 dst1,dst2,dst3
	ld hl,(memorystreamcurrentaddr)
	memory_stream_read_byte dst1
	memory_stream_read_byte dst2
	memory_stream_read_byte dst3
	ld (memorystreamcurrentaddr),hl
	endm

memorystreamread1
;out: a = byte
	memory_stream_read_1 a
	ret

memorystreamread2
;out: de = word
	memory_stream_read_2 e,d
	ret

memorystreamread3
;out: c = byte0, e = byte1, d = byte2
	memory_stream_read_3 c,e,d
	ret

memorystreamread4
;out: adbc = dword
memorystreamcurrentaddr=$+1
	ld hl,0
	memory_stream_read_byte c
	memory_stream_read_byte b
	memory_stream_read_byte d
	memory_stream_read_byte a
	ld (memorystreamcurrentaddr),hl
	ret

memorystreamread
;bc = number of bytes
;de = dest addr
	ld a,c
	dec bc
	inc b
	ld c,b
	ld b,a
	ld hl,(memorystreamcurrentaddr)
.readloop
	memory_stream_read_byte a
	ld (de),a
	inc de
	djnz .readloop
	dec c
	jr nz,.readloop
	ld (memorystreamcurrentaddr),hl
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

memorystreamseek
;dehl = absolute position
;out: hl = read address
	ld a,e
	ld b,h
	sla b
	rla
	sla b
	rla
	add a,memorystreampages%256
	ld e,a
	adc a,memorystreampages/256
	sub e
	ld d,a
	ld a,(de)
	ld (memorystreamcurrentpage),a
	inc de
	ld (memorystreampageaddr),de
        IF AREA_C000_FFFF=1
	;SETPGC000
	push hl ;*
	OS_SET_PAGE_SLOT3	
	pop hl ;*
        set 6,h
        ELSE
	SETPG8000
	res 6,h
        ENDIF
	set 7,h
	ld (memorystreamcurrentaddr),hl
	ret

memorystreamgetpos
;out: dehl = absolute position
	ld hl,(memorystreampageaddr)
	ld de,-memorystreampages-1
	add hl,de
	ex de,hl
	ld hl,(memorystreamcurrentaddr)

        IF AREA_C000_FFFF=1
        bit 7,h
        res 7,h
        res 6,h
	jr nz,$+6
        ELSE
	res 7,h
	bit 6,h
;	jr z,$+6
        ENDIF
	jr nz,$+6
	inc de                            
	ld hl,0                              
	xor a                                 
	rr e
	rra
	rr e
	rra
	or h
	ld h,a
	ret

memorystreamsize
	ds 4
