import Foundation
import Vapor
import VaporMySQL
import SwiftyBeaverVapor
import SwiftyBeaver

let drop = Droplet()

try drop.addProvider(VaporMySQL.Provider.self)

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

drop.get { req in
    let posts = try Post.all().makeNode().converted(to: JSON.self)

    return try drop.view.make("home", [
        "posts": posts
    ])
}

drop.resource("posts", PostController())
drop.get("posts/create") { req in
    return try drop.view.make("Post/create")
}
drop.resource("users", UserController())

drop.run()
