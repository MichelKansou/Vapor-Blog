import Vapor
import HTTP
import Turnstile
import Auth
import Foundation

final class CheckUser: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if let id = request.headers["Authorization"]?.capturedGroups(withRegex: "^id(.+?(?=secret))"),
         let secret = request.headers["Authorization"]?.capturedGroups(withRegex: "secret(.*)") {
            let credentials = APIKey(id: id, secret: secret)
            try? request.auth.login(credentials, persist: false)
        }

        return try next.respond(to: request)
   }
}

extension String {
    func capturedGroups(withRegex pattern: String) -> String {
        var results : String = ""

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }

        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.characters.count))

        guard let match = matches.first else { return results }

        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }

        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.rangeAt(i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }

        return results.trimmingCharacters(in: .whitespaces)
    }
}
