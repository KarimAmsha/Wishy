//
//  TapEditableViewDelegate.swift
//  TapEditableView
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//

import TapAdditionsKitV2

public protocol TapEditableViewDelegate: ClassProtocol {

    func editableViewDidBeginEditing(_ editableView: TapEditableView)
    func editableViewDidEndEditing(_ editableView: TapEditableView)
}
