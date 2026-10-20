import AVFoundation

/// All files are prepared on a background task. Keypress playback never opens a file.
@MainActor final class SoundEngine {
    private var players: [SoundPack: AVAudioPlayer] = [:]
    private(set) var failure: String?
    private var active: AVAudioPlayer?
    private var sessionActive = false
    private var observers: [NSObjectProtocol] = []
    init() {
        for name in [AVAudioSession.interruptionNotification, AVAudioSession.routeChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.stop(); self?.sessionActive = false }
            })
        }
    }
    deinit { for token in observers { NotificationCenter.default.removeObserver(token) } }
    func prepare() async {
        let assets: [(SoundPack, Data)] = await Task.detached(priority: .utility) {
            SoundPack.allCases.compactMap { pack in
                guard pack != .silent,
                      let url = Bundle.main.url(forResource: pack.rawValue, withExtension: "wav"),
                      let data = try? Data(contentsOf: url) else { return nil }
                return (pack, data)
            }
        }.value
        do {
            // prepareToPlay itself activates the session. Configure mixing/mute behavior first.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            for (pack, data) in assets {
                let player = try AVAudioPlayer(data: data)
                if !player.prepareToPlay() { failure = "Audio could not be prepared. Playback may be unavailable." }
                players[pack] = player
            }
            if assets.count != 4 { failure = "Some sound assets are missing. Unavailable packs stay silent." }
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionActive = false
        } catch { failure = "Audio preparation failed: \(error.localizedDescription)" }
    }
    @discardableResult func play(_ preferences: SoundPreferences) -> Bool {
        guard preferences.audible else { stop(); return true }
        guard let player = players[preferences.pack] else { failure = "Sound asset unavailable."; return false }
        do {
            if !sessionActive {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                sessionActive = true
            }
            active?.pause()
            player.currentTime = 0
            player.volume = Float(preferences.volume * preferences.intensity)
            active = player
            let played = player.play()
            if !played { failure = "The audio session could not start playback." }
            return played
        } catch { failure = "Audio unavailable: \(error.localizedDescription)"; return false }
    }
    func stop() { active?.stop(); active = nil }
    func releaseResources() {
        stop()
        players.removeAll()
        sessionActive = false
        do { try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        catch { failure = "Audio session could not deactivate: \(error.localizedDescription)" }
    }
}
