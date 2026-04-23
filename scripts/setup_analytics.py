#!/usr/bin/env python3
"""
Setup script for GeoC Analytics System
This script helps set up Firestore indexes and create a cron job for daily analytics.
"""

import subprocess
import json
import sys

def run_command(cmd):
    """Run a shell command and return the output."""
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(f"ERROR: {result.stderr}", file=sys.stderr)
    return result

def check_prerequisites():
    """Check if required tools are installed."""
    print("\n=== Checking Prerequisites ===\n")

    # Check Python version
    if sys.version_info < (3, 8):
        print("ERROR: Python 3.8+ is required")
        return False

    print(f"✓ Python version: {sys.version}")

    # Check if flutter is available (optional, for build)
    flutter_check = run_command("which flutter")
    if flutter_check.returncode != 0:
        print("⚠ Flutter not found. You'll need to run 'dart run build_runner build' manually")
    else:
        print("✓ Flutter is installed")

    # Check if openclaw is available (for cron job)
    openclaw_check = run_command("which openclaw")
    if openclaw_check.returncode != 0:
        print("⚠ OpenClaw not found. Cron job setup will be skipped")
        return True
    else:
        print("✓ OpenClaw is installed")

    return True

def show_firestore_index_instructions():
    """Print instructions for creating Firestore indexes manually."""
    print("\n" + "="*80)
    print("FIRESTORE INDEX SETUP INSTRUCTIONS")
    print("="*80 + "\n")

    print("You need to create the following composite indexes in Firebase Console:\n")

    indexes = [
        {
            "name": "Date range queries by type",
            "collection": "quizAttempts",
            "fields": [
                {"name": "answeredAt", "direction": "DESC"},
                {"name": "questionType", "direction": "ASC"}
            ],
            "scope": "Collection"
        },
        {
            "name": "User attempts by date",
            "collection": "quizAttempts",
            "fields": [
                {"name": "userId", "direction": "ASC"},
                {"name": "answeredAt", "direction": "DESC"}
            ],
            "scope": "Collection"
        },
        {
            "name": "Question attempts by date",
            "collection": "quizAttempts",
            "fields": [
                {"name": "questionId", "direction": "ASC"},
                {"name": "answeredAt", "direction": "DESC"}
            ],
            "scope": "Collection"
        }
    ]

    for i, idx in enumerate(indexes, 1):
        print(f"\n{i}. {idx['name']}")
        print(f"   Collection: {idx['collection']}")
        print(f"   Fields:")
        for field in idx['fields']:
            print(f"     - {field['name']} ({field['direction']})")
        print(f"   Query Scope: {idx['scope']}")

    print("\n" + "-"*80)
    print("STEPS:")
    print("-"*80)
    print("1. Go to Firebase Console: https://console.firebase.google.com")
    print("2. Select your project")
    print("3. Navigate to Firestore Database → Indexes")
    print("4. Click 'Add Index'")
    print("5. Fill in the fields as shown above")
    print("6. Repeat for all 3 indexes")
    print("7. Wait for indexes to build (usually takes a few minutes)\n")

def create_cron_job():
    """Create a cron job for daily analytics."""
    print("\n" + "="*80)
    print("SETTING UP DAILY ANALYTICS CRON JOB")
    print("="*80 + "\n")

    result = run_command("which openclaw")
    if result.returncode != 0:
        print("⚠ OpenClaw not found. Skipping cron job setup.")
        return

    print("This will create a cron job that runs every day at 9:00 AM")
    print("and sends an analytics report to your Telegram.\n")

    choice = input("Create cron job now? (y/n): ").strip().lower()
    if choice != 'y':
        print("Cron job setup skipped.")
        return

    # Create cron job command
    cron_prompt = """
Generate daily analytics report for GeoC quiz app.

1. Connect to Firestore and retrieve quiz_attempts from the last 24 hours
2. Calculate statistics:
   - Most failed questions (top 10)
   - Easiest questions (top 10)
   - Success rate by category (flag, capital, region, etc.)
   - Total attempts in period
   - Average response time
3. Format as a readable report with:
   - Summary of key metrics
   - Top failed questions with success rates
   - Category breakdown
   - Recommendations for improvements
4. Send the formatted report to Telegram chat

Use the Firebase Firestore SDK (firebase-admin) to query the quiz_attempts collection.
"""

    cmd = f'openclaw cronjob create --schedule "0 9 * * *" --name "GeoC Analytics - Daily" --prompt "{cron_prompt}" --deliver origin'

    print(f"\nExecuting: {cmd}\n")
    result = run_command(cmd)

    if result.returncode == 0:
        print("\n✓ Cron job created successfully!")
        print("  Check with: openclaw cronjob list")
    else:
        print("\n✗ Failed to create cron job")
        print("  You can create it manually using the command above")

def build_project():
    """Run build_runner to generate freezed files."""
    print("\n" + "="*80)
    print("BUILDING PROJECT")
    print("="*80 + "\n")

    print("This will generate freezed files for the new models.")
    print("Make sure you're in the GeoC directory.\n")

    # Check if we're in GeoC directory
    if not "/GeoC" in subprocess.check_output(['pwd'], text=True):
        print("WARNING: You might not be in the GeoC directory.")
        print("Current directory:", subprocess.check_output(['pwd'], text=True).strip())

    choice = input("Run build_runner now? (y/n): ").strip().lower()
    if choice != 'y':
        print("Build skipped. Run manually:")
        print("  cd /root/openclaw/workspace/GeoC")
        print("  dart run build_runner build --delete-conflicting-outputs")
        return

    result = run_command("dart run build_runner build --delete-conflicting-outputs")
    if result.returncode == 0:
        print("\n✓ Build successful!")
    else:
        print("\n✗ Build failed. Check the errors above.")

def main():
    """Main setup flow."""
    print("\n" + "="*80)
    print("GEOC ANALYTICS SYSTEM SETUP")
    print("="*80 + "\n")

    # Check prerequisites
    if not check_prerequisites():
        print("\n❌ Prerequisites check failed. Please install missing tools.")
        sys.exit(1)

    # Show Firestore index instructions
    show_firestore_index_instructions()

    # Build project
    build_project()

    # Setup cron job
    create_cron_job()

    # Summary
    print("\n" + "="*80)
    print("SETUP COMPLETE")
    print("="*80 + "\n")

    print("✓ Analytics system files created:")
    print("  - lib/data/models/quiz_attempt_model.dart")
    print("  - lib/domain/repositories/quiz_attempt_repository.dart")
    print("  - lib/data/repositories/quiz_attempt_repository_impl.dart")
    print("  - lib/presentation/providers/quiz_attempt_provider.dart")
    print("\n✓ Modified files:")
    print("  - lib/core/constants/firebase_constants.dart")
    print("  - lib/presentation/providers/game_provider.dart")
    print("  - lib/presentation/providers/multiplayer_provider.dart")
    print("\n📝 Next steps:")
    print("  1. Create Firestore indexes (see instructions above)")
    print("  2. Test the app: flutter run")
    print("  3. Answer some questions to generate data")
    print("  4. Verify data in Firestore Console")
    print("  5. Wait for cron job report (next day at 9 AM)\n")

if __name__ == "__main__":
    main()
