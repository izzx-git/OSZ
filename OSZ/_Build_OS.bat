copy Sample.trd OS.TRD
rem sjasmplus.exe cmd.asm --lst=cmd.lst
sjasmplus.exe os_main.asm --lst=os_main.lst
copy os.$c ..\Release\osz\os.$c 
copy _Doc\readme.txt ..\Release\osz\ReadMe.txt 
copy OS.TRD ..\Release\osz\OS.TRD 
copy net.apg ..\Release\osz\net.apg 
copy sys.osg ..\Release\osz\sys.osg 
copy autorun.txt ..\Release\osz\autorun.txt
"dmimg.exe" ..\Unreal\wc.img put ..\Release\osz\os.$c \osz\os.$c
"dmimg.exe" ..\Unreal\wc.img put ..\Release\osz\ReadMe.txt \osz\ReadMe.txt
"dmimg.exe" ..\Unreal\wc.img put ..\Release\osz\OS.TRD \osz\OS.TRD 
"dmimg.exe" ..\Unreal\wc.img put ..\Release\osz\net.apg \osz\net.apg 
"dmimg.exe" ..\Unreal\wc.img put ..\Release\osz\sys.osg \osz\sys.osg 
"dmimg.exe" ..\Unreal\wc.img put ..\Release\osz\autorun.txt \osz\autorun.txt
copy OS.TRD ..\Unreal\OS.TRD 
pause
..\Unreal\unreal.exe OS.trd