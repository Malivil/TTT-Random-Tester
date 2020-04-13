@echo off
set /p changes="Enter Changes: "
"C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmpublish.exe"  update -addon "TTT-Random-Tester.gma" -id "2055633544" -changes "%changes%"
pause