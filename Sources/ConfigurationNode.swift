/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

class ConfigurationNode {
    /// Hierarchy separator used when accessing fields via subscript
    static let separator: String = "."

    // TODO
    // Look into parsing [{},{}] into array of nodes
    /// Value of node
    private var content: Any?

    /// Children of node
    private var children: [String: ConfigurationNode] = [:]

    /// Whether or not node has children, or is a leaf value
    private var isLeaf: Bool {
        return children.isEmpty
    }

    init(rawValue: Any? = nil) {
        self.rawValue = rawValue
    }

    /// Serialize/deserialize tree at current node to/from Foundation types
    var rawValue: Any? {
        get {
            if isLeaf {
                return content
            }
            else {
                var dict: [String: Any] = [:]

                for (key, node) in children {
                    dict[key] = node.rawValue
                }

                return dict
            }
        }
        set {
            clear()

            if let dict = newValue as? [String: Any] {
                for (key, value) in dict {
                    let node = ConfigurationNode(rawValue: value)

                    // use subscript to catch case when key contains
                    // separator character(s)
                    self[key] = node
                }
            }
            else {
                content = newValue
            }
        }
    }

    /// Shallow depth-first merge; copy class instance references instead of deep copy
    func merge(overwrite other: ConfigurationNode) {
        if isLeaf && content == nil {
            // self is empty
            // shallow copy other
            content = other.content
            children = other.children
        }
        else if !isLeaf && !other.isLeaf {
            for (key, child) in other.children {
                if let myChild = children[key] {
                    // recursively merge/overwrite
                    myChild.merge(overwrite: child)
                }
                else {
                    // no entry for key exists in self; add it
                    children[key] = child
                }
            }
        }
    }

    /// path may be object path or simple key
    subscript(path: String) -> ConfigurationNode? {
        get {
            // check if it's an object path
            if let range = path.range(of: ConfigurationNode.separator) {
                let firstKey = path.substring(to: range.lowerBound)
                let restOfKeys = path.substring(from: range.upperBound)

                return children[firstKey]?[restOfKeys]
            }
            else {
                return children[path]
            }
        }
        set {
            // check if it's an object path
            if let range = path.range(of: ConfigurationNode.separator) {
                let firstKey = path.substring(to: range.lowerBound)
                let restOfKeys = path.substring(from: range.upperBound)

                // check if child node at first key exists
                if let child = children[firstKey] {
                    child[restOfKeys] = newValue
                }
                else {
                    // child node doesn't exist
                    // create one
                    let child = ConfigurationNode()

                    // insert newValue by recursion
                    child[restOfKeys] = newValue

                    // append to children
                    children[firstKey] = child
                }
            }
            else {
                // index is same index
                // update node reference in children
                children[path] = newValue
            }
        }
    }
    
    private func clear() {
        content = nil
        children.removeAll()
    }
}
