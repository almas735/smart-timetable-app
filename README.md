# Smart Timetable Generator (Flutter + Genetic Algorithm)

A mobile app that generates conflict-free weekly college timetables using a **genetic algorithm**, with separate views for **admin, faculty and students**.

Backend repo: https://github.com/almas735/smart-timetable-backend

## Features
- Role-based login (admin / faculty / student)
- Admin CRUD: departments, faculty, subjects, rooms, sections
- One-tap timetable generation (genetic algorithm + repair step, 0 hard conflicts)
- Explainable result: clash counts, lab/capacity checks, same-day repeats
- Tap-to-edit manual override with live clash validation
- Automatic rescheduling when a faculty member is on leave
- NEP 2020 cross-department electives
- Analytics: room utilisation and faculty load
- PDF export (one page per section)
- Push notifications (Firebase Cloud Messaging) when a new timetable is generated
- Personal timetable view for each faculty member and student

## Tech stack
| Layer | Technology |
|---|---|
| App | Flutter / Dart, `http`, `pdf`, `printing`, `firebase_messaging` |
| Backend | Python, FastAPI, SQLAlchemy, SQLite, PyGAD, bcrypt |
| Notifications | Firebase Cloud Messaging |
| Hosting | Render (backend), GitHub |

## How it works
Each class is two genes (time slot, room). The fitness function penalises section, faculty and room clashes and same-day repeats. A repair step then fixes any remaining hard conflicts.

## Run it
1. Start the backend (see the backend repo README): `uvicorn main:app --host 0.0.0.0 --port 8000`
2. Set the backend address in `lib/config.dart`:
   - browser on the same PC: `http://127.0.0.1:8000`
   - real phone on the same WiFi: `http://<your-PC-WiFi-IP>:8000`
3. `flutter pub get`
4. Browser test: `flutter run -d web-server --web-port=8080`
5. Android build: `flutter build apk --release`

Push notifications need your own `android/app/google-services.json` from a Firebase project (not included in this repo).

## Demo accounts (local development only)
| Role | Email | Password |
|---|---|---|
| Admin | admin@college.edu | admin123 |
| Faculty | sharma.login@college.edu | faculty123 |
| Student | student@college.edu | student123 |

## Known limitations
- Login has no tokens yet (JWT planned); endpoints are not role-protected
- Tested on Android only
- Generating a timetable takes about 4-5 minutes
- Labs only need any lab room, not their own department's lab

## Roadmap
- PHP + MySQL REST API version of the backend
- JWT authentication and role-based authorisation
- Provider/Riverpod state management and tests
