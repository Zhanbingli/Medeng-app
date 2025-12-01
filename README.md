# Medeng – Medical English Learning App

Medeng is an iOS app for healthcare students and professionals to learn and review medical English with flashcards, AI-assisted insights, and progress tracking.

## Features
- **Rich vocabulary**: Categorized medical terms with pronunciation, concise definitions, translations, etymology, examples, and related terms.
- **Smart practice**: Spaced-repetition style flashcards, swipe/score (Again/Good), and mastery tracking.
- **AI insights**: Configure your AI API key to get breakdowns, memory tips, clinical usage, and common mistakes for any term.
- **Search & filters**: Full-text search, category/difficulty filters, quick scopes (All/Favorites/Due), and import from UMLS (with API key).
- **Progress tracking**: Overall stats, collapsible category breakdown, streaks, recent activity, and due reminders.

## Requirements
- Xcode 16+
- iOS 17.0+ (tested on iOS 17–18)
- Swift 5+

## Run the app
1. Open `Medeng.xcodeproj` in Xcode.  
2. Select an iOS simulator or a physical device.  
3. Press ⌘R to build and run.  
4. For device deployment, ensure a valid Team is set under Signing & Capabilities.

## Configure AI (optional)
1. In the app, open the Vocabulary screen and tap the gear icon (top right) to open AI Settings.  
2. Enter your API key (OpenAI/Anthropic/Qwen/Kimi) and save.  
3. Without a key, AI buttons are disabled; with a key, AI Insights return richer breakdowns.

## Import or add terms
- **Import from UMLS**: On the Vocabulary screen, tap the download icon, enter a term, and import (requires UMLS API key).  
- **Add your own**: Tap the plus icon to open “Add Medical Term,” fill required fields, or use “Auto-fill (concise)” for a quick template, then save.

## Key screens
- **Vocabulary**: Browse/search terms, open details with pronunciation and AI insights, import/add new terms.  
- **Practice**: Swipeable flashcards, Again/Flip/Good with haptics, session source options (Auto/Due/All).  
- **Progress**: Overall stats, collapsible category breakdown, streaks, and recent activity cards.

## Notes for testers
- AI features require an AI API key.  
- UMLS import requires a UMLS key.  
- If no keys are set, related actions are disabled with in-app guidance.

## License
Educational use only. Contributions and feedback are welcome.
