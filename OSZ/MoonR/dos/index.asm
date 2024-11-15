    IFDEF ESX
    include "esxdos.asm"
	ENDIF
    IFDEF TRD
    include "trdos.asm"
	ENDIF
    IFDEF ZSFAT
    include "zsfat.asm"
	ENDIF	
    include "console.asm"