# Device Verification – v0.1.0

**Simulator-only. Device verification pending.**

Diese Checkliste dokumentiert echte Prüfungen auf einem physischen iPhone. Alle Punkte beginnen offen; ein Simulator-Ergebnis oder erfolgreicher Quellcode-Build erfüllt keinen Gerätepunkt. Ein Häkchen erst setzen, wenn Gerät, iOS-Version, Datum und reproduzierbarer Nachweis eingetragen sind. Für mehrere Geräte die Tabelle pro Gerät kopieren.

Release: [v0.1.0 – Simulator Foundation](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/releases/tag/v0.1.0) · Quellcode: `b36f4be17d2c4abf4d62ab304f3a3cef157afaf7`.

## Durchführung

Tester/in: _offen_  
Getesteter Commit / Build: _offen_  
Signierung / tatsächlich verfügbare Entitlements: _offen_

Vollständige Matrix und kostenlose Möglichkeiten: [Testanleitung](../Documentation/TESTING.md), [kostenlose Entwicklung](../Documentation/FREE-DEVELOPMENT.md). Keine Zertifikate, Profile, Zugangsdaten oder persönlichen Eingaben in Nachweise aufnehmen.

## Abhakbare Prüfungen

| Prüfung | Status | Gerät | iOS-Version | Datum | Notiz |
| --- | --- | --- | --- | --- | --- |
| Signierter Geräte-Build | ⏳ Offen | — | — | — | Gültige eigene Signierung; Build, Installation und Start auf Hardware nachweisen. |
| Tastatur aktiviert | ⏳ Offen | — | — | — | In Einstellungen hinzufügen, über Globe auswählen; Verhalten ohne/mit tatsächlich gewährtem Full Access getrennt festhalten. |
| Tippen in Safari | ⏳ Offen | — | — | — | Normales Textfeld: Zeichen, Leerzeichen, Shift, Löschen, Layoutwechsel; sichere iOS-Felder separat notieren. |
| Tippen in Messages | ⏳ Offen | — | — | — | Entwurf ohne Versand: Eingabe, Löschen, Return und Wechsel zur Systemtastatur. |
| Tippen in Notizen | ⏳ Offen | — | — | — | Mehrzeilige Eingabe und Wiederaufnahme nach App-Wechsel. |
| Sound-Packs | ⏳ Offen | — | — | — | Jedes enthaltene Pack und Silent; App-Vorschau, Tastatur, Mute, Lautstärke, Audio-Route und Full Access prüfen. |
| Haptik | ⏳ Offen | — | — | — | Tatsächlich unterstütztes Verhalten und Systemeinstellungen prüfen; fehlende Unterstützung als nicht unterstützt dokumentieren. |
| App Group / Widget | ⏳ Offen | — | — | — | Tatsächliche Entitlements und gemeinsame Theme-/Sound-Präferenz über Prozessgrenzen; ohne App Group getrennten lokalen Modus festhalten. |
| App Group / Control Center | ⏳ Offen | — | — | — | Verfügbaren Control hinzufügen, Einstellung ändern, Rückwirkung im Host/Tastatur prüfen; OS-/Entitlement-Grenzen dokumentieren. |
| Accessibility – VoiceOver | ⏳ Offen | — | — | — | Fokusfolge, verständliche Labels, Editor, Vorschau und Tastatur bedienen. |
| Accessibility – Dynamic Type | ⏳ Offen | — | — | — | Kleine bis größte Accessibility-Schrift; lesbare Inhalte und erreichbare Bedienelemente. |
| Accessibility – Reduce Motion | ⏳ Offen | — | — | — | Reduzierte Bewegung aktivieren; Animationen und Bedienbarkeit prüfen. |
| Performance | ⏳ Offen | — | — | — | Startzeit, Eingabelatenz, schnelles längeres Tippen, Speicher und Prozess-Neustart mit Messmethode festhalten. |

- [ ] Signierter Geräte-Build installiert und gestartet
- [ ] Tastatur aktiviert und auswählbar
- [ ] Tippen in Safari geprüft
- [ ] Tippen in Messages geprüft (kein Versand nötig)
- [ ] Tippen in Notizen geprüft
- [ ] Sound-Packs und Silent geprüft
- [ ] Haptik geprüft oder fehlende Unterstützung mit Grund dokumentiert
- [ ] App Group mit Widget geprüft
- [ ] App Group mit Control Center geprüft
- [ ] VoiceOver geprüft
- [ ] Dynamic Type geprüft
- [ ] Reduce Motion geprüft
- [ ] Performance mit Messwerten dokumentiert

## Statusregeln und Nachweise

`⏳ Offen`, `✅ Bestanden`, `❌ Fehlgeschlagen`, `🚫 Blockiert` oder `— Nicht unterstützt` verwenden. Blockiert/nicht unterstützt sind keine erfolgreichen Tests. Bei Fehlern Reproduktion und Issue verlinken; offene Punkte nicht pauschal abhaken. Screenshots/Logs müssen den geprüften Build und das Datum erkennen lassen und frei von privaten Inhalten sein. Es gibt hier noch keine bestätigten Hardware-Ergebnisse.
