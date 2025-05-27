..\sjasmplus main.asm -DZW -DZSGMX -DGS -DZSFAT --lst=main.lst -DV=16
copy data\example.pt3 ..\..\Release\osz\data\example.pt3 
copy data\example.scr ..\..\Release\osz\data\example.scr
copy data\index.gph ..\..\Release\osz\data\index.gph
copy data\logo.scr ..\..\Release\osz\data\logo.scr
copy moonr.apg ..\..\Release\osz\moonr.apg 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\data\example.pt3  \osz\data\example.pt3 
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\data\example.scr \osz\data\example.scr
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\data\index.gph \osz\data\index.gph
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\data\logo.scr \osz\data\logo.scr
..\"dmimg.exe" ..\..\Unreal\wc.img put ..\..\Release\osz\moonr.apg \osz\moonr.apg
pause