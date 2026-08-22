from PIL import Image, ImageDraw, ImageFont
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "Sign Group Icons")
os.makedirs(OUTPUT_DIR, exist_ok=True)

SIZE = 96
CENTER = SIZE // 2

# Color palette
COLORS = {
    "bg": (255, 255, 255),
    "primary": (50, 50, 50),
    "accent": (70, 130, 180),
    "red": (220, 80, 60),
    "green": (60, 170, 90),
    "orange": (230, 140, 40),
    "purple": (140, 80, 180),
    "teal": (50, 170, 160),
    "blue": (60, 120, 200),
    "pink": (220, 120, 150),
    "brown": (150, 100, 60),
    "yellow": (240, 210, 60),
    "dark_blue": (30, 70, 130),
}

def draw_hand(draw, x, y, size, color):
    """Draw a simple hand symbol"""
    s = size
    # Palm
    draw.ellipse([x - s//3, y - s//4, x + s//3, y + s//3], fill=color)
    # Fingers (5 small ovals)
    for i, angle in enumerate([-30, -10, 10, 30, 50]):
        import math
        rad = math.radians(angle)
        fx = x + int(s//2 * math.cos(rad))
        fy = y - int(s//2 * math.sin(rad)) - s//4
        draw.ellipse([fx - 3, fy - 6, fx + 3, fy + 6], fill=color)

def draw_star(draw, cx, cy, size, color, points=5):
    """Draw a star"""
    import math
    outer = size // 2
    inner = size // 4
    pts = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        angle = math.radians(i * 180 / points - 90)
        pts.append((cx + int(r * math.cos(angle)), cy + int(r * math.sin(angle))))
    draw.polygon(pts, fill=color)

def draw_arrow(draw, x1, y1, x2, y2, color, width=3):
    """Draw an arrow"""
    draw.line([x1, y1, x2, y2], fill=color, width=width)
    import math
    angle = math.atan2(y2 - y1, x2 - x1)
    arrow_len = 10
    for da in [0.4, -0.4]:
        ax = x2 - int(arrow_len * math.cos(angle + da))
        ay = y2 - int(arrow_len * math.sin(angle + da))
        draw.line([x2, y2, ax, ay], fill=color, width=width)

def create_icon(name, draw_func, bg_color=None):
    """Create an icon and save it"""
    img = Image.new("RGBA", (SIZE, SIZE), bg_color or COLORS["bg"])
    draw = ImageDraw.Draw(img)
    draw_func(draw)
    filename = f"{name}.png"
    img.save(os.path.join(OUTPUT_DIR, filename))
    print(f"Created: {filename}")

# ---- Icon drawing functions ----

def icon_sign_main(draw):
    draw.ellipse([20, 20, 76, 76], fill=COLORS["accent"])
    draw_hand(draw, CENTER, CENTER, 50, COLORS["bg"])

def icon_az_sign(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["blue"])
    try:
        font = ImageFont.truetype("arial.ttf", 36)
    except:
        font = ImageFont.load_default()
    draw.text((28, 22), "A-Z", fill=COLORS["bg"], font=font)

def icon_manners(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["green"])
    draw_hand(draw, CENTER - 10, CENTER + 5, 35, COLORS["bg"])
    draw_hand(draw, CENTER + 10, CENTER + 5, 35, COLORS["bg"])

def icon_family(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["pink"])
    # Two people
    for cx in [34, 62]:
        draw.ellipse([cx - 8, 22, cx + 8, 38], fill=COLORS["bg"])
        draw.rounded_rectangle([cx - 10, 40, cx + 10, 65], radius=4, fill=COLORS["bg"])

def icon_feelings(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["orange"])
    # Heart
    draw.ellipse([28, 28, 48, 48], fill=COLORS["bg"])
    draw.ellipse([48, 28, 68, 48], fill=COLORS["bg"])
    draw.polygon([28, 42, 48, 70, 68, 42], fill=COLORS["bg"])

def icon_questions(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["purple"])
    try:
        font = ImageFont.truetype("arial.ttf", 48)
    except:
        font = ImageFont.load_default()
    draw.text((32, 18), "?", fill=COLORS["bg"], font=font)

def icon_grammar(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["teal"])
    # "Abc" text style
    try:
        font = ImageFont.truetype("arial.ttf", 24)
    except:
        font = ImageFont.load_default()
    draw.text((22, 30), "Abc", fill=COLORS["bg"], font=font)

def icon_prepositions(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["dark_blue"])
    # Arrow pointing to box
    draw.rectangle([50, 35, 75, 60], outline=COLORS["bg"], width=2)
    draw_arrow(draw, 25, 47, 48, 47, COLORS["bg"])

def icon_descriptions(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["accent"])
    # Star shape
    draw_star(draw, CENTER, CENTER, 50, COLORS["bg"])

def icon_colours(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["bg"])
    colors = [COLORS["red"], COLORS["blue"], COLORS["green"], COLORS["yellow"]]
    for i, c in enumerate(colors):
        draw.ellipse([18 + i*18, 30, 34 + i*18, 66], fill=c)

def icon_numbers(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["accent"])
    try:
        font = ImageFont.truetype("arial.ttf", 32)
    except:
        font = ImageFont.load_default()
    draw.text((26, 24), "123", fill=COLORS["bg"], font=font)

def icon_quantity(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["brown"])
    # Balance/scale
    draw.line([CENTER, 25, CENTER, 55], fill=COLORS["bg"], width=3)
    draw.line([25, 40, 71, 40], fill=COLORS["bg"], width=3)
    draw.polygon([18, 55, 32, 55, 25, 65], fill=COLORS["bg"])
    draw.polygon([64, 55, 78, 55, 71, 65], fill=COLORS["bg"])

def icon_time(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["dark_blue"])
    draw.ellipse([22, 22, 74, 74], outline=COLORS["bg"], width=3)
    draw.line([CENTER, CENTER, CENTER, 30], fill=COLORS["bg"], width=2)
    draw.line([CENTER, CENTER, 58, CENTER], fill=COLORS["bg"], width=2)

def icon_letters(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["purple"])
    try:
        font = ImageFont.truetype("arial.ttf", 28)
    except:
        font = ImageFont.load_default()
    draw.text((24, 28), "abc", fill=COLORS["bg"], font=font)

def icon_food(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["orange"])
    # Apple shape
    draw.ellipse([28, 30, 68, 72], fill=COLORS["bg"])
    draw.line([48, 30, 52, 18], fill=COLORS["green"], width=3)

def icon_personal_actions(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["teal"])
    # Person moving
    draw.ellipse([38, 14, 58, 34], fill=COLORS["bg"])
    draw.line([48, 34, 48, 58], fill=COLORS["bg"], width=3)
    draw.line([48, 42, 30, 55], fill=COLORS["bg"], width=3)
    draw.line([48, 42, 66, 55], fill=COLORS["bg"], width=3)
    draw.line([48, 58, 32, 78], fill=COLORS["bg"], width=3)
    draw.line([48, 58, 64, 78], fill=COLORS["bg"], width=3)

def icon_shared_activities(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["green"])
    # Two people holding hands
    for cx in [32, 64]:
        draw.ellipse([cx - 7, 16, cx + 7, 30], fill=COLORS["bg"])
        draw.rounded_rectangle([cx - 9, 32, cx + 9, 55], radius=4, fill=COLORS["bg"])
    draw.line([40, 44, 56, 44], fill=COLORS["bg"], width=3)

def icon_hygiene(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["accent"])
    # Water drop
    draw.polygon([CENTER, 18, 30, 50, 66, 50], fill=COLORS["bg"])
    draw.ellipse([28, 45, 68, 78], fill=COLORS["bg"])

def icon_clothing(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["pink"])
    # T-shirt shape
    draw.polygon([30, 25, 40, 25, 45, 35, 51, 35, 56, 25, 66, 25, 72, 40, 60, 48, 60, 75, 36, 75, 36, 48, 24, 40], fill=COLORS["bg"])

def icon_possessions(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["yellow"])
    # Key shape
    draw.ellipse([22, 22, 48, 48], outline=COLORS["primary"], width=3)
    draw.line([40, 48, 70, 48], fill=COLORS["primary"], width=3)
    draw.line([62, 48, 62, 58], fill=COLORS["primary"], width=3)
    draw.line([70, 48, 70, 55], fill=COLORS["primary"], width=3)

def icon_home(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["red"])
    # House
    draw.polygon([CENTER, 15, 18, 42, 78, 42], fill=COLORS["bg"])
    draw.rectangle([28, 42, 68, 75], fill=COLORS["bg"])
    draw.rectangle([40, 55, 56, 75], fill=COLORS["accent"])

def icon_general_objects(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["teal"])
    # Box
    draw.rectangle([22, 30, 74, 72], outline=COLORS["bg"], width=3)
    draw.line([22, 50, 74, 50], fill=COLORS["bg"], width=2)

def icon_computer(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["dark_blue"])
    # Monitor
    draw.rectangle([18, 18, 78, 58], outline=COLORS["bg"], width=3)
    draw.rectangle([24, 24, 72, 52], fill=COLORS["bg"])
    draw.rectangle([38, 58, 58, 65], fill=COLORS["bg"])
    draw.rectangle([30, 65, 66, 72], fill=COLORS["bg"])

def icon_school(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["orange"])
    # Book
    draw.rectangle([20, 22, 76, 72], outline=COLORS["bg"], width=2)
    draw.line([CENTER, 22, CENTER, 72], fill=COLORS["bg"], width=2)
    draw.line([28, 35, 44, 35], fill=COLORS["primary"], width=2)
    draw.line([28, 45, 44, 45], fill=COLORS["primary"], width=2)
    draw.line([52, 35, 68, 35], fill=COLORS["primary"], width=2)
    draw.line([52, 45, 68, 45], fill=COLORS["primary"], width=2)

def icon_leisure(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["purple"])
    # Music note
    draw.ellipse([25, 52, 40, 67], fill=COLORS["bg"])
    draw.line([38, 58, 38, 22], fill=COLORS["bg"], width=3)
    draw.line([38, 22, 60, 18, 60, 38], fill=COLORS["bg"], width=3)
    draw.ellipse([50, 48, 65, 63], fill=COLORS["bg"])

def icon_sport(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["green"])
    # Ball
    draw.ellipse([22, 22, 74, 74], fill=COLORS["bg"])
    draw.arc([22, 22, 74, 74], 0, 360, fill=COLORS["primary"], width=2)
    draw.line([22, CENTER, 74, CENTER], fill=COLORS["primary"], width=2)
    draw.line([CENTER, 22, CENTER, 74], fill=COLORS["primary"], width=2)

def icon_animals(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["brown"])
    # Paw print
    draw.ellipse([28, 45, 50, 68], fill=COLORS["bg"])
    for cx, cy in [(22, 30), (36, 22), (50, 22), (60, 30)]:
        draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=COLORS["bg"])

def icon_weather(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["accent"])
    # Sun and cloud
    draw.ellipse([38, 28, 74, 64], fill=COLORS["yellow"])
    draw.ellipse([14, 42, 50, 72], fill=COLORS["bg"])
    draw.ellipse([30, 38, 60, 62], fill=COLORS["bg"])

def icon_outside(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["green"])
    # Tree
    draw.rectangle([42, 55, 54, 78], fill=COLORS["brown"])
    draw.ellipse([22, 18, 74, 58], fill=COLORS["bg"])

def icon_places(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["blue"])
    # Map pin
    draw.ellipse([30, 16, 66, 52], outline=COLORS["bg"], width=3)
    draw.polygon([48, 52, 38, 78, 58, 78], fill=COLORS["bg"])

def icon_transport(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["red"])
    # Car shape
    draw.rounded_rectangle([14, 35, 82, 60], radius=6, fill=COLORS["bg"])
    draw.rounded_rectangle([22, 22, 68, 42], radius=4, fill=COLORS["bg"])
    draw.ellipse([22, 55, 36, 69], fill=COLORS["primary"])
    draw.ellipse([60, 55, 74, 69], fill=COLORS["primary"])

def icon_money(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["green"])
    draw.ellipse([18, 18, 78, 78], outline=COLORS["bg"], width=3)
    try:
        font = ImageFont.truetype("arial.ttf", 40)
    except:
        font = ImageFont.load_default()
    draw.text((28, 18), "$", fill=COLORS["bg"], font=font)

def icon_notices(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["orange"])
    # Exclamation triangle
    draw.polygon([CENTER, 14, 14, 78, 82, 78], outline=COLORS["bg"], width=3)
    draw.polygon([CENTER, 22, 22, 72, 74, 72], fill=COLORS["bg"])
    try:
        font = ImageFont.truetype("arial.ttf", 32)
    except:
        font = ImageFont.load_default()
    draw.text((38, 32), "!", fill=COLORS["primary"], font=font)

def icon_countries(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["dark_blue"])
    # Globe
    draw.ellipse([16, 16, 80, 80], outline=COLORS["bg"], width=2)
    draw.ellipse([16, 16, 80, 80], outline=COLORS["bg"], width=2)
    draw.arc([16, 16, 80, 80], 0, 360, fill=COLORS["bg"], width=2)
    draw.line([16, CENTER, 80, CENTER], fill=COLORS["bg"], width=2)
    draw.arc([30, 16, 66, 80], -80, 80, fill=COLORS["bg"], width=2)

def icon_religion(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["purple"])
    # Cross
    draw.rectangle([38, 18, 58, 78], fill=COLORS["bg"])
    draw.rectangle([22, 35, 74, 55], fill=COLORS["bg"])

def icon_gender(draw):
    draw.rounded_rectangle([10, 10, 86, 86], radius=12, fill=COLORS["pink"])
    # Male/Female symbols
    draw.ellipse([16, 28, 44, 56], outline=COLORS["bg"], width=3)
    draw.line([44, 28, 56, 16], fill=COLORS["bg"], width=3)
    draw.line([50, 16, 56, 16], fill=COLORS["bg"], width=3)
    draw.line([56, 16, 56, 22], fill=COLORS["bg"], width=3)
    # Female
    draw.ellipse([52, 42, 80, 70], outline=COLORS["bg"], width=3)
    draw.line([66, 36, 66, 48], fill=COLORS["bg"], width=3)
    draw.line([60, 42, 72, 42], fill=COLORS["bg"], width=3)


# Generate all icons
icons = [
    ("Sign Main", icon_sign_main),
    ("A-Z Of Sign", icon_az_sign),
    ("Manners and Greetings", icon_manners),
    ("Family and People", icon_family),
    ("Feelings and Health", icon_feelings),
    ("Questions", icon_questions),
    ("Grammatical Elements", icon_grammar),
    ("Prepositions", icon_prepositions),
    ("Descriptions and Attributes", icon_descriptions),
    ("Colours", icon_colours),
    ("Numbers", icon_numbers),
    ("Quantity and Measurement", icon_quantity),
    ("Time and Days", icon_time),
    ("Letters", icon_letters),
    ("Food and Drink", icon_food),
    ("Personal Actions", icon_personal_actions),
    ("Shared Activities", icon_shared_activities),
    ("Personal Hygiene", icon_hygiene),
    ("Clothing and Personal", icon_clothing),
    ("Personal Possessions", icon_possessions),
    ("Home and Household", icon_home),
    ("General Objects", icon_general_objects),
    ("Computer Items", icon_computer),
    ("School and Instructions", icon_school),
    ("Leisure Activities and Interests", icon_leisure),
    ("Sport", icon_sport),
    ("Animals and Nature", icon_animals),
    ("Weather", icon_weather),
    ("Outside", icon_outside),
    ("Places", icon_places),
    ("Transport and Vehicles", icon_transport),
    ("Money", icon_money),
    ("Public Notices", icon_notices),
    ("Other Countries", icon_countries),
    ("Religion and Customs", icon_religion),
    ("Gender and Sexuality", icon_gender),
]

for name, func in icons:
    create_icon(name, func)

print(f"\nAll {len(icons)} icons created in: {OUTPUT_DIR}")
