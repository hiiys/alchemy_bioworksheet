# Macrobenthos Counter

A production-ready Flutter Android app for field teams to register sample metadata, manage specimen taxa, perform hierarchical counting with drill-down bubbles, and save results back into a sample list.

## Features

### Core Functionality
- **Sample Management**: Create, edit, and manage field samples with metadata
- **Taxon Registration**: Hierarchical taxonomy management with parent-child relationships
- **Specimen Counting**: Intuitive bubble-based UI for hierarchical counting
- **Data Persistence**: SQLite database for offline data storage
- **Navigation**: Five main pages with consistent navigation

### Pages
1. **Home** - Overview with quick links and active sample info
2. **Sample Info** - Form for entering project/site/session metadata
3. **Sample List** - List of saved samples with view/continue and delete actions
4. **Specimen Registration** - Manage taxonomy library with tree view
5. **Macrobenthos Analysis** - Hierarchical drill-down bubble counter

### Technical Features
- Material 3 design with modern UI
- Provider state management
- SQLite database with proper indexing
- Hierarchical taxon navigation
- Search functionality across taxa
- Automatic data persistence
- Responsive design

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                 # Main app widget and routing
├── core/
│   ├── app_state.dart       # Central state management
│   ├── routing.dart         # Navigation constants
│   └── theme.dart           # App theming
├── data/
│   ├── models.dart          # Data models
│   ├── db.dart              # Database helper
│   ├── dao/
│   │   ├── project_dao.dart
│   │   ├── sample_dao.dart
│   │   ├── taxon_dao.dart
│   │   └── count_dao.dart
│   └── csv/                 # CSV import/export (future)
├── ui/
│   ├── widgets/
│   │   ├── app_scaffold.dart
│   │   ├── bubble_chip.dart
│   │   └── counter_bar.dart
│   ├── home/
│   │   └── home_page.dart
│   ├── sample_info/
│   │   └── sample_info_page.dart
│   ├── sample_list/
│   │   └── sample_list_page.dart
│   ├── registration/
│   │   └── registration_page.dart
│   └── analysis/
│       └── analysis_page.dart
```

## Data Model

### Core Entities
- **ProjectInfo**: Project metadata (name, client, team, date, remarks)
- **Sample**: Field sample (station ID, date, GPS, habitat, remarks)
- **Taxon**: Hierarchical taxonomy (name, parent, rank, notes)
- **CountRecord**: Specimen counts (sample, taxon, count, notes, photo)

### Database Schema
- SQLite database with foreign key constraints
- Indexes for performance on common queries
- Automatic creation with default test taxa

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio / VS Code
- Android emulator or physical device

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

### Development Commands
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Build for release
flutter build apk
```

## Usage Guide

### 1. Setting Up a Sample
1. Navigate to **Sample Info** page
2. Fill in required fields (Station ID, Date)
3. Optionally add GPS coordinates, habitat, and remarks
4. Click "Set as Active" to create and activate the sample

### 2. Managing Taxonomy
1. Go to **Specimen Registration** page
2. Add root taxa using the + button
3. Add child taxa by selecting a parent taxon
4. Edit or delete taxa using the options menu

### 3. Counting Specimens
1. Navigate to **Macrobenthos Analysis** page
2. Drill down through the hierarchical bubble interface
3. Select a leaf taxon to start counting
4. Use the bottom counter bar to increment/decrement counts
5. Counts are automatically saved to the active sample

### 4. Managing Samples
1. View all samples in **Sample List** page
2. Tap to set as active and continue counting
3. Long-press for additional options
4. Delete samples with confirmation

## Technical Implementation Notes

### State Management
- Uses Provider pattern for centralized state
- AppState class manages all application data
- Automatic persistence to SQLite database
- Real-time UI updates through ChangeNotifier

### Database Operations
- Singleton DatabaseHelper for connection management
- DAO pattern for data access operations
- Proper transaction handling
- Indexed queries for performance

### Navigation
- Named routes for all pages
- Consistent navigation bar across all screens
- Breadcrumb navigation in analysis page
- Modal dialogs for actions and forms

### UI Components
- Custom BubbleChip for hierarchical navigation
- CounterBar for specimen counting controls
- AppScaffold for consistent page layout
- Responsive grid layouts

## Future Enhancements

### Planned Features
- CSV import/export for taxa
- GPS location capture integration
- Photo attachment for count records
- Undo functionality for counting
- Dark mode support
- Data export and reporting

### Technical Improvements
- Unit and widget testing
- Performance optimization for large datasets
- Data validation and error handling
- Internationalization support

## Troubleshooting

### Common Issues
1. **No active sample**: Create a sample in Sample Info first
2. **No taxa available**: Add taxa in Specimen Registration
3. **Database errors**: App will automatically recreate database if corrupted

### Development Tips
- Use hot reload for quick UI testing
- Check console for SQLite debug information
- Test with the default sample taxa provided

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the project
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request
