# Mermaid ERD

![License](https://img.shields.io/badge/license-MIT-green.svg)
![Gem](https://img.shields.io/gem/v/mermaid_erd.svg)
![Downloads](https://img.shields.io/gem/dt/mermaid_erd.svg)

Generate Mermaid-compatible Entity Relationship Diagrams (ERDs) from your Rails models, with support for excluding specific models. Designed for modern Rails apps that use Active Record.

## Why?

Keeping ER diagrams up to date is usually manual, and they quickly go stale.
This gem generates a diagram directly from your Rails models, so your
documentation always reflects the current domain model with almost no effort.

## Features

- Outputs a Mermaid `erDiagram` to `documentation/domain-model.md`
- Includes all Active Record models with a database table
- Excludes models listed in `config/mermaid_erd.yml` under `exclude`
- Visualises `belongs_to` associations
- Run via a Rake task (`rake erd:generate`)
- Adds a post-migration reminder in development

## Requirements

- Ruby 3.4+
- Rails 8+
- PostgreSQL (uses array/enum column support)

## Installation

Add this line to the development section of your Gemfile:

```ruby
  gem "mermaid_erd"
```

Then install:

```bash
bundle install
```

Alternatively, install it directly:

```bash
gem install mermaid_erd
```

## Usage

Run the following Rake task to generate the ERD:

```bash
bundle exec rake erd:generate
```

This will output a Mermaid diagram to:

```
documentation/domain-model.md
```

### Customization

You can customize which models to exclude by creating a file at:

```yaml
# config/mermaid_erd.yml

exclude:
  - ActiveStorage::*
  - SolidQueue::*
  - Blazer::*
```
You can limit to specific models:

```yaml
# config/mermaid_erd.yml

only:
  - Order
  - Customer
  - Product
```

### Post-Migration Reminder

To remind developers to regenerate the diagram after each migration, this gem automatically hooks into `db:migrate` and prints a message like:

```
[ℹ] If this migration added or modified database tables, consider:
    • Updating the Mermaid ER diagram: bundle exec rake erd:generate
    • Excluding models in: config/mermaid_erd.yml
```

> ⚠ This task only runs in the development environment.

## Output Example

Example output (`documentation/domain-model.md`):

```mermaid
erDiagram
  Saiyan {
    integer id
    string name
    enum rank
    integer power_level
    boolean tail
    datetime born_at
    datetime created_at
    datetime updated_at
  }

  Planet {
    integer id
    string name
    boolean destroyed
    datetime created_at
    datetime updated_at
  }

  Transformation {
    integer id
    integer saiyan_id
    enum form
    integer power_multiplier
    datetime achieved_at
    datetime created_at
    datetime updated_at
  }

  Battle {
    integer id
    string location
    enum outcome
    datetime started_at
    datetime finished_at
    datetime created_at
    datetime updated_at
  }

  BattleParticipation {
    integer id
    integer battle_id
    integer fighter_id
    enum fighter_type
    integer damage_dealt
    boolean defeated
    datetime created_at
    datetime updated_at
  }

  Sensei {
    integer id
    string name
    string technique_speciality
    datetime created_at
    datetime updated_at
  }

  TrainingSession {
    integer id
    integer saiyan_id
    integer sensei_id
    integer planet_id
    integer duration_days
    integer power_gained
    datetime started_at
    datetime finished_at
    datetime created_at
    datetime updated_at
  }

  Saiyan }o--|| Planet : belongs_to
  Transformation }o--|| Saiyan : belongs_to
  TrainingSession }o--|| Saiyan : belongs_to
  TrainingSession }o--|| Sensei : belongs_to
  TrainingSession }o--|| Planet : belongs_to
  BattleParticipation }o--|| Battle : belongs_to
  BattleParticipation }o--|| Saiyan : belongs_to
```
