<#
=============================================================================
 IA Locale - INSTALLATION
=============================================================================
 Cree le venv Python 3.11, installe les dependances, Ollama et les modeles.

 Utilisation :
   .\INSTALL.ps1                 # installation complete
   .\INSTALL.ps1 -Core           # interface + Ollama uniquement (rapide)
   .\INSTALL.ps1 -Recreate       # recree le venv de zero
   .\INSTALL.ps1 -NoModels       # n'installe pas les modeles Ollama

 NOTE : ce script n'utilise que des caracteres ASCII afin d'eviter tout
        probleme d'encodage (accents mal affiches) dans PowerShell.
=============================================================================
#>

[CmdletBinding()]
param(
    [switch]$Core,
    [switch]$Recreate,
    [switch]$NoModels
)

$ErrorActionPreference = "Continue"
$PROJECT_DIR = $PSScriptRoot
$VENV_DIR    = Join-Path $PROJECT_DIR ".venv"

# Chemin de l'interpreteur du venv (Windows : Scripts\python.exe, sinon bin/python)
function Get-VenvPython {
    $win = Join-Path $VENV_DIR "Scripts\python.exe"
    if (Test-Path $win) { return $win }
    $nix = Join-Path $VENV_DIR "bin/python"
    if (Test-Path $nix) { return $nix }
    return $win   # valeur attendue sous Windows si le venv n'existe pas encore
}
$VENV_PY = Get-VenvPython

$GROUPS = @{
    Core    = @(
        "gradio>=4.44.0,<6.0.0", "gradio_client>=1.3.0", "ollama>=0.4.0",
        "PyYAML>=6.0.1", "psutil>=5.9.0", "requests>=2.31.0",
        "python-multipart>=0.0.9", "numpy>=1.26.0,<3.0.0", "Pillow>=10.0.0"
    )
    Vocal   = @(
        "faster-whisper>=1.0.0", "sounddevice>=0.4.6", "soundfile>=0.12.1",
        # webrtcvad-wheels = fork du webrtcvad (wiseman) AVEC roues precompilées
        # Windows/macOS/Linux : le paquet "webrtcvad" classique echoue sous
        # Python 3.11+ car il faut compiler le C/C++.
        "pydub>=0.25.1", "webrtcvad-wheels>=2.0.14", "playsound>=1.2.2",
        "piper-tts>=1.2.0"
    )
    Rag     = @(
        "chromadb>=0.4.24", "sentence-transformers>=2.7.0", "langchain>=0.2.0",
        "langchain-community>=0.2.0", "langchain-text-splitters>=0.2.0",
        "pypdf>=4.2.0", "docx2txt>=0.8"
    )
    IA      = @(
        "torch>=2.2.0", "torchvision>=0.17.0", "torchaudio>=2.2.0",
        "transformers>=4.41.0", "diffusers>=0.29.0", "accelerate>=0.30.0",
        "opencv-python>=4.9.0"
    )
    # Modélisation 3D (mailles étanches + export STL/3MF/OBJ/PLY/GLB).
    # LEGER : aucune dépendance GPU — installé par défaut (même en -Core)
    # pour que l'onglet « Modélisation & Export » fonctionne directement.
    Modele3D = @("trimesh>=4.0.0", "scikit-image>=0.21.0")
    Coqui   = @("TTS>=0.22.0")
}

function Write-Step  ($m) { Write-Host "`n[$m]" -ForegroundColor Cyan }
function Write-OK    ($m) { Write-Host "  [OK]   $m" -ForegroundColor Green }
function Write-Warn2 ($m) { Write-Host "  [!]    $m" -ForegroundColor Yellow }
function Write-Err   ($m) { Write-Host "  [ERR]  $m" -ForegroundColor Red }

# -----------------------------------------------------------------------------
# 0. Banniere
# -----------------------------------------------------------------------------
Clear-Host
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   IA LOCALE - INSTALLATION" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   Dossier projet : $PROJECT_DIR"

# -----------------------------------------------------------------------------
# 1. Recherche de Python 3.11
# -----------------------------------------------------------------------------
Write-Step "1/6 - Detection de Python 3.11"

function Find-Python311 {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python312\python.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    # Recherche via le launcher py
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        foreach ($tag in @("-3.11", "-3.12", "-3")) {
            try {
                $out = & py $tag -c "import sys; print(sys.executable)" 2>$null
                if ($LASTEXITCODE -eq 0 -and $out) { return $out.Trim() }
            } catch { }
        }
    }
    # Dernier recours : python du PATH
    $sys = Get-Command python -ErrorAction SilentlyContinue
    if ($sys) { return $sys.Source }
    return $null
}

$PY_BASE = Find-Python311
if (-not $PY_BASE) {
    Write-Err "Python introuvable."
    Write-Host "  Installez Python 3.11 : https://www.python.org/downloads/windows/" -ForegroundColor Yellow
    Write-Host "  IMPORTANT : cochez 'Add python.exe to PATH' pendant l'installation." -ForegroundColor Yellow
    exit 1
}
Write-OK "Python detecte : $PY_BASE"
& $PY_BASE -c "import sys; print('  Version :', sys.version.split()[0])"

# -----------------------------------------------------------------------------
# 2. Environnement virtuel
# -----------------------------------------------------------------------------
Write-Step "2/6 - Environnement virtuel (.venv)"

if ($Recreate -and (Test-Path $VENV_DIR)) {
    Write-Warn2 "Suppression de l'ancien venv (-Recreate)..."
    Remove-Item $VENV_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $VENV_PY)) {
    Write-Host "  Creation du venv..." -ForegroundColor Gray
    & $PY_BASE -m venv $VENV_DIR
    $VENV_PY = Get-VenvPython
    if (-not (Test-Path $VENV_PY)) {
        Write-Err "Echec de la creation du venv."
        exit 1
    }
    Write-OK "venv cree"
} else {
    Write-OK "venv deja present"
}

Write-Host "  Mise a jour de pip..." -ForegroundColor Gray
& $VENV_PY -m pip install --upgrade pip setuptools wheel --quiet
Write-OK "pip a jour"

$VPY = $VENV_PY   # python du venv : TOUJOURS utiliser celui-ci

# -----------------------------------------------------------------------------
# 3. Dependances Python
# -----------------------------------------------------------------------------
Write-Step "3/6 - Installation des dependances Python"

function Install-Group {
    param([string]$Name, [string[]]$Packages)
    Write-Host "`n  -- Groupe : $Name --" -ForegroundColor Gray
    foreach ($pkg in $Packages) {
        Write-Host "     install $pkg ..." -ForegroundColor Gray -NoNewline
        & $VPY -m pip install --prefer-binary --disable-pip-version-check --quiet $pkg 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
        } else {
            Write-Host " ECHEC (ignore, fonctionnalite partielle)" -ForegroundColor Yellow
        }
    }
}

Install-Group -Name "Core (obligatoire)" -Packages $GROUPS.Core

# Verification stricte du coeur par VRAI import (pas seulement find_spec).
# find_spec ne confirme que le dossier existe : un package peut etre present
# mais CASSE (wheel incompatible, dependance binaire manquante) et alors
# `import` echoue. C'est l'ecart qui produisait « install tout vert mais
# START echoue sur gradio ». Ici on importe reellement chaque module, on
# affiche la cause, et on re-ininstalle automatiquement ce qui echoue.
# NB : le nom d'IMPORT differe parfois du nom pip ("python-multipart" s'importe
# "multipart", "PyYAML" s'importe "yaml").
$corePkgs = @(
    @{ label = "Interface web (gradio)";     pip = "gradio";           imp = "gradio" }
    @{ label = "Client Ollama (ollama)";     pip = "ollama";           imp = "ollama" }
    @{ label = "Configuration (PyYAML)";     pip = "PyYAML";           imp = "yaml" }
    @{ label = "Monitoring (psutil)";        pip = "psutil";           imp = "psutil" }
    @{ label = "HTTP (requests)";            pip = "requests";         imp = "requests" }
    @{ label = "Upload (python-multipart)";  pip = "python-multipart"; imp = "multipart" }
    @{ label = "Calcul (numpy)";             pip = "numpy";            imp = "numpy" }
    @{ label = "Images (Pillow)";            pip = "Pillow";           imp = "PIL" }
)

function Test-CoreImport {
    param([string]$ImportName)
    $out = & $VPY -c "import importlib,sys; importlib.import_module(sys.argv[1]); print('IMPORT_OK')" $ImportName 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $out -match "IMPORT_OK") {
        return @{ ok = $true; err = "" }
    }
    $lines = @($out -split "`r?`n" | Where-Object { $_.Trim() -ne "" })
    return @{ ok = $false; err = $(if ($lines.Count -gt 0) { $lines[-1].Trim() } else { "echec inconnu" }) }
}

$coreMissing = @()
foreach ($p in $corePkgs) {
    $r = Test-CoreImport $p.imp
    if ($r.ok) {
        Write-Host "     [OK] $($p.label) importe" -ForegroundColor Green
        continue
    }
    # Le package est-il au moins present (dossier) ?
    & $VPY -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('$($p.imp)') else 1)" 2>$null
    $present = ($LASTEXITCODE -eq 0)
    if ($present) {
        Write-Host "     [!] $($p.label) : present mais import echoue -> reinstallation" -ForegroundColor Yellow
        Write-Host "         cause : $($r.err)" -ForegroundColor Red
        & $VPY -m pip install --prefer-binary --disable-pip-version-check --quiet --force-reinstall --no-cache-dir $p.pip 2>$null
    } else {
        Write-Host "     [!] $($p.label) : absent -> installation" -ForegroundColor Yellow
        & $VPY -m pip install --prefer-binary --disable-pip-version-check --quiet $p.pip 2>$null
    }
    $r2 = Test-CoreImport $p.imp
    if ($r2.ok) {
        Write-Host "     [OK] $($p.label) installe/reinstalle et importe" -ForegroundColor Green
    } else {
        Write-Host "     [X] $($p.label) : echec persistant" -ForegroundColor Red
        Write-Host "         cause : $($r2.err)" -ForegroundColor Red
        $coreMissing += "$($p.label) (pip install $p.pip)"
    }
}
if ($coreMissing.Count -gt 0) {
    Write-Err "Modules coeur non importables : $($coreMissing -join ', ')"
    Write-Host "  Relancez : .\INSTALL.ps1  -  ou venv propre : .\INSTALL.ps1 -Recreate -Core" -ForegroundColor Yellow
    exit 1
}
Write-OK "Tous les modules coeur sont importables (verifie par VRAI import, pas seulement presence)"

# Modélisation 3D (léger, sans GPU) : installé par défaut, même en -Core,
# pour que l'onglet « Modélisation & Export » (STL/3MF/...) fonctionne.
Install-Group -Name "Modele3D (léger - mailles + export STL/3MF)" -Packages $GROUPS.Modele3D

if ($Core) {
    Write-Warn2 "Mode -Core : fonctionnalites avancees non installees."
} else {
    Install-Group -Name "Vocal (points 2, 9, 23, 29)"  -Packages $GROUPS.Vocal
    Install-Group -Name "RAG / sessions (points 4, 14)" -Packages $GROUPS.Rag
    Install-Group -Name "IA / images / 3D (points 6, 12, 13)" -Packages $GROUPS.IA

    Write-Host "`n  -- Groupe : Coqui TTS (optionnel, lourd) --" -ForegroundColor Gray
    $coquiLog = & $VPY -m pip install --prefer-binary --quiet $GROUPS.Coqui[0] 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Coqui TTS installe (meilleure qualite multi-voix)"
    } else {
        Write-Warn2 "Coqui TTS non installe (paquet lourd) : Piper-TTS assurera la synthese vocale"
        $last = $coquiLog | Select-Object -Last 1
        if ($last) { Write-Host "         Derniere erreur pip : $last" -ForegroundColor DarkGray }
        Write-Host "         Pour l'installer plus tard : .\.venv\Scripts\pip install TTS" -ForegroundColor Yellow
        Write-Host "         (la config basculera sur Coqui dans config.yaml > models.tts.provider)" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# 4. Ollama
# -----------------------------------------------------------------------------
Write-Step "4/6 - Ollama (moteur LLM local)"

$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollamaCmd) {
    Write-Warn2 "Ollama n'est pas installe."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "  Installation via winget..." -ForegroundColor Gray
        winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
        Start-Sleep -Seconds 5
        $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
    }
    if (-not $ollamaCmd) {
        Write-Warn2 "Installez Ollama manuellement : https://ollama.com/download"
        Write-Host "  Puis relancez ce script." -ForegroundColor Yellow
    }
} else {
    Write-OK "Ollama detecte : $($ollamaCmd.Source)"
}

# -----------------------------------------------------------------------------
# 5. Modeles Ollama
# -----------------------------------------------------------------------------
Write-Step "5/6 - Modeles Ollama"

if ($NoModels) {
    Write-Warn2 "Installation des modeles ignoree (-NoModels)"
} elseif (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Warn2 "Ollama absent : modeles non installes"
} else {
    # Demarrer le serveur si necessaire
    $running = $false
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -UseBasicParsing -TimeoutSec 3
        $running = $true
    } catch { $running = $false }

    if (-not $running) {
        Write-Host "  Demarrage du serveur Ollama..." -ForegroundColor Gray
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        for ($i = 0; $i -lt 20 -and -not $running; $i++) {
            Start-Sleep -Milliseconds 500
            try {
                $null = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -UseBasicParsing -TimeoutSec 2
                $running = $true
            } catch { }
        }
    }

    if ($running) {
        Write-OK "Serveur Ollama actif"

        $installed = @()
        try {
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -UseBasicParsing -TimeoutSec 5
            $data = $resp.Content | ConvertFrom-Json
            foreach ($m in $data.models) { $installed += ($m.name -split ":")[0] }
        } catch { }

        $want = @("llama3.2", "mistral", "phi3", "llava")
        foreach ($model in $want) {
            if ($installed -contains $model) {
                Write-OK "Modele deja present : $model"
            } else {
                Write-Host "  Telechargement de $model (peut prendre plusieurs minutes)..." -ForegroundColor Gray
                & ollama pull $model
                if ($LASTEXITCODE -eq 0) { Write-OK "Modele installe : $model" }
                else { Write-Warn2 "Echec du telechargement de $model" }
            }
        }
    } else {
        Write-Warn2 "Serveur Ollama non joignable : modeles non installes"
    }
}

# -----------------------------------------------------------------------------
# 6. Verification finale
# -----------------------------------------------------------------------------
Write-Step "6/6 - Verification (preflight)"

if (Test-Path (Join-Path $PROJECT_DIR "preflight.py")) {
    & $VPY (Join-Path $PROJECT_DIR "preflight.py") --fix
} else {
    Write-Warn2 "preflight.py introuvable"
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   INSTALLATION TERMINEE" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   Pour demarrer :  .\START.ps1   (ou double-clic sur START.bat)"
Write-Host ""
