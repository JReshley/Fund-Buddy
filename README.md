# FuBu - Fund Buddy 💰

> A mobile finance tracker for student organizations, built with Flutter and Supabase.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)

---

## 📖 About The Project

### The Problem
Student organizations at universities (like Holy Angel University) currently use **manual spreadsheets and paper logs** for financial tracking. This approach is:
- ⚠️ **Inefficient** - Time-consuming manual data entry
- ❌ **Error-prone** - High risk of calculation mistakes
- 📊 **Audit challenges** - Hard to prepare organized financial reports

### The Solution
**Fund Buddy** is a mobile-first application that provides a **centralized, secure, and collaborative platform** for managing student organization finances. It streamlines data entry, enhances accuracy, and provides a real-time view of the organization's financial health—making financial management accessible, transparent, and efficient.

---

## ✨ Key Features

### 📝 Transaction Management
- Full **CRUD operations** (Create, Read, Update, Delete) for financial records
- Track both **inflows (receipts)** and **outflows (disbursements)**
- Detailed transaction history with search and sort capabilities
- Attach receipt images to transactions for audit trails

### 🤖 AI-Powered Receipt Scanning
- Leverages **Google Gemini API** for intelligent receipt analysis
- Automatically extracts key details:
  - Seller name
  - Receipt control number
  - Total amount
  - Transaction date (formatted as YYYY-MM-DD)
  - Item description
- Reduces manual data entry by ~90%

### 📊 Real-time Dashboard
- Visual overview of organization's financial health
- Live calculations of:
  - Total receipts (inflows)
  - Total disbursements (outflows)
  - Net balance
- Updates automatically via Supabase real-time subscriptions

### 🏢 Organization Management
- Multi-user support for collaborative finance tracking
- **Role-based access control**:
  - **Admins**: Full access to edit org details, add/remove members, manage all transactions
  - **Members**: View transactions and add new entries
- Create or join existing organizations

### 🔐 Secure Authentication
- Email/password sign-up and login
- **Google OAuth** integration for seamless authentication
- Password reset functionality with deep link handling
- Secure credential storage using Flutter Secure Storage
- Powered by **Supabase Auth**

### 🌙 Dark Mode
- User-friendly dark theme toggle
- Theme preference persisted across sessions
- Consistent styling across all screens

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language

### Backend & Database
- **Supabase** - Backend-as-a-Service platform
  - PostgreSQL database for data storage
  - Auth for user authentication
  - Real-time subscriptions for live updates
  - Storage for receipt images

### AI & External Services
- **Google Gemini API** - AI-powered receipt text extraction (Gemini 2.0 Flash Lite model)

### Design & Tools
- **Figma** - UI/UX design and prototyping
- **VS Code** - Primary development IDE
- **Git & GitHub** - Version control

---

## 🚀 Getting Started

Follow these instructions to set up Fund Buddy on your local machine.

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (latest stable version)
  ```bash
  # Check Flutter installation
  flutter doctor
  ```
- **Dart SDK** (comes with Flutter)
- **VS Code** or **Android Studio** with Flutter plugins
- **Git** for version control
- A physical device or emulator for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/JReshley/FundBuddy.git
   cd FundBuddy
   ```

2. **Set up Supabase**
   - Create a new project at [Supabase](https://supabase.com/)
   - Navigate to **Settings > API** to get your:
     - Project URL
     - Anon/Public Key
   - Set up your database schema:
     - Go to **SQL Editor** in Supabase dashboard
     - Run the schema SQL file (if provided in `database/schema.sql`)
     - Create the following tables:
       - `user` (id, username, email, firstName, lastName, fullName, orgID, profileImageUrl)
       - `organizations` (organizationID, orgName, description, logoUrl, abbreviation)
       - `transactions` (transactionID, userID, sellerName, amount, date, typeOfActivity, description, etc.)

3. **Get Google Gemini API Key**
   - Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create a new API key for Gemini API
   - Copy the key for the next step

4. **Create Environment File**
   
   Create a `.env` file in the project root directory:
   ```bash
   # .env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_gemini_api_key
   ```

   ⚠️ **Important:** Never commit your `.env` file to Git! It's already in `.gitignore`.

5. **Install Dependencies**
   ```bash
   flutter pub get
   ```

6. **Run the Application**
   
   For development:
   ```bash
   flutter run
   ```
   
   For release build:
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

### Configuration Notes

- **Deep Links**: For password reset functionality, configure deep links in:
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`
  - Use the scheme: `fundbuddy://`

- **Google OAuth**: 
  - Add your Android SHA-1 certificate fingerprint to Supabase dashboard
  - Configure OAuth redirect URLs in Supabase Auth settings

---

## 👥 Meet The Team

| Name | Role | Responsibilities |
|------|------|------------------|
| **John Reshley Gonzales** | Project Manager & Backend Developer | Transaction management, API integration, database architecture |
| **Mark Harold Valderrama** | Backend Developer | User authentication, Supabase setup, security implementation |
| **Keith Ryan Almanzor** | UI/UX Designer | Interface design, user experience, Figma prototyping |
| **Randel Angelo Yumul** | Lead Frontend Developer | Flutter implementation, UI components, state management |

---

## 📁 Project Structure

```
fund_buddy/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── supabase_config.dart         # Supabase configuration
│   ├── entity/                      # Data models
│   │   ├── user_profile.dart
│   │   ├── organization.dart
│   │   ├── transaction.dart
│   │   ├── transaction_database.dart
│   │   └── organization_database.dart
│   ├── gemini_api/                  # AI service integration
│   │   ├── gemini_client.dart
│   │   └── gemini_service.dart
│   └── pages/                       # UI screens
│       ├── opening_page.dart
│       ├── login_page.dart
│       ├── signup_page.dart
│       ├── dashboard.dart
│       ├── home_page.dart
│       ├── transactions_page.dart
│       ├── profile_page.dart
│       └── widgets/                 # Reusable components
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
├── .env                            # Environment variables (not in repo)
├── pubspec.yaml                    # Dependencies
└── README.md                       # This file
```

---

## 🧪 Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```

---

## 🔒 Security & Privacy

- **Environment Variables**: Sensitive API keys are stored in `.env` and never committed to version control
- **Secure Storage**: User credentials use Flutter Secure Storage
- **Row Level Security**: Supabase RLS policies ensure users only access their organization's data
- **Authentication**: Supabase Auth provides secure, token-based authentication
- **HTTPS**: All API communications use encrypted HTTPS connections

---

## 🐛 Known Issues & Limitations

- Zero-amount transactions are currently allowed (should be validated)
- Concurrent edits to organization details may cause data overwrites (no conflict resolution)
- Gemini API errors show technical messages (need user-friendly alternatives)
- Receipt scanning accuracy depends on image quality and receipt format

---

## 🗺️ Roadmap

- [ ] Add expense categories and budgeting features
- [ ] Generate PDF reports for audits
- [ ] Multi-language support (English, Filipino)
- [ ] Push notifications for transaction approvals
- [ ] Export transactions to Excel/CSV
- [ ] Biometric authentication (fingerprint/face ID)
- [ ] Offline mode with sync capability

---

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute to Fund Buddy:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please ensure your code follows the project's coding standards and includes appropriate tests.

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Fund Buddy Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Contact & Support

For questions, suggestions, or issues:

- **GitHub Issues**: [Open an issue](https://github.com/JReshley/FundBuddy/issues)
- **Email**: [Contact the team](mailto:fundbuddy.team@example.com)
- **Documentation**: [Wiki](https://github.com/JReshley/FundBuddy/wiki)

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - Amazing cross-platform framework
- [Supabase](https://supabase.com/) - Powerful open-source Firebase alternative
- [Google Gemini](https://ai.google.dev/) - AI-powered receipt scanning
- All students who provided feedback during development

---

<div align="center">

**Made by the Fund Buddy Team**

</div>
