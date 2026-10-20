# AirKeyboard Connect für Windows

Eine eigenständige native Windows-Oberfläche für den AirKeyboard-Installationsablauf. Keine Python-, Node- oder Xcode-Installation auf deinem Windows-PC erforderlich. Benötigt Windows 10/11 mit .NET Framework 4.8, Apple-Gerätetreiber und separat installiertes Sideloadly. Sideloadly und Apple-Software werden nicht mitgeliefert.

## Start

1. Starte `AirKeyboardConnect.exe` aus dem Windows-Paket.
2. Verbinde das iPhone per USB, entsperre es und bestätige „Vertrauen“. „USB-Geräte prüfen“ zeigt Apple-USB-Erkennung und den Status des Apple Mobile Device Service. Das bestätigt weder die Gerätefreigabe noch eine erfolgreiche Installation.
3. Wähle eine `AirKeyboard.ipa`. Alternativ öffne mit `Besitzer/Repository` den GitHub-Workflow **iPhone package** und lade nach einem erfolgreichen Lauf das Artefakt herunter und entpacke es. Die IPA muss zuerst auf einem macOS-Buildserver gebaut werden. Es ist kein eigener Mac nötig. Die Quellcode-ZIP ist keine IPA.
4. Der Helfer prüft Paketpfade, Größen und die drei ARM64-iOS-Programme für App, Tastatur und Widgets. Signaturen/Provisioning werden dadurch nicht verifiziert.
5. Installiere Sideloadly nur von [sideloadly.io](https://sideloadly.io/), starte es über den Helfer und ziehe die geprüfte IPA vom dunklen Dateifeld in dessen Fenster. Falls nötig, wähle deine installierte `Sideloadly.exe` über den Dateidialog aus.
6. Wähle in Sideloadly dein iPhone und gib dort deinen Apple-Account ein. Behalte die Tastatur- und Widget-Erweiterungen; verwende keine Optionen zum Entfernen von Erweiterungen oder Verändern der Mindest-iOS-Version. Starte die Signierung/Installation in Sideloadly. Der Helfer speichert keine Zugangsdaten und meldet den externen Vorgang nicht als erfolgreich.
7. Aktiviere gegebenenfalls den Entwicklermodus und vertraue dem Entwicklerprofil gemäß der aktuellen Installationsanleitung des Signierwerkzeugs. Öffne AirKeyboard auf dem iPhone, füge die Tastatur in Einstellungen → Allgemein → Tastatur hinzu und wähle sie über die Globus-Taste.

Eigene Töne brauchen optionalen Tastatur-Vollzugriff. Gemeinsame Themes und die Systemsteuerung brauchen App-Group-Berechtigungen, die für alle drei Komponenten konsistent provisioniert sein müssen. Ob der verwendete Sideload-Signer diese korrekt erhält/zuordnet, muss am Gerät geprüft werden. Der unsignierte Build ist allein nicht installierbar. Ohne passende Berechtigungen sind geteilte Einstellungen nicht garantiert; das ist keine erfolgreiche Vollinstallation.

## Selbst bauen und testen

```powershell
powershell -NoProfile -File .\Desktop\Windows\Build.ps1
$exe = (Resolve-Path .\Desktop\Windows\dist\AirKeyboardConnect.exe).Path
$report = Join-Path $env:TEMP 'AirKeyboard-self-test.txt'
$process = Start-Process -FilePath $exe -ArgumentList @('--self-test', ('"' + $report + '"')) -WindowStyle Hidden -Wait -PassThru
Get-Content -LiteralPath $report
if ($process.ExitCode -ne 0) { throw 'Tests failed' }
```

Der C#-Compiler aus dem .NET Framework wird verwendet; keine NuGet-Pakete. Sieben Tests prüfen echte ZIP/Mach-O-Auswertung mit synthetischen Testdateien. Diese sind ausdrücklich keine echten iPhone-Apps und werden nicht als Installationsdateien ausgeliefert. Keine Installation/Signierung wurde am Gerät getestet. Der Quellcode ist MIT-lizenziert; externe Tools haben eigene Lizenzen.
