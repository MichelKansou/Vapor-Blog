import Foundation
import Fluent
import Vapor
import VaporMySQL
import SwiftyBeaverVapor
import SwiftyBeaver
import Auth
import Cookies

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

drop.preparations.append(User.self)
drop.preparations.append(Post.self)

drop.middleware.append(AuthMiddleware(user: User.self))

// Log config with SwiftyBeaver
let console = ConsoleDestination()  // log to Xcode Console in color
let file = FileDestination()  // log to file in color
file.logFileURL = URL(fileURLWithPath: "/tmp/VaporLogs.log") // set log file
let sbProvider = SwiftyBeaverProvider(destinations: [console, file])

try drop.addProvider(sbProvider)

let log = drop.log.self

let authController = AuthController()
authController.addRoutes(to: drop)

drop.get { req in
    let posts = try JSON(node: Post.query().sort("created_at", Sort.Direction.descending).all().makeNode())

    return try drop.view.make("home", [
        "posts": posts
    ])
}
let protect = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))

drop.grouped(CheckUser(), protect).group("admin") { admin in

    admin.resource("posts", PostController())
    admin.get("posts/create") { req in
        return try drop.view.make("Admin/Post/create", [
            "request": req
        ])
    }
    admin.resource("users", UserController())
}


drop.run()
