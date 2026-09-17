@echo off
setlocal EnableExtensions

set "FLUTTER_COMMAND=flutter"
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"

if exist "C:\src\flutter\bin\flutter.bat" (
    set "FLUTTER_COMMAND=C:\src\flutter\bin\flutter.bat"
) else (
    where "%FLUTTER_COMMAND%" >nul 2>&1
    if errorlevel 1 (
        echo [ERREUR] Flutter est introuvable dans le PATH et dans C:\src\flutter.
        echo Installez Flutter ou adaptez FLUTTER_COMMAND dans ce script.
        pause
        exit /b 1
    )
)

if not exist "%ADB_PATH%" (
    echo [AVERTISSEMENT] ADB introuvable : %ADB_PATH%
    echo La compilation peut continuer, mais le transfert USB ne sera pas disponible.
)

echo [1/2] Recuperation des dependances...
call "%FLUTTER_COMMAND%" pub get
if errorlevel 1 (
    echo [ERREUR] flutter pub get a echoue.
    pause
    exit /b 1
)

echo [2/2] Compilation de l'APK release...
call "%FLUTTER_COMMAND%" build apk --release %*
if errorlevel 1 (
    echo [ECHEC] La compilation a echoue.
    exit /b 1
)

echo.
echo [SUCCES] Compilation terminee !
echo APK: build\app\outputs\flutter-apk\app-release.apk
pause
