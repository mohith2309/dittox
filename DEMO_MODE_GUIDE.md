# Demo Mode Testing Guide

## 🎭 What is Demo Mode?

Demo mode allows you to test the app without:
- Real backend API calls
- Real payment processing (Razorpay)
- User authentication

## 🚀 How to Activate

Set `accessToken` to `"demo_token"` when navigating:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (ctx) => SelectShops(accessToken: "demo_token"),
  ),
);
```

Or in your auth flow, store `"demo_token"` in SharedPreferences.

---

## 📍 Demo Shops Available

When in demo mode, 3 shops are automatically injected in **Bangalore**:

| Shop | Location | Price Range | Rating |
|------|----------|-------------|--------|
| **Demo Xerox Shop - MG Road** | MG Road | ₹1-30 | ⭐ 4.5 |
| **Demo Digital Prints - Koramangala** | Koramangala | ₹0.8-25 | ⭐ 4.8 |
| **Demo Express Prints - Indiranagar** | 100 Feet Road | ₹1.2-35 | ⭐ 4.2 |

### Map Location
- **Center**: Bangalore (12.9716, 77.5946)
- **Zoom**: Level 12 (city view)

---

## 💳 Payment Flow in Demo Mode

### Step 1: Select Shop
- Map shows 3 demo shop markers
- Carousel at bottom lets you swipe between shops
- Tap "Proceed" on any shop

### Step 2: Demo Confirmation Dialog
```
┌─────────────────────────────┐
│  Demo Mode                  │
│                             │
│  Selected: Demo Xerox Shop  │
│  Cost: ₹150.00              │
│                             │
│  ┌─────────────────────────┐│
│  │ In demo mode, payment ││
│  │ will be bypassed...   ││
│  └─────────────────────────┘│
│                             │
│  [Cancel]    [Continue]     │
└─────────────────────────────┘
```

### Step 3: Summary Screen
- Shows your PDFs
- Shows selected shop
- Two buttons:
  - **"Pay Later"** → Mock success
  - **"Pay Now"** → Mock payment success

### Step 4: Mock Payment Dialog
```
┌─────────────────────────────┐
│  ✅ Demo Mode                 │
│                             │
│  Demo payment successful!   │
│                             │
│  ┌─────────────────────────┐│
│  │ This is a demo. No    ││
│  │ real payment was      ││
│  │ processed.            ││
│  └─────────────────────────┘│
│                             │
│           [Continue]        │
└─────────────────────────────┘
```

---

## 🔧 Files Added/Modified

### New Files:
1. **`lib/utils/demo_data.dart`** - Demo shops and mock responses
2. **`lib/screens/maps/selectShops_optimized.dart`** - Multiple demo shops support
3. **`lib/screens/additional/summaryScreen_optimized.dart`** - Payment bypass

### Demo Shop Model:
Each demo shop includes:
- Full pricing (sides, colors, paper sizes, binding)
- Location coordinates
- Opening/closing hours
- Rating
- Contact info

---

## 🧪 Testing Checklist

### Map Screen
- [ ] Demo badge shows in top-left
- [ ] Map centers on Bangalore
- [ ] 3 shop markers visible
- [ ] Swipe carousel updates map position
- [ ] Tap marker selects shop in carousel
- [ ] "Proceed" button opens demo dialog

### Summary Screen
- [ ] PDFs listed correctly
- [ ] Selected shop info shown
- [ ] "Pay Later" works → shows success
- [ ] "Pay Now" works → shows demo payment dialog
- [ ] Dialog shows "This is a demo" warning
- [ ] Continue navigates to home

### Edge Cases
- [ ] No PDFs in cart → handles gracefully
- [ ] Rapid button clicks → debounced
- [ ] Back button → returns to shop selection

---

## 🎨 Customizing Demo Data

Edit `lib/utils/demo_data.dart`:

```dart
// Add more shops
static List<Shop> getDemoShops() {
  return [
    // Existing shops...
    Shop(
      id: "demo_shop_4",
      name: "My Custom Shop",
      address: "Custom Address",
      locationX: 12.9000,  // Your latitude
      locationY: 77.6000,  // Your longitude
      // ... pricing
    ),
  ];
}
```

---

## 🔍 Identifying Demo Mode in Code

```dart
import 'utils/demo_data.dart';

// Check if in demo mode
if (DemoData.isDemoMode(accessToken)) {
  // Use mock data
  final shops = DemoData.getDemoShops();
  final response = DemoData.getMockOrderResponse();
}
```

---

## 📱 Visual Indicators

| Screen | Indicator |
|--------|-----------|
| **Map** | "DEMO MODE" badge (amber chip) |
| **Summary** | "Pay Now" shows demo dialog |
| **Payment** | Dialog with amber warning box |

---

## ⚠️ Important Notes

1. **Demo mode is NOT production** - Never ship with demo_token hardcoded
2. **No real orders** - Everything is local/mock
3. **No real money** - Payment is completely simulated
4. **State resets** - Demo orders aren't persisted

---

## 🔄 Switching to Production

Change from:
```dart
accessToken: "demo_token"
```

To:
```dart
accessToken: realAccessToken  // From auth/login
```

---

**Happy Testing!** 🦾
