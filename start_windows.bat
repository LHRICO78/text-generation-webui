@echo off
setlocal enabledelayedexpansion

cd /D "%~dp0"

set PATH=%PATH%;%SystemRoot%\system32

if not defined "CD" (
    echo Ce script dépend de Miniconda qui ne peut être installé en mode silencieux sous un chemin contenant des espaces. && goto end
)

@rem Vérification des caractères spéciaux dans le chemin d'installation
set SPCHARMESSAGE="PRECAUTION: Des caractères spéciaux ont été détectés dans le chemin d'installation! Cela peut causer l'échec de l'installation!" "         Veuillez vérifier et retirer les caractères spéciaux si nécessaire."
if "%CD%"| findstr /R /C:"[!#$%&()*+,;<=>?@\[\]\^`{|}~]" >nul 2>&1 (
    call :PrintBigMessage %SPCHARMESSAGE%
)
set SPCHARMESSAGE=

@rem correction de l'installation échouée lors de l'installation sur un disque séparé
set TMP=%cd%\installer_files
set TEMP=%cd%\installer_files

@rem désactiver les environnements Conda existants si nécessaire pour éviter les conflits
(call conda deactivate && call conda deactivate && call conda deactivate) 2>nul

@rem configuration
set INSTALL_DIR=%cd%\installer_files
set CONDA_ROOT_PREFIX=%cd%\installer_files\conda
set INSTALL_ENV_DIR=%cd%\installer_files\env
set MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-py310_23.3.1-0-Windows-x86_64.exe
set MINICONDA_CHECKSUM=307194e1f12bbeb52b083634e89cc67db4f7980bd542254b43d3309eaf7cb358
set conda_exists=F

@rem (si nécessaire) installer git et Conda dans un environnement contenu
@rem téléchargement de Conda
if "%conda_exists%" == "F" (
    echo Téléchargement de Miniconda depuis %MINICONDA_DOWNLOAD_URL% vers %INSTALL_DIR%\miniconda_installer.exe

    mkdir "%INSTALL_DIR%"
    call curl -Lk "%MINICONDA_DOWNLOAD_URL%" > "%INSTALL_DIR%\miniconda_installer.exe" || ( echo. && echo L'installation de Miniconda a échoué. && goto end )

    for /f %%a in ('CertUtil -hashfile "%INSTALL_DIR%\miniconda_installer.exe" SHA256 ^| find /i /v " " ^| find /i "%MINICONDA_CHECKSUM%"') do (
        set "output=%%~a"
    )

    if not defined output (
        echo La vérification de l'intégrité du hach SHA256 pour miniconda_installer.exe a échoué.
        del "%INSTALL_DIR%\miniconda_installer.exe"
        goto end
    ) else (
        echo La vérification de l'intégrité du hach SHA256 pour miniconda_installer.exe a réussi avec succès.
    )

    echo Installation de Miniconda dans %CONDA_ROOT_PREFIX%
    start /wait "" "%INSTALL_DIR%\miniconda_installer.exe" /InstallationType=JustMe /NoShortcuts=1 /AddToPath=0 /RegisterPython=0 /NoRegistry=1 /S /D=%CONDA_ROOT_PREFIX%
)

@rem créer l'environnement d'installation
if not exist "%INSTALL_ENV_DIR%" (
    echo Paquets à installer: %PACKAGES_TO_INSTALL%
    call "%CONDA_ROOT_PREFIX%\_conda.exe" create --no-shortcuts -y -k --prefix "%INSTALL_ENV_DIR%" python=3.11 || ( echo. && echo L'installation de l'environnement Conda a échoué. && goto end )
)

@rem vérifier si l'environnement Conda a été réellement créé
if not exist "%INSTALL_ENV_DIR%\python.exe" ( echo. && echo L'environnement Conda est vide. && goto end )

@rem isolation de l'environnement
set PYTHONNOUSERSITE=1
set PYTHONPATH=
set PYTHONHOME=
set "CUDA_PATH=%INSTALL_ENV_DIR%"
set "CUDA_HOME=%CUDA_PATH%"

@rem activer l'environnement d'installation
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" || ( echo. && echo Anchor de Conda introuvable. && goto end )

@rem configurer l'environnement d'installation
call python one_click.py %*

@rem ci-dessous se trouvent des fonctions pour le script, cette ligne saute ces étapes pendant l'exécution normale
goto end

:PrintBigMessage
echo. && echo.
echo *******************************************************************
for %%M in (%*) do echo * %%~M
echo *******************************************************************
echo. && echo.
exit /b

:end
pause
