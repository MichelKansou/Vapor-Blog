import Vapor
import Fluent
import Foundation

final class Post: Model {
    var id: Node?
    var exists: Bool = false
    var title: String
    var content: String
    var image: String?
    var url: String?
    var created_at: Int
    var updated_at: Int


    init(title: String, content: String, image: String?, url: String?) {
        self.id = nil
        self.title = title
        self.content = content
        self.image = image
        self.url = url
        self.created_at = Int(Date().timeIntervalSince1970)
        self.updated_at = Int(Date().timeIntervalSince1970)
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        title = try node.extract("title")
        content = try node.extract("content")
        image = try node.extract("image")
        url = try node.extract("url")
        created_at = try node.extract("created_at")
        updated_at = try node.extract("updated_at")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "title": title,
            "content": content,
            "image": image,
            "url": url,
            "created_at": Post.timestampsToString(created_at),
            "updated_at": Post.timestampsToString(updated_at)
        ])
    }
}

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("posts", closure: { (post) in
            post.id()
            post.string("title")
            post.string("content")
            post.string("image", optional: true)
            post.string("url", optional: true)
            post.int("created_at")
            post.int("updated_at")
        })
    }

    static func revert(_ database: Database) throws {
        try database.delete("posts")
    }
}

extension Post {
    static func timestampsToString(_ timestamps: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamps))
        let dateformatter = DateFormatter()
        dateformatter.timeZone = TimeZone(identifier: "France/Paris")
        dateformatter.dateFormat = "dd-MM-yyyy"
        let val = dateformatter.string(from: date)
        return val
    }
}
