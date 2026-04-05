# Habit Tracker

Ein moderner Flutter Habit-/Todo-Tracker mit Datumsnavigation, Unterpunkten, Kategorien und lokalem Storage.

## Features

- Datumsbasierte Todo-Ansicht (Tag fuer Tag)
- Horizontaler Date-Selector mit Today-Indikator
- Todos mit optionalem Faelligkeitsdatum
- Unterpunkte pro Todo (inkl. Progress)
- Kategorien mit Icon und Farbe
- Status-Logik (`open`, `done`, `skipped`)
- Swipe-to-delete fuer Todos
- Dark/Light Theme Umschaltung
- Persistente lokale Speicherung (JSON auf dem Geraet)

## Tech Stack

- Flutter
- Dart
- `path_provider` fuer lokale Dateipfade

## Projekt starten

### Voraussetzungen

- Flutter SDK installiert
- Android Studio / IntelliJ oder VS Code
- Ein Emulator oder physisches Geraet

### Installation

```bash
flutter pub get
```

### App starten

```bash
flutter run
```

### Qualitaetschecks

```bash
flutter analyze
flutter test
```

## Projektstruktur

```text
lib/
  data/
    local_store.dart          # Persistenz + Business-Logik
  models/
    habit_item.dart
    subtask_model.dart
    category.dart
  screens/
    categories_page.dart
    category_picker_sheet.dart
    subtasks_sheet.dart
    subtasks_modal.dart
    subtask_editor_sheet.dart
  ui/
    icon_registry.dart
  main.dart                   # App-Entry + Haupt-UI
```

## Kernkonzepte

### Todo-Status

Ein Todo kann einen der folgenden Stati haben:

- `open`: offen
- `done`: erledigt
- `skipped`: uebersprungen

Die Statuswechsel werden zentral in `LocalStore` verwaltet.

### Unterpunkte

Unterpunkte koennen beim Erstellen eines Todos oder spaeter in der Detailansicht gepflegt werden:

- Hinzufuegen
- Umordnen
- Erledigen/abhaeken
- Loeschen

### Kategorien

Kategorien sind optional und enthalten:

- Name
- Farbe
- Icon-Key

Beim Loeschen einer Kategorie werden verknuepfte Todos automatisch entkoppelt.

## Datenhaltung

Alle Daten werden lokal gespeichert. Es gibt aktuell keine Cloud-Synchronisierung.

Beispielhafte gespeicherte Felder:

```json
{
  "id": 1,
  "name": "Workout",
  "dueDate": "2026-04-05",
  "status": "open",
  "categoryId": 2,
  "subtasks": [
    { "id": 1, "title": "Warm-up", "isDone": true },
    { "id": 2, "title": "Core", "isDone": false }
  ]
}
```

## Screenshots

Lege Screenshots unter `assets/screenshots/` ab und verlinke sie hier:

```md
![Home](assets/screenshots/home.png)
![Todo erstellen](assets/screenshots/create-todo.png)
```

## Roadmap (optional)

- Erinnerungen/Notifications
- Wiederkehrende Habits
- Export/Import
- Cloud Sync

## Lizenz

Private Nutzung / Projektstatus nach Bedarf anpassen.
