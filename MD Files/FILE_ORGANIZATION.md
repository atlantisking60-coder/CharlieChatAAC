# Charlie Chat File Organization

## Overview
This document describes the updated file organization structure for the Charlie Chat project.

## Folder Structure

### `C:\Users\Craig\Downloads\Charlie Chat\Cascade Logs\`
**Purpose:** Cascade conversation logs only
**Contents:** 
- `2026-06-29_Cascade_Conversation.md` - Daily conversation logs with user requests and responses
- Future date-based conversation logs will be created here

### `C:\Users\Craig\Downloads\Charlie Chat\MD Files\`
**Purpose:** Project documentation files (.md)
**Contents:**
- `README.md` - Project overview and getting started guide
- `FLUTTER_SETUP.md` - Flutter installation and setup instructions
- `AAC_CORE_ENGINE.md` - AAC core engine documentation
- `API_VERSIONING.md` - API versioning strategy
- `BACKEND_COMPATIBILITY.md` - Backend compatibility notes
- `CLEAN_ARCHITECTURE.md` - Clean architecture documentation
- `CONFLICTS_ANALYSIS.md` - Conflicts analysis
- `CROSS_PLATFORM_ARCHITECTURE.md` - Cross-platform architecture
- `CROSS_PLATFORM_SUPPORT.md` - Cross-platform support details
- `DATA_LAYER.md` - Data layer documentation
- `DOMAIN_LAYER.md` - Domain layer documentation
- `FLUTTER_UNIVERSAL_CLIENT.md` - Flutter universal client docs
- `HYBRID_PROJECT_GUIDE.md` - Hybrid project guide
- `NAVIGATION_ARCHITECTURE.md` - Navigation architecture
- `OFFLINE_FIRST_ARCHITECTURE.md` - Offline-first architecture
- `PLATFORM_SETUP.md` - Platform setup instructions
- `PRESENTATION_LAYER.md` - Presentation layer documentation
- `PROFILE_MANAGEMENT_SYSTEM.md` - Profile management system
- `ROOM_DATABASE_SCHEMA.md` - Room database schema
- `UNIVERSAL_DATABASE.md` - Universal database documentation
- `FILE_ORGANIZATION.md` - This file

### `C:\Users\Craig\Downloads\Charlie Chat\LOGS\`
**Purpose:** Application log files (.log)
**Contents:**
- `board_editor.log` - Board editor application logs
- `launch_preview_windows_*.log` - Flutter Windows preview logs (timestamped)
- `launch_preview_web.log` - Flutter web preview logs
- `flutter_debug_*.log` - Flutter debug logs (timestamped)

## Batch File References

All batch files have been updated to use the new folder structure:

### Log Files (point to LOGS folder):
- `launch_board_editor.bat` → `LOGS\board_editor.log`
- `launch_preview_win.bat` → `LOGS\launch_preview_windows_*.log`
- `launch_preview_win_fixed.bat` → `LOGS\launch_preview_windows_*.log`
- `launch_preview_web.bat` → `LOGS\launch_preview_web.log`
- `launch_flutter_debug.bat` → `LOGS\flutter_debug_*.log`

### Documentation Files (point to MD Files folder):
- `FLUTTER_SETUP.md` references updated to `MD Files\FLUTTER_SETUP.md`
- `README.md` is located in `MD Files\README.md`

## Migration Summary

**Completed:**
- ✅ All .log files moved to LOGS folder
- ✅ All .md files moved to MD Files folder
- ✅ Cascade conversation logs moved to Cascade Logs folder
- ✅ All batch files updated with new paths
- ✅ Documentation references updated

**Benefits:**
- Clean project root directory
- Organized file structure by type
- Easy to find specific file types
- Consistent naming conventions
- Better project maintainability

## Usage

### For Developers:
- Look in `MD Files\` for project documentation
- Check `LOGS\` for application logs and debugging information
- Review `Cascade Logs\` for conversation history and development decisions

### For New Setup:
1. Read `MD Files\README.md` for project overview
2. Follow `MD Files\FLUTTER_SETUP.md` for Flutter setup
3. Check `LOGS\` for any runtime issues
4. Review `Cascade Logs\` for development context

## Future Files

- All new .md files should be created in `MD Files\`
- All new .log files will be automatically created in `LOGS\`
- All Cascade conversation logs will be created in `Cascade Logs\`
