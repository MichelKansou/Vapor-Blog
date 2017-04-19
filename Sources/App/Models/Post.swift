import Vapor
import Fluent
import Foundation

struct Post: Model {
    var id: Node?
    var exists: Bool = false
    var title: String
    var content: String
    var image: String?
    var url: String?
    var created_at: Date


    enum Error: Swift.Error {
        case dateNotSupported
    }
}
extension Post: NodeConvertible {
    init(title: String, content: String, image: String?, url: String?) {
        self.id = nil
        self.title = title
        self.content = content
        self.image = image
        self.url = url
        self.created_at = Date()
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        title = try node.extract("title")
        content = try node.extract("content")
        image = try node.extract("image")
        url = try node.extract("url")
        if let unix = node["created_at"]?.double {
            // allow unix timestamps (easy to send this format from Paw)
            created_at = Date(timeIntervalSince1970: unix)
        } else if let raw = node["created_at"]?.string {
            // if it's a string we assume it's in mysql date format
            // this could be expanded to support many formats
            guard let created_at = dateFormatter.date(from: raw) else {
                throw Error.dateNotSupported
            }

            self.created_at = created_at
        } else {
            throw Error.dateNotSupported
        }
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "title": title,
            "content": content,
            "image": image,
            "url": url,
            "created_at": dateFormatter.string(from: created_at)
        ])
    }
}

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("posts", closure: { (post) in
            post.id()
            post.string("title")
            post.string("content")
            post.longText("image", optional: true)
            post.string("url", optional: true)
            post.datetime("created_at")
        })

        // Create first post
        let seedData: [Post] = [
            Post(
                title: "Welcome",
                content: "This is your first post :D",
                image: "",
                url: "https://www.youtube.com/watch?v=LQ1SbHLXlH8"
            )
        ]

        try database.seed(seedData)
    }

    static func revert(_ database: Database) throws {
        try database.delete("posts")
    }
}

// Change date Format
private var _df: DateFormatter?
private var dateFormatter: DateFormatter {
    if let date = _df {
        return date
    }

    let date = DateFormatter()
    date.dateFormat = "yyyy-MM-dd HH:mm:ss"
    _df = date
    return date
}
