//
//  SourceListViewModelTypesTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 19/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
@testable import CoppiceCore

class SourceListNodeCollectionTests: XCTestCase {
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
}


class SourceListNodeTests: XCTestCase {
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


class CanvasSourceListNodeTests: XCTestCase {
    func test_setsItemToCanvases() {
        XCTAssertEqual(CanvasesSourceListNode().item, .canvases)
    }

    func test_setsTypeToBigCell() {
        XCTAssertEqual(CanvasesSourceListNode().cellType, .bigCell)
    }
}


class PagesGroupSourceListNodeTests: XCTestCase {
    func test_setsItemToFolderWithSuppliedFolder() {
        let folder = Folder()
        let node = PagesGroupSourceListNode(rootFolder: folder)

        XCTAssertEqual(node.item, .folder(folder.id))
    }

    func test_setsTypeToGroupCell() {
        let folder = Folder()
        let node = PagesGroupSourceListNode(rootFolder: folder)

        XCTAssertEqual(node.cellType, .groupCell)
    }
}


class FolderSourceListNodeTests: XCTestCase {
    func test_init_setsItemToSuppliedFolder() {
        let folder = Folder()
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.item, .folder(folder.id))
    }


    //MARK: - .title
    func test_title_get_returnsFolderTitle() {
        let folder = Folder()
        folder.title = "Hello World"
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.title, "Hello World")
    }

    func test_title_set_setsFolderTitle() {
        let folder = Folder()
        folder.title = "Hello World"
        let node = FolderSourceListNode(folder: folder)
        node.title = "Foo Bar"
        XCTAssertEqual(folder.title, "Foo Bar")
    }


    //MARK: - .folderForCreation
    func test_folderForCreation_returnsFolder() {
        let folder = Folder()
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.folderForCreation, folder)
    }

    //MARK: - .folderItemForCreation
    func test_folderItemForCreation_returnsLastItemFromFolder() {
        let containedFolder = Folder()
        let containedPage1 = Page()
        let containedPage2 = Page()
        let folder = Folder()
        folder.insert([containedPage1, containedFolder, containedPage2])
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.folderItemForCreation as? Page, containedPage2)
    }

    //MARK: - .folderContainable
    func test_folderContainable_returnsFolder() {
        let folder = Folder()
        let node = FolderSourceListNode(folder: folder)
        XCTAssertEqual(node.folderContainable as? Folder, folder)
    }
}


class PagesSourceListNodeTests: XCTestCase {
    func test_init_setsItemToSuppliedPage() {
        let page = Page()
        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.item, .page(page.id))
    }


    //MARK: - .title
    func test_title_get_returnsPageTitle() {
        let page = Page()
        page.title = "OMG Possum!"
        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.title, "OMG Possum!")
    }

    func test_title_set_setsPageTitle() {
        let page = Page()
        page.title = "No possums :'("
        let node = PageSourceListNode(page: page)
        node.title = "MOAR POSSUMS!"
        XCTAssertEqual(page.title, "MOAR POSSUMS!")
    }


    //MARK: - .folderForCreation
    func test_folderForCreation_returnsPagesContainingFolder() {
        let page = Page()

        let folder = Folder()
        folder.insert([page])

        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.folderForCreation, folder)
    }


    //MARK: - .folderItemForCreation
    func test_folderItemForCreation_returnsPage() {
        let page = Page()

        let folder = Folder()
        folder.insert([page])

        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.folderItemForCreation as? Page, page)
    }


    //MARK: - .folderContainable
    func test_folderContainable_returnsPage() {
        let page = Page()

        let folder = Folder()
        folder.insert([page])

        let node = PageSourceListNode(page: page)
        XCTAssertEqual(node.folderContainable as? Page, page)
    }
}
