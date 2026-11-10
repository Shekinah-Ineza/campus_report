# Campus Report

This is a Flutter mobile app for reporting campus problems, such as broken facilities, water shortages, power outages, damaged furniture, sanitation issues and safety concerns, and following them until they are fixed.

Students submit reports with a category, description, location and optional photo. Authorized staff review the reports and update their status, and every change is recorded so students can see what happened and when.

## Features

**For students**
- Register and sign in with email and password (Firebase Authentication)
- Submit a report with a category, title, location, description and optional photo
- Browse all reports in a live feed that updates in real time
- Search by keyword and filter by category and status
- View report details, the photo and a status timeline showing every change
- Press "This affects me too" instead of reporting the same problem twice
- Home screen with a summary of your own reports, and a Profile page listing them

**For staff**
- Everything students can do
- Update a report's status: Submitted → In Review → In Progress → Resolved (or Rejected)
- A separate staff portal home: an overview of all reports on campus, new reports waiting for review, and the open reports waiting longest
- Leave a note for the student when changing a status
- Staff dashboard showing reports by status and category, and the average time to resolve

**Security**
- New sign-ups are always students; staff access is granted by an administrator
- Firestore Security Rules enforce the roles on the server, so a modified app still cannot change a status or a user's own role

## Tech stack

| Area | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Photo storage | Cloudinary (unsigned uploads) |

**Why Cloudinary instead of Firebase Storage:** Firebase Storage now requires a billing account. With the lecturer's approval, photos are uploaded to Cloudinary's free plan, and only the photo's URL is saved in Firestore. This also keeps Firestore documents small, since they are limited to 1 MB.

## Architecture

The app is organized in layers, so each part has one job:

```
UI (screens and widgets)  →  State (Riverpod providers)  →  Repositories  →  Firebase / Cloudinary
```

```
lib/
├── core/      App theme, constants and Cloudinary settings
├── models/    Data classes (incident, user, status change, enums)
├── data/      Repositories: the only code that talks to Firebase and Cloudinary
├── state/     Riverpod providers connecting the data to the screens
└── ui/
    ├── screens/   App screens (login, feed, report form, details, dashboard)
    └── widgets/   Reusable components (incident card, status chip, etc.)
```

Screens only display data and handle user input. They never call Firebase directly, which keeps the code easier to test and change.

## Firestore data structure

```
users/{uid}
  name, email, role ("student" or "staff"), createdAt

incidents/{incidentId}
  title, category, location, description, imageUrl,
  status, reporterId, reporterName, upvotes, lastNote, createdAt, updatedAt
  └── status history entries (who changed the status, to what, and when)
```

## Getting started

**Requirements:** Flutter SDK, Android Studio with an emulator (or a physical Android device), a Firebase project and a free Cloudinary account.

1. **Clone the repository**
   ```bash
   git clone https://github.com/Shekinah-Ineza/campus_report.git
   cd campus_report
   flutter pub get
   ```

2. **Connect Firebase**
   - Create a Firebase project and enable **Email/Password** sign-in under Authentication.
   - Create a **Cloud Firestore** database.
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`.

3. **Publish the security rules**
   Copy the contents of `firestore.rules` into **Firestore → Rules** in the Firebase console and click **Publish**.

4. **Set up Cloudinary**
   - In the Cloudinary console, create an **unsigned upload preset**.
   - Put your cloud name and preset name in `lib/core/cloudinary_config.dart`.

5. **Run the app**
   ```bash
   flutter run
   ```

6. **Create a staff account**
   Register a normal account in the app, then in **Firestore → users** change that account's `role` from `student` to `staff`. The app switches to the staff portal automatically.

## Testing

```bash
flutter test
```

The tests cover form validation, search, filter and sort logic, the data models (parsing, default values, status logic) and the status chip widget. Role-based access was tested manually by confirming that a student account cannot update a report's status.