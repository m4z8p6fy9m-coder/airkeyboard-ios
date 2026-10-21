# Sicherheitsrichtlinie

Stand: 21.10.2026. **Simulator-only. Device verification pending.**

## Schwachstellen melden

Bevorzugter Meldeweg ist ein privater Bericht über [GitHub Security Advisories](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/security/advisories): **Security → Report a vulnerability**, sobald private Meldungen verfügbar sind.

**Aktuelle Lücke:** Am 21.10.2026 zeigt GitHub „Private vulnerability reporting: Disabled“. Maintainer können Advisories verwalten; externe private Meldungen sind damit noch nicht eingerichtet. Empfehlung: Private Vulnerability Reporting aktivieren. Diese Dokumentationsänderung aktiviert keine Einstellung und eröffnet keinen privaten Kontakt.

Solange der Meldebutton fehlt, nur mit einem inhaltsarmen öffentlichen Issue um einen privaten Meldeweg bitten. Keine ausnutzbaren Details, Eingaben oder Geheimnisse öffentlich posten. Es gibt derzeit keine veröffentlichte private Maintainer-Adresse. Für GitHub-Nutzer-Missbrauch stehen GitHubs eigene Meldefunktionen zur Verfügung.

Ein vertraulicher Bericht sollte betroffenen Commit/Version, Gerät und iOS-Version, Full-Access-/App-Group-Status, erwartetes/tatsächliches Verhalten und eine minimale Reproduktion mit synthetischen Daten enthalten. Keine echten Tastatureingaben, Schlüssel, Zertifikate oder Profile anhängen. Rückmeldung, Behebung und koordinierte Veröffentlichung erfolgen nach verfügbarer Kapazität; keine garantierte Reaktionszeit oder unabhängige Prüfung zugesagt.

## Unterstützte Versionen

| Stand | Behandlung von Sicherheitsmeldungen | Verifikationsgrenze |
| --- | --- | --- |
| v0.1.0 / 0.1.x | Aktuelles Pre-release; Meldungen werden zur Prüfung angenommen, kein langfristiger Backport- oder Supportvertrag | Simulator-Nachweise vorhanden; physisches Gerät und Sicherheitsaudit offen |
| main | Entwicklungsstand; Meldungen zum genauen Commit willkommen | Kann unveröffentlichte Änderungen enthalten |
| Ältere Entwicklungsstände / fremde Builds | Keine gesonderte Pflege zugesagt | Herkunft und Unterschiede müssen geprüft werden |

Das ist keine Zusage, dass ungeprüfte Geräte-Builds sicher oder produktionsreif sind. [Verifikation](Docs/Device-Verification.md).

## Bedrohungsmodell und Verhalten

- **Eingaben sind sensibel:** Die aktive Tastatur verarbeitet alle über ihre Tasten eingegebenen Zeichen und kann den von iOS freigegebenen Textkontext lesen. Im Quellcode wird Kontext kurzzeitig zur Großschreibung verwendet. Sie sieht nicht pauschal sämtliche Eingaben auf dem Gerät: sichere Textfelder nutzen die Systemtastatur; Host-Apps können fremde Tastaturen sperren. Siehe [Apples Tastaturgrenzen](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface).
- **Keine Netzwerkkommunikation im iOS-Code vorgesehen:** Kein Backend, Telemetrie, Eingabeverlauf oder Netzwerkclient; eingegebener Text wird weder gespeichert noch protokolliert oder übertragen. Das beschreibt den geprüften Quellcode, keinen unabhängigen Laufzeit-Audit. Host-App, iOS und selbst veränderte Distributionen liegen außerhalb dieser Zusage. GitHub/Browser-Zugriffe des separaten Windows-Helfers sind keine Tastatur-Netzwerkfunktion.
- **Full Access nur bei Bedarf:** Tippen funktioniert ohne die Freigabe. Optionale eigene Tastaturtöne sind im Code daran gebunden; App-Group-Nutzung benötigt tatsächliche Berechtigungen. Full Access erweitert die Sandbox einschließlich möglicher Netzwerkfähigkeiten, die AirKeyboard nicht nutzt. Nur aktivieren, wenn die Zusatzfunktion gebraucht wird; kein Datenschutz-Siegel. [Apple: Open Access](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard).
- **Speichergrenzen:** Die private Bibliothek enthält Themes/Favoriten; die App Group nur aktives Theme und Sound-Präferenzen samt Wiederherstellungskopie. Ohne verfügbare App Group bleiben Sandboxes getrennt. Importe sind begrenztes, validiertes JSON ohne ausführbare Inhalte oder nachladbare Assets. Fehlerhafte Pakete, manipulierte Einstellungen und falsche Entitlements sind relevante Angriffsflächen.
- **Offen:** Geräte-Sandbox und Full Access an/aus, Dateischutz, Import-Fuzzing, Cross-Process-Verhalten, Audio und unabhängige Sicherheitsprüfung. Erfolgreiche Simulator-Tests ersetzen diese Prüfungen nicht.

## Privacy-Manifest geprüft

[Resources/PrivacyInfo.xcprivacy](Resources/PrivacyInfo.xcprivacy) ist vorhanden und als plist lesbar. Es deklariert `NSPrivacyTracking = false`, keine gesammelten Datentypen und UserDefaults mit Begründung `CA92.1`. Xcode-Projekt und Generator referenzieren es als Ressource für App, Tastatur und Widgets. Die Datei wurde nicht geändert.

Offene Empfehlung vor einer Geräte-/Store-Freigabe: tatsächliche API-Nutzung, passende Begründungen und Manifest-Inhalt in jedem gebauten Bundle erneut prüfen. Die vorhandene Deklaration ist kein Beleg für einen abgeschlossenen Datenschutz-Audit oder Store-Akzeptanz. Weitere Details: [Datenschutzmodell](Documentation/PRIVACY.md).
