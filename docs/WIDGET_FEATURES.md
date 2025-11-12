# Add Transaction Widget - Features & Visual Guide

## Widget Overview

The `AddTransactionWidget` is a complete solution for managing transactions in your Money Control app. This document describes the visual appearance and interactive features.

## Visual Layout

### Component Structure

```
┌──────────────────────────────────────────┐
│  ADD TRANSACTION WIDGET                   │
├──────────────────────────────────────────┤
│                                          │
│  ╭───────────────────────────────────╮  │
│  │  AVAILABLE BALANCE      🔄        │  │
│  │                                  │  │
│  │  ₹ 1,234.56                      │  │
│  ╰───────────────────────────────────╯  │
│                                          │
│  ADD NEW TRANSACTION                      │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │ ₹  Amount                       │  │
│  │    Enter amount                 │  │
│  └──────────────────────────────────┘  │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │ 👤  Recipient                    │  │
│  │    Enter name or ID             │  │
│  └──────────────────────────────────┘  │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │ 📊  Category (Optional)          │  │
│  │    e.g., Food, Transport        │  │
│  └──────────────────────────────────┘  │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │ 📝  Note (Optional)              │  │
│  │    Add a note                   │  │
│  │                                  │  │
│  └──────────────────────────────────┘  │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │   ↗️  SEND MONEY               │  │
│  └──────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

## Section Details

### 1. Balance Display Section

**Visual Appearance:**
- Gradient background (blue to purple for light theme)
- Large, bold balance text with rupee symbol
- Refresh button on the right
- "Available Balance" label in smaller, muted text

**States:**

#### Loading State
```
╭──────────────────────────────────╮
│  Available Balance      🔄      │
│                                │
│  ░░░░░░░░░░░░ (shimmer)      │
╰──────────────────────────────────╯
```

#### Normal State
```
╭──────────────────────────────────╮
│  Available Balance      🔄      │
│                                │
│  ₹ 5,432.10                    │
╰──────────────────────────────────╯
```

#### Error State
```
╭──────────────────────────────────╮
│  Available Balance      🔄      │
│                                │
│  --                           │
╰──────────────────────────────────╯
```

### 2. Transaction Form Section

#### Amount Field

**Features:**
- Currency rupee icon prefix
- Numeric keyboard with decimal support
- Real-time validation
- Error message display

**Validation:**
- Required field
- Must be positive number
- Cannot exceed balance (for send type)

**Example States:**

```
Empty State:
┌─────────────────────────────────┐
│ ₹  Amount                     │
│    Enter amount               │
└─────────────────────────────────┘

Filled State:
┌─────────────────────────────────┐
│ ₹  Amount                     │
│    500.00                     │
└─────────────────────────────────┘

Error State:
┌─────────────────────────────────┐ ❌
│ ₹  Amount                     │
│    10000                      │
│    Insufficient balance       │
└─────────────────────────────────┘
```

#### Recipient Field

**Features:**
- Person icon prefix
- Text input
- Label changes based on transaction type
  - Send: "Recipient"
  - Receive: "Sender"

#### Category Field (Optional)

**Features:**
- Category icon prefix
- Suggestions: Food, Transport, Bills, Shopping, etc.
- Optional field

#### Note Field (Optional)

**Features:**
- Note icon prefix
- Multi-line text area (2 lines)
- Optional field
- Supports longer descriptions

### 3. Submit Button

**Visual Appearance:**
- Full-width button
- Rounded corners (12px)
- Icon + Text
- Color based on transaction type:
  - Send: Primary blue color
  - Receive: Secondary purple color

**States:**

```
Normal State (Send):
┌────────────────────────────────┐
│  ↗️  SEND MONEY             │
└────────────────────────────────┘

Normal State (Receive):
┌────────────────────────────────┐
│  ↙️  RECEIVE MONEY          │
└────────────────────────────────┘

Loading State:
┌────────────────────────────────┐
│         ⧖ Loading...        │
└────────────────────────────────┘

Disabled State:
┌────────────────────────────────┐
│  ↗️  SEND MONEY (grayed)    │
└────────────────────────────────┘
```

## Theme Support

### Light Theme

**Colors:**
- Background: Light gray (#F6F8FD)
- Surface: White
- Primary: Blue (#2F80ED)
- Secondary: Purple (#8A3FFC)
- Text: Black
- Border: Light gray (#EBEBEB)

**Balance Section:**
- Gradient: Blue to Purple (light opacity)
- Shadow: Subtle, soft

### Dark Theme

**Colors:**
- Background: Dark blue (#1B2339)
- Surface: Dark purple (#23253C)
- Primary: Light blue (#90AFFF)
- Secondary: Light purple (#B39DDB)
- Text: White
- Border: Dark purple (#31304F)

**Balance Section:**
- Gradient: Dark blue to Dark purple
- Shadow: Deeper, more pronounced

## Interactive Features

### 1. Real-time Validation

```
User Types: "abc"
→ Error: "Please enter a valid amount"

User Types: "-100"
→ Error: "Please enter a valid amount"

User Types: "10000" (balance: 5000)
→ Error: "Insufficient balance"

User Types: "500" (balance: 5000)
→ Valid ✓
```

### 2. Balance Updates

```
Initial Balance: ₹ 5,000.00

User Sends: ₹ 500.00
→ New Balance: ₹ 4,500.00

User Receives: ₹ 1,000.00
→ New Balance: ₹ 5,500.00
```

### 3. Feedback Messages

**Success (Green):**
```
✓ Transaction added successfully!
```

**Error (Red):**
```
✗ Insufficient balance
✗ Failed to add transaction
✗ User not authenticated
```

## Accessibility Features

✅ **Screen Reader Support**
- All fields have proper labels
- Error messages are announced
- Button states are communicated

✅ **Keyboard Navigation**
- Tab through fields
- Enter to submit
- Escape to close (if in modal)

✅ **Color Contrast**
- WCAG AA compliant
- Works in high contrast mode

✅ **Touch Targets**
- Minimum 48x48 dp
- Adequate spacing between elements

## Animation & Transitions

### Loading States
- **Balance Shimmer**: Pulsing gray rectangle
- **Button Spinner**: Rotating circular indicator
- **Duration**: Continuous until loaded

### Form Validation
- **Error Shake**: Subtle shake animation on invalid input
- **Success Fade**: Green checkmark fades in
- **Duration**: 300ms

### Field Focus
- **Border Color**: Animates to primary color
- **Duration**: 200ms
- **Easing**: Ease-in-out

## Responsive Design

### Mobile (< 600px)
- Single column layout
- Full-width inputs
- Comfortable touch targets
- Adequate padding

### Tablet (600-900px)
- Slightly wider inputs
- More whitespace
- Larger text

### Desktop (> 900px)
- Maximum width constraint
- Centered layout
- Hover states on buttons

## Best Practices

### Do's ✅
- Keep balance updated in real-time
- Provide clear error messages
- Show loading states
- Clear form after success
- Validate before submission

### Don'ts ❌
- Don't allow negative amounts
- Don't skip validation
- Don't hide error messages
- Don't submit without user action
- Don't freeze UI during operations

## Performance Metrics

### Target Metrics
- **Balance Load Time**: < 1 second
- **Form Validation**: Instant (< 100ms)
- **Transaction Submit**: < 2 seconds
- **UI Responsiveness**: 60 FPS

### Optimization Tips
1. Cache balance locally
2. Debounce validation
3. Lazy load categories
4. Use indexed queries
5. Minimize re-renders

---

**Document Version**: 1.0.0

**Last Updated**: November 12, 2025

**Maintained By**: Money Control Development Team
