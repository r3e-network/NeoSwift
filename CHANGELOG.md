# Changelog

All notable changes to NeoSwift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-01-21

### Added
- Neo N3 v3.9 RPC coverage for `findstorage`, `getcandidates`, and `canceltransaction`
- Transaction attributes for Conflicts, NotValidBefore, and NotaryAssisted
- Expanded `getversion` decoding for rpc/protocol metadata (hardforks, seedlist, standbycommittee)

### Changed
- Address encoding/validation now respects configured address version
- Transaction attribute de-duplication aligned with node rules

### Tests
- Added attribute serialization round-trip coverage

## [2.0.0] - 2024-12-19

### 🛡️ Security (BREAKING CHANGES)
- **Added** `SecureBytes` class for secure memory management of sensitive data
- **Added** `SecureECKeyPair` class for secure private key handling  
- **Added** `ConstantTime` utility for timing-attack resistant operations
- **Moved** test credentials from source code to external JSON files
- **Added** compile-time protection preventing test data in release builds
- **Updated** NEP2 implementation to use constant-time comparisons
- **Added** dependency version upper bounds for supply chain security

### ⚡ Performance
- **Added** `OptimizedBinaryWriter` with pre-allocated buffers (50-70% faster)
- **Added** `HashCache` for thread-safe caching of repeated hash operations
- **Fixed** async operations to use proper Future patterns instead of blocking semaphores
- **Replaced** O(n) array concatenation with O(1) buffer operations

### 🧪 Testing & Quality
- **Added** comprehensive `SecurityTests` suite for cryptographic operations
- **Added** `IntegrationTestBase` and `WalletIntegrationTests` for end-to-end testing
- **Added** automated security scanning in CI/CD pipeline
- **Added** SwiftLint security rules configuration
- **Added** test coverage reporting

### 📚 Documentation
- **Added** `SECURITY.md` with comprehensive security best practices
- **Added** `DEPLOYMENT.md` with production deployment guide
- **Added** `SECURITY_FIXES_SUMMARY.md` documenting all security improvements
- **Updated** README with security considerations and new APIs

### 🔧 Infrastructure
- **Added** comprehensive CI/CD workflows for build, test, and release
- **Added** automated security scanning with TruffleHog and Semgrep
- **Added** multi-platform builds (macOS, Linux)
- **Added** release automation with changelog generation

### 🔄 Migration Guide

#### From v1.x to v2.0

**For Enhanced Security (Recommended):**
```swift
// Old (v1.x)
let keyPair = try ECKeyPair.createEcKeyPair()

// New (v2.0) - Secure
let secureKeyPair = try SecureECKeyPair.createEcKeyPair()
```

**Performance Optimizations:**
```swift
// Enable hash caching
HashCache.shared.maxCacheSize = 5000

// Use optimized binary writer
let writer = BinaryWriter.optimized()
```

**Security-Critical Comparisons:**
```swift
// Old - Vulnerable to timing attacks
if calculatedHash == expectedHash { }

// New - Constant time
if ConstantTime.areEqual(calculatedHash, expectedHash) { }
```

## [1.x.x] - Previous Versions

See git history for changes in previous versions.

---

### Legend
- 🛡️ Security improvements
- ⚡ Performance improvements  
- 🧪 Testing and quality
- 📚 Documentation
- 🔧 Infrastructure and tooling
- 🔄 Migration information
