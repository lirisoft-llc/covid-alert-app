//
//  LocalStore.swift
//  CovidShield
//
//  Created by Avinash P on 9/30/20.
//

import Foundation


@propertyWrapper
class Persisted<Value: Codable> {
  typealias Item = Data
  typealias Key = String
  
  enum KeychainQuery {
    case add(Key, Item)
    case updateQuery(Key)
    case updateAttr(Item)
    case get(Key)
    case delete(Key)
    
    var query: [String : Any] {
      switch self {
      case .add(let key, let item):
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: item]
      case .get(let key):
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String  : kSecMatchLimitOne]
      case .updateQuery(let key):
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key]
      case .updateAttr(let item):
        return [kSecValueData as String: item]
      case .delete(let key):
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key]
      }
    }
  }
  
  
  init(userDefaultsKey: String, notificationName: Notification.Name, defaultValue: Value) {
    self.userDefaultsKey = userDefaultsKey
    self.notificationName = notificationName
    self.storeKey = "com.lirisoft.rastreaelvirus.\(userDefaultsKey)"
    
    var item: CFTypeRef?
    let getItem = KeychainQuery.get(storeKey)
    let status = SecItemCopyMatching(getItem.query as CFDictionary, &item)
  
    if status == errSecItemNotFound || status != errSecSuccess {
      print("No value found, setting default value")
      wrappedValue = defaultValue
      return
    }
            
    do {
      if let data = item as? Data {
        print("Value found")
        isKeychainValue = true
        wrappedValue = try JSONDecoder().decode(Value.self, from: data)
      } else {
        print("No value found, setting default value")
        wrappedValue = defaultValue
      }
    } catch {
      print("Error decoding value")
      wrappedValue = defaultValue
    }
  }
  
  let userDefaultsKey: String
  let notificationName: Notification.Name
  let storeKey: String
  var isKeychainValue = false

  var wrappedValue: Value {
    didSet {
      let data = try! JSONEncoder().encode(wrappedValue)
      let key = storeKey
      var status: OSStatus!
      
      if isKeychainValue {
        let updateItem = KeychainQuery.updateQuery(key)
        let updateItemAttr = KeychainQuery.updateAttr(data)
        status = SecItemUpdate(updateItem.query as CFDictionary, updateItemAttr.query as CFDictionary)
      } else {
        let addItem = KeychainQuery.add(key, data)
        status = SecItemAdd(addItem.query as CFDictionary, nil)
      }
                  
      guard status == errSecSuccess else {
          print("Failed to save item: \(userDefaultsKey) in key chain")
          return
      }
      NotificationCenter.default.post(name: notificationName, object: nil)
    }
  }
  
  var projectedValue: Persisted<Value> { self }
  
  func addObserver(using block: @escaping () -> Void) -> NSObjectProtocol {
      return NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
          block()
      }
  }
}

@objc class LocalStore: NSObject {
  @objc static let shared = LocalStore()
  @Persisted(userDefaultsKey: "latestDetectedURL", notificationName: .init("LocalStoreDidUpdateLastDetectionURL"), defaultValue: "")
  var latestDetectedURL: String

  @Persisted(userDefaultsKey: "latestDetectedDate", notificationName: .init("LocalStoreDidUpdateLastDate"), defaultValue: Date())
  var latestDetectedDate: Date?
  
  @objc func updateLastDetectedURLString(_ urlString: String) {
    self.latestDetectedURL = urlString
  }
}



