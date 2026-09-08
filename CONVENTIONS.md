# ZigDungeon Conventions

## Import Ordering and Regions

Zig source files that contain imports group them at the top of the file with
two named regions:

```zig
// #region Namespace imports
// Namespace imports: std and project modules kept under their namespace.
// #endregion

// #region Concrete imports
// Concrete types, functions, and values extracted from namespaces or modules.
// #endregion
```

Follow these rules:

1. Put `std` first in the namespace imports region when it is used.
2. The local name determines the import region: every import whose local name
   is entirely lowercase belongs in `Namespace imports`, including names with
   underscores such as `world_module` or `project_settings`. This remains true
   when the import expression selects a member, such as `.raylib` or
   `.randomizer`.
3. Imports whose local name uses PascalCase belong in `Concrete imports`.
4. Order the namespace imports from generic to specific: `std` and its
   aliases first, then libraries, then vendors, then engine modules, then
   project-local namespaces.
5. Within the project-local namespaces, order imports by increasing path
   depth. Keep the existing order for imports at the same depth.
6. Keep the import regions contiguous at the top of the file. Leave one blank
   line between the regions and one blank line after the second region.
7. Keep local declarations such as `@This()` types and error sets outside the
   import regions, immediately after them.
8. Do not create an empty concrete-import region when the file has no concrete
   imports.

Use `// #endregion` to close each region. Region names are part of the
convention and should remain exactly `Namespace imports` and `Concrete
imports`.
