```markdown
# one-step Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `one-step` Swift codebase. You'll learn how to structure files, write imports and exports, follow commit message conventions, and implement and test features according to the repository's standards. This guide is ideal for contributors aiming for consistency and maintainability in Swift projects without a specific framework.

## Coding Conventions

### File Naming
- Use **PascalCase** for all file names.

  **Example:**
  ```
  UserProfile.swift
  TaskManager.swift
  ```

### Import Style
- Use **relative imports** within the codebase.

  **Example:**
  ```swift
  import "../Models/UserProfile"
  import "../Utilities/Helpers"
  ```

### Export Style
- Use **named exports** for all public symbols.

  **Example:**
  ```swift
  public struct TaskManager {
      // ...
  }
  ```

### Commit Messages
- Use **conventional commit** format.
- Prefix feature additions with `feat`.
- Keep commit messages concise (average ~38 characters).

  **Example:**
  ```
  feat: add user authentication flow
  ```

## Workflows

### Feature Development
**Trigger:** When adding a new feature or module  
**Command:** `/feature-development`

1. Create a new Swift file using PascalCase naming.
2. Implement the feature using relative imports for dependencies.
3. Export public types or functions using named exports.
4. Write or update related test files (`*.test.*`).
5. Commit changes using the `feat:` prefix and a concise description.

### Testing
**Trigger:** When verifying code functionality  
**Command:** `/run-tests`

1. Locate or create test files matching the `*.test.*` pattern.
2. Write tests for new or modified code.
3. Run tests using the project's preferred test runner (framework unknown; refer to project documentation or use `swift test` if applicable).
4. Ensure all tests pass before merging.

## Testing Patterns

- Test files follow the `*.test.*` naming pattern (e.g., `UserProfile.test.swift`).
- The specific testing framework is not detected; follow Swift best practices or consult project maintainers.
- Place test files alongside or in a dedicated test directory as per project structure.

  **Example:**
  ```
  UserProfile.test.swift
  ```

## Commands
| Command              | Purpose                                      |
|----------------------|----------------------------------------------|
| /feature-development | Start a new feature with proper conventions  |
| /run-tests           | Run all tests in the codebase                |
```
