# Hit the Deck Manager Architecture

## Purpose

Hit the Deck Manager is a cross-platform inventory management application for Hit the Deck Sports. It manages the lifecycle of baseball equipment from acquisition through sale while preserving the accounting relationships created by repairs, trade-ins, Deals, disposals, warranty replacements, consignments, and contacts.

The application is designed primarily for Android and iOS. Desktop builds are also used during development and testing.

---

## Technology Stack

| Component | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Planned Backend | Firebase / Cloud Firestore |
| Planned Authentication | Firebase Authentication |
| Planned Image Storage | Firebase Storage |

Firebase integration belongs to the next implementation phase. Phase 2 intentionally uses repository interfaces with in-memory implementations so application/domain behavior can be completed and tested before persistence is introduced.

---

## Architectural Principles

The project favors:

- Readability over clever code
- Simple, explicit domain rules
- Feature-first organization
- Repository abstraction between application logic and persistence
- Riverpod providers as dependency-injection and state boundaries
- GoRouter route names/paths centralized in the app layer
- Small reusable presentation components
- Testable workflows with rollback behavior for multi-record operations
- Historical accounting snapshots on completed transactions
- Minimal coupling between unrelated features

---

## Project Structure

```text
lib/
  app/
    app.dart
    app_router.dart
    app_routes.dart
    app_shell.dart

  core/
    config/
    errors/
    formatting/
    validation/

  features/
    contacts/
      data/
      domain/
      presentation/

    inventory/
      data/
      domain/
      presentation/

    transactions/
      data/
      domain/
      presentation/

    dashboard/
    reports/
    settings/

  shared/
    presentation/
```

A feature may contain `data`, `domain`, and `presentation` layers as needed.

---

## Layer Conventions

### Domain

Domain code contains business models, repository contracts, and domain services. Domain classes do not depend on Flutter widgets.

Examples include:

- `InventoryItem`
- `SaleTransaction`
- `RepairTransaction`
- `TradeTransaction`
- `DisposalTransaction`
- `ConsignmentTransaction`
- `Deal`
- `WarrantyReplacementDeal`

### Data

The data layer implements repository contracts.

Phase 2 uses in-memory repositories. Firebase-backed repositories will replace or sit behind the same contracts in the persistence phase.

### Presentation

Presentation code contains screens, forms, widgets, Riverpod providers/controllers, and navigation actions.

Controllers coordinate multi-step workflows and are responsible for keeping related repository changes consistent. When a workflow creates multiple records, rollback behavior is used where practical so a partial failure does not silently leave inconsistent application state.

---

## Provider Conventions

- Repository providers expose repository interfaces.
- Stream providers expose changing collections such as inventory and transaction history.
- Family providers retrieve individual records or records linked to an inventory item.
- Notifier/AsyncNotifier controllers own user-initiated workflows.
- Screens invalidate affected providers after successful mutations.
- Business calculations should live on domain models/services when they are reusable outside one widget.

---

## Repository Conventions

Repository interfaces define the persistence boundary.

Current repository-backed areas include:

- Inventory
- Contacts
- Sales
- Repairs
- Trade-ins
- Disposals
- Consignments
- Deals
- Warranty Replacement Deals

In-memory implementations are the Phase 2 reference behavior and are covered by repository tests.

---

## Core Workflow Rules

### Inventory

Inventory is represented by `InventoryItem`. Required domain values include category, brand, acquisition type, and acquisition value.

Inventory status includes:

- Available
- Sold
- Inactive
- Broken
- Disposed

Inventory numbers are generated after save using the category/date sequence convention.

### Sales

A completed sale:

- records a `SaleTransaction`
- marks the inventory item Sold
- snapshots the sale cost basis
- may create incoming trade-in inventory
- may create a `TradeTransaction`
- may create a one-level `Deal`

### Trade-ins and Deals

Trade-ins are recorded as part of the sale workflow rather than as a separate user-facing standalone trade workflow.

A sale with incoming trade-in inventory automatically creates a one-level Deal. Deal reporting rolls child inventory results back to the parent sale relationship.

### Repairs

Repairs are independent transaction records linked to inventory and preserve repair date, description, and cost.

### Disposals

A disposal:

- records reason/date/notes
- changes inventory status to Disposed
- remains visible in inventory and transaction history

Warranty Replacement disposals may create replacement inventory and a dedicated Warranty Replacement Deal relationship.

### Warranty Replacement

Replacement inventory carries forward the disposed item's economic cost basis instead of being treated as zero-cost inventory.

Warranty Replacement Deal records are intentionally separate from Sale Deal profit calculations.

### Consignment

A consignment agreement records Hit the Deck's agreed commission.

When consigned inventory sells:

- the Sale records the consignor payout as its cost basis
- Sale profit therefore equals the agreed commission
- the Consignment record is linked to the completed Sale

### Transaction History

The Transactions screen presents:

- Deals
- Sales
- Trade-ins
- Repairs
- Disposals
- Consignments

Sales and repairs navigate to their existing detail workflows. Other transaction categories remain summarized in the unified transaction history until dedicated detail screens are required.

---

## Error and Validation Conventions

- Invalid domain values are rejected before persistence.
- Repository duplicate/not-found/validation failures use application exception types.
- UI forms validate user-entered values before controllers are invoked.
- Multi-record workflows attempt rollback when a later step fails.
- Tests cover both success and important failure/edge paths.

---

## Testing Conventions

Tests are organized under `test/` using the same feature/layer structure as production code.

The suite includes:

- domain model tests
- repository tests
- provider/controller tests
- widget tests
- navigation/integration tests
- workflow regression tests

Before committing a completed task:

```text
dart format .
flutter analyze
flutter test
```

A Phase 2 change is not considered complete while analyzer issues or regression failures remain.

---

## Current Development Status

### Phase 2 - Core Architecture

Status: **Complete pending final regression verification and merge to `develop`.**

Completed Phase 2 capabilities include:

- Feature-first Flutter architecture
- Riverpod application/provider organization
- Centralized GoRouter navigation
- Shared responsive page/layout components
- Domain model conventions
- Repository interfaces and in-memory implementations
- Shared formatting, validation, and application error utilities
- Inventory acquisition/edit/detail/status workflows
- Contacts architecture/workflows
- Sale workflow and historical profit snapshots
- Repair workflow/history
- Trade-in integration with sales
- One-level Deal architecture, profit roll-up, history, and navigation
- Disposal foundation/UI/history
- Warranty Replacement workflow
- Consignment agreement/UI/sale accounting
- Unified transaction history across Phase 2 transaction types
- Automated model/repository/provider/widget/integration tests
- Architecture and testing conventions documented

---

## Next Phase

The next phase should introduce persistence and authenticated cloud operation behind the established repository boundaries, including:

- Firebase project configuration
- Firebase Authentication
- Cloud Firestore repository implementations
- Firebase Storage for images
- migration from development sample/in-memory data to persisted data
- security rules and authorized-user access

The Phase 2 domain and workflow behavior should remain the reference behavior while persistence is introduced.