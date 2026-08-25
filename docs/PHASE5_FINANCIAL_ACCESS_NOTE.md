# Phase 5 Financial Access Note

Phase 5 enforces the approved Owner/Admin/User financial visibility rules in the application and enforces disposal authorization in Firestore.

## Enforced now

- Owner/Admin can view financial Dashboard metrics and Reports.
- Ordinary Users do not see acquisition cost, profit, gross margin, repair cost, Deal profit, or consignment financial values in the application.
- Ordinary Users retain access to Minimum Acceptable Price where operationally required.
- Ordinary Users cannot access Reports routes.
- Ordinary Users cannot access disposal routes.
- Firestore blocks ordinary Users from creating/updating disposal records.
- Firestore blocks ordinary Users from moving inventory into or out of `disposed` status.

## Known schema limitation

Some operational Firestore documents currently contain both operational fields and financial fields. Firestore Security Rules cannot selectively hide individual fields in a document that a User is otherwise allowed to read.

Therefore, field-level backend secrecy for those mixed documents requires a future schema split into protected financial documents/collections. This is intentionally documented rather than represented as solved by UI hiding.

The application-level restrictions implemented in Phase 5 remain the v1.0 behavior until that schema separation is scheduled.