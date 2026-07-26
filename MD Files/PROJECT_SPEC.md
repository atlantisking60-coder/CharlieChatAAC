\# AAC Board Compiler



Version: 1.0 (Project Specification)



\## Purpose



This project builds an entire AAC board library from a single Excel workbook.



The workbook is the \*\*single source of truth\*\*.



No JSON files should ever be edited manually.



Running



```bash

python generate\_boards.py

```



should completely regenerate the entire `boards/` folder.



\---



\# Input



Primary input:



```

Board Structure.xlsx

```



The workbook contains one or more worksheets.



The compiler should automatically read every worksheet.



No worksheet names are hard-coded.



\---



\# Spreadsheet Columns



The compiler should discover columns by header name rather than fixed column numbers.



Current headers include:



\- AREA

\- MAIN BOARD OR SUBBOARD

\- BOARD NAME

\- COLUMNS

\- WORDS ON BOARD

\- SUBBOARDS AT START

\- SUBBOARDS AT END

\- CLICK TO OPEN FULL SIZE PICTURE

\- FOLDER PATH FOR WORD ICONS

\- FOLDER PATH FOR FOLDER LINK ICONS



Future columns may be added.



Unknown columns should be ignored.



\---



\# Output



The compiler produces



```

boards/

```



containing one JSON file for every board.



Example:



```

boards/

&#x20;   common\_words.json

&#x20;   feelings.json

&#x20;   sad.json

&#x20;   mad.json

&#x20;   colours.json

&#x20;   numbers.json

&#x20;   letters.json

&#x20;   animals.json

&#x20;   ...

```



\---



\# Design Philosophy



The spreadsheet is treated as a Domain Specific Language (DSL).



The compiler should not generate JSON while reading Excel.



Instead it should perform multiple compiler passes.



Pipeline:



Workbook



↓



Lexer



↓



Parser



↓



Internal Board Model



↓



Semantic Validation



↓



Layout Engine



↓



Asset Resolver



↓



JSON Writer



\---



\# Internal Model



The project exists in memory as:



```

AACProject

&#x20;   Boards

&#x20;   Assets

&#x20;   Statistics

&#x20;   Errors

&#x20;   Warnings

```



Each board contains Tile objects.



No JSON exists until the final compiler stage.



\---



\# Compiler Passes



\## Pass 1



Load workbook.



Discover worksheets.



Discover headers.



Ignore empty rows.



\---



\## Pass 2



Create Board objects.



Automatically generate board IDs.



Example:



```

Feelings

```



↓



```

prebuilt\_feelings

```



\---



\## Pass 3



Create Tile objects.



Tile types include:



\- Vocabulary

\- Board Link

\- Image Viewer

\- Blank

\- Number

\- Phonics



Future tile types should be easy to add.



\---



\## Pass 4



Resolve board links.



Example:



```

Sad

```



↓



```

linkedBoardId = prebuilt\_sad

```



Errors if missing.



\---



\## Pass 5



Resolve image assets.



Image lookup should be case insensitive.



Supported formats:



\- png

\- jpg

\- jpeg

\- webp



\---



\## Pass 6



Calculate layouts.



Rows are automatically determined.



Blank tiles are automatically added.



Example



Columns = 6



Tiles = 31



↓



Rows = 6



↓



Blank tiles added = 5



\---



\## Pass 7



Validation



Checks include



\- duplicate boards

\- duplicate IDs

\- missing images

\- missing linked boards

\- invalid layouts

\- empty boards

\- invalid JSON



Compiler should collect all errors before aborting.



\---



\## Pass 8



Write JSON.



Each Board serialises itself.



\---



\# Data Classes



Main classes:



```

AACProject



Board



Tile



CompilerContext



AACBoardCompiler

```



The compiler should be driven by



```

AACBoardCompiler.run()

```



which performs all compiler passes.



\---



\# Tile Types



Current tile types



Vocabulary



Board Link



Image Viewer



Blank



Number



Phonics



Future tile types may include



Video



PDF



Sound



Web Link



Sentence Builder



AI Prompt



Dynamic Grammar



Tile creation should therefore use a TileFactory.



\---



\# Automatic Behaviours



Automatically



\- discover worksheets

\- discover headers

\- generate IDs

\- generate board links

\- resolve image paths

\- calculate layouts

\- insert blank tiles

\- validate project

\- write JSON



Nothing should require manual editing.



\---



\# Image Resolution



The compiler builds an Asset Database.



Rather than repeatedly checking disk:



```

dog.png

```



↓



AssetDatabase



↓



Dictionary lookup.



\---



\# Statistics



The compiler produces a report.



Example



Boards



Vocabulary Tiles



Board Links



Image Viewer Tiles



Blank Tiles



Images Found



Images Missing



Warnings



Errors



Average Board Size



Largest Board



Smallest Board



\---



\# Logging



Example



```

Loading workbook...



Scanning assets...



Building boards...



Resolving links...



Checking images...



Writing JSON...



Finished.

```



\---



\# Build Cache (Future)



The compiler may eventually support incremental builds.



A hash cache determines which boards have changed.



Unchanged boards are skipped.



\---



\# Translation (Future)



Internally store keys rather than literal labels.



Example



```

happy

```



↓



translation key



↓



English



happy



↓



Welsh



hapus



↓



French



heureux



\---



\# Themes (Future)



Rather than storing colours on every tile, themes define appearance.



Examples



Normal



Board Link



Viewer



Danger



Positive



Negative



\---



\# Directives (Future)



Support directives such as



```

@blank



@viewer Feelings Wheel



@folder Animals



@theme danger



@nospeech

```



These extend the spreadsheet language without changing compiler architecture.



\---



\# Coding Style



Everything lives in a single file:



```

generate\_boards.py

```



Internally organised into sections



Imports



Configuration



Data Classes



Utilities



Workbook Loader



Compiler Passes



Validation



JSON Writer



Main



No giant procedural script.



Prefer classes and small methods.



\---



\# Goal



The final workflow should be:



1\. Edit Board Structure.xlsx

2\. Add or update image assets

3\. Run



```bash

python generate\_boards.py

```



4\. Entire AAC board library is rebuilt automatically.



No manual JSON editing.



The compiler should remain extensible, maintainable, and data-driven.

