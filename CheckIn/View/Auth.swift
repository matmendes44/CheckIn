import Foundation
import CryptoKit

//  User model

extension User {
    var isIdentifiable: Bool { role == .professor }
    var displayName: String { role == .professor ? name : "Anonymous" }
}

// university's info

struct IdentityClaims {
    let subject: String          // stable unique id from the IdP ("sub")
    let name: String?
    let email: String?
    let affiliations: [String]   // e.g. eduPersonAffiliation: ["faculty"], ["student"]
}

enum UserFactory {

    static func role(from claims: IdentityClaims) -> UserRole {
        claims.affiliations.map { $0.lowercased() }.contains("faculty") ? .professor : .student
    }

    static func user(from claims: IdentityClaims) -> User {
        switch role(from: claims) {
        case .professor:
            // Identifiable: keep verified name and email.
            return User(id: claims.subject,
                        name: claims.name ?? "Professor",
                        role: .professor,
                        email: claims.email)
        default:
            // Anonymous: no name, no email. Only an opaque id derived from the SSO subject,
            // so the same student gets the same id on every device without us storing who they are.
            return User(id: pseudonym(for: claims.subject),
                        name: "Anonymous",
                        role: .student,
                        email: nil)
        }
    }

    
    private static func pseudonym(for subject: String) -> String {
        let digest = SHA256.hash(data: Data(("checkin.v1|" + subject).utf8))
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }
}

// Auth service

typealias WebAuthenticate = (_ url: URL, _ callbackScheme: String) async throws -> URL

protocol AuthService {
    func signIn(authenticate: WebAuthenticate) async throws -> User
}

/// server auth code exchange
protocol IdentityBackend {
    func claims(forAuthorizationCode code: String) async throws -> IdentityClaims
}

enum AuthError: LocalizedError {
    case missingCode, backendNotConfigured
    var errorDescription: String? {
        switch self {
        case .missingCode: return "Sign-in didn't complete. Please try again."
        case .backendNotConfigured: return "University sign-in isn't set up yet."
        }
    }
}

struct UniversitySSOAuthService: AuthService {
    let authorizeURL: URL          // e.g. https://sso.towsonuniversity.edu/authorize
    let clientID: String
    let callbackScheme: String     // e.g. "checkin" (register under URL Types)
    let backend: IdentityBackend

    func signIn(authenticate: WebAuthenticate) async throws -> User {
        var comps = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: "openid profile email eduperson_affiliation"),
            .init(name: "redirect_uri", value: "\(callbackScheme)://callback"),
        ]
        let callback = try await authenticate(comps.url!, callbackScheme)
        guard let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw AuthError.missingCode }

        let claims = try await backend.claims(forAuthorizationCode: code)
        return UserFactory.user(from: claims)
    }
}

/// test/mocks
struct MockAuthService: AuthService {
    let asProfessor: Bool
    func signIn(authenticate: WebAuthenticate) async throws -> User {
        UserFactory.user(from: IdentityClaims(
            subject: asProfessor ? "prof-123" : "stud-456",
            name: asProfessor ? "Mr. Jal Irani" : "Real Student Name",
            email: asProfessor ? "JIrani@university.edu" : "student@university.edu",
            affiliations: [asProfessor ? "faculty" : "student"]))
    }
}

/// place in for database server. mock buttons still work.
struct PlaceholderIdentityBackend: IdentityBackend {
    func claims(forAuthorizationCode code: String) async throws -> IdentityClaims {
        throw AuthError.backendNotConfigured
    }
}
