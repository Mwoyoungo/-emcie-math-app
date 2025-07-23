# 🌟 Emcie - E=mc² Energy for Math

**An AI-powered mathematics learning assistant app built with Flutter, featuring chat-based tutoring, performance tracking, and professional tutor integration.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

## ✨ Features

### 🤖 AI-Powered Chat Tutoring
- **Mam Rose AI Tutor**: Interactive chat-based learning with personalized assessment
- **LaTeX Math Support**: Proper mathematical notation rendering
- **CAPS Curriculum Aligned**: South African Grade 10-12 mathematics curriculum
- **Image Upload**: Take photos or upload math problems for analysis

### 📊 Performance Tracking
- **Real-time Analytics**: Track questions answered, correct/wrong answers, and accuracy
- **Topic-based Progress**: Individual performance tracking for 10 CAPS mathematics topics
- **Gamified Badges**: Performance-based achievement system
- **Visual Progress**: Interactive charts and progress indicators

### 👨‍🏫 Professional Tutor Integration
- **WhatsApp-style Call Button**: Easy access to professional tutors
- **Smart Triggers**: Automatic tutor suggestions based on performance
- **Pricing Tiers**: Quick Help ($8) and Deep Sessions ($25-50)
- **Keyword Detection**: AI detects when students need help

### 📱 Responsive Design
- **Mobile-first**: Optimized touch interface for smartphones
- **Tablet Layout**: Enhanced side panels and better spacing
- **Desktop Experience**: Professional dashboard with persistent navigation
- **Web-ready**: Fully responsive across all screen sizes

### 🔐 Authentication & Roles
- **Supabase Auth**: Secure user authentication
- **Role-based Access**: Student and Teacher accounts
- **Profile Management**: Comprehensive user profiles
- **Data Privacy**: Row-level security policies

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.5.0)
- Dart SDK
- Android Studio / VS Code
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/emcie-math-app.git
   cd emcie-math-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Supabase**
   - Create a project at [Supabase](https://supabase.com)
   - Copy `lib/config/supabase_config.template.dart` to `lib/config/supabase_config.dart`
   - Add your Supabase URL and anon key
   - Run the SQL schema from the template file

4. **Run the app**
   ```bash
   flutter run
   ```

### Web Deployment
```bash
flutter build web
# Deploy the build/web folder to your hosting platform
```

## 🎯 Core Modules

### 📚 Topics Covered
1. Functions (Linear, Quadratic, Exponential & Trigonometric)
2. Number Patterns, Sequences & Series
3. Algebra (Equations, Inequalities & Manipulation)
4. Finance, Growth & Decay
5. Trigonometry
6. Analytical Geometry
7. Statistics
8. Probability
9. Calculus
10. Euclidean Geometry

### 🏗️ Architecture
```
lib/
├── screens/           # UI screens
│   ├── auth/         # Authentication flows
│   ├── chat/         # AI tutoring interface
│   ├── home/         # Topic selection
│   ├── progress/     # Performance analytics
│   └── entryPoint/   # Navigation
├── services/         # Business logic
│   ├── ai_service.dart
│   ├── supabase_service.dart
│   ├── performance_service.dart
│   └── chat_session_service.dart
├── utils/           # Utilities
│   ├── responsive_utils.dart
│   └── rive_utils.dart
└── config/          # Configuration
    └── supabase_config.dart
```

## 🔧 Technologies Used

- **Frontend**: Flutter, Dart
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **AI Integration**: FlowiseAI API
- **Animations**: Rive
- **Math Rendering**: flutter_math_fork
- **State Management**: Provider
- **Image Handling**: image_picker

## 🎨 Design System

### Colors
- **Primary Purple**: `#7553F6`
- **Success Green**: `#4ECDC4`
- **Warning Red**: `#FF6B6B`
- **Info Blue**: `#80A4FF`
- **Background**: `#EEF1F8`

### Typography
- **Primary Font**: Intel
- **Headers**: Poppins (Bold)
- **Math**: LaTeX rendering

## 📈 Performance Features

### Smart Triggers
- **3 Wrong Answers**: Automatic tutor popup
- **Gamified Badges**: Access after 3 questions
- **Keyword Detection**: Help request recognition
- **WhatsApp-style Access**: Always-available call button

### Analytics
- **Session Persistence**: Conversations saved across app restarts
- **Real-time Tracking**: Live performance updates
- **Topic Insights**: Detailed performance per mathematics topic

## 🔒 Security & Privacy

- **Row Level Security**: Database access controls
- **Secure Authentication**: Supabase auth with JWT
- **Data Encryption**: All communications encrypted
- **No Credential Exposure**: Template-based configuration

## 🌐 Web Optimization

### Responsive Breakpoints
- **Mobile**: < 600px (single column)
- **Tablet**: 600-1200px (two columns)
- **Desktop**: > 1200px (three columns + sidebar)

### Performance
- **Lazy Loading**: Efficient component rendering
- **Adaptive Layouts**: Screen-size optimized interfaces
- **Touch & Mouse**: Dual input support

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **CAPS Curriculum**: South African Department of Education
- **Rive**: Beautiful micro-interactions
- **Supabase**: Backend-as-a-Service platform
- **Flutter Community**: Excellent packages and support

## 📞 Support

For support, email support@emcie.app or join our community Discord.

---

**Built with ❤️ for South African mathematics students**