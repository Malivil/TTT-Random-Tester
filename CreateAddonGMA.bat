"C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder %1
echo Removing old file
del TTT-Random-Tester.gma
echo Renaming file
ren %1.gma TTT-Random-Tester.gma
pause