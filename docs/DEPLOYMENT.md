# NeoSwift Production Deployment Guide

## Prerequisites

Before deploying NeoSwift to production:

1. **Swift Version**: 5.3 or higher
2. **Platform Requirements**:
   - macOS 10.15+
   - iOS 13.0+
   - tvOS 13.0+
   - watchOS 6.0+
3. **Security Audit**: Complete security review
4. **Testing**: All tests passing with >80% coverage

## Pre-Deployment Checklist

### Code Security
- [ ] Remove all test credentials
- [ ] No hardcoded secrets or private keys
- [ ] All force unwrapping eliminated
- [ ] Security tests passing
- [ ] SwiftLint security rules passing

### Dependencies
- [ ] All dependencies using version upper bounds
- [ ] Security scan completed on dependencies
- [ ] Licenses reviewed and compliant
- [ ] Package.resolved committed

### Configuration
- [ ] Production endpoints configured
- [ ] Network timeouts appropriate for production
- [ ] Error messages don't leak sensitive info
- [ ] Logging configured appropriately

## Deployment Steps

### 1. Build Configuration

Create a production build configuration:

```swift
// In your app's build settings
#if DEBUG
    let networkUrl = URL(string: "https://testnet1.neo.coz.io:443")!
#else
    let networkUrl = URL(string: "https://mainnet1.neo.coz.io:443")!
#endif
```

### 2. Security Configuration

Configure secure key management:

```swift
// AppDelegate or main configuration
import NeoSwift

class NeoSwiftConfiguration {
    static func configure() {
        // Set production network
        let httpService = HttpService(url: URL(string: "https://mainnet1.neo.coz.io:443")!)
        let neoSwift = NeoSwift.build(httpService)
        
        // Configure hash cache size for production load
        HashCache.shared.maxCacheSize = 5000
        
        // Use optimized binary writer
        // BinaryWriter will automatically use optimized version
    }
}
```

### 3. Key Management Setup

Implement secure key storage:

```swift
import NeoSwift
import KeychainAccess

class SecureKeyManager {
    private let keychain = Keychain(service: "com.yourapp.neoswift")
        .accessibility(.whenUnlockedThisDeviceOnly)
    
    func storeEncryptedKey(_ nep2: String, for account: String) throws {
        try keychain.set(nep2, key: "nep2_\(account)")
    }
    
    func retrieveKeyPair(for account: String, password: String) throws -> SecureECKeyPair {
        guard let nep2 = keychain["nep2_\(account)"] else {
            throw KeyManagerError.keyNotFound
        }
        
        let keyPair = try NEP2.decrypt(password, nep2)
        return keyPair.toSecureKeyPair()
    }
}
```

### 4. Transaction Security

Implement transaction validation:

```swift
class TransactionValidator {
    static let maxAcceptableGasFee: Int64 = 10_000_000 // 0.1 GAS
    
    static func validate(_ transaction: Transaction) throws {
        // Check fees
        guard transaction.systemFee + transaction.networkFee < maxAcceptableGasFee else {
            throw ValidationError.excessiveFees
        }
        
        // Verify recipient addresses
        for signer in transaction.signers {
            guard isKnownAddress(signer.account) else {
                throw ValidationError.unknownRecipient
            }
        }
        
        // Additional validation...
    }
}
```

### 5. Error Handling

Implement production error handling:

```swift
enum AppError: LocalizedError {
    case networkError
    case invalidTransaction
    case insufficientFunds
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please try again."
        case .invalidTransaction:
            return "Transaction validation failed."
        case .insufficientFunds:
            return "Insufficient funds for this operation."
        }
    }
    
    var recoverySuggestion: String? {
        // Provide user-friendly recovery suggestions
    }
}
```

### 6. Monitoring Setup

Configure monitoring and analytics:

```swift
class NeoSwiftMonitor {
    static func logTransaction(_ tx: Transaction, status: TransactionStatus) {
        // Log to your analytics service
        Analytics.track("transaction", properties: [
            "status": status.rawValue,
            "fee": tx.systemFee + tx.networkFee,
            "signers": tx.signers.count
            // Do NOT log private keys or transaction contents
        ])
    }
    
    static func logError(_ error: Error, context: String) {
        // Log errors without sensitive information
        let sanitizedError = sanitizeError(error)
        Crashlytics.recordError(sanitizedError, userInfo: ["context": context])
    }
}
```

## Performance Optimization

### 1. Connection Pooling

```swift
class NeoSwiftConnectionPool {
    private let pool: [NeoSwift]
    private var currentIndex = 0
    
    init(urls: [URL], poolSize: Int = 3) {
        self.pool = urls.flatMap { url in
            (0..<poolSize).map { _ in
                NeoSwift.build(HttpService(url: url))
            }
        }
    }
    
    func getConnection() -> NeoSwift {
        currentIndex = (currentIndex + 1) % pool.count
        return pool[currentIndex]
    }
}
```

### 2. Caching Strategy

```swift
// Configure caching for production load
HashCache.shared.maxCacheSize = 10_000

// Cache frequently accessed data
class BlockCache {
    private let cache = NSCache<NSNumber, NeoGetBlock>()
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
}
```

## Security Hardening

### 1. Network Security

```swift
// Configure certificate pinning
class SecureHttpService: HttpService {
    override func urlSession(_ session: URLSession, 
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Implement certificate pinning
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Verify certificate
        // ... certificate pinning logic ...
    }
}
```

### 2. Rate Limiting

```swift
class RateLimiter {
    private var lastRequestTime: [String: Date] = [:]
    private let minInterval: TimeInterval = 0.1 // 100ms between requests
    
    func shouldAllowRequest(for endpoint: String) -> Bool {
        let now = Date()
        if let lastTime = lastRequestTime[endpoint],
           now.timeIntervalSince(lastTime) < minInterval {
            return false
        }
        lastRequestTime[endpoint] = now
        return true
    }
}
```

## Production Monitoring

### 1. Health Checks

```swift
class HealthCheckService {
    static func performHealthCheck() async throws -> HealthStatus {
        // Check Neo node connectivity
        let neoSwift = getNeoSwiftInstance()
        let blockCount = try await neoSwift.getBlockCount().send()
        
        guard blockCount.error == nil else {
            return .unhealthy(reason: "Node connection failed")
        }
        
        // Check local services
        // ... additional checks ...
        
        return .healthy
    }
}
```

### 2. Metrics Collection

```swift
struct MetricsCollector {
    static func trackOperation(_ operation: String, duration: TimeInterval, success: Bool) {
        // Send to metrics service
        Metrics.record(
            name: "neoswift.\(operation)",
            value: duration,
            tags: ["success": String(success)]
        )
    }
}
```

## Troubleshooting

### Common Issues

1. **High Memory Usage**
   - Check hash cache size
   - Verify no memory leaks in key handling
   - Use Instruments to profile

2. **Slow Performance**
   - Enable connection pooling
   - Check network latency
   - Profile with Time Profiler

3. **Transaction Failures**
   - Verify network fees
   - Check account balance
   - Validate script correctness

### Debug Logging

```swift
// Production-safe logging
class Logger {
    static func log(_ message: String, level: LogLevel) {
        #if DEBUG
        print("[\(level)] \(message)")
        #else
        // Use production logging service
        LoggingService.log(message, level: level)
        #endif
    }
}
```

## Post-Deployment

### 1. Monitor
- Transaction success rates
- API response times
- Error rates
- Resource usage

### 2. Update Plan
- Security patches within 24 hours
- Feature updates with staged rollout
- Dependency updates monthly

### 3. Incident Response
- Error spike alerts
- Automatic rollback capability
- On-call rotation for critical issues

## Compliance

Ensure compliance with:
- Data protection regulations (GDPR, CCPA)
- Financial regulations if handling funds
- Export controls for cryptography
- App Store guidelines for iOS apps

---

For additional support, refer to:
- [SECURITY.md](./SECURITY.md) - Security best practices
- [README.md](../README.md) - General usage
- [Neo Documentation](https://docs.neo.org) - Blockchain specifics