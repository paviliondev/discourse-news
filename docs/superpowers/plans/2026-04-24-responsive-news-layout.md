# Responsive News Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre le plugin discourse-news entièrement responsive — desktop (≥ 1025px), tablette (768px–1024px) et smartphone (≤ 767px) — sans scrolling horizontal ni images débordantes.

**Architecture:** On adopte l'Approche A : `@media` queries dans `common/discourse-news.scss` pour gérer les trois breakpoints (le fichier mobile Discourse reste pour les overrides user-agent). Les images inline du corps d'article sont contraintes via `.news-item-body img`. Aucun changement JavaScript ni de template.

**Tech Stack:** SCSS (plugin Discourse), pas de dépendance externe.

---

## Fichiers modifiés

| Fichier | Action | Responsabilité |
|---|---|---|
| `assets/stylesheets/common/discourse-news.scss` | Modifier | Layout principal + breakpoints responsive |
| `assets/stylesheets/mobile/discourse-news.scss` | Modifier | Nettoyage `!important`, thumbnail hauteur auto |

---

## Task 1 : Corriger la largeur fixe et le layout flex desktop

**Fichiers :**
- Modifier : `assets/stylesheets/common/discourse-news.scss:44-46`

Le problème central est `width: 750px` sans `max-width`. On le remplace pour que la colonne puisse se réduire sur les écrans étroits.

- [ ] **Step 1.1 : Ouvrir `common/discourse-news.scss` et remplacer le bloc `.topic-list-contents`**

Remplacer aux lignes 44–46 :
```scss
// AVANT
.topic-list-contents {
  width: 750px;
}
```
par :
```scss
// APRÈS
.topic-list-contents {
  width: 750px;
  max-width: 100%;
  box-sizing: border-box;
}
```

- [ ] **Step 1.2 : Ajouter `min-width: 0` sur le flex container `#list-area`**

Dans le sélecteur `body.news #list-area` (ligne 37), ajouter après `display: flex;` :
```scss
body.news #list-area {
  display: flex;
  min-width: 0;          // empêche le flex item de déborder
  overflow-x: hidden;   // filet de sécurité global
  // ... reste inchangé
}
```

- [ ] **Step 1.3 : Committer**
```bash
git add assets/stylesheets/common/discourse-news.scss
git commit -m "fix: replace fixed 750px width with max-width on news topic-list-contents"
```

---

## Task 2 : Ajouter les `@media` queries pour tablette (768px–1024px)

**Fichiers :**
- Modifier : `assets/stylesheets/common/discourse-news.scss` (ajouter à la fin)

Sur tablette, la sidebar est cachée et la colonne articles passe en pleine largeur. Le titre est réduit légèrement.

- [ ] **Step 2.1 : Ajouter le bloc `@media` tablette à la fin du fichier**

Ajouter ces règles **après la dernière accolade fermante** du fichier `common/discourse-news.scss` :

```scss
// === Tablet (768px – 1024px) ===
@media screen and (max-width: 1024px) {
  body.news #list-area {
    flex-direction: column;

    .topic-list-contents {
      width: 100%;
      max-width: 100%;
    }

    .sidebar {
      display: none;
    }
  }

  body.news #list-area .contents .topic-list tbody {
    .news-item .news-item-title a {
      font-size: 28px;
      line-height: 36px;
    }
  }
}
```

- [ ] **Step 2.2 : Vérifier visuellement dans un navigateur à 900px de large**

Ouvrir `/news` dans un navigateur, redimensionner à 900px de large. Vérifier :
- La sidebar n'est plus visible
- La colonne d'articles occupe 100% de la largeur
- Pas de scrollbar horizontale

- [ ] **Step 2.3 : Committer**
```bash
git add assets/stylesheets/common/discourse-news.scss
git commit -m "feat: add tablet responsive breakpoint (768-1024px) hiding sidebar"
```

---

## Task 3 : Corriger le fichier mobile — thumbnail hauteur auto + suppression des `!important`

**Fichiers :**
- Modifier : `assets/stylesheets/mobile/discourse-news.scss`

Le fichier actuel force `height: 200px !important` sur les thumbnails. On passe à `height: auto` pour préserver le ratio. On supprime les `!important` devenus inutiles car le fichier mobile est chargé après le commun.

- [ ] **Step 3.1 : Réécrire `mobile/discourse-news.scss`**

Remplacer le contenu intégral par :

```scss
#list-area.news {
  .contents {
    .topic-list {
      width: 100%;

      tbody {
        width: 100%;

        .news-item {
          max-width: 100%;
          width: 100%;
          box-sizing: border-box;

          .news-item-thumbnail {
            float: initial;
            margin: 10px 0;

            img {
              width: 100%;
              height: auto;         // ratio préservé (était height: 200px !important)
              object-fit: cover;
            }
          }

          .news-item-title {
            margin-bottom: 5px;

            a {
              font-size: 22px;
              line-height: 30px;
            }
          }

          .news-item-body {
            margin-top: 0;
          }
        }
      }
    }
  }
}
```

- [ ] **Step 3.2 : Committer**
```bash
git add assets/stylesheets/mobile/discourse-news.scss
git commit -m "fix: mobile thumbnail height auto instead of fixed 200px, remove !important"
```

---

## Task 4 : Contraindre les images inline dans le corps de l'article

**Fichiers :**
- Modifier : `assets/stylesheets/common/discourse-news.scss`

Les posts Discourse peuvent contenir des `<img>` avec des attributs `width` inline (ex: `width="800"`). Sans override CSS, ces images cassent le layout sur les petits écrans.

- [ ] **Step 4.1 : Ajouter la règle sur `.news-item-body img` dans `common/discourse-news.scss`**

Dans le bloc `.news-item-body` (ligne 122–125), ajouter les règles image :

```scss
// AVANT
.news-item-body {
  max-height: initial;
  color: var(--primary);
}
```

```scss
// APRÈS
.news-item-body {
  max-height: initial;
  color: var(--primary);

  // Empêche les images inline du post de déborder sur les petits écrans
  img {
    max-width: 100%;
    height: auto;
  }
}
```

- [ ] **Step 4.2 : Vérifier sur un article avec une image large dans le corps**

Ouvrir `/news`, cliquer sur un article qui contient des images dans son corps. Redimensionner à 375px. Vérifier que les images ne débordent pas.

- [ ] **Step 4.3 : Committer**
```bash
git add assets/stylesheets/common/discourse-news.scss
git commit -m "fix: constrain inline images in news-item-body to max-width 100%"
```

---

## Task 5 : Vérification complète multi-viewport

- [ ] **Step 5.1 : Tester desktop (≥ 1025px)**

Ouvrir `/news` à pleine largeur. Vérifier :
- Layout flex horizontal (articles à gauche, sidebar à droite)
- Sidebar visible avec bordure
- Images thumbnail en pleine largeur de la colonne, ratio correct
- Pas de scrollbar horizontale

- [ ] **Step 5.2 : Tester tablette (768px–1024px)**

Redimensionner à 900px. Vérifier :
- Sidebar cachée
- Colonne articles pleine largeur
- Titre légèrement réduit (28px)
- Pas de scrollbar horizontale

- [ ] **Step 5.3 : Tester smartphone (≤ 767px)**

Utiliser les DevTools (mode mobile, ex: iPhone 14 Pro = 390px). Vérifier :
- Tout en colonne
- Thumbnail pleine largeur, hauteur auto
- Titre 22px lisible
- Pas de scrollbar horizontale
- Images du corps de l'article ne débordent pas

- [ ] **Step 5.4 : Lancer RuboCop pour s'assurer que rien de Ruby n'a été touché**
```bash
bundle exec rubocop
```
Attendu : pas d'erreur (aucun fichier Ruby modifié).

- [ ] **Step 5.5 : Committer si des ajustements ont été faits lors des tests**
```bash
git add assets/stylesheets/
git commit -m "fix: responsive news layout adjustments from cross-viewport testing"
```

---

## Résumé des changements

| Problème | Cause | Fix |
|---|---|---|
| Scrollbar horizontale sur tablette/mobile | `width: 750px` fixe sur `.topic-list-contents` | → `max-width: 100%` + `overflow-x: hidden` |
| Sidebar écrase la colonne sur écrans étroits | Flex row sans breakpoint | → `flex-direction: column` + `sidebar { display: none }` à ≤ 1024px |
| Thumbnail tronquée (ratio cassé) sur mobile | `height: 200px !important` | → `height: auto; object-fit: cover` |
| Images du corps de l'article débordent | Attributs `width` inline Discourse | → `.news-item-body img { max-width: 100%; height: auto }` |
