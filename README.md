# 🤖 IA Locale — Assistant IA 100 % local

Interface web (Gradio) qui regroupe **reconnaissance vocale, synthèse vocale, RAG, génération
d'images, 3D, personnalités, monitoring système et nettoyage automatique** — le tout exécuté
sur votre machine, sans compte ni service en ligne.

---

## 🚀 Démarrage en 3 étapes

| Étape | Action | Détail |
|-------|--------|--------|
| **1** | Double-cliquez sur **`INSTALL.bat`** | Crée l'environnement Python, installe les dépendances, Ollama et les modèles |
| **2** | Double-cliquez sur **`TEST.bat`** | Vérifie que tout est prêt et teste le démarrage réel de l'interface |
| **3** | Double-cliquez sur **`START.bat`** | Lance l'interface (option `-Browser` : le navigateur s'ouvre seul dès que la page est prête) |

Puis ouvrez : **http://127.0.0.1:7860**

> Le démarrage peut prendre 30-90 s (plus au 1er lancement) avant que la page web ne réponde :
> la console affiche l'avancement, et en cas d'échec le diagnostic.

> En ligne de commande, remplacez `*.bat` par `.\INSTALL.ps1`, `.\TEST.ps1`, `.\START.ps1`.

---

## 📋 Prérequis

| Logiciel | Version | Où l'obtenir |
|----------|---------|--------------|
| **Python** | 3.11 (3.12 accepté) | https://www.python.org/downloads/windows/ — cochez **« Add python.exe to PATH »** |
| **Ollama** | dernière | https://ollama.com/download |
| **Git / Visual C++ Build Tools** | — | **Plus requis** : toutes les dépendances (torch, TTS, webrtcvad) sont livrées en roues précompilées |

---

## 🧩 Contenu du projet

```
local-ai/
├── INSTALL.bat / INSTALL.ps1     # Installation complète (venv + dépendances + Ollama + modèles)
├── START.bat   / START.ps1       # Démarrage de l'interface
├── TEST.bat    / TEST.ps1        # Vérification complète + test de démarrage réel
├── preflight.py                  # Contrôle des prérequis (noms d'import corrects)
├── install_all_ai.py             # Installateur CLI des IA optionnelles
├── requirements.txt              # Toutes les dépendances
├── requirements-core.txt         # Dépendances minimales (démarrage garanti)
├── config/
│   ├── config.yaml               # Configuration principale (port, modèles, seuils)
│   └── personalities/            # Personnalités / rôles enregistrés
├── ui/
│   ├── futuristic_app.py         # Interface principale (Gradio)
│   └── futuristic_theme.py       # Thème cyberpunk / glassmorphism
├── scripts/                      # Modules fonctionnels
│   ├── stt.py                    # Reconnaissance vocale (faster-whisper)
│   ├── tts.py                    # Synthèse vocale multi-voix (Piper / Coqui)
│   ├── llm.py                    # Dialogue avec Ollama
│   ├── rag.py                    # Recherche documentaire (ChromaDB)
│   ├── llm_checker.py            # Vérification MANUELLE des LLM (bouton)
│   ├── ai_model_manager.py       # Gestion / installation des modèles
│   ├── personality_manager.py    # Rôles et personnalités
│   ├── sound_effects.py          # Effets sonores
│   ├── advanced_voice_commands.py# Commandes vocales avancées
│   ├── dictation_mode.py         # Dictée vocale
│   ├── auto_cleaner.py           # Nettoyage automatique
│   ├── resource_monitor.py       # Monitoring CPU / RAM / disque
│   └── project_paths.py          # Chemins portables (Windows / Linux / macOS)
├── 3d/                           # Génération et reconstruction 3D
├── uncensored/                   # Modèles non censurés (optionnel)
└── sounds/                       # Sons par défaut générés automatiquement
```

Les dossiers `models/`, `outputs/`, `chroma_db/` et `.venv/` sont créés à l'utilisation.

---

## ✨ Fonctionnalités

### Voix
- **Reconnaissance vocale en temps réel** — `faster-whisper` (points 2 et 29)
- **Synthèse vocale multi-voix, 100 % locale et sans authentification** — Piper (léger) ou Coqui TTS (point 9)
- **Dictée vocale** avec sessions et export texte/JSON (point 29)
- **Commandes vocales avancées** : « génère une image de chat », « change de personnalité expert technique »,
  « montre les ressources système », « nettoie les fichiers temporaires », « liste les modèles » (point 28)
- **Effets sonores** : 7 thèmes, sons personnalisés, file d'attente (point 23)

### Intelligence
- **Multi-modèles** : llama3.2, mistral, phi3, llava… + modèles non censurés (point 12)
- **IA non censurée / Dark** : un **onglet et un champ de chat dédiés**, séparés du
  chat principal, avec deux niveaux d'intensité — 🌙 **Non censurée** (sans refus,
  sans jugement) et 🌑 **Dark** (niveau maximum : aucun filtre, aucune
  moralisation, ton explicite). Choix du modèle (nous-hermes2, openhermes,
  mistral, llama3.1) et du mode en un clic. ⚠️ À utiliser avec responsabilité.
- **Vérification manuelle des LLM** par bouton (aucune vérification automatique)
- **Installation des IA optionnelles** depuis l'interface ou via `python install_all_ai.py`
- **Personnalités / rôles** : 8 profils fournis, création, édition, application en un clic (point 17)
- **RAG** : interrogez vos PDF, DOCX et TXT (point 14)
- **Génération d'images** (LLaVA / Stable Diffusion) et **3D** (point 6)
- **Modélisation 3D + export impression** : les vues générées sont transformées
  en **maille 3D solide et imprimable** (visual hull multi-vues + marching
  cubes), puis le projet est exporté en **STL, 3MF, OBJ, PLY et GLB**. Onglet
  *🎨 Modélisation 3D* → section **🖨 Modélisation & Export** : choisir le
  projet, les formats, la taille (mm) et la résolution, puis « Modéliser &
  Exporter ». Les fichiers sont téléchargeables dans l'interface.

> **Note 3D** : au 1er usage, le modèle Stable Diffusion (~4,5 Go) est téléchargé
> une seule fois, puis l'avancement (téléchargement → génération de chaque vue →
> création de la galerie/scène) est affiché dans le champ **Statut**. Choisissez la
> **taille 256** pour un résultat rapide et léger sur CPU (512 pour la qualité max).
>
> **Note modélisation/export** : la modélisation (maille) et les exports STL/3MF
> utilisent **uniquement les vues déjà générées** (numpy + trimesh, et scikit-image
> pour la surface lisse) — pas besoin du modèle Stable Diffusion ni d'un GPU pour
> cette étape. **Auto-réparation** : si trimesh ou scikit-image manque, le premier
> clic « Modéliser & Exporter » les installe tout seul (pip du venv courant). Sans
> scikit-image, un moteur de secours 100 % numpy (maille voxelique fermée) prend le
> relais. Plus la résolution est élevée (64 → 128), plus la surface est fine, mais
> plus c'est lent et gourmand en RAM. La maille est recentrée, mise à l'échelle à la
> taille demandée (mm) et posée sur z=0, prête pour un trancheur (Cura, PrusaSlicer…).
> 16 Go de RAM recommandés. En cas d'échec, le **détail de l'erreur** s'affiche dans
> le statut et la prévisualisation.
- **Fine-tuning** et **sessions de conversation** (points 4 et 13)
- **Plugins** : architecture modulaire `scripts/` (point 14)

### Système
- **Monitoring des ressources** en temps réel : CPU, RAM, disque, température (point 36)
- **Nettoyage automatique** paramétrable par type de fichier et par âge (point 35)
- **Compression des données** et gestion de l'espace disque (point 38)
- **Mises à jour manuelles des modèles** (point 39)

---

## ⚙️ Configuration

Fichier : `config/config.yaml`

| Réglage | Valeur par défaut | Description |
|---------|-------------------|-------------|
| `ui.port` | `7860` | Port de l'interface |
| `ui.host` | `127.0.0.1` | Écoute locale uniquement (recommandé) |
| `models.llm.model_name` | `llama3.2` | Modèle de dialogue |
| `models.stt.model_size` | `medium` | Précision de la reconnaissance vocale |
| `models.tts.provider` | `piper` | `piper` (léger, défaut) ou `coqui` (lourd, qualité) |
| `llm.check_automatically` | `false` | **Vérification manuelle uniquement** |
| `auto_cleaner.auto_clean_enabled` | `false` | Nettoyage planifié désactivé par défaut |
| `resource_monitor.auto_start` | `false` | Monitoring lancé à la demande |

Après modification du port, `START.ps1` affiche automatiquement la bonne URL.

---

## 🔧 Options utiles

```powershell
.\INSTALL.ps1 -Core        # Interface + Ollama uniquement (installation rapide)
.\INSTALL.ps1 -Recreate    # Recrée l'environnement virtuel de zéro
.\INSTALL.ps1 -NoModels    # N'installe pas les modèles Ollama
.\START.ps1 -Port 8080     # Change le port
.\START.ps1 -Browser       # Ouvre le navigateur automatiquement
.\TEST.ps1 -Fast           # Vérifie sans lancer l'application
python preflight.py        # Diagnostic détaillé des prérequis
```

---

## 🩺 Dépannage

### « Aucune IA ne me donne de résultat » — commencer ici

Ouvrez l'onglet **🩺 Diagnostic des IA** (le 1er onglet de l'application) :

1. Cliquez sur **🔍 Lancer le diagnostic** (ou attendez : il se lance aussi à l'ouverture).
2. Lisez le statut de **chaque** IA : ✅ opérationnel / ⚠️ attention (ex. : modèle
   non téléchargé) / ❌ en erreur, **avec la cause exacte**.
3. Pour chaque ❌, un bouton de **correction en un clic** est proposé :
   - **▶️ Démarrer Ollama** / **⬇️ Installer Ollama** (Windows, macOS et Linux —
     winget ou installateur officiel sous Windows)
   - **⬇️ Télécharger le modèle** (`llama3.2`, `mistral`, `nous-hermes2`…)
   - **🎨 Télécharger Stable Diffusion 3D** (~4,5 Go, pour la 3D)
   - **🔊 Télécharger la voix Piper** (~70 Mo, pour la synthèse vocale)
   - **📦 Installer les packages manquants** (pip)

La progression des téléchargements s'affiche en direct, puis le diagnostic
s'actualise tout seul. En ligne de commande : `python scripts/ai_diagnostic.py`
(liste le même diagnostic et les commandes de correction).

> Dans la grande majorité des cas, « aucune IA ne répond » = **Ollama n'est pas
> installé** (ou son serveur n'est pas lancé) **et le modèle `llama3.2` n'est pas
> téléchargé**. Le diagnostic le dit explicitement et le corrige en 2 clics.

| Symptôme | Cause | Solution |
|----------|-------|----------|
| **Aucune IA ne répond** (chat, 3D, voix…) | Ollama non installé / non démarré, modèle non téléchargé, voix absente | **Onglet 🩺 Diagnostic des IA** : diagnostic + corrections en un clic (voir section ci-dessus) |
| `ModuleNotFoundError: No module named 'gradio'` | Dépendances non installées dans le venv | `.\INSTALL.ps1 -Core` |
| `Failed to connect to Ollama` | Serveur Ollama arrêté | `ollama serve` puis `ollama pull llama3.2` |
| Le port 7860 est déjà utilisé | Une instance tourne déjà | Ouvrir http://127.0.0.1:7860 ou `.\START.ps1 -Port 8080` |
| Aucun son / pas de micro | Dépendances audio absentes | `{\.venv\Scripts\python} -m pip install sounddevice soundfile pydub` |
| La voix ne fonctionne pas | Piper/Coqui absent | `{\.venv\Scripts\python} -m pip install piper-tts` (la voix française se télécharge seule au 1er usage, ~60 Mo) |
| Erreur au démarrage d'un module | Module optionnel manquant | L'application démarre quand même et indique la commande `pip install` à lancer |
| `Execution of scripts is disabled` | Politique PowerShell | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` (ou utilisez les `.bat`) |
| Chat : aucune réponse, `model ... not found` | Modèle Ollama non installé | `ollama pull llama3.2` (le fallback automatique essaie quand même les modèles présents) |
| Chat : le menu "Modèle LLM" est vide | Ollama n'était pas démarré au lancement de l'app | Redémarrer l'application après `ollama serve` (le modèle par défaut reste utilisable) |
| "Impossible de joindre la page web" au démarrage | L'application met 30-90 s à démarrer (1er lancement plus long) | Attendre le message du veilleur dans la console ; avec `.\START.bat -Browser`, le navigateur s'ouvre seul **dès que la page est prête** |
| La console de démarrage se ferme sans la page | Échec du démarrage (dépendance, port…) | Relancer via `.\START.bat` (la console reste ouverte et affiche le diagnostic + la cause) |
| 3D : le bouton semble "figé" sans rien afficher | 1er usage : téléchargement du modèle Stable Diffusion (~4,5 Go) puis génération CPU de plusieurs minutes | Lire le champ **Statut** sous les boutons (l'avancement y est affiché) ; lancer `.\TEST.ps1 -IA` pour vérifier que la chaîne 3D fonctionne avec un modèle simulé |
| 3D : « Aucune vue générée » / erreur au chargement | Mémoire insuffisante, téléchargement du modèle interrompu, ou disque plein | Le **détail exact** est affiché dans le champ Statut et la fenêtre de prévisualisation. Conseils : choisir la **taille 256** (plus léger), prévoir **16 Go de RAM** et **~4,5 Go de disque** pour le modèle, connexion stable au 1er téléchargement |
| 3D : génération trop lente | 512 px sur CPU | Choisir la **taille 256** (≈ 4× plus rapide et plus léger) et réduire le nombre de vues |
| 3D : `Erreur: 'image_scene_code'` | Ancienne version du visualiseur (bug corrigé) | Utiliser la version du 20/09/2026 ; le HTML 3D est maintenant autonome (images intégrées) |

---

## ✅ Vérifier que tout fonctionne

`TEST.ps1` exécute automatiquement :

1. Présence des fichiers du projet
2. Version de Python et environnement virtuel
3. Import de **chaque** dépendance (avec les noms d'import corrects, ex. `python-multipart` → `multipart`)
4. État d'Ollama et liste des modèles
5. Disponibilité du port
6. **Lancement réel de l'application** et attente d'une réponse HTTP 200, puis arrêt propre

Résultat attendu :

```
   Echecs : 0
   RESULTAT : PRET A DEMARRER  ->  .\START.ps1
```

### 🧪 Test des IA par simulation (`TEST.ps1 -IA`)

Permet de vérifier que **le chat LLM, la liste des modèles et la 3D/images fonctionnent**
même sans GPU ni modèles lourds installés. L'application est lancée avec un
**Ollama simulé** (`scripts/mock_ollama.py`, HTTP + CLI) et un **Stable Diffusion
simulé** (images de test) :

```powershell
pwsh -File TEST.ps1 -IA     # verification complete + test IA (~1 min)
```

Ce qui est vérifié (40 points de contrôle) :

- **Chat complet** : envoi d'un message → réponse du LLM simulée (chaîne
  interface → `LocalLLM` → Ollama → affichage)
- **Bouton "Vérifier Ollama"**, liste des modèles, test d'un modèle
- **Chat non censuré / Dark** (mode `nous-hermes2`, champs dédiés, modes
  `libre` et `dark`)
- **Génération d'image** (Point 6) et **génération 3D** (vues + galerie +
  scène HTML interactive autonome)
- **Reconstruction 3D** à partir d'images (nuage de points) et export OBJ/PLY
- **Modélisation maille + export impression** : maille solide étanche depuis
  les vues, export **STL / 3MF / OBJ / PLY / GLB**, contrôle binaire du STL et
  du 3MF (zip + `3D/3dmodel.model`)
- **Diagnostic unifié des IA** : état « Ollama absent » (cause claire +
  correction proposée, jamais de réponse vide) et état « Ollama présent »
  (chat + non censuré opérationnels), actions de correction exécutées

En cas de doute sur une "IA qui ne répond pas", lancez d'abord ce test : s'il
passe, le code est sain et le problème vient de l'environnement réel
(Ollama pas démarré, modèle non installé, GPU…). Pour tester manuellement sans
l'app : `python scripts/mock_ollama.py` puis ouvrez l'application.

---

## 🔐 Vie privée

Toutes les fonctionnalités principales fonctionnent **hors ligne** : les modèles sont exécutés
localement via Ollama et les données restent sur votre disque. Aucune authentification, aucun
compte, aucun envoi vers un service tiers n'est requis (points 9 et 11 exclus du périmètre).

---

**Version :** 3.0 — **Dernière mise à jour :** 19 septembre 2026
