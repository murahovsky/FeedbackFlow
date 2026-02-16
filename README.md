# FeedbackFlow

A self-hosted feature request and voting system for iOS apps, powered by [Supabase](https://supabase.com). Full control over your data, no recurring fees.

Your users leave feature requests:
<p align="center">                                                                                                               
    <img src="https://github.com/user-attachments/assets/d525db0f-4d32-4cd5-992e-66ceb443ad0a" width="295" alt="New Request" />                                                                                                                              
    &nbsp;&nbsp;                                                                                                                   
    <img src="https://github.com/user-attachments/assets/7f4fb30d-da9b-4919-886e-741738473c9d" width="295" alt="Feature Requests" 
  /> 
  </p>

Which you can then prioritize in admin UI: 

<img width="2032" height="1162" alt="image" src="https://github.com/user-attachments/assets/447fc611-7732-4481-bfb5-bdbad9b7cda8" />






**Zero external dependencies.** Pure Swift + URLSession. No Supabase SDK required.

## Features

- **Feature request list** with status filters (Planned, In Progress, In Review, Completed)
- **Upvoting** — users vote on requests, with optimistic UI updates
- **Comments** — users can discuss feature requests
- **Submit new requests** — built-in submission form with optional email field
- **Theming** — fully customizable colors to match your app
- **Admin panel** — single HTML file with Kanban board, drag & drop status changes
- **Privacy-first** — device-based identity, no user accounts required
- **Row Level Security** — users only see approved requests; admins see everything

## Architecture

```
iOS App                         Admin Panel (HTML)
  ↓                                 ↓
FeedbackFlow (SPM)            Supabase JS SDK
  ↓                                 ↓
URLSession → Supabase REST API (PostgREST) + Auth
                    ↓
              PostgreSQL (RLS)
```

## Installation

### Swift Package Manager

Add FeedbackFlow as a local or remote package:

**Local package** (during development):
1. Copy the `FeedbackFlow` folder into your project's `Packages/` directory
2. In Xcode: File → Add Package Dependencies → Add Local → select `Packages/FeedbackFlow`

**Remote package** (after publishing):
```swift
dependencies: [
    .package(url: "https://github.com/murahovsky/FeedbackFlow.git", from: "1.0.0")
]
```

## Setup

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Click **New Project** and fill in the details
3. Wait for the project to finish setting up (~2 minutes)

### 2. Run the Database Migration

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Paste the contents of [`supabase/migration.sql`](supabase/migration.sql)
4. Click **Run** (or Cmd+Enter)

This creates:
- `feedback_requests` — stores feature requests with status and vote counts
- `feedback_votes` — tracks which devices voted on which requests
- `feedback_comments` — user comments on requests
- `toggle_vote()` — atomic RPC function for voting/unvoting
- Row Level Security policies for anonymous and admin access

### 3. Create an Admin User

1. In your Supabase dashboard, go to **Authentication** → **Users**
2. Click **Add User** → **Create new user**
3. Enter your admin email and password
4. This account is used to log into the admin panel

### 4. Get Your API Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the **Project URL** (e.g., `https://xxxxx.supabase.co`)
3. Copy the **anon / public** key (under "Project API keys")

> **Note:** You need the `anon` key, not the `service_role` key. The anon key is safe to include in client apps — Row Level Security protects your data.

### 5. Configure in Your App

```swift
import FeedbackFlow

@main
struct MyApp: App {
    init() {
        FeedbackFlow.configure(
            supabaseUrl: "https://xxxxx.supabase.co",
            supabaseAnonKey: "eyJ...",
            theme: .init(
                accent: .blue,
                background: Color(hex: "0F0A07"),
                secondaryBackground: Color(hex: "1A1210"),
                text: .white,
                secondaryText: .white.opacity(0.6)
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 6. Present the Feedback View

```swift
import FeedbackFlow

struct SettingsView: View {
    @State private var showFeedback = false

    var body: some View {
        Button("Feature Requests") {
            showFeedback = true
        }
        .sheet(isPresented: $showFeedback) {
            NavigationStack {
                FeedbackFlow.FeedbackListView()
                    .navigationTitle("Feature Requests")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { showFeedback = false }
                        }
                    }
            }
        }
    }
}
```

## Theming

FeedbackFlow adapts to your app's design system:

```swift
FeedbackFlow.configure(
    supabaseUrl: "...",
    supabaseAnonKey: "...",
    theme: FeedbackTheme(
        accent: .blue,            // Buttons, selected states, accents
        background: .black,       // Main background
        secondaryBackground: Color(white: 0.12), // Cards, input fields
        text: .white,             // Primary text
        secondaryText: .gray      // Labels, placeholders, metadata
    )
)
```

If no theme is provided, a dark theme is used by default.

## Analytics Callbacks

Hook into feedback events for your analytics:

```swift
FeedbackFlow.onFeedbackSubmitted = { hasEmail in
    // User submitted a new feature request
    // hasEmail: whether they included their email
    Analytics.track("feedback_submitted", ["has_email": hasEmail])
}

FeedbackFlow.onVoteToggled = { action in
    // action: "vote" or "unvote"
    Analytics.track("feedback_voted", ["action": action])
}
```

## Admin Panel

The admin panel is a single HTML file at `admin/index.html`. No build step, no framework — just open it in a browser.

### First-Time Setup

1. Open `admin/index.html` in your browser
2. Enter your Supabase **Project URL** and **Anon Key** (saved to localStorage)
3. Enter your admin **email** and **password** (from step 3 above)
4. Click **Sign In**

### Features

- **Kanban board** with 5 columns: Pending → In Review → Planned → In Progress → Completed
- **Drag & drop** cards between columns to change status
- **Click a card** to see full details, comments, and device info
- **Delete requests** from the detail modal
- **Auto-login** on return visits (session stored by Supabase SDK)

### Hosting

You can host the admin panel anywhere:
- Open locally as a file (`file://`)
- Deploy to Vercel, Netlify, or GitHub Pages
- Serve from your own domain

No server-side code needed — it talks directly to Supabase.

## Database Schema

### `feedback_requests`

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid (PK) | Auto-generated |
| `title` | text | Required |
| `description` | text | Optional |
| `email` | text | Optional — for follow-ups |
| `status` | text | `pending` / `in_review` / `planned` / `in_progress` / `completed` |
| `vote_count` | integer | Denormalized vote count |
| `device_id` | text | Submitter's device UUID |
| `created_at` | timestamptz | Auto-generated |

### `feedback_votes`

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid (PK) | Auto-generated |
| `request_id` | uuid (FK) | → feedback_requests.id (cascade delete) |
| `device_id` | text | Voter's device UUID |
| `created_at` | timestamptz | Auto-generated |
| | UNIQUE | (request_id, device_id) |

### `feedback_comments`

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid (PK) | Auto-generated |
| `request_id` | uuid (FK) | → feedback_requests.id (cascade delete) |
| `body` | text | Comment text |
| `device_id` | text | Commenter's device UUID |
| `created_at` | timestamptz | Auto-generated |

## Row Level Security

| Table | Role | Access |
|-------|------|--------|
| `feedback_requests` | Anonymous | Read non-pending, insert new |
| `feedback_requests` | Authenticated | Full access (admin) |
| `feedback_votes` | Anonymous | Read all |
| `feedback_votes` | Authenticated | Full access (admin) |
| `feedback_comments` | Anonymous | Read (on non-pending requests), insert |
| `feedback_comments` | Authenticated | Full access (admin) |

Voting is handled via the `toggle_vote()` RPC function (SECURITY DEFINER), which bypasses RLS to atomically insert/delete votes and update the count.

## Requirements

- iOS 17.0+
- Swift 5.9+
- Supabase project (free tier works)

## License

MIT
