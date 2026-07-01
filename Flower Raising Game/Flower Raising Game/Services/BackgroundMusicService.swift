import AVFoundation
import Combine
import Foundation

struct BackgroundMusicTrack: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let fileName: String
    let fileExtension: String
}

@MainActor
final class BackgroundMusicService: ObservableObject {
    static let availableTracks = [
        BackgroundMusicTrack(
            id: "rainy_season",
            title: "雨の日の庭",
            subtitle: "しっとり落ち着くBGM",
            fileName: "Rainy_Season",
            fileExtension: "mp3"
        ),
        BackgroundMusicTrack(
            id: "flying_birds",
            title: "小鳥の朝",
            subtitle: "軽く明るいBGM",
            fileName: "flying_birds",
            fileExtension: "mp3"
        ),
        BackgroundMusicTrack(
            id: "breeze_hometown",
            title: "そよ風の故郷",
            subtitle: "やさしく穏やかなBGM",
            fileName: "そよ風の故郷",
            fileExtension: "mp3"
        )
    ]

    @Published private(set) var isEnabled: Bool
    @Published private(set) var selectedTrack: BackgroundMusicTrack

    private let isEnabledKey = "backgroundMusic.isEnabled"
    private let selectedTrackIDKey = "backgroundMusic.selectedTrackID"
    private let userDefaults: UserDefaults
    private var player: AVAudioPlayer?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if userDefaults.object(forKey: isEnabledKey) == nil {
            userDefaults.set(true, forKey: isEnabledKey)
        }

        self.isEnabled = userDefaults.bool(forKey: isEnabledKey)
        let savedTrackID = userDefaults.string(forKey: selectedTrackIDKey)
        self.selectedTrack = Self.availableTracks.first { $0.id == savedTrackID } ?? Self.availableTracks[0]
        preparePlayer()
    }

    var tracks: [BackgroundMusicTrack] {
        Self.availableTracks
    }

    func startIfEnabled() {
        guard isEnabled else {
            return
        }

        play()
    }

    func pause() {
        player?.pause()
    }

    func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        userDefaults.set(isEnabled, forKey: isEnabledKey)

        if isEnabled {
            play()
        } else {
            pause()
        }
    }

    func toggle() {
        setEnabled(!isEnabled)
    }

    func selectTrack(_ track: BackgroundMusicTrack) {
        guard selectedTrack != track else {
            return
        }

        player?.stop()
        player = nil
        selectedTrack = track
        userDefaults.set(track.id, forKey: selectedTrackIDKey)
        preparePlayer()

        if isEnabled {
            play()
        }
    }

    private func preparePlayer() {
        guard let url = Bundle.main.url(forResource: selectedTrack.fileName, withExtension: selectedTrack.fileExtension) else {
            assertionFailure("Missing background music file: \(selectedTrack.fileName).\(selectedTrack.fileExtension)")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.17
            player.prepareToPlay()
            self.player = player
        } catch {
            assertionFailure("Failed to prepare background music: \(error.localizedDescription)")
        }
    }

    private func play() {
        if player == nil {
            preparePlayer()
        }

        player?.play()
    }
}
