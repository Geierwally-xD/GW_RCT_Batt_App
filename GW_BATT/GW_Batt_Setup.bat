@REM Installation of RCT-Batt App V2.3.5 on Jeti Transmitters
@echo off
@echo ================================
@echo connection  transmitter
@echo ================================
@echo connect your transmitter USB and type in the drive letter e.g. E
@Set /P transmitter=SET transmitter:
@echo ================================
IF not exist %transmitter%:\Model\*.* goto FAILPATH
IF not exist %transmitter%:\apps\*.* goto FAILLUA
@echo ================================
@echo Partial transmitter backup required ?
@echo ================================
@echo If partial backup should be done, type in Y or J 
@Set /P backup=SET backup:
IF "%backup%"=="Y" goto PARTIAL
IF "%backup%"=="y" goto PARTIAL
IF "%backup%"=="J" goto PARTIAL
IF "%backup%"=="j" goto PARTIAL
goto INSTAL

:PARTIAL
@echo ================================
@echo generating partial backup of transmitter, pleas wait
@echo ================================
set "backupFolder=%date%_partial"
IF exist %backupFolder% rd %backupFolder% /S /Q
md %backupFolder%
IF not exist %backupFolder% goto FAILPATH_BACK 
cd %backupFolder%
md Apps
cd ..
XCOPY /S %transmitter%:\Apps %backupFolder%\Apps  
cd %backupFolder%
md Audio
cd ..
XCOPY /S %transmitter%:\Audio %backupFolder%\Audio 
cd %backupFolder%
md Model
cd ..
XCOPY /S %transmitter%:\Model %backupFolder%\Model 
@echo ================================
@echo partial transmitter backup successful finished
@echo ================================

:INSTAL
@echo delete old files on transmitter please wait
rd %transmitter%:\apps\GW_BATT /S /Q && md %transmitter%:\apps\GW_BATT
rd %transmitter%:\apps\RCT_BATT /S /Q
del %transmitter%:\apps\RCT-Batt.*
del %transmitter%:\apps\lang\RCT-Batt.*
del %transmitter%:\apps\GW_Batt.*
del %transmitter%:\apps\lang\GW_Batt.*
@echo ================================
@echo copy new files to transmitter please wait
IF not exist apps\*.* goto FAILPATH_UPD
setlocal
%transmitter%:
cd apps
md GW_BATT
endlocal
XCOPY /S apps\GW_BATT %transmitter%:\apps\GW_BATT
copy apps\GW_Batt.lc %transmitter%:\apps

@echo ================================
@echo installation successful finished
@echo ================================
goto END
:FAILLUA
@echo Installation failed, missing Lua API. Pls. instal Lua API (download Lua update for your transmitter from jetimodel.com )
goto END
:FAILPATH
@echo Installation failed transmitter is not connected or drive letter for transmitter is not correct
goto END
:FAILPATH_UPD
@echo Installation failed the apps folder does not exist.
goto END

:END
@PAUSE

