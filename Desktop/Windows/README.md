# AirKeyboard Connect für Windows

Kostenlose Open-Source-Entwicklung benötigt weder Apple-Developer-Abo noch Signierdateien. Der Standardweg ist der öffentliche **Free simulator build and tests**-Workflow: Quellcode, Swift-Tests, Simulator-Build und Simulator-Ausführung auf einem Standard-macOS-Runner. Dieser Build ist keine iPhone-IPA.

## Windows-Helfer starten

`AirKeyboardConnect.exe` ist eine echte native .NET-Framework-Anwendung. Windows 10/11 mit .NET Framework 4.8 genügt für die Oberfläche. Python, Node, Xcode, Apple-Treiber oder ein Signierwerkzeug sind für das bloße Öffnen der Oberfläche und der öffentlichen CI-Seite nicht erforderlich.

- **Kostenlose Simulator-Builds öffnen:** öffnet die Actions-Seite des öffentlichen Repositories. Kein eigener Mac ist für den gehosteten Build nötig; der Simulator selbst läuft nicht auf Windows.
- **USB-Geräte prüfen:** sucht nach Apple-USB-Geräten und dem Apple Mobile Device Service. Dafür sind passende Apple-Treiber nötig. Das bestätigt keine Gerätefreigabe oder Installation.
- **Vorhandene Geräte-IPA prüfen:** optionaler Weg, falls bereits eine echte Geräte-IPA vorhanden ist. Der Helfer prüft ZIP-Pfade/Größen und die ARM64-iOS-Programme für App, Tastatur und Widgets. Er prüft keine Apple-Provisionierung und erzeugt keine IPA.
- **Sideloadly starten:** optionaler, benutzergesteuerter Übergang zu einem separat installierten externen Signierer. Die geprüfte IPA kann vom Dateifeld in dessen Fenster gezogen werden. Apple-Login und der tatsächliche Installationsstart erfolgen dort. Der Helfer speichert keine Zugangsdaten und meldet den externen Vorgang nicht als erfolgreich.

Sideloadly ist keine Pflichtabhängigkeit der Entwicklung und wird nicht mitgeliefert. Falls du diesen Geräteweg ausprobierst, nutze dessen offizielle Seite und aktuelle Anleitung. Behalte beide Erweiterungen. Free-Account-Unterstützung eines Signierers beweist nicht, dass AirKeyboard inklusive App Groups funktioniert. Kein Kauf eines Apple-Abos wird vorausgesetzt oder empfohlen.

## Lokal bauen und testen

```powershell
powershell -NoProfile -File .\Desktop\Windows\Build.ps1
$exe = (Resolve-Path .\Desktop\Windows\dist\AirKeyboardConnect.exe).Path
$report = Join-Path $env:TEMP 'AirKeyboard-self-test.txt'
$process = Start-Process -FilePath $exe -ArgumentList @('--self-test', ('"' + $report + '"')) -WindowStyle Hidden -Wait -PassThru
Get-Content -LiteralPath $report
if ($process.ExitCode -ne 0) { throw 'Tests failed' }
```

Keine NuGet-Pakete. Sieben ausgeführte Tests verwenden synthetische ZIP/Mach-O-Dateien in temporären Verzeichnissen. Diese sind keine installierbaren Apps und werden nicht ausgeliefert. Die kostenlose Xcode-/Personal-Team-Möglichkeit, lokale Einstellungen ohne App Groups und die Grenzen stehen in `Documentation/FREE-DEVELOPMENT.md`.
