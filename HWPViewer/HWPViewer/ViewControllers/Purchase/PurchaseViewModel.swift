//
//  PurchaseViewModel.swift
//  HWPViewer
//
//  Created by Eragon on 25/8/25.
//

import SPNComponent
import Foundation
import Combine

class PurchaseViewModel {
    private let useCase: PurchaseUseCase
    private var cancellables = Set<AnyCancellable>()
    
    init(useCase: PurchaseUseCase) {
        self.useCase = useCase
    }
    
}
extension PurchaseViewModel: ViewModelType {
    struct Input {
        var fetchFiles: AnyPublisher<Void, Never>
        var restore: AnyPublisher<Void, Never>
        var buy: AnyPublisher<String, Never>
    }
    
    class Output: ObservableObject {
        @Published var listItems: [Product]?
        @Published var isLoading: Bool?
        @Published var errorMessage: String?
    }

    func transform(_ input: Input) -> Output {
        let output = Output()
        let indicatorLoading = ActivityIndicator()
        let errorTracker = ErrorTracker()
        
        input.fetchFiles
            .flatMap { [weak self] in
                guard let self else {
                    return Empty<[Product], Error>(completeImmediately: false).eraseToAnyPublisher()
                }
                return useCase.fetchItems()
                    .trackActivity(indicatorLoading)
                    .trackError(errorTracker)
                    .catch {
                        logger("Error occurred: \($0)")
                        return Empty<[Product], Error>(completeImmediately: false)
                    }.eraseToAnyPublisher()
            }.tryMap {$0}
            .replaceError(with: nil)
            .assign(to: \.listItems, on: output)
            .store(in: &cancellables)
        
        input.buy
            .sink(receiveValue: { [weak self] in
                self?.useCase.buy(with: $0)
            })
            .store(in: &cancellables)
        
        input.restore
            .sink { [weak self] in
                self?.useCase.restore()
            }.store(in: &cancellables)
        
        indicatorLoading.loading
            .compactMap{$0}
            .assign(to: \.isLoading, on: output)
            .store(in: &cancellables)
        
        errorTracker.asPublisher()
            .compactMap {$0.localizedDescription}
            .assign(to: \.errorMessage, on: output)
            .store(in: &cancellables)
        
        return output
    }
}
