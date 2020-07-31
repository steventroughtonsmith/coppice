//
//  EditableModelObject.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

protocol EditableModelObject: ModelObject {
    func createEditor(with documentWindowState: DocumentWindowViewModel) -> (Editor & NSViewController)?
}


extension Page: EditableModelObject {
    func createEditor(with documentWindowViewModel: DocumentWindowViewModel) -> (Editor & NSViewController)? {
        if UserDefaults.standard.bool(forKey: "M3UseDebugEditors") {
            let viewModel = DebugPageEditorViewModel(page: self)
            return DebugPageEditor(viewModel: viewModel)
        }

        let viewModel = PageEditorViewModel(page: self, documentWindowViewModel: documentWindowViewModel)
        return PageEditorViewController(viewModel: viewModel)
    }
}


extension Canvas: EditableModelObject {
    func createEditor(with documentWindowViewModel: DocumentWindowViewModel) -> (Editor & NSViewController)? {
        guard let modelController = self.modelController else {
            return nil
        }

        if UserDefaults.standard.bool(forKey: "M3UseDebugEditors") {
            let viewModel = DebugCanvasEditorViewModel(canvas: self, modelController: modelController)
            return DebugCanvasEditor(viewModel: viewModel)
        }

        let viewModel = CanvasEditorViewModel(canvas: self, documentWindowViewModel: documentWindowViewModel)
        return CanvasEditorViewController(viewModel: viewModel)
    }
}
