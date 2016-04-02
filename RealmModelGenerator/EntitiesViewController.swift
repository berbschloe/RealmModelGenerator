//
//  EntitieViewController.swift
//  RealmModelGenerator
//
//  Created by Zhaolong Zhong on 3/21/16.
//  Copyright © 2016 QuarkWorks. All rights reserved.
//

import Cocoa

protocol EntitiesVCDelegate: class {
    func entitiesVC(entitiesVC:EntitiesViewController, selectedEntityDidChange entity:Entity?)
}

class EntitiesViewController: NSViewController, EntitiesViewDelegate, EntitiesViewDataSource {
    static let TAG = NSStringFromClass(EntitiesViewController)
    
    @IBOutlet weak var entitiesView: EntitiesView! {
        didSet {
            self.entitiesView.delegate = self
            self.entitiesView.dataSource = self
        }
    }
    
    var schema = Schema() {
        didSet {
            invalidateViews()
            selectedEntity = nil
        }
    }
    
    private var model: Model {
        return schema.currentModel
    }
    
    weak var selectedEntity: Entity? {
        didSet {
            if oldValue === self.selectedEntity { return }
            invalidateSelectedIndex()
            self.delegate?.entitiesVC(self, selectedEntityDidChange: self.selectedEntity)
        }
    }
    
    weak var delegate:EntitiesVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func invalidateViews() {
        if !self.viewLoaded { return }
        self.entitiesView.reloadData()
        invalidateSelectedIndex()
    }
    
    func invalidateSelectedIndex() {
        self.entitiesView.selectedIndex = self.model.entities.indexOf({$0 === self.selectedEntity})
    }

    //MARK: - EntitiesViewDataSource
    func numberOfRowsInEntitiesView(entitiesView: EntitiesView) -> Int {
        return self.model.entities.count
    }
    
    func entitiesView(entitiesView:EntitiesView, titleForEntityAtIndex index:Int) -> String {
        return self.model.entities[index].name
    }
    
    //MARK: - EntitiesViewDelegate
    func addEntityInEntitiesView(entitiesView: EntitiesView) {
        let entity = self.model.createEntity()
        self.selectedEntity = entity
        self.invalidateViews()
    }
    
    func entitiesView(entitiesView: EntitiesView, removeEntityAtIndex index: Int) {
        let entity = self.model.entities[index]
        let isSelectedEntity = entity === self.selectedEntity
        self.model.removeEntity(model.entities[index])
        self.invalidateViews()
        
        if isSelectedEntity {
            if self.model.entities.count == 0 {
                self.selectedEntity = nil
            } else if index < self.model.entities.count {
                self.selectedEntity = self.model.entities[index]
            } else {
                self.selectedEntity = self.model.entities[self.model.entities.count - 1]
            }
        }
        
        self.delegate?.entitiesVC(self, selectedEntityDidChange: self.selectedEntity)
    }
    
    func entitiesView(entitiesView: EntitiesView, selectedIndexDidChange index: Int?) {
        if let index = index {
            self.selectedEntity = self.model.entities[index]
        } else {
            self.selectedEntity = nil
        }
    }
    
    func entitiesView(entitiesView: EntitiesView, shouldChangeEntityName name: String, atIndex index: Int) -> Bool {
        let entity = model.entities[index]
        do {
            try entity.setName(name)
            defer { self.invalidateViews() }
            self.delegate?.entitiesVC(self, selectedEntityDidChange: entity)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.addButtonWithTitle("OK")
            alert.informativeText = "Unable to rename entity: \(entity.name) to: \(name). There is an entity with the same name."
            alert.runModal()
            return false
        }
        return true
    }
}