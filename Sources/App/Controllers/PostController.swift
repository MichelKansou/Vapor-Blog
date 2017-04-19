import Vapor
import Fluent
import Foundation
import HTTP

final class PostController: ResourceRepresentable {

    func addRoutes(to drop: Droplet) {
        let URL = "admin/posts"
        drop.post(URL, Post.self, "update", handler: update)
        drop.post(URL, Post.self, "delete", handler: delete)
        drop.get(URL + "/create") { req in
            return try drop.view.make("Admin/Post/create", [
                "request": req
            ])
        }
    }

    func index(request: Request) throws -> ResponseRepresentable {
        let posts = try JSON(node: Post.query().sort("created_at", Sort.Direction.descending).all().makeNode())

        return try drop.view.make("Admin/Post/index", [
            "posts": posts,
            "postsPage": true
        ])
    }

    func store(request: Request) throws -> ResponseRepresentable {
        var post: Post
        guard let title = request.data["title"]?.string,
            let content = request.data["content"]?.string else { throw Abort.badRequest }

        post = Post(title: title, content: content, image: "", url: "")

        if let image = request.multipart?["image"]?.file {
            post.image = encodeImageToBase64(bytes: image.data)
        }

        if let url = request.data["url"]?.string {
            post.url = url
        }

        try post.save()
        return Response(redirect: "/admin/posts")
    }

    func show(request: Request, post: Post) throws -> ResponseRepresentable {
        return try drop.view.make("Admin/Post/show", [
            "post": post,
            "postsPage": true
        ])
    }

    func delete(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return Response(redirect: "/admin/posts")
    }

    func update(request: Request, post: Post) throws -> ResponseRepresentable {
        var post = post
        guard let title = request.data["title"]?.string,
            let content = request.data["content"]?.string else { throw Abort.badRequest }

        post.title = title
        post.content = content

        if let image = request.multipart?["image"]?.file {
            post.image = encodeImageToBase64(bytes: image.data)
        }
        if let url = request.data["url"]?.string {
            post.url = url
        }

        try post.save()
        guard let id = post.id!.int else { throw Abort.badRequest }
        return Response(redirect: "/admin/posts/\(id)")
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
