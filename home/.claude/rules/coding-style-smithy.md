---
globs: ["**/*.smithy", "smithy-build.json"]
---

# Smithy Coding Style Guidelines

## File and Folder Structure

### Package Organization

- **Rule**: Organize Smithy files in a hierarchical structure that reflects your service's domain model.
- **Rule**: Place core types used across multiple operations in a `types.smithy` file within the appropriate namespace directory.
- **Good Example**:
  ```
  /com
    /example
      /grauto
        /vendoradapter
          /model
            types.smithy           # Core data types and shared structures
            operations.smithy      # Service operations
            /vendor
              vendortypes.smithy   # Vendor-specific types
  ```

### Namespace Conventions

- **Rule**: Use reverse-domain-name notation for your namespace (e.g., `com.example.grauto.vendoradapter.model`).
- **Rule**: Keep namespaces consistent across related models.
- **Rule**: Service models and APIs should be located in their own namespaces to allow for clear dependency management.

### File Content Organization

- **Rule**: Organize contents within a Smithy file in the following order:
  1. Namespace declaration
  2. Imports
  3. Service definition (if applicable)
  4. Operations (if applicable)
  5. Resource definitions (if applicable)
  6. Structures
  7. Typed strings and simple types
  8. Enumerations

## Type Definitions

### Typed Strings

- **Rule**: Always use typed strings rather than raw strings for identifiers and business concepts.
- **Rule**: Place related typed strings in the `types.smithy` file.
- **Rule**: Add validation traits like `@length` and `@pattern` to constrain values appropriately.
- **Rule**: For IDs, include specific pattern constraints that match their expected format.
- **Rule**: Add links to external documentation in comments when a type has complex semantics or planned future improvements.
- **Good Example**:
  ```smithy
  // TODO [TICKET-123] [TechImprovement]: Link to wiki as external documentation for container id definition and use cases
  @documentation("A unique container identifier. A container may represent a bot, a tray, a lane, a tote etc.")
  @pattern("^[a-zA-Z0-9\\-_]+$")
  @length(min: 1, max: 64)
  string ContainerId

  @documentation("Order identifier, e.g. 71219bed-eed1-4ec0-b723-9de52776be5b")
  @pattern("^[a-zA-Z0-9\\-]+$")
  @length(min: 1, max: 64)
  string OrderId

  @documentation("ISO-8601 formatted timestamp to seconds, millis, or nanos precision")
  @pattern("^(?<date>[0-9]{4}-[0-9]{2}-[0-9]{2})T(?<time>[0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]{0,9})?)Z$")
  @length(min: 20, max: 30)
  string ISO8601Timestamp
  ```
- **Bad Example** (using raw strings instead of typed strings):
  ```smithy
  structure Vendor {
      @required
      vendorId: String,  // Should be a typed VendorId
      name: String,
  }
  ```

### Structure Definitions

- **Rule**: Use singular nouns for structure names.
- **Rule**: Mark required fields with the `@required` trait.
- **Rule**: Order fields with required fields first, followed by optional fields.
- **Good Example**:
  ```smithy
  structure CatalogItem {
      @required
      itemId: ItemId,
      @required
      title: String,
      description: String,
      price: PriceAmount,
      categories: CategoriesList,
  }
  ```

### Enumerations

- **Rule**: Use singular nouns for enumeration names.
- **Rule**: Use ALL_CAPS for enumeration values.
- **Rule**: Include a documentation string for the enum and each value, even when the meaning seems obvious.
- **Rule**: Use commas to separate enum values for consistency.
- **Rule**: When adding new values to existing enums, add them at the end to maintain backward compatibility.
- **Rule**: Consider marking deprecated values with the `@deprecated` trait.
- **Good Example**:
  ```smithy
  @documentation("Enumeration of the possible statuses associated with a Port")
  enum PortStatus {
      @deprecated
      OCCUPIED,
      @deprecated
      EMPTY,
      ENABLED,
      DISABLED
  }

  @documentation("Enumeration for the type of catalog sync operation")
  enum CatalogSyncType {
      @documentation("Updates items in the Vendor catalog with the ones in the payload, if item does not exist add it to the catalog")
      UPDATE,

      @documentation("Completely replace items in the Vendor catalog with the ones in the payload")
      OVERRIDE
  }
  ```

## Documentation

### Service and Operation Documentation

- **Rule**: All services and operations **MUST** have descriptive documentation strings using `@documentation`.
- **Rule**: Operation documentation should describe the purpose, important parameters, and potential side effects.
- **Good Example**:
  ```smithy
  @documentation("Service that manages vendor catalog items and synchronization")
  @paginated(inputToken: "nextToken", outputToken: "nextToken", pageSize: "maxResults")
  service VendorCatalogService {
      version: "2023-01-01",
      operations: [
          ListVendorItems,
          GetVendorItem,
      ]
  }

  @documentation("Retrieves a paginated list of items from a vendor's catalog")
  @readonly
  operation ListVendorItems {
      input: ListVendorItemsInput,
      output: ListVendorItemsOutput,
      errors: [
          ValidationException,
          InternalServerException,
          VendorNotFoundException,
      ]
  }
  ```

### Structure and Field Documentation

- **Rule**: All structures and their fields **MUST** have descriptive documentation strings using `@documentation`.
- **Rule**: Documentation should describe what the field represents, not how it's used programmatically.
- **Good Example**:
  ```smithy
  @documentation("Configuration for synchronization with a vendor's catalog system")
  structure VendorSyncConfig {
      @required
      @documentation("Unique identifier for the vendor")
      vendorId: VendorId,

      @documentation("Maximum number of items to synchronize in a single batch")
      batchSize: Integer,

      @documentation("Time interval in minutes between synchronization attempts")
      syncIntervalMinutes: Integer,
  }
  ```
- **Bad Example** (poor documentation):
  ```smithy
  @documentation("Config")  // Not descriptive
  structure VendorSyncConfig {
      @required
      @documentation("The vendor ID")  // Doesn't add value beyond the field name
      vendorId: VendorId,

      @documentation("Used to set batch size")  // Describes how it's used, not what it is
      batchSize: Integer,
  }
  ```

### Enum Documentation

- **Rule**: All enums and enum values **MUST** have descriptive documentation strings using `@documentation`.
- **Rule**: The documentation should describe what the enum or value represents in business terms.
- **Good Example**:
  ```smithy
  @documentation("Describes result of 'RequestBulkCatalogItemSync' processing")
  enum CatalogSyncResultStatus {
      @documentation("All of the requested items were successfully synchronized")
      SUCCESS,

      @documentation("Any of the requested items failed synchronization, although some may still have succeeded")
      FAILURE,

      @documentation("The synchronization request was accepted but is still being processed")
      IN_PROGRESS
  }
  ```

## Lists and Collections

### List Definitions

- **Rule**: Define constraints using the `@length` trait to specify minimum and maximum sizes.
- **Rule**: Use the `@uniqueItems` trait when list items should not contain duplicates.
- **Rule**: Document the purpose of the list, not just the type of items it contains.
- **Good Example**:
  ```smithy
  @uniqueItems
  @length(min: 0, max: 50)
  list ContainerFlagList {
      member: ContainerFlag
  }

  @length(min: 1, max: 300)
  list ItemToPickList {
      member: ItemToPick
  }
  ```

## Traits and Validation

### Validation Traits

- **Rule**: Use appropriate validation traits for all fields where constraints can be defined.
- **Rule**: For strings, always use `@length` with reasonable min/max values.
- **Rule**: For IDs and codes, use `@pattern` with specific regex patterns that match the expected format.
- **Rule**: For numeric types, use `@range` to define valid input ranges, especially for pagination parameters.
- **Rule**: Use validation traits that match business rules (e.g., timestamp formats, ID formats).
- **Good Example**:
  ```smithy
  @length(min: 3, max: 100)
  @pattern("^[A-Za-z0-9_-]+$")
  @documentation("Unique identifier for a category in the catalog")
  string CategoryId

  @range(min: 1, max: 1000)
  @documentation("Maximum number of results to return in a paginated response")
  integer MaxResults

  @range(min: 0)
  @documentation("Value of the weight in the unit defined in the unit field. This field is always positive")
  value: BigDecimal
  ```

### Operation Traits

- **Rule**: Mark operations as `@readonly` if they don't modify resources.
- **Rule**: Use `@paginated` for operations that return collections that might be large.
- **Rule**: Use `@idempotent` for operations where repeated calls with the same parameters have the same effect as a single call.
- **Good Example**:
  ```smithy
  @readonly
  @paginated(inputToken: "nextToken", outputToken: "nextToken", pageSize: "maxResults")
  operation ListVendorItems {
      input: ListVendorItemsInput,
      output: ListVendorItemsOutput
  }

  @idempotent
  operation UpdateVendorItemStatus {
      input: UpdateVendorItemStatusInput,
      output: UpdateVendorItemStatusOutput
  }
  ```

## Error Handling

### Error Definitions

- **Rule**: Define specific error types for different failure scenarios in your service.
- **Rule**: Use standard error types where appropriate (e.g., `ValidationException`, `InternalServerException`).
- **Rule**: Include error-specific fields in custom error structures to provide context.
- **Good Example**:
  ```smithy
  @error("client")
  @httpError(400)
  structure ValidationException {
      @required
      message: String,

      @documentation("List of fields that failed validation")
      fields: FieldList
  }

  @error("client")
  @httpError(404)
  structure VendorNotFoundException {
      @required
      message: String,

      @documentation("ID of the vendor that was not found")
      vendorId: VendorId
  }
  ```

### Operation Errors

- **Rule**: Explicitly list all possible errors that an operation can return.
- **Rule**: Include both standard and custom errors in the operation's error list.
- **Good Example**:
  ```smithy
  operation GetVendorItem {
      input: GetVendorItemInput,
      output: GetVendorItemOutput,
      errors: [
          ValidationException,
          VendorNotFoundException,
          ItemNotFoundException,
          InternalServerException,
          ThrottlingException
      ]
  }
  ```

## Version and Compatibility

### Versioning

- **Rule**: Include a version for all services using the `version` property.
- **Rule**: Use ISO 8601 date format (YYYY-MM-DD) for version strings.
- **Good Example**:
  ```smithy
  service VendorCatalogService {
      version: "2023-01-01",
      operations: [GetVendorItem]
  }
  ```

### Backward Compatibility

- **Rule**: Maintain backward compatibility when evolving models.
- **Rule**: Never remove or rename fields in existing structures.
- **Rule**: Never make optional fields required.
- **Rule**: Never change field types to incompatible types.
- **Rule**: Add new fields as optional to maintain compatibility.

## File Organization and Structure

### Operation Files

- **Rule**: Define each operation in its own file within an `operation` subfolder.
- **Rule**: Name operation files after the operation name in snake_case (e.g., `get_catalog_items.smithy`).
- **Rule**: Follow a consistent structure within operation files:
  1. Namespace declaration
  2. Operation definition with documentation
  3. Input structure with the `@input` trait
  4. Output structure with the `@output` trait
  5. Supporting structures and unions specific to the operation
- **Good Example**:
  ```smithy
  $version: "2"

  namespace com.example

  @documentation("Return data for one or more catalog items, as registered in Vendor system")
  operation GetCatalogItems {
      input: GetCatalogItemsInput
      output: GetCatalogItemsOutput
      errors: [
          DependencyException
          InternalFaultException
          InvalidInputException
      ]
  }

  @input
  structure GetCatalogItemsInput {
      // Input fields
  }

  @output
  structure GetCatalogItemsOutput {
      // Output fields
  }

  // Operation-specific supporting structures
  ```

### Service Definition

- **Rule**: Define the service in a `main.smithy` file.
- **Rule**: List all operations in the service definition, even if they are defined in separate files.
- **Rule**: Use ISO 8601 date format (YYYY-MM-DD) for the service version.
- **Good Example**:
  ```smithy
  $version: "2"
  namespace com.example

  service ExampleService {
      version: "2023-01-15"
      operations: [
          CreateItem
          GetItem
          ListItems
          UpdateItem
          DeleteItem
      ]
  }
  ```

## Common Patterns

### Selectors

- **Rule**: Use a selector pattern for complex filtering or selection criteria.
- **Rule**: Implement selectors as unions when multiple selection strategies are available.
- **Rule**: Include selector type enums to differentiate between selection strategies.
- **Good Example**:
  ```smithy
  // Main selector structure
  structure CatalogItemsSelector {
      @required
      type: CatalogItemsSelectorType
      @required
      details: CatalogItemsSelectorDetails
  }

  // Selector type enum
  enum CatalogItemsSelectorType {
      @documentation("Get catalog data for selected ASINs")
      SELECTED_ASINS,
      @documentation("Get catalog data for all items that are part of selection for a store")
      ALL
  }

  // Selector details as a union
  union CatalogItemsSelectorDetails {
      allCatalogItemsSelector: AllCatalogItemsSelector
      selectedCatalogItemsSelector: SelectedCatalogItemsSelector
  }

  // Implementation of each selector type
  structure AllCatalogItemsSelector {
      @required
      requestId: RequestId
  }

  structure SelectedCatalogItemsSelector {
      @required
      asins: SelectedAsinsList
  }
  ```

### Resource Modeling

- **Rule**: Model domain entities as resources where appropriate.
- **Rule**: Define clear relationships between resources using the `@relation` trait.
- **Rule**: Associate operations with resources using the `resources` property of a service.
- **Good Example**:
  ```smithy
  resource Vendor {
      identifiers: { vendorId: VendorId },
      read: GetVendor,
      list: ListVendors,
      resources: [VendorItem]
  }

  @documentation("An item in a vendor's catalog")
  resource VendorItem {
      identifiers: {
          vendorId: VendorId,
          itemId: VendorItemId
      },
      read: GetVendorItem,
      list: ListVendorItems,
      update: UpdateVendorItem,
      delete: DeleteVendorItem,
      create: CreateVendorItem
  }
  ```

## Common Anti-patterns to Avoid

### Overloading String Types

- **Rule**: Don't use generic strings for semantically different concepts.
- **Rule**: Create specific typed strings for identifiers, even if they follow the same pattern.
- **Bad Example**:
  ```smithy
  // Don't use String for semantically different concepts
  structure VendorData {
      id: String,      // Should be VendorId
      itemId: String,  // Should be VendorItemId
      status: String   // Should be an enum
  }
  ```

### Missing Validation for Core Types

- **Rule**: Don't leave validation constraints undefined for core types, especially IDs and timestamps.
- **Bad Example**:
  ```smithy
  // Missing length and pattern constraints
  string OrderId

  // Missing range constraint for a value that should be positive
  structure Quantity {
      value: BigDecimal  // Should have @range(min: 0)
      unit: QuantityUnit
  }
  ```

### Inconsistent Unit Representation

- **Rule**: Always represent measurements (weight, dimensions, etc.) with both value and unit.
- **Bad Example**:
  ```smithy
  // Inconsistent unit representation
  structure Item {
      weightKg: BigDecimal,  // Should be a proper Weight structure with value and unit
      lengthMm: BigDecimal   // Should be a proper Dimension structure with value and unit
  }
  ```
- **Good Example**:
  ```smithy
  structure Item {
      weight: Weight,
      dimensions: Dimensions
  }

  structure Weight {
      @required
      @range(min: 0)
      value: BigDecimal,

      @required
      unit: WeightUnit
  }
  ```

### Inadequate Documentation

- **Rule**: Don't provide generic or redundant documentation that just repeats the field name.
- **Bad Example**:
  ```smithy
  @documentation("ID")  // Too vague
  string ItemId

  @documentation("Quantity")  // Just repeating the field name
  structure Quantity {
      value: BigDecimal,
      unit: QuantityUnit
  }
  ```

### Mixing Operations and Structures in the Same File

- **Rule**: Don't define operations and their related structures in the same file as shared types.
- **Rule**: Don't define multiple unrelated operations in the same file.
- **Bad Example**: Putting multiple operations in a single file rather than organizing them into separate operation files.

### Inconsistent Naming

- **Rule**: Use consistent naming patterns across related concepts.
- **Bad Example**:
  ```smithy
  // Inconsistent naming
  structure GetVendorRequest {
      vendorId: VendorId
  }

  structure FetchItemInput {  // Should be GetItemRequest for consistency
      itemId: ItemId
  }
  ```

### Insufficient Error Modeling

- **Rule**: Don't rely solely on generic errors; define domain-specific error types.
- **Bad Example**:
  ```smithy
  operation GetVendorItem {
      input: GetVendorItemInput,
      output: GetVendorItemOutput,
      errors: [ServiceException]  // Too generic, should define specific errors
  }
  ```

By following these guidelines, your Smithy models will be more readable, maintainable, and provide better client experiences through clear documentation, consistent patterns, and appropriate validation.
