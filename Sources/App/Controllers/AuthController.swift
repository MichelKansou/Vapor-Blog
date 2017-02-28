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
        drop.post("login", handler: login)
        drop.post("register", handler: register)
    }

    func register(_ request: Request)throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
        let password = request.data["password"]?.string else {
            throw Abort.badRequest
        }

        let creds = UsernamePassword(username: username, password: password)
        var user = try User.register(credentials: creds) as? User

        if user != nil {
            try user!.save()
            guard let id = user!.id!.int else { throw Abort.badRequest }
            return Response(redirect: "/users/\(id)")
        } else {
            return Response(redirect: "/register")
        }
    }

    func login(_ request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
            let password = request.data["password"]?.string else {
                throw Abort.badRequest
        }

        let credentials = UsernamePassword(username: username, password: password)
        do {
            try request.auth.login(credentials, persist: true)
            return Response(redirect: "admin/new-post")
        } catch {
            return Response(redirect: "login?succeded=false")
        }
    }


}
