@echo off

goto START

:Usage
echo Usage: exportpkgs [DestDir] [Product] [BuildType] [OwnerType]
echo    DestDir........... Required, Destination directory to export
echo    ProductName....... Required, Name of the product to be created.
echo    BuildType......... Required, Retail/Test
echo    OwnerType......... Ignored. Only OEM packages exported

echo    [/?]...................... Displays this usage string.
echo    Example:
echo        exportpkgs C:\Temp SampleA Test
echo        exportpkgs C:\Temp SampleA Retail
echo Run this command only after a successful ffu creation. (See buildimage.cmd)

exit /b 1

:START
if not defined PKGBLD_DIR (
    echo Environment not defined. Call setenv
    exit /b 1
)
REM Input validation
if [%1] == [/?] goto Usage
if [%1] == [-?] goto Usage
if [%1] == [] goto Usage
set WORK_DIR=%1\%BSP_VERSION%

if not exist "%BLD_DIR%\%2\%3" ( goto Usage )
if not defined FFUNAME ( set FFUNAME=Flash)
set OCPNAME=%2_OCP
set OCPCAB=%OCPNAME%_%BSP_VERSION%
set OUTPUT=%WORK_DIR%\%OCPCAB%
if not exist "%BLD_DIR%\%2\%3\%FFUNAME%.ffu" (
    echo. %CLRRED% %BLD_DIR%\%2\%3\%FFUNAME%.ffu not found. Build the image before exporting.%CLREND%
    exit /b 1
)

if not exist "%BLD_DIR%\%2\%3\%FFUNAME%.BSPDB_publish.xml" (
    echo. %FFUNAME%.BSPDB_publish.xml not found. Build the image before exporting.
    exit /b 1
)
if not exist "%OUTPUT%" ( mkdir "%OUTPUT%" )
setlocal

powershell -executionpolicy unrestricted  -Command ("%TOOLS_DIR%\ExportBSPDB.ps1 %BLD_DIR%\%2\%3 %OUTPUT%")

echo. Making BSP DB cab
call makecab %OUTPUT%\%FFUNAME%.BSPDB.xml %OUTPUT%\%FFUNAME%.BSPDB.xml.cab >nul
echo. Signing BSP DB cab
call sign.cmd %OUTPUT%\%FFUNAME%.BSPDB.xml.cab >nul
del %OUTPUT%\%FFUNAME%.BSPDB.xml
cd /D %WORK_DIR%
echo. Making %OCPCAB%.cab
dir /s /b /a-d %OCPCAB% > files.txt
makecab /d "CabinetName1=%OCPCAB%.cab" /d DiskDirectoryTemplate=. /d InfFileName=NUL /d RptFileName=NUL /d MaxDiskSize=0 /f files.txt
del /q /f files.txt
echo. Signing %OCPCAB%.cab
call sign.cmd %OCPCAB%.cab >nul
endlocal
exit /b

