---
description: Java formatting and style rules based on Google Java Style Guide — braces, indentation, whitespace, Javadoc format
author: Development Team
version: 3.1
tags: ["java", "formatting", "style", "google-style", "javadoc"]
reference: https://google.github.io/styleguide/javaguide.html
globs: ["**/*.java"]
---

# Java Formatting & Style Reference

Mechanical formatting rules enforced by checkstyle/IDE. Load this file only for style reviews or formatting questions. For coding standards and idioms, see `coding-style-java.steering.md`.

---

## Source File Basics

- Source files encoded in **UTF-8**, no tabs (ASCII space 0x20 only)
- File name matches top-level class name + `.java`
- Use escape sequences (`\b`, `\t`, `\n`, `\f`, `\r`, `\"`, `\'`, `\\`) over octal/Unicode escapes
- For non-ASCII: use actual Unicode char or `\uXXXX` based on readability

## Source File Structure (in order)

1. License/copyright (if present)
2. Package declaration (not line-wrapped)
3. Imports — no wildcards, not line-wrapped, ASCII sorted
   - Static imports (single group) → blank line → non-static imports (single group)
4. Exactly one top-level class

One blank line separates each section.

## Braces

- Always use braces with `if`, `else`, `for`, `do`, `while` — even for single statements
- K&R style: opening brace on same line, closing brace on own line
- Empty blocks may be concise (`void doNothing() {}`) except in multi-block statements

## Indentation

- Block: **+2 spaces**
- Continuation: at least **+4 spaces**

## Column Limit

- **100 characters** (exceptions: package/import, URLs in Javadoc, command lines in comments)

## Line-Wrapping

- Break at higher syntactic level
- Break **before** non-assignment operators (`.`, `::`, `&`, `|`)
- Break **after** assignment operators
- Method name stays attached to `(`
- Comma stays with preceding token

## Whitespace

### Vertical
- Single blank line between consecutive members
- Single blank line between statement groups for logical organization

### Horizontal
- Space after keywords (`if`, `for`, `catch`) before `(`
- Space before `{`
- Space on both sides of binary/ternary operators
- Space after `,`, `:`, `;`, closing `)` of cast
- Horizontal alignment never required

## Variable Declarations

- One variable per declaration (except `for` headers)
- Declare close to first use
- Array brackets on type: `String[] args` not `String args[]`

## Switch Formatting

- +2 indentation for switch contents
- Fall-through must be commented in old-style switches
- Switch expressions use arrow syntax

```java
return switch (list.size()) {
  case 0 -> "";
  case 1 -> list.getFirst();
  default -> String.join(", ", list);
};
```

## Annotations

- Type-use: immediately before annotated type (`final @Nullable String name`)
- Class: one per line
- Method: one per line (single parameterless may share line: `@Override public int hashCode()`)
- Field: multiple allowed on same line (`@Partial @Mock DataLoader loader`)

## Modifiers Order (JLS)

`public protected private abstract default static final sealed non-sealed transient volatile synchronized native strictfp`

## Numeric Literals

- Use uppercase `L` for longs (`3000000000L` not `3000000000l`)

## Text Blocks

- Opening `"""` on new line
- Closing `"""` on new line, same indentation as opening
- Content indented at least as much as delimiters

```java
String query = """
    SELECT id, name
    FROM users
    WHERE active = true
    """;
```

## TODO Comments

- `// TODO: issue-link - description` (all caps, with bug/issue reference)

## Javadoc Format

- `/** ... */` with aligned asterisks
- Single-line form OK when no block tags: `/** Returns the ID. */`
- Paragraphs separated by blank `*` line, subsequent paragraphs start with `<p>`
- Block tags in order: `@param`, `@return`, `@throws`, `@deprecated` — never empty
- Summary fragment: noun/verb phrase, capitalized, not "This method..." or "A {@code Foo}..."
- Required for public/protected members (skip obvious getters, overrides)

## Enum Formatting

```java
private enum Suit { CLUBS, HEARTS, SPADES, DIAMONDS }

private enum Answer {
  YES {
    @Override public String toString() { return "yes"; }
  },
  NO,
  MAYBE
}
```

## Block Comments

- Indented at same level as surrounding code
- Multi-line `/* */` has `*` aligned on subsequent lines

## Camel Case Conversion

1. Convert to plain ASCII, remove apostrophes
2. Split on spaces/punctuation
3. Lowercase all, then uppercase first char of each word (Upper) or all but first (lower)
4. Join: `"XML HTTP request"` → `XmlHttpRequest`

## Style Enforcement

```gradle
checkstyle {
    toolVersion = '10.3.4'
}
```
