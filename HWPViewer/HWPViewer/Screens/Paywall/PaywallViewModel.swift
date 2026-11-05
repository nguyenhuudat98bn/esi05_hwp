//
//  PaywallViewModel.swift
//  HWPViewer
//
//  Paywall state: products for the plan cards, a busy flag for the HUD while the store works, and
//  toast messages. Premium itself is switched on by PurchaseService, which posts
//  `actionWhenPurchaseCompleted` — the paywall dismisses on that notification, not on anything here.
//

import Foundation
import Combine
import StoreKit
import SPNComponent

final class PaywallViewModel: ViewModelType {
    struct Input {
        let load: AnyPublisher<Void, Never>
        let buy: AnyPublisher<String, Never>
        let restore: AnyPublisher<Void, Never>
    }

    final class Output: ObservableObject {
        /// nil until the store answers; stays nil if loading failed (a toast says why).
        @Published var products: [PaywallProduct]?
        @Published var isBusy: Bool?
        @Published var message: String?
    }

    private let useCase: PaywallUseCase
    private var cancellables = Set<AnyCancellable>()
    /// Store calls in flight; the HUD masks the screen so they rarely overlap, but the flag stays
    /// right if they do.
    private var callsInFlight = 0

    init(useCase: PaywallUseCase) {
        self.useCase = useCase
    }

    /// The sinks hold `output` strongly: the screen keeps only the `$products` / `$isBusy` / `$message`
    /// publishers, which do not retain it. With a weak capture `output` was gone as soon as `bind()`
    /// returned — load, buy and restore all silently did nothing (no prices, dead buttons).
    func transform(_ input: Input) -> Output {
        let output = Output()

        input.load
            .sink { [weak self] in
                guard let self else { return }
                self.run(output) { output in
                    do {
                        output.products = try await self.useCase.loadProducts()
                    } catch {
                        logger("[Paywall] products failed: \(error)")
                        output.message = error.localizedDescription
                    }
                }
            }
            .store(in: &cancellables)

        input.buy
            .sink { [weak self] productID in
                guard let self else { return }
                self.run(output) { output in
                    do {
                        // purchased → PurchaseService turns premium on and the paywall dismisses;
                        // pending → the App Store finishes it later; cancelled → nothing to say.
                        _ = try await self.useCase.buy(productID: productID)
                    } catch {
                        output.message = L10n.purchaseFailedMessage
                    }
                }
            }
            .store(in: &cancellables)

        input.restore
            .sink { [weak self] in
                guard let self else { return }
                self.run(output) { output in
                    do {
                        let isPremium = try await self.useCase.restore()
                        if !isPremium {
                            output.message = L10n.purchaseRestoreNothingMessage
                        }
                    } catch StoreKitError.userCancelled {
                        // Closed the App Store sign-in sheet.
                    } catch {
                        logger("[Paywall] restore failed: \(error)")
                        output.message = L10n.purchaseFailedMessage
                    }
                }
            }
            .store(in: &cancellables)

        return output
    }

    private func run(_ output: Output, _ work: @escaping @MainActor (Output) async -> Void) {
        Task { @MainActor in
            callsInFlight += 1
            output.isBusy = true
            await work(output)
            callsInFlight -= 1
            output.isBusy = callsInFlight > 0
        }
    }
}
