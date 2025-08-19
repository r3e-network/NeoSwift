import XCTest
@testable import NeoSwift

/// Integration tests for wallet operations
final class WalletIntegrationTests: IntegrationTestBase {
    
    func testCreateAndSaveWallet() async throws {
        // Create a new wallet with multiple accounts
        let account1 = try Account.create()
        let account2 = try Account.create()
        
        let wallet = try Wallet.withAccounts([account1, account2])
            .name("TestWallet")
            .version("1.0")
        
        // Verify wallet properties
        XCTAssertEqual(wallet.name, "TestWallet")
        XCTAssertEqual(wallet.version, "1.0")
        XCTAssertEqual(wallet.accounts.count, 2)
        
        // Test NEP6 export
        let nep6Json = try wallet.toNEP6Json()
        XCTAssertFalse(nep6Json.isEmpty)
        
        // Test wallet reconstruction from NEP6
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test-wallet.json")
        try nep6Json.write(to: tempFile, atomically: true, encoding: .utf8)
        
        let reconstructedWallet = try Wallet.fromNEP6Wallet(tempFile.path)
        XCTAssertEqual(reconstructedWallet.accounts.count, 2)
        
        // Clean up
        try FileManager.default.removeItem(at: tempFile)
    }
    
    func testMultiSigAccount() async throws {
        // Create multiple key pairs
        let keyPair1 = try ECKeyPair.createEcKeyPair()
        let keyPair2 = try ECKeyPair.createEcKeyPair()
        let keyPair3 = try ECKeyPair.createEcKeyPair()
        
        let publicKeys = [
            keyPair1.publicKey,
            keyPair2.publicKey,
            keyPair3.publicKey
        ]
        
        // Create 2-of-3 multi-sig account
        let multiSigAccount = try Account.createMultiSigAccount(publicKeys, 2)
        
        // Verify multi-sig properties
        XCTAssertEqual(multiSigAccount.signingThreshold, 2)
        XCTAssertEqual(multiSigAccount.nrOfParticipants, 3)
        XCTAssertTrue(multiSigAccount.isMultiSig)
        
        // Verify verification script
        let verificationScript = try multiSigAccount.getVerificationScript()
        XCTAssertFalse(verificationScript.script.isEmpty)
    }
    
    func testAccountEncryption() async throws {
        // Create account with known private key
        let privateKey = try ECKeyPair.createEcKeyPair().privateKey
        let account = try Account.fromPrivateKey(privateKey)
        
        // Test NEP2 encryption
        let password = "TestPassword123!"
        let encrypted = try account.encryptPrivateKey(password)
        
        // Verify encrypted format
        XCTAssertTrue(encrypted.hasPrefix("6P"))
        XCTAssertEqual(encrypted.count, 58)
        
        // Test decryption
        let decryptedAccount = try Account.fromNEP2(encrypted, password)
        XCTAssertEqual(account.address, decryptedAccount.address)
        XCTAssertEqual(account.getScriptHash(), decryptedAccount.getScriptHash())
    }
    
    func testWalletAccountOperations() async throws {
        var wallet = try Wallet.create()
        
        // Add accounts
        let account1 = try Account.create()
        let account2 = try Account.create()
        
        wallet = wallet.addAccounts([account1, account2])
        XCTAssertEqual(wallet.accounts.count, 3) // 1 default + 2 added
        
        // Remove account
        wallet = wallet.removeAccount(account1.address)
        XCTAssertEqual(wallet.accounts.count, 2)
        XCTAssertNil(wallet.accounts.first { $0.address == account1.address })
        
        // Set default account
        wallet = wallet.defaultAccount(account2.address)
        XCTAssertEqual(wallet.defaultAccount?.address, account2.address)
    }
    
    func testAccountBalanceQuery() async throws {
        // This test requires a funded testnet account
        // Skip if no testnet access
        guard ProcessInfo.processInfo.environment["ENABLE_NETWORK_TESTS"] == "true" else {
            throw XCTSkip("Network tests disabled")
        }
        
        // Use a known testnet address with balance
        let testAddress = "NTrezR3C4X8aMLVg7vozt5wguyNfFhwuFx"
        let account = try Account.fromAddress(testAddress)
        
        // Query NEP17 balances
        let balances = try await account.getNep17Balances(neoSwift)
        
        // Should have at least GAS balance
        XCTAssertFalse(balances.isEmpty)
        
        // Check for specific tokens
        let gasBalance = balances.first { $0.contractHash == GasToken.SCRIPT_HASH }
        XCTAssertNotNil(gasBalance)
    }
}