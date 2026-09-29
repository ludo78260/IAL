#!/usr/bin/env python3
"""
Script d'Installation Complète des IA
======================================

Ce script permet d'installer TOUTES les IA disponibles pour le Local AI Assistant.
Il installe :
- Tous les modèles LLM (Ollama)
- Tous les modèles STT (Faster-Whisper)
- Tous les modèles TTS (Coqui, Piper)
- Tous les modèles 3D (Stable Diffusion)
- Tous les modèles d'Embeddings
- Toutes les dépendances nécessaires

Usage:
    python install_all_ai.py              # Installe tout
    python install_all_ai.py --llm        # Installe seulement les LLM
    python install_all_ai.py --category 3d # Installe une catégorie spécifique
    python install_all_ai.py --list        # Liste les modèles disponibles
    python install_all_ai.py --recommended  # Installe les modèles recommandés
"""

import argparse
import sys
import os
import platform
import urllib.request
from pathlib import Path
from typing import List, Dict, Any
import time

# Ajouter les chemins nécessaires
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / "scripts"))

def print_header(text: str):
    """Affiche un en-tête coloré."""
    print("\n" + "=" * 80)
    print(f"🚀 {text}")
    print("=" * 80 + "\n")


def print_section(text: str):
    """Affiche une section."""
    print(f"\n📌 {text}")
    print("-" * 60)


def print_success(text: str):
    """Affiche un message de succès."""
    print(f"✅ {text}")


def print_error(text: str):
    """Affiche un message d'erreur."""
    print(f"❌ {text}")


def print_warning(text: str):
    """Affiche un avertissement."""
    print(f"⚠️ {text}")


def print_info(text: str):
    """Affiche une information."""
    print(f"ℹ️ {text}")


def check_dependencies() -> Dict[str, bool]:
    """Vérifie les dépendances nécessaires."""
    dependencies = {
        "python": sys.version_info >= (3, 8),
        "pip": True,
        "ollama": False,
        "torch": False,
        "diffusers": False,
        "transformers": False,
        "faster-whisper": False,
        "TTS": False,
        "sentence-transformers": False,
    }
    
    # Vérifier les packages Python
    try:
        import torch
        dependencies["torch"] = True
    except ImportError:
        pass
    
    try:
        import diffusers
        dependencies["diffusers"] = True
    except ImportError:
        pass
    
    try:
        import transformers
        dependencies["transformers"] = True
    except ImportError:
        pass
    
    try:
        from faster_whisper import WhisperModel
        dependencies["faster-whisper"] = True
    except ImportError:
        pass
    
    try:
        from TTS.api import TTS
        dependencies["TTS"] = True
    except ImportError:
        pass
    
    try:
        from sentence_transformers import SentenceTransformer
        dependencies["sentence-transformers"] = True
    except ImportError:
        pass
    
    # Vérifier Ollama
    try:
        import subprocess
        result = subprocess.run(["which", "ollama"], capture_output=True, text=True, errors="replace")
        dependencies["ollama"] = result.returncode == 0
    except:
        pass
    
    return dependencies


def install_python_dependencies():
    """Installe les dépendances Python nécessaires."""
    print_section("Installation des dépendances Python")
    
    required_packages = [
        "torch",
        "diffusers",
        "transformers",
        "accelerate",
        "faster-whisper",
        "sentence-transformers",
        "langchain",
        "chromadb",
        "ollama",
        "gradio",
        "sounddevice",
        "numpy",
        "pydub",
        "soundfile",
        "playsound",
        "pyyaml",
        "python-dotenv",
        "psutil",
    ]
    
    optional_packages = [
        "open3d",
        "plotly",
        "opencv-python-headless",
        "piper-tts",
        "TTS",
    ]
    
    all_packages = required_packages + optional_packages
    
    print_info(f"Installation de {len(all_packages)} packages Python...")
    
    # Installer par groupes pour éviter les timeouts
    import subprocess
    
    # Groupe 1: PyTorch (le plus long)
    print_info("Installation de PyTorch...")
    # Note : pas de --index-url force ici. Sur PyPI, pip choisit deja les
    # roues Windows/Linux du jour ; forcer cu118 ajoute ~2.5 Go de CUDA
    # inutile sur une machine sans GPU NVIDIA.
    torch_cmd = "pip install torch torchvision torchaudio"
    try:
        subprocess.run(torch_cmd, shell=True, check=True, capture_output=True, text=True, errors="replace")
        print_success("PyTorch installé")
    except subprocess.CalledProcessError as e:
        print_warning(f"PyTorch: {e.stderr}")
    
    # Groupe 2: Diffusers et Transformers
    print_info("Installation de Diffusers et Transformers...")
    diffusers_cmd = "pip install diffusers transformers accelerate"
    try:
        subprocess.run(diffusers_cmd, shell=True, check=True, capture_output=True, text=True, errors="replace")
        print_success("Diffusers et Transformers installés")
    except subprocess.CalledProcessError as e:
        print_warning(f"Diffusers/Transformers: {e.stderr}")
    
    # Groupe 3: Audio
    # (TTS Coqui isole : paquet lourd, son echec ne doit pas bloquer le reste)
    print_info("Installation des packages audio...")
    audio_cmd = "pip install faster-whisper sentence-transformers sounddevice pydub soundfile playsound webrtcvad-wheels"
    try:
        subprocess.run(audio_cmd, shell=True, check=True, capture_output=True, text=True, errors="replace")
        print_success("Packages audio installés")
    except subprocess.CalledProcessError as e:
        print_warning(f"Audio: {e.stderr}")

    print_info("Installation de Coqui TTS (optionnel, lourd)...")
    try:
        subprocess.run("pip install TTS", shell=True, check=True, capture_output=True, text=True, errors="replace")
        print_success("Coqui TTS installé (optionnel)")
    except subprocess.CalledProcessError as e:
        print_warning(f"Coqui TTS (optionnel): échec - Piper-TTS assurera la synthèse vocale. {e.stderr}")
    
    # Groupe 4: Autres
    print_info("Installation des autres packages...")
    other_cmd = "pip install langchain chromadb ollama gradio numpy pyyaml python-dotenv psutil"
    try:
        subprocess.run(other_cmd, shell=True, check=True, capture_output=True, text=True, errors="replace")
        print_success("Autres packages installés")
    except subprocess.CalledProcessError as e:
        print_warning(f"Autres: {e.stderr}")
    
    # Groupe 5: Optionnels
    print_info("Installation des packages optionnels...")
    optional_cmd = "pip install open3d plotly opencv-python-headless piper-tts"
    try:
        subprocess.run(optional_cmd, shell=True, check=True, capture_output=True, text=True, errors="replace")
        print_success("Packages optionnels installés")
    except subprocess.CalledProcessError as e:
        print_warning(f"Optionnels: {e.stderr}")


def _ollama_reachable(timeout: float = 3.0) -> bool:
    """Vérifie que le serveur Ollama répond (sans curl, compatible Windows)."""
    import urllib.request
    try:
        with urllib.request.urlopen("http://localhost:11434/api/version", timeout=timeout):
            return True
    except Exception:
        return False


def _find_ollama_bin():
    """Chemin du binaire ollama dans le PATH (Windows inclus)."""
    import shutil
    found = shutil.which("ollama")
    if found:
        return found
    if platform.system() == "Windows":
        for d in filter(os.path.isdir, os.environ.get("PATH", "").split(os.pathsep)):
            cand = Path(d) / "ollama.exe"
            if cand.exists():
                return str(cand)
    return None


def install_ollama():
    """Installe Ollama (Windows, macOS, Linux)."""
    print_section("Installation d'Ollama")

    import subprocess
    import platform

    system = platform.system()

    if system == "Windows":
        import shutil
        winget = shutil.which("winget")
        if winget:
            print_info("Installation via winget (Microsoft Store)...")
            try:
                subprocess.run(
                    [winget, "install", "-e", "--id", "Ollama.Ollama",
                     "--accept-source-agreements", "--accept-package-agreements"],
                    check=False)
            except Exception as e:
                print_error(f"winget a échoué: {e}")
            if _find_ollama_bin():
                print_success("Ollama installé")
                return True
            print_warning("winget n'a pas abouti : tentative du téléchargement direct...")
        # Repli : programme d'installation officiel (assistant graphique, 2 clics)
        url = "https://ollama.com/download/ollama-setup-windows.exe"
        exe = Path(os.environ.get("TEMP", ".")) / "ollama-setup-windows.exe"
        try:
            print_info(f"Téléchargement de {url} ...")
            urllib.request.urlretrieve(url, exe)
            print_info("Lancement de l'installateur (suivez l'assistant)...")
            os.startfile(str(exe))  # type: ignore[attr-deprecated]
            print_warning("Terminez l'installation, puis relancez ce script.")
            return _find_ollama_bin() is not None
        except Exception as e:
            print_error(f"Échec du téléchargement/installation: {e}")
            print_info("Installation manuelle : https://ollama.com/download/windows")
            return False

    elif system == "Linux":
        print_info("Installation d'Ollama sur Linux...")
        try:
            subprocess.run("curl -fsSL https://ollama.com/install.sh | sh", shell=True, check=True)
            print_success("Ollama installé")

            # Ajouter au PATH
            home = Path.home()
            ollama_path = home / ".local" / "bin"
            if ollama_path.exists():
                print_info(f"Ajout de {ollama_path} au PATH...")
                # Ne pas modifier automatiquement le PATH, l'utilisateur doit le faire
                print_warning(f"Ajoutez ceci à votre ~/.bashrc ou ~/.zshrc: export PATH=$PATH:{ollama_path}")

            return True
        except subprocess.CalledProcessError as e:
            print_error(f"Échec de l'installation d'Ollama: {e}")
            return False

    elif system == "Darwin":
        print_info("Installation d'Ollama sur macOS...")
        try:
            subprocess.run("brew install ollama", shell=True, check=True)
            print_success("Ollama installé via Homebrew")
            return True
        except subprocess.CalledProcessError as e:
            print_error(f"Échec de l'installation d'Ollama: {e}")
            return False

    else:
        print_error(f"Système non supporté: {system}")
        return False


def start_ollama():
    """Démarre le serveur Ollama (Windows, macOS, Linux)."""
    print_section("Démarrage d'Ollama")

    import subprocess

    try:
        # Vérifier si Ollama répond déjà (sans curl/ps, compatible Windows)
        if _ollama_reachable():
            print_success("Ollama est déjà en cours d'exécution")
            return True

        bin_path = _find_ollama_bin()
        if not bin_path:
            print_error("Ollama n'est pas installé (binaire introuvable). "
                        "Lancez d'abord : python install_all_ai.py  (étape Ollama) "
                        "ou installez-le sur https://ollama.com/download")
            return False

        print_info("Démarrage du serveur Ollama...")
        creationflags = 0
        if platform.system() == "Windows":
            creationflags = 0x00000208  # NEW_PROCESS_GROUP | DETACHED
        subprocess.Popen(
            [bin_path, "serve"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            creationflags=creationflags,
        )

        # Attendre que le serveur soit prêt
        print_info("Attente du démarrage d'Ollama...")
        for i in range(15):
            if _ollama_reachable(timeout=3):
                print_success("Ollama est prêt !")
                return True
            time.sleep(2)
            print_info(f"Attente... ({i+1}/15)")

        print_warning("Ollama n'a pas répondu après 30 secondes. Vérifiez les logs.")
        return False

    except Exception as e:
        print_error(f"Échec du démarrage d'Ollama: {e}")
        return False


def install_ollama_models():
    """Installe les modèles Ollama."""
    print_section("Installation des modèles Ollama")
    
    import subprocess
    
    # Liste des modèles à installer
    models = [
        "llama3.2",
        "mistral",
        "phi3",
        "llava",
        "nous-hermes2",
    ]
    
    print_info(f"Installation de {len(models)} modèles LLM...")
    
    for i, model in enumerate(models):
        print_info(f"[{i+1}/{len(models)}] Installation de {model}...")
        try:
            result = subprocess.run(
                ["ollama", "pull", model],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=600  # 10 minutes par modèle
            )
            
            if result.returncode == 0:
                print_success(f"✅ {model} installé")
            else:
                print_error(f"❌ {model} échoué: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            print_error(f"⏰ {model} timeout (10 minutes)")
        except Exception as e:
            print_error(f"❌ {model} erreur: {e}")
    
    print_success("Installation des modèles Ollama terminée")


def install_huggingface_models():
    """Installe les modèles HuggingFace (téléchargement au premier usage)."""
    print_section("Préparation des modèles HuggingFace")
    
    print_info("""
    Les modèles HuggingFace sont téléchargés AUTOMATIQUEMENT 
    au premier usage. Aucun téléchargement manuel nécessaire.
    
    Modèles qui seront téléchargés automatiquement :
    - Stable Diffusion 1.5 (2.0 Go)
    - ControlNet Depth (1.5 Go)
    - all-MiniLM-L6-v2 (80 Mo)
    - XTTS v2 (1.5 Go)
    """)
    
    print_success("Prêt pour le téléchargement automatique")


def list_models():
    """Liste tous les modèles disponibles."""
    print_header("Liste des Modèles IA Disponibles")
    
    try:
        from scripts.ai_model_manager import AIModelManager, ModelCategory
        
        manager = AIModelManager()
        models = manager.get_all_models()
        
        # Par catégorie
        for category in ModelCategory:
            cat_models = manager.get_models_by_category(category)
            if cat_models:
                print(f"\n📁 {category.value.upper()} ({len(cat_models)} modèles)")
                print("-" * 60)
                
                for model in cat_models:
                    status = manager.get_status(model.id)
                    status_emoji = "✅" if status == "installed" else "❌"
                    default_marker = " [DÉFAUT]" if model.default else ""
                    recommended_marker = " ⭐" if model.recommended else ""
                    
                    print(f"{status_emoji} {model.name}{default_marker}{recommended_marker}")
                    print(f"   Taille: {model.size_gb} Go")
                    print(f"   Description: {model.description}")
                    print()
        
        # Statistiques
        print("\n📊 Statistiques")
        print("-" * 60)
        stats = manager.get_statistics()
        print(f"Total modèles: {stats.get('total_models', 0)}")
        print(f"Installés: {stats.get('installed_models', 0)}")
        print(f"À installer: {stats.get('not_installed_models', 0)}")
        print(f"Taille totale: {stats.get('total_size_gb', 0)} Go")
        
    except Exception as e:
        print_error(f"Impossible de lister les modèles: {e}")


def install_by_category(category: str):
    """Installe tous les modèles d'une catégorie."""
    print_header(f"Installation de la catégorie: {category}")
    
    try:
        from scripts.ai_model_manager import AIModelManager, ModelCategory
        
        manager = AIModelManager()
        
        if category not in [c.value for c in ModelCategory]:
            print_error(f"Catégorie invalide: {category}")
            print_info(f"Catégories valides: {[c.value for c in ModelCategory]}")
            return
        
        cat = ModelCategory(category)
        models = manager.get_models_by_category(cat)
        
        print_info(f"Installation de {len(models)} modèles de la catégorie {category}...")
        
        result = manager.install_category(cat)
        
        if result.get("success"):
            print_success(f"Catégorie {category} installée avec succès")
        else:
            print_error(f"Échec de l'installation de la catégorie {category}")
            
    except Exception as e:
        print_error(f"Erreur: {e}")


def install_recommended():
    """Installe tous les modèles recommandés."""
    print_header("Installation des modèles recommandés")
    
    try:
        from scripts.ai_model_manager import AIModelManager
        
        manager = AIModelManager()
        recommended = manager.get_recommended_models()
        
        print_info(f"Installation de {len(recommended)} modèles recommandés...")
        print_info("Modèles à installer:")
        for model in recommended:
            print(f"  - {model.name} ({model.size_gb} Go)")
        
        result = manager.install_all_recommended()
        
        if result.get("success"):
            print_success("Tous les modèles recommandés installés")
        else:
            print_error("Certains modèles ont échoué")
            for model_id, res in result.get("results", {}).items():
                if not res.get("success"):
                    print(f"  ❌ {model_id}: {res.get('error')}")
            
    except Exception as e:
        print_error(f"Erreur: {e}")


def install_all():
    """Installe TOUS les modèles."""
    print_header("Installation de TOUS les modèles IA")
    
    print_warning("""
    ⚠️  ATTENTION : Cette opération peut prendre PLUSIEURS HEURES
    et nécessiter plus de 45 Go d'espace disque !
    
    Modèles à installer:
    - 8 modèles LLM/Ollama (~30 Go)
    - 5 modèles STT (~5 Go)
    - 3 modèles TTS (~3 Go)
    - 6 modèles 3D (~15 Go)
    - 4 modèles Embeddings (~0.5 Go)
    
    Espace total requis: ~50-60 Go
    Temps estimé: 2-6 heures (selon la connexion)
    """)
    
    confirm = input("Voulez-vous continuer ? (oui/non): ").strip().lower()
    if confirm != "oui":
        print_info("Installation annulée")
        return
    
    try:
        from scripts.ai_model_manager import AIModelManager
        
        manager = AIModelManager()
        all_models = manager.get_all_models()
        model_ids = [m.id for m in all_models]
        
        print_info(f"Installation de {len(model_ids)} modèles...")
        
        result = manager.install_multiple_models(model_ids)
        
        if result.get("success"):
            print_success("Tous les modèles installés avec succès !")
        else:
            print_error("Certains modèles ont échoué")
            for model_id, res in result.get("results", {}).items():
                if res.get("success"):
                    print(f"  ✅ {model_id}")
                else:
                    print(f"  ❌ {model_id}: {res.get('error')}")
            
    except Exception as e:
        print_error(f"Erreur: {e}")


def main():
    """Point d'entrée principal."""
    parser = argparse.ArgumentParser(
        description="Installeur complet des IA pour Local AI Assistant",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples:
  python install_all_ai.py                    # Installe tout
  python install_all_ai.py --list            # Liste les modèles
  python install_all_ai.py --recommended     # Installe les recommandés
  python install_all_ai.py --category llm    # Installe une catégorie
  python install_all_ai.py --category 3d     # Installe la 3D
        """
    )
    
    parser.add_argument(
        "--list", "-l",
        action="store_true",
        help="Liste tous les modèles disponibles"
    )
    parser.add_argument(
        "--recommended", "-r",
        action="store_true",
        help="Installe tous les modèles recommandés"
    )
    parser.add_argument(
        "--category", "-c",
        type=str,
        help="Installe tous les modèles d'une catégorie (llm, stt, tts, 3d, embeddings, uncensored)"
    )
    parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Installe TOUS les modèles (attention: ~50 Go !)"
    )
    parser.add_argument(
        "--dependencies", "-d",
        action="store_true",
        help="Installe uniquement les dépendances Python"
    )
    parser.add_argument(
        "--ollama", "-o",
        action="store_true",
        help="Installe uniquement Ollama et ses modèles"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Vérifie les dépendances et modèles installés"
    )
    
    args = parser.parse_args()
    
    print_header("Local AI Assistant - Installateur Complète des IA")
    
    # Vérifier les dépendances
    if args.check or not any([args.list, args.recommended, args.category, args.all, 
                              args.dependencies, args.ollama]):
        print_section("Vérification des dépendances")
        deps = check_dependencies()
        
        print("\n📋 État des dépendances:")
        for dep, installed in deps.items():
            status = "✅" if installed else "❌"
            print(f"{status} {dep}")
        
        if not args.check:
            print("\n")
    
    # Actions
    if args.list:
        list_models()
    
    elif args.dependencies:
        install_python_dependencies()
    
    elif args.ollama:
        if deps.get("ollama"):
            start_ollama()
            install_ollama_models()
        else:
            if install_ollama():
                start_ollama()
                install_ollama_models()
    
    elif args.category:
        install_by_category(args.category)
    
    elif args.recommended:
        install_recommended()
    
    elif args.all:
        install_all()
    
    else:
        # Menu interactif
        print("\n🎯 Que souhaitez-vous faire ?")
        print("-" * 60)
        print("1. 📋 Lister tous les modèles disponibles")
        print("2. ⭐ Installer les modèles recommandés")
        print("3. 📁 Installer une catégorie spécifique")
        print("4. 🚀 Installer TOUS les modèles")
        print("5. 🐍 Installer les dépendances Python")
        print("6. 🦙 Installer Ollama et ses modèles")
        print("7. 🔍 Vérifier les dépendances")
        print("8. ❌ Quitter")
        print()
        
        choice = input("Choix (1-8): ").strip()
        
        if choice == "1":
            list_models()
        elif choice == "2":
            install_recommended()
        elif choice == "3":
            from scripts.ai_model_manager import ModelCategory
            print("\nCatégories disponibles:")
            for i, cat in enumerate(ModelCategory, 1):
                print(f"{i}. {cat.value}")
            cat_choice = input("Choix (1-6): ").strip()
            cats = [c.value for c in ModelCategory]
            if cat_choice.isdigit() and 1 <= int(cat_choice) <= len(cats):
                install_by_category(cats[int(cat_choice)-1])
            else:
                print_error("Choix invalide")
        elif choice == "4":
            install_all()
        elif choice == "5":
            install_python_dependencies()
        elif choice == "6":
            if deps.get("ollama"):
                start_ollama()
                install_ollama_models()
            else:
                if install_ollama():
                    start_ollama()
                    install_ollama_models()
        elif choice == "7":
            deps = check_dependencies()
            print("\n📋 État des dépendances:")
            for dep, installed in deps.items():
                status = "✅" if installed else "❌"
                print(f"{status} {dep}")
        elif choice == "8":
            print_info("Au revoir !")
            sys.exit(0)
        else:
            print_error("Choix invalide")
            sys.exit(1)


if __name__ == "__main__":
    main()