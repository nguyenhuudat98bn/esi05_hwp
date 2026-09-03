# Codebase summary – NovaProject (iOS base)

NovaProject là base UIKit cho các app Supernova. Từ 2026-09-03 phần dùng chung nằm ở Swift Package
`SPNComponent` (`~/Documents/Work/SPNComponent`, local reference `../../SPNComponent`).

```
NovaProject/NovaProject/
├── AppDelegate.swift              SDK init, SPNComponent.configure, SPNOnboardingCoordinator, lifecycle → ads
├── AppEnvironment/
│   ├── AppConstants.swift         URLs, Notification names, alias ApplicationSession = SPNSession, mainColor
│   ├── AppSecrets.swift           SPNAdSecret (AES key/iv giải mã ad unit) – đổi khi clone
│   ├── FirebaseRemoteConfigStore  : SPNRemoteConfigStore, fetch + defaults từ DefaultConfigs.json, IapConfigs
│   ├── AppTheme.swift             SPNTheme của app (primary theo appconfigs.main_color)
│   ├── OnboardingConfigs.swift    Skin cho Splash / PrepareAds / Language / Status / Intro
│   └── PaywallPresenter.swift     Bridge PurchaseViewController ↔ hook presentPaywall
├── ViewControllers/Home           HomeViewController: SPNBaseViewController
├── ViewControllers/Purchase       Paywall (VC/VM/UseCase/cells)
├── Managers/                      StoreKitManager, ReceiptValidator, TrackingManager (: SPNAnalyticsLogging), SKAN, Reminder
├── Extensions/PDFView+Ext.swift
├── Generated/                     SwiftGen (Assets, L10n) + NSCustomLocalizedString → String.localized (SPNCore)
└── Resources/                     Assets, Colors, Localizables (32 lang), DefaultConfigs.json, GoogleService-Info
```

Luồng khởi động: `SPNOnboardingCoordinator.start()` → `SPNSplashViewController` (`SPNLaunchFlow`: ATT → mạng → UMP →
remote config → AO/Inter → native preload) → Language → Status → Intro → paywall hook → Home.
Reopen: `coordinator.lifecycleHandler` (PrepareAds + AO `reopen_app`).

Chi tiết kiến trúc: `docs/spn-component-architecture-draft.md`; API package: `SPNComponent/README.md`, `USAGE.md`.

## Clone base thành app mới

```
scripts/clone-project.sh --name ScanPro --display-name "Scan Pro" --bundle-id com.spn.scanpro \
  --ad-key <32 ký tự> --ad-iv <16 ký tự> --admob-app-id ca-app-pub-…~… \
  [--dest ~/Documents/Work/scanpro] [--fb-app-id … --fb-client-token …] [--team-id …] \
  [--google-service GoogleService-Info.plist] [--spn-path ~/Documents/Work/SPNComponent] [--no-git]
```
Script copy repo (bỏ .git), đổi tên project/target/thư mục, bundle id, `ApplicationName` trong 32 lproj, `AppSecrets.swift`,
`GADApplicationIdentifier` + Facebook trong Info.plist, team id, đường dẫn local package SPNComponent, rồi `git init` + commit đầu.
Việc còn lại thủ công: GoogleService-Info.plist, DefaultConfigs.json (ad unit đã mã hoá theo key/iv mới), asset, strings, URL, product id IAP.
