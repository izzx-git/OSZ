set name=artview
..\sjasmplus.exe %name%.asm --lst=%name%.lst
copy %name%.apg ..\..\Release\osz\%name%.apg 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\%name%.apg \osz\%name%.apg
pause
