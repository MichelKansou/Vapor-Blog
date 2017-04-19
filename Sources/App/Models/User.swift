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
import Core

struct Authentication {
    static let AccessTokenSigningKey: Bytes = Array("dhGVd4qr".utf8)
    static let AccesTokenValidationLength = Date() + (60 * 5) // 5 Minutes later
}

struct User: Model {
    var id: Node?
    var username: String!
    var password: String!
    var token: String?
    var apiKeyID = URandom().secureToken
    var apiKeySecret = URandom().secureToken
    var exists: Bool = false
}

extension User: NodeConvertible {
    init (username: String, password: String) {
        self.id = nil
        self.username = username
        self.password = BCrypt.hash(password: password)
    }

    init (node: Node, in context: Context) throws {
        id = try node.extract("id")
        username = try node.extract("username")
        password = try node.extract("password")
        apiKeyID = try node.extract("api_key_id")
        apiKeySecret = try node.extract("api_key_secret")
    }

    init(credentials: UsernamePassword) {
        self.username = credentials.username
        self.password = BCrypt.hash(password: credentials.password)
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": self.id,
            "username": self.username,
            "password": self.password,
            "api_key_id": self.apiKeyID,
            "api_key_secret": self.apiKeySecret
            ])
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("users", closure: { (user) in
            user.id()
            user.string("username")
            user.string("password")
            user.string("api_key_id", optional: true)
            user.string("api_key_secret", optional: true)
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

                /**
             Authenticates via API Keys
             */
            case let credentials as APIKey:
                user = try User.query()
                    .filter("api_key_id", credentials.id)
                    .filter("api_key_secret", credentials.secret)
                    .first()

            case let credentials as Identifier:
                user = try User.find(credentials.id)

            default:
                throw UnsupportedCredentialsError()
        }
        if var user = user {
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
               try newUser.save()
               return newUser
           } else {
               throw AccountTakenError()
           }

       }
}


extension User {
    mutating func merge(updates: User) {
        id = updates.id ?? id
        username = updates.username ?? username
        password = BCrypt.hash(password: updates.password ?? password)
    }
}
