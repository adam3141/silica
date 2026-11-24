# Coding Style Guide

This guide sets the C++ conventions for the projects in this workspace. It is written to work with the `.clang-format` and `.clang-tidy` files at the repository root.

Where a tool enforces a rule, the rule is tagged **Enforced:** and names the check. Rules without a tag are enforced in code review.

## Contents

1. [Scope and authority](#1-scope-and-authority)
2. [Toolchain and build](#2-toolchain-and-build)
3. [Formatting](#3-formatting)
4. [Naming](#4-naming)
5. [Files and headers](#5-files-and-headers)
6. [Declarations and types](#6-declarations-and-types)
7. [Classes](#7-classes)
8. [Interfaces](#8-interfaces)
9. [Functions](#9-functions)
10. [Control flow](#10-control-flow)
11. [Expressions and conversions](#11-expressions-and-conversions)
12. [Memory and resources](#12-memory-and-resources)
13. [Error handling](#13-error-handling)
14. [Templates and concepts](#14-templates-and-concepts)
15. [Library and language features](#15-library-and-language-features)
16. [Preprocessor and macros](#16-preprocessor-and-macros)
17. [Comments and documentation](#17-comments-and-documentation)
18. [Concurrency](#18-concurrency)
19. [Testing](#19-testing)
20. [Tooling and workflow](#20-tooling-and-workflow)
21. [Review checklist](#21-review-checklist)

---

## 1. Scope and authority

- This guide applies to all C++ in the workspace, including tests and tools.
- `.clang-format` and `.clang-tidy` are the source of truth for every rule they enforce. If a rule here and a config disagree, change both in the same change. Do not work around one.
- Layout is normally not a review topic. Run clang-format and accept its output.
- clang-format sometimes produces poor layout. When it does, reviewers may ask for a change, and the author first restructures the code so the formatter handles it well. If that is not practical, wrap the affected code in `// clang-format off` and `// clang-format on`, with a comment explaining why.
- Code that passes clang-format and clang-tidy can still break a rule that only review can check. Fix it in review.
- Minimum tool versions: clang-format 18 and clang-tidy 19. Older clang-tidy releases lack `misc-use-internal-linkage`, which this guide relies on. The configs were tested with clang-format and clang-tidy 23.

## 2. Toolchain and build

- Language standard is **C++26**, built with **GCC 16** and `-freflection` for static reflection (flint ADR-0001). Do not use compiler extensions (`__attribute__`, GNU statement expressions, variable-length arrays).
- Reflection syntax (`^^`, `[: :]`, `template for`, `<meta>`) appears only in `meta/detail/*_impl.hpp` headers, so clangd and clang-tidy, which do not yet implement reflection, work everywhere else. See flint ADR-0003.
- Build with warnings enabled and treated as errors:
  - GCC and Clang: `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Werror`
  - MSVC: `/W4 /permissive- /WX`
- Export the compilation database so clang-tidy sees the real flags: configure with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`.
- Prefer the standard library. Add a third-party dependency only when it is needed and maintained, and record the reason in the pull request.

## 3. Formatting

clang-format owns all layout. The rules below are listed for reference; the configuration is authoritative.

| Topic | Rule |
|---|---|
| Indentation | 2 spaces. Never tabs. |
| Line length | 140 columns maximum. |
| Braces | Opening brace on the same line as the statement, class, or function. |
| Control statements | Always use braces, even for a single statement. |
| Pointers and references | Attach the symbol to the type: `int* p`, `const Size& size`. |
| Qualifiers | Qualifier before the type: `const int`, not `int const`. |
| Access specifiers | At the class indentation level, members indented one step. |
| Namespaces | Contents are not indented. |
| Wrapped parameters or arguments | Either all on one line, or one per line. |
| Function definitions | Separated by a blank line. |
| Blank lines | At most one in a row. None directly after an opening brace. |
| Empty bodies | Written `{}`, with no space inside. |
| Trailing whitespace | None. Every file ends with a newline. |

```cpp
namespace opal {

class Button {
public:
  explicit Button(std::string label);

  [[nodiscard]] auto GetLabel() const noexcept -> const std::string& { return m_label; }

  auto CalculateCentre(const Size& size) -> void;

private:
  std::string m_label;
  int m_clickCount{0};
};

}  // namespace opal
```

### Include order

Includes are grouped and sorted by clang-format. Separate groups with one blank line:

1. The file's own header (for `button.cpp`, `button.hpp` comes first).
2. Standard library, `<vector>` style.
3. Third-party, with a path, `<gtest/gtest.h>` style.
4. Project headers, `"geometry/Size.hpp"` style.

**Enforced:** clang-format (`IncludeBlocks: Regroup`, `SortIncludes`).

### Disabling formatting

`// clang-format off` and `// clang-format on` are allowed where clang-format produces poor layout, including data tables where alignment carries meaning. Each use needs a comment explaining why it is necessary.

## 4. Naming

The case rules below are enforced by `readability-identifier-naming`.

| Entity | Case | Example |
|---|---|---|
| Namespace | `lower_case`, a single word | `opal`, `detail` |
| Class, struct, union | `PascalCase` | `Button`, `Point` |
| Enum and its enumerators | `PascalCase` | `enum class MouseButtonState { Released, Pressed };` |
| Type alias | `PascalCase` | `using StringVector = std::vector<std::string>;` |
| Template parameter | `PascalCase` | `template <typename Value>` |
| Concept | `PascalCase` | `concept Drawable = ...;` |
| Function and method | `PascalCase` | `CalculateCentre()` |
| Parameter and local variable | `camelCase` | `tooltipFadeTime` |
| Private or protected data member | `m_` + `camelCase` | `m_clickCount` |
| Public data member of a struct | `camelCase` | `point.xPos` |
| `constexpr` variable (any scope) | `k` + `PascalCase` | `kTooltipFadeTime` |
| `const` constant at namespace, class, or static scope | `k` + `PascalCase` | `kMaxRetries` |
| Macro | `UPPER_SNAKE_CASE`, prefixed with the library name | `FLINT_PROFILE_ZONE`, `AGATE_ASSERT`, `OPAL_ASSERT` |
| File | `lower_snake_case` | `button.hpp`, `button.cpp` |

Rules beyond casing (reviewed):

- Names describe purpose. `retryCount`, not `n`. Short names are fine for loop indices and small mathematical expressions (`i`, `x`, `y`).
- Treat acronyms as words: `HttpClient`, `JsonParser`, `userId`.
- Use **British English** spelling in every identifier, configuration key and markup name: `Colour`, `Centre`, `Grey`, `Behaviour`, `Serialise`, `Initialise`. agate's C++ names become markup names through reflection, so spelling is public API (workspace ADR-0005).
- No Hungarian notation or type prefixes. The `m_` prefix (members) and the `k` prefix (constants) are the only prefixes.
- Namespaces are a single lowercase word. Do not use underscores or multiple words, such as `opal_ui`. Nested namespaces are each a single word, for example `opal::detail`.
- Boolean variables read as a question: `isVisible`, `hasFocus`.
- Boolean functions start with `Is`, `Has`, or `Can`, depending on what reads best: `IsVisible()`, `HasFocus()`, `CanClose()`.
- Getters start with `Get` and setters with `Set`: `GetLabel()`, `SetLabel()`.
- Never declare identifiers that begin with an underscore, or that contain a double underscore. They are reserved.
- Do not reuse a name in an inner scope. The `-Wshadow` warning is an error.

## 5. Files and headers

- Each header declares one main type, and its name matches that type (`button.hpp` declares `Button`). Small types that exist only to support the main type, such as its enums or option structs, may live in the same header. Helpers used by only one `.cpp` go in an anonymous namespace in that file.
- Headers use `.hpp`. Implementation files use `.cpp`.
- Every header starts with `#pragma once`. Do not use include guards.

  ```cpp
  #pragma once

  // ...
  ```

- Every header is self-contained: it compiles on its own, with no includes required from the includer. CI compiles each header in isolation.
- Include what you use. Include the header that declares each name the file uses. **Enforced:** `misc-include-cleaner`.
- Forward-declare in headers when a pointer or reference is enough. This reduces compile time and coupling.
- Never write `using namespace` in a header. Never write `using namespace std;` anywhere. Clang's `-Wheader-hygiene` flags the header case; the rest is review.
- Use fixed-width integer types from `<cstdint>` when the size matters: `std::uint32_t`, not `unsigned long`.

## 6. Declarations and types

- Variables and parameters are `const` unless they change. **Enforced:** `misc-const-correctness`.
- Initialize every variable where it is declared. **Enforced:** `cppcoreguidelines-init-variables`.
- Use `auto` when the type is obvious from the initializer or is long to write: iterators, lambdas, and chrono literals such as `auto tooltipFadeTime = std::chrono::milliseconds{100};`. Spell the type out when it hides meaning or changes conversions.
- Represent time, distance, and other units with a type, not a bare `int`. e.g. Use `std::chrono` for durations.
- Use `enum class`. Specify an underlying type when the enum is stored, serialized, or part of a binary interface, for example `enum class Level : std::uint8_t`.
- Use `nullptr`, never `NULL` or `0`, for pointers. **Enforced:** `modernize-use-nullptr`.
- Use `using`, not `typedef`. **Enforced:** `modernize-use-using`.
- Mark overrides with `override`. Mark classes that must not be derived from with `final`. **Enforced:** `modernize-use-override`.
- Mark functions whose result must not be ignored (queries, factories, status results) with `[[nodiscard]]`. **Enforced:** `modernize-use-nodiscard`.
- Mark single-argument constructors and conversion operators `explicit`. **Enforced:** `google-explicit-constructor`.
- Declare every function with a trailing return type: `auto CalculateAge() -> std::uint16_t;`. Constructors and destructors have no return type and are not affected. **Enforced:** `modernize-use-trailing-return-type`.
- Prefer `constexpr` for values known at compile time. Use `consteval` only when the function must run at compile time.
- One declaration per line. Declare a variable close to its first use.
- Use `static_assert` to record assumptions about types and sizes.

## 7. Classes

- **Rule of zero:** a class that owns no resources declares no special member functions. Let the compiler generate them.
- **Rule of five:** if a class declares any of the destructor, copy constructor, copy assignment, move constructor, or move assignment, it declares or explicitly defaults or deletes all five. **Enforced:** `cppcoreguidelines-special-member-functions`.
- Data members are private, unless the type is a plain aggregate with no invariants (use a `struct` for that). Private and protected data members use the `m_` prefix. Each data member has a default member initializer. **Enforced:** `cppcoreguidelines-pro-type-member-init`, `misc-non-private-member-variables-in-classes`.
- Polymorphic base classes have a `virtual` destructor, or a `protected` non-virtual one. **Enforced:** `cppcoreguidelines-virtual-class-destructor`.
- Member functions that do not change the object are `const`. **Enforced:** `readability-make-member-function-const`.
- Move operations are `noexcept`. **Enforced:** `cppcoreguidelines-noexcept-move-operations`.
- Prefer composition to inheritance. Use inheritance for a true is-a relationship with an [interface](#8-interfaces).
- Do not use multiple inheritance of implementation, except for policy classes (below). Several interfaces may be inherited together.
- **Policy classes** are named with a `Policy` suffix, such as `RetryPolicy` or `LoggingPolicy`. A host class inherits from one or more policies to combine their behaviour at compile time. Policy classes:
  - have no virtual functions and no public data members. They are never used as runtime polymorphic types.
  - hold no data members where possible, so that they add no size to the host.
  - are inherited privately, unless the policy's interface is part of the host's public interface.
  - must be justified in the pull request, because multiple inheritance is reviewed closely.

  ```cpp
  class LoggingPolicy {
  protected:
    static auto Log(std::string_view message) -> void;
  };

  class RetryPolicy {
  protected:
    static constexpr auto kMaxAttempts = 3;
  };

  class HttpClient final : private LoggingPolicy, private RetryPolicy {
  public:
    auto Send(const Request& request) -> std::expected<Response, HttpError>;
  };
  ```

- Do not call virtual functions from constructors or destructors.
- Use `struct` for plain data with no invariants. Use `class` when the type maintains invariants.
- Order members: nested types and constants, constructors and destructor, public functions, protected functions, private functions, data members.
- Use `friend` only for types that are tightly coupled by design.

## 8. Interfaces

An interface is an abstract class that defines behaviour for runtime polymorphism. Its name ends with the `Interface` suffix, such as `ClockInterface`, so the role it defines is clear from the name.

- An interface has a virtual destructor, pure virtual functions, and nothing else. It has no data members and no non-virtual member functions. **Enforced:** `cppcoreguidelines-virtual-class-destructor`.
- Give the destructor a body of `= default`.
- Interfaces are not copied or moved by value. Hold implementations through `std::unique_ptr` or a reference.
- An implementation inherits publicly from the interface, marks every override `override`, and is marked `final` unless it is designed to be derived from. **Enforced:** `modernize-use-override`.
- A class may implement several interfaces. Multiple inheritance of interfaces is allowed. No implementation is inherited from them.
- Depend on interfaces, not implementations, in parameters and members: `auto Run(const ClockInterface& clock) -> void;`.
- Keep an interface focused on one role. Do not add a pure virtual function to a published interface, because every implementation breaks. Create a new interface instead.
- Use an interface when the substitution is needed at run time, such as for plugins or test doubles. If the choice is only needed at compile time, use a policy class or a template constrained by a concept instead.

```cpp
class ClockInterface {
public:
  virtual ~ClockInterface() = default;

  [[nodiscard]] virtual auto Now() const -> std::chrono::steady_clock::time_point = 0;
  virtual auto Sleep(std::chrono::milliseconds duration) -> void = 0;
};

class SystemClock final : public ClockInterface {
public:
  [[nodiscard]] auto Now() const -> std::chrono::steady_clock::time_point override;
  auto Sleep(std::chrono::milliseconds duration) -> void override;
};
```

## 9. Functions

- A function does one thing. If it needs a comment to explain its sections, split it.
- Parameter passing:
  - Read-only and non-trivial: `const T&`. Use `std::string_view` or `std::span` for non-owning views.
  - Cheap to copy (scalars, small value types): by value.
  - Stored or moved into the object: by value, then `std::move` it into the member, or provide `T&&` overloads.
  - Results: never through non-const reference parameters. Return a value, a struct, or a `std::expected` (see [Error handling](#13-error-handling)).
  **Enforced:** `performance-unnecessary-value-param`.
- Keep parameter lists short, about five at most. Group related parameters into a struct.
- Default arguments are for values most callers use. Do not use `bool` flags to select behaviour; use an `enum class`.
- Name literal arguments at the call site: `Resize(/*width=*/640, /*height=*/480);`. **Enforced:** `bugprone-argument-comment`.
- Overloads do the same kind of thing. Do not use overloading to change meaning.
- Lambdas capture explicitly. Do not use `[=]` with `this` (deprecated in C++20). Use `[&]` only for lambdas that do not outlive the enclosing scope.
- Helpers that are not part of the interface are `static` or in an anonymous namespace. **Enforced:** `misc-use-internal-linkage`.

## 10. Control flow

- Always use braces on control statements. **Enforced:** `readability-braces-around-statements`.
- Return early to reduce nesting. Do not write `else` after a `return`. **Enforced:** `readability-else-after-return`.
- Compare non-`bool` types explicitly: `if (ptr != nullptr)`, not `if (ptr)`. **Enforced:** `readability-implicit-bool-conversion`.
- Test containers with `empty()`, not `size() == 0`. **Enforced:** `readability-container-size-empty`.
- Do not assign inside a condition. **Enforced:** `bugprone-assignment-in-if-condition`.
- `switch` on an `enum class` lists every enumerator and has no `default`, so the compiler warns when a new value is added. `default` is for other types.
- Every `case` ends with `break`, `return`, or `throw`. A deliberate fall-through is marked `[[fallthrough]];`. **Enforced:** `-Wimplicit-fallthrough` (compiler).
- Do not use `goto`. **Enforced:** `cppcoreguidelines-avoid-goto`.
- Iterate containers with range-based `for`, not index loops. **Enforced:** `modernize-loop-convert`.
- Use `<algorithm>` and `<ranges>` for find, transform, and count operations, rather than hand-written loops.

## 11. Expressions and conversions

- No implicit narrowing. Convert explicitly with `static_cast`. Brace initialization rejects narrowing. **Enforced:** `bugprone-narrowing-conversions`.
- No C-style casts. **Enforced:** `cppcoreguidelines-pro-type-cstyle-cast`.
- `reinterpret_cast` is used only where unavoidable, such as platform APIs, and has a comment explaining why. **Enforced:** `cppcoreguidelines-pro-type-reinterpret-cast`.
- Sizes and indices are `std::size_t`. Do not compare signed and unsigned values. **Enforced:** `-Wsign-compare` (compiler).
- Name numeric literals that carry meaning. Use `0`, `1`, `-1`, and `2` for halving or doubling freely. Other literals become named constants.
- Do not compare floating-point values with `==`, except against exact sentinel values. Use a tolerance helper.
- Parenthesize mixed `&&`/`||` and mixed bitwise and arithmetic operators. **Enforced:** `-Wparentheses` (compiler).
- Do not rely on evaluation order between operands. Do not put two side effects in one expression.
- Signed integer overflow is undefined behaviour. Check or widen arithmetic on values from outside the program.

## 12. Memory and resources

- No raw `new` or `delete` in application code. Use `std::make_unique`, `std::make_shared`, or a container. **Enforced:** `cppcoreguidelines-owning-memory`, `cppcoreguidelines-no-malloc`.
- Ownership is visible in the type:
  - `std::unique_ptr<T>` for exclusive ownership.
  - `T*` or `T&` for a non-owning reference.
  - `std::shared_ptr<T>` only when ownership is genuinely shared. It is not the default.
- Fixed-size arrays use `std::array`. Dynamic arrays use `std::vector`. **Enforced:** `modernize-avoid-c-arrays`.
- Non-owning views of contiguous data use `std::span`, or `std::string_view` for text.
- Every resource (file, socket, lock, handle) is owned by an object whose destructor releases it (RAII).
- No pointer arithmetic. Use iterators or indices. **Enforced:** `cppcoreguidelines-pro-bounds-pointer-arithmetic`.
- Never return or store a pointer or reference to a temporary, or to an element of a container that may reallocate.

## 13. Error handling

Failure is part of normal operation, so it is reported in the type system, not by throwing.

### Returning failure

- Every function that can fail returns `std::expected<T, E>` from `<expected>`. This includes file I/O, parsing, network calls, validation, and lookups that can fail for a reason.
- Do not signal failure with a sentinel value, a `bool`, an out-parameter, or a thrown exception.
- `E` is a project error type: an `enum class` for a fixed set of causes, or a struct when the caller needs context such as a path, offset, or code. Do not use strings as error values.
- Report failure with `std::unexpected(error)`.
- Chain fallible calls with `and_then`, `transform`, and `or_else`. Test with `has_value()` before using the value. Do not call `value()` on an unchecked result, because it throws `std::bad_expected_access`.
- Use `std::optional<T>` only for a lookup whose only failure is "not found", where no reason is useful to the caller.
- Mark functions returning `std::expected` with `[[nodiscard]]`, so a result cannot be silently dropped.

```cpp
#include <expected>
#include <string>
#include <string_view>

enum class ConfigError {
  Malformed,
  TooLarge,
};

// Adapter around a third-party parser that throws on malformed input.
auto ParseConfig(std::string_view text) -> std::expected<Config, ConfigError> {
  if (text.size() > kMaxConfigBytes) {
    return std::unexpected(ConfigError::TooLarge);
  }
  try {
    return Config{thirdparty::Parse(text)};
  } catch (const thirdparty::ParseError&) {
    return std::unexpected(ConfigError::Malformed);
  }
}
```

### When exceptions are allowed

Exceptions are for truly exceptional circumstances: conditions that are not part of normal operation and cannot be reported through a return value. Examples are `std::bad_alloc` and a failure of a required system resource at startup. No tool checks this rule; it is enforced in code review.

- Expected failures never throw. Invalid input, a missing file, a parse error, a timeout, and a denied permission all return `std::expected`.
- Programmer errors (broken invariants) are assertions, not exceptions. Assertions are never used to validate input.
- Do not use exceptions for ordinary control flow.
- Do not catch truly exceptional exceptions to convert them. Let them propagate to a top-level handler.
- Throw by value and catch by `const&`.

### Library code that throws

The standard library and third-party libraries sometimes throw for failures that are not truly exceptional. Such exceptions are caught and converted to `std::expected`.

- Catch at an adapter boundary, one per library. Callers of the adapter never see the library's exception.
- Convert the exception to the project error type. Do not let the library's exception type leak into the interface.
- Prefer non-throwing overloads where they exist. Use `std::from_chars` rather than `std::stoi`, and the `std::error_code` overloads of `std::filesystem` functions rather than the throwing ones.

```cpp
#include <charconv>
#include <expected>
#include <filesystem>
#include <string_view>
#include <system_error>

enum class ParseError {
  NotANumber,
  OutOfRange,
};

// Non-throwing overload: no try/catch needed.
auto ParseInt(std::string_view text) -> std::expected<int, ParseError> {
  int value{};
  const auto [end, ec] = std::from_chars(text.data(), text.data() + text.size(), value);
  if (ec == std::errc::result_out_of_range) {
    return std::unexpected(ParseError::OutOfRange);
  }
  if (ec != std::errc{} || end != text.data() + text.size()) {
    return std::unexpected(ParseError::NotANumber);
  }
  return value;
}

// Throwing library: catch at the adapter and convert.
auto FileExists(const std::filesystem::path& path) -> std::expected<bool, std::error_code> {
  std::error_code ec;
  const bool exists = std::filesystem::exists(path, ec);
  if (ec) {
    return std::unexpected(ec);
  }
  return exists;
}
```

### Other rules

- Never swallow an exception. An empty `catch` block is not allowed. **Enforced:** `bugprone-empty-catch`.
- Destructors, move operations, and `swap` do not throw. **Enforced:** `cppcoreguidelines-noexcept-move-operations` for move operations.
- Validate all external input (files, network, user input) at the boundary, and return `std::expected` from there.
- Error values say what failed and which identifier or value was involved.

## 14. Templates and concepts

- Constrain templates with concepts: `template <std::integral Value>`, not an unconstrained `typename` where a concept applies.
- Prefer overloads, concepts, and `if constexpr` to SFINAE.
- Define templates in headers. Hide implementation details in a `detail` namespace.
- Avoid template metaprogramming unless it makes the call site simpler.
- Name template parameters for what they represent.

## 15. Library and language features

Prefer:

- `std::string_view` and `std::span` for non-owning parameters.
- `std::expected` for fallible results, and `std::optional` for lookups where only "not found" can happen (see [Error handling](#13-error-handling)).
- Structured bindings for pairs, tuples, and structs: `auto [key, value] = ...;`
- `std::chrono` for time.
- `std::jthread` for threads (see [Concurrency](#18-concurrency)).
- Algorithms and ranges (`std::ranges::`) when the toolchain supports them.
- `std::format` and `std::println` (C++23) for formatting and output.

Avoid:

- `std::bind`. Use lambdas.
- `std::auto_ptr`, `std::random_shuffle`, and other removed or deprecated facilities.
- The C stdio family (`printf`, `sprintf`) in C++ code. Use `std::format` or `std::ostream`.
- `volatile` for synchronization. Use `std::atomic`.
- `setjmp` and `longjmp`.

## 16. Preprocessor and macros

- Prefer `constexpr` variables, `inline` functions, and templates to macros. **Enforced:** `cppcoreguidelines-macro-usage`.
- Any macro that cannot be avoided is named with its library's prefix (`FLINT_`, `AGATE_`, `OPAL_`) followed by an `UPPER_SNAKE_CASE` name.
- Conditional compilation (`#if`) is confined to a small number of platform or configuration headers.
- `#include` appears only at file scope.

## 17. Comments and documentation

- Comments explain *why*, or what is not obvious from the code. They do not restate the code.
- Document every public declaration in a header with `///`. Include a summary line, and `@param`, `@return`, and `@throws` where they apply:

  ```cpp
  /// Returns the centre of the button relative to its parent.
  /// @param size The size of the parent container.
  /// @return The centre point, in parent coordinates.
  [[nodiscard]] auto CalculateCentre(const Size& size) const -> Point;
  ```

- Do not commit commented-out code. Version control keeps the history.
- `TODO` comments name an owner and reference a tracked item: `// TODO(name): describe the work (tracking reference)`.
- When you change code, update the comments that describe it.

## 18. Concurrency

- Prefer immutable data and message passing over shared mutable state.
- Where data must be shared and mutable, protect it with a mutex. Document, next to the mutex, what it protects.
- Lock with RAII only: `std::scoped_lock` or `std::lock_guard`. Never call `lock()` or `unlock()` directly.
- Use `std::jthread`, which joins on destruction. Do not leave threads detached.
- Do not call callbacks or unknown code while holding a lock.
- Use `std::atomic` for simple flags and counters. Specify a memory order explicitly when the default is not the one you need.
- **Enforced:** the `concurrency-*` checks.

## 19. Testing

- Every bug fix ships with a regression test that fails before the fix.
- Tests are deterministic. Do not synchronize with sleeps. Do not depend on wall-clock time or on test execution order.
- Test names describe behaviour, for example `ButtonTest.ReportsClickCountAfterRelease`.
- Test through the public interface. Do not test private members.
- Test code follows this guide and passes the same clang-format and clang-tidy checks as production code, except for the checks disabled, with reasons, in each library's `tests/.clang-tidy`.

## 20. Tooling and workflow

Run from the silica root, with a build directory that contains `compile_commands.json` (for example `build/debug` after `cmake --preset debug`):

```bash
# Format files in place
clang-format -i path/to/file.cpp path/to/file.hpp

# Check formatting without modifying files (used in CI)
clang-format --dry-run --Werror path/to/file.cpp

# Lint with the repository configuration (tools/tidy.sh adds the flags a GCC compile database needs under clang)
tools/tidy.sh build/debug 'flint/src/.*'

# Lint in CI: every warning fails the build
tools/tidy.sh build/debug '(flint|agate)/.*\.cpp' -warnings-as-errors='*'
```

### Suppressions

Fixing the code is always preferred to suppressing a warning. When a suppression is genuinely necessary:

- Suppress one named check, on one line, with a reason:

  ```cpp
  // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): the Win32 API requires this cast
  ```

- A bare `NOLINT` with no check name is not allowed.
- A reviewer must accept every suppression in a pull request.

### Changing the guide

- Propose rule changes in a pull request that updates this guide and, where relevant, `.clang-format` and `.clang-tidy` together.
- Disabling a clang-tidy check requires a comment in `.clang-tidy` stating why.

## 21. Review checklist

Reviewers check the following. The tools cover the rest.

- [ ] Names follow [Naming](#4-naming), including meaning and not only case.
- [ ] Variables and parameters are `const` where possible, and initialized where declared.
- [ ] Ownership is clear from the types. No raw `new` or `delete`.
- [ ] Fallible functions return `std::expected`. Exceptions appear only for truly exceptional failures, and library exceptions are converted at an adapter.
- [ ] Headers are self-contained, start with `#pragma once`, and include what they use.
- [ ] Functions do one thing, and parameter passing follows [Functions](#9-functions).
- [ ] Non-obvious values are named constants, not literals.
- [ ] Shared mutable state is protected, and locks are RAII.
- [ ] Every public declaration has a `///` comment. Non-obvious code has a *why* comment.
- [ ] Every bug fix has a regression test.
- [ ] Every suppression names a check and gives a reason.
