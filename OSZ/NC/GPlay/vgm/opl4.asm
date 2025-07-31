WAVEHEADERBUFFERSIZE = MOONRAMWAVETABLESIZE*MOONWAVEHEADERSIZE

opl4writemusiconlyfm1
;skips writes to control registers
;e = register
;d = value
	ld a,e
	cp 0x20
	jp nc,opl4writefm1
	cp 0x08
	ret nz
	jp opl4writefm1

opl4writemusiconlyfm2
;skips writes to control registers
;e = register
;d = value
	ld a,e
	cp 4
    ret c    
	cp 5
	ret z
	jp opl4writefm2

opl4writewavemusiconly
;skips writes to control registers and handles ROM dumps
;e = register
;d = value
	ld a,e
	cp 0x38
	jp nc,opl4writewave
	cp 0x08
	ret c
	cp 0x20
	jr c,writewavetableindexlo
;force wave table index into 384--511 range if ROM data is loaded
isromloaded=$+1
	ld a,0
	or d
	ld d,a
	jp opl4writewave
writewavetableindexlo
	ld a,(isromloaded)
	rrca
	or d
	ld d,a
	call opl4writewave
;wait for the header to load
	ld a,MOON_BASE_HI
	in a,(MOON_STAT)
	and 3
	jr nz,$-4
	ret

vgmopl4init
	xor a
	ld (isromloaded),a
	ld hl,MOONSOUNDROMSIZE%65536
	ld (opl4loadramdatablockheader.romsize0),hl
	ld a,MOONSOUNDROMSIZE/65536
	ld (opl4loadramdatablockheader.romsize2),a
	jp opl4init

sub24x16
;dhl = minuend
;bc = subtrahend
;out: cf=1 if negative result, zf=1 if zero
	sub hl,bc
	jr c,.carry
	ret nz
	ld a,d
	or a
	ret
.carry
	ld a,d
	sbc a,0
	ld d,a
	ret nz
	ld a,l
	or h
	ret

opl4loadromdatablockheader
;dhl = header+data size
;out: zf=1 if no data to load, dhl = data block size, dhl' = start address
	exx
	call memorystreamread4 ;adbc = total rom size
	ld (opl4loadramdatablockheader.romsize0),bc
	ld a,d
	add 0x20 ;place in RAM
	ld (opl4loadramdatablockheader.romsize2),a
	call memorystreamread4 ;adbc = start address
	ld hl,bc
	set 5,d ;place in RAM
	exx
	ld bc,8
	jr sub24x16

opl4loadramdatablockheader
;dhl = header+data size
;out: zf=1 if no data to load, dhl = data block size, dhl' = start address
	exx
	call memorystreamread4 ;adbc = total ram size
	call memorystreamread4 ;adbc = start address
.romsize0=$+1
	ld hl,0
	add hl,bc
.romsize2=$+1
	ld a,0
	adc a,d
	and 0x3f
	ld d,a
	exx
	ld bc,8
	jr sub24x16

setup24bitscounterloop
;dhl = counter
;out: b = inner loop counter, de = outer loop counter
	ld e,l
	ld bc,1
	sub hl,bc
	jr nc,$+3
	dec d
	ld b,e
	ld e,h
	inc de
	ret

opl4loadsample
;dhl = sample start address
;dhl' = sample size
	ld b,d
	ld de,0x0305
	call opl4writefm2
	ld d,b
	call opl4setmemoryaddress
	ld de,0x1102
	call opl4writewave
	opl4_wait
	ld a,6
	push bc
	ld b,MOON_BASE_HI
	ld c,MOON_WREG
	out (c),a
	pop bc
	exx
	call setup24bitscounterloop
	ld hl,(memorystreamcurrentaddr)
.loop
	memory_stream_read_byte c
	opl4_wait
	ld a,c
	push bc
	ld b,MOON_BASE_HI	
	ld c,MOON_WDAT
	out (c),a
	pop bc
	djnz .loop
	dec de
	ld a,e
	or d
	jr nz,.loop
	ld (memorystreamcurrentaddr),hl
	ld de,0x1002
	jp opl4writewave

opl4loadramdatablock
;dhl = data+header size
	call opl4loadramdatablockheader
	ret z
	exx
	jr opl4loadsample

opl4loadromdatablock
;dhl = data+header size
	call opl4loadromdatablockheader
	ret z
	exx
	push de
	call opl4loadsample
	pop af
;check if the address is within the first 64K of RAM
	cp 0x21
	ret nc
;patch all 128 headers that LSI can read from RAM
	ld a,1
	ld (isromloaded),a
	ld hl,MOONSOUNDROMSIZE%65536
	ld d,MOONSOUNDROMSIZE/65536
	ld bc,WAVEHEADERBUFFERSIZE
	ld ix,waveheaderbuffer
	call opl4readmemory
	ld hl,waveheaderbuffer
	ld de,MOONWAVEHEADERSIZE
	ld b,MOONRAMWAVETABLESIZE
.loop
	set 5,(hl) ;set base address in RAM area
	add hl,de
	djnz .loop
	ld hl,MOONSOUNDROMSIZE%65536
	ld d,MOONSOUNDROMSIZE/65536
	ld bc,WAVEHEADERBUFFERSIZE
	ld ix,waveheaderbuffer
	jp opl4writememory

opl4inittimer60hz
	ld de,0x2f02
	call opl4writefm1
	ld de,0x2104
	jp opl4writefm1

opl4waittimer60hz
	ld a,MOON_BASE_HI
	in a,(MOON_STAT)
	rla
	jr nc,opl4waittimer60hz
	ld de,0x8104
	jp opl4writefm1
