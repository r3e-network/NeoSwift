
import Combine
import Foundation

public actor BlockIndexActor {
    
    var blockIndex: Int? = nil
    
    func setIndex(_ index: Int) {
        blockIndex = index
    }
    
}

public struct BlockIndexPolling {
    
    var currentBlockIndex = BlockIndexActor()
    
    public func blockIndexPublisher(_ neoSwift: NeoSwift, _ executor: DispatchQueue, _ pollingInterval: Int) -> AnyPublisher<Int, Error> {
        return Timer.publish(every: Double(pollingInterval) / 1000, on: .current, in: .default)
            .autoconnect()
            .setFailureType(to: Error.self)
            .asyncMap { _ -> [Int]? in
                let latestBlockIndex = try await neoSwift.getBlockCount().send().getResult() - 1
                if await currentBlockIndex.blockIndex == nil {
                    await currentBlockIndex.setIndex(latestBlockIndex)
                }
                if await latestBlockIndex > currentBlockIndex.blockIndex! {
                    let currIndex = await currentBlockIndex.blockIndex!
                    await currentBlockIndex.setIndex(latestBlockIndex )
                    return Array((currIndex + 1)...latestBlockIndex)
                }
                return nil
            }
            .compactMap { $0 }
            .flatMap { $0.publisher.setFailureType(to: Error.self) }
            .subscribe(on: executor)
            .eraseToAnyPublisher()
    }
    
}


extension Publisher {
    /// Maps values using an async transformation without blocking threads
    func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future<T, Error> { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Legacy syncMap for backward compatibility - DEPRECATED
    @available(*, deprecated, renamed: "asyncMap", message: "Use asyncMap instead to avoid thread blocking")
    func syncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        return asyncMap(transform)
    }
}
