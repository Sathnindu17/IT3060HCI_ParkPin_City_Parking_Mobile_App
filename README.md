# ParkPin – City Parking Mobile App

IT3060HCI_ParkPin_City_Parking_Mobile_App
ParkPin – Mobile app for finding and reserving parking in city centres, built for IT3060 HCI (Group WE_46, SLIIT).

| Part | Tech | Folder |
|---|---|---|
| Mobile app | Flutter (Android) | `frontend/` |
| Backend | Supabase – PostgreSQL, Auth, Row Level Security, Realtime | `supabase/` |

## Requirements
- Flutter SDK (stable) + Android Studio (SDK + emulator)
- A Supabase project (free tier) – see `supabase/README.md`
- Git

## Run the app
1. Set up Supabase once (`supabase/README.md`) and fill in `frontend/lib/core/config/supabase_config.dart`.
2. Start an Android emulator, then:
```
cd frontend
flutter pub get
flutter run
```

## Build the APK
```
cd frontend
flutter build apk --release
```
Output: `frontend/build/app/outputs/flutter-apk/app-release.apk`

## Demo accounts
| Role | Email | Password |
|---|---|---|
| Driver | driver@parkpin.lk | Password123 |
| Operator | operator@parkpin.lk | Password123 |
| Authority | authority@parkpin.lk | Password123 |

## Team
| Student ID | Name | Interfaces |
|---|---|---|
| IT23610484 | Wijesekara S | Driver D01–D13 |
| IT23606760 | Marasinghe M M W K | Operator O01–O10 |
| IT23615748 | E M K S Ekanayaka | Authority A01–A08 |
| IT23610002 | Rupasinghe K S | Driver D14–D22 |

## Branches
`main` (final) ← `dev` (integration) ← `feature/*` (one per member)