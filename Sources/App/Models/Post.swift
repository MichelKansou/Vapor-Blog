import Vapor
import Fluent
import Foundation

final class Post: Model {
    var id: Node?
    var exists: Bool = false

    var title: String
    var content: String

    init(title: String, content: String) {
        self.id = nil
        self.title = title
        self.content = content
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        title = try node.extract("title")
        content = try node.extract("content")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "title": title,
            "content": content
        ])
    }
}

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("posts", closure: { (post) in
            post.id()
            post.string("title")
            post.string("content")
        })
    }

    static func revert(_ database: Database) throws {
        try database.delete("posts")
    }
}
