..\sjasmplus.exe GPlay\gp_gzip.asm --lst=gp_gzip.lst
..\sjasmplus.exe nc.asm --lst=nc.lst
copy nc.apg ..\..\Release\osz\nc.apg 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\nc.apg \osz\nc.apg
pause
