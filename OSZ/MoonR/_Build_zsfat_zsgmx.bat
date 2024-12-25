..\sjasmplus main.asm -DZW -DZSGMX -DGS -DZSFAT --lst=main.lst -DV=16
copy data\example.pt3 ..\osz\data\example.pt3 
copy data\example.scr ..\osz\data\example.scr
copy data\index.gph ..\osz\data\index.gph
copy data\logo.scr ..\osz\data\logo.scr
copy moonr.com ..\osz\moonr.com 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\osz\data\example.pt3  \osz\data\example.pt3 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\osz\data\example.scr \osz\data\example.scr
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\osz\data\index.gph \osz\data\index.gph
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\osz\data\logo.scr \osz\data\logo.scr
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\osz\moonr.com \osz\moonr.com
pause