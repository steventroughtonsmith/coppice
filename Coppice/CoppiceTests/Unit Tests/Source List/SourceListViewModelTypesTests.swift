//
//  SourceListViewModelTypesTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 19/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import Coppice
@testable import CoppiceCore
import XCTest

class SourceListNodeTestsBase: XCTestCase {
    var modelController: CoppiceModelController!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
    }
}


class SourceListNodeCollectionTests: SourceListNodeTestsBase {
    //MARK: - .count
    func test_count_returnsNumberOfNodesInCollection() {
        let collection = SourceListNodeCollection()

        collection.add(SourceListNode(item: .canvases))
        collection.add(SourceListNode(item: .canvases))
        collection.add(SourceListNode(item: .canvases))
        collection.add(SourceListNode(item: .canvases))

        XCTAssertEqual(collection.count, 4)
    }

    //MARK: - add(_:)
    func test_addNode_addsNodeToCollection() {
        let collection = SourceListNodeCollection()
        let node = SourceListNode(item: .canvases)
        collection.add(node)

        XCTAssertTrue(collection.nodes.contains(node))
    }

    func test_addNode_addingNodesWithSameParentSetsNodesShareParentToTrue() {
        let collection = SourceListNodeCollection()
        let parent = SourceListNode(item: .canvases)

        let child1 = SourceListNode(item: .canvases)
        let child2 = SourceListNode(item: .canvases)

        parent.children = [child1, child2]

        collection.add(child1)
        collection.add(child2)

        XCTAssertTrue(collection.nodesShareParent)
    }

    func test_addNode_addingNodesWithDifferentParentsSetsNodesShareParentToFalse() {
        let collection = SourceListNodeCollection()
        let parent = SourceListNode(item: .canvases)

        let child1 = SourceListNode(item: .canvases)
        let child2 = SourceListNode(item: .canvases)

        parent.children = [child1, child2]

        collection.add(child1)
        collection.add(parent)
        collection.add(child2)

        XCTAssertFalse(collection.nodesShareParent)
    }

    func test_addNode_addingCanvasesNodeSetsContainsCanvasesToTrue() {
        let collection = SourceListNodeCollection()
        XCTAssertFalse(collection.containsCanvases)

        collection.add(CanvasesSourceListNode())

        XCTAssertTrue(collection.containsCanvases)
    }

    func test_addNode_addingCanvasNodeSetsContainsCanvasToTrue() {
        let collection = SourceListNodeCollection()
        XCTAssertFalse(collection.containsCanvases)

        collection.add(SourceListNode(item: .canvas(Canvas.modelID(with: UUID()))))

        XCTAssertTrue(collection.containsCanvases)
    }

    func test_addNode_addingPageNodeSetsContainsPagesToTrue() {
        let collection = SourceListNodeCollection()
        XCTAssertFalse(collection.containsPages)

        collection.add(PageSourceListNode(page: Page()))

        XCTAssertTrue(collection.containsPages)
    }

    func test_addNode_addingFolderSetsContainsFoldersToTrue() {
        let collection = SourceListNodeCollection()
        XCTAssertFalse(collection.containsFolders)

        collection.add(FolderSourceListNode(folder: Folder()))

        XCTAssertTrue(collection.containsFolders)
    }


    //MARK: - .commonAncestor
    func test_commonAncestor_returnsNilIfNoNodesInCollection() throws {
        let collection = SourceListNodeCollection()
        XCTAssertNil(collection.commonAncestor)
    }

    func test_commonAncestor_returnsNilIfOnlyNodeHasNoParent() throws {
        let node = PageSourceListNode(page: Page())
        let collection = SourceListNodeCollection()
        collection.add(node)

        XCTAssertNil(collection.commonAncestor)
    }

    func test_commonAncestor_returnsParentOfTwoNodesWithSameParent() throws {
        let folder = Folder()
        let folderNode = FolderSourceListNode(folder: folder)
        let page1Node = PageSourceListNode(page: Page())
        let page2Node = PageSourceListNode(page: Page())
        folder.insert([page1Node.page, page2Node.page])
        folderNode.children = [page1Node, page2Node]

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(page2Node)

        XCTAssertEqual(collection.commonAncestor, folderNode)
    }

    func test_commonAncestor_returnsParentFolderIfCollectionContainsChildrenOfThatFolderEvenIfThereIsAnotherFolderAbove() throws {
        let rootFolder = Folder()
        let rootFolderNode = FolderSourceListNode(folder: rootFolder)
        let folder = Folder()
        let folderNode = FolderSourceListNode(folder: folder)
        rootFolder.insert([folder])
        rootFolderNode.children = [folderNode]

        let page1Node = PageSourceListNode(page: Page())
        let page2Node = PageSourceListNode(page: Page())
        folder.insert([page1Node.page, page2Node.page])
        folderNode.children = [page1Node, page2Node]

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(page2Node)

        XCTAssertEqual(collection.commonAncestor, folderNode)
    }

    func test_commonAncestor_returnsCommonAncestorFolderIfCollectionContainsFolderAndChildOfThatFolder() throws {
        let rootFolder = Folder()
        let rootFolderNode = FolderSourceListNode(folder: rootFolder)
        let folder = Folder()
        let folderNode = FolderSourceListNode(folder: folder)
        rootFolder.insert([folder])
        rootFolderNode.children = [folderNode]

        let page1Node = PageSourceListNode(page: Page())
        let page2Node = PageSourceListNode(page: Page())
        folder.insert([page1Node.page, page2Node.page])
        folderNode.children = [page1Node, page2Node]

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(folderNode)

        XCTAssertEqual(collection.commonAncestor, rootFolderNode)
    }

    func test_commonAncestor_returnsCommonAncestorFolderIfCollectionContainsFolderAndChildOfAnotherFolder() throws {
        let rootFolder = Folder()
        let rootFolderNode = FolderSourceListNode(folder: rootFolder)
        let folder1 = Folder()
        let folder1Node = FolderSourceListNode(folder: folder1)
        let folder2 = Folder()
        let folder2Node = FolderSourceListNode(folder: folder2)
        rootFolder.insert([folder1, folder2])
        rootFolderNode.children = [folder1Node, folder2Node]

        let page1Node = PageSourceListNode(page: Page())
        let page2Node = PageSourceListNode(page: Page())
        folder1.insert([page1Node.page, page2Node.page])
        folder1Node.children = [page1Node, page2Node]

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(folder2Node)

        XCTAssertEqual(collection.commonAncestor, rootFolderNode)
    }

    func test_commonAncestor_returnsNilIfNoSharedAncestorFound() throws {
        let folder1 = Folder()
        let folder1Node = FolderSourceListNode(folder: folder1)
        let folder2 = Folder()
        let folder2Node = FolderSourceListNode(folder: folder2)

        let page1Node = PageSourceListNode(page: Page())
        let page2Node = PageSourceListNode(page: Page())
        folder1.insert([page1Node.page, page2Node.page])
        folder1Node.children = [page1Node, page2Node]

        let collection = SourceListNodeCollection()
        collection.add(page1Node)
        collection.add(folder2Node)

        XCTAssertNil(collection.commonAncestor)
    }
}


class SourceListNodeTests: SourceListNodeTestsBase {
    //MARK: - init(item:cellType:)
    func test_init_setsItemAndCellType() {
        let modelID = Page.modelID(with: UUID())
        let node = SourceListNode(item: .page(modelID), cellType: .groupCell)

        XCTAssertEqual(node.item, .page(modelID))
        XCTAssertEqual(node.cellType, .groupCell)
    }

    //MARK: - .children
    func test_children_settingParentOfAllChildrenToSelf() {
        let parent = SourceListNode(item: .canvases)
        let child1 = SourceListNode(item: .canvases)
        let child2 = SourceListNode(item: .canvases)
        let child3 = SourceListNode(item: .canvases)

        parent.children = [child1, child2, child3]

        XCTAssertEqual(child1.parent, parent)
        XCTAssertEqual(child2.parent, parent)
        XCTAssertEqual(child3.parent, parent)
    }
}


class CanvasSourceListNodeTests: SourceListNodeTestsBase {
    func test_setsItemToCanvases() {
        XCTAssertEqual(CanvasesSourceListNode().item, .canvases)
    }

    func test_setsTypeToBigCell() {
        XCTAssertEqual(CanvasesSourceListNode().cellType, .navCell)
    }
}


class PagesGroupSourceListNodeTests: SourceListNodeTestsBase {
    func test_setsItemToFolderWithSuppliedFolder() {
        let folder = self.modelController.folderCollection.newObject()
        let node = PagesGroupSourceListNode(rootFolder: folder)

        XCTAssertEqual(node.item, .folder(folder.id))
    }

    func test_setsTypeToGroupCell() {
        let folder = self.modelController.folderCollection.newObject()
        let node = PagesGroupSourceListNode(rootFolder: folder)

        XCTAssertEqual(node.cellType, .groupCell)
    }
}


class FolderSourceListNodeTests: SourceListNodeTestsBase {
    func test_init_setsItemToSuppliedFolder() {
        let folder = self.modelController.folderCollection.newObject()
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.item, .folder(folder.id))
    }


    //MARK: - .title
    func test_title_get_returnsFolderTitle() {
        let folder = self.modelController.folderCollection.newObject()
        folder.title = "Hello World"
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.title, "Hello World")
    }

    func test_title_set_setsFolderTitle() {
        let folder = self.modelController.folderCollection.newObject()
        folder.title = "Hello World"
        let node = FolderSourceListNode(folder: folder)
        node.title = "Foo Bar"
        XCTAssertEqual(folder.title, "Foo Bar")
    }


    //MARK: - .folderForCreation
    func test_folderForCreation_returnsFolder() {
        let folder = self.modelController.folderCollection.newObject()
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.folderForCreation, folder)
    }

    //MARK: - .folderItemForCreation
    func test_folderItemForCreation_returnsLastItemFromFolder() {
        let containedFolder = self.modelController.folderCollection.newObject()
        let containedPage1 = self.modelController.pageCollection.newObject()
        let containedPage2 = self.modelController.pageCollection.newObject()
        let folder = self.modelController.folderCollection.newObject()
        folder.insert([containedPage1, containedFolder, containedPage2])
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.folderItemForCreation as? Page, containedPage2)
    }

    //MARK: - .folderContainable
    func test_folderContainable_returnsFolder() {
        let folder = self.modelController.folderCollection.newObject()
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.folderContainable as? Folder, folder)
    }
}


class PagesSourceListNodeTests: SourceListNodeTestsBase {
    func test_init_setsItemToSuppliedPage() {
        let page = self.modelController.pageCollection.newObject()
        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.item, .page(page.id))
    }


    //MARK: - .title
    func test_title_get_returnsPageTitle() {
        let page = self.modelController.pageCollection.newObject()
        page.title = "OMG Possum!"
        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.title, "OMG Possum!")
    }

    func test_title_set_setsPageTitle() {
        let page = self.modelController.pageCollection.newObject()
        page.title = "No possums :'("
        let node = PageSourceListNode(page: page)
        node.title = "MOAR POSSUMS!"
        XCTAssertEqual(page.title, "MOAR POSSUMS!")
    }


    //MARK: - .folderForCreation
    func test_folderForCreation_returnsPagesContainingFolder() {
        let page = self.modelController.pageCollection.newObject()

        let folder = self.modelController.folderCollection.newObject()
        folder.insert([page])

        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.folderForCreation, folder)
    }


    //MARK: - .folderItemForCreation
    func test_folderItemForCreation_returnsPage() {
        let page = self.modelController.pageCollection.newObject()

        let folder = self.modelController.folderCollection.newObject()
        folder.insert([page])

        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.folderItemForCreation as? Page, page)
    }


    //MARK: - .folderContainable
    func test_folderContainable_returnsPage() {
        let page = self.modelController.pageCollection.newObject()

        let folder = self.modelController.folderCollection.newObject()
        folder.insert([page])

        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.folderContainable as? Page, page)
    }
}
