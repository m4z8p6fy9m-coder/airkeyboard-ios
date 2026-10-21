# Häufige Fragen

## Warum keine Cloud?

Themes und Einstellungen sollen lokal und ohne Konto, Abo oder Backend funktionieren. Die iOS-App enthält keinen Netzwerkclient und speichert keine Tastatureingaben. Dateiexporte erfolgen bewusst über den eigenen Files-/Teilen-Workflow. GitHub dient Quellcode und Entwicklung, nicht als Tastatur-Backend. Ein unabhängiger Datenschutz-Audit ist offen; siehe [SECURITY.md](../SECURITY.md).

## Warum Simulator-first?

Öffentliche GitHub-Runner erlauben Xcode-Builds und Simulator-Tests ohne Gerätezertifikate oder bezahlten Apple-Account. Das schafft überprüfbare Entwicklungsbelege. Es beweist keine Installation, Audioausgabe oder App-Group-Funktion auf einem iPhone. [v0.1.0](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/releases/tag/v0.1.0) ist ein Simulator-Pre-release; keine installierbare iPhone-IPA ist bereitgestellt. Kostenlose lokale Wege und Grenzen stehen in [FREE-DEVELOPMENT.md](../Documentation/FREE-DEVELOPMENT.md).

## Wie aktiviere ich die Tastatur?

Voraussetzung ist eine tatsächlich installierte App samt Tastaturerweiterung. Diese Anleitung ist kein bereits bestandener Geräte-Test:

1. **Einstellungen → Allgemein → Tastatur → Tastaturen → Tastatur hinzufügen** öffnen.
2. **AirKeyboard** auswählen, sofern die installierte Erweiterung angeboten wird.
3. In einem unterstützten Textfeld die **Globe-Taste** gedrückt halten und AirKeyboard wählen.

Full Access für normales Tippen ausgeschaltet lassen. Nur bei Bedarf an den optionalen Zusatzfunktionen bewusst aktivieren; Tastaturtöne sind im Code daran gebunden. Gemeinsame Themes benötigen zusätzlich eine wirklich provisionierte App Group. Ohne diese bleibt die Tastatur im lokalen Modus. Hardware-Verhalten ist noch zu prüfen.

Sichere Textfelder verwenden die Systemtastatur; manche Apps erlauben keine fremden Tastaturen. Das ist eine iOS-Grenze, kein Anlass für einen Umgehungsversuch. [Apple: Custom Keyboard Interface](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface).

## Was fehlt noch?

Ein realer iPhone-Test einschließlich signiertem Build, Installation und Eingaben in Safari, Messages und Notizen. Außerdem sind Sound/Mute/Full Access, App Group mit Widgets/Control Center, Haptik-Unterstützung, VoiceOver, Dynamic Type, Reduce Motion und Performance auf Hardware offen. Der bestandene Simulator-UI-Test prüft Studio-Vorschau und Theme-Persistenz, nicht diese Geräteeigenschaften.

Die [Device-Checkliste](Device-Verification.md) enthält die offenen Nachweise. Wortvorhersage, zusätzliche Theme-Galerie, Lokalisierung und weitere Layouts stehen nur als **geplant, nicht zugesagt** in der [Roadmap](../ROADMAP.md).

## Reicht Full Access als Sicherheitsnachweis?

Nein. Es erweitert die Sandbox, obwohl AirKeyboard die zusätzlichen Netzwerkfähigkeiten nicht nutzt. Quellcode und Herkunft des installierten Builds bleiben relevant. [Sicherheitsmodell und Meldeweg](../SECURITY.md); eine unabhängige Prüfung steht aus.
