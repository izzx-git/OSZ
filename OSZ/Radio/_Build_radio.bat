..\sjasmplus.exe radio.asm --lst=radio.lst
copy radio.apg ..\..\Release\osz\radio.apg 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\radio.apg \osz\radio.apg
pause
