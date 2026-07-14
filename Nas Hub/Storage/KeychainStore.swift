import Foundation
import Security

protocol TokenStore: Sendable { func save(_ tokens: Tokens) throws; func load() throws -> Tokens?; func clear() throws }
final class KeychainStore: TokenStore, @unchecked Sendable {
    private let service = "com.ebantugan.Nas-Hub.auth", account = "tokens"
    func save(_ tokens: Tokens) throws { let data = try JSONEncoder().encode(tokens); try clear(); let query: [String: Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account,kSecValueData as String:data,kSecAttrAccessible as String:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]; let status=SecItemAdd(query as CFDictionary,nil); guard status==errSecSuccess else{throw KeychainError.status(status)} }
    func load() throws -> Tokens? { let query:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account,kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne];var item:CFTypeRef?;let status=SecItemCopyMatching(query as CFDictionary,&item);if status==errSecItemNotFound{return nil};guard status==errSecSuccess,let data=item as? Data else{throw KeychainError.status(status)};return try JSONDecoder().decode(Tokens.self,from:data) }
    func clear() throws { let status=SecItemDelete([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:account] as CFDictionary);if status != errSecSuccess && status != errSecItemNotFound { throw KeychainError.status(status) } }
}
enum KeychainError: Error { case status(OSStatus) }

