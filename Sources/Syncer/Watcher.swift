//
//  Watcher.swift
//  Syncer
//
//  Created by Joe Smith on 2/10/19.
//

import Dispatch
import Foundation

public class Watcher {
    public enum WatcherError: Error {
        case fileOpenError(String)
    }

    var source: DispatchSourceFileSystemObject?
    var queue: DispatchQueue?
    var file: Int32?
    let path: String
    let trigger: DispatchWorkItem

    func bootstrap() throws {
        let pathReference = (path as NSString).fileSystemRepresentation
        file = open(pathReference, O_EVTONLY)
        queue = DispatchQueue(label: "com.bjoli.Syncer.Watcher")
        
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: file!, eventMask: .link, queue: queue)
        
        source?.setEventHandler {
            DispatchQueue.main.async {
                self.trigger.perform()
                self.source?.cancel()
                do {
                    try self.bootstrap()
                } catch {
                    print("Problem trying to recreate watch!")
                    print(error)
                }
            }
        }
        source?.setCancelHandler {
            if let file = self.file {
                close(file)
            }
        }
        source?.resume()
    }

    init(path: String, trigger: DispatchWorkItem) throws {
        self.path = path
        self.trigger = trigger
        try bootstrap()
    }

    public func cancel() {
        source?.cancel()
    }
}
