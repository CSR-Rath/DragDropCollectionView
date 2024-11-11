//
//  DataManager.swift
//  DragDropCollectionView
//
//  Created by Rath! on 11/11/24.
//

import Foundation
import UIKit

class DataManager{
    
   static let shared = DataManager()
   private let userDefaults = UserDefaults.standard
    
}



// MARK: - Save object
extension DataManager {
    
    func saveDragDropMenu(data: [MenuListModel]) {
        saveObject(object: data, forKey: "dataList")
    }
}

// MARK: - Get object
extension DataManager {
    func getDragDropMenu() -> [MenuListModel]? {
        return getObject([MenuListModel].self, with: "dataList") ?? []
    }

}

// MARK: - Object Storage Functions
extension DataManager {
    
    // MARK: Get Object
    private func getObject<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
    
    // MARK: Save Object
    private func saveObject<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }
}
