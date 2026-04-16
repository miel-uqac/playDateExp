# Plant Climber — Jeu Playdate


## Description du projet

**Plant Climber** est un jeu de type *endless runner* développé pour la console `Playdate`, une console portable dotée d'une manivelle comme contrôle principal.

Dans notre jeu, le joueur incarne une plante qui grimpe sans fin vers le ciel. En tournant la manivelle, il guide la tige de la plante pour éviter les obstacles qui apparaissent. Plus le joueur survit longtemps, plus le jeu devient difficile, et plus son score grimpe !

### Fonctionnalités principales
- Contrôle via la manivelle de la Playdate
- Système de score avec sauvegarde du meilleur score
- Deux types d'obstacles avec difficulté progressive
- Système de bonus
- Background parallaxe à plusieurs couches

---

## Technologies utilisées

| Technologie | Usage |
|-------------|-------|
| **Lua** | Langage principal de développement |
| **Playdate SDK** | API graphique, audio, inputs, datastore |
| **Playdate Simulator** | Test et débogage sur PC |
| **GIMP** | Création des assets |

Le développement Playdate permet également l'utilisation du C pour des besoins de performance, mais ce projet est entièrement réalisé en Lua, le langage recommandé pour débuter sur Playdate.

---

## Lancer le projet

### Prérequis
- Télécharger et installer le [Playdate SDK](https://play.date/dev/)
- Avoir accès au Playdate Simulator (normalement inclus dans le SDK)

### Étapes
1. Dans un terminal, allez de le dossier voulu via la commande 
```bash
    cd C:/VotreFichier/
```
2. Ensuite, cloner le dépôt :
```bash
   git clone https://github.com/miel-uqac/playDateExp.git
```
3. Ouvrir le Playdate Simulator
4. Dans le Simulator, aller dans **File > Open** et sélectionner le dossier du projet
5. Pour lancer le jeu, appuyez sur **F5**

---

## Structure du projet

```
├── assets/

│   ├── audio/          # Musiques et effets sonores

│   ├── Background/     # Assets du background parallaxe

│   └── ...             # Autres assets graphiques

├── main.lua            # Point d'entrée, boucle de jeu principale

├── plant.lua           # Logique et rendu de la plante

├── obstacles.lua       # Classes des obstacles (Saw, FallingPot)

├── bonus.lua           # Système de bonus collectables

├── audio.lua           # Gestion de l'audio

├── ui.lua              # HUD et menus

├── game_constants.lua  # Toutes les constantes du jeu

└── pdxinfo             # Métadonnées du projet Playdate
```
---

## Documentation

Toute la documentation technique du projet est disponible sur le [Wiki GitHub](https://github.com/miel-uqac/playDateExp/wiki).

Le Wiki contient notamment :
- Des informations sur l'utilisation du SDK
- Des tutoriels sur la création d'un jeu Playdate
- Des explications sur nos choix pendant le développement du projet
- Des aides au code
- Les assets que nous avons utilisé

---

## Contexte académique

Ce projet a été réalisé dans le cadre du cours de projet de l'UQAC.

**Objectifs pédagogiques :**
- Découvrir le développement de jeu sur une console contrainte (Playdate)
- Apprendre à structurer un projet de jeu complet
- Travailler en équipe sur un projet de A à Z
- Créer une documentation technique en français sur la création de jeux Playdate

## Crédits

| Rôle | Personne |
|------|----------|
| Développement, game design et documentation | **[Basile MONOD](https://github.com/BASile15)** (étudiant, UQAC) |
| Développement, game design et documentation | **[Edgar MARTIN](https://github.com/MaiSan18)** (étudiant, UQAC) |
| Supervision | **[Damien BRUN](https://github.com/makowildcat)** (Professeur, UQAC) |

---

## Liens utiles

- [Wiki du projet](https://github.com/miel-uqac/playDateExp/wiki)
- [Site officiel Playdate](https://play.date/)
- [Télécharger le SDK Playdate](https://play.date/dev/)
- [Documentation officielle du SDK](https://sdk.play.date/)
