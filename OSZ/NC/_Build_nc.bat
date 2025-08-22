set name=nc
set name2=gp_gzip
..\sjasmplus.exe GPlay\%name2%.asm --lst=%name2%.lst
..\sjasmplus.exe %name%.asm --lst=%name%.lst
copy %name2%.bin ..\..\Release\osz\%name2%.bin
copy %name%.apg ..\..\Release\osz\%name%.apg 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\%name2%.bin \osz\%name2%.bin
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\%name%.apg \osz\%name%.apg
pause


