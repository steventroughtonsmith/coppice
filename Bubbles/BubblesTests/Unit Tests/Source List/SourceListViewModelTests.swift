////
////  SourceListViewModelTests.swift
////  BubblesTests
////
////  Created by Martin Pilkington on 05/08/2019.
////  Copyright © 2019 M Cubed Software. All rights reserved.
////

import XCTest
@testable import Bubbles


class SourceListViewModelTests: XCTestCase {

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

    private func createViewModel() -> SourceListViewModel {
        return  SourceListViewModel(documentWindowViewModel: self.documentWindowViewModel,
                                 notificationCenter: self.notificationCenter)
    }

    private func addTestData(to viewModel: SourceListViewModel) -> (Page, Folder, Page, Page) {
        let rootFolder = self.documentWindowViewModel.rootFolder
        let page = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page])
        let folder = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder], below: page)
        let subPage1 = self.modelController.collection(for: Page.self).newObject()
        folder.insert([subPage1])
        let page2 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page2], below: folder)
        viewModel.reloadSourceListNodes()

        return (page, folder, subPage1, page2)
    }


    //MARK: - .rootSourceListNodes
    func test_rootSourceListNodes_returnsCanvasesAndPagesGroupWhenModelControllerIsEmpty() throws {
        let vm = self.createViewModel()

        let sourceListNodes = vm.rootSourceListNodes
        XCTAssertEqual(sourceListNodes.count, 2)

        let canvasNode = try XCTUnwrap(sourceListNodes[safe: 0])
        XCTAssertEqual(canvasNode.item, .canvases)
        XCTAssertEqual(canvasNode.children.count, 0)

        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
        XCTAssertEqual(pagesItem.item, .folder(self.documentWindowViewModel.rootFolder.id))
        XCTAssertEqual(pagesItem.children.count, 0)
    }

    func test_rootSourceListNodes_returnsNodesInRootFolderAsPartOfPagesGroup() throws {
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
        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        XCTAssertEqual(sourceListNodes.count, 2)

        let canvasNode = try XCTUnwrap(sourceListNodes[safe: 0])
        XCTAssertEqual(canvasNode.item, .canvases)
        XCTAssertEqual(canvasNode.children.count, 0)

        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
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

    func test_rootSourceListNodes_returnsNodesInFoldersInsidePagesGroup() throws {
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


        vm.reloadSourceListNodes()
        let sourceListNodes = vm.rootSourceListNodes
        XCTAssertEqual(sourceListNodes.count, 2)

        let canvasNode = try XCTUnwrap(sourceListNodes[safe: 0])
        XCTAssertEqual(canvasNode.item, .canvases)
        XCTAssertEqual(canvasNode.children.count, 0)

        let pagesNode = try XCTUnwrap(sourceListNodes[safe: 1])
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

    func test_rootSourceListNodes_reloadsNodesWhenPageAdded() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPagesItem = try XCTUnwrap(initialSourceListNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 0)

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page1])

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 1)
    }

    func test_rootSourceListNodes_reloadsNodesWhenPageRemoved() throws {
        let vm = self.createViewModel()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page1])

        vm.reloadSourceListNodes()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPagesItem = try XCTUnwrap(initialSourceListNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 1)

        self.documentWindowViewModel.delete([.page(page1.id)])

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 0)
    }

    func test_rootSourceListNodes_reloadsNodesWhenFolderAdded() throws {
        let vm = self.createViewModel()
        vm.reloadSourceListNodes()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPagesItem = try XCTUnwrap(initialSourceListNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 0)


        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder1])

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 1)
    }

    func test_rootSourceListNodes_reloadsNodesWhenFolderRemoved() throws {
        let vm = self.createViewModel()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder1])

        vm.reloadSourceListNodes()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPagesItem = try XCTUnwrap(initialSourceListNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 1)

        self.documentWindowViewModel.delete([.folder(folder1.id)])

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 0)
    }

    func test_rootSourceListNodes_reloadsNodesWhenItemMovedToNewFolder() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([folder1, page1])

        vm.reloadSourceListNodes()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPagesItem = try XCTUnwrap(initialSourceListNodes[safe: 1])
        XCTAssertEqual(initialPagesItem.children.count, 2)
        let initialFolderItem = try XCTUnwrap(initialPagesItem.children[safe: 0])
        XCTAssertEqual(initialFolderItem.children.count, 0)

        folder1.insert([page1])

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pagesItem = try XCTUnwrap(sourceListNodes[safe: 1])
        XCTAssertEqual(pagesItem.children.count, 1)
        let folderItem = try XCTUnwrap(pagesItem.children[safe: 0])
        XCTAssertEqual(folderItem.children.count, 1)
    }

    func test_rootSourceListNodes_rootNodesAreIdenticalAcrossReloads() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialCanvases = try XCTUnwrap(initialSourceListNodes[safe: 0])
        let initialPageGroup = try XCTUnwrap(initialSourceListNodes[safe: 1])
        self.modelController.collection(for: Page.self).newObject()

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let canvases = try XCTUnwrap(sourceListNodes[safe: 0])
        let pageGroup = try XCTUnwrap(sourceListNodes[safe: 1])

        XCTAssertTrue(initialCanvases === canvases)
        XCTAssertTrue(initialPageGroup === pageGroup)
    }

    func test_rootSourceListNodes_pageNodesAreIdenticalAcrossReloads() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page1 = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page1])
        vm.reloadSourceListNodes()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPageGroup = try XCTUnwrap(initialSourceListNodes[safe: 1])
        let initialPageNode = try XCTUnwrap(initialPageGroup.children[safe: 0])

        self.modelController.collection(for: Page.self).newObject()

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pageGroup = try XCTUnwrap(sourceListNodes[safe: 1])
        let pageNode = try XCTUnwrap(pageGroup.children[safe: 0])

        XCTAssertTrue(initialPageNode === pageNode)
    }

    func test_rootSourceListNodes_folderNodesAreIdenticalAcrossReloads() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let folder1 = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder1])
        vm.reloadSourceListNodes()

        let initialSourceListNodes = vm.rootSourceListNodes
        let initialPageGroup = try XCTUnwrap(initialSourceListNodes[safe: 1])
        let initialFolderNode = try XCTUnwrap(initialPageGroup.children[safe: 0])

        self.modelController.collection(for: Folder.self).newObject()

        vm.reloadSourceListNodes()

        let sourceListNodes = vm.rootSourceListNodes
        let pageGroup = try XCTUnwrap(sourceListNodes[safe: 1])
        let folderNode = try XCTUnwrap(pageGroup.children[safe: 0])

        XCTAssertTrue(initialFolderNode === folderNode)
    }


    //MARK: - .allNodes
    func test_allNodes_includesRootNodes() {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page])
        let folder = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder])
        let subPage = self.modelController.collection(for: Page.self).newObject()
        folder.insert([subPage])
        vm.reloadSourceListNodes()

        vm.rootSourceListNodes.forEach {
            XCTAssertTrue(vm.allNodes.contains($0))
        }
    }

    func test_allNodes_includesSubnodes() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let rootFolder = self.documentWindowViewModel.rootFolder
        let page = self.modelController.collection(for: Page.self).newObject()
        rootFolder.insert([page])
        let folder = self.modelController.collection(for: Folder.self).newObject()
        rootFolder.insert([folder])
        let subPage = self.modelController.collection(for: Page.self).newObject()
        folder.insert([subPage])
        vm.reloadSourceListNodes()

        let folderNode = try XCTUnwrap(vm.pagesGroupNode.children[safe: 0])
        let pageNode = try XCTUnwrap(vm.pagesGroupNode.children[safe: 1])
        let subPageNode = try XCTUnwrap(folderNode.children[safe: 0])
        XCTAssertTrue(vm.allNodes.contains(pageNode))
        XCTAssertTrue(vm.allNodes.contains(folderNode))
        XCTAssertTrue(vm.allNodes.contains(subPageNode))
    }


    //MARK: - updateSelectedNodes(with:)
    func test_updateSelectedNodes_setsSelectedNodesToMatchSuppliedPageItems() {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, subPage, _) = self.addTestData(to: vm)

        vm.updateSelectedNodes(with: [.page(page1.id), .page(subPage.id)])

        XCTAssertEqual(vm.selectedNodes.count, 2)
        XCTAssertTrue(vm.selectedNodes.contains(where: { $0.item == .page(page1.id) }))
        XCTAssertTrue(vm.selectedNodes.contains(where: { $0.item == .page(subPage.id) }))

    }

    func test_updateSelectedNodes_setsSelectedNodesToMatchSuppliedFolderItems() {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, _, _) = self.addTestData(to: vm)

        vm.updateSelectedNodes(with: [.folder(folder.id)])

        XCTAssertEqual(vm.selectedNodes.count, 1)
        XCTAssertTrue(vm.selectedNodes.contains(where: { $0.item == .folder(folder.id) }))
    }

    func test_updateSelectedNodes_setsSelectedNodesToCanvasesIfSuppliedItemsContainsCanvases() {
        let vm = self.createViewModel()
        vm.startObserving()

        vm.updateSelectedNodes(with: [.canvas(Canvas.modelID(with: UUID()))])

        XCTAssertEqual(vm.selectedNodes.count, 1)
        XCTAssertTrue(vm.selectedNodes.contains(where: { $0.item == .canvases }))
    }


    //MARK: - canDropItems(with:onto:atChildIndex:)
    func test_candDropItemsWithIDsOntoNode_returnsFalseIfNodeIsAPage() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, folder, subpage1, page2) = self.addTestData(to: vm)

        let node = try XCTUnwrap(vm.node(for: .page(page1.id)))

        let (canDrop, _, _) = vm.canDropItems(with: [folder.id, subpage1.id, page2.id], onto: node, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_candDropItemsWithIDsOntoNode_returnsFalseIfNodeIsCanvasesGroup() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)

        let (canDrop, _, _) = vm.canDropItems(with: [folder.id, subpage1.id, page2.id], onto: vm.canvasesNode, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropItemsWithIDsOntoNode_returnsFalseIfNodesFolderIsInIDs() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .folder(folder.id)))
        let rootFolder = self.documentWindowViewModel.rootFolder

        let (canDrop, _, _) = vm.canDropItems(with: [rootFolder.id, subpage1.id, page2.id], onto: node, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropItemsWithIDsOntoNode_returnsFalseIfNodesFoldersAncestorIsInIDs() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let childFolder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childFolder])
        vm.reloadSourceListNodes()
        let node = try XCTUnwrap(vm.node(for: .folder(childFolder.id)))
        let rootFolder = self.documentWindowViewModel.rootFolder

        let (canDrop, _, _) = vm.canDropItems(with: [rootFolder.id, subpage1.id, page2.id], onto: node, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropItemsWithIDsOntoNode_returnsFalseIfOneIDIsACanvasID() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .folder(folder.id)))

        let (canDrop, _, _) = vm.canDropItems(with: [subpage1.id, Canvas.modelID(with: UUID()), page2.id], onto: node, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropItemsWithIDsOntoNode_returnsFalseIfOneIDIsACanvasPageID() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .folder(folder.id)))

        let (canDrop, _, _) = vm.canDropItems(with: [subpage1.id, CanvasPage.modelID(with: UUID()), page2.id], onto: node, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropItemsWithIDsOntoNode_returnsTrueIfDroppedOntoFolderAndAllIDsArePagesOrFolders() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, _, page2) = self.addTestData(to: vm)

        let (canDrop, _, _) = vm.canDropItems(with: [folder.id, page2.id], onto: vm.pagesGroupNode, atChildIndex: 0)
        XCTAssertTrue(canDrop)
    }


    //MARK: - dropItems(with:onto:aChildIndex:)
    func test_dropItemsWithIDsOntoNode_returnsFalseIfNodeIsAPage() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, folder, subpage1, page2) = self.addTestData(to: vm)

        let node = try XCTUnwrap(vm.node(for: .page(page1.id)))

        XCTAssertFalse(vm.dropItems(with: [folder.id, subpage1.id, page2.id], onto: node, atChildIndex: -1))
    }

    func test_dropItemsWithIDsOntoNode_returnsFalseIfnodeIsCanvasesGroup() {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)

        XCTAssertFalse(vm.dropItems(with: [folder.id, subpage1.id, page2.id], onto: vm.canvasesNode, atChildIndex: -1))
    }

    func test_dropItemsWithIDsOntoNode_returnsFalseIfNodesFolderIsInIDs() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .folder(folder.id)))
        let rootFolder = self.documentWindowViewModel.rootFolder

        XCTAssertFalse(vm.dropItems(with: [rootFolder.id, subpage1.id, page2.id], onto: node, atChildIndex: -1))
    }

    func test_dropItemsWithIDsOntoNode_returnsFalseIfNodesFolderAncestorIsInIDs() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let childFolder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childFolder])
        vm.reloadSourceListNodes()
        let node = try XCTUnwrap(vm.node(for: .folder(childFolder.id)))
        let rootFolder = self.documentWindowViewModel.rootFolder

        XCTAssertFalse(vm.dropItems(with: [rootFolder.id, subpage1.id, page2.id], onto: node, atChildIndex: -1))
    }

    func test_dropItemsWithIDsOntoNode_returnsFalseIfOneIDIsACanvasID() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .folder(folder.id)))

        XCTAssertFalse(vm.dropItems(with: [subpage1.id, Canvas.modelID(with: UUID()), page2.id], onto: node, atChildIndex: -1))
    }

    func test_dropItemsWithIDsOntoNode_returnsFalseIfOneIDIsACanvasPageID() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, subpage1, page2) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .folder(folder.id)))

        XCTAssertFalse(vm.dropItems(with: [subpage1.id, CanvasPage.modelID(with: UUID()), page2.id], onto: node, atChildIndex: -1))
    }

    func test_dropItemsWithIDsOntoNode_insertsItemsToEndOfFolderIfIndexIsMinus1() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, folder, _, _) = self.addTestData(to: vm)

        XCTAssertTrue(vm.dropItems(with: [page1.id, folder.id], onto: vm.pagesGroupNode, atChildIndex: -1))

        let rootFolder = self.documentWindowViewModel.rootFolder
        XCTAssertEqual(rootFolder.contents[safe: 1] as? Page, page1)
        XCTAssertEqual(rootFolder.contents[safe: 2] as? Folder, folder)
    }

    func test_dropItemsWithIDsOntoNode_insertsItemsBelowFirstItemOfFolderIfIndexIs0() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, folder, _, page2) = self.addTestData(to: vm)

        XCTAssertTrue(vm.dropItems(with: [folder.id, page2.id], onto: vm.pagesGroupNode, atChildIndex: 0))

        let rootFolder = self.documentWindowViewModel.rootFolder
        XCTAssertEqual(rootFolder.contents[safe: 0] as? Folder, folder)
        XCTAssertEqual(rootFolder.contents[safe: 1] as? Page, page2)
    }

    func test_dropItemsWithIDsOntoNode_insertsItemsBelowItemAtIndex() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, _) = self.addTestData(to: vm)

        XCTAssertTrue(vm.dropItems(with: [page1.id], onto: vm.pagesGroupNode, atChildIndex: 2))

        let rootFolder = self.documentWindowViewModel.rootFolder
        XCTAssertEqual(rootFolder.contents[safe: 1] as? Page, page1)
    }


    //MARK: - canDropFiles(at:onto:atChildIndex:)
    func test_canDropFilesAtURLsOntoNode_returnsFalseIfNodeIsNilAndURLsContainsNonValidType() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))
        let zipURL = try XCTUnwrap(self.testBundle.url(forResource: "test-zip", withExtension: "zip"))

        let (canDrop, _, _) = vm.canDropFiles(at: [textURL, imageURL, zipURL], onto: nil, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropFilesAtURLsOntoNode_returnsTrueIfNodeIsNilAndURLsAreImagesAndTextFiles() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let (canDrop, _, _) = vm.canDropFiles(at: [textURL, imageURL], onto: nil, atChildIndex: -1)
        XCTAssertTrue(canDrop)
    }

    func test_canDropFilesAtURLsOntoNode_returnsDropOnPageGroupNodeIfNodeIsNilAndURLsAreImagesAndTextFiles() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let (_, targetNode, targetIndex) = vm.canDropFiles(at: [textURL, imageURL], onto: nil, atChildIndex: -1)
        XCTAssertEqual(targetNode, vm.pagesGroupNode)
        XCTAssertEqual(targetIndex, -1)
    }

    func test_canDropFilesAtURLsOntoNode_returnsFalseIfNodeIsPage() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, _) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .page(page1.id)))

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let (canDrop, _, _) = vm.canDropFiles(at: [textURL, imageURL], onto: node, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropFilesAtURLsOntoNode_returnsFalseIfNodeIsCanvases() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let (canDrop, _, _) = vm.canDropFiles(at: [textURL, imageURL], onto: vm.canvasesNode, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropFilesAtURLsOntoNode_returnsFalseIfNodeIsFolderAndURLsContainsNonValidTypes() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))
        let zipURL = try XCTUnwrap(self.testBundle.url(forResource: "test-zip", withExtension: "zip"))

        let (canDrop, _, _) = vm.canDropFiles(at: [textURL, imageURL, zipURL], onto: vm.pagesGroupNode, atChildIndex: -1)
        XCTAssertFalse(canDrop)
    }

    func test_canDropFilesAtURLsOntoNode_returnsTrueIfNodeIsFolderAndURLsAreImagesAndTextFiles() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let (canDrop, _, _) = vm.canDropFiles(at: [textURL, imageURL], onto: vm.pagesGroupNode, atChildIndex: 1)
        XCTAssertTrue(canDrop)
    }

    func test_canDropFilesAtURLsOntoNode_returnsSuppliedNodeAndINdexIfNodeIsFolderAndURLsAreImagesAndTextFiles() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let (_, targetNode, targetIndex) = vm.canDropFiles(at: [textURL, imageURL], onto: vm.pagesGroupNode, atChildIndex: 1)
        XCTAssertEqual(targetNode, vm.pagesGroupNode)
        XCTAssertEqual(targetIndex, 1)
    }


    //MARK: - dropFiles(at:onto:atChildIndex:)
    func test_dropFilesAtURLsOntoNode_returnsFalseIfNodeIsNil() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        XCTAssertFalse(vm.dropFiles(at: [textURL, imageURL], onto: nil, atChildIndex: -1))
    }

    func test_dropFilesAtURLsOntoNode_returnsFalseIfNodeItemIsPage() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, _) = self.addTestData(to: vm)
        let node = try XCTUnwrap(vm.node(for: .page(page1.id)))

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        XCTAssertFalse(vm.dropFiles(at: [textURL, imageURL], onto: node, atChildIndex: -1))
    }

    func test_dropFilesAtURLsOntoNode_returnsFalseIfNodeItemIsCanvases() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        XCTAssertFalse(vm.dropFiles(at: [textURL, imageURL], onto: vm.canvasesNode, atChildIndex: -1))
    }

    func test_dropFilesAtURLsOntoNode_returnsFalseIfFolderDoesNotExist() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        XCTAssertFalse(vm.dropFiles(at: [textURL, imageURL], onto: FolderSourceListNode(folder: Folder()), atChildIndex: -1))
    }

    func test_dropFilesAtURLsOntoNode_returnsFalseIfURLsContainsNonValidTypes() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))
        let zipURL = try XCTUnwrap(self.testBundle.url(forResource: "test-zip", withExtension: "zip"))

        XCTAssertFalse(vm.dropFiles(at: [textURL, imageURL, zipURL], onto: vm.pagesGroupNode, atChildIndex: -1))
    }

    func test_dropFilesAtURLsOntoNode_returnsTrueIfURLsAreValid() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        XCTAssertTrue(vm.dropFiles(at: [textURL, imageURL], onto: vm.pagesGroupNode, atChildIndex: -1))
    }

    func test_dropFilesAtURLsOntoNode_createsPagesAtEndOfNodeFolderIfURLsAreValidAndIndexIsMinus1() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        _ = self.addTestData(to: vm)

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let rootFolder = self.documentWindowViewModel.rootFolder
        _ = vm.dropFiles(at: [textURL, imageURL], onto: vm.pagesGroupNode, atChildIndex: -1)

        XCTAssertTrue((rootFolder.contents[safe: 3] as? Page)?.content is TextPageContent)
        XCTAssertTrue((rootFolder.contents[safe: 4] as? Page)?.content is ImagePageContent)
    }

    func test_dropFilesAtURLsOntoNode_createsPagesAtStartOfNodeFolderIfURLsAreValidAndIndexIs0() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        _ = self.addTestData(to: vm)

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let rootFolder = self.documentWindowViewModel.rootFolder
        _ = vm.dropFiles(at: [textURL, imageURL], onto: vm.pagesGroupNode, atChildIndex: 0)

        XCTAssertTrue((rootFolder.contents[safe: 0] as? Page)?.content is TextPageContent)
        XCTAssertTrue((rootFolder.contents[safe: 1] as? Page)?.content is ImagePageContent)
    }

    func test_dropFilesAtURLsOntoNode_createsPagesAboveItemAtIndexOfNodeFolderIfURLsAreValid() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        _ = self.addTestData(to: vm)

        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let rootFolder = self.documentWindowViewModel.rootFolder
        _ = vm.dropFiles(at: [textURL, imageURL], onto: vm.pagesGroupNode, atChildIndex: 2)

        XCTAssertTrue((rootFolder.contents[safe: 2] as? Page)?.content is TextPageContent)
        XCTAssertTrue((rootFolder.contents[safe: 3] as? Page)?.content is ImagePageContent)
    }


    //MARK: - createPage(ofType:underNodes:)
    func test_createPageOfTypeUnderNodes_createsNewPageInsideContainingFolderOfAndUnderneathLastNode() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, _) = self.addTestData(to: vm)
        let pageNode = try XCTUnwrap(vm.node(for: .page(page1.id)))

        let collection = SourceListNodeCollection()
        collection.add(pageNode)
        guard case .page(let pageID) = vm.createPage(ofType: .text, underNodes: collection) else {
            XCTFail()
            return
        }

        let newPage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(pageID))
        XCTAssertEqual(newPage.containingFolder, self.documentWindowViewModel.rootFolder)
        XCTAssertEqual(self.documentWindowViewModel.rootFolder.contents[safe: 1] as? Page, newPage)
    }


    //MARK: - createFolder(underNodes:)
    func test_createFolderUnderNodes_createsFolderInsideSameFolderAsSelection() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (_, _, _, page2) = self.addTestData(to: vm)
        let pageNode = try XCTUnwrap(vm.node(for: .page(page2.id)))
        let expectedFolder = page2.containingFolder

        let collection = SourceListNodeCollection()
        collection.add(pageNode)
        guard case .folder(let folderID) = vm.createFolder(underNodes: collection) else {
            XCTFail()
            return
        }

        let newFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folderID))
        XCTAssertEqual(newFolder.containingFolder, expectedFolder)
        XCTAssertEqual(self.documentWindowViewModel.rootFolder.contents[safe: 3] as? Folder, newFolder)
    }


    //MARK: - createFolder(usingSelection:)
    func test_createFolderUsingSelection_returnsNilIfSelectionIsEmpty() {
        let vm = self.createViewModel()
        vm.startObserving()

        let collection = SourceListNodeCollection()
        XCTAssertNil(vm.createFolder(usingSelection: collection))
    }

    func test_createFolderUsingSelection_createsAtEndOfContainingFolderOfLastNodeInSelection() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, page2) = self.addTestData(to: vm)
        let page1Node = try XCTUnwrap(vm.node(for: .page(page1.id)))
        let page2Node = try XCTUnwrap(vm.node(for: .page(page2.id)))
        let expectedFolder = page2.containingFolder

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(page2Node)

        guard case .folder(let folderID) = try XCTUnwrap(vm.createFolder(usingSelection: collection)) else {
            XCTFail()
            return
        }

        let folder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folderID))
        XCTAssertEqual(folder.containingFolder, expectedFolder)
        XCTAssertEqual(expectedFolder?.contents.last as? Folder, folder)
    }

    func test_createFolderUsingSelection_addsAllItemsInSelectionToCreatedFolder() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, page2) = self.addTestData(to: vm)
        let page1Node = try XCTUnwrap(vm.node(for: .page(page1.id)))
        let page2Node = try XCTUnwrap(vm.node(for: .page(page2.id)))

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(page2Node)

        guard case .folder(let folderID) = try XCTUnwrap(vm.createFolder(usingSelection: collection)) else {
            XCTFail()
            return
        }

        let folder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folderID))
        XCTAssertEqual(folder.contents[safe: 0] as? Page, page1)
        XCTAssertEqual(folder.contents[safe: 1] as? Page, page2)
    }


    //MARK: - createPages(fromFilesAt:underNodes:)
    func test_createPagesFromFilesAtURLsUnderNodes_createsPagesUsingTheLastNodeOfTheNodeCollection() throws {
        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, _, _) = self.addTestData(to: vm)
        let page1Node = try XCTUnwrap(vm.node(for: .page(page1.id)))

        let collection = SourceListNodeCollection()
        collection.add(page1Node)

        let results = vm.createPages(fromFilesAt: [textURL, imageURL], underNodes: collection)

        guard case .page(let textPageID) = results[safe: 0], case .page(let imagePageID) = results[safe: 1] else {
            XCTFail()
            return
        }

        let textPage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(textPageID))
        let imagePage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(imagePageID))

        let rootFolder = self.documentWindowViewModel.rootFolder
        XCTAssertEqual(textPage.containingFolder, rootFolder)
        XCTAssertEqual(imagePage.containingFolder, rootFolder)
        XCTAssertEqual(rootFolder.contents[safe: 1] as? Page, textPage)
        XCTAssertEqual(rootFolder.contents[safe: 2] as? Page, imagePage)
    }


    //MARK: - addNodes(_:to:)
    func test_addNodesToCanvas_doesntAddNodesIfItContainsCanvases() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, subpage1, page2) = self.addTestData(to: vm)

        let page1Node = try XCTUnwrap(vm.node(for: .page(page1.id)))
        let subpage1Node = try XCTUnwrap(vm.node(for: .page(subpage1.id)))
        let page2Node = try XCTUnwrap(vm.node(for: .page(page2.id)))

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(subpage1Node)
        collection.add(page2Node)
        collection.add(CanvasesSourceListNode())

        let canvas = self.modelController.collection(for: Canvas.self).newObject()

        vm.addNodes(collection, to: canvas)

        XCTAssertEqual(canvas.pages.count, 0)
    }

    func test_addNodesToCanvas_doesntAddNodesIfItContainsFolders() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, folder, subpage1, page2) = self.addTestData(to: vm)

        let page1Node = try XCTUnwrap(vm.node(for: .page(page1.id)))
        let folderNode = try XCTUnwrap(vm.node(for: .folder(folder.id)))
        let subpage1Node = try XCTUnwrap(vm.node(for: .page(subpage1.id)))
        let page2Node = try XCTUnwrap(vm.node(for: .page(page2.id)))

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(folderNode)
        collection.add(subpage1Node)
        collection.add(page2Node)

        let canvas = self.modelController.collection(for: Canvas.self).newObject()

        vm.addNodes(collection, to: canvas)

        XCTAssertEqual(canvas.pages.count, 0)
    }

    func test_addNodesToCanvas_addsNodesToSuppliedCanvasIfTheyContainJustPages() throws {
        let vm = self.createViewModel()
        vm.startObserving()

        let (page1, _, subpage1, page2) = self.addTestData(to: vm)

        let page1Node = try XCTUnwrap(vm.node(for: .page(page1.id)))
        let subpage1Node = try XCTUnwrap(vm.node(for: .page(subpage1.id)))
        let page2Node = try XCTUnwrap(vm.node(for: .page(page2.id)))

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(subpage1Node)
        collection.add(page2Node)

        let canvas = self.modelController.collection(for: Canvas.self).newObject()

        vm.addNodes(collection, to: canvas)

        XCTAssertEqual(canvas.pages.count, 3)
        XCTAssertTrue(canvas.pages.contains(where: { $0.page == page1 }))
        XCTAssertTrue(canvas.pages.contains(where: { $0.page == subpage1 }))
        XCTAssertTrue(canvas.pages.contains(where: { $0.page == page2 }))
    }
}


//MARK: - Helpers

private class MockSourceListView: SourceListView {
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

