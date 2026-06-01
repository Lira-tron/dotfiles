---
description: Java 17+ coding standards, modern idioms, and unit testing guidelines for code-writing agents
author: Development Team
version: 3.1
tags: ["java", "java17", "java21", "coding-standard", "testing", "unit-tests", "best-practices", "modern-java"]
globs: ["**/*.java"]
---

# Java Coding Standards (Java 17+)

Rules that influence code generation decisions. For formatting/style details (braces, indentation, whitespace, Javadoc format), see `java-formatting.steering.md`.

---

## Naming Conventions

- Packages: `all.lowercase.concatenated`
- Classes: `UpperCamelCase` (nouns). Test classes end with `Test`
- Methods: `lowerCamelCase` (verbs). Test methods: `methodName_scenario` with underscores
- Constants (`static final`, deeply immutable): `UPPER_SNAKE_CASE`
- Fields, parameters, locals: `lowerCamelCase`
- Type variables: single letter (`T`, `E`) or class-style + `T` (`RequestT`)
- No prefixes/suffixes (`mName`, `name_`, `s_name`)

---

## Modern Java Idioms (17+)

### Records (Java 16+)
- Use records for immutable data carriers instead of `@Value`
- Use Lombok `@NonNull` on record components for null checks — avoids boilerplate compact constructors
- Use compact constructors only when custom validation beyond null checks is needed
- Prefer records over `@Value` unless you need builder, `@With`, `@Singular`, or inheritance

```java
// Simple null checks — use @NonNull, no compact constructor needed
public record OrderInfo(@NonNull String orderId, @NonNull String customerId) {}

// Custom validation beyond null checks — compact constructor is appropriate
public record Money(@NonNull BigDecimal amount, @NonNull Currency currency) {
    public Money {
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount cannot be negative");
        }
    }
}

// Local record for intermediate grouping
public Map<String, BigDecimal> calculateRevenue(final List<Order> orders) {
    record OrderRevenue(String region, BigDecimal amount) {}
    return orders.stream()
        .map(o -> new OrderRevenue(o.getRegion(), o.getTotal()))
        .collect(groupingBy(OrderRevenue::region,
            reducing(BigDecimal.ZERO, OrderRevenue::amount, BigDecimal::add)));
}
```

### Sealed Types (Java 17+)
- Use sealed types for closed hierarchies where all subtypes are known
- Combine with records for algebraic data types

```java
public sealed interface PaymentMethod
    permits CreditCard, BankTransfer, DigitalWallet {
    BigDecimal amount();
}
public record CreditCard(String cardNumber, String expiry, BigDecimal amount)
    implements PaymentMethod {}
```

### Pattern Matching
- Always use pattern matching `instanceof` — never cast after plain `instanceof`
- Use pattern matching in switch for type-based dispatch (Java 21+)
- Use guarded patterns (`when`) instead of if-else inside cases
- Combine with sealed types for exhaustive, compiler-checked switches

```java
// instanceof (Java 16+)
if (obj instanceof String s && !s.isBlank()) {
    processNonBlankString(s);
}

// Switch with sealed types — exhaustive, no default needed (Java 21+)
public BigDecimal calculateFee(PaymentMethod method) {
    return switch (method) {
        case CreditCard cc when cc.amount().compareTo(LARGE_AMOUNT) > 0 ->
            cc.amount().multiply(PREMIUM_RATE);
        case CreditCard cc -> cc.amount().multiply(STANDARD_RATE);
        case BankTransfer bt -> FLAT_FEE;
        case DigitalWallet dw -> BigDecimal.ZERO;
    };
}

// Record destructuring (Java 21+)
return switch (shape) {
    case Circle(var radius) -> Math.PI * radius * radius;
    case Rectangle(var w, var h) -> w * h;
};
```

### Sequenced Collections (Java 21+)
- Prefer `getFirst()` / `getLast()` over index-based access
- Use `reversed()` for reverse-order views

### Virtual Threads (Java 21+)
- Use for I/O-bound concurrent tasks, never for CPU-bound
- Never pool virtual threads — create new ones per task
- Use `ReentrantLock` instead of `synchronized` (avoids pinning carrier thread)

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    final var futures = serviceUrls.stream()
        .map(url -> executor.submit(() -> checkHealth(url)))
        .toList();
    return futures.stream().map(this::getResult).toList();
}
```

### Collections & Strings
- Prefer `List.of()`, `Set.of()`, `Map.of()` for immutable collections
- Use `List.copyOf()` for defensive copies
- Use `.toList()` instead of `.collect(Collectors.toList())`
- Use `String.formatted()`, `isBlank()`, `strip()`, `lines()`

---

## Core Practices

### Imports Over Fully-Qualified Names
- Always add an `import` statement and use the simple class name in code
- Never use fully-qualified class names inline (e.g., `throw new com.example.foo.BarException(...)`)
- Only use FQCNs when two classes share the same simple name and both are needed in the same file — import the more frequently used one, qualify the other

```java
// Bad — inline FQCN
throw new com.example.myservice.exception.ItemNotFoundException(e.getMessage(), e);

// Good — import and use simple name
import com.example.myservice.exception.ItemNotFoundException;
// ...
throw new ItemNotFoundException(e.getMessage(), e);
```

### final, var, and Immutability
- Always use `final` for class members, method parameters, and local variables where possible
- Use `final var` when type is obvious from right-hand side
- Don't use `var` when it reduces readability

```java
// Good: final var with obvious type
final var config = OrderConfig.builder().maxRetries(3).build();

// Good: explicit type when not obvious
final Optional<User> user = repository.findById(id);
```

### Streams Over Loops
- Prefer streams for filtering, mapping, collecting
- Use traditional loops when performance is critical or logic is complex
- Use method references when possible

```java
return customers.stream()
    .filter(Customer::isActive)
    .map(Customer::getEmail)
    .filter(Objects::nonNull)
    .toList();
```

### Error Handling
- Use `Optional<>` instead of returning null
- Validate inputs at method boundaries with Lombok `@NonNull` (`lombok.NonNull`) on parameters and record components — Lombok generates the runtime null check (`NullPointerException` with the parameter name), no `Objects.requireNonNull()` boilerplate. **Never use JetBrains `org.jetbrains.annotations.NotNull` or JSR-305 `javax.annotation.Nonnull`** — they are annotation-only and don't enforce at runtime
- Use specific exception types with meaningful context messages
- Log or throw, not both (except at service activity layer)
- Use multi-catch for related exception types

```java
import lombok.NonNull;

public Optional<User> findUser(@NonNull final String userId) {
    return Optional.ofNullable(repository.findById(userId));
}
```

### Boolean Parameters
- Use enums instead of boolean parameters for extensibility

### Switch Expressions
- Use arrow syntax for switch expressions
- Every switch must be exhaustive (`default` or cover all cases)

---

## Lombok

### Approved Annotations
| Annotation | When to Use |
|---|---|
| `@Value` + `@Builder` | Immutable objects needing builder or inheritance |
| `@Data` + `@NoArgsConstructor` | JPA entities, mutable DTOs |
| `@RequiredArgsConstructor` | Dependency injection (Spring/Dagger) |
| `@Log4j2` | All classes needing logging |
| `@Getter`/`@Setter` | Selective accessor generation |
| `@With` | Immutable copies with one field changed |
| `@Singular` | Builder collection fields |
| `@ToString.Exclude` | Sensitive/verbose fields |
| `@EqualsAndHashCode.Exclude` | Fields excluded from equality |
| `@Builder.Default` | Default values in builders |
| `@NonNull` (`lombok.NonNull`) | Runtime null check on parameters / record components (replaces `Objects.requireNonNull`) |

### Avoid
- `@SneakyThrows` — handle checked exceptions explicitly
- `@Cleanup` — use try-with-resources
- `@val`/`@var` — use Java's built-in `var`
- `@Synchronized` — use explicit locks

### Records vs Lombok Decision
- Simple immutable data (≤3 fields, no defaults) → Record
- Builder pattern, `@With`, `@Singular`, inheritance → `@Value` + `@Builder`

---

## Logging

- Use `@Log4j2` annotation
- Parameterized logging only — never string concatenation
- Always include stacktrace when logging exceptions
- Never log full objects at INFO or above
- Include actionable context: `orderId={}`, `customerId={}`

```java
log.info("Order processing started - orderId={}, customerId={}", order.getId(), order.getCustomerId());
log.error("Payment failed for order {} - Error: {}", order.getId(), e.getMessage(), e);
```

---

## Unit Testing

### Assertions
- Prefer AssertJ as primary assertion library
- If unavailable, use Hamcrest; otherwise follow project convention
- Never mix assertion libraries in same test class

### Structure
- Test names: `methodNameScenarioValidation` or `methodName_scenario`
- Use meaningful constants, never magic values
- Always use Given/When/Then structure (comments required)
- Test happy path, edge cases, null inputs, error scenarios
- Avoid mocking static methods — refactor to dependency injection
- Use `@Nested` to group tests by method or scenario
- Use `@ParameterizedTest` with `@CsvSource`, `@EnumSource`, or `@MethodSource` for 3+ similar test cases

```java
@ExtendWith(MockitoExtension.class)
class OrderProcessorTest {
    private static final String VALID_ORDER_ID = "ORD-12345";

    @Mock private PaymentService paymentService;
    @InjectMocks private OrderProcessor orderProcessor;

    @Nested
    class ProcessOrder {
        @Test
        void validOrderSuccess() {
            // Given
            final var order = TestUtils.createValidOrder();
            when(paymentService.processPayment(any())).thenReturn(successfulResult());
            // When
            final var result = orderProcessor.processOrder(order);
            // Then
            assertThat(result.isSuccessful()).isTrue();
            verify(paymentService).processPayment(order.getPayment());
        }

        @Test
        void nullOrderThrowsException() {
            assertThatThrownBy(() -> orderProcessor.processOrder(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Order cannot be null");
        }

        @ParameterizedTest
        @EnumSource(value = OrderStatus.class, names = {"CANCELLED", "EXPIRED", "REFUNDED"})
        void invalidStatusThrowsException(final OrderStatus status) {
            // Given
            final var order = TestUtils.createOrderWithStatus(status);
            // When/Then
            assertThatThrownBy(() -> orderProcessor.processOrder(order))
                .isInstanceOf(IllegalStateException.class);
        }
    }
}
```

### Test Utilities
- Create `TestUtils` classes for shared test data builders
- Use `assertThatThrownBy()` for exception testing — verify both type and message

---

## Comments

- Comment complex logic and non-obvious decisions, not what code does
- Javadoc on ALL public methods — include `@param`, `@return`, `@throws` as applicable
- Skip Javadoc on obvious getters/setters generated by Lombok
- TODO format: `// TODO: issue-link - description`

---

**Key Principles**: Modern Java idioms (records, sealed types, pattern matching), `final` everything, streams over loops, imports over FQCNs, specific exceptions with context, AssertJ tests, parameterized logging.
