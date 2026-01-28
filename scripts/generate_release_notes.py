#!/usr/bin/env python3
"""
Generate release notes using Claude API.
Analyzes commits since last release to generate user-friendly release notes.
"""

import os
import re
import sys
import subprocess
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("Installing anthropic package...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "anthropic"])
    import anthropic


def get_repo_root() -> Path:
    """Get the repository root directory."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return Path(result.stdout.strip())


def get_last_release_tag() -> str | None:
    """Get the most recent release tag."""
    try:
        result = subprocess.run(
            ["git", "describe", "--tags", "--abbrev=0"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        # No tags found, use first commit
        result = subprocess.run(
            ["git", "rev-list", "--max-parents=0", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()[:8]


def get_commits_since_tag(tag: str) -> list[dict]:
    """Get all commits since the given tag."""
    try:
        result = subprocess.run(
            [
                "git",
                "log",
                f"{tag}..HEAD",
                "--pretty=format:%H|%s|%b|%an|%ad",
                "--date=short",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        # If tag comparison fails, get recent commits
        result = subprocess.run(
            [
                "git",
                "log",
                "-50",
                "--pretty=format:%H|%s|%b|%an|%ad",
                "--date=short",
            ],
            capture_output=True,
            text=True,
            check=True,
        )

    commits = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("|")
        if len(parts) >= 5:
            commits.append(
                {
                    "hash": parts[0],
                    "subject": parts[1],
                    "body": parts[2],
                    "author": parts[3],
                    "date": parts[4],
                }
            )

    return commits


def get_changed_files_since_tag(tag: str) -> list[str]:
    """Get list of changed files since tag."""
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", f"{tag}..HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip().split("\n")
    except subprocess.CalledProcessError:
        return []


def get_current_version(repo_root: Path) -> str:
    """Try to get current version from project files."""
    # Try Info.plist
    for plist in (repo_root / "Trivit").glob("**/Info.plist"):
        content = plist.read_text()
        match = re.search(
            r"<key>CFBundleShortVersionString</key>\s*<string>(\d+\.\d+\.\d+)</string>",
            content,
        )
        if match:
            return match.group(1)

    # Try project.pbxproj
    project_file = repo_root / "Trivit.xcodeproj" / "project.pbxproj"
    if project_file.exists():
        content = project_file.read_text()
        match = re.search(r'MARKETING_VERSION\s*=\s*(\d+\.\d+\.\d+)', content)
        if match:
            return match.group(1)

    return "1.0.0"


def generate_release_notes() -> str:
    """Generate release notes using Claude."""
    repo_root = get_repo_root()
    last_tag = get_last_release_tag()
    commits = get_commits_since_tag(last_tag)
    changed_files = get_changed_files_since_tag(last_tag)
    current_version = get_current_version(repo_root)

    app_name = "Trivit"
    app_context = "A simple and elegant counting app for tracking anything"

    # Format commits for the prompt
    commit_text = "\n".join([f"- {c['subject']} ({c['date']})" for c in commits[:50]])

    # Categorize changed files
    ios_changes = [f for f in changed_files if f.startswith("Trivit/")]
    watch_changes = [f for f in changed_files if "Watch" in f or "watchOS" in f]
    widget_changes = [f for f in changed_files if "Widget" in f]
    test_changes = [f for f in changed_files if "Test" in f]

    client = anthropic.Anthropic()

    prompt = f"""You are writing App Store release notes for {app_name} ({app_context}).

Version: {current_version}
Last release tag: {last_tag}

Commits since last release:
{commit_text}

Changed areas:
- iOS app changes: {len(ios_changes)} files
- Watch app changes: {len(watch_changes)} files
- Widget changes: {len(widget_changes)} files
- Test changes: {len(test_changes)} files

Write release notes that:
1. Are user-friendly (avoid technical jargon)
2. Focus on user-visible improvements
3. Are concise (under 500 characters for App Store limit)
4. Use bullet points for multiple changes
5. Start with most impactful changes
6. Group related changes together
7. Skip internal/technical changes users don't care about
8. Use emojis sparingly if at all

For a counting app like Trivit, focus on:
- UI/UX improvements
- New counting features
- Widget improvements
- Apple Watch updates
- Performance improvements
- Bug fixes that affect users

If there are no significant user-facing changes, write something like:
"Bug fixes and performance improvements."

Output ONLY the release notes text, no additional commentary."""

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=500,
        messages=[{"role": "user", "content": prompt}],
    )

    return response.content[0].text


def main():
    """Main entry point."""
    # Check for API key
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("Error: ANTHROPIC_API_KEY environment variable not set")
        sys.exit(1)

    print("Analyzing commits since last release...")
    last_tag = get_last_release_tag()
    print(f"Last release: {last_tag}")

    print("Generating release notes with Claude...")
    notes = generate_release_notes()

    # Output
    print("\n" + "=" * 50)
    print("GENERATED RELEASE NOTES:")
    print("=" * 50)
    print(notes)
    print("=" * 50)
    print(f"Character count: {len(notes)} (limit: 4000)")

    # Save to metadata file
    repo_root = get_repo_root()
    output_path = (
        repo_root / "fastlane" / "metadata" / "en-US" / "release_notes.txt"
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(notes)
    print(f"\nSaved to: {output_path}")


if __name__ == "__main__":
    main()
