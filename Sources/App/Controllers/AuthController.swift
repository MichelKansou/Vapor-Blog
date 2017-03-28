//
//  File.swift
//  blog
//
//  Created by Michel Kansou on 27/02/2017.
//
//

import Vapor
import HTTP
import Auth
import Turnstile

final class AuthController {

    func addRoutes(to drop: Droplet) {
        drop.get("login", handler: loginView)
        drop.post("login", handler: login)
        drop.post("logout", handler: logout)
    }

    func loginView(request: Request) throws -> ResponseRepresentable {
        return try drop.view.make("Auth/login")
    }

    func register(request: Request)throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
        let password = request.data["password"]?.string else {
            throw Abort.badRequest
        }

        let creds = UsernamePassword(username: username, password: password)
        var user = try User.register(credentials: creds) as? User

        if user != nil {
            try user!.save()
            guard let id = user!.id!.int else { throw Abort.badRequest }
            return Response(redirect: "/login")
        } else {
            return Response(redirect: "/register")
        }
    }

    func login(request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
            let password = request.data["password"]?.string else {
            throw Abort.custom(status: Status.badRequest, message: "Missing username or password")
        }

        let credentials = UsernamePassword(username: username, password: password)

        do {
            try request.auth.login(credentials)
            return Response(redirect: "/admin/posts")
        } catch {
            throw Abort.custom(status: Status.badRequest, message: "Invalid email or password")
        }
    }

    func logout(request: Request) throws -> ResponseRepresentable {
        // Invalidate the current access token
        log.info("logout")
        var user = try request.user()
        log.info("username: \(user.username)")
        user.token = nil
        try user.save()

        // Clear the session
        request.subject.logout()
        return Response(redirect: "/")
    }

}

extension Request {
    // Helper method to get the current user
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw UnsupportedCredentialsError()
        }
        return user
    }
    // Exposes the Turnstile subject, as Vapor has a facade on it.
    var subject: Subject {
        return storage["subject"] as! Subject
    }
}
