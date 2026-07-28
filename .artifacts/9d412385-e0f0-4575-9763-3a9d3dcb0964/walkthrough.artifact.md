# Expanded Disney and Pixar Story Boards

I have expanded the Disney Stories board to include a comprehensive list of 73 movies, ordered chronologically by release year as requested.

## Changes Made

### 1. Updated Existing Boards
- Updated `sortOrder` in the 26 existing board JSON files to fit the new sequence.
- Maintained the "101 Dalmatians (1961)" name as requested.
- Kept "The Nightmare Before Christmas (1993)" in its chronological position.

### 2. Created 47 New Board Files
- Created folders and JSON files for the missing movies (e.g., *The Aristocats*, *Toy Story*, *Encanto*, *Elio*, etc.).
- Each new board is initially empty with a single blank tile, ready for content.
- Assigned `sortOrder` values in increments of 10 to establish the final sequence.

### 3. Updated Parent Board
- **[prebuilt_disney_stories.json](file:///C:/Users/Craig/Downloads/Charlie%20Chat/lib/data/boards/Common/People/Characters/Disney%20Stories/prebuilt_disney_stories.json)**:
    - Increased `rows` to 15 to accommodate the 73 movie links.
    - Updated the `tiles` list to include board links for all movies in the exact order requested (Disney Animation Studios followed by Pixar).

### 4. Updated Hierarchy
- **[board_hierarchy.dart](file:///C:/Users/Craig/Downloads/Charlie%20Chat/lib/data/board_hierarchy.dart)**:
    - Added all 73 movies to the `boardHierarchy` constant in the correct sequence.

## Verification Results

### Manual Verification
- The "Disney Stories" board now shows 73 sub-board tabs in the following sequence:
    1.  Walt Disney Animation Studios (1937–2023)
    2.  Pixar Animation Studios (1995–2025)
- All tabs are functional and correctly link to their respective (new or existing) boards.
