# WIP

# 🔐 Authorized

Vapor 3 package to define permissions and authorize authenticated users to do actions on resources.

## Installation

### Swift Package Manager

Add the package to your dependencies in `Package.swift`

```swift
.package(url: "https://github.com/zdnk/Authorized.git", from: "1.0.0-alpha.1")
```

and in Terminal run `swift package resolve`.

If you are using Xcode for development: `swift package generate-xcodeproj`.

## Example

Check example application in [`Example/`](https://github.com/zdnk/Authorized/tree/master/Example) of this repository, or see Usage section below.

## Mechanics

`.deny` takes precedence before `.allow`. If any rule results in `.deny`, the authorization fails even if all other rules respond with `.allow`.

## Usage

Everything begins with:
```swift
import Authorized
```

### Define resources and actions (or extend models)

```swift
struct Post: Resource { // Probably also conforms to Fluent.Model

    enum Action: String, ResourceAction {
        case create
        case delete
    }

    var id: Int?
    let authorId: User.ID

}
```

### Define user (or extend existing)

```swift
struct User: Authorizable { // Probably also conforms to Fluent.Model and Authenticatable

    var id: Int?
    let username: String

}
```

### Write policies

```swift
struct PostPolicy: ResourcePolicy {

    typealias Model = Post

    // This function is required to return the policy configuration.
    // Think of it as a mapping of actions to functions
    func rules() -> ResourceRules<Post> {
        var rules = ResourceRules<Post>()
        rules.add(self.create, for: .create)
        rules.add(self.delete, for: .delete)
        return rules
    }

    // Define functions that will resolve the permission

    func create(as user: User, on container: Container) -> Future<PermissionResolution> {
        // Allow everyone to create Posts
        return container.future(.allow)
    }

    func delete(post: Post, as user: User, on container: Container) throws -> Future<PermissionResolution> {
        // Allow only authors of the post to delete them
        let result = try post.authorId == user.requireID()
        return container.future(result ? .allow : .deny)
    }

}
```

### Register the policies

You need to register the service in your `configure.swift`.

```swift
// Register provider
try services.register(AuthorizationProvider())

// Initialize configuration - needs to be mutable (var)
var auth = AuthorizationConfig()

// Add policies to the configuration
auth.add(policy: PostPolicy())

// Now register the configuration to the services
services.register(auth)
```

### Authorize actions in your controllers 

One possible way can be like the example below, for more options, please check the API section.

```swift
/// DELETE /posts/{id}
func delete(_ req: Request) -> Future<HTTPStatus> {
    return req.parameters.next(Post.self)
        // Check if there is someone authenticated of type User,
        // and verify if this specific User has permission
        // to remove this specific Post
        .authorize(.delete, as: User.self, on: req) // returns Future<Post>
        .flatMap { post in
            return post.delete(on: req)
        }
        .transform(to: HTTPStatus.noContent)
}
```

or

```swift
/// DELETE /posts/{id}
func delete(_ req: Request) -> Future<HTTPStatus> {
    let user = try self.requireAuthenticated(User.self)
    
    return req.parameters.next(Post.self)
        .authorize(.delete, as: user, on: req) // returns Future<Post>
        .flatMap { post in
            return post.delete(on: req)
        }
        .transform(to: HTTPStatus.noContent)
}
```

Both examples are using Vapors `Authentication` library so the `User` needs to conform to `Authenticatable`.
Also it relies on `Post` being a `Model`.

## API

### Extensions

There are several extensions available on Vapors and Swift NIOs types to help you easily authorize users and actions on resources.

#### `Request` from Vapor

```swift
extension Request {

    public func authorize<A, R>(_: A.Type, _ resource: R, _ action: R.Action) throws -> Future<R> where A : Authenticatable, A : Authorizable, R : Resource

    public func authorize<A, R>(_ user: A, _ resource: R, _ action: R.Action) throws -> Future<R> where A : Authorizable, R : Resource

    public func authorize<A, R>(_: A.Type, _ resource: R.Type, _ action: R.Action) throws -> Future<Void> where A : Authenticatable, A : Authorizable, R : Resource

    public func authorize<A, R>(_ user: A, _ resource: R.Type, _ action: R.Action) throws -> Future<Void> where A : Authorizable, R : Resource

}
```

#### `Future<T: Resource>` from Swift NIO

```swift
extension EventLoopFuture where T : Resource {

    public func authorize<A>(_ action: T.Action, as user: A, on container: Container) -> Future<T> where A : Authorizable

    public func authorize<A>(_ action: T.Action, as user: A.Type, on request: Request) -> Future<T> where A : Authenticatable, A : Authorizable

}
```
#### `Authorizable` from Authorized

```swift
extension Authorizable {

    public func can<R>(_: R.Type, _ action: R.Action, on container: Container) throws -> Future<Bool> where R : Resource

    public func authorize<R>(_: R.Type, _ action: R.Action, on container: Container) throws -> Future<Void> where R : Resource

    public func can<R>(_ resource: R, _ action: R.Action, on container: Container) throws -> Future<Bool> where R : Resource

    public func authorize<R>(_ resource: R, _ action: R.Action, on container: Container) throws -> Future<R> where R : Resource

}
```

### Overriding

If you need to allow everything for some specific user, deny everything or any other global behavior, you can define it like this:

```swift
struct AdminRolePolicy: Policy {
    
    func configure(in config: PermissionDefining) throws {

        config.before { (context) -> EventLoopFuture<PermissionResolution?> in
            guard let user = context.user as? User else {
                // passing `nil` means continue executing with default behavior
                return context.container.future(nil)
            }
            
            if user.role == .admin {
                // Admins can do anything!
                // passing `.allow` or `.deny` will cause the authorization to fail early
                // and skips executing the regular rules
                return context.container.future(.allow)
            }
            
            // passing `nil` means continue executing with default behavior
            return context.container.future(nil)
        }
        
    }
    
}
```

In `configure.swift`:
```swift
auth.add(policy: AdminRolePolicy())
```

## Bug? Feature request?

Did you find a bug or would like to see new feature implemented? Great! Please [open new issue](https://github.com/zdnk/Authorized/issues/new) or [create pull request](https://github.com/zdnk/Authorized/compare) :)
