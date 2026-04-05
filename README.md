# Clothy - Modern Flutter Clothing App

A beautiful and modern clothing shopping app built with Flutter, featuring smooth animations, clean UI, and comprehensive functionality.

## ✨ Features

### 🎨 Design & UI
- **Modern Material 3 Design** with Cairo font via Google Fonts
- **Light & Dark Theme** support with smooth transitions
- **Smooth Animations** throughout the app using custom AnimationControllers
- **Responsive Design** that works on all screen sizes
- **Clean & Flat Design** with consistent padding and rounded corners

### 📱 Screens & Navigation
- **Onboarding Screen** - 3-step introduction with smooth page indicators
- **Authentication** - Login/Register with form validation and Google login option
- **Home Screen** - Modern design with bottom navigation, product grid, and categories
- **Product Details** - Hero transitions, size/color selection, quantity control
- **Shopping Cart** - Provider-based state management with quantity controls
- **Checkout** - Complete order flow with address and payment options
- **Order Complete** - Success animation with confetti effect
- **Profile** - User settings, dark mode toggle, and account management

### 🛍️ Shopping Features
- **Product Browsing** with grid layout and search functionality
- **Product Filtering** by categories and favorites
- **Size & Color Selection** with animated UI components
- **Shopping Cart** with add/remove/update quantity functionality
- **Checkout Process** with address input and payment method selection
- **Order Tracking** with order number and status updates

### 🔧 Technical Features
- **State Management** using Provider pattern
- **Navigation** using GoRouter for smooth page transitions
- **Custom Animations** for enhanced user experience
- **Form Validation** for all input fields
- **Error Handling** with user-friendly messages
- **Theme Management** with light/dark mode toggle

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd clothy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2          # State management
  google_fonts: ^6.2.1      # Cairo font
  go_router: ^14.2.7        # Navigation
  flutter_svg: ^2.0.10+1    # SVG support
  smooth_page_indicator: ^1.1.0  # Page indicators
  iconsax: ^0.0.8           # Beautiful icons
  cupertino_icons: ^1.0.8   # iOS style icons
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point and routing
├── theme.dart               # Light & dark themes
├── models/
│   └── product.dart         # Product model and sample data
├── providers/
│   ├── cart_provider.dart   # Shopping cart state management
│   └── theme_provider.dart  # Theme switching logic
└── screens/
    ├── onboarding_screen.dart    # 3-step onboarding
    ├── auth_screen.dart          # Login/Register
    ├── home_screen.dart          # Main home with bottom nav
    ├── product_detail_screen.dart # Product details with hero animation
    ├── checkout_screen.dart      # Checkout process
    ├── order_complete_screen.dart # Order confirmation
    └── profile_screen.dart       # User profile and settings
```

## 🎯 Key Components

### State Management
- **CartProvider**: Manages shopping cart items, quantities, and totals
- **ThemeProvider**: Handles light/dark theme switching

### Navigation
- **GoRouter**: Provides smooth page transitions and named routes
- **Hero Animations**: Smooth transitions between product list and details

### UI Components
- **Custom Cards**: Rounded corners with consistent elevation
- **Animated Buttons**: Scale and fade animations on interaction
- **Form Validation**: Real-time validation with error messages
- **Loading States**: Smooth loading animations for better UX

### Animations
- **Page Transitions**: Smooth slide and fade animations
- **Success Animations**: Confetti effect on order completion
- **Micro Interactions**: Button press feedback and transitions

## 🎨 Design System

### Colors
- **Primary**: #0A8F8F (Teal)
- **Secondary**: #6C63FF (Purple)
- **Background**: White/Dark based on theme
- **Surface**: #F8F9FA/Dark surface

### Typography
- **Font Family**: Cairo (Google Fonts)
- **Consistent sizing** across all text elements
- **Proper hierarchy** with different font weights

### Spacing
- **Consistent padding**: 16px, 24px, 32px
- **Rounded corners**: 12px, 16px for different elements
- **Proper margins** between UI components

## 🔮 Future Enhancements

- [ ] **Real API Integration** for products and user authentication
- [ ] **Push Notifications** for order updates
- [ ] **Search & Filters** for better product discovery
- [ ] **Reviews & Ratings** system
- [ ] **Wishlist/Favorites** functionality
- [ ] **Order History** and tracking
- [ ] **Multiple Payment Methods** integration
- [ ] **Social Media Login** options
- [ ] **Multi-language Support**
- [ ] **Offline Support** with local storage

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

Built with ❤️ using Flutter

---

**Happy Coding!** 🚀
