import re
text = open('lib/data/board_hierarchy.dart').read()
pattern = r"BoardHierarchyEntry\('([^']+)',\s*'([^']+)'\s*(?:,\s*'([^']+)')?\)"
const_start = text.find('const List<BoardHierarchyEntry> boardHierarchy = [')
const_end = text.find('];', const_start)
const_text = text[const_start:const_end]
entries = re.findall(pattern, const_text)

# Common top-level boards
common_top = [(name, area, parent) for name, area, parent in entries if area == 'Common' and not parent]

# ALL names in non-Common areas (including sub-boards)
other_names = set()
for name, area, parent in entries:
    if area != 'Common':
        other_names.add(name.lower())

collisions = [n for n, _, _ in common_top if n.lower() in other_names]
print('Collisions (Common top-level boards with same name ANYWHERE in other areas):')
for c in collisions:
    # find all entries with this name
    all_matches = [(name, area, parent) for name, area, parent in entries if name.lower() == c.lower()]
    for name, area, parent in all_matches:
        print(f'  {name} -> area={area}, parent={parent}')
print(f'\nCount: {len(collisions)} out of {len(common_top)} Common top-level boards')
print()

# Predict the order the user would see
# Step 1: boards found by hierarchyTopLevel('Common'), sorted by runtimeBoardHierarchy index
step1 = [n for n, _, _ in common_top if n.lower() not in other_names]
# Step 2: remaining boards, sorted by prebuiltBoardNames.indexOf = first occurrence in runtimeBoardHierarchy
step2 = [n for n, _, _ in common_top if n.lower() in other_names]

# For step 2, sort by position in the original hierarchy
name_to_index = {}
for i, (name, area, parent) in enumerate(entries):
    key = name.lower()
    if key not in name_to_index:  # first occurrence
        name_to_index[key] = i

step2_sorted = sorted(step2, key=lambda n: name_to_index[n.lower()])

print("Predicted tab order:")
for i, n in enumerate(step1, 1):
    print(f'  {i}. {n} (step 1)')
for n in step2_sorted:
    i += 1
    print(f'  {i}. {n} (step 2)')

print("\nUser reports:")
user_order = ['common words', 'small words', 'feelings', 'actions', 'Body parts', 
              'jobs and careers', 'Animals', 'clothes', 'toys', 'transport', 'world map',
              'letters', 'numbers', 'people', 'places', 'colours', 'prepositions', 
              'weather', 'time', 'money']
for i, n in enumerate(user_order, 1):
    print(f'  {i}. {n}')
