# Changelog

## v0.1.0 – Simulator Foundation

> **Simulator-only. Device verification pending.**

Status: Release-Entwurf; noch keine veröffentlichte Geräteversion.

Aktueller Nachweis: [Lauf #20](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39634992350), Commit `f17568818222115c671249bb2612e3ebff38f5d6`: alle drei CI-Jobs grün, einschließlich des erweiterten Studio-UI-Tests (66,154 Sekunden). Gebaut mit Simulator-SDK 18.5; ausgeführt auf iPhone SE (3. Generation), Runtime iOS 26.2. SDK- und Laufzeitversion sind getrennt dokumentiert. Der Draft bleibt unveröffentlicht.

### Foundation

- Native SwiftUI-App mit Theme-Studio, sechs eigenen Themes, JSON-Import/-Export und lokaler Bibliothek.
- UIKit-Tastatur, vier eigene Sound-Packs plus Silent, WidgetKit und unterstützter Control-Center-Sound-Schalter.
- Getrennte lokale Speicherung ohne App Group; gemeinsame Gerätefähigkeiten werden nicht vorgetäuscht.
- MIT-Lizenz, keine neuen Drittanbieter-Abhängigkeiten und kein obligatorischer Backend-/Cloud-Dienst.

### Verifikation und CI

- Erfolgreicher [Lauf #17](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39623141955): Simulator-Build aller Produkte, 16 Core-XCTest-Fälle auf Mac und Simulator sowie ein realer App-UI-Speicher-/Neustart-Test.
- Standard-ARM64-Runner mit Xcode 16.4, CoreSimulator-Wake-up, separatem YAML-Boot, `-collect-test-diagnostics never`, Befehlslimits und 25-Minuten-Joblimit. Der bereits verifizierte ARM64-Fallback bleibt erhalten; macos-14 läuft am 2026-11-02 aus.
- Echte Simulator-App, Logs und XCTest-Ergebnisse als kurzlebige CI-Artefakte; niemals als iPhone-IPA bezeichnet.

### Open-Source-Auftritt

- Scanbares README mit eigenem Logo-Platzhalter, dynamischen Shields.io-Badges, Feature- und Verification-Tabellen, Quick Start und aufklappbaren Details.
- Eindeutig markierter `assets/demo.gif`-Platzhalter und echte, unveränderte Studio-Aufnahme aus dem bestandenen CI-Lauf #20 in `assets/theme-studio.png`. Der Generator schützt vorhandene Aufnahmen. Vorläufiges Logo aus dem eigenen App-Icon; Herkunft und Hashes dokumentiert.
- Bug-/Feature-Vorlagen, PR-Checkliste und Good-First-Issue-Einstieg.

### Theme-Studio-Polish

- Sofortige Theme-Vorschau bleibt direkt an den Editor-State gebunden; kein manueller Reload.
- Lokaler Hell/Dunkel-Vorschaukontext mit SF-Symbolen und abgerundetem Rahmen. Er verändert weder das gespeicherte Theme noch seine Palette; die bestehende Appearance-Auswahl bleibt erhalten.
- Bestehender realer UI-Workflow prüft zusätzlich beide Schalterstellungen und legt eine echte Studio-Aufnahme im XCTest-Ergebnis ab. Die UI-Prüfung trifft die Schalterfläche relativ zum Accessibility-Element statt die Zeilenmitte und wartet begrenzt auf den tatsächlichen Wert. Der erste erweiterte Lauf deckte eine unzuverlässige Tap-Zielwahl auf; fehlgeschlagene Läufe bleiben in Actions sichtbar. Beide Zustandswechsel sowie Speichern/Neustart wurden anschließend in Lauf #20 erfolgreich geprüft.

### Vor Gerätefreigabe offen

- Physisches iPhone, gültige Gerätesignierung/Installation und echte Host-Eingaben.
- Hörbares Audio, Full-Access-/Mute-Verhalten und Latenz auf Hardware.
- App Group, Widgets und Control Center im tatsächlichen Cross-Process-Betrieb.
- Accessibility-Matrix auf Geräten. Keine installierbare IPA oder Geräte-Reife versprochen.
