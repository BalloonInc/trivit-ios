# App Groups Configuration Fix

## 🔴 Issue
The App Group `group.ballooninc.trivit.Documents` appears red in Xcode because:
- Bundle ID changed from `be.ballooninc.trivit` → `com.wouterdevriendt.trivit`
- App Group identifier still uses old `ballooninc` domain
- Not configured in Apple Developer portal for new bundle ID

## ✅ Solution

### 1. Update App Group Identifier
**Current (red):** `group.ballooninc.trivit.Documents`  
**Update to:** `group.com.wouterdevriendt.trivit.Documents`

### 2. Configure in Xcode
1. Open **Trivit.xcodeproj** 
2. Select **Trivit** target → **Signing & Capabilities**
3. Find **App Groups** section
4. Uncheck `group.ballooninc.trivit.Documents`
5. Click **+** and add `group.com.wouterdevriendt.trivit.Documents`

### 3. Configure Watch App Target
1. Select **Trivit Watch App** target → **Signing & Capabilities**
2. Add **App Groups** capability if not present
3. Add same identifier: `group.com.wouterdevriendt.trivit.Documents`

### 4. Apple Developer Portal (if needed)
If Xcode shows errors, manually create the App Group:
1. Go to [developer.apple.com](https://developer.apple.com)
2. **Certificates, Identifiers & Profiles** → **Identifiers** → **App Groups**
3. Click **+** → **Register App Group**
4. **Identifier:** `group.com.wouterdevriendt.trivit.Documents`
5. **Description:** `Trivit Data Sharing`

## 🔄 Why App Groups Are Required

App Groups enable **real-time sync** between:
- 📱 **iPhone** ↔ ⌚ **Apple Watch** 
- 💻 **iPad/Mac** data sharing
- 🔄 **Background sync** when apps are inactive

## 🚀 Sync Architecture

```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│   iPhone    │     iPad    │     Mac     │    Watch    │
│             │             │             │             │
│  CloudKit ◄─┼─► CloudKit ◄─┼─► CloudKit ◄─┼─► WatchKit  │
│             │             │             │ Connectivity│
└─────────────┴─────────────┴─────────────┴─────────────┘
                           │
                    App Groups Container
                  (Fallback for offline sync)
```

## 📁 Implementation Files
- **iPhone:** `trivit/WatchSyncService.swift`
- **Watch:** `trivit Watch App/Services/SyncService.swift`
- **Fallback:** App Groups shared container
