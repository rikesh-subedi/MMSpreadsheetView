//
//  MMSpreadsheetView.swift
//  MMSpreadsheetView
//
//  Created by Subedi, Rikesh on 12/05/18.
//  Copyright © 2018 Mutual Mobile. All rights reserved.
//

import Foundation
public extension NSIndexPath {
    var mmSpreadsheetRow: Int {
        return self.section
    }
    
    var mmSpreadsheetColumn: Int {
        return self.row
    }
}

public extension IndexPath {
    var mmSpreadsheetRow: Int {
        return self.section
    }
    
    var mmSpreadsheetColumn: Int {
        return self.row
    }
}

enum MMSpreadsheetViewCollection:Int {
    case upperLeft
    case upperRight
    case lowerRight
    case lowerLeft
}

enum MMSpreadsheetViewHeaderConfiguration {
    case none
    case columnOnly
    case rowOnly
    case both
}

struct MMConstants {
    static let MMSpreadsheetViewGridSpace:CGFloat = 1.0
    static let MMSpreadsheetViewScrollIndicatorWidth:CGFloat = 5.0
    static let MMSpreadsheetViewScrollIndicatorSpace:CGFloat = 3.0
    static let MMSpreadsheetViewScrollIndicatorMinimum:CGFloat = 25.0
    static let MMScrollIndicatorDefaultInsetSpace:CGFloat = 2.0
    static let MMScrollIndicatorTag:Int64 = 12345
}

@objc public protocol MMSpreadsheetViewDelegate:class {
    
}

@objc public protocol MMSpreadsheetViewDataSource:class  {
    func spreadsheetView(_ spreadsheetView: MMSpreadsheetView, sizeForItemAtIndexPath: IndexPath) -> CGSize
    func numberOfRowsInSpreadsheetView(_ spreadsheetView:MMSpreadsheetView) -> Int
    func numberOfColumnsInSpreadsheetView(_ spreadsheetView:MMSpreadsheetView) -> Int
    func spreadsheetView(_ spreadsheetView: MMSpreadsheetView, cellForItemAtIndexPath: IndexPath) -> UICollectionViewCell
}

@objc public class MMSpreadsheetView: UIView {
    
    var headerRowCount: Int
    var headerColumnCount: Int
    var bounces: Bool = false {
        didSet {
            self.upperLeftCollectionView.bounces = bounces
            self.lowerLeftCollectionView.bounces = bounces
            self.upperRightCollectionView.bounces = bounces
            self.lowerRightCollectionView.bounces = bounces
        }
    }
    
    @objc public weak var dataSource: MMSpreadsheetViewDataSource? {
        didSet {
            if self.upperLeftCollectionView != nil {
                self.initializeCollectionViewLayoutItemSize(collectionView: self.upperLeftCollectionView)
            }
            if self.upperRightCollectionView != nil {
                self.initializeCollectionViewLayoutItemSize(collectionView: self.upperRightCollectionView)
            }
            if self.lowerLeftCollectionView != nil {
                self.initializeCollectionViewLayoutItemSize(collectionView: self.lowerLeftCollectionView)
            }
            if self.lowerRightCollectionView != nil {
                self.initializeCollectionViewLayoutItemSize(collectionView: self.lowerRightCollectionView)
            }
            
            //let maxRows = datasource?.numberOfRows(in: self)
            //let maxCols = datasource?.numberOfColumns(in: self)
        }
    }
    @objc public weak var delegate: MMSpreadsheetViewDelegate? {
        didSet {
            
        }
    }
    
    var spreadsheetHeaderConfiguration: MMSpreadsheetViewHeaderConfiguration!
    var controllingScrollView: UIScrollView!
    var upperLeftContainerView: UIView!
    var upperRightContainerView: UIView!
    var lowerLeftContainerView: UIView!
    var lowerRightContainerView:UIView!
    var upperLeftCollectionView: UICollectionView!
    var upperRightCollectionView: UICollectionView!
    var lowerLeftCollectionView: UICollectionView!
    var lowerRightCollectionView:UICollectionView!
    var upperRightBouncing: Bool!
    var lowerLeftBouncing: Bool!
    var lowerRightBouncing: Bool!
    
    var verticalScrollIndicator: UIView!
    var horizontalScrollIndicator: UIView!
    var selectedItemCollectionView: UICollectionView!
    var selectedItemIndexPath: IndexPath!
    
    private var scrollIndicatorInsets: UIEdgeInsets!
    private var showsVerticalScrollIndicator: Bool!
    private var showHorizontalScrollIndicator: Bool!
    
    
    public init(numberOfHeaderRows: Int, numberOfHeaderColumns: Int,  frame: CGRect = CGRect.zero) {
        self.headerRowCount = numberOfHeaderRows
        self.headerColumnCount = numberOfHeaderColumns
        super.init(frame: frame)
        
        self.scrollIndicatorInsets = UIEdgeInsets.zero
        self.showsVerticalScrollIndicator = true
        self.showHorizontalScrollIndicator = true
        
        if headerColumnCount == 0 && headerRowCount == 0 {
            self.spreadsheetHeaderConfiguration = MMSpreadsheetViewHeaderConfiguration.none
        } else if headerColumnCount > 0 && headerRowCount == 0 {
            spreadsheetHeaderConfiguration = MMSpreadsheetViewHeaderConfiguration.columnOnly
        } else if headerColumnCount == 0 && headerRowCount > 0 {
            spreadsheetHeaderConfiguration = MMSpreadsheetViewHeaderConfiguration.rowOnly
        } else if headerColumnCount > 0 && headerRowCount > 0 {
            spreadsheetHeaderConfiguration = MMSpreadsheetViewHeaderConfiguration.both
        }
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundColor = UIColor.lightText
        self.setupSubviews()
        
        
    }
    func setupSubviews() {
        switch spreadsheetHeaderConfiguration! {
        case .both:
            setupUpperLeftView()
            setupUpperRightView()
            setupLowerLeftView()
            setupLowerRightView()
        case .columnOnly:
            setupLowerLeftView()
            setupLowerRightView()
        case .rowOnly:
            setupUpperRightView()
            setupLowerRightView()
        case .none:
            setupLowerRightView()
            break
        }
        
        verticalScrollIndicator = setupScrollIndicator()
    }
    func setupScrollIndicator() -> UIView {
        return UIView.init()
    }
    
    func initializeCollectionViewLayoutItemSize(collectionView: UICollectionView) {
        let indexPathZero = IndexPath(item: 0, section: 0)
        let layout = collectionView.collectionViewLayout as! MMGridLayout
        let size = self.collectionView(collectionView, layout: layout, sizeForItemAt: indexPathZero)
        layout.itemSize = size
    }

    func setupUpperLeftView() {
        self.upperLeftContainerView = UIView(frame:CGRect.zero)
        self.upperLeftCollectionView = setupCollectionViewWithGridLayout()
        self.setupContainerSubview(container: upperLeftContainerView, collectionView: upperLeftCollectionView, tag: MMSpreadsheetViewCollection.upperLeft.rawValue )
        self.upperLeftCollectionView.isScrollEnabled = false
    }
    func setupUpperRightView() {
        self.upperRightContainerView = UIView(frame:CGRect.zero)
        self.upperRightCollectionView = setupCollectionViewWithGridLayout()
        self.upperLeftCollectionView.panGestureRecognizer.addTarget(self, action: #selector(MMSpreadsheetView.handleUpperRightPanGesture(sender:)))
        self.setupContainerSubview(container: upperRightContainerView, collectionView: upperRightCollectionView, tag: MMSpreadsheetViewCollection.upperRight.rawValue)
    }
    
    
    func setupLowerRightView() {
        self.lowerRightContainerView = UIView(frame:CGRect.zero)
        self.lowerRightCollectionView = setupCollectionViewWithGridLayout()
        self.lowerRightCollectionView.panGestureRecognizer.addTarget(self, action: #selector(MMSpreadsheetView.handleLowerRightPanGesture(sender:)))
        self.setupContainerSubview(container: lowerRightContainerView, collectionView: lowerRightCollectionView, tag: MMSpreadsheetViewCollection.lowerRight.rawValue)
    }
    
    func setupLowerLeftView() {
        self.lowerLeftContainerView = UIView(frame:CGRect.zero)
        self.lowerLeftCollectionView = setupCollectionViewWithGridLayout()
        self.lowerLeftCollectionView.panGestureRecognizer.addTarget(self, action: #selector(MMSpreadsheetView.handleLowerLeftPanGesture(sender:)))
        self.setupContainerSubview(container: lowerLeftContainerView, collectionView: lowerLeftCollectionView, tag: MMSpreadsheetViewCollection.lowerLeft.rawValue)
    }
    
    func handleUpperRightPanGesture(sender: UIPanGestureRecognizer){
        
    }
    func handleLowerRightPanGesture(sender: UIPanGestureRecognizer){
        
    }
    func handleLowerLeftPanGesture(sender: UIPanGestureRecognizer){
        
    }
    func deselectItem(atIndexPath: IndexPath, animated: Bool) {
        
    }
    
    func setupContainerSubview(container: UIView, collectionView: UICollectionView, tag: Int ) {
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(container)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.tag = tag
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        container.addSubview(collectionView)
        
    }
    
    func setupCollectionViewWithGridLayout() -> UICollectionView {
        let layout = MMGridLayout.init()
        let collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        return collectionView
    }
    
    
    public convenience override init(frame: CGRect) {
        self.init(numberOfHeaderRows: 0, numberOfHeaderColumns: 0, frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData() {
        self.upperLeftCollectionView.reloadData()
        self.upperRightCollectionView.reloadData()
        self.lowerLeftCollectionView.reloadData()
        self.lowerRightCollectionView.reloadData()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        let indexpathZero = IndexPath.init(item: 0, section: 0)
        switch self.spreadsheetHeaderConfiguration! {
        case .none:
            self.lowerRightContainerView.frame = self.bounds
        case .columnOnly:
            let size = self.lowerLeftCollectionView.collectionViewLayout.collectionViewContentSize
            let cellSize = self.collectionView(self.lowerRightCollectionView, layout: self.lowerRightCollectionView.collectionViewLayout, sizeForItemAt: indexpathZero)
            let maxLockDistance = self.bounds.size.width - cellSize.width
            if size.width > maxLockDistance {
                assert(false, "Width of header too large! Reduce the number of header columns.")
            }
            self.lowerLeftCollectionView.frame = CGRect(x: 0, y: 0, width: size.width, height: self.bounds.size.height)
            self.lowerRightContainerView.frame = CGRect(x: size.width + MMConstants.MMSpreadsheetViewGridSpace, y: 0, width: self.bounds.size.width - size.width - MMConstants.MMSpreadsheetViewGridSpace, height: self.bounds.size.height)
            
            break
        case .rowOnly:
            let size = self.upperRightCollectionView.collectionViewLayout.collectionViewContentSize
            let cellSize = self.collectionView(self.lowerRightCollectionView, layout: self.lowerRightCollectionView.collectionViewLayout, sizeForItemAt: indexpathZero)
            let maxLockDistance = self.bounds.size.width - cellSize.width
            if size.width > maxLockDistance {
                assert(false, "Width of header too large! Reduce the number of header columns.")
            }
            self.upperRightContainerView.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: size.height)
            self.lowerRightCollectionView.frame = CGRect(x: size.width + MMConstants.MMSpreadsheetViewGridSpace, y: 0, width: self.bounds.size.width - size.width - MMConstants.MMSpreadsheetViewGridSpace, height: self.bounds.size.height)
            break
        case .both:
            let size = self.upperLeftCollectionView.collectionViewLayout.collectionViewContentSize
            let cellSize = self.collectionView(self.lowerRightCollectionView, layout: self.lowerRightCollectionView.collectionViewLayout, sizeForItemAt: indexpathZero)
            var maxLockDistance = self.bounds.size.height - cellSize.height
            if size.height > maxLockDistance {
                assert(false, "Height of header too large! Reduce the number of header rows.")
            }
            
            maxLockDistance = self.bounds.size.width - cellSize.width
            if size.width > maxLockDistance {
                assert(false, "Width of header too large! Reduce the number of header columns.")
            }
            
            self.upperLeftContainerView.frame = CGRect(x: 0.0,
                                                           y: 0.0,
                                                           width: size.width,
                                                           height: size.height)
            self.upperRightContainerView.frame = CGRect(x: size.width + MMConstants.MMSpreadsheetViewGridSpace,
                                                        y: CGFloat(0),
                                                        width: self.bounds.size.width - size.width - MMConstants.MMSpreadsheetViewGridSpace,
                                                        height: size.height)
            self.lowerLeftContainerView.frame = CGRect(x: 0.0,
                                                       y: size.height + MMConstants.MMSpreadsheetViewGridSpace,
                                                       width: size.width,
                                                       height: self.bounds.size.height - size.height - MMConstants.MMSpreadsheetViewGridSpace)
            self.lowerRightContainerView.frame = CGRect(x: size.width + MMConstants.MMSpreadsheetViewGridSpace,
                                                        y: size.height + MMConstants.MMSpreadsheetViewGridSpace,
                                                        width: self.bounds.size.width - size.width - MMConstants.MMSpreadsheetViewGridSpace,
                                                        height: self.bounds.size.height - size.height - MMConstants.MMSpreadsheetViewGridSpace)
            
            break
            
        }
        
        // Resize the indicators.
        self.verticalScrollIndicator.frame = CGRect(x: self.frame.size.width - MMConstants.MMSpreadsheetViewScrollIndicatorWidth - self.scrollIndicatorInsets.right - MMConstants.MMScrollIndicatorDefaultInsetSpace,
                                                    y: self.scrollIndicatorInsets.top + MMConstants.MMSpreadsheetViewScrollIndicatorSpace,
                                                    width: MMConstants.MMSpreadsheetViewScrollIndicatorWidth,
                                                    height: self.frame.size.height - 4 *  MMConstants.MMSpreadsheetViewScrollIndicatorSpace)
        
        
    }
    
    
    func registerCellClass(_ cellClass: AnyClass?, forCellWithReuseIdentifier: String) {
        self.upperLeftCollectionView.register(cellClass, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
        self.upperRightCollectionView.register(cellClass, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
        self.lowerLeftCollectionView.register(cellClass, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
        self.lowerRightCollectionView.register(cellClass, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
    }
    
    func register(nib: UINib? , forCellWithReuseIdentifier: String) {
        self.upperLeftCollectionView.register(nib, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
        self.upperRightCollectionView.register(nib, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
        self.lowerLeftCollectionView.register(nib, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
        self.lowerRightCollectionView.register(nib, forCellWithReuseIdentifier: forCellWithReuseIdentifier)
    }
    
    func dequeueReusableCell(reuseIdentifier: String, forIndexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewIndexPath = self.collectionViewIndexPath(for: forIndexPath),
            let collectionView = self.collectionView(for: collectionViewIndexPath) else {
                assert(false, "could not deque cell")
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: collectionViewIndexPath)
        return cell
    }
    
    func collectionViewIndexPath(for datasourceIndexPath: IndexPath) -> IndexPath? {
        guard let collectionView = self.collectionView(for: datasourceIndexPath) else {
            return nil
        }
        var column = datasourceIndexPath.mmSpreadsheetColumn
        var row = datasourceIndexPath.mmSpreadsheetRow
        switch collectionView.tag {
        case MMSpreadsheetViewCollection.upperLeft.rawValue:
            break
        case MMSpreadsheetViewCollection.upperRight.rawValue:
            column = column - self.headerColumnCount
            break
        case MMSpreadsheetViewCollection.lowerLeft.rawValue:
            row = row - self.headerRowCount
            break
        case MMSpreadsheetViewCollection.lowerRight.rawValue:
            row = row - self.headerRowCount
            column = column - self.headerColumnCount
            break
        default:
            return nil
            
        }
        
        return IndexPath.init(item: column, section: row)
        
        
    }
    func collectionView(for datasourceIndexPath: IndexPath) -> UICollectionView? {
        var collectionView:UICollectionView?
        let indexPath = datasourceIndexPath
        switch (self.spreadsheetHeaderConfiguration!) {
        case .none:
            collectionView = self.lowerRightCollectionView;
            break;
            
        case .columnOnly:
            if (indexPath.row >= self.headerColumnCount) {
                collectionView = self.lowerRightCollectionView;
            }
            else {
                collectionView = self.lowerLeftCollectionView;
            }
            break;
            
        case .rowOnly:
            if (indexPath.section >= self.headerRowCount) {
                collectionView = self.lowerRightCollectionView;
            }
            else {
                collectionView = self.upperRightCollectionView;
            }
            break;
            
        case .both:
            if (indexPath.mmSpreadsheetRow >= self.headerRowCount) {
                if (indexPath.mmSpreadsheetColumn >= self.headerColumnCount) {
                    collectionView = self.lowerRightCollectionView;
                }
                else {
                    collectionView = self.lowerLeftCollectionView;
                }
            }
            else {
                if (indexPath.mmSpreadsheetColumn >= self.headerColumnCount) {
                    collectionView = self.upperRightCollectionView;
                }
                else {
                    collectionView = self.upperLeftCollectionView;
                }
            }
            break;
        }
        return collectionView;
    }
    
    
}

extension MMSpreadsheetView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var items = 0
        let columnCount = self.dataSource?.numberOfColumnsInSpreadsheetView(self) ?? 0
        switch collectionView.tag {
        case MMSpreadsheetViewCollection.upperLeft.rawValue:
            items = self.headerColumnCount
             
        case MMSpreadsheetViewCollection.upperRight.rawValue:
           items = columnCount - self.headerColumnCount
        case MMSpreadsheetViewCollection.lowerLeft.rawValue:
            items = headerColumnCount
        case MMSpreadsheetViewCollection.lowerRight.rawValue:
            items = columnCount - self.headerColumnCount
        default:
            break
        }
        return items
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let datasourceIndexPath = self.datasourceIndexpath(from: collectionView, indexpath: indexPath)
        return self.dataSource!.spreadsheetView(self, cellForItemAtIndexPath: datasourceIndexPath)
    }
    
    func datasourceIndexpath(from collectionView: UICollectionView, indexpath: IndexPath) -> IndexPath {
        var column = indexpath.mmSpreadsheetColumn
        var row = indexpath.mmSpreadsheetRow
        
        switch collectionView.tag {
        case MMSpreadsheetViewCollection.upperLeft.rawValue:
            break
        case MMSpreadsheetViewCollection.upperRight.rawValue:
            column = column + self.headerColumnCount
        case MMSpreadsheetViewCollection.lowerLeft.rawValue:
            row = row + self.headerRowCount
        case MMSpreadsheetViewCollection.lowerRight.rawValue:
            column = column + self.headerColumnCount
            row = row + self.headerRowCount
        default:
            break
        }
        return IndexPath.init(item: column, section: row)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        let rowCount = self.dataSource?.numberOfRowsInSpreadsheetView(self)  ?? 0
        var adjustedRows:Int = 1
        switch collectionView.tag {
        case MMSpreadsheetViewCollection.upperLeft.rawValue, MMSpreadsheetViewCollection.upperRight.rawValue:
            adjustedRows = self.headerRowCount
        case MMSpreadsheetViewCollection.lowerLeft.rawValue, MMSpreadsheetViewCollection.lowerRight.rawValue:
            adjustedRows = rowCount - self.headerRowCount
        default:
            break
        }
        
        return Int(adjustedRows)
    }
}

extension MMSpreadsheetView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let datasourceIndexPath = self.datasourceIndexpath(from: collectionView, indexpath: indexPath)
        let size = self.dataSource!.spreadsheetView(self, sizeForItemAtIndexPath: datasourceIndexPath)
        return size
    }
}

extension MMSpreadsheetView : UIScrollViewDelegate {
    func lowerLeftCollectionViewDidScroll(){
        let contentOffset = self.lowerLeftCollectionView.contentOffset
        let point = CGPoint(x: contentOffset.x, y: contentOffset.y)
        self.lowerRightCollectionView.setContentOffset(point, animated: false)
        //TO DO updateVerticalScrollIndicator
        if contentOffset.y < 0 {
            var rect = self.upperLeftContainerView.frame
            rect.origin.y = 0 - contentOffset.y
            self.upperLeftContainerView.frame = rect
            
            rect = self.upperRightContainerView.frame
            rect.origin.y = 0 - contentOffset.y
            self.upperRightContainerView.frame = rect
        } else {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.y = 0;
            self.upperLeftContainerView.frame = rect;
            
            rect = self.upperRightContainerView.frame;
            rect.origin.y = 0;
            self.upperRightContainerView.frame = rect;
        }
        
    }
    func lowerRightCollectionViewDidScroll(){
        let contentOffset = self.lowerRightCollectionView.contentOffset
        let lowerLeftOffset = CGPoint(x: 0, y: contentOffset.y)
        self.lowerLeftCollectionView.setContentOffset(lowerLeftOffset, animated: false)
        
        let upperRightOffset = CGPoint(x: contentOffset.x, y: 0)
        self.upperRightCollectionView.setContentOffset(upperRightOffset, animated: false)
        
        if (contentOffset.y <= 0.0) {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.y = 0 - contentOffset.y;
            self.upperLeftContainerView.frame = rect;
            
            rect = self.upperRightContainerView.frame;
            rect.origin.y = 0 - contentOffset.y;
            self.upperRightContainerView.frame = rect;
        }
        else {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.y = 0.0;
            self.upperLeftContainerView.frame = rect;
            
            rect = self.upperRightContainerView.frame;
            rect.origin.y = 0.0;
            self.upperRightContainerView.frame = rect;
        }
        
        if (contentOffset.x <= 0.0) {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.x = 0 - contentOffset.x;
            
            self.upperLeftContainerView.frame = rect;
            rect = self.lowerLeftContainerView.frame;
            rect.origin.x = 0 - contentOffset.x;
            self.lowerLeftContainerView.frame = rect;
        }
        else {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.x = 0.0;
            
            self.upperLeftContainerView.frame = rect;
            rect = self.lowerLeftContainerView.frame;
            rect.origin.x = 0.0;
            self.lowerLeftContainerView.frame = rect;
        }
        
    }
    func upperRightCollectionViewDidScroll(){
        let contentOffset = self.upperRightCollectionView.contentOffset
        let lowerRightOffset = CGPoint(x: contentOffset.x, y: self.lowerRightCollectionView.contentOffset.y)
        self.lowerRightCollectionView.setContentOffset(lowerRightOffset, animated: false)
        //TO DO: updateHorizontalScrollIndicator
        if (contentOffset.x <= 0.0) {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.x = 0 - contentOffset.x;
            self.upperLeftContainerView.frame = rect;
            
            rect = self.lowerLeftContainerView.frame;
            rect.origin.x = 0 - contentOffset.x;
            self.lowerLeftContainerView.frame = rect;
        }
        else {
            var rect = self.upperLeftContainerView.frame;
            rect.origin.x = 0.0;
            self.upperLeftContainerView.frame = rect;
            
            rect = self.lowerLeftContainerView.frame;
            rect.origin.x = 0.0;
            self.lowerLeftContainerView.frame = rect;
        }
        
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.controllingScrollView == scrollView {
            switch scrollView.tag {
            case MMSpreadsheetViewCollection.upperLeft.rawValue:
                break
            case MMSpreadsheetViewCollection.upperRight.rawValue:
                upperRightCollectionViewDidScroll()
                break
            case MMSpreadsheetViewCollection.lowerLeft.rawValue:
                lowerLeftCollectionViewDidScroll()
                break
            case MMSpreadsheetViewCollection.lowerRight.rawValue:
                lowerRightCollectionViewDidScroll()
                break
            default:
                break
                
            }
        } else {
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.setScrollEnabled(scrollEnabled: false, scrollView: scrollView)
   
            if self.controllingScrollView != scrollView {
                self.lowerLeftCollectionView.setContentOffset(self.lowerLeftCollectionView.contentOffset, animated: false)
                self.upperRightCollectionView.setContentOffset(self.upperRightCollectionView.contentOffset, animated: false)
                self.lowerRightCollectionView.setContentOffset(self.lowerRightCollectionView.contentOffset, animated: false)
                
                    self.controllingScrollView = scrollView
            }
        
        self.setScrollEnabled(scrollEnabled: true, scrollView: scrollView)
    }
    
    public func setScrollEnabled(scrollEnabled: Bool, scrollView: UIScrollView) {
        switch scrollView.tag {
        case MMSpreadsheetViewCollection.upperLeft.rawValue:
            break
        case MMSpreadsheetViewCollection.upperRight.rawValue:
            self.lowerLeftCollectionView.isScrollEnabled = scrollEnabled
            self.lowerRightCollectionView.isScrollEnabled = scrollEnabled
        case MMSpreadsheetViewCollection.lowerLeft.rawValue:
            self.upperRightCollectionView.isScrollEnabled = scrollEnabled
            self.lowerRightCollectionView.isScrollEnabled = scrollEnabled
        case MMSpreadsheetViewCollection.lowerRight.rawValue:
            self.upperRightCollectionView.isScrollEnabled = scrollEnabled
            self.lowerLeftCollectionView.isScrollEnabled = scrollEnabled
        default:
            break
          
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    public func scrollViewDidStop(scrollView: UIScrollView) {
        
    }
}


