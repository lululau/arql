# rename_columns Configuration Feature

## Problem

Some database tables have columns whose names conflict with ActiveRecord/ActiveModel built-in methods (e.g., `model_name`, `connection`, `type`). This causes `ActiveRecord::DangerousAttributeError` when arql tries to generate model classes for these tables. The existing `ignored_columns` config can suppress the error, but at the cost of losing all access to the column.

## Solution

Add a `rename_columns` configuration option that creates AR-level attribute aliases. The original column name is automatically added to `ignored_columns` to prevent conflicts, and a new accessible name is created via Rails' built-in `alias_attribute`.

## Configuration Format

```yaml
development:
  adapter: mysql2
  host: localhost
  database: myapp
  rename_columns:
    model_name: record_model_name
    type: biz_type
```

Key = original DB column name, Value = new alias name exposed on the model.

## Implementation Approach

**Chosen: `alias_attribute` + auto `ignored_columns`** (over manual `read_attribute`/`write_attribute` or column name hacking).

Rationale:
- Rails native mechanism, well-tested
- Query aliasing works automatically: `where(record_model_name: 'xxx')` translates to `WHERE model_name = 'xxx'`
- Minimal code changes

## Architecture

### Single file change: `lib/arql/definition.rb`

1. **New method: `rename_columns_mapping`**
   - Returns `options[:rename_columns] || {}`
   - Follows the pattern of existing `model_names_mapping` (line 95)

2. **New method: `validate_rename_columns!`**
   - Called per-table after model class creation
   - Three-layer conflict detection (see below)

3. **Modified method: `make_model_class`** (line 150)
   - Inside the `Class.new` block, after `ignored_columns` handling (line 161):
     - Merge renamed original column names into `ignored_columns`
     - Call `alias_attribute` for each rename mapping that belongs to this table

4. **Modified method: `define_model_from_table`** (line 99)
   - After model class creation, call `validate_rename_columns!`

### Data Flow

```
YAML config (rename_columns: { model_name: record_model_name })
  → options hash passed to Definition#initialize
  → Definition#make_model_class reads options[:rename_columns]
  → filters mappings for current table's columns
  → original names added to ignored_columns
  → alias_attribute called for each mapping
  → validate_rename_columns! checks for conflicts
```

### Conflict Detection (at startup)

| Check                 | Rule                                                                 | On failure          |
| --------------------- | -------------------------------------------------------------------- | ------------------- |
| Column name conflict  | New name must not match any other existing column in the same table   | `warn`, skip mapping |
| AR reserved name      | New name must not be in `ActiveRecord::AttributeMethods.dangerous_attribute_methods` | `raise`, abort startup |
| arql method name      | New name must not be an arql Extension instance method                | `warn`, skip mapping |

arql Extension instance methods to check: `v`, `t`, `vd`, `to_insert_sql`, `to_upsert_sql`, `to_create_sql`, `dump`, `write_csv`, `write_excel`.

**Why `raise` for AR reserved names**: These cause unpredictable behavior and silent data corruption. Column name and arql method conflicts are less severe and can be skipped gracefully.

## Edge Cases

| Scenario                                                        | Behavior                   |
| --------------------------------------------------------------- | -------------------------- |
| Original column name in `rename_columns` doesn't exist in table | `warn`, skip mapping        |
| Same original column renamed twice in config (config error)     | Last one wins, `warn`      |
| `rename_columns` and `ignored_columns` specify the same column  | Merged and deduplicated    |
| `rename_columns` shared across environments via YAML anchor     | Works, validated per-env   |
| `redefine` Pry command used                                     | Works (re-runs full flow)  |

## What's NOT Affected

- **DB layer**: No database changes, pure AR mapping
- **`t`/`v`/`vd` output**: Displays original column names (correct, since DB is unchanged)
- **SQL logs**: `where(record_model_name: 'xxx')` shows `WHERE model_name = 'xxx'` in logs
- **`redefine` command**: Automatically supported (calls `define_model_from_table`)
- **Existing `ignored_columns`**: Fully compatible, merged at runtime

## Example Usage

Before (fails):
```
ARQL@dev(main) [1] ❯ AGH.last
ActiveRecord::DangerousAttributeError: model_name is defined by Active Record
```

After (with config):
```yaml
rename_columns:
  model_name: record_model_name
```

```
ARQL@dev(main) [1] ❯ AGH.last.record_model_name
=> "SomeModel"
ARQL@dev(main) [2] ❯ AGH.where(record_model_name: "SomeModel").count
=> 5
```
