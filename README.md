# AidGrid — Food Distribution Management System

AidGrid is a Flutter-based food distribution management application designed to help non-profit organizations coordinate food inventory, distribution sites, volunteers, and assignments. It aims to make food distribution more organized by centralizing operational data and providing role-based access to key features.

## Features

- **Inventory Management:** View available inventory and manage stock quantities.
- **Site Management:** Maintain information about distribution sites.
- **Volunteer Management:** Retrieve registered volunteers and assign them to distribution tasks.
- **Assignment Management:** Create assignments for multiple volunteers, track their status, and associate them with distribution sites.
- **Distribution Tracking:** Record food distributions, including the item, quantity, site, and volunteer information.
- **Role-Based Access Control:** Distinguish between administrators and volunteers to control access to operational features.
- **Real-Time Data:** Use Firebase Firestore streams to keep relevant application data updated.
- **Assignment Search:** Search for volunteers when creating assignments.
- **Legacy Data Compatibility:** Support older assignments that use a single `volunteerId` alongside newer assignments that use a `volunteerIds` list.

## Problem Statement

Non-profit organizations often coordinate food distribution across multiple communities using fragmented communication channels. This can make it difficult to track inventory, assign volunteers, and maintain a clear record of distributions.

AidGrid aims to centralize these activities in one application, helping coordinators organize assignments, monitor available stock, and maintain distribution records.

## Tech Stack

- **Frontend:** Flutter
- **Programming Language:** Dart
- **Backend and Database:** Firebase
- **Database:** Cloud Firestore
- **Authentication:** Firebase Authentication
- **Version Control:** Git and GitHub

## User Roles

### Administrator

Administrators have management access to the application's operational data.

- Manage inventory items.
- Manage distribution sites.
- Create, update, and delete assignments.
- Manage distribution records.
- Access administrative data according to Firestore security rules.

### Volunteer

Volunteers have restricted access based on their assigned responsibilities.

- View assignments they are assigned to.
- Update the status of their assignments.
- Access permitted application data.
- Operate within the restrictions enforced by Firebase security rules.

## Assignment Workflow

1. An administrator creates an assignment for a distribution site.
2. One or more volunteers are assigned to the task.
3. Volunteers view their assigned tasks.
4. Assigned volunteers update the assignment status as work progresses.
5. Distribution records can be associated with an assignment where applicable.

Assignment statuses include:

- `Pending`
- `In Progress`
- `Completed`

## Distribution Workflow

1. Select a distribution site.
2. Select a volunteer.
3. Select an inventory item.
4. Optionally link an assignment.
5. Enter the quantity to distribute.
6. Record the distribution.

The distribution service uses a Firestore transaction to update inventory and create a corresponding distribution record atomically.

Distribution management is restricted to administrators under the current security rules.

## Database Structure

AidGrid uses the following Firestore collections:

| Collection | Purpose |
|---|---|
| `users` | User profiles and roles |
| `Inventory` | Inventory items and available quantities |
| `Sites` | Distribution site information |
| `Assignments` | Volunteer assignments, task details, and status |
| `Distributions` | Records of completed distribution operations |

New assignments support multiple volunteers through the `volunteerIds` field. Older assignments may use the legacy `volunteerId` field.

## Security

Firestore Security Rules are used to enforce access permissions.

- Users cannot change their own role through ordinary profile updates.
- Inventory creation, updates, and deletion are restricted to administrators.
- Site creation, updates, and deletion are restricted to administrators.
- Administrators can manage assignments.
- Assigned volunteers can update assignment status, subject to the rules.
- Distribution creation is restricted to administrators.
- Distribution updates and deletions are disabled under the current rules.

Client-side checks provide a better user experience, while Firestore rules enforce access at the database level.

## Getting Started

### Prerequisites

Install the following:

- Flutter SDK
- Dart SDK compatible with the Flutter version
- Git
- An editor such as Visual Studio Code or Android Studio
- A Firebase project with Authentication and Cloud Firestore configured

### 1. Clone the repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd food_distribution_app
```

Replace `<YOUR_REPOSITORY_URL>` with your GitHub repository URL.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Configure the application to connect to your Firebase project.

If you use FlutterFire CLI, you can configure the project with:

```bash
flutterfire configure
```

Ensure Firebase Authentication, Firestore, and the required platform configuration are set up correctly.

### 4. Run the application

For a connected device or emulator:

```bash
flutter run
```

To run the web version, if web support is configured:

```bash
flutter run -d chrome
```

## Testing and Code Analysis

Run static analysis:

```bash
flutter analyze
```

Run the test suite:

```bash
flutter test
```

## Project Goals

AidGrid is intended to provide a manageable and testable foundation for food distribution coordination, with an emphasis on:

- Centralized inventory and distribution records.
- Clear volunteer responsibilities.
- Multi-volunteer assignment support.
- Reliable stock updates.
- Database-enforced access control.
- Maintainable Flutter and Dart code.

## Future Improvements

Potential improvements include:

- More detailed inventory and distribution reports.
- Low-stock alerts.
- Assignment and distribution dashboards.
- Improved filtering and search.
- Automated tests for Firestore security rules.
- Better offline handling and synchronization.
- Migration tools for legacy assignment documents.

## License

No license has been specified yet. Add a license before distributing or reusing this project publicly.
