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
        case directoryOpeningError(String)
    }

    var sources = [DispatchSourceFileSystemObject]()
    var queue: DispatchQueue?
    var file: Int32?
    let path: String
    let trigger: DispatchWorkItem

    func createSource(_ pathReference: UnsafePointer<Int8>) -> DispatchSourceFileSystemObject {
        file = open(pathReference, O_EVTONLY)
        queue = DispatchQueue(label: "com.bjoli.Syncer.Watcher")
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: file!, eventMask: DispatchSource.FileSystemEvent.link.union(DispatchSource.FileSystemEvent.write), queue: queue)
        
        source.setEventHandler {
            DispatchQueue.main.async {
                self.trigger.perform()
                source.cancel()
                do {
                    try self.bootstrap()
                } catch {
                    print("Problem trying to recreate watch!")
                    print(error)
                }
            }
        }
        source.setCancelHandler {
            if let file = self.file {
                close(file)
            }
        }
        source.resume()
        return source
    }

    func bootstrap() throws {
        guard let fileTree = FileManager.default.enumerator(atPath: path) else {
            throw WatcherError.directoryOpeningError("Problem opening: \(path)")
        }

        for pathObject in fileTree {
            guard let path = pathObject as? NSString else {
                break
            }

            let pathReference = path.fileSystemRepresentation
            let source = createSource(pathReference)
            sources.append(source)
        }
    }

    init(path: String, trigger: DispatchWorkItem) throws {
        self.path = path
        self.trigger = trigger
        try bootstrap()
    }

    public func cancel() {
        _ = self.sources.map { $0.cancel() }
        sources = [DispatchSourceFileSystemObject]()
    }
}
