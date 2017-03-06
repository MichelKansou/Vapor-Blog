import Vapor
import HTTP

final class UserController: ResourceRepresentable {
    func index(request: Request) throws -> ResponseRepresentable {
        let users = try User.all().makeNode().converted(to: JSON.self)
        return try drop.view.make("User/index", [
            "users" : users
        ])
    }

    func show(request: Request, user: User) throws -> ResponseRepresentable {
        return try drop.view.make("User/show", [
            "user": user
        ])
    }

    func makeResource() -> Resource<User> {
        return Resource (
            index: index,
            show: show
        )
    }
}
