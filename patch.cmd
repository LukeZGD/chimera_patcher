@echo off

echo Input file: %1

if "%1" == "" (
    echo Usage: patch.cmd /path/to/input_ipa
    echo Drag the ipa to patch.cmd to produce a patched ipa
    pause >nul
    exit
)

set hash=6fe6517f6ba4b2e826b8a53bcc15c08e231ac672
certutil -hashfile %1 SHA1 > hash
< hash (
    set /p line1=
    set /p hash_local=
)
del hash
if not "%hash_local%" == "%hash%" (
    echo SHA1sum mismatch. Expected %hash%, got %hash_local%
    echo Your copy of the .ipa may be corrupted or incomplete.
    pause >nul
    exit
)

echo Setting up environment
md unpacked

echo Extracting
tar -xf %1 -C unpacked

echo Patching
move "unpacked\Payload\Chimera.app\Chimera" Chimera
bspatch Chimera "unpacked\Payload\Chimera.app\Chimera" Chimera.patch
del Chimera

echo Compressing
move unpacked\Payload Payload
rd /s /q unpacked
tar -acf Chimera-patched.zip Payload
move Chimera-patched.zip Chimera-patched.ipa
rd /s /q Payload

echo Done. Output is Chimera-patched.ipa
pause >nul
