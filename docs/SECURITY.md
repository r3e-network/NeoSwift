# NeoSwift Security Guide

## Overview

This document outlines security best practices and considerations when using NeoSwift in production environments. NeoSwift handles sensitive cryptographic operations and private keys, making security a critical concern.

## Security Features

### 1. Secure Memory Management

NeoSwift provides `SecureBytes` and `SecureECKeyPair` classes for handling sensitive data:

- **Memory Protection**: Sensitive data is stored in protected memory regions
- **Automatic Clearing**: Memory is securely overwritten when no longer needed
- **Memory Locking**: Prevents sensitive data from being swapped to disk

```swift
// Use SecureECKeyPair for production key management
let secureKeyPair = try SecureECKeyPair.createEcKeyPair()

// Private key memory is automatically protected and cleared
let signature = secureKeyPair.sign(messageHash: messageHash)
```

### 2. Constant-Time Operations

All cryptographic comparisons use constant-time algorithms to prevent timing attacks:

```swift
// Constant-time comparison for password verification
if ConstantTime.areEqual(providedHash, expectedHash) {
    // Password is correct
}
```

### 3. Test Credential Isolation

Test credentials are isolated from production code:
- Stored in external JSON files
- Only available in DEBUG builds
- Compilation fails if test credentials are used in RELEASE builds

## Security Best Practices

### Private Key Management

1. **Never store private keys in plain text**
   ```swift
   // DON'T do this
   let privateKey = "84180ac9d6eb6fba207ea4ef9d2200102d1ebeb4b9c07e2c6a738a42742e27a5"
   
   // DO this instead
   let secureKeyPair = try SecureECKeyPair.createEcKeyPair()
   ```

2. **Use NEP-2 encryption for key storage**
   ```swift
   let password = getSecurePasswordFromUser()
   let encrypted = try NEP2.encrypt(password, keyPair)
   // Store 'encrypted' safely
   ```

3. **Clear sensitive data after use**
   ```swift
   let secureData = SecureBytes(sensitiveBytes)
   defer { secureData.clear() }
   // Use secureData
   ```

### Network Security

1. **Always use HTTPS endpoints**
   ```swift
   let url = URL(string: "https://mainnet1.neo.coz.io:443")!
   let neoSwift = NeoSwift.build(HttpService(url: url))
   ```

2. **Validate node responses**
   ```swift
   let response = try await neoSwift.getBlock(blockHash).send()
   guard response.error == nil else {
       // Handle error appropriately
       throw SecurityError.untrustedResponse
   }
   ```

### Transaction Security

1. **Verify transaction details before signing**
   ```swift
   let tx = try await TransactionBuilder(neoSwift)
       .script(script)
       .signers(signers)
       .getUnsignedTransaction()
   
   // Verify transaction details
   guard tx.systemFee + tx.networkFee < maxAcceptableFee else {
       throw SecurityError.excessiveFees
   }
   
   // Only sign after verification
   let signedTx = try tx.sign()
   ```

2. **Use multi-signature accounts for high-value operations**
   ```swift
   let multiSigAccount = try Account.createMultiSigAccount(publicKeys, threshold: 2)
   ```

## Vulnerability Reporting

If you discover a security vulnerability in NeoSwift:

1. **DO NOT** create a public GitHub issue
2. Email security details to: [security@neoswift.io] (update with actual email)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

## Security Checklist for Production

Before deploying to production, ensure:

- [ ] All private keys use `SecureECKeyPair` or are encrypted with NEP-2
- [ ] Test credentials are not included in production builds
- [ ] All network communication uses HTTPS
- [ ] Transaction fees are validated before signing
- [ ] Error messages don't leak sensitive information
- [ ] Dependencies are up-to-date and from trusted sources
- [ ] Audit logs don't contain private keys or passwords
- [ ] Multi-signature is used for high-value accounts
- [ ] Regular security updates are applied

## Cryptographic Specifications

NeoSwift implements:
- **Elliptic Curve**: secp256r1 (P-256)
- **Signing Algorithm**: ECDSA with deterministic k (RFC 6979)
- **Hash Functions**: SHA-256, RIPEMD-160
- **Key Derivation**: Scrypt (N=16384, r=8, p=8)
- **Encryption**: AES-256-ECB (for NEP-2)

## Dependencies Security

Regular security audits should include:

1. **Dependency Updates**
   ```bash
   swift package update
   swift package show-dependencies
   ```

2. **Known Vulnerabilities Check**
   - Review security advisories for all dependencies
   - Monitor: BigInt, SwiftECC, CryptoSwift, Scrypt, BIP39

3. **Supply Chain Security**
   - Verify package checksums
   - Use specific version constraints in Package.swift

## Secure Development Workflow

1. **Code Review**: All cryptographic code changes require security review
2. **Testing**: Run security test suite before releases
3. **Static Analysis**: Use SwiftLint with security rules
4. **Penetration Testing**: Conduct regular security assessments

## Emergency Response

In case of security incident:

1. **Immediate Actions**
   - Revoke compromised keys
   - Update affected accounts
   - Notify users if their funds are at risk

2. **Investigation**
   - Analyze logs (ensure no sensitive data logged)
   - Identify attack vector
   - Assess impact scope

3. **Remediation**
   - Patch vulnerability
   - Update security measures
   - Publish security advisory

## Additional Resources

- [Neo Security Best Practices](https://docs.neo.org/docs/n3/develop/write/security)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
- [Swift Security Guidelines](https://developer.apple.com/documentation/security)

---

Remember: Security is an ongoing process, not a one-time implementation. Regular reviews and updates are essential for maintaining a secure blockchain application.