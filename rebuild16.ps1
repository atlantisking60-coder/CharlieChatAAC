$ErrorActionPreference = "Stop"

function Blank($id) {
    @{id=$id;type="blank";label="";category="Custom";imageAsset="";emoji="";isBoardLink=$false;linkedBoardId="";linkedBoardName=$null;isFullScreenImage=$false;bgColor="transparent";textColor="#000000";tileSize=1;colSpan=1;rowSpan=1;customVoice=""}
}

function Tile($id,$label,$img,$bg="transparent",$tc="#000000",$cat="Assets",$inst=$false) {
    $t = @{id=$id;type="vocabulary";label=$label;category=$cat;imageAsset=$img;emoji="";isBoardLink=$false;linkedBoardId="";linkedBoardName=$null;isFullScreenImage=$false;bgColor=$bg;textColor=$tc;tileSize=1;colSpan=1;rowSpan=1;customVoice=""}
    if($inst){$t.isFullScreenImage=$true}
    $t
}

function Inst($id,$label,$img) { Tile $id $label $img "#000000" "#FFFFFF" "Assets" $true }
function Title($id,$label,$img) { Tile $id $label $img "#4FC3F7" }
function Vocab($id,$label,$img) { Tile $id $label $img }

function Write-Board($path,$cols,$rows,$tiles) {
    $existing = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $existing.columns = $cols
    $existing.layout.rows = $rows
    $existing.layout.blankTilesAdded = 0
    $existing.tiles = $tiles
    $existing | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
    Write-Host "OK: $path"
}

$base = "C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Recipes\Recipes"
$cook = "assets/Subject Vocab\Cooking"
$common = "assets\Common"

# Board 16: Italian Pasta
Write-Board "$base\italian_pasta\prebuilt_recipes_italian_pasta.json" 7 8 @(
    # Row 1: Italian, Pasta, blank, blank, blank, 1 Instr, 2 Instr
    Title "prebuilt_recipes_italian_pasta_tile_1" "Italian" "$cook\More Symbols\italian flag.png"
    Title "prebuilt_recipes_italian_pasta_tile_2" "Pasta" "$cook\Carbohydrates\pasta.png"
    Blank "prebuilt_recipes_italian_pasta_tile_3"
    Blank "prebuilt_recipes_italian_pasta_tile_4"
    Blank "prebuilt_recipes_italian_pasta_tile_5"
    Inst "prebuilt_recipes_italian_pasta_tile_6" "Italian Pasta Instructions 1" "$cook\Recipes\Instructions\Italian Pasta Instructions 1.jpg"
    Inst "prebuilt_recipes_italian_pasta_tile_7" "Italian Pasta Instructions 2" "$cook\Recipes\Instructions\Italian Pasta Instructions 2.jpg"
    # Row 2: blank x7
    Blank "prebuilt_recipes_italian_pasta_tile_8"
    Blank "prebuilt_recipes_italian_pasta_tile_9"
    Blank "prebuilt_recipes_italian_pasta_tile_10"
    Blank "prebuilt_recipes_italian_pasta_tile_11"
    Blank "prebuilt_recipes_italian_pasta_tile_12"
    Blank "prebuilt_recipes_italian_pasta_tile_13"
    Blank "prebuilt_recipes_italian_pasta_tile_14"
    # Row 3: half, cup, pasta, blank, one, clove, garlic
    Vocab "prebuilt_recipes_italian_pasta_tile_15" "half" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_16" "cup" "$cook\Cooking Equipment\cup.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_17" "pasta" "$cook\Carbohydrates\pasta.png"
    Blank "prebuilt_recipes_italian_pasta_tile_18"
    Vocab "prebuilt_recipes_italian_pasta_tile_19" "one" "$common\Numbers\1.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_20" "clove" "$cook\Vegetables\garlic.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_21" "garlic" "$cook\Vegetables\garlic.png"
    # Row 4: 400g tin, chopped, tomato, blank, 15ml, spoon, oil
    Vocab "prebuilt_recipes_italian_pasta_tile_22" "400g tin" "$cook\Cooking Equipment\scales.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_23" "chopped" "$cook\More Symbols\chopped.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_24" "tomato" "$cook\Fruit\tomato.png"
    Blank "prebuilt_recipes_italian_pasta_tile_25"
    Vocab "prebuilt_recipes_italian_pasta_tile_26" "15ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_27" "spoon" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_28" "oil" "$cook\More Symbols\oil.png"
    # Row 5: half, teaspoon, paprika, blank, half, blank, onion
    Vocab "prebuilt_recipes_italian_pasta_tile_29" "half" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_30" "teaspoon" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_31" "paprika" "$cook\Spices\paprika.png"
    Blank "prebuilt_recipes_italian_pasta_tile_32"
    Vocab "prebuilt_recipes_italian_pasta_tile_33" "half" "$cook\Cooking Equipment\spoon.png"
    Blank "prebuilt_recipes_italian_pasta_tile_34"
    Vocab "prebuilt_recipes_italian_pasta_tile_35" "onion" "$cook\Vegetables\onion.png"
    # Row 6: sweetcorn, blank, blank, blank, fresh, basil, leaves
    Vocab "prebuilt_recipes_italian_pasta_tile_36" "sweetcorn" "$cook\Vegetables\sweetcorn.png"
    Blank "prebuilt_recipes_italian_pasta_tile_37"
    Blank "prebuilt_recipes_italian_pasta_tile_38"
    Blank "prebuilt_recipes_italian_pasta_tile_39"
    Vocab "prebuilt_recipes_italian_pasta_tile_40" "fresh" "$cook\More Symbols\fresh.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_41" "basil" "$cook\Herbs\basil.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_42" "leaves" "$cook\More Symbols\leaves.png"
    # Row 7: peas, blank, blank, blank, 5ml, spoon, dried
    Vocab "prebuilt_recipes_italian_pasta_tile_43" "peas" "$cook\Vegetables\peas.png"
    Blank "prebuilt_recipes_italian_pasta_tile_44"
    Blank "prebuilt_recipes_italian_pasta_tile_45"
    Blank "prebuilt_recipes_italian_pasta_tile_46"
    Vocab "prebuilt_recipes_italian_pasta_tile_47" "5ml" "$cook\Cooking Equipment\jug.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_48" "spoon" "$cook\Cooking Equipment\spoon.png"
    Vocab "prebuilt_recipes_italian_pasta_tile_49" "dried" "$cook\More Symbols\dried.png"
    # Row 8: blank, blank, blank, blank, blank, blank, basil
    Blank "prebuilt_recipes_italian_pasta_tile_50"
    Blank "prebuilt_recipes_italian_pasta_tile_51"
    Blank "prebuilt_recipes_italian_pasta_tile_52"
    Blank "prebuilt_recipes_italian_pasta_tile_53"
    Blank "prebuilt_recipes_italian_pasta_tile_54"
    Blank "prebuilt_recipes_italian_pasta_tile_55"
    Vocab "prebuilt_recipes_italian_pasta_tile_56" "basil" "$cook\Herbs\basil.png"
)

Write-Host "Done 16"
