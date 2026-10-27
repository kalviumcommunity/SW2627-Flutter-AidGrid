# AidGrid — Low-Level Design (LLD)

## 1. Purpose

This document describes the internal design of AidGrid's core data models, service methods, Firestore documents, and workflows.

The design reflects the implementation discussed during development. Exact method names and file paths should be checked against the current repository before using this document as a line-by-line code reference.

## 2. Project Structure

The relevant application code follows a structure similar to:

```text
lib/
├── models/
│   └── assignment.dart
├── screens/
│   ├── assignments/
│   │   └── assignments_page.dart
│   ├── distributions/
│   │   └── record_distribution_page.dart
│   └── sites/
├── services/
│   ├── assignments_service.dart
│   └── distribution_services.dart
└── main.dart

test/
└── assignment_model_test.dart
```

The directory names shown here are based on the development context. Verify the exact spelling of each path in the current repository.

## 3. Data Models

### 3.1 Assignment Model

The `Assignment` model represents a task assigned to one or more volunteers.

Principal fields:

| Field | Type | Purpose |
|---|---|---|
| `id` | `String` | Assignment document identifier |
| `siteId` | `String` | Associated site |
| `volunteerIds` | `List<String>` | IDs of assigned volunteers |
| `taskDescription` | `String` | Task details |
| `assignedAt` | `DateTime` | Assignment timestamp |
| `status` | `AssignmentStatus` | Current task status |
| `siteName` | `String?` | Optional site display name |

The exact field types and constructor requirements should be verified against `lib/models/assignment.dart`.

#### Serialization

`fromMap` converts Firestore-style map data into a Dart assignment object.

For backward compatibility:
1. Read `volunteerIds` when the field exists and contains a list.
2. Otherwise, read the legacy `volunteerId` string.
3. Convert the legacy value into a single-element list.
4. Preserve the other assignment properties.

`toMap` writes the current representation using `volunteerIds`.

`copyWith` allows selected properties, such as the volunteer list or status, to be updated without rebuilding the object manually.

#### Assignment Status

The supported status values are:
- `Pending`
- `In Progress`
- `Completed`

The stored string representation must match the values expected by Firestore Security Rules.

### 3.2 Inventory Data

Inventory documents are stored in the `Inventory` collection.

Important fields include:
- `name`
- `quantity`
- `unit`

The distribution service reads the current quantity and decreases it after validating the requested quantity.

### 3.3 Site Data

Site documents are stored in `Sites`.

The application uses fields including:
- `name`
- `isActive`

A site ID is stored in assignments and distribution records.

### 3.4 User Data

User profiles are stored in the lowercase `users` collection.

The role field distinguishes administrators from volunteers. The authenticated Firebase UID is used to identify the current user.

The role values used by the current rules include:
- `ADMIN`
- `VOLUNTEER`

### 3.5 Distribution Record

Distribution documents are stored in `Distributions`.

The rules and service use fields including:
- `itemId`
- `siteId`
- `quantity`
- `volunteerId`
- `distributedAt`

The service also uses an optional assignment reference and an assignment description when available.

The exact serialization schema for all optional fields should be verified in the distribution-record model.

## 4. Assignment Service

### 4.1 Assignment Creation

The assignment creation service accepts multiple volunteer IDs.

Processing:
1. Receive the site, task description, and volunteer IDs.
2. Trim whitespace from volunteer IDs.
3. Remove empty IDs.
4. Deduplicate the IDs using a set.
5. Construct the assignment object.
6. Serialize the assignment.
7. Create the Firestore document, subject to administrator authorization.

The deduplication step prevents the same volunteer from being selected multiple times.

An empty volunteer selection should be rejected by the UI and validated wherever the service contract requires it.

### 4.2 Volunteer Assignment Stream

The volunteer assignment stream retrieves tasks associated with a specific volunteer.

The current implementation supports two query paths:

**Legacy query**
- Match `volunteerId` to the volunteer's UID.

**Multi-volunteer query**
- Use `arrayContains` on `volunteerIds`.

The service merges results from both streams and deduplicates documents by assignment ID.

The merged results are filtered to assignments containing the requested volunteer ID and sorted by assignment time.

#### Complexity

For \(n\) retrieved assignments, merging into a map and sorting the resulting assignments takes approximately:

\[
O(n \log n)
\]

This describes client-side processing after Firestore returns the results. Firestore query cost depends on the documents and indexes involved, not just this complexity.

#### Stream lifecycle

The service manages subscriptions to both Firestore queries and the local fallback stream. Subscriptions should be cancelled when the returned stream is cancelled to avoid unnecessary listeners.

#### Error handling

The service records fallback state and the most recent Firestore error. Local fallback data may be emitted if a remote stream fails.

Fallback data is not equivalent to a successful server read and must not be treated as authoritative for authorization.

### 4.3 Assignment Status Update

The status update service accepts:
- Assignment ID.
- New status.
- Current user ID.
- Administrator flag.

Processing:
1. Fetch the assignment document.
2. Reject the operation if the document does not exist.
3. Extract `volunteerIds`, falling back to legacy `volunteerId`.
4. If the caller is not an administrator, verify that their UID is assigned to the document.
5. Update the status field.
6. Update local state when the write succeeds.
7. Return the persistence result or propagate the relevant authorization error.

The client-side authorization check improves error handling. Firestore Security Rules remain the authoritative access control mechanism.

## 5. Assignment UI

The assignment management screen provides the interface for creating and updating assignments.

### Multi-volunteer selection

The selection workflow:
1. Open a volunteer search interface.
2. Search the available volunteer records.
3. Select a volunteer ID.
4. Add the ID to a set of selected IDs.
5. Display selected volunteers.
6. Allow volunteers to be removed from the selection.
7. Submit the resulting list when creating the assignment.

A set avoids duplicate selection.

The create operation should be disabled or rejected when no volunteers are selected.

### Status update workflow

The UI submits the assignment ID, requested status, current UID, and administrator state to the assignment service.

The UI should display success only when the service confirms the write. Failed updates should show an error and should not falsely indicate persistence.

## 6. Distribution Service

The distribution service is responsible for recording a distribution and updating inventory.

### Method contract

The service accepts:
- `itemId`
- `siteId`
- `quantity`
- Optional `assignmentId`
- `volunteerId`

The current implementation also checks for an authenticated Firebase user before executing the operation.

### Validation

Before committing changes, the service validates:
1. A user is authenticated.
2. The requested quantity is greater than zero.
3. The inventory document exists.
4. The site document exists.
5. The volunteer document exists.
6. The volunteer has the expected role.
7. If an assignment is provided, the assignment exists.
8. The selected volunteer is assigned to the assignment, supporting both legacy and new formats.
9. The assignment site matches the selected site.
10. The assignment status is `Pending` or `In Progress`.
11. Sufficient inventory is available.

### Transaction workflow

Within a Firestore transaction, the service reads the relevant documents and performs the required validation.

If the checks pass:
- Update the inventory quantity.
- Create the distribution record.

The stock calculation is:

\[
Q_{\text{remaining}} = Q_{\text{current}} - Q_{\text{distributed}}
\]

The operation must ensure:

\[
Q_{\text{distributed}} > 0
\]

and

\[
Q_{\text{remaining}} \geq 0
\]

If validation fails, the transaction must not commit either write.

### Transactional consistency

Both writes belong to the same transaction. This prevents a successful inventory deduction from being committed without its corresponding distribution record, or a record from being committed without the associated stock update.

Firestore transactions can be retried when concurrent changes affect the documents they read. Transaction callbacks should therefore avoid non-idempotent external side effects.

## 7. Firestore Security Rules

### 7.1 User Profiles

- Users can read their own profile.
- Administrators can read user profiles.
- Users can create their own profile only with the permitted volunteer role.
- Ordinary profile updates must preserve the role.
- Profile deletion is disabled.

Administrator provisioning must be handled through a trusted process rather than allowing users to assign themselves administrative privileges.

### 7.2 Inventory

- Authenticated users can read inventory.
- Only administrators can create, update, or delete inventory documents.

### 7.3 Sites

- Authenticated users can read site documents.
- Only administrators can create, update, or delete sites.

### 7.4 Assignments

The rules support:
- The legacy `volunteerId` field.
- The newer `volunteerIds` list.
- Administrator management.
- Volunteer reads when the requesting UID is assigned.
- Volunteer updates limited to the `status` field.
- A fixed list of permitted status values.

Because Firestore rules are not filters, volunteer queries must be structured so the query's potential results satisfy the applicable read rules.

### 7.5 Distributions

- Distribution creation is restricted to administrators.
- Updates and deletions are disabled.
- Reads are restricted according to administrator access or the recorded volunteer field.

The distribution service and the security rules must remain consistent as the application evolves.

## 8. Error Handling

Expected failure cases include:
- Unauthenticated requests.
- Missing inventory or site documents.
- Invalid quantities.
- Insufficient stock.
- Invalid volunteer roles.
- Assignment/volunteer mismatches.
- Assignment/site mismatches.
- Invalid assignment status.
- Firestore permission errors.
- Network or database failures.

The UI should show actionable messages while avoiding the display of sensitive information.

## 9. Testing Strategy

### Model Tests
- Parse an assignment with `volunteerIds`.
- Parse a legacy assignment with `volunteerId`.
- Serialize an assignment using the new format.
- Verify `copyWith` behavior.

### Assignment Service Tests
- Create an assignment with multiple volunteers.
- Verify duplicate IDs are removed.
- Retrieve assignments for each assigned volunteer.
- Verify results are deduplicated across legacy and new query paths.
- Verify status updates reject unassigned volunteers.

### Distribution Tests
- Reject a non-positive quantity.
- Reject missing inventory or site records.
- Reject a volunteer not assigned to the selected assignment.
- Reject a site that does not match the assignment.
- Reject an invalid assignment status.
- Verify inventory deduction and record creation succeed together.
- Verify insufficient inventory does not result in a partial write.

### Security Rules Tests
- Test administrator access.
- Test assigned-volunteer access.
- Test unassigned-volunteer denial.
- Test attempts to alter assignment fields other than status.
- Test self-promotion attempts.
- Test unauthorized inventory and distribution writes.

## 10. Known Design Considerations

1. Legacy compatibility in model parsing does not automatically provide legacy compatibility in Firestore queries. Queries must explicitly handle both formats or the data must be migrated.
2. Client-side role flags must not be treated as authoritative authorization.
3. Firestore security rules must validate the fields that determine access and constrain permitted updates.
4. The exact model fields, service signatures, and error behavior should be kept synchronized with the source code.
5. Sample or fallback records must not create authorization exceptions that apply to real Firestore documents.

## 11. Future Improvements

Potential improvements include:
- Automated Firestore Security Rules tests.
- A controlled migration from `volunteerId` to `volunteerIds`.
- More comprehensive service-level tests.
- Improved offline synchronization.
- Distribution reporting and inventory alerts.
- Better monitoring of failed transactions and authorization errors.
