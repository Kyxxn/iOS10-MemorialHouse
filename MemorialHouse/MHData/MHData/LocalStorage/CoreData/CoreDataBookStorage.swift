import MHFoundation
import MHCore
import CoreData

public final class CoreDataBookStorage {
    private let coreDataStorage: CoreDataStorage
    
    public init(coreDataStorage: CoreDataStorage) {
        self.coreDataStorage = coreDataStorage
    }
}

extension CoreDataBookStorage: BookStorage {
    public func create(data: BookDTO) async -> Result<Void, MHDataError> {
        return await coreDataStorage.performDatabaseTask { [weak self] context in
            guard let entity = NSEntityDescription.entity(forEntityName: "BookEntity", in: context) else {
                throw MHDataError.noSuchEntity(key: "BookEntity")
            }
            let book = NSManagedObject(entity: entity, insertInto: context)
            book.setValue(data.id, forKey: "id")
            book.setValue(data.title, forKey: "title")
            book.setValue(self?.dtoPagesToCore(data.pages, in: context), forKey: "pages")
            
            try context.save()
        }
    }
    
    public func fetch(with id: UUID) async -> Result<BookDTO, MHDataError> {
        return await coreDataStorage.performDatabaseTask { [weak self] context in
            guard let bookEntity = try self?.getEntityByIdentifier(in: context, with: id) else {
                throw MHDataError.findEntityFailure
            }
            guard let bookDTO = self?.coreBookToDTO(bookEntity) else {
                throw MHDataError.convertDTOFailure
            }
            
            return bookDTO
        }
    }
    
    public func update(with id: UUID, data: BookDTO) async -> Result<Void, MHDataError> {
        return await coreDataStorage.performDatabaseTask { [weak self] context in
            guard let newEntity = try self?.getEntityByIdentifier(in: context, with: id) else {
                throw MHDataError.findEntityFailure
            }
            newEntity.setValue(data.id, forKey: "id")
            newEntity.setValue(data.title, forKey: "title")
            newEntity.setValue(self?.dtoPagesToCore(data.pages, in: context), forKey: "pages")
            
            try context.save()
        }
    }
    
    public func delete(with id: UUID) async -> Result<Void, MHDataError> {
        return await coreDataStorage.performDatabaseTask { [weak self] context in
            guard let entity = try self?.getEntityByIdentifier(in: context, with: id) else {
                throw MHDataError.findEntityFailure
            }
            context.delete(entity)
            
            try context.save()
        }
    }
    
    private func getEntityByIdentifier(in context: NSManagedObjectContext, with id: UUID) throws -> BookEntity? {
        let request = BookEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@", id as CVarArg
        )
        
        return try context.fetch(request).first
    }
}

// MARK: - Mapper
extension CoreDataBookStorage {
    // MARK: - Core to DTO
    private func coreBookToDTO(_ book: BookEntity) -> BookDTO? {
        guard let id = book.id,
              let title = book.title,
              let corePages = book.pages
        else { return nil }
        let pages = corePagesToDTO(corePages)
        
        return BookDTO(
            id: id,
            title: title,
            pages: pages
        )
    }
    
    private func corePagesToDTO(_ pages: NSOrderedSet) -> [PageDTO] {
        return pages.compactMap {
            guard let page = $0 as? PageEntity else { return nil }
            return corePageToDTO(page)
        }
    }
    
    private func corePageToDTO(_ page: PageEntity) -> PageDTO? {
        guard let id = page.id,
              let mediaDescriptions = page.mediaDescriptions,
              let text = page.text
        else { return nil }
        
        let metadata = mediaDescriptions.reduce(into: [Int: MediaDescriptionDTO]()) { partialResult, element in
            guard let element = element as? MediaDescriptionEntity else { return }
            guard let (index, mediaDescription) = coreMediaDescriptionToDTO(element) else { return }
            partialResult[index] = mediaDescription
        }
                
        return PageDTO(
            id: id,
            metadata: metadata,
            text: text
        )
    }
    
    private func coreMediaDescriptionToDTO(_ mediaDescription: MediaDescriptionEntity) -> (Int, MediaDescriptionDTO)? {
        guard let id = mediaDescription.id,
              let type = mediaDescription.type
        else { return nil }
        let location = mediaDescription.location
        return (Int(location), MediaDescriptionDTO(
            id: id,
            type: type,
            attributes: mediaDescription.attributes
        ))
    }
    
    // MARK: - DTO to Core
    private func dtoPagesToCore(_ pages: [PageDTO], in context: NSManagedObjectContext) -> NSOrderedSet? {
        let pageEntities = pages.compactMap { dtoPageToCore($0, in: context) }
        return NSOrderedSet(array: pageEntities)
    }
    
    private func dtoPageToCore(_ page: PageDTO, in context: NSManagedObjectContext) -> PageEntity? {
        guard let entity = NSEntityDescription.insertNewObject(
            forEntityName: "PageEntity",
            into: context
        ) as? PageEntity else {
            return nil
        }
        
        entity.id = page.id
        entity.text = page.text
        entity.mediaDescriptions = dtoMediaDescriptionsToCore(page.metadata, in: context)
        
        return entity
    }
    
    private func dtoMediaDescriptionsToCore(
        _ metadata: [Int: MediaDescriptionDTO],
        in context: NSManagedObjectContext
    ) -> NSSet? {
        let mediaDescriptionEntities = metadata.compactMap { location, description in
            dtoMediaDescriptionToCore(location: location, description, in: context)
        }
        return NSSet(array: mediaDescriptionEntities)
    }
    
    private func dtoMediaDescriptionToCore(
        location: Int,
        _ mediaDescription: MediaDescriptionDTO,
        in context: NSManagedObjectContext
    ) -> MediaDescriptionEntity? {
        guard let entity = NSEntityDescription.insertNewObject(
            forEntityName: "MediaDescriptionEntity",
            into: context
        ) as? MediaDescriptionEntity else {
            return nil
        }
        
        entity.id = mediaDescription.id
        entity.type = mediaDescription.type
        entity.attributes = mediaDescription.attributes
        entity.location = Int64(location)
        
        return entity
    }
}
