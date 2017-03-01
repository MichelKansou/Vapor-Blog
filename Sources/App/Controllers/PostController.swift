import Vapor
import HTTP

final class PostController: ResourceRepresentable {
    func index(request: Request) throws -> ResponseRepresentable {
        let posts = try Post.all().makeNode().converted(to: JSON.self)
        return try drop.view.make("Post/index", [
            "posts": posts
        ])
    }

    func store(request: Request) throws -> ResponseRepresentable {
        guard let title = request.data["title"]?.string, let content = request.data["content"]?.string else { throw Abort.badRequest }
        var post = Post(title: title, content: content)
        try post.save()
        guard let id = post.id!.int else { throw Abort.badRequest }
        return Response(redirect: "/posts/\(id)")
    }

    func show(request: Request, post: Post) throws -> ResponseRepresentable {
        return try drop.view.make("Post/show", [
            "post": post
        ])
    }

    func delete(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return Response(redirect: "/posts")
    }

    func update(request: Request, post: Post) throws -> ResponseRepresentable {
        guard let title = request.data["title"]?.string, let content = request.data["content"]?.string else { throw Abort.badRequest }
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
}

extension Request {
    func post() throws -> Post {
        guard let json = json else { throw Abort.badRequest }
        return try Post(node: json)
    }
}
