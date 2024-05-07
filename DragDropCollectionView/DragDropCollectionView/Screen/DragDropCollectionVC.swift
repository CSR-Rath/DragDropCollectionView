//
//  ViewController.swift
//  DragDropCollectionView
//
//  Created by Rath! on 7/5/24.
//

import UIKit
enum MenuTitle: String{
    case wallet = "Wallet"
    case reward = "Reward"
    case fun = "Fun"
    case offer = "Special Offer"
    case events = "Events"
    case charity = "Charity"
    case none = "none"
}

class DragDropCollectionVC :UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    static let  cell = "MenuListDragDropCell"
            var didSelectItemsCell : ((_ : MenuTitle)->())?
    var collectionView : UICollectionView!
    
    var  dataList : [TitleImageModel] = [] {
        didSet{
            collectionView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        setupCollectionView()
        loadDataList()
        observeAppLifecycle()
    }

    
 
    
    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
   
    }
    
    @objc private func appWillTerminate() {
        saveDataList()
    }
    

    func saveDataList() {
        let encodedData = try? JSONEncoder().encode(dataList)
        UserDefaults.standard.set(encodedData, forKey: "DataListKey")
    }
    
    
    //MARK: Set default date and fetching data
    func loadDataList() {
        if let encodedData = UserDefaults.standard.data(forKey: "DataListKey"),
           let savedDataList = try? JSONDecoder().decode([TitleImageModel].self, from: encodedData) {
            dataList = savedDataList
        } else {
            // Set default dataList if no saved data is found
            dataList = [
                TitleImageModel(image: .icWalletManu, title: MenuTitle.wallet.rawValue),
                TitleImageModel(image: .icRewardManu, title: MenuTitle.reward.rawValue),
                TitleImageModel(image: .icFunManu, title: MenuTitle.fun.rawValue),
                TitleImageModel(image: .icOfferManu, title: MenuTitle.offer.rawValue),
                TitleImageModel(image: .icEventManu, title: MenuTitle.events.rawValue),
                TitleImageModel(image: .icCharityManu, title: MenuTitle.charity.rawValue)
            ]
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
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: -10),
            collectionView.leadingAnchor.constraint(equalTo:  view.leadingAnchor,constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: CGFloat((size*2) + 35)),
        ])
    }
    
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellIdentifier", for: indexPath) as! MenuDragDropCell
        let titleImageModel = dataList[indexPath.item]
        cell.imgIcone.image = titleImageModel.image
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
               let cell = item.dragItem.localObject as? MenuDragDropCell {
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
                                let titleImageModel = TitleImageModel(image: .icFunManu, title: draggedItem as String)
                                self.dataList.insert(titleImageModel, at: insertionIndexPath.item)
                                collectionView.insertItems(at: [insertionIndexPath])
                            })
                        }
                    }
                })
            }
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print(indexPath.row)
        
        let selectedItem = dataList[indexPath.item].title
        print("selectedItem: \(selectedItem)")
        
        didSelectItemsCell?(MenuTitle(rawValue: selectedItem) ?? MenuTitle.none)
    }
}



struct TitleImageModel: Codable {
    let imageData: Data
    let title: String
    
    var image: UIImage? {
        return UIImage(data: imageData)
    }
    
    init(image: UIImage, title: String) {
        self.imageData = image.pngData() ?? Data()
        self.title = title
    }
    
    private enum CodingKeys: String, CodingKey {
        case imageData
        case title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageData = try container.decode(Data.self, forKey: .imageData)
        title = try container.decode(String.self, forKey: .title)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageData, forKey: .imageData)
        try container.encode(title, forKey: .title)
    }
}
