import Vapor
import Fluent
import Foundation
import HTTP

final class PostController: ResourceRepresentable {
    func index(request: Request) throws -> ResponseRepresentable {
        let posts = try JSON(node: Post.query().sort("created_at", Sort.Direction.descending).all().makeNode())

        return try drop.view.make("Admin/Post/index", [
            "posts": posts,
            "postsPage": true
        ])
    }

    func store(request: Request) throws -> ResponseRepresentable {
        guard let title = request.data["title"]?.string, let content = request.data["content"]?.string,
        let image = request.multipart?["image"]?.file, let url = request.data["url"]?.string else { throw Abort.badRequest }
        var post = Post(title: title, content: content, image: encodeImageToBase64(bytes: image.data), url: url)
        try post.save()
        // guard let id = post.id!.int else { throw Abort.badRequest }
        return Response(redirect: "posts/")
    }

    func show(request: Request, post: Post) throws -> ResponseRepresentable {
        return try drop.view.make("Admin/Post/show", [
            "post": post,
            "postsPage": true
        ])
    }

    func delete(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return Response(redirect: "/posts")
    }

    func update(request: Request, post: Post) throws -> ResponseRepresentable {
        guard let title = request.data["title"]?.string, let content = request.data["content"]?.string,
        let image = request.data["image"]?.string, let url = request.data["url"]?.string else { throw Abort.badRequest }
        var post = post
        post.title = title
        post.content = content
        try post.save()
        guard let id = post.id!.int else { throw Abort.badRequest }
        return Response(redirect: "/posts/\(id)")
    }

    func makeResource() -> Resource<Post> {
        return Resource(
            index: index,
            store: store,
            show: show,
            modify: update,
            destroy: delete
        )
    }

    func encodeImageToBase64(bytes: [UInt8]) -> String {
        //convert bytes to data
        let data = Data(bytes: bytes, count: bytes.count)
        //convert data to base64
        let strBase64 = data.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        return strBase64
    }
}

extension Request {
    func post() throws -> Post {
        guard let json = json else { throw Abort.badRequest }
        return try Post(node: json)
    }
}
