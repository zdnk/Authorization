import Foundation
import Vapor

open class PermissionManager: PermissionVerifying {

    internal var repository: PermissionRepository
    
    public required init(repository: PermissionRepository) {
        self.repository = repository
    }
    
    public convenience init() {
        self.init(repository: PermissionRepository())
    }
    
    open func allowed<R, A>(_ target: ResourceTarget<R>, _ action: R.Action, as user: A, on container: Container) -> Future<Bool> where R : Resource, A : Authorizable {
        let permissions = self.permissions(
            action: action.actionIdentifier,
            resource: R.resourceIdentifier,
            user: user,
            instance: target.isInstance
        )
        
        return self.resolve(
            permissions,
            target: target,
            user: user,
            on: container
        ).map { resolution -> Bool in
            return resolution.isAllow
        }
    }
    
}
