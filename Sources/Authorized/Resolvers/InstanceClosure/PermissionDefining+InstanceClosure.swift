import Foundation

extension PermissionDefining {
    
    public func allow<R, A>(_ resource: R.Type, _ action: R.Action, as user: A.Type, _ resolve: @escaping (R, A) -> Bool) where R: Resource, A: Authorizable {
        let request = PermissionRequest(
            authorizable: A.authorizableIdentifier,
            resource: R.resourceIdentifier,
            action: action.actionIdentifier,
            isInstance: true
        )
        
        define(
            with: request,
            resolver: InstanceClosurePermissionResolver{ resource, user in
                return resolve(resource, user) ? .allow : .deny
            }
        )
    }
    
    public func deny<R, A>(_ resource: R.Type, _ action: R.Action, as user: A.Type, _ resolve: @escaping (R, A) -> Bool) where R: Resource, A: Authorizable {
        let request = PermissionRequest(
            authorizable: A.authorizableIdentifier,
            resource: R.resourceIdentifier,
            action: action.actionIdentifier,
            isInstance: true
        )
        
        define(
            with: request,
            resolver: InstanceClosurePermissionResolver { resource, user in
                return resolve(resource, user) ? .deny : .allow
            }
        )
    }
    
}