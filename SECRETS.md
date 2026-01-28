# GitHub Secrets Configuration

This document describes all the GitHub secrets required for the CI/CD workflows.

## Required Secrets

### App Store Connect API

These are required for TestFlight uploads and App Store submissions.

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `APP_STORE_CONNECT_API_KEY_ID` | The Key ID from App Store Connect | App Store Connect → Users and Access → Keys → Create API Key |
| `APP_STORE_CONNECT_API_ISSUER_ID` | The Issuer ID from App Store Connect | App Store Connect → Users and Access → Keys (shown at top) |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded content of the .p8 key file | Download .p8 file, then: `base64 -i AuthKey_XXXXXX.p8` |

### Team Information

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `TEAM_ID` | Apple Developer Team ID | Apple Developer Portal → Membership |
| `ITC_TEAM_ID` | App Store Connect Team ID (for multiple teams) | App Store Connect → Users and Access |
| `APPLE_ID` | Apple ID email (for legacy auth, optional) | Your Apple ID email |

### Code Signing (Match)

These are required for building signed IPAs.

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `MATCH_GIT_URL` | URL to certificates repo | Create private repo, e.g., `https://github.com/BalloonInc/trivit-certificates` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` for repo access | `echo -n "username:github_pat_xxx" \| base64` |
| `MATCH_PASSWORD` | Password to encrypt/decrypt certificates | Generate a secure password and store it |

### CI/CD

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `KEYCHAIN_PASSWORD` | Password for temporary CI keychain | Generate any secure password |

## Setting Up Secrets

### 1. Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **Users and Access** → **Keys**
3. Click **Generate API Key**
4. Select **App Manager** or **Admin** role
5. Download the `.p8` file (only downloadable once!)
6. Note the **Key ID** and **Issuer ID**

### 2. Encode the API Key

```bash
# Encode the .p8 file to base64
base64 -i AuthKey_XXXXXX.p8 | tr -d '\n'
```

### 3. Set Up Match Repository

1. Create a **private** GitHub repository for certificates (e.g., `trivit-certificates`)
2. Generate a GitHub Personal Access Token (PAT) with `repo` scope
3. Encode credentials:

```bash
echo -n "your-github-username:ghp_xxxxxxxxxxxx" | base64
```

### 4. Initialize Match (First Time Only)

Run locally to set up certificates:

```bash
# Initialize match with your new repo
bundle exec fastlane match init

# Create App Store certificates
bundle exec fastlane match appstore

# Create Development certificates (optional)
bundle exec fastlane match development
```

### 5. Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each secret

## Testing Locally

You can test Fastlane locally by setting environment variables:

```bash
export APP_STORE_CONNECT_API_KEY_ID="XXXXXXXXXX"
export APP_STORE_CONNECT_API_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export APP_STORE_CONNECT_API_KEY_CONTENT="$(base64 -i AuthKey_XXXXXX.p8)"
export TEAM_ID="XXXXXXXXXX"
export MATCH_PASSWORD="your-match-password"
export MATCH_GIT_URL="https://github.com/BalloonInc/trivit-certificates"

# Test the beta lane
bundle exec fastlane beta skip_build:true
```

## Security Notes

- **Never** commit the `.p8` file to the repository
- **Never** commit the `MATCH_PASSWORD` anywhere
- Use GitHub's encrypted secrets for all sensitive values
- The certificates repo should be **private**
- Rotate API keys periodically
- Use the minimum required permissions for API keys

## Troubleshooting

### "Could not find App Store Connect API Key"

Ensure the `APP_STORE_CONNECT_API_KEY_CONTENT` is properly base64-encoded without newlines.

### "Match: Could not decrypt"

The `MATCH_PASSWORD` must match what was used when initially setting up match.

### "No signing certificate found"

Run `bundle exec fastlane match appstore` locally to regenerate certificates.

### "Provisioning profile doesn't match bundle identifier"

Ensure all app identifiers are registered in the Apple Developer Portal and match is run for each:
- `be.ballooninc.trivit`
- `be.ballooninc.trivit.watchkitapp`
- `be.ballooninc.trivit.watchkitapp.watchkitextension`
- `be.ballooninc.trivit.widget`
