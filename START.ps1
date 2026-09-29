<#
=============================================================================
 IA Locale - DEMARRAGE
=============================================================================
 Active le venv, demarre Ollama, verifie le port puis lance l'interface web.

 Utilisation :
   .\START.ps1              # demarrage normal
   .\START.ps1 -Browser     # ouvre le navigateur automatiquement
   .\START.ps1 -Port 8080   # force un port different
   .\START.ps1 -SkipChecks  # ignore la verification des dependances

 NOTE : caracteres ASCII uniquement (evite tout probleme d'encodage).
=============================================================================
#>

[CmdletBinding()]
param(
    [switch]$Browser,
    [int]$Port = 0,
    [switch]$SkipChecks
)

$PROJECT_DIR = $PSScriptRoot
function Get-VenvPython {
    $win = Join-Path $PROJECT_DIR ".venv\Scripts\python.exe"
    if (Test-Path $win) { return $win }
    $nix = Join-Path $PROJECT_DIR ".venv\bin/python"
    if (Test-Path $nix) { return $nix }
    return $win
}
$VENV_PY     = Get-VenvPython
$APP_FILE    = Join-Path $PROJECT_DIR "ui\futuristic_app.py"
$CONFIG_FILE = Join-Path $PROJECT_DIR "config\config.yaml"

function Say  ($m, $c = "Gray") { Write-Host $m -ForegroundColor $c }
function Step ($m) { Write-Host "`n[$m]" -ForegroundColor Cyan }
function OK   ($m) { Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "  [!]    $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "  [ERR]  $m" -ForegroundColor Red }

Clear-Host
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   IA LOCALE - DEMARRAGE" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Magenta

# -----------------------------------------------------------------------------
# 1. Choix de l'interpreteur Python
# -----------------------------------------------------------------------------
Step "1/5 - Environnement Python"

$PY = $null
if (Test-Path $VENV_PY) {
    $PY = $VENV_PY
    OK "venv detecte : .venv"
} else {
    Warn "venv absent : utilisation de Python systeme"
    $sys = Get-Command python -ErrorAction SilentlyContinue
    if ($sys) {
        $PY = $sys.Source
    } else {
        Fail "Python introuvable."
        Say "  Lancez d'abord : .\INSTALL.ps1" "Yellow"
        Read-Host "Appuyez sur Entree pour fermer"
        exit 1
    }
}
& $PY -c "import sys; print('  Python', sys.version.split()[0], '-', sys.executable)"

# -----------------------------------------------------------------------------
# 2. Verification des dependances (via preflight.py : noms d'import corrects)
# -----------------------------------------------------------------------------
if (-not $SkipChecks) {
    Step "2/5 - Verification des dependances"
    $preflight = Join-Path $PROJECT_DIR "preflight.py"
    if (Test-Path $preflight) {
        & $PY $preflight --quiet
        if ($LASTEXITCODE -ne 0) {
            Fail "Dependances requises manquantes."
            Say ""
            & $PY $preflight --fix
            Say ""
            Say "  Corrigez avec : .\INSTALL.ps1 -Core" "Yellow"
            Read-Host "Appuyez sur Entree pour fermer"
            exit 1
        }
        # Import reel (plus fiable que find_spec) du module le plus critique.
        # On CAPTURE l'erreur pour afficher la cause reelle (au lieu de la masquer).
        $gradioErr = & $PY -c "import gradio" 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Fail "Le module 'gradio' ne peut pas etre importe."
            $errLines = @($gradioErr -split "`r?`n" | Where-Object { $_.Trim() -ne "" })
            if ($errLines.Count -gt 0) {
                Say "  Cause reelle (derniere ligne de l'erreur) :" "Yellow"
                $errLines | Select-Object -Last 2 | ForEach-Object { Say "    $_" "Red" }
            }
            Say ""
            Say "  1) Reinstaller le coeur :            .\INSTALL.ps1 -Core" "Yellow"
            Say "  2) Si ca persiste (venv corrompu) :  .\INSTALL.ps1 -Recreate -Core" "Yellow"
            Say "  3) Diagnostic complet :              .\TEST.ps1  (ou python preflight.py)" "Yellow"
            Read-Host "Appuyez sur Entree pour fermer"
            exit 1
        }
        OK "Dependances requises presentes"
    } else {
        Warn "preflight.py introuvable : verification ignoree"
    }
} else {
    Step "2/5 - Verification des dependances (ignoree)"
}

# -----------------------------------------------------------------------------
# 3. Ollama
# -----------------------------------------------------------------------------
Step "3/5 - Moteur LLM (Ollama)"

function Test-Ollama {
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -UseBasicParsing -TimeoutSec 3
        return $true
    } catch { return $false }
}

if (Test-Ollama) {
    OK "Serveur Ollama deja actif"
} elseif (Get-Command ollama -ErrorAction SilentlyContinue) {
    Say "  Demarrage du serveur Ollama..." "Gray"
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    $up = $false
    for ($i = 0; $i -lt 20 -and -not $up; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-Ollama) { $up = $true }
    }
    if ($up) { OK "Serveur Ollama demarre" } else { Warn "Ollama ne repond pas encore" }
} else {
    Warn "Ollama non installe : le chat ne fonctionnera pas"
    Say "  Telechargement : https://ollama.com/download" "Yellow"
}

# -----------------------------------------------------------------------------
# 4. Verification du port
# -----------------------------------------------------------------------------
Step "4/5 - Port de l'interface"

# Port configure dans config.yaml
$cfgPort = 7860
try {
    $hostLine = Select-String -Path $CONFIG_FILE -Pattern '^\s+port:\s*(\d+)' -ErrorAction SilentlyContinue |
                Select-Object -First 1
    if ($hostLine) { $cfgPort = [int]$hostLine.Matches[0].Groups[1].Value }
} catch { }

if ($Port -gt 0) {
    $cfgPort = $Port
    # Appliquer le port demande dans la configuration
    try {
        $content = Get-Content $CONFIG_FILE -Raw
        $content = [regex]::Replace($content, '(?m)^(\s+port:\s*)\d+', "`${1}$Port")
        # Ecriture sans BOM : PyYAML lit ainsi le fichier sans ambiguite
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Resolve-Path $CONFIG_FILE), $content, $utf8NoBom)
        OK "Port $Port ecrit dans config\config.yaml"
    } catch { Warn "Impossible de modifier config.yaml : port non modifie" }
}

$inUse = $false
try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect("127.0.0.1", $cfgPort)
    $inUse = $client.Connected
    $client.Close()
} catch { $inUse = $false }

if ($inUse) {
    Warn "Le port $cfgPort est deja utilise (instance deja lancee ?)"
    Say "  Interface existante : http://127.0.0.1:$cfgPort" "Cyan"
    $answer = Read-Host "  Lancer une seconde instance ? (o/N)"
    if ($answer -notmatch '^[oOyY]') { exit 0 }
} else {
    OK "Port $cfgPort disponible"
}

# Regle pare-feu (silencieuse : necessite les droits administrateur)
try {
    netsh advfirewall firewall show rule name="IA Locale $cfgPort" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        netsh advfirewall firewall add rule name="IA Locale $cfgPort" dir=in action=allow protocol=TCP localport=$cfgPort | Out-Null
    }
    if ($LASTEXITCODE -eq 0) { OK "Pare-feu : port $cfgPort autorise" }
} catch { }

# -----------------------------------------------------------------------------
# 5. Lancement
# -----------------------------------------------------------------------------
Step "5/5 - Lancement de l'interface"

if (-not (Test-Path $APP_FILE)) {
    Fail "ui\futuristic_app.py introuvable dans $PROJECT_DIR"
    Read-Host "Appuyez sur Entree pour fermer"
    exit 1
}
OK "Application : ui\futuristic_app.py"

Say ""
Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "   INTERFACE PRETE" -ForegroundColor Green
Write-Host "   URL : http://127.0.0.1:$cfgPort" -ForegroundColor Cyan
Write-Host "   (la premiere requete peut prendre 10-30 s : chargement des modeles)" -ForegroundColor Gray
Write-Host "   Pour arreter : Ctrl+C dans cette fenetre" -ForegroundColor Gray
Write-Host "==============================================================================" -ForegroundColor Magenta
Say ""

# Veilleur de port : detecte le moment ou la page web repond (HTTP 200),
# et le signale. Si -Browser, ouvre le navigateur a ce moment la.
$TEMP_DIR = if ($env:TEMP) { $env:TEMP }
            elseif ($env:TMP) { $env:TMP }
            else { [System.IO.Path]::GetTempPath() }
$readyFile = Join-Path $TEMP_DIR "local_ai_ready_$cfgPort.txt"
Remove-Item $readyFile -ErrorAction SilentlyContinue
$watchJob = Start-Job -ScriptBlock {
    param($p, $openBrowser, $readyFile)
    $ready = $false
    for ($i = 0; $i -lt 150; $i++) {
        Start-Sleep -Seconds 2
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$p/" -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) {
                if (-not $ready) {
                    $ready = $true
                    Set-Content -Path $readyFile -Value "READY"
                    if ($openBrowser) { Start-Process "http://127.0.0.1:$p" }
                }
                continue
            }
        } catch { }
        if ($ready) {
            # La page ne repond plus : l'application s'est arretee
            Set-Content -Path $readyFile -Value "GONE"
            return
        }
    }
    if (-not $ready) { Set-Content -Path $readyFile -Value "TIMEOUT" }
} -ArgumentList $cfgPort, [bool]$Browser, $readyFile

# Lancer l'application dans le dossier ui/ (les imports relatifs en dependent)
$startTime = Get-Date
Push-Location (Split-Path $APP_FILE)
try {
    & $PY (Split-Path $APP_FILE -Leaf)
} finally {
    Pop-Location
}
$elapsed = [int]((Get-Date) - $startTime).TotalSeconds

# Nettoyage du veilleur
$watchJob | Stop-Job -ErrorAction SilentlyContinue | Out-Null
$watchJob | Remove-Job -Force -ErrorAction SilentlyContinue

$readyState = "NO"
if (Test-Path $readyFile) {
    $readyState = (Get-Content $readyFile -Raw).Trim()
    Remove-Item $readyFile -ErrorAction SilentlyContinue
}

Say ""
if ($readyState -eq "READY") {
    Say "  Application arretee (la page web etait fonctionnelle avant l'arret)." "Yellow"
} elseif ($elapsed -lt 120) {
    Fail "L'application s'est arretee au bout de $elapsed s (demarrage echoue)."
    Say ""
    Say "  Diagnostic :" "Yellow"
    Say "   1. Regardez les messages d'erreur dans la console ci-dessus" "Yellow"
    Say "   2. Dependances manquantes ?   -> .\INSTALL.ps1" "Yellow"
    Say "   3. Verification complete :    -> .\TEST.ps1" "Yellow"
    Say "   4. Si la console s'est fermee : ouvrir une invite CMD et lancer" "Yellow"
    Say "        .\START.bat   (la console restera ouverte avec le message d'erreur)" "Yellow"
} else {
    Say "  Application arretee apres $elapsed s sans que la page reponde." "Yellow"
    Say "  Le demarrage a peut-etre pris plus de 5 min (modeles lourds au 1er lancement)." "Yellow"
    Say "  En cas d'erreur, voir la console ci-dessus, ou lancer .\TEST.ps1" "Yellow"
}
Read-Host "Appuyez sur Entree pour fermer"
