//
//  ViewController.swift
//  DragDropCollectionView
//
//  Created by Rath! on 7/5/24.
//

import UIKit

class DragDropCollectionVC :UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    static let  cell = "MenuListDragDropCell"
            var didSelectItemsCell : ((_ : MenuListModel)->())?
    var collectionView : UICollectionView!
    
    var  dataList : [MenuListModel] = [] {
        didSet{
            collectionView.reloadData()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            
            print("Touch ended")
        }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        setupCollectionView()
        loadDataList()
    }

    
    //MARK: Set default date and fetching data
    func loadDataList() {
        
        let dateMenu =  DataManager.shared.getDragDropMenu() ?? []
        if  dateMenu.count > 0  {
            dataList = dateMenu
        }else{
            
            // Set default dataList if no saved data is found
            dataList = [
                MenuListModel(imageName: "", title: "Titem 1", id: 1),
                MenuListModel(imageName: "", title: "Titem 2", id: 2),
                MenuListModel(imageName: "", title: "Titem 3",  id: 3),
                MenuListModel(imageName: "", title: "Titem 4", id: 4),
                MenuListModel(imageName: "", title: "Titem 5", id: 5),
                MenuListModel(imageName: "", title: "Titem 6", id: 6)
            ]
            
            DataManager.shared.saveDragDropMenu(data: dataList)
        }
    }
}

extension DragDropCollectionVC{
    
    
    private func setupCollectionView() {
        
        let spacing = 15
        let size = ((Int(UIScreen.main.bounds.width)-32)-(spacing*2))/3
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: size, height: size)
        layout.minimumInteritemSpacing = CGFloat(spacing)
        layout.minimumLineSpacing = CGFloat(spacing)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        collectionView = UICollectionView(frame: .zero , collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.register(MenuDragDropCell.self, forCellWithReuseIdentifier: "CellIdentifier")
        collectionView.backgroundColor = .orange
        
        view.addSubview(collectionView)
        
        collectionView.frame = view.bounds
 
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellIdentifier", for: indexPath) as! MenuDragDropCell
        let titleImageModel = dataList[indexPath.item]
        cell.imgIcone.image =  UIImage(named: titleImageModel.imageName)
        cell.titleLabel.text = titleImageModel.title
     
        return cell
    }
    
    // MARK: - UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        //        UIDevice.vibrate()
        
        let generator = UIImpactFeedbackGenerator(style: .light) // You can change the style to .medium or .heavy
        generator.prepare()
        generator.impactOccurred()
        
        let titleImageModel = dataList[indexPath.item]
        let itemProvider = NSItemProvider(object: titleImageModel.title as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = collectionView.cellForItem(at: indexPath)
        return [dragItem]
    }
    
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isLocalDrag = session.localDragSession != nil
        return UICollectionViewDropProposal(operation: isLocalDrag ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath,
               let _ = item.dragItem.localObject as? MenuDragDropCell {
                collectionView.performBatchUpdates({
                    let movedItem = dataList.remove(at: sourceIndexPath.item)
                    dataList.insert(movedItem, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }, completion: { finished in
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                })
            } else {
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "CellIdentifier"))
                
                item.dragItem.itemProvider.loadObject(ofClass: NSString.self, completionHandler: { (object, error) in
                    if let draggedItem = object as? NSString {
                        DispatchQueue.main.async {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                let titleImageModel = MenuListModel(imageName: "", title: draggedItem as String, id: 1)
                                self.dataList.insert(titleImageModel, at: insertionIndexPath.item)
                                collectionView.insertItems(at: [insertionIndexPath])
                            })
                        }
                    }
                })
            }
        }
        
        
        DataManager.shared.saveDragDropMenu(data: dataList)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print(indexPath.row)
        
        let selectedItem = dataList[indexPath.item]
        print("selectedItem: \(selectedItem)")
        
//        didSelectItemsCell?(MenuTitle(rawValue: selectedItem) ?? MenuTitle.none)
    }
}



struct MenuListModel: Codable {
    let imageName: String
    let title: String
    let id: Int
}

