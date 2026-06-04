#!/bin/bash

# Dittox Optimization Migration Script
# Usage: ./migrate.sh [backup|apply|rollback|cleanup]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$PROJECT_DIR/lib"
BACKUP_DIR="$LIB_DIR/backup"

echo "🦾 Dittox Optimization Migration Tool"
echo "===================================="
echo ""

# Function to backup files
backup_files() {
    echo "📦 Creating backups..."
    mkdir -p "$BACKUP_DIR/screens/pdf"
    mkdir -p "$BACKUP_DIR/screens/additional"
    mkdir -p "$BACKUP_DIR/widgets/Cart"
    
    if [ -f "$LIB_DIR/screens/pdf/singlePDfFilter.dart" ]; then
        cp "$LIB_DIR/screens/pdf/singlePDfFilter.dart" "$BACKUP_DIR/screens/pdf/"
        echo "  ✅ singlePDfFilter.dart backed up"
    fi
    
    if [ -f "$LIB_DIR/screens/additional/summaryScreen.dart" ]; then
        cp "$LIB_DIR/screens/additional/summaryScreen.dart" "$BACKUP_DIR/screens/additional/"
        echo "  ✅ summaryScreen.dart backed up"
    fi
    
    if [ -f "$LIB_DIR/widgets/Cart/payLater.dart" ]; then
        cp "$LIB_DIR/widgets/Cart/payLater.dart" "$BACKUP_DIR/widgets/Cart/"
        echo "  ✅ payLater.dart backed up"
    fi
    
    echo "✅ All backups created in $BACKUP_DIR"
}

# Function to apply migration
apply_migration() {
    echo "🚀 Applying optimization..."
    
    # Check if optimized files exist
    if [ ! -f "$LIB_DIR/screens/pdf/singlePDfFilter_optimized.dart" ]; then
        echo "❌ Optimized files not found!"
        exit 1
    fi
    
    # Backup first if not already done
    if [ ! -d "$BACKUP_DIR" ]; then
        backup_files
    fi
    
    # Rename old files
    mv "$LIB_DIR/screens/pdf/singlePDfFilter.dart" "$LIB_DIR/screens/pdf/singlePDfFilter_old.dart" 2>/dev/null || true
    mv "$LIB_DIR/screens/additional/summaryScreen.dart" "$LIB_DIR/screens/additional/summaryScreen_old.dart" 2>/dev/null || true
    mv "$LIB_DIR/widgets/Cart/payLater.dart" "$LIB_DIR/widgets/Cart/payLater_old.dart" 2>/dev/null || true
    
    # Move optimized files into place
    mv "$LIB_DIR/screens/pdf/singlePDfFilter_optimized.dart" "$LIB_DIR/screens/pdf/singlePDfFilter.dart"
    mv "$LIB_DIR/screens/additional/summaryScreen_optimized.dart" "$LIB_DIR/screens/additional/summaryScreen.dart"
    mv "$LIB_DIR/widgets/Cart/payLater_optimized.dart" "$LIB_DIR/widgets/Cart/payLater.dart"
    
    echo "✅ Migration applied!"
    echo ""
    echo "Next steps:"
    echo "  1. cd $PROJECT_DIR"
    echo "  2. flutter clean"
    echo "  3. flutter pub get"
    echo "  4. flutter analyze"
    echo "  5. flutter run"
}

# Function to rollback
rollback_migration() {
    echo "↩️  Rolling back..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ No backup found! Cannot rollback."
        exit 1
    fi
    
    # Restore from backup
    cp "$BACKUP_DIR/screens/pdf/singlePDfFilter.dart" "$LIB_DIR/screens/pdf/"
    cp "$BACKUP_DIR/screens/additional/summaryScreen.dart" "$LIB_DIR/screens/additional/"
    cp "$BACKUP_DIR/widgets/Cart/payLater.dart" "$LIB_DIR/widgets/Cart/"
    
    echo "✅ Rolled back to original files!"
    echo ""
    echo "Run 'flutter clean && flutter pub get' to refresh"
}

# Function to cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    
    # Remove old files
    rm -f "$LIB_DIR/screens/pdf/singlePDfFilter_old.dart"
    rm -f "$LIB_DIR/screens/additional/summaryScreen_old.dart"
    rm -f "$LIB_DIR/widgets/Cart/payLater_old.dart"
    
    # Remove backup
    rm -rf "$BACKUP_DIR"
    
    echo "✅ Cleanup complete!"
}

# Main command handler
case "${1:-help}" in
    backup)
        backup_files
        ;;
    apply)
        apply_migration
        ;;
    rollback)
        rollback_migration
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        echo "Usage: $0 {backup|apply|rollback|cleanup}"
        echo ""
        echo "Commands:"
        echo "  backup   - Create backups of original files"
        echo "  apply    - Apply optimized files (replaces original)"
        echo "  rollback - Restore original files from backup"
        echo "  cleanup  - Remove backups and old files"
        echo ""
        echo "Typical workflow:"
        echo "  1. $0 backup    # Always backup first"
        echo "  2. $0 apply    # Apply optimization"
        echo "  3. Test app... # Verify everything works"
        echo "  4. $0 cleanup  # Remove old files if tests pass"
        echo ""
        echo "If something breaks:"
        echo "  $0 rollback    # Restore originals"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac
