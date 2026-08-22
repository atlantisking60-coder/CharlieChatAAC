# Helper functions
function MakeBlank($id) {
    return @{
        id = $id
        type = "blank"
        label = ""
        category = "Custom"
        imageAsset = $null
        emoji = ""
        isBoardLink = $false
        linkedBoardId = ""
        linkedBoardName = $null
        isFullScreenImage = $false
        bgColor = "transparent"
        textColor = "#000000"
        tileSize = 1
        colSpan = 1
        rowSpan = 1
        customVoice = ""
    }
}

function MakeTitle($id, $label, $imageAsset) {
    return @{
        id = $id
        type = "vocabulary"
        label = $label
        category = "Assets"
        imageAsset = $imageAsset
        emoji = ""
        isBoardLink = $false
        linkedBoardId = ""
        linkedBoardName = $null
        isFullScreenImage = $false
        bgColor = "#4FC3F7"
        textColor = "#000000"
        tileSize = 1
        colSpan = 1
        rowSpan = 1
        customVoice = ""
    }
}

function MakeInstruction($id, $label, $imageAsset) {
    return @{
        id = $id
        type = "vocabulary"
        label = $label
        category = "Assets"
        imageAsset = $imageAsset
        emoji = ""
        isBoardLink = $false
        linkedBoardId = ""
        linkedBoardName = $null
        isFullScreenImage = $true
        bgColor = "#000000"
        textColor = "#FFFFFF"
        tileSize = 1
        colSpan = 1
        rowSpan = 1
        customVoice = ""
    }
}

function MakeTile($id, $label, $imageAsset) {
    return @{
        id = $id
        type = "vocabulary"
        label = $label
        category = "Assets"
        imageAsset = $imageAsset
        emoji = ""
        isBoardLink = $false
        linkedBoardId = ""
        linkedBoardName = $null
        isFullScreenImage = $false
        bgColor = "transparent"
        textColor = "#000000"
        tileSize = 1
        colSpan = 1
        rowSpan = 1
        customVoice = ""
    }
}

function ConvertTo-JsonFlat($obj) {
    $obj | ConvertTo-Json -Depth 10 -Compress
}

function Write-BoardFile($path, $board) {
    $json = $board | ConvertTo-Json -Depth 10
    # Pretty print with 2-space indent
    $json = $json -replace '"', '"'
    [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
}

$basePath = "C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Recipes\Recipes"
$assetBase = "assets/Subject Vocab/Cooking"
$commonBase = "assets/Common"

# ============================================================
# 27. Simple Spring Rolls (6 cols, 6 rows = 36 tiles)
# ============================================================
Write-Host "Building Simple Spring Rolls..."
$tiles27 = @()
# Row 1: Simple, Spring Rolls, blank, blank, 1 Instr, 2 Instr
$tiles27 += MakeTitle "prebuilt_recipes_simple_spring_rolls_tile_1" "Simple" "$assetBase/More Symbols/simple.png"
$tiles27 += MakeTitle "prebuilt_recipes_simple_spring_rolls_tile_2" "Spring Rolls" "$assetBase/More Symbols/spring rolls.png"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_3"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_4"
$tiles27 += MakeInstruction "prebuilt_recipes_simple_spring_rolls_tile_5" "Simple Spring Rolls Instructions 1" "$assetBase/Recipes/Instructions/Simple Spring Rolls Instructions 1.png"
$tiles27 += MakeInstruction "prebuilt_recipes_simple_spring_rolls_tile_6" "Simple Spring Rolls Instructions 2" "$assetBase/Recipes/Instructions/Simple Spring Rolls Instructions 2.png"
# Row 2: blank x6
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_7"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_8"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_9"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_10"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_11"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_12"
# Row 3: one, carrot, blank, blank, 25g, peas
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_13" "one" "$commonBase/Numbers/1.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_14" "carrot" "$assetBase/Vegetables/carrot.png"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_15"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_16"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_17" "25g" "$assetBase/Cooking Equipment/scales.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_18" "peas" "$assetBase/Vegetables/peas.png"
# Row 4: two, spring onion, blank, blank, 40g, beansprouts
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_19" "two" "$commonBase/Numbers/2.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_20" "spring onion" "$assetBase/Vegetables/spring onion.png"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_21"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_22"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_23" "40g" "$assetBase/Cooking Equipment/scales.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_24" "beansprouts" "$assetBase/More Symbols/beansprouts.png"
# Row 5: four, filo pastry, blank, 15ml, spoon, oyster sauce
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_25" "four" "$commonBase/Numbers/4.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_26" "filo pastry" "$assetBase/More Symbols/filo pastry.png"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_27"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_28" "15ml" "$assetBase/Cooking Equipment/jug.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_29" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_30" "oyster sauce" "$assetBase/More Symbols/oyster sauce.png"
# Row 6: blank, blank, blank, 10ml, spoon, oil
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_31"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_32"
$tiles27 += MakeBlank "prebuilt_recipes_simple_spring_rolls_tile_33"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_34" "10ml" "$assetBase/Cooking Equipment/jug.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_35" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles27 += MakeTile "prebuilt_recipes_simple_spring_rolls_tile_36" "oil" "$assetBase/Fats/Good Fats/oils.png"

$board27 = @{
    id = "prebuilt_recipes_simple_spring_rolls"
    name = "Simple Spring Rolls"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 6; blankTilesAdded = 0 }
    tiles = $tiles27
}
Write-BoardFile "$basePath\simple_spring_rolls\prebuilt_recipes_simple_spring_rolls.json" $board27

# ============================================================
# 28. Sizzling Stir Fry (6 cols, 8 rows = 48 tiles)
# ============================================================
Write-Host "Building Sizzling Stir Fry..."
$tiles28 = @()
# Row 1
$tiles28 += MakeTitle "prebuilt_recipes_sizzling_stir_fry_tile_1" "Sizzling" "$assetBase/More Symbols/sizzling.png"
$tiles28 += MakeTitle "prebuilt_recipes_sizzling_stir_fry_tile_2" "Stir Fry" "$assetBase/Meals/stir fry.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_3"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_4"
$tiles28 += MakeInstruction "prebuilt_recipes_sizzling_stir_fry_tile_5" "Sizzling Stir Fry Instructions 1" "$assetBase/Recipes/Instructions/Sizzling Stir Fry Instructions 1.png"
$tiles28 += MakeInstruction "prebuilt_recipes_sizzling_stir_fry_tile_6" "Sizzling Stir Fry Instructions 2" "$assetBase/Recipes/Instructions/Sizzling Stir Fry Instructions 2.png"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_$($_+6)" }
# Row 3: 80g, noodles, blank, blank, blank, blank
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_13" "80g" "$assetBase/Cooking Equipment/scales.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_14" "noodles" "$assetBase/Carbohydrates/noodles.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_15"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_16"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_17"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_18"
# Row 4: one, chicken breast, blank, 1, blank, pak choi
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_19" "one" "$commonBase/Numbers/1.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_20" "chicken breast" "$assetBase/Protein/chicken.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_21"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_22" "1" "$commonBase/Numbers/1.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_23"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_24" "pak choi" "$assetBase/Vegetables/pak choi.png"
# Row 5: three, mushroom, blank, 1, clove, garlic
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_25" "three" "$commonBase/Numbers/3.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_26" "mushroom" "$assetBase/Vegetables/mushroom.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_27"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_28" "1" "$commonBase/Numbers/1.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_29" "clove" "$assetBase/More Symbols/clove.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_30" "garlic" "$assetBase/Vegetables/garlic.png"
# Row 6: half, chilli pepper, blank, 1, centimetre, ginger
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_31" "half" "$assetBase/More Symbols/half.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_32" "chilli pepper" "$assetBase/Vegetables/chilli pepper.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_33"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_34" "1" "$commonBase/Numbers/1.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_35" "centimetre" "$assetBase/More Symbols/centimetre.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_36" "ginger" "$assetBase/Spices/ginger.png"
# Row 7: half, red onion, blank, 15ml, spoon, oil
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_37" "half" "$assetBase/More Symbols/half.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_38" "red onion" "$assetBase/Vegetables/red onion.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_39"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_40" "15ml" "$assetBase/Cooking Equipment/jug.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_41" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_42" "oil" "$assetBase/Fats/Good Fats/oils.png"
# Row 8: half, pepper, blank, 10ml, spoon, soy sauce
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_43" "half" "$assetBase/More Symbols/half.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_44" "pepper" "$assetBase/Vegetables/pepper.png"
$tiles28 += MakeBlank "prebuilt_recipes_sizzling_stir_fry_tile_45"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_46" "10ml" "$assetBase/Cooking Equipment/jug.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_47" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles28 += MakeTile "prebuilt_recipes_sizzling_stir_fry_tile_48" "soy sauce" "$assetBase/More Symbols/soy sauce.png"

$board28 = @{
    id = "prebuilt_recipes_sizzling_stir_fry"
    name = "Sizzling Stir Fry"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 8; blankTilesAdded = 0 }
    tiles = $tiles28
}
Write-BoardFile "$basePath\Sizzling Stir Fry\prebuilt_recipes_sizzling_stir_fry.json" $board28

# ============================================================
# 29. Spicy Bean Burger (6 cols, 6 rows = 36 tiles)
# ============================================================
Write-Host "Building Spicy Bean Burger..."
$tiles29 = @()
# Row 1: Spicy, Bean, Burger, blank, 1 Instr, 2 Instr
$tiles29 += MakeTitle "prebuilt_recipes_spicy_bean_burger_tile_1" "Spicy" "$assetBase/Spices/chilli powder.png"
$tiles29 += MakeTitle "prebuilt_recipes_spicy_bean_burger_tile_2" "Bean" "$assetBase/Vegetables/beans.png"
$tiles29 += MakeTitle "prebuilt_recipes_spicy_bean_burger_tile_3" "Burger" "$assetBase/More Symbols/burger.png"
$tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_4"
$tiles29 += MakeInstruction "prebuilt_recipes_spicy_bean_burger_tile_5" "Spicy Bean Burger Instructions 1" "$assetBase/Recipes/Instructions/Spicy Bean Burger Instructions 1.png"
$tiles29 += MakeInstruction "prebuilt_recipes_spicy_bean_burger_tile_6" "Spicy Bean Burger Instructions 2" "$assetBase/Recipes/Instructions/Spicy Bean Burger Instructions 2.png"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_$($_+6)" }
# Row 3: two, 400g, tin, kidney beans, blank, coriander
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_13" "two" "$commonBase/Numbers/2.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_14" "400g" "$assetBase/Cooking Equipment/scales.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_15" "tin" "$assetBase/More Symbols/tin.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_16" "kidney beans" "$assetBase/Protein/kidney beans.png"
$tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_17"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_18" "coriander" "$assetBase/Herbs/coriander.png"
# Row 4: two, tablespoon, mild, chilli powder, blank, salsa
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_19" "two" "$commonBase/Numbers/2.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_20" "tablespoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_21" "mild" "$assetBase/More Symbols/mild.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_22" "chilli powder" "$assetBase/Spices/chilli powder.png"
$tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_23"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_24" "salsa" "$assetBase/More Symbols/salsa.png"
# Row 5: one, egg, blank, blank, 100g, breadcrumbs
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_25" "one" "$commonBase/Numbers/1.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_26" "egg" "$assetBase/Dairy/egg.png"
$tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_27"
$tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_28"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_29" "100g" "$assetBase/Cooking Equipment/scales.png"
$tiles29 += MakeTile "prebuilt_recipes_spicy_bean_burger_tile_30" "breadcrumbs" "$assetBase/More Symbols/breadcrumbs.png"
# Row 6: blank x6
1..6 | ForEach-Object { $tiles29 += MakeBlank "prebuilt_recipes_spicy_bean_burger_tile_$($_+30)" }

$board29 = @{
    id = "prebuilt_recipes_spicy_bean_burger"
    name = "Spicy Bean Burger"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 6; blankTilesAdded = 0 }
    tiles = $tiles29
}
Write-BoardFile "$basePath\Spicy Bean Burger\prebuilt_recipes_spicy_bean_burger.json" $board29

# ============================================================
# 30. Sweet Pancake (6 cols, 5 rows = 30 tiles)
# ============================================================
Write-Host "Building Sweet Pancake..."
$tiles30 = @()
# Row 1: Sweet, Pancake, blank, blank, blank, 1 Instr
$tiles30 += MakeTitle "prebuilt_recipes_sweet_pancake_tile_1" "Sweet" "$assetBase/More Symbols/salad.png"
$tiles30 += MakeTitle "prebuilt_recipes_sweet_pancake_tile_2" "Pancake" "$assetBase/More Symbols/pancake.png"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_3"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_4"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_5"
$tiles30 += MakeInstruction "prebuilt_recipes_sweet_pancake_tile_6" "Sweet Pancake Instructions 1" "$assetBase/Recipes/Instructions/Sweet Pancake Instructions 1.jpg"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_$($_+6)" }
# Row 3: 125ml, self raising flour, blank, blank, one, egg
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_13" "125ml" "$assetBase/Cooking Equipment/jug.png"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_14" "self raising flour" "$assetBase/Carbohydrates/self raising flour.png"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_15"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_16"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_17" "one" "$commonBase/Numbers/1.png"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_18" "egg" "$assetBase/Dairy/egg.png"
# Row 4: 180ml, semi-skimmed milk, blank, blank, 10g, sugar
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_19" "180ml" "$assetBase/Cooking Equipment/jug.png"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_20" "semi-skimmed milk" "$assetBase/Dairy/semi-skimmed milk.png"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_21"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_22"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_23" "10g" "$assetBase/Cooking Equipment/scales.png"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_24" "sugar" "$assetBase/Carbohydrates/caster sugar.png"
# Row 5: blank, blank, blank, blank, blank, oil
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_25"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_26"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_27"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_28"
$tiles30 += MakeBlank "prebuilt_recipes_sweet_pancake_tile_29"
$tiles30 += MakeTile "prebuilt_recipes_sweet_pancake_tile_30" "oil" "$assetBase/More Symbols/oil.png"

$board30 = @{
    id = "prebuilt_recipes_sweet_pancake"
    name = "Sweet Pancake"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 5; blankTilesAdded = 0 }
    tiles = $tiles30
}
Write-BoardFile "$basePath\sweet_pancake\prebuilt_recipes_sweet_pancake.json" $board30

# ============================================================
# 31. Thai Green Curry (6 cols, 8 rows = 48 tiles)
# ============================================================
Write-Host "Building Thai Green Curry..."
$tiles31 = @()
# Row 1: Thai, Green, Curry, blank, 1 Instr, 2 Instr
$tiles31 += MakeTitle "prebuilt_recipes_thai_green_curry_tile_1" "Thai" "$assetBase/More Symbols/thai.png"
$tiles31 += MakeTitle "prebuilt_recipes_thai_green_curry_tile_2" "Green" "$assetBase/Food Groups/vegetable.png"
$tiles31 += MakeTitle "prebuilt_recipes_thai_green_curry_tile_3" "Curry" "$assetBase/More Symbols/curry.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_4"
$tiles31 += MakeInstruction "prebuilt_recipes_thai_green_curry_tile_5" "Thai Green Curry Instructions 1" "$assetBase/Recipes/Instructions/Thai Green Curry Instructions 1.jpg"
$tiles31 += MakeInstruction "prebuilt_recipes_thai_green_curry_tile_6" "Thai Green Curry Instructions 2" "$assetBase/Recipes/Instructions/Thai Green Curry Instructions 2.jpg"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_$($_+6)" }
# Row 3: one, garlic, clove, blank, 3, spring onion
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_13" "one" "$commonBase/Numbers/1.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_14" "garlic" "$assetBase/Vegetables/garlic.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_15" "clove" "$assetBase/More Symbols/clove.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_16"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_17" "3" "$commonBase/Numbers/3.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_18" "spring onion" "$assetBase/Vegetables/spring onion.png"
# Row 4: 15ml, spoon, soy sauce, blank, half, lime
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_19" "15ml" "$assetBase/Cooking Equipment/jug.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_20" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_21" "soy sauce" "$assetBase/More Symbols/soy sauce.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_22"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_23" "half" "$assetBase/More Symbols/half.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_24" "lime" "$assetBase/Fruit/lime.png"
# Row 5: 15ml, spoon, oil, blank, 200ml, coconut milk
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_25" "15ml" "$assetBase/Cooking Equipment/jug.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_26" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_27" "oil" "$assetBase/More Symbols/oil.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_28"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_29" "200ml" "$assetBase/Cooking Equipment/jug.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_30" "coconut milk" "$assetBase/More Symbols/coconut milk.png"
# Row 6: 30ml, spoon, green curry paste, blank, 80g, sugar snap peas
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_31" "30ml" "$assetBase/Cooking Equipment/jug.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_32" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_33" "green curry paste" "$assetBase/More Symbols/green curry paste.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_34"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_35" "80g" "$assetBase/Cooking Equipment/scales.png"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_36" "sugar snap peas" "$assetBase/Vegetables/peas.png"
# Row 7: chicken breast, blank, blank, coriander, blank, black pepper
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_37" "chicken breast" "$assetBase/Protein/chicken.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_38"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_39"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_40" "coriander" "$assetBase/Herbs/coriander.png"
$tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_41"
$tiles31 += MakeTile "prebuilt_recipes_thai_green_curry_tile_42" "black pepper" "$assetBase/Spices/peppercorns.png"
# Row 8: blank x6
1..6 | ForEach-Object { $tiles31 += MakeBlank "prebuilt_recipes_thai_green_curry_tile_$($_+42)" }

$board31 = @{
    id = "prebuilt_recipes_thai_green_curry"
    name = "Thai Green Curry"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 8; blankTilesAdded = 0 }
    tiles = $tiles31
}
Write-BoardFile "$basePath\thai_green_curry\prebuilt_recipes_thai_green_curry.json" $board31

# ============================================================
# 32. Toastie (6 cols, 1 row = 6 tiles)
# ============================================================
Write-Host "Building Toastie..."
$tiles32 = @()
# Row 1: Toastie, blank, blank, blank, 1 Instr, 2 Instr
$tiles32 += MakeTitle "prebuilt_recipes_toastie_tile_1" "Toastie" "$assetBase/More Symbols/toastie.png"
$tiles32 += MakeBlank "prebuilt_recipes_toastie_tile_2"
$tiles32 += MakeBlank "prebuilt_recipes_toastie_tile_3"
$tiles32 += MakeBlank "prebuilt_recipes_toastie_tile_4"
$tiles32 += MakeInstruction "prebuilt_recipes_toastie_tile_5" "Toastie Instructions 1" "$assetBase/Recipes/Instructions/Toastie Instructions 1.png"
$tiles32 += MakeInstruction "prebuilt_recipes_toastie_tile_6" "Toastie Instructions 2" "$assetBase/Recipes/Instructions/Toastie Instructions 2.png"

$board32 = @{
    id = "prebuilt_recipes_toastie"
    name = "Toastie"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 1; blankTilesAdded = 0 }
    tiles = $tiles32
}
Write-BoardFile "$basePath\toastie\prebuilt_recipes_toastie.json" $board32

# ============================================================
# 33. Tomato and Basil Tart (6 cols, 8 rows = 48 tiles)
# ============================================================
Write-Host "Building Tomato and Basil Tart..."
$tiles33 = @()
# Row 1: Tomato, Basil, Tart, blank, 1 Instr, 2 Instr
$tiles33 += MakeTitle "prebuilt_recipes_tomato_and_basil_tart_tile_1" "Tomato" "$assetBase/Fruit/tomato.png"
$tiles33 += MakeTitle "prebuilt_recipes_tomato_and_basil_tart_tile_2" "Basil" "$assetBase/Herbs/basil.png"
$tiles33 += MakeTitle "prebuilt_recipes_tomato_and_basil_tart_tile_3" "Tart" "$assetBase/More Symbols/tart.png"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_4"
$tiles33 += MakeInstruction "prebuilt_recipes_tomato_and_basil_tart_tile_5" "Tomato and Basil Tart Instructions 1" "$assetBase/Recipes/Instructions/Tomato and Basil Tart Instructions 1.png"
$tiles33 += MakeInstruction "prebuilt_recipes_tomato_and_basil_tart_tile_6" "Tomato and Basil Tart Instructions 2" "$assetBase/Recipes/Instructions/Tomato and Basil Tart Instructions 2.png"
# Row 2: blank, blank, blank, blank, 3 Instr, 4 Instr
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_7"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_8"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_9"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_10"
$tiles33 += MakeInstruction "prebuilt_recipes_tomato_and_basil_tart_tile_11" "Tomato and Basil Tart Instructions 3" "$assetBase/Recipes/Instructions/Tomato and Basil Tart Instructions 3.png"
$tiles33 += MakeInstruction "prebuilt_recipes_tomato_and_basil_tart_tile_12" "Tomato and Basil Tart Instructions 4" "$assetBase/Recipes/Instructions/Tomato and Basil Tart Instructions 4.png"
# Row 3: 100g, flour plain, blank, blank, 125ml, semi-skimmed milk
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_13" "100g" "$assetBase/Cooking Equipment/scales.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_14" "flour plain" "$assetBase/Carbohydrates/self raising flour.png"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_15"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_16"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_17" "125ml" "$assetBase/Cooking Equipment/jug.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_18" "semi-skimmed milk" "$assetBase/Dairy/semi-skimmed milk.png"
# Row 4: two, eggs, blank, blank, 50g, butter
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_19" "two" "$commonBase/Numbers/2.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_20" "eggs" "$assetBase/Dairy/eggs.png"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_21"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_22"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_23" "50g" "$assetBase/Cooking Equipment/scales.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_24" "butter" "$assetBase/Dairy/butter.png"
# Row 5: two, tomato, blank, blank, 50g, cheese
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_25" "two" "$commonBase/Numbers/2.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_26" "tomato" "$assetBase/Fruit/tomato.png"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_27"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_28"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_29" "50g" "$assetBase/Cooking Equipment/scales.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_30" "cheese" "$assetBase/Dairy/cheddar.png"
# Row 6: 30ml, water, blank, blank, blank, black pepper
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_31" "30ml" "$assetBase/Cooking Equipment/jug.png"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_32" "water" "$assetBase/More Symbols/water.png"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_33"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_34"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_35"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_36" "black pepper" "$assetBase/Spices/peppercorns.png"
# Row 7: blank, blank, blank, blank, blank, basil
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_37"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_38"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_39"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_40"
$tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_41"
$tiles33 += MakeTile "prebuilt_recipes_tomato_and_basil_tart_tile_42" "basil" "$assetBase/Herbs/basil.png"
# Row 8: blank x6
1..6 | ForEach-Object { $tiles33 += MakeBlank "prebuilt_recipes_tomato_and_basil_tart_tile_$($_+42)" }

$board33 = @{
    id = "prebuilt_recipes_tomato_and_basil_tart"
    name = "Tomato and Basil Tart"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 8; blankTilesAdded = 0 }
    tiles = $tiles33
}
Write-BoardFile "$basePath\tomato_and_basil_tart\prebuilt_recipes_tomato_and_basil_tart.json" $board33

# ============================================================
# 34. Tuna Pasta Bake (6 cols, 7 rows = 42 tiles)
# ============================================================
Write-Host "Building Tuna Pasta Bake..."
$tiles34 = @()
# Row 1: Tuna, Pasta, Bake, blank, 1 Instr, 2 Instr
$tiles34 += MakeTitle "prebuilt_recipes_tuna_pasta_bake_tile_1" "Tuna" "$assetBase/Protein/seafood.png"
$tiles34 += MakeTitle "prebuilt_recipes_tuna_pasta_bake_tile_2" "Pasta" "$assetBase/Carbohydrates/pasta.png"
$tiles34 += MakeTitle "prebuilt_recipes_tuna_pasta_bake_tile_3" "Bake" "$assetBase/More Symbols/pasta bake.png"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_4"
$tiles34 += MakeInstruction "prebuilt_recipes_tuna_pasta_bake_tile_5" "Tuna Pasta Bake Instructions 1" "$assetBase/Recipes/Instructions/Tuna Pasta Bake Instructions 1.png"
$tiles34 += MakeInstruction "prebuilt_recipes_tuna_pasta_bake_tile_6" "Tuna Pasta Bake Instructions 2" "$assetBase/Recipes/Instructions/Tuna Pasta Bake Instructions 2.png"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_$($_+6)" }
# Row 3: 200g, tin, tuna, blank, 250g, pasta
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_13" "200g" "$assetBase/Cooking Equipment/scales.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_14" "tin" "$assetBase/More Symbols/tin.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_15" "tuna" "$assetBase/Protein/seafood.png"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_16"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_17" "250g" "$assetBase/Cooking Equipment/scales.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_18" "pasta" "$assetBase/Carbohydrates/pasta.png"
# Row 4: 150g, tin, sweetcorn, blank, 75g, cheddar
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_19" "150g" "$assetBase/Cooking Equipment/scales.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_20" "tin" "$assetBase/More Symbols/tin.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_21" "sweetcorn" "$assetBase/Vegetables/sweetcorn.png"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_22"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_23" "75g" "$assetBase/Cooking Equipment/scales.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_24" "cheddar" "$assetBase/Dairy/cheddar.png"
# Row 5: 25g, plain flour, blank, blank, 250ml, semi-skimmed milk
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_25" "25g" "$assetBase/Cooking Equipment/scales.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_26" "plain flour" "$assetBase/Carbohydrates/self raising flour.png"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_27"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_28"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_29" "250ml" "$assetBase/Cooking Equipment/jug.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_30" "semi-skimmed milk" "$assetBase/Dairy/semi-skimmed milk.png"
# Row 6: 25g, butter, blank, blank, two, tomato
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_31" "25g" "$assetBase/Cooking Equipment/scales.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_32" "butter" "$assetBase/Dairy/butter.png"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_33"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_34"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_35" "two" "$commonBase/Numbers/2.png"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_36" "tomato" "$assetBase/Fruit/tomato.png"
# Row 7: blank, blank, blank, blank, blank, black pepper
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_37"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_38"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_39"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_40"
$tiles34 += MakeBlank "prebuilt_recipes_tuna_pasta_bake_tile_41"
$tiles34 += MakeTile "prebuilt_recipes_tuna_pasta_bake_tile_42" "black pepper" "$assetBase/Spices/peppercorns.png"

$board34 = @{
    id = "prebuilt_recipes_tuna_pasta_bake"
    name = "Tuna Pasta Bake"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 7; blankTilesAdded = 0 }
    tiles = $tiles34
}
Write-BoardFile "$basePath\tuna_pasta_bake\prebuilt_recipes_tuna_pasta_bake.json" $board34

# ============================================================
# 35. Turkey Burgers (6 cols, 5 rows = 30 tiles)
# ============================================================
Write-Host "Building Turkey Burgers..."
$tiles35 = @()
# Row 1: Turkey, Burger, blank, blank, 1 Instr, 2 Instr
$tiles35 += MakeTitle "prebuilt_recipes_turkey_burgers_tile_1" "Turkey" "$assetBase/Protein/turkey.png"
$tiles35 += MakeTitle "prebuilt_recipes_turkey_burgers_tile_2" "Burger" "$assetBase/More Symbols/burger.png"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_3"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_4"
$tiles35 += MakeInstruction "prebuilt_recipes_turkey_burgers_tile_5" "Turkey Burgers Instructions 1" "$assetBase/Recipes/Instructions/Turkey Burgers Instructions 1.jpg"
$tiles35 += MakeInstruction "prebuilt_recipes_turkey_burgers_tile_6" "Turkey Burgers Instructions 2" "$assetBase/Recipes/Instructions/Turkey Burgers Instructions 2.jpg"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_$($_+6)" }
# Row 3: one, onion, blank, 250g, turkey, mince
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_13" "one" "$commonBase/Numbers/1.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_14" "onion" "$assetBase/Vegetables/onion.png"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_15"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_16" "250g" "$assetBase/Cooking Equipment/scales.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_17" "turkey" "$assetBase/Protein/turkey.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_18" "mince" "$assetBase/More Symbols/mince.png"
# Row 4: black pepper, blank, blank, 5ml, spoon, mixed herbs
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_19" "black pepper" "$assetBase/Spices/peppercorns.png"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_20"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_21"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_22" "5ml" "$assetBase/Cooking Equipment/jug.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_23" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_24" "mixed herbs" "$assetBase/Herbs/basil.png"
# Row 5: blank, blank, blank, 5ml, spoon, worcestershire sauce
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_25"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_26"
$tiles35 += MakeBlank "prebuilt_recipes_turkey_burgers_tile_27"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_28" "5ml" "$assetBase/Cooking Equipment/jug.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_29" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles35 += MakeTile "prebuilt_recipes_turkey_burgers_tile_30" "worcestershire sauce" "$assetBase/More Symbols/worcestershire sauce.png"

$board35 = @{
    id = "prebuilt_recipes_turkey_burgers"
    name = "Turkey Burgers"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 5; blankTilesAdded = 0 }
    tiles = $tiles35
}
Write-BoardFile "$basePath\turkey_burgers\prebuilt_recipes_turkey_burgers.json" $board35

# ============================================================
# 36. Veg Frittata (6 cols, 6 rows = 36 tiles)
# ============================================================
Write-Host "Building Veg Frittata..."
$tiles36 = @()
# Row 1: Vegetable, Frittata, blank, blank, 1 Instr, 2 Instr
$tiles36 += MakeTitle "prebuilt_recipes_easy_veg_frittatas_tile_1" "Vegetable" "$assetBase/More Symbols/vegetable.png"
$tiles36 += MakeTitle "prebuilt_recipes_easy_veg_frittatas_tile_2" "Frittata" "$assetBase/More Symbols/frittata.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_3"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_4"
$tiles36 += MakeInstruction "prebuilt_recipes_easy_veg_frittatas_tile_5" "Easy Veg Frittatas Instructions 1" "$assetBase/Recipes/Instructions/Easy Veg Frittatas Instructions 1.jpg"
$tiles36 += MakeInstruction "prebuilt_recipes_easy_veg_frittatas_tile_6" "Easy Veg Frittatas Instructions 2" "$assetBase/Recipes/Instructions/Easy Veg Frittatas Instructions 2.jpg"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_$($_+6)" }
# Row 3: two, spring onion, blank, 40ml, blank, milk
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_13" "two" "$commonBase/Numbers/2.png"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_14" "spring onion" "$assetBase/Vegetables/spring onion.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_15"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_16" "40ml" "$assetBase/Cooking Equipment/jug.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_17"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_18" "milk" "$assetBase/Dairy/milk.png"
# Row 4: three, eggs, blank, 50g, blank, cheese
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_19" "three" "$commonBase/Numbers/3.png"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_20" "eggs" "$assetBase/Dairy/eggs.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_21"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_22" "50g" "$assetBase/Cooking Equipment/scales.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_23"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_24" "cheese" "$assetBase/Dairy/cheddar.png"
# Row 5: black pepper, blank, blank, 80g, blank, sweetcorn
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_25" "black pepper" "$assetBase/Spices/peppercorns.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_26"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_27"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_28" "80g" "$assetBase/Cooking Equipment/scales.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_29"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_30" "sweetcorn" "$assetBase/Vegetables/sweetcorn.png"
# Row 6: coriander, blank, blank, blank, blank, oil
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_31" "coriander" "$assetBase/Herbs/coriander.png"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_32"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_33"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_34"
$tiles36 += MakeBlank "prebuilt_recipes_easy_veg_frittatas_tile_35"
$tiles36 += MakeTile "prebuilt_recipes_easy_veg_frittatas_tile_36" "oil" "$assetBase/Fats/Good Fats/oils.png"

$board36 = @{
    id = "prebuilt_recipes_easy_veg_frittatas"
    name = "Easy Veg Frittatas"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 6; blankTilesAdded = 0 }
    tiles = $tiles36
}
Write-BoardFile "$basePath\easy_veg_frittatas\prebuilt_recipes_easy_veg_frittatas.json" $board36

# ============================================================
# 37. Veg Soup (6 cols, 7 rows = 42 tiles)
# ============================================================
Write-Host "Building Veg Soup..."
$tiles37 = @()
# Row 1: Vegetable, Soup, blank, 1 Instr, 2 Instr, 3 Instr
$tiles37 += MakeTitle "prebuilt_recipes_veg_soup_tile_1" "Vegetable" "$assetBase/More Symbols/vegetable.png"
$tiles37 += MakeTitle "prebuilt_recipes_veg_soup_tile_2" "Soup" "$assetBase/Meals/soup.png"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_3"
$tiles37 += MakeInstruction "prebuilt_recipes_veg_soup_tile_4" "Veg Soup Instructions 1" "$assetBase/Recipes/Instructions/Veg Soup Instructions 1.png"
$tiles37 += MakeInstruction "prebuilt_recipes_veg_soup_tile_5" "Veg Soup Instructions 2" "$assetBase/Recipes/Instructions/Veg Soup Instructions 2.png"
$tiles37 += MakeInstruction "prebuilt_recipes_veg_soup_tile_6" "Veg Soup Instructions 3" "$assetBase/Recipes/Instructions/Veg Soup Instructions 3.png"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_$($_+6)" }
# Row 3: one, onion, blank, blank, spoon, coriander
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_13" "one" "$commonBase/Numbers/1.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_14" "onion" "$assetBase/Vegetables/onion.png"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_15"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_16"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_17" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_18" "coriander" "$assetBase/Herbs/coriander.png"
# Row 4: one, carrot, blank, blank, spoon, oil
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_19" "one" "$commonBase/Numbers/1.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_20" "carrot" "$assetBase/Vegetables/carrot.png"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_21"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_22"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_23" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_24" "oil" "$assetBase/More Symbols/oil.png"
# Row 5: one, leek, blank, blank, 600ml, water
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_25" "one" "$commonBase/Numbers/1.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_26" "leek" "$assetBase/Vegetables/leek.png"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_27"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_28"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_29" "600ml" "$assetBase/Cooking Equipment/jug.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_30" "water" "$assetBase/More Symbols/water.png"
# Row 6: one, potato, blank, blank, 1, stock cube
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_31" "one" "$commonBase/Numbers/1.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_32" "potato" "$assetBase/Vegetables/potato.png"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_33"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_34"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_35" "1" "$commonBase/Numbers/1.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_36" "stock cube" "$assetBase/More Symbols/stock cube.png"
# Row 7: one, celery, blank, blank, blank, black pepper
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_37" "one" "$commonBase/Numbers/1.png"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_38" "celery" "$assetBase/Vegetables/celery.png"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_39"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_40"
$tiles37 += MakeBlank "prebuilt_recipes_veg_soup_tile_41"
$tiles37 += MakeTile "prebuilt_recipes_veg_soup_tile_42" "black pepper" "$assetBase/Spices/peppercorns.png"

$board37 = @{
    id = "prebuilt_recipes_veg_soup"
    name = "Veg Soup"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 7; blankTilesAdded = 0 }
    tiles = $tiles37
}
Write-BoardFile "$basePath\veg_soup\prebuilt_recipes_veg_soup.json" $board37

# ============================================================
# 38. Veg Cous Cous Salad (6 cols, 7 rows = 42 tiles)
# ============================================================
Write-Host "Building Veg Cous Cous Salad..."
$tiles38 = @()
# Row 1: Vegetable, Couscous, Salad, blank, 1 Instr, 2 Instr
$tiles38 += MakeTitle "prebuilt_recipes_veg_cous_cous_salad_tile_1" "Vegetable" "$assetBase/More Symbols/vegetable.png"
$tiles38 += MakeTitle "prebuilt_recipes_veg_cous_cous_salad_tile_2" "Couscous" "$assetBase/Carbohydrates/couscous.png"
$tiles38 += MakeTitle "prebuilt_recipes_veg_cous_cous_salad_tile_3" "Salad" "$assetBase/More Symbols/salad.png"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_4"
$tiles38 += MakeInstruction "prebuilt_recipes_veg_cous_cous_salad_tile_5" "Vegetable Couscous Salad Instructions 1" "$assetBase/Recipes/Instructions/Vegetable Couscous Salad Instructions 1.png"
$tiles38 += MakeInstruction "prebuilt_recipes_veg_cous_cous_salad_tile_6" "Vegetable Couscous Salad Instructions 2" "$assetBase/Recipes/Instructions/Vegetable Couscous Salad Instructions 2.png"
# Row 2: blank x6
1..6 | ForEach-Object { $tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_$($_+6)" }
# Row 3: 175ml, boiling, water, blank, 100g, couscous
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_13" "175ml" "$assetBase/Cooking Equipment/jug.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_14" "boiling" "$assetBase/More Symbols/boiling.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_15" "water" "$assetBase/More Symbols/water.png"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_16"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_17" "100g" "$assetBase/Cooking Equipment/scales.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_18" "couscous" "$assetBase/Carbohydrates/couscous.png"
# Row 4: one, vegetable, stock cube, blank, 1, spring onion
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_19" "one" "$commonBase/Numbers/1.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_20" "vegetable" "$assetBase/More Symbols/vegetable.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_21" "stock cube" "$assetBase/More Symbols/stock cube.png"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_22"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_23" "1" "$commonBase/Numbers/1.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_24" "spring onion" "$assetBase/Vegetables/spring onion.png"
# Row 5: one, medium, tomato, blank, quarter, cucumber
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_25" "one" "$commonBase/Numbers/1.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_26" "medium" "$assetBase/More Symbols/medium.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_27" "tomato" "$assetBase/Fruit/tomato.png"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_28"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_29" "quarter" "$assetBase/More Symbols/quarter.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_30" "cucumber" "$assetBase/Vegetables/cucumber.png"
# Row 6: four, dried, apricot, blank, half, pepper
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_31" "four" "$commonBase/Numbers/4.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_32" "dried" "$assetBase/More Symbols/dried.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_33" "apricot" "$assetBase/Fruit/apricot.png"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_34"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_35" "half" "$assetBase/More Symbols/half.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_36" "pepper" "$assetBase/Vegetables/pepper.png"
# Row 7: 30ml, low fat, salad dressing, blank, blank, parsley
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_37" "30ml" "$assetBase/Cooking Equipment/jug.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_38" "low fat" "$assetBase/More Symbols/low fat.png"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_39" "salad dressing" "$assetBase/More Symbols/salad dressing.png"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_40"
$tiles38 += MakeBlank "prebuilt_recipes_veg_cous_cous_salad_tile_41"
$tiles38 += MakeTile "prebuilt_recipes_veg_cous_cous_salad_tile_42" "parsley" "$assetBase/Herbs/parsley.png"

$board38 = @{
    id = "prebuilt_recipes_veg_cous_cous_salad"
    name = "Veg Cous Cous Salad"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 7; blankTilesAdded = 0 }
    tiles = $tiles38
}
Write-BoardFile "$basePath\Veg Cous Cous Salad\prebuilt_recipes_veg_cous_cous_salad.json" $board38

# ============================================================
# 39. Vegetable Samosas (6 cols, 7 rows = 42 tiles)
# ============================================================
Write-Host "Building Vegetable Samosas..."
$tiles39 = @()
# Row 1: Vegetable, Samosas, blank, 1 Instr, 2 Instr, 3 Instr
$tiles39 += MakeTitle "prebuilt_recipes_vegetable_samosas_tile_1" "Vegetable" "$assetBase/More Symbols/vegetable.png"
$tiles39 += MakeTitle "prebuilt_recipes_vegetable_samosas_tile_2" "Samosas" "$assetBase/More Symbols/samosa.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_3"
$tiles39 += MakeInstruction "prebuilt_recipes_vegetable_samosas_tile_4" "Vegetable Samosas Instructions 1" "$assetBase/Recipes/Instructions/Veg Samosa Instructions 1.png"
$tiles39 += MakeInstruction "prebuilt_recipes_vegetable_samosas_tile_5" "Vegetable Samosas Instructions 2" "$assetBase/Recipes/Instructions/Veg Samosa Instructions 2.png"
$tiles39 += MakeInstruction "prebuilt_recipes_vegetable_samosas_tile_6" "Vegetable Samosas Instructions 3" "$assetBase/Recipes/Instructions/Veg Samosa Instructions 3.png"
# Row 2: half, potato, blank, blank, 25g, peas
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_7" "half" "$assetBase/More Symbols/half.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_8" "potato" "$assetBase/Vegetables/potato.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_9"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_10"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_11" "25g" "$assetBase/Cooking Equipment/scales.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_12" "peas" "$assetBase/Vegetables/peas.png"
# Row 3: half, carrot, blank, blank, 25g, butter
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_13" "half" "$assetBase/More Symbols/half.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_14" "carrot" "$assetBase/Vegetables/carrot.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_15"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_16"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_17" "25g" "$assetBase/Cooking Equipment/scales.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_18" "butter" "$assetBase/Dairy/butter.png"
# Row 4: half, onion, blank, blank, 15ml, coriander
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_19" "half" "$assetBase/More Symbols/half.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_20" "onion" "$assetBase/Vegetables/onion.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_21"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_22"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_23" "15ml" "$assetBase/Cooking Equipment/jug.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_24" "coriander" "$assetBase/Herbs/coriander.png"
# Row 5: half, chilli pepper, blank, blank, spray, oil
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_25" "half" "$assetBase/More Symbols/half.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_26" "chilli pepper" "$assetBase/Vegetables/chilli pepper.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_27"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_28"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_29" "spray" "$assetBase/More Symbols/spray.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_30" "oil" "$assetBase/More Symbols/oil.png"
# Row 6: three, filo pastry, blank, 3ml, spoon, turmeric
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_31" "three" "$commonBase/Numbers/3.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_32" "filo pastry" "$assetBase/More Symbols/filo pastry.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_33"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_34" "3ml" "$assetBase/Cooking Equipment/jug.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_35" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_36" "turmeric" "$assetBase/Spices/turmeric.png"
# Row 7: 40ml, water, blank, 5ml, spoon, garam masala
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_37" "40ml" "$assetBase/Cooking Equipment/jug.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_38" "water" "$assetBase/More Symbols/water.png"
$tiles39 += MakeBlank "prebuilt_recipes_vegetable_samosas_tile_39"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_40" "5ml" "$assetBase/Cooking Equipment/jug.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_41" "spoon" "$assetBase/Cooking Equipment/spoon.png"
$tiles39 += MakeTile "prebuilt_recipes_vegetable_samosas_tile_42" "garam masala" "$assetBase/More Symbols/garam masala.png"

$board39 = @{
    id = "prebuilt_recipes_vegetable_samosas"
    name = "Vegetable Samosas"
    area = "Recipes"
    columns = 6
    backgroundColor = "transparent"
    adjustableLayout = $false
    isSubBoard = $true
    isTertiaryBoard = $true
    isQuaternaryBoard = $false
    isQuinaryBoard = $false
    sortOrder = 0
    tier = 1
    boxScale = 1
    tileHeight = 100
    tileWidth = 100
    layout = @{ rows = 7; blankTilesAdded = 0 }
    tiles = $tiles39
}
Write-BoardFile "$basePath\vegetable_samosas\prebuilt_recipes_vegetable_samosas.json" $board39

Write-Host ""
Write-Host "All 13 recipe board files have been rebuilt with 6-column layouts!"
