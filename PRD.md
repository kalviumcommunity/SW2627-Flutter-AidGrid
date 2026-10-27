# AidGrid — Product Requirements Document (PRD)

**Project:** AidGrid — Food Distribution Management System  
**Platform:** Flutter application  
**Backend:** Firebase  
**Database:** Cloud Firestore  
**Version:** 1.0  
**Status:** Project implementation in progress

## 1. Product Overview

AidGrid is a food distribution management application designed for non-profit organizations that coordinate food distribution across multiple communities and sites.

The application centralizes inventory management, site information, volunteer assignments, and distribution records. It uses role-based access control to distinguish administrative operations from volunteer activities.

## 2. Problem Statement

Non-profit organizations often coordinate food distribution through fragmented communication channels. This makes it difficult to track inventory, coordinate volunteers, and maintain an accurate record of food distributed at individual sites.

During active campaigns, coordinators need reliable information about available stock and assignment progress to manage distribution operations effectively.

AidGrid addresses this problem by providing a centralized application for managing operational data and coordinating volunteers.

## 3. Product Objectives

The primary objectives are:

1. Centralize inventory and distribution-site information.
2. Allow administrators to create assignments for multiple volunteers.
3. Enable volunteers to view their assignments and update assignment status.
4. Maintain records of distribution activities.
5. Ensure inventory quantities are updated consistently when distributions are recorded.
6. Enforce permissions using Firebase Authentication and Firestore Security Rules.

## 4. Target Users

### 4.1 Administrators

Administrators coordinate and manage the food distribution operation.

Responsibilities:
- Create, update, and delete inventory items.
- Manage distribution sites.
- Create and manage assignments.
- Assign multiple volunteers to a task.
- Manage distribution records.
- Monitor application data.

### 4.2 Volunteers

Volunteers carry out assigned distribution activities.

Responsibilities:
- View assignments assigned to them.
- Update the status of their assignments.
- Access permitted operational information.

Volunteers should not have unrestricted permission to manage inventory or create distribution records under the current authorization policy.

## 5. Functional Requirements

### FR-01: Authentication and User Roles

- Users must authenticate before accessing protected application data.
- User profiles are stored in the `users` collection.
- User roles distinguish administrators from volunteers.
- Users must not be able to promote themselves by changing their own role.

### FR-02: Inventory Management

- Administrators can create inventory items.
- Administrators can update item information and quantities.
- Administrators can delete inventory items.
- Authenticated users can read inventory information, subject to application behavior and security rules.
- Inventory quantities must not become negative through a valid distribution operation.

### FR-03: Distribution-Site Management

- Administrators can create, update, and delete distribution sites.
- Site information is stored in Firestore.
- Active sites can be retrieved for distribution workflows.

### FR-04: Assignment Management

- Administrators can create assignments for distribution sites.
- An assignment can be assigned to one or more volunteers.
- Volunteers can be searched and selected during assignment creation.
- Assignments contain a description, site, assignment date, and status.
- Administrators can manage assignments.
- Assigned volunteers can update assignment status within the permitted status values.

Supported statuses:
- `Pending`
- `In Progress`
- `Completed`

### FR-05: Volunteer Assignment Retrieval

- Volunteers should see assignments associated with their user ID.
- The application supports the new `volunteerIds` list.
- Older assignment documents using `volunteerId` must remain compatible where the relevant query and security rules support them.

### FR-06: Distribution Recording

- Administrators can record a distribution.
- A distribution identifies an inventory item, site, quantity, and volunteer.
- An assignment can optionally be linked to the distribution.
- The quantity must be a positive integer.
- The selected inventory item and site must exist.
- The inventory deduction and distribution-record creation must occur in a Firestore transaction.

### FR-07: Authorization

- Administrators have management permissions for operational collections.
- Volunteers can update only the status of assignments assigned to them.
- Users cannot change their own role through ordinary profile updates.
- Distribution creation is restricted to administrators under the current Firestore rules.
- Authorization must be enforced by Firestore Security Rules, not solely by Flutter UI checks.

## 6. Non-Functional Requirements

### Security
- Require authentication for protected data.
- Apply least-privilege access.
- Validate critical operations in Firestore Security Rules.
- Prevent unauthorized stock modifications and role changes.

### Data Consistency
- Use Firestore transactions for distribution recording.
- Validate quantity before changing inventory.
- Avoid creating a distribution record when the associated stock update fails.

### Maintainability
- Separate models, services, and UI screens.
- Keep data-access logic out of presentation widgets where practical.
- Maintain compatibility with older assignment records.

### Reliability
- Handle authentication, database, and validation errors.
- Provide clear feedback when an operation fails.
- Test important workflows using multiple user roles.

## 7. Core User Workflows

### Workflow A: Create an Assignment
1. Administrator opens assignment management.
2. Administrator selects a site.
3. Administrator searches for and selects one or more volunteers.
4. Administrator enters task details.
5. The application creates the assignment in Firestore.

### Workflow B: Update Assignment Status
1. Volunteer signs in.
2. The application retrieves assignments associated with that volunteer.
3. Volunteer opens an assignment.
4. Volunteer selects a permitted status.
5. The service updates the assignment, subject to Firestore authorization.

### Workflow C: Record a Distribution
1. Administrator selects a site and volunteer.
2. Administrator selects an inventory item.
3. Administrator optionally links an assignment.
4. Administrator enters a positive quantity.
5. The service validates the data and executes a Firestore transaction.
6. The transaction decreases inventory and creates a distribution record.

## 8. Acceptance Criteria

- An administrator can create an assignment with multiple volunteers.
- Every assigned volunteer can retrieve the assignment, subject to query and security-rule compatibility.
- An assigned volunteer can update the assignment status.
- An unassigned volunteer cannot update another volunteer's assignment.
- Inventory quantities remain non-negative after valid distribution operations.
- A successful distribution creates a corresponding record and updates stock atomically.
- Failed transactions do not leave a partial stock deduction.
- Users cannot promote themselves to administrator.

## 9. Out of Scope and Future Enhancements

Potential future improvements include:
- Low-stock alerts.
- Distribution analytics and reporting.
- Campaign-level coordination.
- Offline-first operation.
- Automated notification workflows.
- Automated Firestore Security Rules tests.

These are proposed enhancements, not claims about the current implementation.

## 10. Success Measures

Project success can be evaluated through:
- Successful assignment creation and retrieval.
- Correct role-based access enforcement.
- Correct inventory calculations.
- Consistent distribution records.
- Passing automated tests and end-to-end workflow tests.
