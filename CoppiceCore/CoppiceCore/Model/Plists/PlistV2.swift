//
//  PlistV2.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 31/07/2022.
//

import Foundation
import M3Data

extension Plist {
    class V2: ModelPlist {
        override class var version: Int {
            return 2
        }

        override class var supportedTypes: [ModelPlist.PersistenceTypes] {
            return [
                PersistenceTypes(modelType: Page.modelType, persistenceName: "pages"),
                PersistenceTypes(modelType: Folder.modelType, persistenceName: "folders"),
                PersistenceTypes(modelType: Canvas.modelType, persistenceName: "canvases"),
                PersistenceTypes(modelType: CanvasPage.modelType, persistenceName: "canvasPages"),
            ]
        }

        override func migrateToNextVersion() throws -> [String: Any] {
            var migratedPlist = [String: Any]()
            migratedPlist["pages"] = self.plistRepresentations(of: Page.modelType).map(\.toPersistanceRepresentation)
            migratedPlist["folders"] = self.plistRepresentations(of: Folder.modelType).map(\.toPersistanceRepresentation)

            migratedPlist["settings"] = self.settings
            migratedPlist["version"] = V3.version


            let existingCanvasPages = self.plistRepresentations(of: CanvasPage.modelType)
            var canvasPagesByID = [String: [ModelPlistKey: Any]]()
            for existingCanvasPage in existingCanvasPages {
                guard let idString = (existingCanvasPage[.id] as? ModelID)?.stringRepresentation else {
                    throw ModelPlist.Errors.missingID(existingCanvasPage.toPersistanceRepresentation)
                }
                canvasPagesByID[idString] = existingCanvasPage
            }

            let existingCanvases = self.plistRepresentations(of: Canvas.modelType)
            var createdPageHierarchies = [[ModelPlistKey: Any]]()
            for canvas in existingCanvases {
                guard let closedHierarchies = canvas[.Canvas.closedPageHierarchies] as? [String: [String: [String: Any]]] else {
                    continue
                }

                guard let canvasID = canvas[.id] as? ModelID else {
                    throw ModelPlist.Errors.migrationFailed("Invalid canvas found")
                }

                for (canvasPageID, hierarchies) in closedHierarchies {
                    guard
                        let canvasPageModelID = ModelID(string: canvasPageID),
                        let pageIDString = canvasPagesByID[canvasPageID]?[.CanvasPage.page] as? String,
                        let pageID = ModelID(string: pageIDString),
                        let frameString = canvasPagesByID[canvasPageID]?[.CanvasPage.frame] as? String
                    else {
                        throw ModelPlist.Errors.migrationFailed("Invalid canvas page found in closed hierarchy")
                    }
                    for (_, rawLegacyHierarchy) in hierarchies {
                        guard let legacyHierarchy = LegacyPageHierarchy(plistRepresentation: rawLegacyHierarchy) else {
                            throw ModelPlist.Errors.migrationFailed("Invalid page hierarchy found")
                        }

                        var pageHierarchyPlist = legacyHierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: canvasPageModelID, sourcePageID: pageID, andFrame: NSRectFromString(frameString))
                        pageHierarchyPlist[.id] = ModelID(modelType: PageHierarchy.modelType)
                        pageHierarchyPlist[.PageHierarchy.canvas] = canvasID.stringRepresentation
                        createdPageHierarchies.append(pageHierarchyPlist)
                    }
                }
            }

            migratedPlist["pageHierarchies"] = createdPageHierarchies.map(\.toPersistanceRepresentation)
            migratedPlist["canvases"] = existingCanvases.map(\.toPersistanceRepresentation)


            var createdCanvasLinks = [[ModelPlistKey: Any]]()
            var migratedCanvasPages = [[ModelPlistKey: Any]]()
            for canvasPage in existingCanvasPages {
                guard let destinationID = (canvasPage[.id] as? ModelID)?.stringRepresentation else {
                    throw ModelPlist.Errors.missingID(canvasPage.toPersistanceRepresentation)
                }

                guard let sourceID = canvasPage[.CanvasPage.parent] as? String else {
                    migratedCanvasPages.append(canvasPage)
                    continue
                }

                guard
                    let sourcePageString = canvasPagesByID[sourceID]?[.CanvasPage.page] as? String,
                    let sourcePageID = ModelID(string: sourcePageString),
                    let destinationPageString = canvasPage[.CanvasPage.page] as? String,
                    let destinationPageID = ModelID(string: destinationPageString),
                    let canvasString = canvasPage[.CanvasPage.canvas] as? String,
                    let canvas = ModelID(string: canvasString)
                else {
                    throw ModelPlist.Errors.migrationFailed("Missing page for link between pages \(sourceID) and \(destinationID)")
                }


                var updatedCanvasPage = canvasPage
                updatedCanvasPage[.CanvasPage.parent] = nil
                migratedCanvasPages.append(updatedCanvasPage)

                let canvasLink: [ModelPlistKey: Any] = [
                    .id: CanvasLink.modelID(with: UUID()),
                    .CanvasLink.link: PageLink(destination: destinationPageID, source: sourcePageID, autoGenerated: false).url.absoluteString,
                    .CanvasLink.sourcePage: sourceID,
                    .CanvasLink.destinationPage: destinationID,
                    .CanvasLink.canvas: canvas,
                ]
                createdCanvasLinks.append(canvasLink)
            }

            migratedPlist["canvasPages"] = migratedCanvasPages.map(\.toPersistanceRepresentation)
            migratedPlist["canvasLinks"] = createdCanvasLinks.map(\.toPersistanceRepresentation)

            return migratedPlist
        }
    }
}
