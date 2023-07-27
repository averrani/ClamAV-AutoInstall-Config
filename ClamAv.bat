@echo off
echo -----------------------------------------------------------
echo Starting ClamAv installation and configuration script
echo -----------------------------------------------------------

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

rem Copy file from Custom repository to Program Files
rem set "SourceFolder=\\10.243.100.203\data-deploy-script-lgc\ClamAV"
set SourceFolder=\\10.243.100.203\data-deploy-script-lgc\ClamAV
set DestinationFolder=C:\ClamAV

if not exist "C:\ClamAV" (
    echo Création du dossier "%DestinationFolder%"...
    mkdir "C:\ClamAV"
    xcopy %SourceFolder% %DestinationFolder%\ /E /I /Y 
    
    if %errorlevel% equ 0 (
        echo Copied successfully.
    ) else (
        echo Error occurred while copying.
    )
) 

rem Executing Freshclam
start "" "%DestinationFolder%\freshclam.exe"

rem Adding quarantine folder
mkdir "C:\quarantine"

rem adding cronjob for antivirus checking 
rem schtasks /create /sc hourly /mo 10 /tn "ClamScanTask" /tr "\"%DestinationFolder%\clamscan.exe\" -r --bell -i \"C:\Users\" --move=\"C:\quarantine\\\" --exclude-dir=\"C:\quarantine\\\" -l \"C:\clamav.log\""

set TaskName=ClamScanTask
set TaskCommand="%DestinationFolder%\clamscan.exe -r --bell -i \"C:\Users\" --move=\"C:\quarantine\\\" --exclude-dir=\"C:\quarantine\\\" -l \"C:\clamav.log\""

schtasks /query /tn "%TaskName%" > nul 2>&1
if %errorlevel% equ 0 (
    echo "%TaskName%" already exists.
) else (
    echo Creating "%TaskName%"...
    schtasks /create /sc hourly /mo 10 /tn "%TaskName%" /tr %TaskCommand%
    echo Created successfully.
)