import Vapor
import HTTP

final class PostController: ResourceRepresentable {
    func index(request: Request) throws -> ResponseRepresentable {
        let posts = try Post.all().makeNode().converted(to: JSON.self)
        log.info("a nice information")
        return try drop.view.make("Post/index", [
            "posts": posts
        ])
    }

    func store(request: Request) throws -> ResponseRepresentable {
        log.info("post create")
        var post = try request.post()
        try post.save()
        log.info("post saved")
        // guard let id = post.id!.int else { throw Abort.badRequest }
        return Response(redirect: "/posts")
    }

    func show(request: Request, post: Post) throws -> ResponseRepresentable {
        return try drop.view.make("Post/show", [
            "post": post
        ])
    }

    func delete(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return JSON([:])
    }

    func update(request: Request, post: Post) throws -> ResponseRepresentable {
        let new = try request.post()
        var post = post
        post.content = new.content
        try post.save()
        return post
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
