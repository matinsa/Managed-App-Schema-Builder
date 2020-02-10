//
//  ViewController.swift
//  Managed Prefs Builder
//
//  Created by Leslie Helou on 2/7/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let fileManager = FileManager.default
    
    @IBOutlet weak var preferenceDomain_TextField: NSTextField!
    @IBOutlet weak var preferenceDomainDescr_TextField: NSTextField!
    @IBOutlet weak var keyFriendlyName_TextField: NSTextField!
    @IBOutlet weak var keyDescription_TextField: NSTextView!
    
    @IBOutlet weak var keyType_Button: NSPopUpButton!
    
    @IBOutlet weak var keys_TableView: NSTableView!
    var preferenceKeys_TableArray: [String]?
    
    var keysArray = [String]()
    
    var valueType = ""
    var keyName   = ""
    
    var keyValuePairs = [String:[String:Any]]()
    
        
    @IBAction func importFile_Button(_ sender: NSButton) {

            var json: Any?
            // filetypes that are selectable
            let fileTypeArray: Array = ["json"]
            
//            let defaultPath: String = NSHomeDirectory() + "/Desktop"
            //let defaultPath: String = "/Users"
            //let pathURL = NSURL(fileURLWithPath: defaultPath.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!, isDirectory: true)
//            var importPathUrl = NSURL(fileURLWithPath: defaultPath, isDirectory: false)

            var importPathUrl = fileManager.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        
        
            let importDialog: NSOpenPanel        = NSOpenPanel()
            importDialog.canChooseDirectories    = false
            importDialog.allowsMultipleSelection = false
            importDialog.resolvesAliases         = true
            importDialog.allowedFileTypes        = fileTypeArray
            importDialog.directoryURL            = importPathUrl
            importDialog.beginSheetModal(for: self.view.window!){ result in
            if result == .OK {
                importPathUrl = importDialog.url!
            
                    //    var err = NSError?()
                    print("path: \(importPathUrl)")
                    var rawKeyValuePairs = [String: Any]()
                    do {
                        self.keyValuePairs.removeAll()
//                        let fileUrl = URL(fileURLWithPath: path)
                        // Getting data from JSON file using the file URL
                        let data = try Data(contentsOf: importPathUrl, options: .mappedIfSafe)
                        json = try? JSONSerialization.jsonObject(with: data)
                        let manifestJson = json as? [String: Any]
                        
                        self.preferenceDomain_TextField.stringValue = manifestJson!["title"] as! String
                        self.preferenceDomainDescr_TextField.stringValue = manifestJson!["description"] as! String
                        let properties = manifestJson!["properties"] as! [String: [String: Any]]
                        self.keysArray.removeAll()
                        self.keyValuePairs.removeAll()
                        for (prefKey, _) in properties {
                            self.keysArray.append(prefKey)
                            rawKeyValuePairs = properties[prefKey]!

                            self.keyValuePairs[prefKey] = [:]
                            self.keyValuePairs[prefKey]!["title"] = rawKeyValuePairs["title"] as! String
                            self.keyValuePairs[prefKey]!["description"] = rawKeyValuePairs["description"] as! String
                            let anyOf = rawKeyValuePairs["anyOf"] as! [[String: String]]
                            if anyOf.count > 1 {
                                self.keyValuePairs[prefKey]!["valueType"] = anyOf[1]["type"]
                            } else {
                                self.keyValuePairs[prefKey]!["valueType"] = "Select Value Type"
                            }
                        }
                        self.keysArray.sort()

                        if self.keysArray.count > 0 {
                            self.preferenceKeys_TableArray = self.keysArray
                            self.keys_TableView.reloadData()
                        }
        //                    print("\(json)")
                    } catch {
                        print("couldn't reach json file")
                    }
            }
        }
    }

    
    @IBAction func addKey_Action(_ sender: Any) {
        
        if keyName != "" {
            updateKeyValuePair(whichKey: keyName)
        }
        
        DispatchQueue.main.async {
            
            let dialog: NSAlert = NSAlert()
            dialog.messageText = "Add new preference key:"
            dialog.alertStyle = NSAlert.Style.informational

            let newKey = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            newKey.stringValue = ""

            dialog.addButton(withTitle: "Add")
            dialog.addButton(withTitle: "Cancel")
            
            dialog.accessoryView = newKey
            newKey.becomeFirstResponder()
            
            dialog.beginSheetModal(for: self.view.window!){ result in
                if result == NSApplication.ModalResponse.alertFirstButtonReturn {

                    print("keyName: \(newKey.stringValue)")
                    if newKey.stringValue != "" {
                        self.keyName = newKey.stringValue
                        // see if key already exists - start
                        if let _ = self.keysArray.firstIndex(of: self.keyName) {
                            Alert().display(header: "Attention", message: "Key already exists.")
                            self.keyName = ""
                            return
                        } else {
                            print("new key")
                            self.keysArray.append(self.keyName)
                            self.keysArray.sort()
                            self.preferenceKeys_TableArray = self.keysArray
                            
                            self.keys_TableView.reloadData()
                            self.keyValuePairs[self.keyName] = [:]
                            // initialize values - start
                            self.keyValuePairs[self.keyName]!["title"] = self.keyName
                            self.keyFriendlyName_TextField.stringValue = self.keyName
                            self.keyValuePairs[self.keyName]!["description"] = ""
                            self.keyDescription_TextField.string = ""
                            self.keyType_Button.selectItem(at: 0)
                            self.keyValuePairs[self.keyName]!["valueType"] = "Select Value Type"
                            let keyIndex = self.preferenceKeys_TableArray?.firstIndex(of: self.keyName)
                            self.keys_TableView.selectRowIndexes(.init(integer: keyIndex!), byExtendingSelection: false)
                            // initialize values - end
                        }
                        // see if key already exists - end
                    }
                } else {
                    print("cancelled add key")
                }
            } // added with modal
            
//            Add to edit existing key name?
//            self.keys_TableView.editColumn(0, row: theRow, with: nil, select: true)
            

        }
    }
    
    @IBAction func removeKey_Action(_ sender: Any) {
        DispatchQueue.main.async {
            let theRow = self.keys_TableView.selectedRow
            if theRow >= 0 {
                self.keyName = self.preferenceKeys_TableArray?[theRow] ?? ""
                self.keyValuePairs.removeValue(forKey: self.keyName)
                self.keysArray.remove(at: theRow)
                self.preferenceKeys_TableArray = self.keysArray
//                self.preferenceKeys_TableArray?.remove(at: theRow)
                self.keys_TableView.reloadData()
                self.keyName = ""
                self.keyFriendlyName_TextField.stringValue = ""
                self.keyDescription_TextField.string = ""
                self.keyType_Button.selectItem(at: 0)
            }
        }
    }
    
    @IBAction func selectKeyName(_ sender: Any) {
        
        if keyName != "" {
            updateKeyValuePair(whichKey: keyName)
        }
        
        let theRow = keys_TableView.selectedRow
        if theRow >= 0 {
            keyName = preferenceKeys_TableArray?[theRow] ?? ""
        } else {
            keyName = ""
        }
        
        if keyName != "" {
            if let _ = keyValuePairs[keyName]!["title"] {
//                keyTitle = try! keyValuePairs[keyName]!["title"] as! String
                keyFriendlyName_TextField.stringValue = keyValuePairs[keyName]!["title"] as! String
            } else {
                keyFriendlyName_TextField.stringValue = ""
            }

            if let _ = keyValuePairs[keyName]!["description"] {
                keyDescription_TextField.string = keyValuePairs[keyName]!["description"] as! String
            } else {
                keyDescription_TextField.string = ""
            }

            if keyValuePairs[keyName]!["valueType"] as! String != "Select Value Type" {
                keyType_Button.selectItem(withTitle: "\(String(describing: keyValuePairs[keyName]!["valueType"]!))")
            }
        }   // if keyName != ""
        
    }
    
    func updateKeyValuePair(whichKey: String) {
    
        print("updating friendly name (title) for key \(keyName)")
        keyValuePairs[keyName]!["title"] = "\(keyFriendlyName_TextField.stringValue)"
    
        print("updating description for key \(keyName)")
        keyValuePairs[keyName]!["description"] = "\(keyDescription_TextField.string)"

        print("updating data type for key \(keyName) with value \(keyType_Button.titleOfSelectedItem!)")
        keyValuePairs[keyName]!["valueType"] = "\(keyType_Button.titleOfSelectedItem!)"
    }

    @IBAction func save_Action(_ sender: Any) {
                
//                let timeStamp = Time().getCurrent()
        
        if keyName != "" {
            updateKeyValuePair(whichKey: keyName)
        }
        
        var keysWritten = 0
        var keyDelimiter = ",\n"
        
        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        if preferenceDomain_TextField.stringValue != "" {
            var preferenceDomainFile = "\(preferenceDomain_TextField.stringValue).json"
            var exportURL = downloadsDirectory.appendingPathComponent(preferenceDomainFile)
            
            let saveDialog = NSSavePanel()
            saveDialog.canCreateDirectories = true
            saveDialog.nameFieldStringValue = preferenceDomainFile
            saveDialog.beginSheetModal(for: self.view.window!){ result in
                if result == .OK {
                    preferenceDomainFile = saveDialog.nameFieldStringValue
                    exportURL            = saveDialog.url!
                    print("fileName", preferenceDomainFile)

                    do {
                        try "{\n\t\"title\": \"\(self.preferenceDomain_TextField.stringValue)\",\n\t\"description\": \"\(self.preferenceDomainDescr_TextField.stringValue)\",\n\t\"properties\": {\n".write(to: exportURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("failed to write the.")
                    }
                    
                    if let preferenceDomainFileOp = try? FileHandle(forUpdating: exportURL) {
                         for (key, _) in self.keyValuePairs {
                            preferenceDomainFileOp.seekToEndOfFile()
                            keysWritten += 1
                            if keysWritten == self.keyValuePairs.count {
                                keyDelimiter = "\n"
                            }
        //                                     let text = "\t{\"id\": \"\(String(describing: keyValuePairs[key]!["id"]!))\", \"name\": \"\(key)\"},\n"
                            let text = """
                            \t\t"\(key)": {
                            \t\t\t"title": "\(String(describing: self.keyValuePairs[key]!["title"]!))",
                            \t\t\t"description": "\(String(describing: self.keyValuePairs[key]!["description"]!))",
                            \t\t\t"property_order": \(keysWritten),
                            \t\t\t"anyOf": [
                            \t\t\t\t{"type": "null", "title": "Not Configured"},
                            \t\t\t\t{
                            \t\t\t\t\t"title": "Configured",
                            \t\t\t\t\t"type": "\(String(describing: self.keyValuePairs[key]!["valueType"]!))"
                            \t\t\t\t}
                            \t\t\t]
                            \t\t}\(keyDelimiter)
                            """
                            preferenceDomainFileOp.write(text.data(using: String.Encoding.utf8)!)
                            
                         }   // for (key, _) in packagesDict - end
                        preferenceDomainFileOp.seekToEndOfFile()
                        preferenceDomainFileOp.write("\t}\n}".data(using: String.Encoding.utf8)!)
                        preferenceDomainFileOp.closeFile()
                        
                        do {
                            let manifest = try String(contentsOf: exportURL)
        //                    print("manifest: \(manifest)")
                            // copy manifest to clipboard - start
                            let clipboard = NSPasteboard.general
                            clipboard.clearContents()
                            clipboard.setString(manifest, forType: .string)
                            // copy manifest to clipboard - end
                        } catch {
                            print("file not found.")
                        }
                        
                    }
                }
            }
        } else {
            // preference domain required
            print("preference domain required")
            Alert().display(header: "Attention", message: "You must supply a preference domain.")

        }   // if preferenceDomain_TextField != "" - end
                    
                    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keys_TableView.delegate   = self
        keys_TableView.dataSource = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func quit_Button(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    

}


extension ViewController: NSTableViewDataSource {

  func numberOfRows(in keys_TableView: NSTableView) -> Int {
    return preferenceKeys_TableArray?.count ?? 0
  }
}

extension ViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCell_Id"
    }
    
    func tableView(_ object_TableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
    
//        print("[func tableView] item: \(unusedItems_TableArray?[row] ?? nil)")
        guard let item = preferenceKeys_TableArray?[row] else {
            return nil
        }
        
        if tableColumn == object_TableView.tableColumns[0] {
            text = "\(item)"
            cellIdentifier = CellIdentifiers.NameCell
        }
    
        if let cell = object_TableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

}
