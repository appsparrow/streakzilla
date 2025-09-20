# 🏆 Streakzilla - Cross-Platform Habit Tracker

A React Native + Expo app that works on iOS, Android, and Web. Build better habits with friends using the 75 Hard challenge or custom streaks.

## ✨ Features

- 📱 **Cross-Platform**: One codebase for iOS, Android, and Web
- 🔐 **Authentication**: Secure user accounts with Supabase Auth
- 🎯 **Streak Creation**: Create 75 Hard, custom, or open-ended challenges
- 👥 **Social**: Join streaks with friends using invite codes
- 📊 **Progress Tracking**: Visual 75-circle tracker with day states
- ❤️ **Lives System**: 3 lives per streak for missed days
- 📸 **Photo Uploads**: Daily progress photos (coming soon)
- 🏅 **Streakmates**: See your friends' progress and support each other

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Expo CLI: `npm install -g @expo/cli`
- iOS Simulator (for iOS testing)
- Android Studio (for Android testing)

### Installation

1. **Clone and install dependencies**:
   ```bash
   git clone <your-repo>
   cd streakzilla
   npm install
   ```

2. **Set up Supabase Database**:
   - Copy the SQL from `database-setup.sql` (coming soon)
   - Run it in your Supabase SQL Editor
   - This creates all tables, RLS policies, and functions

3. **Start the development server**:
   ```bash
   npm start
   ```

4. **Choose your platform**:
   - Press `i` for iOS Simulator
   - Press `a` for Android Emulator  
   - Press `w` for Web Browser
   - Or scan QR code with Expo Go app

## 📱 Platform Support

### iOS
- Native iOS app via Expo
- Full feature support
- App Store ready

### Android  
- Native Android app via Expo
- Full feature support
- Google Play Store ready

### Web
- Progressive Web App via react-native-web
- Responsive design
- Deployable to any web host

## 🛠 Development

### Project Structure

```
streakzilla/
├── App.tsx                 # Main app component with navigation
├── context/               # React contexts (Auth)
├── screens/              # App screens
│   ├── LoginScreen.tsx
│   ├── HomeScreen.tsx
│   └── ...
├── components/           # Reusable UI components
│   └── ui/              # Base UI components
├── lib/                 # Utilities and configuration
│   ├── supabase.ts     # Supabase client setup
│   └── database.types.ts # TypeScript types
└── web-build/          # Web build output for deployment
```

### Key Technologies

- **React Native + Expo**: Cross-platform mobile development
- **React Native Web**: Web support from same codebase
- **NativeWind**: Tailwind CSS for React Native
- **React Navigation**: Navigation for mobile apps
- **Supabase**: Backend-as-a-Service (Auth + Database)
- **TypeScript**: Type safety and better DX

## 🚀 Deployment

### Mobile Apps

```bash
# Build for app stores
eas build --platform all

# Submit to stores
eas submit --platform all
```

### Web App (Cloudflare Pages)

1. **Build the app**:
   ```bash
   npm run build:deploy
   ```

2. **Deploy to Cloudflare Pages**:
   - Push your code to GitHub
   - Connect your repo to Cloudflare Pages
   - Set build command: `npm run build:deploy`
   - Set build output directory: `web-build`
   - Set Node.js version: `18.x` or `20.x`

3. **Environment Variables** (if needed):
   - Add any required environment variables in Cloudflare Pages settings

### Build Configuration

The app is configured with:
- ✅ **Webpack bundler** for web deployment
- ✅ **Crypto polyfills** disabled for browser compatibility
- ✅ **Static file generation** in `web-build/` directory
- ✅ **Cloudflare Pages** compatible headers and redirects

## 📋 TODO

- [ ] Complete all screen implementations
- [ ] Add photo upload with Cloudflare R2
- [ ] Implement push notifications
- [ ] Add streak leaderboards
- [ ] Create admin controls
- [ ] Add subscription system
- [ ] Implement offline support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on all platforms
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For questions or issues:

1. Check the GitHub issues
2. Create a new issue with detailed description
3. Include platform and error details

---

**Built with ❤️ for habit builders everywhere**