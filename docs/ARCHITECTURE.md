# Hit the Deck Manager Architecture

## Purpose

Hit the Deck Manager is a cross-platform inventory management application built for Hit the Deck Sports. The application is designed to manage the complete lifecycle of baseball equipment, from acquisition through sale, while tracking costs, repairs, trades, profits, and customer information.

The application is intended to run on:

- Android
- iOS

Future versions may also support Web.

---

# Design Goals

The application is designed around the following principles:

- Simple and intuitive user interface
- Fast data entry
- Minimal screen navigation
- Scalable architecture
- Easy maintenance
- Offline-friendly where practical
- Cloud synchronization using Firebase

---

# Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| Language | Dart |
| Backend | Firebase |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication |
| Image Storage | Firebase Storage |
| State Management | Riverpod |
| Navigation | GoRouter |

---

# Project Structure

The application follows a feature-first architecture.

Each feature owns its own:

- Screens
- Widgets
- Models
- Providers
- Services

Example:

lib/
    features/
        inventory/
        contacts/
        dashboard/
        transactions/

This structure keeps related code together and makes the application easier to maintain as it grows.
---

# Feature Layer Structure

Features may use the following structure as they grow:

```text
feature_name/
    data/
    domain/
    presentation/
---

# Current Development Status

Current Milestone:

Phase 2 — Core Architecture

Completed:

- Git repository and branch workflow established
- Flutter project created
- Feature-first folder structure created
- Riverpod added at the application root
- GoRouter configured
- Centralized route names and paths created
- Responsive application navigation shell created
- Main feature routes added
- Buy Inventory and Sell Inventory routes added
- Shared page layout component created
- Navigation widget tests added
- Shared page layout tests added

In Progress:

- Feature-layer architecture conventions
- Riverpod provider organization
- Domain model structure
- Repository interface structure
- Shared application utilities
- Additional testing conventions
- Architecture documentation updates

Upcoming:

- Initial inventory domain model
- Repository contracts
- Firebase project integration
- Firebase Authentication
- Cloud Firestore integration
- Firebase Storage integration
- Inventory module implementation
- Contacts module implementation
- Transactions module implementation
- Dashboard and reports implementation

# Development Philosophy

The project favors:

- Readability over clever code
- Simplicity over unnecessary complexity
- Consistency across all features
- Modular design
- Long-term maintainability

Every feature should be developed so that it can be modified independently without affecting unrelated portions of the application.

---

This document is a living document and will evolve as the application grows.