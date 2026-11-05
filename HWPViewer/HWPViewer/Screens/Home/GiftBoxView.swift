//
//  GiftBoxView.swift
//  HWPViewer
//
//  Gift box on Home (Figma 6764:101491, logic from NPI03): 3D gift 102×91 that wobbles every 2 s,
//  "mm:ss" countdown pill under it (black 55%, Medium 14 white, 20pt high), close button 28pt at the
//  top-right. Draggable around the screen. Tapping the gift opens the paywall.
//  - Countdown (remote `iap_configs.gift_box_countdown_time`): stops at 0 and the pill hides; the box
//    stays until the user closes it.
//  - Leaving Home or going to the background pauses it; coming back restarts it from the top.
//  - Closed (X / tapped) → not shown again until the next cold start.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

final class GiftBoxView: UIView {
    /// Closed or used during this run of the app (in memory: back after a cold start, kept when Home
    /// is rebuilt, e.g. after a language change).
    static var isDismissedThisSession = false

    let giftTapped = PassthroughSubject<Void, Never>()
    let closeTapped = PassthroughSubject<Void, Never>()
    let countdownEnded = PassthroughSubject<Void, Never>()

    private let giftButton = UIButton(type: .custom)
    private let closeButton = UIButton(type: .custom)
    private let timerPill = UIView()
    private let timerLabel = UILabel()
    private let initialSeconds: Int
    private var secondsLeft: Int
    private var timer: Timer?
    private var dragStart: CGPoint = .zero
    private var cancellables = Set<AnyCancellable>()

    init(seconds: Int) {
        initialSeconds = max(1, seconds)
        secondsLeft = initialSeconds
        super.init(frame: .zero)
        setupViews()
        bindActions()
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.pauseCountdown() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self, window != nil else { return }
                restartCountdown()
            }
            .store(in: &cancellables)
        updateLabel()
        startTimer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit { timer?.invalidate() }

    // MARK: - Layout (Figma group 108×139: close 28 at x 80, gift column 92 wide from y 26)

    private func setupViews() {
        giftButton.setImage(Asset.Assets.App.imgGiftBox.image.withRenderingMode(.alwaysOriginal), for: .normal)
        giftButton.adjustsImageWhenHighlighted = false
        giftButton.accessibilityLabel = "Gift"
        closeButton.setImage(Asset.Assets.App.icGiftClose.image.withRenderingMode(.alwaysOriginal), for: .normal)
        closeButton.accessibilityLabel = L10n.ocrClose

        timerPill.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        timerPill.layer.cornerRadius = 10
        timerLabel.font = AppFonts.medium(14)
        timerLabel.textColor = .white
        timerLabel.textAlignment = .center
        timerPill.addSubview(timerLabel)

        [giftButton, timerPill, closeButton].forEach(addSubview)
        snp.makeConstraints { $0.size.equalTo(CGSize(width: 108, height: 139)) }
        giftButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(26)
            make.centerX.equalTo(snp.leading).offset(46)
            make.size.equalTo(CGSize(width: 102, height: 91))
        }
        timerPill.snp.makeConstraints { make in
            make.top.equalTo(giftButton.snp.bottom).offset(2)
            make.centerX.equalTo(giftButton)
            make.height.equalTo(20)
        }
        timerLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(7)
        }
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.size.equalTo(28)
        }
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragged(_:))))
    }

    private func bindActions() {
        giftButton.tapPublisher
            .throttle(for: .seconds(0.35), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in self?.giftTapped.send() }
            .store(in: &cancellables)
        closeButton.tapPublisher
            .throttle(for: .seconds(0.35), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in self?.closeTapped.send() }
            .store(in: &cancellables)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startWobble() }
    }

    /// Shakes ±15° during the first 30% of a 2 s cycle, then rests.
    private func startWobble() {
        let angle = CGFloat.pi / 12
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [0, -angle, angle, -angle, angle, 0, 0]
        animation.keyTimes = [0, 0.06, 0.12, 0.18, 0.24, 0.3, 1]
        animation.duration = 2
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        giftButton.layer.add(animation, forKey: "wobble")
    }

    /// Drag anywhere inside the superview's safe area. Moves by `transform` (Auto Layout keeps the
    /// resting spot; `center` ignores the transform), clamped to the screen.
    @objc private func dragged(_ gesture: UIPanGestureRecognizer) {
        guard let superview else { return }
        if gesture.state == .began { dragStart = CGPoint(x: transform.tx, y: transform.ty) }
        let t = gesture.translation(in: superview)
        let halfW = bounds.width / 2, halfH = bounds.height / 2
        let insets = superview.safeAreaInsets
        let x = min(max(center.x + dragStart.x + t.x, halfW), superview.bounds.width - halfW)
        let y = min(max(center.y + dragStart.y + t.y, insets.top + halfH), superview.bounds.height - insets.bottom - halfH)
        transform = CGAffineTransform(translationX: x - center.x, y: y - center.y)
    }

    // MARK: - Countdown

    func pauseCountdown() {
        timer?.invalidate()
        timer = nil
    }

    func restartCountdown() {
        secondsLeft = initialSeconds
        timerPill.isHidden = false
        updateLabel()
        startTimer()
    }

    private func startTimer() {
        pauseCountdown()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        // .common: keeps counting while the user scrolls the list.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        secondsLeft -= 1
        updateLabel()
        guard secondsLeft <= 0 else { return }
        pauseCountdown()
        timerPill.isHidden = true
        countdownEnded.send()
    }

    private func updateLabel() {
        let seconds = max(0, secondsLeft)
        timerLabel.text = String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
