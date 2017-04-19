import Vapor
import Auth
import HTTP

final class UserController: ResourceRepresentable {

    func addRoutes(to drop: Droplet) {
        drop.post("admin/users", User.self, "update", handler: update)
    }

    func index(request: Request) throws -> ResponseRepresentable {
        let users = try User.all().makeNode().converted(to: JSON.self)
        return try drop.view.make("Admin/User/index", [
            "users" : users,
            "usersPage": true
        ])
    }

    /**
     Show an instance.
    */
    func show(request: Request, user: User) throws -> ResponseRepresentable {
        return try drop.view.make("Admin/User/show", [
            "user": user,
            "usersPage": true
        ])
    }


    /**
        Modify an instance (only the fields that are present in the request)
    */
    func update(request: Request, user: User) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
        let password = request.data["password"]?.string else { throw Abort.badRequest }
        var new = user
        var user = user
        new.username = username
        new.password = password
        user.merge(updates: new)
        try user.save()
        return Response(redirect: "/admin/my-profile")
    }

    func makeResource() -> Resource<User> {
        return Resource (
            index: index,
            show: show,
            modify: update
        )
    }
}
