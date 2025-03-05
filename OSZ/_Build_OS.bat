copy Sample.trd OS.TRD
rem sjasmplus.exe cmd.asm --lst=cmd.lst
sjasmplus.exe os_main.asm --lst=os_main.lst
copy os.$c osz\os.$c 
copy _Doc\readme.txt osz\ReadMe.txt 
copy OS.TRD osz\OS.TRD 
copy net.apg osz\net.apg 
copy sys.osg osz\sys.osg 
copy autorun.txt osz\autorun.txt
"dmimg.exe" ..\Unreal\wc.img put osz\os.$c \osz\os.$c
"dmimg.exe" ..\Unreal\wc.img put osz\ReadMe.txt \osz\ReadMe.txt
"dmimg.exe" ..\Unreal\wc.img put osz\OS.TRD \osz\OS.TRD 
"dmimg.exe" ..\Unreal\wc.img put osz\net.apg \osz\net.apg 
"dmimg.exe" ..\Unreal\wc.img put osz\sys.osg \osz\sys.osg 
"dmimg.exe" ..\Unreal\wc.img put osz\autorun.txt \osz\autorun.txt
copy OS.TRD ..\Unreal\OS.TRD 
pause
..\Unreal\unreal.exe OS.trd