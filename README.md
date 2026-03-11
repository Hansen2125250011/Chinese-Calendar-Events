# Chinese Calendar Events

A modern Flutter application designed to help users track Chinese Lunar Calendar events, traditional deity festivals, and personal custom reminders. Features a sleek UI with smooth animations and robust notification support.

## 🚀 Features

- **Traditional Festivals**: Comprehensive database of deity birthdays and traditional Chinese holidays.
- **Lunar Calendar Support**: Accurate conversion between Solar and Lunar dates.
- **Custom Events**: Add your own events, either on the Solar or Lunar calendar.
- **Smart Notifications**: Never miss an event with automated, optimized scheduling.
- **Multilingual UI**: Support for English (EN), Indonesian (ID), and Chinese (ZH).
- **Performance Optimized**: Efficient database batching and parallel notification processing.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.27+)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Database**: [Drift](https://drift.simonbinder.eu) (SQLite)
- **Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **Lunar Calculations**: [Lunar](https://pub.dev/packages/lunar) (6tails Library)
- **Navigation**: [Go Router](https://pub.dev/packages/go_router)
- **Animations**: [Flutter Animate](https://pub.dev/packages/flutter_animate)

## 📦 Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Android Studio / VS Code with Dart/Flutter extensions
- Java 17+ (for Android builds)

### Installation

1. **Clone the repository**:

   ```bash
   git clone git@github.com:Hansen2125250011/Chinese-Calendar-Events.git
   cd Chinese-Calendar-Events
   ```

2. **Get dependencies**:

   ```bash
   flutter pub get
   ```

3. **Generate database/provider code**:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```text
lib/
├── core/               # Shared services, constants, and database
│   ├── database/       # Drift DB implementation
│   └── services/       # Notification & global services
├── features/           # Feature-based modules
│   ├── calendar/       # Lunar/Solar conversion logic
│   ├── events/         # Traditional & Custom event management
│   ├── notifications/  # Scheduling & repo logic
│   └── settings/       # User preferences
└── shared/             # Reusable widgets and themes
```

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
