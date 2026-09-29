<#
=============================================================================
 IA Locale - VERIFICATION COMPLETE
=============================================================================
 Verifie l'environnement, les dependances, les modeles, puis teste le
 demarrage reel de l'application (import des modules + reponse HTTP).

 Utilisation :
   .\TEST.ps1            # verification complete
   .\TEST.ps1 -Fast      # sans test de demarrage de l'application
   .\TEST.ps1 -IA        # + test IA par simulation (chat LLM + 3D, ~1 min)

 NOTE : caracteres ASCII uniquement (evite tout probleme d'encodage).
=============================================================================
#>

[CmdletBinding()]
param([switch]$Fast, [switch]$IA)

$PROJECT_DIR = $PSScriptRoot
$VENV_PY     = Join-Path $PROJECT_DIR ".venv\Scripts\python.exe"
$CONFIG_FILE = Join-Path $PROJECT_DIR "config\config.yaml"

# Repertoire temporaire (env:TEMP peut etre vide selon l'environnement)
$TEMP_DIR = if ($env:TEMP) { $env:TEMP }
            elseif ($env:TMP) { $env:TMP }
            else { [System.IO.Path]::GetTempPath() }

function Get-TempFile {
    param([string]$Name)
    try {
        $path = Join-Path $TEMP_DIR $Name
        # Verifier que le dossier est utilisable
        [void][System.IO.Path]::GetFullPath($path)
        return $path
    } catch {
        return Join-Path $PROJECT_DIR $Name
    }
}

$script:Fails = 0
$script:Warns = 0

function Step ($m) { Write-Host "`n[$m]" -ForegroundColor Cyan }
function OK   ($m) { Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "  [!]    $m" -ForegroundColor Yellow; $script:Warns++ }
function Fail ($m) { Write-Host "  [ERR]  $m" -ForegroundColor Red; $script:Fails++ }

Clear-Host
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   IA LOCALE - VERIFICATION COMPLETE" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   Projet : $PROJECT_DIR"

# -----------------------------------------------------------------------------
# 1. Fichiers du projet
# -----------------------------------------------------------------------------
Step "1/6 - Fichiers du projet"
$files = @(
    "ui\futuristic_app.py", "ui\futuristic_theme.py", "config\config.yaml",
    "scripts\llm.py", "scripts\tts.py", "scripts\stt.py", "scripts\rag.py",
    "scripts\project_paths.py", "preflight.py", "requirements.txt", "install_all_ai.py"
)
foreach ($f in $files) {
    if (Test-Path (Join-Path $PROJECT_DIR $f)) { OK $f } else { Fail "$f introuvable" }
}

# -----------------------------------------------------------------------------
# 2. Python et venv
# -----------------------------------------------------------------------------
Step "2/6 - Python"

$PY = $null
if (Test-Path $VENV_PY) { $PY = $VENV_PY; OK "venv : .venv\Scripts\python.exe" }
else {
    Warn "venv absent (lancez .\INSTALL.ps1)"
    $sys = Get-Command python -ErrorAction SilentlyContinue
    if ($sys) { $PY = $sys.Source; OK "Python systeme : $($sys.Source)" }
    else { Fail "Aucun Python utilisable" }
}

if ($PY) {
    $pyver = & $PY -c "import sys; print('.'.join(map(str, sys.version_info[:3])))" 2>$null
    if ($pyver) {
        if ([version]$pyver -ge [version]"3.11.0") { OK "Version Python : $pyver" }
        elseif ([version]$pyver -ge [version]"3.10.0") { Warn "Python $pyver (3.11+ recommande)" }
        else { Fail "Python $pyver trop ancien" }
    }
}

# -----------------------------------------------------------------------------
# 3. Dependances (via le nom d'IMPORT : corrige le bug des tirets)
# -----------------------------------------------------------------------------
Step "3/6 - Dependances Python"

if ($PY) {
    $mods = @(
        @{ n = "Interface web (gradio)";       i = "gradio";                req = $true },
        @{ n = "Client Ollama (ollama)";       i = "ollama";                req = $true },
        @{ n = "Configuration (PyYAML)";       i = "yaml";                  req = $true },
        @{ n = "Monitoring (psutil)";          i = "psutil";                req = $true },
        @{ n = "HTTP (requests)";              i = "requests";              req = $true },
        @{ n = "Upload (python-multipart)";    i = "multipart";             req = $true },
        @{ n = "Calcul (numpy)";               i = "numpy";                 req = $true },
        @{ n = "Images (Pillow)";              i = "PIL";                   req = $false },
        @{ n = "STT (faster-whisper)";         i = "faster_whisper";        req = $false },
        @{ n = "TTS (piper)";                  i = "piper";                 req = $false },
        @{ n = "TTS (coqui)";                  i = "TTS";                   req = $false },
        @{ n = "Audio (sounddevice)";          i = "sounddevice";           req = $false },
        @{ n = "Audio (soundfile)";            i = "soundfile";             req = $false },
        @{ n = "Audio (pydub)";                i = "pydub";                 req = $false },
        @{ n = "IA (torch)";                   i = "torch";                 req = $false },
        @{ n = "IA (transformers)";            i = "transformers";          req = $false },
        @{ n = "RAG (chromadb)";               i = "chromadb";              req = $false },
        @{ n = "RAG (sentence-transformers)";  i = "sentence_transformers"; req = $false },
        @{ n = "RAG (langchain)";              i = "langchain";             req = $false }
    )
    foreach ($m in $mods) {
        & $PY -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('$($m.i)') else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) { OK $m.n }
        elseif ($m.req) { Fail "$($m.n) - REQUIS" }
        else { Warn "$($m.n) - optionnel (fonctionnalite desactivee)" }
    }
}

# -----------------------------------------------------------------------------
# 4. Ollama
# -----------------------------------------------------------------------------
Step "4/6 - Ollama"

$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaCmd) { OK "Binaire : $($ollamaCmd.Source)" } else { Warn "Binaire ollama absent du PATH" }

$serverUp = $false
try {
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -UseBasicParsing -TimeoutSec 4
    $serverUp = $true
    OK "Serveur Ollama actif (http://127.0.0.1:11434)"
} catch { Warn "Serveur Ollama injoignable (il sera demarre par START.ps1)" }

if ($serverUp) {
    try {
        $data = $resp.Content | ConvertFrom-Json
        $count = @($data.models).Count
        if ($count -gt 0) {
            OK "$count modele(s) installe(s)"
            foreach ($m in $data.models) { Write-Host "         - $($m.name)" -ForegroundColor Gray }
        } else {
            Warn "Aucun modele : lancez 'ollama pull llama3.2'"
        }
    } catch { Warn "Reponse Ollama illisible" }
}

# -----------------------------------------------------------------------------
# 5. Port de l'interface
# -----------------------------------------------------------------------------
Step "5/6 - Port de l'interface"

$port = 7860
try {
    $match = Select-String -Path $CONFIG_FILE -Pattern '^\s+port:\s*(\d+)' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { $port = [int]$match.Matches[0].Groups[1].Value }
} catch { }
Write-Host "  Port configure : $port" -ForegroundColor Gray

$inUse = $false
try {
    $c = New-Object System.Net.Sockets.TcpClient
    $c.Connect("127.0.0.1", $port)
    $inUse = $c.Connected
    $c.Close()
} catch { $inUse = $false }
if ($inUse) { Warn "Port deja utilise (instance en cours ?)" } else { OK "Port $port libre" }

# -----------------------------------------------------------------------------
# 6. Test de demarrage reel de l'application
# -----------------------------------------------------------------------------
Step "6/6 - Test de demarrage de l'application"

if ($Fast) {
    Warn "Test de demarrage ignore (-Fast)"
} elseif (-not $PY) {
    Fail "Impossible de tester sans Python"
} else {
    # 6a. Import des modules de l'application (sans lancer le serveur)
    Write-Host "  Import des modules de l'application..." -ForegroundColor Gray
    $testScript = Get-TempFile "ia_locale_import_test.py"
    @'
import sys, os
from pathlib import Path
root = Path(sys.argv[1])
sys.path.insert(0, str(root / "scripts"))
sys.path.insert(0, str(root / "3d"))
sys.path.insert(0, str(root / "uncensored"))
sys.path.insert(0, str(root / "ui"))
sys.path.insert(0, str(root))
errors = []
for mod, label in [("stt", "STT"), ("tts", "TTS"), ("llm", "LLM"), ("rag", "RAG")]:
    try:
        __import__(mod); print(f"  [OK]   module {label}")
    except Exception as e:
        print(f"  [!]    module {label} indisponible : {type(e).__name__}"); errors.append(mod)
try:
    import futuristic_theme; print("  [OK]   module theme")
except Exception as e:
    print(f"  [ERR]  module theme : {e}"); errors.append("theme")
print("IMPORT_TEST_OK" if "theme" not in errors else "IMPORT_TEST_FAIL")
'@ | Set-Content -Path $testScript -Encoding UTF8
    & $PY $testScript $PROJECT_DIR
    $importOk = ($LASTEXITCODE -eq 0)

    # 6b. Lancement temporaire du serveur et test HTTP
    Write-Host "`n  Lancement temporaire du serveur (max 60 s)..." -ForegroundColor Gray
    $appFile = Join-Path $PROJECT_DIR "ui\futuristic_app.py"
    $outLog = Get-TempFile "ia_locale_out.log"
    $errLog = Get-TempFile "ia_locale_err.log"
    $startArgs = @{
        FilePath               = $PY
        ArgumentList           = "`"$appFile`""
        PassThru               = $true
        RedirectStandardOutput = $outLog
        RedirectStandardError  = $errLog
    }
    # -WindowStyle n'existe que sous Windows
    if ($env:OS -eq "Windows_NT") { $startArgs["WindowStyle"] = "Hidden" }
    $proc = Start-Process @startArgs

    $httpOk = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        if (-not $proc -or $proc.HasExited) { break }
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -UseBasicParsing -TimeoutSec 3
            if ($r.StatusCode -eq 200) { $httpOk = $true; break }
        } catch { }
    }

    if ($httpOk) {
        OK "Serveur web repond sur http://127.0.0.1:$port (HTTP 200)"
    } elseif (-not $proc -or $proc.HasExited) {
        Fail "L'application s'est arretee (code $($proc.ExitCode))"
        Write-Host "`n  --- Dernieres lignes de log ---" -ForegroundColor Gray
        foreach ($log in @($errLog, $outLog)) {
            if ($log -and (Test-Path $log)) {
                Get-Content $log -Tail 25 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            }
        }
    } else {
        Warn "Pas de reponse HTTP en 60 s (le chargement initial peut etre long)"
    }

    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        OK "Instance de test arretee"
    }
    Remove-Item $testScript -ErrorAction SilentlyContinue
}

# -----------------------------------------------------------------------------
# Test IA par simulation (option -IA)
#   - Phase 1 : generation 3D / images avec Stable Diffusion SIMULE
#   - Phase 2 : application complete + Ollama SIMULE (HTTP + CLI)
#   Permet de valider le fonctionnement des IA sans GPU ni modeles lourds.
# -----------------------------------------------------------------------------
if ($IA) {
    Step "TEST IA (SIMULATION)"
    $iaScript = Join-Path $PROJECT_DIR "tests\test_ia.py"
    if (Test-Path $iaScript) {
        $iaLog = if ($env:TEMP) { Join-Path $env:TEMP "local_ai_test_ia.log" }
                 else { Join-Path $PROJECT_DIR "local_ai_test_ia.log" }
        Write-Host "  (Lance l'application avec un Ollama simule : ~1 minute)" -ForegroundColor DarkGray
        & $PY $iaScript 2>&1 | Tee-Object -FilePath $iaLog
        if ($LASTEXITCODE -eq 0) {
            OK "Test IA : chat LLM + modeles + 3D + images tous verifies"
        } else {
            Fail "Test IA : des echecs sont signales - voir le log : $iaLog"
        }
    } else {
        Warn "Script de test IA introuvable : tests\test_ia.py"
    }
}

# -----------------------------------------------------------------------------
# Bilan
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   BILAN" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   Echecs : $script:Fails" -ForegroundColor $(if ($script:Fails -gt 0) { "Red" } else { "Green" })
Write-Host "   Avertissements : $script:Warns" -ForegroundColor $(if ($script:Warns -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($script:Fails -eq 0) {
    Write-Host "   RESULTAT : PRET A DEMARRER  ->  .\START.ps1" -ForegroundColor Green
} else {
    Write-Host "   RESULTAT : CORRECTIONS NECESSAIRES  ->  .\INSTALL.ps1" -ForegroundColor Red
}
Write-Host ""
Read-Host "Appuyez sur Entree pour fermer"
