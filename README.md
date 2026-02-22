# Koffee - Coffee Farm Registry App

An offline-first agricultural registry application for tracking coffee production from different farms (fincas).

## Features

- **Dual Registration**: Separate tabs for "Rojo" (red coffee cherries) and "Seco" (dry coffee beans)
- **Farm Management**: Save and select fincas (farms) with dropdown
- **Offline Support**: Works without internet connection
- **Cloud Sync**: Automatically syncs data to Firebase when online
- **Data Visualization**: View production statistics by farm in charts

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Android SDK / Xcode (for iOS)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add your Android/iOS app to the project
3. Download `google-services.json` (Android) and place it in `android/app/`
4. Enable Cloud Firestore in Firebase Console

## Usage

### Registration (Rojo Tab)
- Select or add a farm (finca)
- Enter the quantity of red coffee cherries in kilograms
- Save the record

### Registration (Seco Tab)
- Select or add a farm (finca)
- Enter the quantity of dry coffee beans in kilograms
- Enter the unit price per kilogram (minimum 1000 COP)
- Total is calculated automatically

### Viewing Records
- Navigate to "Registros" tab to see all entries
- Records show date, farm, kilos (red/dry), price, and total
- Use refresh button to update the list

### Charts
- Navigate to "Gráfica" tab to see production by farm

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Provider
- **Local Database**: SQLite (sqflite)
- **Cloud Database**: Firebase Firestore
- **Connectivity**: connectivity_plus

## License

MIT License
