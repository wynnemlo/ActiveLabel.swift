//
//  ActiveLabel.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

public protocol ActiveLabelDelegate: class {
    func didSelect(_ text: String, type: ActiveType)
}

@IBDesignable public class ActiveLabel: UILabel {
    
    // MARK: - public properties
    public weak var delegate: ActiveLabelDelegate?
    
    @IBInspectable public var mentionColor: UIColor = .blue() {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var mentionSelectedColor: UIColor? {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var hashtagColor: UIColor = .blue() {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var hashtagSelectedColor: UIColor? {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var URLColor: UIColor = .blue() {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var URLSelectedColor: UIColor? {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var lineSpacing: Float = 0 {
        didSet { updateTextStorage(parseText: false) }
    }

    // MARK: - public methods
    public func handleMentionTap(handler: (String) -> ()) {
        mentionTapHandler = handler
    }
    
    public func handleHashtagTap(handler: (String) -> ()) {
        hashtagTapHandler = handler
    }
    
    public func handleURLTap(handler: (URL) -> ()) {
        urlTapHandler = handler
    }

    public func filterMention(predicate: (String) -> Bool) {
        mentionFilterPredicate = predicate
        updateTextStorage()
    }

    public func filterHashtag(predicate: (String) -> Bool) {
        hashtagFilterPredicate = predicate
        updateTextStorage()
    }

    // MARK: - override UILabel properties
    override public var text: String? {
        didSet { updateTextStorage() }
    }
    
    override public var attributedText: AttributedString? {
        didSet { updateTextStorage() }
    }
    
    override public var font: UIFont! {
        didSet { updateTextStorage(parseText: false) }
    }
    
    override public var textColor: UIColor! {
        didSet { updateTextStorage(parseText: false) }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet { updateTextStorage(parseText: false)}
    }

    public override var numberOfLines: Int {
        didSet { textContainer.maximumNumberOfLines = numberOfLines }
    }
    
    public override var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }
    
    // MARK: - init functions
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _customizing = false
        setupLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _customizing = false
        setupLabel()
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        updateTextStorage()
    }
    
    public override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
    
    
    // MARK: - customzation
    public func customize(block: (label: ActiveLabel) -> ()) -> ActiveLabel{
        _customizing = true
        block(label: self)
        _customizing = false
        updateTextStorage()
        return self
    }

    // MARK: - Auto layout
    public override func intrinsicContentSize() -> CGSize {
        let superSize = super.intrinsicContentSize()
        textContainer.size = CGSize(width: superSize.width, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    // MARK: - touch events
    func onTouch(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .began, .moved:
            if let element = element(at: location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    updateAttributesWhenSelected(false)
                    selectedElement = element
                    updateAttributesWhenSelected(true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(false)
                selectedElement = nil
            }
        case .ended:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            switch selectedElement.element {
            case .mention(let userHandle): didTap(username: userHandle)
            case .hashtag(let hashtag): didTap(hashtag: hashtag)
            case .url(let url): didTap(stringURL: url)
            case .none: ()
            }
            
            let when = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.after(when: when) {
                self.updateAttributesWhenSelected(false)
                self.selectedElement = nil
            }
            avoidSuperCall = true
        case .cancelled:
            updateAttributesWhenSelected(false)
            selectedElement = nil
        case .stationary:
            break
        }
        
        return avoidSuperCall
    }
    
    // MARK: - private properties
    private var _customizing: Bool = true
    
    private var mentionTapHandler: ((String) -> ())?
    private var hashtagTapHandler: ((String) -> ())?
    private var urlTapHandler: ((URL) -> ())?

    private var mentionFilterPredicate: ((String) -> Bool)?
    private var hashtagFilterPredicate: ((String) -> Bool)?

    private var selectedElement: (range: NSRange, element: ActiveElement)?
    private var heightCorrection: CGFloat = 0
    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()
    internal lazy var activeElements: [ActiveType: [(range: NSRange, element: ActiveElement)]] = [
        .mention: [],
        .hashtag: [],
        .url: [],
    ]
    
    // MARK: - helper functions
    private func setupLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        isUserInteractionEnabled = true
    }
    
    private func updateTextStorage(parseText: Bool = true) {
        if _customizing { return }
        // clean up previous active elements
        guard let attributedText = attributedText where attributedText.length > 0 else {
            clearActiveElements()
            textStorage.setAttributedString(AttributedString())
            setNeedsDisplay()
            return
        }
        
        let mutAttrString = addLineBreak(to: attributedText)

        if parseText {
            clearActiveElements()
            parseTextAndExtractActiveElements(from: mutAttrString)
        }
        
        self.addLinkAttribute(to: mutAttrString)
        self.textStorage.setAttributedString(mutAttrString)
        self.setNeedsDisplay()
    }

    private func clearActiveElements() {
        selectedElement = nil
        for (type, _) in activeElements {
            activeElements[type]?.removeAll()
        }
    }

    private func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    /// add link attribute
    private func addLinkAttribute(to mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        attributes[NSFontAttributeName] = font!
        attributes[NSForegroundColorAttributeName] = textColor
        mutAttrString.addAttributes(attributes, range: range)
        
        attributes[NSForegroundColorAttributeName] = mentionColor
        
        for (type, elements) in activeElements {
            
            switch type {
            case .mention: attributes[NSForegroundColorAttributeName] = mentionColor
            case .hashtag: attributes[NSForegroundColorAttributeName] = hashtagColor
            case .url: attributes[NSForegroundColorAttributeName] = URLColor
            case .none: ()
            }
            
            for element in elements {
                mutAttrString.setAttributes(attributes, range: element.range)
            }
        }
    }
    
    /// use regex check all link ranges
    private func parseTextAndExtractActiveElements(from attrString: AttributedString) {
        let textString = attrString.string
        let textLength = textString.utf16.count
        let textRange = NSRange(location: 0, length: textLength)
        
        //URLS
        let urlElements = ActiveBuilder.createURLElements(fromText: textString, range: textRange)
        activeElements[.url]?.append(contentsOf: urlElements)

        //HASHTAGS
        let hashtagElements = ActiveBuilder.createHashtagElements(fromText: textString, range: textRange, filterPredicate: hashtagFilterPredicate)
        activeElements[.hashtag]?.append(contentsOf: hashtagElements)

        //MENTIONS
        let mentionElements = ActiveBuilder.createMentionElements(fromText: textString, range: textRange, filterPredicate: mentionFilterPredicate)
        activeElements[.mention]?.append(contentsOf: mentionElements)
    }

    
    /// add line break mode
    private func addLineBreak(to attrString: AttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = CGFloat(lineSpacing)
        
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    private func updateAttributesWhenSelected(_ isSelected: Bool) {
        guard let selectedElement = selectedElement else {
            return
        }
        
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        if isSelected {
            switch selectedElement.element {
            case .mention(_): attributes[NSForegroundColorAttributeName] = mentionSelectedColor ?? mentionColor
            case .hashtag(_): attributes[NSForegroundColorAttributeName] = hashtagSelectedColor ?? hashtagColor
            case .url(_): attributes[NSForegroundColorAttributeName] = URLSelectedColor ?? URLColor
            case .none: ()
            }
        } else {
            switch selectedElement.element {
            case .mention(_): attributes[NSForegroundColorAttributeName] = mentionColor
            case .hashtag(_): attributes[NSForegroundColorAttributeName] = hashtagColor
            case .url(_): attributes[NSForegroundColorAttributeName] = URLColor
            case .none: ()
            }
        }
        
        textStorage.addAttributes(attributes, range: selectedElement.range)
        
        setNeedsDisplay()
    }
    
    private func element(at location: CGPoint) -> (range: NSRange, element: ActiveElement)? {
        guard textStorage.length > 0 else {
            return nil
        }

        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        
        for element in activeElements.map({ $0.1 }).flatten() {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
            }
        }
        
        return nil
    }
    
    
    //MARK: - Handle UI Responder touches
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, with: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesMoved(touches, with: event)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesCancelled(touches, with: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, with: event)
    }
    
    //MARK: - ActiveLabel handler
    private func didTap(username: String) {
        guard let mentionHandler = mentionTapHandler else {
            delegate?.didSelect(username, type: .mention)
            return
        }
        mentionHandler(username)
    }
    
    private func didTap(hashtag: String) {
        guard let hashtagHandler = hashtagTapHandler else {
            delegate?.didSelect(hashtag, type: .hashtag)
            return
        }
        hashtagHandler(hashtag)
    }
    
    private func didTap(stringURL: String) {
        guard let urlHandler = urlTapHandler, let url = URL(string: stringURL) else {
            delegate?.didSelect(stringURL, type: .url)
            return
        }
        urlHandler(url)
    }
}

extension ActiveLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
