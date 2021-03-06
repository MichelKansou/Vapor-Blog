import Foundation
import Fluent
import Vapor
import VaporMySQL
import SwiftyBeaverVapor
import SwiftyBeaver
import Auth

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

drop.middleware.append(AuthMiddleware(user: User.self))

drop.preparations.append(User.self)
drop.preparations.append(Post.self)

// Log config with SwiftyBeaver
let console = ConsoleDestination()  // log to Xcode Console in color
let file = FileDestination()  // log to file in color
file.logFileURL = URL(fileURLWithPath: "/tmp/VaporLogs.log") // set log file
let sbProvider = SwiftyBeaverProvider(destinations: [console, file])
try drop.addProvider(sbProvider)
let log = drop.log.self


let authController = AuthController()
authController.addRoutes(to: drop)

drop.get("/") { req in
    let posts = try JSON(node: Post.query().sort("created_at", Sort.Direction.descending).all().makeNode())

    return try drop.view.make("home", [
        "posts": posts,
        "homePage": true
    ])
}

drop.get("about") { req in
    return try drop.view.make("about", [
        "aboutPage": true
    ])
}

drop.get("contact") { req in
    return try drop.view.make("contact")
}

let protect = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))

drop.grouped(CheckUser(), protect).group("admin") { admin in

    let userController = UserController()
    userController.addRoutes(to: drop)
    let postController = PostController()
    postController.addRoutes(to: drop)

    admin.resource("posts", postController)
    admin.resource("users", userController)

    admin.get("my-profile") { req in
        guard let authUser = try req.user() as? User else {
            print("unable to get authenticated user")
        }
        return try drop.view.make("Admin/User/show", [
            "user": authUser
        ])
    }
}


drop.run()
