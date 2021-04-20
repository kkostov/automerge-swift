//
//  Proxy+UnsafeAccess.swift
//  Automerge
//
//  Created by Lukas Schmidt on 08.06.20.
//

import Foundation

extension Proxy {
    public func unsafe() -> UnsafeProxy {
        return UnsafeProxy(context: context, objectId: objectId, path: path)
    }
}

@dynamicMemberLookup
public final class UnsafeProxy {

    init(
        context: Context,
        objectId: String?,
        path: [Context.KeyPathElement]
    ) {
        self.context = context
        self.objectId = objectId
        self.path = path
    }

    public let objectId: String?
    let context: Context
    let path: [Context.KeyPathElement]

    public subscript(dynamicMember dynamicMember: String) -> UnsafeProxy {
        guard case .map(let map)? = self.objectId.map({ context.getObject(objectId: $0) }) else {
            fatalError()
        }
        let objectId = map.mapValues[dynamicMember]?.objectId
        return UnsafeProxy(context: context, objectId: objectId, path: path + [.init(key: .string(dynamicMember), objectId: objectId ?? "")])
    }

    private func set(rootObject: Map) {
        for (key, value) in rootObject.mapValues {
            context.setMapKey(path: path, key: key, value: value)
        }
    }

    public func set<T: Codable>(_ newValue: T) {
        let newObject: Object = try! TypeToObject().map(newValue)
        guard let lastPathKey = path.last?.key else {
            if case .map(let root) = newObject {
                self.set(rootObject: root)
            }
            return
        }
        switch lastPathKey {
        case .string(let key):
            let path = Array(self.path.dropLast())
            context.setMapKey(path: path, key: key, value: newObject)
        case .index(let index):
            let path = Array(self.path.dropLast())
            context.setListIndex(path: path, index: index, value: newObject)
        }
    }

    public subscript(index: Int) -> UnsafeProxy {
        get {
            guard case .list(let list)? = self.objectId.map({ context.getObject(objectId: $0) }) else {
                fatalError()
            }
            if index >= list.listValues.count {
                return UnsafeProxy(context: context, objectId: nil, path: path + [.init(key: .index(index), objectId: "")])
            }
            let objectId = list[index].objectId
            return UnsafeProxy(context: context, objectId: objectId, path: path + [.init(key: .index(index), objectId: objectId ?? "")])
        }
    }

}

//func set(newValue: Object) {
//    guard let lastPathKey = path.last?.key else {
//        if case .map(let root) = newValue {
//            self.set(rootObject: root)
//        }
//        return
//    }
//    switch lastPathKey {
//    case .string(let key):
//        let path = Array(self.path.dropLast())
//        context.setMapKey(path: path, key: key, value: newValue)
//    case .index(let index):
//        let path = Array(self.path.dropLast())
//        context.setListIndex(path: path, index: index, value: newValue)
//    }
//}
//
//public func set(_ newValue: Wrapped) {
//    let mapper = TypeToObject()
//    let object = try! mapper.map(newValue)
//
//    set(newValue: object)
//}

