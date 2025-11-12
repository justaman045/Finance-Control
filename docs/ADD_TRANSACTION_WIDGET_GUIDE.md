# Add Transaction Widget Guide

## Overview

The `AddTransactionWidget` is a comprehensive Flutter widget that allows users to add new transactions and view their current available balance in real-time. This widget is perfect for personal finance management applications.

## Features

✅ **Real-time Balance Calculation** - Automatically calculates and displays the current balance

✅ **Transaction Management** - Add both send and receive transactions

✅ **Input Validation** - Built-in validation for all fields

✅ **Balance Verification** - Prevents sending money if insufficient balance

✅ **Loading States** - Visual feedback during data operations

✅ **Error Handling** - Graceful error handling with user-friendly messages

✅ **Firebase Integration** - Seamlessly integrates with Cloud Firestore

✅ **Theme Support** - Fully responsive to light and dark themes

## Installation

### Prerequisites

Make sure you have the following packages in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_screenutil: ^5.9.0
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  firebase_core: ^2.24.2
```

## File Structure

```
lib/
├── Components/
│   ├── add_transaction_widget.dart    # Main widget file
│   └── colors.dart                    # Color definitions
├── Models/
│   ├── transaction.dart               # Transaction data model
│   └── user_model.dart                # User data model
└── Screens/
    └── add_transaction_screen.dart    # Example implementation
```

## Usage

### Basic Implementation

#### 1. Import the Widget

```dart
import 'package:money_control/Components/add_transaction_widget.dart';
```

#### 2. Use the Widget in Your Screen

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: AddTransactionWidget(
          transactionType: 'send', // or 'receive'
        ),
      ),
    );
  }
}
```

### Advanced Implementation with Tabs

For a more complete implementation with both send and receive options:

```dart
import 'package:flutter/material.dart';
import 'package:money_control/Screens/add_transaction_screen.dart';

// Navigate to the screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddTransactionScreen(),
  ),
);
```

## Widget Properties

### `AddTransactionWidget`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `transactionType` | `String` | `'send'` | Type of transaction: `'send'` or `'receive'` |

## Features Breakdown

### 1. Balance Display

The widget displays the current available balance at the top:

- **Real-time Calculation**: Automatically calculates balance from all transactions
- **Refresh Button**: Manual refresh option
- **Loading State**: Shimmer effect while loading
- **Error Handling**: Graceful error messages

### 2. Transaction Form

The form includes the following fields:

#### Amount Field
- **Required**: Yes
- **Validation**: 
  - Must be a valid number
  - Must be greater than 0
  - For 'send' type: Cannot exceed available balance
- **Input Type**: Numeric keyboard with decimal support

#### Recipient/Sender Field
- **Required**: Yes
- **Label**: Changes based on transaction type
  - Send: "Recipient"
  - Receive: "Sender"
- **Input Type**: Text

#### Category Field
- **Required**: No
- **Purpose**: Categorize transactions (e.g., Food, Transport, Bills)
- **Input Type**: Text

#### Note Field
- **Required**: No
- **Purpose**: Add additional details or comments
- **Input Type**: Multi-line text

### 3. Submit Button

The submit button:
- Changes color based on transaction type (primary for send, secondary for receive)
- Shows loading indicator during submission
- Displays appropriate icon and text
- Disabled during loading

## Data Flow

### Balance Calculation

```dart
Balance = (Total Received) - (Total Sent + Total Tax)
```

The widget:
1. Fetches all transactions where user is the sender
2. Fetches all transactions where user is the recipient
3. Calculates: `Received Amount - (Sent Amount + Tax)`

### Transaction Storage

Transactions are stored in Firestore with the following structure:

```
users/
  └── {userEmail}/
      └── transactions/
          └── {transactionId}/
              ├── senderId: string
              ├── recipientId: string
              ├── recipientName: string
              ├── amount: number
              ├── currency: string
              ├── tax: number
              ├── note: string?
              ├── category: string?
              ├── date: timestamp
              ├── status: string
              └── createdAt: timestamp
```

## Customization

### Styling

The widget automatically adapts to your app's theme. You can customize colors in `lib/Components/colors.dart`:

```dart
// Light Theme Colors
const Color kLightPrimary = Color(0xFF2F80ED);
const Color kLightSecondary = Color(0xFF8A3FFC);
const Color kLightBackground = Color(0xFFF6F8FD);

// Dark Theme Colors
const Color kDarkPrimary = Color(0xFF90AFFF);
const Color kDarkSecondary = Color(0xFFB39DDB);
const Color kDarkBackground = Color(0xFF1B2339);
```

### Validation

You can modify validation rules in the widget:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter amount';
  }
  final amount = double.tryParse(value);
  if (amount == null || amount <= 0) {
    return 'Please enter a valid amount';
  }
  // Add custom validation here
  return null;
}
```

## Error Handling

The widget handles several error scenarios:

1. **Authentication Errors**: User not logged in
2. **Network Errors**: Firestore connection issues
3. **Validation Errors**: Invalid input data
4. **Insufficient Balance**: Attempting to send more than available
5. **Database Errors**: Firestore write failures

All errors are displayed using SnackBar with appropriate colors:
- Success: Green (`kLightSuccess`)
- Error: Red (`kLightError`)

## Performance Considerations

### Balance Calculation

⚠️ **Important**: The current implementation fetches all transactions to calculate balance. For apps with many transactions, consider:

1. **Storing Balance in User Document**:
   ```dart
   // Update user document with calculated balance
   await FirebaseFirestore.instance
       .collection('users')
       .doc(userEmail)
       .update({'currentBalance': calculatedBalance});
   ```

2. **Using Cloud Functions**:
   - Calculate balance server-side
   - Update balance on each transaction
   - Use triggers for automatic updates

3. **Pagination**:
   - Fetch transactions in batches
   - Cache results locally

## Examples

### Example 1: Simple Integration

```dart
import 'package:flutter/material.dart';
import 'package:money_control/Components/add_transaction_widget.dart';

class QuickSendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quick Send')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: AddTransactionWidget(transactionType: 'send'),
      ),
    );
  }
}
```

### Example 2: Bottom Sheet

```dart
void showAddTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(16),
      child: AddTransactionWidget(transactionType: 'send'),
    ),
  );
}
```

### Example 3: With Navigation Callback

```dart
class TransactionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AddTransactionWidget(
              transactionType: 'send',
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('View All Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing

### Unit Testing Balance Calculation

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:money_control/Components/add_transaction_widget.dart';

void main() {
  test('Balance calculation with sent transactions', () {
    // Test implementation
  });
  
  test('Balance calculation with received transactions', () {
    // Test implementation
  });
  
  test('Insufficient balance validation', () {
    // Test implementation
  });
}
```

## Troubleshooting

### Issue: Balance Not Updating

**Solution**: Ensure Firebase is properly initialized in `main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Issue: Validation Not Working

**Solution**: Make sure the form key is properly initialized:

```dart
final _formKey = GlobalKey<FormState>();
```

### Issue: Theme Not Applied

**Solution**: Ensure your MaterialApp has proper theme configuration:

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: lightColorScheme,
  ),
  darkTheme: ThemeData(
    colorScheme: darkColorScheme,
  ),
)
```

## Future Enhancements

### Planned Features

- [ ] Transaction categories with icons
- [ ] Recurring transactions
- [ ] Multi-currency support
- [ ] Transaction attachments (receipts)
- [ ] Transaction splitting
- [ ] Expense limits and budgets
- [ ] Transaction search and filters
- [ ] Export to CSV/PDF

## Contributing

To contribute to this widget:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This widget is part of the Money Control app project.

## Support

For issues or questions:
- Create an issue on GitHub
- Contact: coderaman07@gmail.com

---

**Last Updated**: November 12, 2025

**Version**: 1.0.0
