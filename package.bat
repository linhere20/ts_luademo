@echo off
set targetPath=target
set luaName=Lua
set tweakName=Plugin
set luaSourcePath=.
set tweakSourcePath=.\tweak

echo clear target folder...
del /Q %targetPath%\*.tar.gz

echo generating %luaName%.tar.gz...
7z a -ttar %targetPath%\%luaName%.tar %luaSourcePath%\*.lua
7z a -tgzip %targetPath%\%luaName%.tar.gz %targetPath%\%luaName%.tar

echo generating %tweakName%.tar.gz...
7z a -ttar %targetPath%\%tweakName%.tar %tweakSourcePath%\*.deb
7z a -tgzip %targetPath%\%tweakName%.tar.gz %targetPath%\%tweakName%.tar

del /Q %targetPath%\*.tar

echo done
pause