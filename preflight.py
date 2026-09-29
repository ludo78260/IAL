#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
preflight.py - Verification des prerequis de l'IA Locale
========================================================

Verifie, sans dependance externe (stdlib uniquement) :
  1. Version de Python
  2. Fichiers du projet
  3. Packages Python (requis / optionnels) via leur nom d'IMPORT
  4. Ollama (binaire, serveur, modeles)
  5. Disponibilite du port de l'interface

Usage:
    python preflight.py              # rapport complet
    python preflight.py --fix        # affiche les commandes pip a lancer
    python preflight.py --quiet      # code retour uniquement (0 = OK)

Codes retour:
    0 = pret a demarrer
    1 = dependance requise manquante
    2 = Python trop ancien
"""

import importlib.util
import json
import os
import socket
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
CONFIG_FILE = PROJECT_ROOT / "config" / "config.yaml"

# -----------------------------------------------------------------------------
# Table de correspondance : nom pip  ->  nom d'IMPORT (corrige le bug des tirets)
# -----------------------------------------------------------------------------
REQUIRED_PACKAGES = [
    # (nom affiche, nom pip, nom d'import, categorie)
    ("Interface web",       "gradio",            "gradio",            "interface"),
    ("Client Ollama",       "ollama",            "ollama",            "llm"),
    ("Configuration",       "PyYAML",            "yaml",              "base"),
    ("Monitoring systeme",  "psutil",            "psutil",            "systeme"),
    ("Requetes HTTP",       "requests",          "requests",          "base"),
    ("Upload fichiers",       "python-multipart",  "multipart",         "interface"),
    ("Calcul numerique",      "numpy",             "numpy",             "base"),
    ("Mailles 3D (export)",   "trimesh",           "trimesh",           "3d"),
]

OPTIONAL_PACKAGES = [
    # (nom affiche, nom pip, nom d'import, categorie, fonctionnalite)
    ("Reconnaissance vocale", "faster-whisper",       "faster_whisper",       "vocal",     "Point 2 - STT temps reel"),
    ("Synthese vocale Coqui", "TTS",                  "TTS",                  "vocal",     "Point 9 - TTS multi-voix"),
    ("Synthese vocale Piper", "piper-tts",            "piper",                "vocal",     "Point 9 - TTS alternatif"),
    ("Audio lecture",         "sounddevice",          "sounddevice",          "vocal",     "Lecture audio"),
    ("Audio WAV",             "soundfile",            "soundfile",            "vocal",     "Point 23 - effets sonores"),
    ("Audio MP3",             "pydub",                "pydub",                "vocal",     "Point 23 - effets sonores"),
    ("PyTorch",               "torch",                "torch",                "ia",        "Points 6/13 - images/3D"),
    ("Transformers",          "transformers",         "transformers",         "ia",        "Points 6/12 - modeles"),
    ("Embeddings",            "sentence-transformers", "sentence_transformers", "rag",      "Point 14 - plugins/RAG"),
    ("Base vectorielle",      "chromadb",             "chromadb",             "rag",       "Point 4 - sessions/RAG"),
    ("LangChain",             "langchain",            "langchain",            "rag",       "Point 14 - RAG"),
    ("LangChain community",   "langchain-community",  "langchain_community",  "rag",       "Point 14 - RAG"),
    ("Traitement images",     "Pillow",               "PIL",                  "ia",        "Point 6 - generation images"),
    ("Vision ordinateur",     "opencv-python",        "cv2",                  "ia",        "3D - reconstruction"),
    ("Diffusion images",      "diffusers",         "diffusers",         "ia",        "Point 6 - SD/3D"),
    # webrtcvad-wheels : fork du webrtcvad avec roues precompilees (import : webrtcvad)
    ("Espacement vocal",      "webrtcvad-wheels",  "webrtcvad",         "vocal",     "Point 29 - dictee"),
    # scikit-image : marching cubes (surface lisse) pour la modélisation 3D.
    # OPTIONNEL : si absent, un fallback voxelique 100% numpy prend le relais
    # (maille fermée de style voxel) — la modélisation reste fonctionnelle.
    ("Surface lisse 3D",      "scikit-image",      "skimage",           "ia",        "Point 13 - marching cubes (sinon maille voxelique)"),
]

GREEN, RED, YELLOW, CYAN, GREY, RESET = (
    "\033[92m", "\033[91m", "\033[93m", "\033[96m", "\033[90m", "\033[0m"
)
if os.name == "nt" and not os.environ.get("WT_SESSION"):
    GREEN = RED = YELLOW = CYAN = GREY = RESET = ""


def ok(msg):    print(f"  {GREEN}[OK]{RESET}   {msg}")
def ko(msg):    print(f"  {RED}[MANQUE]{RESET} {msg}")
def warn(msg):  print(f"  {YELLOW}[!]{RESET}    {msg}")
def info(msg):  print(f"  {GREY}       {msg}{RESET}")


def title(msg):
    print(f"\n{CYAN}=== {msg} ==={RESET}")


def check_python():
    title("1. Version de Python")
    major, minor = sys.version_info[:2]
    print(f"  Version detectee : {sys.version.split()[0]}")
    print(f"  Executable       : {sys.executable}")
    if (major, minor) >= (3, 11):
        ok("Python 3.11 ou superieur")
        return True
    if (major, minor) >= (3, 10):
        warn("Python 3.10 detecte : l'application fonctionne, 3.11+ est recommande")
        return True
    ko(f"Python {major}.{minor} trop ancien : installez Python 3.11")
    return False


def check_files():
    title("2. Fichiers du projet")
    expected = [
        "ui/futuristic_app.py",
        "ui/futuristic_theme.py",
        "config/config.yaml",
        "scripts/llm.py",
        "scripts/tts.py",
        "scripts/stt.py",
        "scripts/rag.py",
        "requirements.txt",
    ]
    all_ok = True
    for rel in expected:
        if (PROJECT_ROOT / rel).exists():
            ok(rel)
        else:
            ko(f"{rel} introuvable")
            all_ok = False
    return all_ok


def has_module(import_name):
    try:
        return importlib.util.find_spec(import_name) is not None
    except (ImportError, ValueError, ModuleNotFoundError):
        return False


def import_ok(import_name, timeout=120):
    """VRAI import dans un sous-interpreteur isole.

    find_spec() (has_module) ne confirme que le dossier du package existe ;
    un package peut etre presente mais CASSE (wheel incompatible, dependance
    binaire manquante, installation interrompue) : dans ce cas find_spec
    renvoie True alors que `import` echoue. C'est exactement l'ecart qui
    produisait « install tout vert mais START echoue sur gradio ».

    Retourne (bool, message d'erreur court = derniere ligne du traceback).
    """
    env = dict(os.environ)
    env.setdefault("GRADIO_ANALYTICS_ENABLED", "false")
    try:
        r = subprocess.run(
            [sys.executable, "-c",
             "import importlib,sys; importlib.import_module(sys.argv[1])",
             import_name],
            capture_output=True, text=True, errors="replace",
            timeout=timeout, env=env,
        )
        if r.returncode == 0:
            return True, ""
        lines = [ln.strip() for ln in (r.stderr or r.stdout or "").splitlines()
                 if ln.strip()]
        return False, (lines[-1] if lines else "echec d'import inconnu")
    except Exception as e:
        return False, f"{type(e).__name__}: {e}"



def check_packages(fix=False):
    title("3. Packages Python")
    missing_required, broken_required, missing_optional = [], [], []

    print(f"  {CYAN}-- Requis (vrai import, pas seulement presence) --{RESET}")
    for label, pip_name, import_name, _cat in REQUIRED_PACKAGES:
        found = has_module(import_name)
        imp_ok, imp_err = import_ok(import_name) if found else (False, "package absent")
        if imp_ok:
            ok(f"{label} ({pip_name})")
        else:
            ko(f"{label} ({pip_name})")
            if found and imp_err != "package absent":
                info(f"present mais import impossible : {imp_err}")
                broken_required.append(pip_name)
            else:
                missing_required.append(pip_name)

    print(f"\n  {CYAN}-- Optionnels (fonctionnalites avancees) --{RESET}")
    for label, pip_name, import_name, _cat, feature in OPTIONAL_PACKAGES:
        if has_module(import_name):
            ok(f"{label} ({pip_name})")
        else:
            warn(f"{label} ({pip_name}) - {feature}")
            missing_optional.append(pip_name)

    if missing_required and fix:
        print(f"\n  {CYAN}A installer (absents) :{RESET}")
        print(f'    "{sys.executable}" -m pip install ' + " ".join(missing_required))
    if broken_required and fix:
        print(f"\n  {CYAN}A reinstaller (present mais import echoue) :{RESET}")
        print(f'    "{sys.executable}" -m pip install --force-reinstall --no-cache-dir '
              + " ".join(broken_required))
    if missing_optional and fix:
        print(f"\n  {CYAN}Optionnels a lancer :{RESET}")
        print(f'    "{sys.executable}" -m pip install ' + " ".join(missing_optional))

    pkgs_ok = len(missing_required) == 0 and len(broken_required) == 0
    return pkgs_ok, missing_required, broken_required, missing_optional


def http_json(url, timeout=3):
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8", "ignore"))
    except Exception:
        return None


def check_ollama():
    title("4. Ollama (moteur LLM local)")
    ollama_ok = True

    binary = None
    for candidate in ("ollama", "ollama.exe"):
        from shutil import which
        binary = which(candidate)
        if binary:
            break
    if binary:
        ok(f"Binaire trouve : {binary}")
    else:
        warn("Binaire 'ollama' absent du PATH (installez https://ollama.com/download)")
        ollama_ok = False

    tags = http_json("http://127.0.0.1:11434/api/tags")
    if tags is None:
        warn("Serveur Ollama injoignable sur http://127.0.0.1:11434 (lancez : ollama serve)")
        ollama_ok = False
    else:
        models = [m.get("name", "?") for m in tags.get("models", [])]
        ok(f"Serveur Ollama actif - {len(models)} modele(s) installe(s)")
        for m in models[:12]:
            info(f"- {m}")
        if len(models) > 12:
            info(f"... et {len(models) - 12} autre(s)")
        if not models:
            warn("Aucun modele : lancez 'ollama pull llama3.2'")
            ollama_ok = False

    return ollama_ok


def read_port():
    """Lit le port de l'interface depuis config.yaml (sans dependance PyYAML)."""
    port, host = 7860, "127.0.0.1"
    try:
        text = CONFIG_FILE.read_text(encoding="utf-8", errors="ignore")
        section = None
        for raw in text.splitlines():
            line = raw.split("#")[0].rstrip()
            if not line.strip():
                continue
            if not line.startswith(" ") and line.rstrip().endswith(":"):
                section = line.strip().rstrip(":").strip()
                continue
            if section == "ui" and ":" in line:
                key, _, value = line.partition(":")
                key, value = key.strip(), value.strip().strip('"').strip("'")
                if key == "port":
                    port = int(value)
                elif key == "host":
                    host = value
    except Exception:
        pass
    return host, port


def check_port():
    title("5. Port de l'interface")
    host, port = read_port()
    print(f"  Port configure dans config/config.yaml : {port} (hote {host})")
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1.5)
    in_use = sock.connect_ex(("127.0.0.1", port)) == 0
    sock.close()
    if in_use:
        warn(f"Le port {port} est deja utilise - une instance tourne peut-etre deja")
        info(f"Ouvrez http://127.0.0.1:{port} dans votre navigateur")
        return port, False
    ok(f"Port {port} disponible")
    return port, True


def main():
    args = set(sys.argv[1:])
    fix = "--fix" in args
    quiet = "--quiet" in args

    if quiet:
        py_ok = sys.version_info[:2] >= (3, 10)
        files_ok = all((PROJECT_ROOT / p).exists() for p in
                       ["ui/futuristic_app.py", "config/config.yaml", "requirements.txt"])
        # Vrais imports (pas seulement find_spec) : un package present mais
        # casse doit faire echouer le quiet, sinon START echouerait juste apres.
        pkgs_ok = True
        for _l, _p, i, _c in REQUIRED_PACKAGES:
            if not has_module(i):
                pkgs_ok = False
                break
            ok_import, _err = import_ok(i)
            if not ok_import:
                pkgs_ok = False
                break
        sys.exit(0 if (py_ok and files_ok and pkgs_ok) else 1)

    print("=" * 70)
    print("  PREFLIGHT - IA LOCALE")
    print("=" * 70)
    print(f"  Projet : {PROJECT_ROOT}")
    print(f"  Python : {sys.executable}")

    py_ok = check_python()
    files_ok = check_files()
    pkgs_ok, missing_req, broken_req, missing_opt = check_packages(fix=fix)
    ollama_ok = check_ollama()
    port, port_free = check_port()

    print("\n" + "=" * 70)
    print("  RESULTAT")
    print("=" * 70)
    print(f"  Python ................ {'OK' if py_ok else 'A CORRIGER'}")
    print(f"  Fichiers projet ....... {'OK' if files_ok else 'A CORRIGER'}")
    print(f"  Packages requis ....... {'OK' if pkgs_ok else 'A CORRIGER'}")
    print(f"  Ollama ................ {'OK' if ollama_ok else 'A DEMARRER'}")
    print(f"  Port {port} ............. {'LIBRE' if port_free else 'DEJA UTILISE'}")

    if not py_ok:
        print(f"\n  {RED}-> Installez Python 3.11 puis relancez l'installation.{RESET}")
        sys.exit(2)
    if not pkgs_ok:
        print(f"\n  {RED}-> Packages requis a corriger :{RESET}")
        if missing_req:
            print(f"  Absents : {', '.join(missing_req)}")
            print(f'     "{sys.executable}" -m pip install ' + " ".join(missing_req))
        if broken_req:
            print(f"  Present mais import impossible : {', '.join(broken_req)}")
            print(f'     "{sys.executable}" -m pip install --force-reinstall --no-cache-dir '
                  + " ".join(broken_req))
        print(f'  (ou installation complete : "{sys.executable}" -m pip install -r requirements.txt)')
        sys.exit(1)

    print(f"\n  {GREEN}-> Pret a demarrer. Lancez : START.bat (ou .\\START.ps1){RESET}")
    print(f"  {GREEN}-> Interface : http://127.0.0.1:{port}{RESET}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
