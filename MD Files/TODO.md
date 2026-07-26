\# AAC Board Compiler - TODO



\## Project Status



Overall Progress: 0%



\---



\# Phase 1 - Project Setup



\- \[ ] Create `generate\_boards.py`

\- \[ ] Create `requirements.txt`

\- \[ ] Verify Python 3.11+

\- \[ ] Verify workbook loads

\- \[ ] Verify output folder creation



\*\*Complete when:\*\*



Running



```bash

python generate\_boards.py

```



opens the workbook without errors.



\---



\# Phase 2 - Configuration



\- \[ ] Configuration section

\- \[ ] Default colours

\- \[ ] Default layout

\- \[ ] Image extensions

\- \[ ] Output folder settings

\- \[ ] Asset root settings



\---



\# Phase 3 - Core Classes



\## Tile



\- \[ ] Tile dataclass

\- \[ ] VocabularyTile

\- \[ ] BoardLinkTile

\- \[ ] BlankTile

\- \[ ] ImageViewerTile

\- \[ ] NumberTile

\- \[ ] PhonicsTile



\---



\## Board



\- \[ ] Board dataclass

\- \[ ] Add tile support

\- \[ ] JSON serializer



\---



\## Project



\- \[ ] AACProject class

\- \[ ] Statistics

\- \[ ] Errors

\- \[ ] Warnings



\---



\## Compiler



\- \[ ] AACBoardCompiler class

\- \[ ] run()

\- \[ ] CompilerContext



\---



\# Phase 4 - Utilities



\- \[ ] Slug generator

\- \[ ] Safe filename generator

\- \[ ] Colour helper

\- \[ ] Text parser

\- \[ ] CSV splitter

\- \[ ] Image filename normaliser



\---



\# Phase 5 - Workbook Loader



\- \[ ] Load workbook

\- \[ ] Read worksheets

\- \[ ] Ignore empty sheets

\- \[ ] Discover headers automatically

\- \[ ] Validate required headers



Acceptance:



Workbook structure can change without breaking compiler.



\---



\# Phase 6 - Spreadsheet Parser



\- \[ ] Parse AREA

\- \[ ] Parse board type

\- \[ ] Parse board name

\- \[ ] Parse columns

\- \[ ] Parse vocabulary

\- \[ ] Parse subboards

\- \[ ] Parse picture viewers

\- \[ ] Parse asset folders



Acceptance:



All spreadsheet rows become Board objects.



\---



\# Phase 7 - Tile Factory



\- \[ ] Vocabulary tiles

\- \[ ] Blank tiles

\- \[ ] Board links

\- \[ ] Image viewers

\- \[ ] Number tiles

\- \[ ] Phonics tiles



Future



\- \[ ] Video tiles

\- \[ ] PDF tiles

\- \[ ] Sound tiles



Acceptance:



Every spreadsheet token becomes the correct tile type.



\---



\# Phase 8 - Board Builder



\- \[ ] Create Board objects

\- \[ ] Add vocabulary tiles

\- \[ ] Add folder links

\- \[ ] Add picture viewers

\- \[ ] Add blank tiles



Acceptance:



Every board exists entirely in memory.



\---



\# Phase 9 - Link Resolver



\- \[ ] Generate board IDs

\- \[ ] Resolve board links

\- \[ ] Detect missing boards

\- \[ ] Detect circular references



Acceptance:



No unresolved board links remain.



\---



\# Phase 10 - Asset Scanner



\- \[ ] Scan asset folders

\- \[ ] Build asset database

\- \[ ] Case-insensitive lookup

\- \[ ] Support PNG

\- \[ ] Support JPG

\- \[ ] Support JPEG

\- \[ ] Support WEBP



Acceptance:



Every tile either finds an image or produces a warning.



\---



\# Phase 11 - Layout Engine



\- \[ ] Calculate rows

\- \[ ] Calculate required blanks

\- \[ ] Insert blank tiles

\- \[ ] Validate grid size



Acceptance:



Every board has a complete rectangular layout.



\---



\# Phase 12 - Validation



\## Boards



\- \[ ] Duplicate names

\- \[ ] Duplicate IDs

\- \[ ] Missing names



\## Tiles



\- \[ ] Duplicate tile IDs

\- \[ ] Duplicate labels



\## Assets



\- \[ ] Missing icons



\## Links



\- \[ ] Missing linked boards



\## Layout



\- \[ ] Invalid columns

\- \[ ] Empty boards



Acceptance:



Compiler reports all problems before writing JSON.



\---



\# Phase 13 - JSON Writer



\- \[ ] Board serializer

\- \[ ] Tile serializer

\- \[ ] Pretty formatting

\- \[ ] Output folder creation

\- \[ ] Overwrite existing boards



Acceptance:



Generated JSON loads successfully in the AAC application.



\---



\# Phase 14 - Logging



\- \[ ] Startup banner

\- \[ ] Progress messages

\- \[ ] Warning summary

\- \[ ] Error summary

\- \[ ] Build statistics



\---



\# Phase 15 - Command Line



\- \[ ] Normal build



```bash

python generate\_boards.py

```



\- \[ ] Validation only



```bash

python generate\_boards.py --check

```



\- \[ ] Verbose



```bash

python generate\_boards.py --verbose

```



\- \[ ] Clean build



```bash

python generate\_boards.py --clean

```



\---



\# Phase 16 - Testing



\- \[ ] Empty workbook

\- \[ ] Missing worksheet

\- \[ ] Missing headers

\- \[ ] Missing icons

\- \[ ] Broken links

\- \[ ] Duplicate boards

\- \[ ] Duplicate tiles

\- \[ ] Large workbook



Acceptance:



Compiler handles errors gracefully.



\---



\# Phase 17 - Performance



\- \[ ] Asset cache

\- \[ ] Dictionary lookups

\- \[ ] Reduce disk access

\- \[ ] Benchmark build time



Goal:



100+ boards compile in under one second (excluding workbook loading and disk I/O).



\---



\# Phase 18 - Future Features



\## Build Cache



\- \[ ] Incremental builds



\## Translation



\- \[ ] Language database



\## Themes



\- \[ ] Theme support



\## Plugins



\- \[ ] Directive parser



\## New Tile Types



\- \[ ] Video

\- \[ ] Audio

\- \[ ] PDF

\- \[ ] URL

\- \[ ] AI Prompt



\---



\# Release Checklist



Before Version 1.0



\- \[ ] All compiler passes complete

\- \[ ] All validation complete

\- \[ ] JSON schema stable

\- \[ ] README written

\- \[ ] Example workbook included

\- \[ ] Example output included

\- \[ ] Tested on Windows

\- \[ ] Tested on macOS

\- \[ ] Tested on Linux



\---



\# Version History



\## v0.1



\- Basic workbook loading



\## v0.2



\- Board generation



\## v0.3



\- Link generation



\## v0.4



\- Asset resolution



\## v0.5



\- Validation



\## v0.6



\- JSON generation



\## v0.7



\- CLI



\## v0.8



\- Optimisation



\## v0.9



\- Testing



\## v1.0



\- First production release



\---



\# Notes



The Excel workbook is the \*\*single source of truth\*\*.



Never manually edit generated JSON files.



Workflow:



1\. Edit `Board Structure.xlsx`

2\. Add/update image assets

3\. Run:



```bash

python generate\_boards.py

```



4\. Test generated boards

5\. Commit changes to Git

