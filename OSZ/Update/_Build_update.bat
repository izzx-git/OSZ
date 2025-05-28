set name=update
..\sjasmplus.exe %name%.asm --lst=%name%.lst
copy %name%.apg ..\..\Release\osz\%name%.apg 
copy %name%.txt ..\..\Release\osz\%name%.txt 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\%name%.apg \osz\%name%.apg
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\%name%.txt \osz\%name%.txt
pause
