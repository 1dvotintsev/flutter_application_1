# PlantCare Mobile App

## Обзор
Кроссплатформенное мобильное приложение для учёта и автоматизации ухода за домашними растениями.

## Технологический стек
- **Фреймворк:** Flutter 3.x / Dart 3.x
- **Управление состоянием:** Riverpod (или Provider — на выбор)
- **Навигация:** GoRouter
- **HTTP-клиент:** dio
- **Аутентификация:** firebase_auth + google_sign_in
- **Push-уведомления:** firebase_messaging
- **Камера:** image_picker
- **Локальное хранение:** shared_preferences (токен, кэш)

## Бэкенд API
Сервер уже работает: `http://10.0.2.2:8000` (Android-эмулятор проксирует на localhost хоста).
Для iOS-симулятора: `http://localhost:8000`.
Основная платформа для тестирования — Android.

Все запросы требуют заголовка:
```
Authorization: Bearer <firebase_id_token>
```

### Эндпоинты
| Метод | URL | Описание |
|-------|-----|----------|
| POST | /auth/profile | Обновить профиль (name, location, experience_level) |
| GET | /users/me | Получить профиль |
| POST | /plants/identify | Идентификация {image_base64} → plant + species + schedules |
| GET | /plants | Коллекция (?room_id= для фильтра) |
| POST | /plants | Добавить вручную {species_id, room_id?, nickname, pot_type, soil_type} |
| GET | /plants/{id} | Детали растения |
| PUT | /plants/{id} | Обновить параметры |
| DELETE | /plants/{id} | Мягкое удаление |
| GET | /plants/{id}/events | Журнал мероприятий |
| POST | /plants/{id}/events | Добавить запись {care_type, notes?, photo_url?} |
| GET | /schedule/today | Задачи на сегодня |
| POST | /schedule/{id}/complete | Выполнить → пересчёт графика |
| POST | /schedule/{id}/snooze | Отложить на 1 день |
| GET | /species | Поиск (?q=запрос) |
| GET | /species/{id} | Детали вида |

## Структура проекта
```
lib/
├── main.dart
├── app.dart                    # MaterialApp + GoRouter + тема
├── config/
│   └── api_config.dart         # BASE_URL, таймауты
├── models/                     # Dart-классы данных
│   ├── user.dart
│   ├── plant.dart
│   ├── species.dart
│   ├── room.dart
│   ├── care_schedule.dart
│   ├── care_event.dart
│   └── photo.dart
├── services/                   # Взаимодействие с API
│   ├── api_service.dart        # Dio client, interceptors, auth header
│   ├── auth_service.dart       # Firebase Auth (sign in, sign out, token)
│   └── notification_service.dart # Firebase Messaging init, token
├── providers/                  # Riverpod providers
│   ├── auth_provider.dart
│   ├── plants_provider.dart
│   ├── schedule_provider.dart
│   └── species_provider.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart         # Задачи на сегодня
│   ├── collection/
│   │   ├── collection_screen.dart   # Сетка растений
│   │   └── plant_detail_screen.dart # Карточка растения + журнал
│   ├── identify/
│   │   ├── identify_screen.dart     # Камера / галерея
│   │   └── identify_result_screen.dart
│   ├── add_plant/
│   │   └── add_plant_screen.dart    # Форма добавления
│   ├── species/
│   │   └── species_detail_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── rooms_screen.dart
└── widgets/                    # Переиспользуемые компоненты
    ├── care_task_card.dart
    ├── plant_grid_card.dart
    ├── schedule_badge.dart
    └── loading_indicator.dart
```

## Навигация (GoRouter)
```
/login                          → LoginScreen
/                               → ShellRoute (Tab Bar)
  /home                         → HomeScreen (таб 1)
  /collection                   → CollectionScreen (таб 2)
  /identify                     → IdentifyScreen (таб 3)
  /profile                      → ProfileScreen (таб 4)
/plant/:id                      → PlantDetailScreen
/plant/add                      → AddPlantScreen
/identify/result                → IdentifyResultScreen
/species/:id                    → SpeciesDetailScreen
/rooms                          → RoomsScreen
```

## Модели данных (все поля)

### User
```dart
String id, email, name, location, experienceLevel, createdAt
```

### Plant
```dart
int id, speciesId, roomId?, userId
String nickname, potType, soilType, photoUrl
DateTime acquiredDate, createdAt
bool isActive
Species species
Room? room
List<CareSchedule> schedules
```

### Species
```dart
int id, waterIntervalDays, fertilizeIntervalDays, repotIntervalMonths
String commonName, scientificName, family, lightRequirement, description
double temperatureMin, temperatureMax
Map<String, dynamic> careTips
```

### Room
```dart
int id, userId
String name, lightLevel, windowDirection, notes
```

### CareSchedule
```dart
int id, plantId, intervalDays
String careType  // 'water', 'fertilize', 'repot'
DateTime nextDue, updatedAt
double seasonCoefficient
bool notified, isActive
```

### CareEvent
```dart
int id, plantId, scheduleId?
String careType, notes, photoUrl
DateTime performedAt, createdAt
```

## Дизайн
- Цветовая палитра: зелёная основа (#4CAF50 primary, #E8F5E9 background)
- Material Design 3
- Минимальный размер кнопок: 48x48
- Шрифт: системный (Roboto / SF Pro)
- Индикаторы срочности в карточках: зелёный (ok), жёлтый (завтра), красный (просрочено)

## Правила кода
- Все модели с factory fromJson / toJson
- Все API-вызовы через api_service.dart (единая точка)
- Обработка ошибок: try-catch + SnackBar
- Индикатор загрузки при любом запросе к серверу
- Null safety везде