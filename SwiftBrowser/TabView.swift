//
//  TabView.swift
//  SwiftBrowser
//
//  Created by yangjian on 2023/7/19.
//

import UIKit

class TabView: UIView {
    
    var addHandle: (()->Void)? = nil
    var dismissHandle: ((CGRect)->Void)? = nil
    var browserView: HomeContentView {
        return BrowserUtil.shared.webItem.view
    }
    var contentFrame: CGRect = .zero
    var isAnimateCompletion: Bool = false {
        didSet {
            if isAnimateCompletion {
                collectionView.reloadData()
            }
        }
    }
    @IBOutlet  weak var collectionView: UICollectionView!

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(UINib(nibName: "TabCell", bundle: .main), forCellWithReuseIdentifier: "TabCell")
    }
}

extension TabView {
    func selectItem(_ item: WebViewItem) {
        BrowserUtil.shared.select(item)
        collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss()
        }
    }
    
    func removeItem(_ item: WebViewItem, in collection: UICollectionView) {
        BrowserUtil.shared.removeItem(item)
        collection.reloadData()
    }
    
    @IBAction func newItem() {
        BrowserUtil.shared.add()
        addHandle?()
    }
    
    @IBAction func dismiss() {
        dismissAnimation()
    }
    
    func dismissAnimation() {
        let index = findIndexItem()
        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? TabCell {
            let rc = cell.convert(cell.view.frame, to: self)
            let newFrame = CGRect(x: rc.minX, y: rc.minY + 20, width: rc.width, height: rc.height)
            // 回传当前cell坐标
            
            let scale = CGAffineTransform(scaleX: newFrame.width / contentFrame.width, y: newFrame.height / contentFrame.height)
            let x = (contentFrame.width - newFrame.width) / 2.0 + contentFrame.minX - newFrame.minX
            let y = (contentFrame.height - newFrame.height) / 2.0 + contentFrame.minY - newFrame.minY
            let moveDown = CGAffineTransform(translationX: -x, y: -y)
            self.browserView.transform = scale.concatenating(moveDown)
            
            self.dismissHandle?(newFrame)

        }
    }
    
    func findIndexItem() -> Int {
        var index = 0
        for (i, val) in BrowserUtil.shared.webItems.enumerated() {
            if val.isSelect {
                index = i
            }
        }
        return index
    }
}

extension TabView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        BrowserUtil.shared.webItems.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath)
        if let cell = cell as? TabCell {
            cell.isCompletion = isAnimateCompletion
            let item = BrowserUtil.shared.webItems[indexPath.row]
            cell.item = item
            cell.closeHandle = { [weak self] in
                self?.removeItem(item, in: collectionView)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (bounds.width - 48) / 2.0 - 2.0
        let height =  4.0 / 3.0 * width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = BrowserUtil.shared.webItems[indexPath.row]
        selectItem(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView.numberOfItems(inSection: section) == 1 {
            let width = ((bounds.width - 48) / 2.0 - 2.0)
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: collectionView.frame.width - width)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

class TabCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var view: UIView!
    
    var isCompletion: Bool = false
    var closeHandle: (()->Void)? =  nil
    
    @IBAction func closeAction() {
        closeHandle?()
    }
    
    var item: WebViewItem? = nil {
        didSet {
            guard let item = item else { return }
            titleLabel.text = item.view.webView.url?.absoluteString
            closeButton.isHidden = BrowserUtil.shared.webItems.count == 1
            if isCompletion {
                view.subviews.forEach { v in
                    if v is HomeContentView {
                        v.removeFromSuperview()
                    }
                }
                view.addSubview(item.view)
            }
            
            if item.isSelect {
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 1.0
            } else {
                self.layer.borderWidth = 0.0
            }
            
            view.isUserInteractionEnabled = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isCompletion {
            item?.view.frame = view.bounds
        }
    }
    
}
