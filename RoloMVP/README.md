# Rolo - Personal CRM

A personal CRM that surfaces news and nudges to help you maintain meaningful connections with your network.

## ✨ Features

- 📇 **Contact Management** - Full CRUD with tags, priorities, and relationship tracking
- 🤖 **AI Assistant** - Context-aware AI chat for each contact powered by OpenAI
- 📝 **Notes & Reminders** - Track interactions and set follow-up reminders
- 📰 **News Feed** - Stay updated with your network (coming soon)
- 🏷️ **Smart Tagging** - Organize contacts with priority-based tags

## 🛠️ Tech Stack

- **iOS:** SwiftUI + MVVM architecture
- **Backend:** Supabase (PostgreSQL + Auth + Edge Functions)
- **AI:** OpenAI GPT-4o-mini via Supabase Edge Functions
- **State Management:** `@MainActor` ViewModels
- **Services:** Protocol-based async/await architecture

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd RoloMVP/RoloMVP
   ```

2. **Setup configuration**
   ```bash
   cp Resources/Config.xcconfig.template Resources/Config.xcconfig
   # Edit Config.xcconfig with your Supabase credentials
   ```

3. **Open in Xcode**
   ```bash
   open RoloMVP.xcodeproj
   ```

4. **Run the app**
   - Select a simulator or device
   - Press **Cmd+R**

📖 **For detailed setup instructions, see [SETUP.md](SETUP.md)**

📘 **For architecture details, see [Overview.md](Overview.md)**

## 📁 Project Structure

```
RoloMVP/
├── App/                    # App entry point and configuration
├── Core/
│   ├── Models/            # Database models
│   ├── DTOs/              # Data transfer objects
│   ├── Services/          # API services (Supabase + AI)
│   └── Utilities/         # Logging, errors, formatters
├── Features/              # MVVM feature modules
│   ├── Auth/             # Authentication
│   ├── Contacts/         # Contact management + AI chat
│   ├── Home/             # Dashboard
│   ├── News/             # News feed
│   └── Profile/          # User settings
├── SharedUI/
│   ├── Components/       # Reusable UI components
│   └── Theme/            # Colors, typography
└── Resources/            # Assets and configuration
```

## 🔐 Security

- **API keys** are stored in `Config.xcconfig` (gitignored)
- **OpenAI keys** are stored in Supabase secrets (never in client)
- **RLS policies** enforce data isolation per user

## 🤝 Contributing

1. Make sure you've read [SETUP.md](SETUP.md)
2. Create a feature branch
3. Make your changes (see guidelines below)
4. Submit a pull request

### Development Guidelines

- **UI Changes:** Update files in `/Features/[Feature]/Views/` and `/SharedUI/`
- **Logic Changes:** Update ViewModels and Services
- **Never touch:** API keys, secrets, or commit `Config.xcconfig`

## 📄 License

[Your License Here]

## 👥 Team

[Your Team Info Here]

