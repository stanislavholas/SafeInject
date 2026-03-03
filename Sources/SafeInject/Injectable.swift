/// A type whose injected dependencies can be automatically discovered and validated.
///
/// Conform to this protocol using the ``Injectable()`` macro.
/// The macro scans for `@Injected` properties and generates the required members.
public protocol Injectable: AnyObject {

    /// The types of all injected dependencies.
    static var dependencies: [Any.Type] { get }

    /// Creates an instance for validation purposes.
    ///
    /// Generated automatically by the `@Injectable` macro.
    /// Calling this triggers all `@Injected` property wrapper resolutions,
    /// which validates that every dependency is registered in the DI container.
    static func _makeInstance() -> Any
}
