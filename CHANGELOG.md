# Changelog

## v0.1.0 – Simulator Foundation

> **Simulator-only. Device verification pending.**

Status: Release-Entwurf; noch keine veröffentlichte Geräteversion.

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
- Eindeutig markierte `assets/demo.gif`- und `assets/theme-studio.png`-Platzhalter; keine simulierten Produktaufnahmen. Vorläufiges Logo aus dem eigenen App-Icon; Herkunft in ASSETS.md.
- Bug-/Feature-Vorlagen, PR-Checkliste und Good-First-Issue-Einstieg.

### Vor Gerätefreigabe offen

- Physisches iPhone, gültige Gerätesignierung/Installation und echte Host-Eingaben.
- Hörbares Audio, Full-Access-/Mute-Verhalten und Latenz auf Hardware.
- App Group, Widgets und Control Center im tatsächlichen Cross-Process-Betrieb.
- Accessibility-Matrix auf Geräten. Keine installierbare IPA oder Geräte-Reife versprochen.
