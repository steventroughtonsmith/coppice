//
//  ModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ModelController: NSObject {
    weak var document: Document?

    func createTestData() {
        let canvas1 = self.newCanvas()
        canvas1.title = "First"
        let canvas2 = self.newCanvas()
        canvas2.title = "Second!"

        let page1 = self.newPage()
        page1.title = "Foo"
        let page2 = self.newPage()
        page2.title = "Bar"
        let page3 = self.newPage()
        page3.title = "Baz"
    }

    //MARK: - Canvas
    private (set) var allCanvases = [Canvas]()

    func canvasWithID(_ id: UUID) -> Canvas? {
        for canvas in self.allCanvases {
            if canvas.id == id {
                return canvas
            }
        }
        return nil
    }

    func newCanvas() -> Canvas {
        let canvas = Canvas()
        self.allCanvases.append(canvas)
        return canvas
    }

    func delete(_ canvas: Canvas) {
        if let index = self.allCanvases.firstIndex(of: canvas) {
            self.allCanvases.remove(at: index)
        }
    }

    //MARK: - Pages
    private (set) var allPages = [Page]()

    func pageWithID(_ id: UUID) -> Page? {
        for page in self.allPages {
            if page.id == id {
                return page
            }
        }
        return nil
    }

    func newPage() -> Page {
        let page = Page()
        self.allPages.append(page)
        return page
    }

    func delete(_ page: Page) {
        if let index = self.allPages.firstIndex(of: page) {
            self.allPages.remove(at: index)
        }
    }
}
