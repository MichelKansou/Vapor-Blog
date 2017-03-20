//
//  User.swift
//  blog
//
//  Created by Michel Kansou on 09/02/2017.
//
//

import Vapor
import VaporMySQL
import Fluent
import Foundation
import Turnstile
import TurnstileCrypto
import Auth
import VaporJWT
import Core

struct Authentication {
    static let AccessTokenSigningKey: Bytes = Array("dhGVd4qr".utf8)
    static let AccesTokenValidationLength = Date() + (60 * 5) // 5 Minutes later
}

final class User {
    var id: Node?
    var username: String!
    var password: String!
    var token: String?
    var exists: Bool = false


    init (username: String, password: String) {
        self.id = nil
        self.username = username
        self.password = BCrypt.hash(password: password)
    }

    init (node: Node, in context: Context) throws {
        id = try node.extract("id")
        username = try node.extract("username")
        password = try node.extract("password")
        token = try node.extract("token")
    }

    init(credentials: UsernamePassword) {
        self.username = credentials.username
        self.password = BCrypt.hash(password: credentials.password)
    }

    init(credentials: Auth.AccessToken) {
        self.token = credentials.string
    }
}

extension User: Model {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": self.id,
            "username": self.username,
            "password": self.password,
            "token": self.token
            ])
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("users", closure: { (user) in
            user.id()
            user.string("username")
            user.string("password")
            user.string("token", optional: true)
        })

        // Create new user
        let seedData: [User] = [
            User(username: "admin", password: "password")
        ]

        try database.seed(seedData)
    }

    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}

extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        var user: User?
        switch credentials {

            case let credentials as UsernamePassword:
                let fetchedUser = try User.query().filter("username", credentials.username).first()
                if let password = fetchedUser?.password, password != "", (try? BCrypt.verify(password: credentials.password, matchesHash: password)) == true {
                    user = fetchedUser
                }

            case let credentials as Auth.AccessToken:
                user = try User.query().filter("token", credentials.string).first()

            case let credentials as Identifier:
                user = try User.find(credentials.id)

            default:
                throw UnsupportedCredentialsError()
        }
        if var user = user {
            // Check if we have an accessToken first, if not, lets create a new one
            if let accessToken = user.token {

                // Check if our authentication token has expired, if so, lets generate a new one as this is a fresh login
                let receivedJWT = try JWT(token: accessToken)

                // Validate it's time stamp
                if !receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                    try user.generateToken()
                }
            } else {
                // We don't have a valid access token
                try user.generateToken()
            }
            try user.save()

            return user
        } else {
            throw IncorrectCredentialsError()
        }
    }

    static func register(credentials: Credentials) throws -> Auth.User {
           var newUser: User

           switch credentials {
           case let credentials as UsernamePassword:
               newUser = User(credentials: credentials)

           default: throw UnsupportedCredentialsError()
           }

           if try User.query().filter("username", newUser.username).first() == nil {
               try newUser.generateToken()
               try newUser.save()
               return newUser
           } else {
               throw AccountTakenError()
           }

       }
}



extension User {
    func generateToken() throws {
        // Generate our Token
        let jwt = try JWT(payload: Node(ExpirationTimeClaim(Authentication.AccesTokenValidationLength)), signer: HS256(key: Authentication.AccessTokenSigningKey))
        self.token = try jwt.createToken()
    }

    func validateToken() throws -> Bool {
        guard let token = self.token else { return false }
        // Validate our current access token
        let receivedJWT = try JWT(token: token)
        if try receivedJWT.verifySignatureWith(HS256(key: Authentication.AccessTokenSigningKey)) {
            // If we need a new token, lets generate one
            if !receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                try self.generateToken()
                return true
            }
        }
        return false
    }
}
