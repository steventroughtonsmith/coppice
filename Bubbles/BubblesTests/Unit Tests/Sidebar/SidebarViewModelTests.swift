////
////  SidebarViewModelTests.swift
////  BubblesTests
////
////  Created by Martin Pilkington on 05/08/2019.
////  Copyright © 2019 M Cubed Software. All rights reserved.
////

import XCTest
@testable import Bubbles


class SidebarViewModelTests: XCTestCase {

    var notificationCenter: NotificationCenter!

    var documentWindowViewModel: DocumentWindowViewModel!

    var modelController: BubblesModelController!

    override func setUp() {
        super.setUp()

        self.notificationCenter = NotificationCenter()

        self.modelController = BubblesModelController(undoManager: UndoManager())

        self.documentWindowViewModel = MockDocumentWindowViewModel(modelController: self.modelController)
    }

    override func tearDown() {
        super.tearDown()

        self.notificationCenter = nil
        self.documentWindowViewModel = nil
    }

    private func createViewModel() -> SidebarViewModel {
        return  SidebarViewModel(documentWindowViewModel: self.documentWindowViewModel,
                                 notificationCenter: self.notificationCenter)
    }


    //MARK: - .rootSidebarNodes
    func test_rootSidebarNodes_returnsCanvasesAndPagesGroupWhenModelControllerIsEmpty() throws {
        let vm = self.createViewModel()

        let sidebarNodes = vm.rootSidebarNodes
        XCTAssertEqual(sidebarNodes.count, 2)

        let canvasNode = try XCTUnwrap(sidebarNodes[safe: 0])
        XCTAssertEqual(canvasNode.item, .canvases)
        XCTAssertEqual(canvasNode.children.count, 0)

        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.item, .folder(self.documentWindowViewModel.rootFolder.id))
        XCTAssertEqual(pagesItem.children.count, 0)
    }

    func test_rootSidebarNodes_returnsNodesInRootFolderAsPartOfPagesGroup() throws {
        let vm = self.createViewModel()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "My First Page"
        }
        let page2 = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Second Page"
            $0.content = ImagePageContent()
        }
        let page3 = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Possums!"
        }
        let folder1 = self.modelController.collection(for: Folder.self).newObject() {
            $0.title = "Empty"
        }
        let folder2 = self.modelController.collection(for: Folder.self).newObject() {
            $0.title = "Last Folder"
        }

        rootFolder.insert([page1, page2, folder1, page3, folder2])
        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        XCTAssertEqual(sidebarNodes.count, 2)

        let canvasNode = try XCTUnwrap(sidebarNodes[safe: 0])
        XCTAssertEqual(canvasNode.item, .canvases)
        XCTAssertEqual(canvasNode.children.count, 0)

        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.item, .folder(rootFolder.id))
        XCTAssertEqual(pagesItem.children.count, 5)

        let page1Node = try XCTUnwrap(pagesItem.children[safe: 0])
        XCTAssertEqual(page1Node.item, .page(page1.id))
        XCTAssertEqual(page1Node.title, page1.title)
        XCTAssertEqual(page1Node.image, NSImage(named: .textPage))

        let page2Node = try XCTUnwrap(pagesItem.children[safe: 1])
        XCTAssertEqual(page2Node.item, .page(page2.id))
        XCTAssertEqual(page2Node.title, page2.title)
        XCTAssertEqual(page2Node.image, NSImage(named: .imagePage))

        let folder1Node = try XCTUnwrap(pagesItem.children[safe: 2])
        XCTAssertEqual(folder1Node.item, .folder(folder1.id))
        XCTAssertEqual(folder1Node.title, folder1.title)
        XCTAssertEqual(folder1Node.image, NSImage(named: .sidebarFolder))

        let page3Node = try XCTUnwrap(pagesItem.children[safe: 3])
        XCTAssertEqual(page3Node.item, .page(page3.id))
        XCTAssertEqual(page3Node.title, page3.title)
        XCTAssertEqual(page3Node.image, NSImage(named: .textPage))

        let folder2Node = try XCTUnwrap(pagesItem.children[safe: 4])
        XCTAssertEqual(folder2Node.item, .folder(folder2.id))
        XCTAssertEqual(folder2Node.title, folder2.title)
        XCTAssertEqual(folder2Node.image, NSImage(named: .sidebarFolder))
    }

    func test_rootSidebarNodes_returnsNodesInFoldersInsidePagesGroup() throws {
        let vm = self.createViewModel()

        let rootFolder = self.documentWindowViewModel.rootFolder
            let page1 = self.modelController.collection(for: Page.self).newObject() {
                $0.title = "My First Page"
            }

            let folder1 = self.modelController.collection(for: Folder.self).newObject() {
                $0.title = "Folder 1"
            }
                let folder1Page1 = self.modelController.collection(for: Page.self).newObject() {
                    $0.title = "Page 1.1"
                }

                let folder1Folder1 = self.modelController.collection(for: Folder.self).newObject() {
                    $0.title = "Folder 1.1"
                }
                    let folder1Folder1Page1 = self.modelController.collection(for: Page.self).newObject() {
                        $0.title = "Page 1.1.1"
                    }
                    let folder1Folder1Page2 = self.modelController.collection(for: Page.self).newObject() {
                        $0.title = "Page 1.1.2"
                    }
                folder1Folder1.insert([folder1Folder1Page1, folder1Folder1Page2])

                let folder1Page2 = self.modelController.collection(for: Page.self).newObject() {
                    $0.title = "Page 1.2"
                }
            folder1.insert([folder1Page1, folder1Folder1, folder1Page2])

            let folder2 = self.modelController.collection(for: Folder.self).newObject() {
                $0.title = "Folder 2"
            }
                let folder2Page1 = self.modelController.collection(for: Page.self).newObject() {
                    $0.title = "Page 2.1"
                }
            folder2.insert([folder2Page1])
        rootFolder.insert([page1, folder1, folder2])


        vm.reloadSidebarNodes()
        let sidebarNodes = vm.rootSidebarNodes
        XCTAssertEqual(sidebarNodes.count, 2)

        let canvasNode = try XCTUnwrap(sidebarNodes[safe: 0])
        XCTAssertEqual(canvasNode.item, .canvases)
        XCTAssertEqual(canvasNode.children.count, 0)

        let pagesNode = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesNode.item, .folder(rootFolder.id))
        XCTAssertEqual(pagesNode.children.count, 3)

        let page1Item = try XCTUnwrap(pagesNode.children[safe: 0])
        XCTAssertEqual(page1Item.item, .page(page1.id))

        let folder1Item = try XCTUnwrap(pagesNode.children[safe: 1])
        XCTAssertEqual(folder1Item.item, .folder(folder1.id))
        XCTAssertEqual(folder1Item.children.count, 3)
        //START FOLDER 1
        let folder1Page1Item = try XCTUnwrap(folder1Item.children[safe: 0])
        XCTAssertEqual(folder1Page1Item.item, .page(folder1Page1.id))
        XCTAssertEqual(folder1Page1Item.title, folder1Page1.title)
        XCTAssertEqual(folder1Page1Item.image, NSImage(named: .textPage))

        //START FOLDER 1.1
        let folder1Folder1Item = try XCTUnwrap(folder1Item.children[safe: 1])
        XCTAssertEqual(folder1Folder1Item.children.count, 2)
        XCTAssertEqual(folder1Folder1Item.item, .folder(folder1Folder1.id))
        XCTAssertEqual(folder1Folder1Item.title, folder1Folder1.title)
        XCTAssertEqual(folder1Folder1Item.image, NSImage(named: .sidebarFolder))

        let folder1Folder1Page1Item = try XCTUnwrap(folder1Folder1Item.children[safe: 0])
        XCTAssertEqual(folder1Folder1Page1Item.item, .page(folder1Folder1Page1.id))
        XCTAssertEqual(folder1Folder1Page1Item.title, folder1Folder1Page1.title)
        XCTAssertEqual(folder1Folder1Page1Item.image, NSImage(named: .textPage))

        let folder1Folder1Page2Item = try XCTUnwrap(folder1Folder1Item.children[safe: 1])
        XCTAssertEqual(folder1Folder1Page2Item.item, .page(folder1Folder1Page2.id))
        XCTAssertEqual(folder1Folder1Page2Item.title, folder1Folder1Page2.title)
        XCTAssertEqual(folder1Folder1Page2Item.image, NSImage(named: .textPage))
        //END FOLDER 1.1

        let folder1Page2Item = try XCTUnwrap(folder1Item.children[safe: 2])
        XCTAssertEqual(folder1Page2Item.item, .page(folder1Page2.id))
        XCTAssertEqual(folder1Page2Item.title, folder1Page2.title)
        XCTAssertEqual(folder1Page2Item.image, NSImage(named: .textPage))
        //END FOLDER 1

        let folder2Item = try XCTUnwrap(pagesNode.children[safe: 2])
        XCTAssertEqual(folder2Item.item, .folder(folder2.id))
        XCTAssertEqual(folder2Item.children.count, 1)

        let folder2Page1Item = try XCTUnwrap(folder2Item.children[safe: 0])
        XCTAssertEqual(folder2Page1Item.item, .page(folder2Page1.id))
        XCTAssertEqual(folder2Page1Item.title, folder2Page1.title)
        XCTAssertEqual(folder2Page1Item.image, NSImage(named: .textPage))
    }

    func test_rootSidebarNodes_reloadsNodesWhenPageAdded() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPagesItem = try XCTUnwrap(initialSidebarNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 0)

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page1])

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 1)
    }

    func test_rootSidebarNodes_reloadsNodesWhenPageRemoved() throws {
        let vm = self.createViewModel()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page1])

        vm.reloadSidebarNodes()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPagesItem = try XCTUnwrap(initialSidebarNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 1)

        self.documentWindowViewModel.delete([.page(page1.id)])

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 0)
    }

    func test_rootSidebarNodes_reloadsNodesWhenFolderAdded() throws {
        let vm = self.createViewModel()
        vm.reloadSidebarNodes()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPagesItem = try XCTUnwrap(initialSidebarNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 0)


        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder1])

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 1)
    }

    func test_rootSidebarNodes_reloadsNodesWhenFolderRemoved() throws {
        let vm = self.createViewModel()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder1])

        vm.reloadSidebarNodes()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPagesItem = try XCTUnwrap(initialSidebarNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 1)

        self.documentWindowViewModel.delete([.folder(folder1.id)])

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 0)
    }

    func test_rootSidebarNodes_reloadsNodesWhenItemMovedToNewFolder() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([folder1, page1])

        vm.reloadSidebarNodes()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPagesItem = try XCTUnwrap(initialSidebarNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 2)
        let initialFolderItem = try XCTUnwrap(initialPagesItem.children[safe: 0])
        XCTAssertEqual(initialFolderItem.children.count, 0)

        folder1.insert([page1])

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pagesItem = try XCTUnwrap(sidebarNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 1)
        let folderItem = try XCTUnwrap(pagesItem.children[safe: 0])
        XCTAssertEqual(folderItem.children.count, 1)
    }

    func test_rootSidebarNodes_rootNodesAreIdenticalAcrossReloads() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialCanvases = try XCTUnwrap(initialSidebarNodes[safe: 0])
        let initialPageGroup = try XCTUnwrap(initialSidebarNodes[safe: 1])
        self.modelController.collection(for: Page.self).newObject()

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let canvases = try XCTUnwrap(sidebarNodes[safe: 0])
        let pageGroup = try XCTUnwrap(sidebarNodes[safe: 1])

        XCTAssertTrue(initialCanvases === canvases)
        XCTAssertTrue(initialPageGroup === pageGroup)
    }

    func test_rootSidebarNodes_pageNodesAreIdenticalAcrossReloads() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page1])
        vm.reloadSidebarNodes()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPageGroup = try XCTUnwrap(initialSidebarNodes[safe: 1])
        let initialPageNode = try XCTUnwrap(initialPageGroup.children[safe: 0])

        self.modelController.collection(for: Page.self).newObject()

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pageGroup = try XCTUnwrap(sidebarNodes[safe: 1])
        let pageNode = try XCTUnwrap(pageGroup.children[safe: 0])

        XCTAssertTrue(initialPageNode === pageNode)
    }

    func test_rootSidebarNodes_folderNodesAreIdenticalAcrossReloads() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder1])
        vm.reloadSidebarNodes()

        let initialSidebarNodes = vm.rootSidebarNodes
        let initialPageGroup = try XCTUnwrap(initialSidebarNodes[safe: 1])
        let initialFolderNode = try XCTUnwrap(initialPageGroup.children[safe: 0])

        self.modelController.collection(for: Folder.self).newObject()

        vm.reloadSidebarNodes()

        let sidebarNodes = vm.rootSidebarNodes
        let pageGroup = try XCTUnwrap(sidebarNodes[safe: 1])
        let folderNode = try XCTUnwrap(pageGroup.children[safe: 0])

        XCTAssertTrue(initialFolderNode === folderNode)
    }
}


//MARK: - Helpers

private class MockSidebarView: SidebarView {
    func prepareForReload() {

    }
    var reloadCalled = false
    func reload() {
        self.reloadCalled = true
    }

    var reloadSelectionCalled = false
    func reloadSelection() {
        self.reloadSelectionCalled = true
    }

    var reloadCanvasesCalled = false
    func reloadCanvases() {
        self.reloadCanvasesCalled = true
    }

    var reloadPagesCalled = false
    func reloadPages() {
        self.reloadPagesCalled = true
    }
}

