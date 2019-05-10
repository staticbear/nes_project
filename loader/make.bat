@echo off

@rem compile C source file with given name into NES file
@rem useful to compile few projects at once without repeating the build script


@PATH=G:\dendy\programming\cc65-win32-2.13.3-1\bin\

@G:\dendy\programming\cc65-win32-2.13.3-1\bin\ca65 crt0.s || goto fail

@G:\dendy\programming\cc65-win32-2.13.3-1\bin\cc65 -Oi main.c --add-source || goto fail

@G:\dendy\programming\cc65-win32-2.13.3-1\bin\ca65 main.s || goto fail

@G:\dendy\programming\cc65-win32-2.13.3-1\bin\ld65 -C nrom_128_horz.cfg -o loader.nes crt0.o main.o runtime.lib || goto fail

@goto exit

:fail

pause

:exit

@del main.s


pause