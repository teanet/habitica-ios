//
//  AvatarView.swift
//  Habitica
//
//  Created by Phillip Thelen on 07.02.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import UIKit
import PinLayout
import Kingfisher
import SwiftUI

@objc
enum AvatarViewSize: Int {
    case compact
    case regular
}

@IBDesignable
class AvatarView: UIView {

    @objc var avatar: Avatar? {
        didSet {
            if let dict = avatar?.getFilenameDictionary(ignoreSleeping: ignoreSleeping) {
                nameDictionary = dict
            }
            updateView()
        }
    }
    
    var swappedDict: [String: String] = [:] {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var showBackground: Bool = true
    @IBInspectable var showMount: Bool = true
    @IBInspectable var showPet: Bool = true
    @IBInspectable var isFainted: Bool = false
    @IBInspectable var ignoreSleeping: Bool = false
    @objc var size: AvatarViewSize = .regular
    
    public var onRenderingFinished: (() -> Void)?
    
    private var nameDictionary: [String: String?] = [:]
    private var viewDictionary: [String: Bool] = [:]
    
    private static let viewOrder = [
        "background",
        "mount-body",
        "chair",
        "back",
        "skin",
        "shirt",
        "head_0",
        "armor",
        "body",
        "hair-bangs",
        "hair-base",
        "hair-mustache",
        "hair-beard",
        "eyewear",
        "head",
        "head-accessory",
        "hair-flower",
        "shield",
        "weapon",
        "visual-buff",
        "mount-head",
        "zzz",
        "knockout",
        "pet"
    ]
    
    static var imageFilters: [String: (UIImage) -> UIImage] = [:]
    
    lazy private var constraintsDictionary = [
        "background": backgroundConstraints,
        "mount-body": mountConstraints,
        "chair": characterConstraints,
        "back": characterConstraints,
        "skin": characterConstraints,
        "shirt": characterConstraints,
        "armor": characterConstraints,
        "body": characterConstraints,
        "head_0": characterConstraints,
        "hair-base": characterConstraints,
        "hair-bangs": characterConstraints,
        "hair-mustache": characterConstraints,
        "hair-beard": characterConstraints,
        "eyewear": characterConstraints,
        "head": characterConstraints,
        "head-accessory": characterConstraints,
        "hair-flower": characterConstraints,
        "shield": characterConstraints,
        "weapon": characterConstraints,
        "visual-buff": characterConstraints,
        "mount-head": mountConstraints,
        "zzz": characterConstraints,
        "knockout": characterConstraints,
        "pet": petConstraints
    ]
    
    lazy private var specialConstraintsDictionary = [
        "weapon_special_0": weaponSpecialConstraints,
        "weapon_special_1": weaponSpecialConstraints,
        "weapon_special_critical": weaponSpecialCriticalConstraints,
        "head_special_0": headSpecialConstraints,
        "head_special_1": headSpecialConstraints
    ]
    
    func resize(view: UIImageView, image: UIImage, size: AvatarViewSize) {
        let ratio = image.size.width / image.size.height
        if size == .regular {
            view.pin.aspectRatio(ratio).height(image.size.height * (self.bounds.size.height / 147))
        } else {
            view.pin.aspectRatio(ratio).height(image.size.height * (self.bounds.size.height / 90))
        }
    }
    
    let backgroundConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, _, _ in
        view.pin.all()
    }
    
    let characterConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, size, offset in
        if size == .regular {
            view.pin.start(17%).top(offset)
        } else {
            view.pin.start().top(offset)
        }
    }
    
    let mountConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, _, _ in
        view.pin.start(17.5%).top(12%)
    }
    
    let petConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, _, _ in
        view.pin.start().bottom()
    }
    
    let weaponSpecialConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, size, offset in
        if size == .regular {
            view.pin.start(8%).top(offset)
        } else {
            view.pin.start().top(offset)
        }
    }
    
    let weaponSpecialCriticalConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, size, offset in
        if size == .regular {
            view.pin.start(8%).top(offset+10)
        } else {
            view.pin.start(-10%).top(offset)
        }
    }
    
    let headSpecialConstraints: ((AvatarView, UIImageView, AvatarViewSize, CGFloat) -> Void) = { _, view, size, offset in
        if size == .regular {
            view.pin.start(17%).top(offset+3)
        } else {
            view.pin.start().top(offset+3)
        }
    }
    
    var imageViews = [NetworkImageView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        AvatarView.viewOrder.forEach({ (_) in
            let imageView = NetworkImageView()
            imageView.accessibilityIgnoresInvertColors = true
            addSubview(imageView)
            imageViews.append(imageView)
        })
    }
    
    private func updateView() {
        guard let avatar = self.avatar else {
            return
        }
        viewDictionary = avatar.getViewDictionary(showsBackground: showBackground, showsMount: showMount, showsPet: showPet, isFainted: isFainted, ignoreSleeping: ignoreSleeping)
        
        for entry in swappedDict {
            viewDictionary[entry.key] = true
            nameDictionary[entry.key] = entry.value
        }

        AvatarView.viewOrder.enumerated().forEach({ (index, type) in
            if viewDictionary[type] ?? false {
                let imageView = imageViews[index]
                imageView.isHidden = false
                setImage(imageView, type: type)
            } else {
                let imageView = imageViews[index]
                imageView.image = nil
                imageView.isHidden = true
            }
        })

        if let action = self.onRenderingFinished {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                action()
            }
        }
    }
    
    private func setImage(_ imageView: NetworkImageView, type: String) {
        guard let name = nameDictionary[type] else {
            return
        }
        ImageManager.getImage(name: name ?? "") { image, _ in
            guard let image = image else {
                return
            }
            if let filter = AvatarView.imageFilters[type] {
                imageView.image = filter(image)
            } else {
                imageView.image = image
            }
            self.resize(view: imageView, image: image, size: self.size)
            self.setLayout(imageView, type: type)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    private func layout() {
        AvatarView.viewOrder.enumerated().forEach({ (index, type) in
            if viewDictionary[type] ?? false {
                let imageView = imageViews[index]
                imageView.isHidden = false
                if let image = imageView.image, type != "background" {
                    self.resize(view: imageView, image: image, size: self.size)
                    setLayout(imageView, type: type)
                }
                setLayout(imageView, type: type)
            } else {
                let imageView = imageViews[index]
                imageView.image = nil
                imageView.isHidden = true
            }
        })
    }
    
    private func setLayout(_ imageView: UIImageView, type: String) {
        var offset: CGFloat = 0
        if !(viewDictionary["mount-head"] ?? false) && size == .regular {
            offset = 24
            if viewDictionary["pet"] ?? false {
                offset -= 3
            }
        }
        if nameDictionary["mount-head"]??.contains("Kangaroo") == true && size == .regular {
            offset = 16
        }
        offset *= (self.bounds.size.height / 147)
        let name = nameDictionary[type] ?? ""
        if let name = name, specialConstraintsDictionary[name] != nil {
            specialConstraintsDictionary[name]?(self, imageView, size, offset)
        } else {
            constraintsDictionary[type]?(self, imageView, size, offset)
        }
    }
}

struct AvatarViewUI: UIViewRepresentable {
    var avatar: Avatar
    
    func makeUIView(context: Context) -> AvatarView {
        let avatarView = AvatarView()
        return avatarView
    }
    
    func updateUIView(_ uiView: AvatarView, context: Context) {
        uiView.avatar = avatar
    }
}
