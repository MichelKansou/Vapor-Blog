import Vapor
import VaporMySQL

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

drop.preparations.append(User.self)

let authController = AuthController()
authController.addRoutes(to: drop)

drop.get { req in

    return try drop.view.make("home")

}

drop.get("login") { req in

    return try drop.view.make("Auth/login")
}

drop.get("register") { req in

    return try drop.view.make("Auth/register")
}

drop.resource("posts", PostController())
drop.resource("users", UserController())

drop.run()
