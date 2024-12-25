    MODULE Fetcher

fetchFromNet:
    call Gopher.makeRequest : jr c, .error
    call Gopher.loadBuffer
    jp MediaProcessor.processResource
.error
	OS_ESP_CLOSE ;закрыть соединение, если было
    ld hl, .err : call DialogBox.msgBox 
    jp History.back
    
.err db "Document fetch error! Check your connection or hostname!", 0


fetchFromFS:
    call UrlEncoder.extractPath
loadFile
    ld hl, nameBuffer
    call Dos.loadBuffer
    jp MediaProcessor.processResource
    ENDMODULE