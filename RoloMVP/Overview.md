# Rolo - Personal CRM

Rolo is a personal CRM that surfaces news and nudges to help you maintain meaningful connections with your network.

## Architecture

**Tech Stack:**
- SwiftUI + MVVM architecture
- `@MainActor` ViewModels for thread-safe state management
- Supabase backend (PostgreSQL + Auth + Realtime + Edge Functions)
- OpenAI integration via Supabase Edge Functions (gpt-4o-mini)
- Fully integrated service layer with async API calls
- Protocol-based services for testability

**Project Structure:**
```
RoloMVP/
├── App/                     # App entry point and global state
│   ├── RoloApp.swift       # Main app with TabView navigation
│   ├── AppState.swift      # Global app state (onboarding, deep links)
│   └── Environment/        # Configuration and providers
├── Core/                   # Business logic and data
│   ├── Models/             # Codable models matching DB schema
│   ├── DTOs/               # Encodable DTOs for create/update operations
│   ├── Services/           # Fully integrated async service layer
│   └── Utilities/          # Logging, error handling, formatters
├── Features/               # Feature modules (MVVM)
│   ├── Auth/               # Authentication (sign up, sign in, password reset)
│   ├── Home/               # Dashboard with quick actions
│   ├── Contacts/           # Full CRUD with sheets for create/edit
│   ├── Chat/               # AI assistant (placeholder)
│   ├── News/               # Network news feed
│   └── Profile/            # Settings and user profile
├── SharedUI/               # Reusable components and theme
│   ├── Components/         # AvatarView, TagPill, buttons, etc.
│   └── Theme/              # Colors and typography
└── Resources/              # Assets and config
    ├── Assets.xcassets     # Images and colors
    └── Config.xcconfig     # Environment variables
```

## ✅ Completed Features (v1.0)

### Authentication
- ✅ Email/password sign up with validation
- ✅ Email/password sign in
- ✅ Password reset flow
- ✅ Session persistence (stay logged in)
- ✅ Sign out functionality
- ✅ Custom URL scheme for deep links (`rolo://`)

### 1. Home
- ✅ Welcome header
- ✅ Quick action to open contacts
- ✅ Recent news preview (placeholder, ready for data)
- 🔄 Upcoming reminders section (coming soon)

### 2. Contacts List
- ✅ Searchable list of all contacts
- ✅ Each row shows: avatar, name, company/position, relationship priority indicator, last interaction date
- ✅ Pull-to-refresh to reload data
- ✅ Empty state with "Add Contact" action
- ✅ Create new contact sheet with full form

### 3. Contact Detail
- ✅ Header: avatar, name, company/position
- ✅ Edit button to modify contact information
- ✅ Segmented control with 5 tabs:
  - **Info**: 
    - ✅ Tag management with priority (1-10)
    - ✅ Relationship priority slider
    - ✅ LinkedIn link
    - ✅ Last interaction date
    - ✅ Relationship summary
  - **Notes**: 
    - ✅ List of notes chronologically
    - ✅ Add note sheet with meeting checkbox
    - ✅ Optional occurred_at timestamp
  - **Reminders**: 
    - ✅ List of reminders with due dates
    - ✅ Add reminder sheet
    - ✅ Optional due date picker
    - ✅ Quick actions (Next Week, Next Month)
  - **News**: 
    - ✅ Ready for news items from database
  - **AI**: 
    - ✅ Context-aware AI chat per contact
    - ✅ Ask questions about relationship, get suggestions
    - ✅ "Add as Note" button (saves with source='ai_chat')
    - ✅ "Create Reminder" button (saves with origin_type='chat')
    - ✅ Full chat history stored in database

### 4. AI Chat (Per-Contact)
- ✅ Contact-scoped AI assistant powered by OpenAI (gpt-4o-mini)
- ✅ Fetches skinny context (tags, notes, reminders, news) for each contact
- ✅ Supabase Edge Function handles context assembly + OpenAI API calls
- ✅ Chat history persisted to `contact_chat_messages` table
- ✅ Action buttons: "Add as Note" and "Create Reminder"
- ✅ Secure: API key stored in Supabase secrets, never in iOS app

### 5. News Feed
- ✅ Basic news view structure
- 🔄 News fetching integration (planned)

### 6. Profile
- ✅ User info display
- ✅ Settings placeholders
- ✅ Functional sign out button

## 🎨 UI Components Built

### Reusable Components
- **AvatarView**: Circle avatar with initials fallback
- **TagPill**: Colored tag badges with priority-based colors
- **PrimaryButton**: Consistent button styling with loading states
- **EmptyStateView**: Empty states with icons and actions
- **LoadingView**: Spinner with customizable message
- **FlowLayout**: Wrapping layout for tags (like CSS flexbox)

### Forms & Sheets
- **NewContactSheet**: Full contact creation form
- **EditContactSheet**: Edit contact basic info and relationship
- **ManageTagsSheet**: Add/remove/create tags with priorities
- **AddNoteSheet**: Create notes with meeting flag and date
- **AddReminderSheet**: Create reminders with optional due dates

### Theme
- **Colors**: Priority-based color system (1-10 scale)
- **Typography**: Consistent font styles and modifiers

## Database Schema

All tables use snake_case column names. Models use CodingKeys to map to/from Swift's camelCase.

### contacts
| Column                  | Type          | Notes              |
|-------------------------|---------------|--------------------|
| id                      | UUID          | PK                 |
| user_id                 | UUID          | FK to auth.users   |
| full_name               | text          |                    |
| photo_url               | text          | nullable           |
| position                | text          | nullable           |
| company_name            | text          | nullable           |
| linkedin_url            | text          | nullable           |
| relationship_summary    | text          | nullable           |
| relationship_priority   | integer       | 1-10 scale         |
| last_interaction_at     | timestamptz   | nullable           |
| created_at              | timestamptz   |                    |
| updated_at              | timestamptz   |                    |

### tags
| Column       | Type        | Notes              |
|--------------|-------------|--------------------|
| id           | UUID        | PK                 |
| user_id      | UUID        | FK to auth.users   |
| name         | text        |                    |
| slug         | text        | nullable           |
| description  | text        | nullable           |
| created_at   | timestamptz |                    |
| updated_at   | timestamptz |                    |

### contact_tags
| Column         | Type        | Notes                    |
|----------------|-------------|--------------------------|
| contact_id     | UUID        | PK, FK to contacts       |
| tag_id         | UUID        | PK, FK to tags           |
| priority       | smallint    |                          |
| color_override | text        | nullable (hex color)     |
| created_at     | timestamptz |                          |
| updated_at     | timestamptz |                          |

### contact_notes
| Column       | Type        | Notes                        |
|--------------|-------------|------------------------------|
| id           | UUID        | PK                           |
| contact_id   | UUID        | FK to contacts               |
| user_id      | UUID        | FK to auth.users             |
| title        | text        |                              |
| content      | text        |                              |
| source       | text        | 'manual' \| 'ai_chat'        |
| is_meeting   | boolean     |                              |
| occurred_at  | timestamptz | nullable                     |
| created_at   | timestamptz |                              |
| updated_at   | timestamptz |                              |

### contact_reminders
| Column       | Type        | Notes                                    |
|--------------|-------------|------------------------------------------|
| id           | UUID        | PK                                       |
| contact_id   | UUID        | FK to contacts                           |
| user_id      | UUID        | FK to auth.users                         |
| body         | text        |                                          |
| due_at       | timestamptz | nullable                                 |
| source       | text        | 'manual' \| 'ai_suggested', default 'manual' |
| origin_type  | text        | nullable: 'note' \| 'chat' \| 'system'   |
| origin_id    | UUID        | nullable                                 |
| created_at   | timestamptz |                                          |
| updated_at   | timestamptz |                                          |

### contact_news
| Column       | Type        | Notes              |
|--------------|-------------|--------------------|
| id           | UUID        | PK                 |
| contact_id   | UUID        | FK to contacts     |
| source       | text        | e.g., 'LinkedIn'   |
| title        | text        |                    |
| url          | text        |                    |
| summary      | text        |                    |
| published_at | timestamptz |                    |
| fetched_at   | timestamptz |                    |
| topics       | text[]      | nullable array     |
| created_at   | timestamptz |                    |

### contact_chat_messages
| Column           | Type        | Notes                           |
|------------------|-------------|---------------------------------|
| id               | UUID        | PK                              |
| contact_id       | UUID        | FK to contacts                  |
| user_id          | UUID        | FK to auth.users                |
| role             | text        | 'user' \| 'assistant'           |
| content          | text        | Message text                    |
| context_snapshot | jsonb       | nullable (context sent to AI)   |
| created_at       | timestamptz |                                 |

## Setup Instructions

### 1. Install Dependencies

This project uses Supabase for backend. To integrate:

```bash
# Add Supabase Swift SDK via Swift Package Manager in Xcode
# URL: https://github.com/supabase/supabase-swift
```

### 2. Configure Supabase

1. Create a Supabase project at https://supabase.com
2. Copy your project URL and anon key
3. Open `Resources/Config.xcconfig` and replace placeholders:
   ```
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-actual-anon-key
   ```
4. In Xcode Project Settings → Info → Configurations, set `Config.xcconfig` for Debug and Release
5. In Build Settings, ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are defined
6. Add these keys to your `Info.plist`:
   ```xml
   <key>SUPABASE_URL</key>
   <string>$(SUPABASE_URL)</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>$(SUPABASE_ANON_KEY)</string>
   ```

### 3. Deploy Edge Functions & Set Secrets

The AI chat feature requires a Supabase Edge Function:

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login and link project
supabase login
cd supabase
supabase link --project-ref your-project-ref

# Set OpenAI API key secret
# Go to Supabase Dashboard → Settings → Edge Functions → Secrets
# Add: OPENAI_API_KEY = sk-proj-...

# Deploy the contact-chat function
supabase functions deploy contact-chat
```

### 4. Run the App

1. Open `RoloMVP.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

The app will start at the authentication screen if not signed in, then proceed to the main `TabView` with Home, Contacts, Chat, News, and Profile tabs.

## 🚀 Services Fully Integrated

All services are connected to Supabase with complete CRUD operations:

### ContactsService
- ✅ `fetchContacts()` - List with search & pagination
- ✅ `getContact()` - Get single contact
- ✅ `createContact()` - Create new contact
- ✅ `updateContactBasicInfo()` - Update name, company, position, LinkedIn
- ✅ `updateContactRelationship()` - Update summary and priority
- ✅ `deleteContact()` - Delete contact

### TagsService
- ✅ `listTags()` - Get all user's tags
- ✅ `getTag()` - Get single tag
- ✅ `createTag()` - Create new tag
- ✅ `deleteTag()` - Delete tag

### ContactTagsService
- ✅ `listForContact()` - Get all tags for a contact
- ✅ `upsert()` - Add/update tag on contact with priority
- ✅ `remove()` - Remove tag from contact

### NotesService
- ✅ `list()` - Get all notes for contact
- ✅ `get()` - Get single note
- ✅ `create()` - Create new note
- ✅ `delete()` - Delete note

### RemindersService
- ✅ `list()` - Get reminders for contact
- ✅ `listUpcoming()` - Get upcoming reminders for user
- ✅ `get()` - Get single reminder
- ✅ `create()` - Create new reminder
- ✅ `delete()` - Delete reminder

### NewsService
- ✅ `list()` - Get news for contact
- ✅ `listRecent()` - Get recent news
- ✅ `get()` - Get single news item
- ✅ `create()` - Create news entry
- ✅ `delete()` - Delete news

### AIChatService
- ✅ `sendMessage()` - Send user message to contact-scoped AI assistant
- ✅ Calls Supabase Edge Function `/functions/v1/contact-chat`
- ✅ Edge function fetches context, calls OpenAI, saves chat history
- ✅ Returns assistant reply to iOS app

## 📋 Next Sprint

**High Priority:**
- Contact photo upload to Supabase Storage
- Search functionality implementation (currently client-side only)
- Edit/delete notes and reminders
- Swipe actions on lists (delete, edit)
- Pull-to-refresh on all list views

**Medium Priority:**
- Home page carousels for "Overdue check-ins" and "Recent activity"
- Rich filters for News (by contact, topic, date range)
- Contact import from phone contacts
- LinkedIn profile scraping/integration for news
- Enhanced onboarding walkthrough

**Future Features:**
- Enhanced AI Chat capabilities:
  - Scrollable chat history UI
  - Multi-turn conversations with memory
  - Suggesting relationship priorities
  - Auto-summarizing interactions from multiple notes
  - Generate follow-up questions
- Push notifications for reminders
- Calendar integration for reminders
- Export contacts (vCard, CSV)
- Contact grouping/filtering by tags
- Analytics (interaction frequency, priority distribution)

## 🛠️ Development Notes

### Current State
- ✅ All services fully integrated with Supabase
- ✅ Complete CRUD operations for all entities
- ✅ Authentication working with session persistence
- ✅ All forms validate input and handle errors
- ✅ Data automatically refreshes after mutations
- ✅ Logger uses `os.Logger` with subsystem "com.rolo.app"
- ✅ AI Chat integrated via Supabase Edge Functions + OpenAI
- ✅ Chat history persisted in PostgreSQL

### Code Quality
- Services use async/await throughout
- Protocol-based architecture for testability
- Type-safe DTOs for all create/update operations
- Proper error handling with `ServiceError` enum
- SwiftUI previews available (mock data removed)

### Known Limitations
- Search is client-side only (filters loaded contacts)
- No photo upload yet (only URL field)
- No edit/delete for notes and reminders (create only)
- News feature displays data but no fetching logic yet
- AI Chat shows only last reply (no scrollable history UI yet)

## 🧪 Testing

### Manual Testing Checklist
- [x] Sign up with new account
- [x] Sign in with existing account
- [x] Sign out and verify session cleared
- [x] Create new contact
- [x] Edit contact information
- [x] Add tags to contact
- [x] Remove tags from contact
- [x] Create new tag
- [x] Add note (with and without meeting flag)
- [x] Add reminder (with and without due date)
- [x] View contact list
- [x] Search contacts (client-side)
- [x] Navigate between tabs
- [x] Data persists in Supabase
- [x] Send AI chat message and receive response
- [x] Save AI response as note
- [x] Create reminder from AI chat

### To Test
- [ ] Password reset flow
- [ ] Deep link handling
- [ ] Error scenarios (network failures)
- [ ] Concurrent operations
- [ ] Large datasets (100+ contacts)

## 📱 Contributing

When adding new features:
1. Follow MVVM pattern with `@MainActor` ViewModels
2. Use services for all data operations
3. Add both model (Codable) and DTO (Encodable) for new entities
4. Create dedicated sheets for forms (follow existing patterns)
5. Use the shared UI components and theme
6. Handle loading and error states
7. Refresh data after mutations

### File Naming Conventions
- Models: `Contact.swift`, `Tag.swift`
- DTOs: `NewContact.swift`, `UpdateContactBasicInfo.swift`
- Services: `ContactsService.swift`
- Views: `ContactsListView.swift`
- Sheets: `EditContactSheet.swift`, `AddNoteSheet.swift`
- ViewModels: `ContactsListViewModel.swift`

---

## 🤖 AI Chat Architecture

### Edge Function Flow
```
iOS App → AIChatService → Supabase Edge Function → OpenAI API
                                    ↓
                          PostgreSQL (chat_messages)
```

**Edge Function:** `supabase/functions/contact-chat/index.ts`
- **Model:** `gpt-4o-mini` (fast, cheap, perfect for CRM use case)
- **Temperature:** 0.3 (crisp, factual responses)
- **Context:** Fetches top 5 tags, 5 recent notes, 3 reminders, 3 news items
- **Token Budget:** ~1.5-2.5K tokens per chat (~$0.0004 per request)
- **Security:** OpenAI API key stored as Supabase secret, never exposed to client

### System Prompt
```
You are an AI copilot inside a CRM contact page.
Only discuss THIS contact. Be concise, specific, and action-oriented.
Use ONLY the provided context; do not invent facts.
If information is missing, say so and propose a concrete next step.
Prefer short drafts, bullet points, and suggested follow-ups over long narratives.
```

---

**Version:** 1.1.0-MVP  
**Last Updated:** October 15, 2025  
**Status:** ✅ Core features + AI Chat complete

