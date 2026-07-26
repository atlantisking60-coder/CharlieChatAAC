import os, re

base = r'C:\Users\Craig\Downloads\Charlie Chat'

# Read the log file - we'll extract prebuilt IDs from the error messages
log_text = """
prebuilt_school_people prebuilt_gods_titans_heroes_monsters prebuilt_heroes_monsters_greek_roman
prebuilt_disney_stories prebuilt_d_d prebuilt_arthurian_legend prebuilt_arabian_middle_eastern_tales
prebuilt_asian_legends_folklore prebuilt_horror_icons prebuilt_legendary_heroes_folk_heroes
prebuilt_literary_gothic_characters prebuilt_religion_worldviews prebuilt_marvel prebuilt_x_men
prebuilt_dc prebuilt_the_muppets prebuilt_star_wars prebuilt_star_trek prebuilt_the_lord_of_the_rings
prebuilt_computer_games prebuilt_1940_pinocchio prebuilt_1940_fantasia prebuilt_1941_dumbo
prebuilt_1942_bambi prebuilt_1950_cinderella prebuilt_1951_alice_in_wonderland prebuilt_1953_peter_pan
prebuilt_1955_lady_the_tramp prebuilt_1959_sleeping_beauty prebuilt_1961_101_dalmatians
prebuilt_1963_the_sword_in_the_stone prebuilt_1967_the_jungle_book prebuilt_1970_the_aristocats
prebuilt_1973_robin_hood prebuilt_1977_winnie_the_pooh prebuilt_1977_the_rescuers
prebuilt_1981_the_fox_the_hound prebuilt_1985_the_black_cauldron prebuilt_1986_the_great_mouse_detective
prebuilt_1988_oliver_company prebuilt_1989_the_little_mermaid prebuilt_1991_beauty_the_beast
prebuilt_1992_aladdin prebuilt_1993_the_nightmare_before_christmas prebuilt_1994_the_lion_king
prebuilt_1995_pocahontas prebuilt_1995_toy_story prebuilt_1996_the_hunchback_of_notre_dame
prebuilt_1997_hercules prebuilt_1998_mulan prebuilt_1998_a_bug_s_life prebuilt_1999_tarzan
prebuilt_2000_dinosaur prebuilt_2000_the_emperor_s_new_groove prebuilt_2001_atlantis_the_lost_empire
prebuilt_2001_monsters_inc prebuilt_2002_lilo_stitch prebuilt_2002_treasure_planet
prebuilt_2003_brother_bear prebuilt_2003_finding_nemo prebuilt_2004_home_on_the_range
prebuilt_2004_the_incredibles prebuilt_2005_chicken_little prebuilt_2006_cars
prebuilt_2007_meet_the_robinsons prebuilt_2007_ratatouille prebuilt_2008_bolt
prebuilt_2008_wall_e prebuilt_2009_the_princess_the_frog prebuilt_2009_up prebuilt_2010_tangled
prebuilt_2012_wreck_it_ralph prebuilt_2012_brave prebuilt_2013_frozen prebuilt_2014_big_hero_6
prebuilt_2015_inside_out prebuilt_2015_the_good_dinosaur prebuilt_2016_zootopia prebuilt_2016_moana
prebuilt_2017_coco prebuilt_2020_onward prebuilt_2020_soul prebuilt_2021_raya_the_last_dragon
prebuilt_2021_encanto prebuilt_2021_luca prebuilt_2022_turning_red prebuilt_2022_strange_world
prebuilt_2023_wish prebuilt_2023_elemental prebuilt_2025_elio prebuilt_rooms_home prebuilt_furniture
prebuilt_internal_organs prebuilt_time_clocks prebuilt_special_days prebuilt_world_map
prebuilt_baycroft_expects prebuilt_subject_vocabulary prebuilt_sentence_creator
prebuilt_small_words_subject prebuilt_letters_subject prebuilt_numbers_subject
prebuilt_breaktime prebuilt_lunchtime prebuilt_tutor_time prebuilt_english prebuilt_maths
prebuilt_science prebuilt_t_f_l_i_t prebuilt_p_d prebuilt_p_e_e_p prebuilt_e_p_i_c prebuilt_p_e
prebuilt_art prebuilt_performing_arts prebuilt_sustainability prebuilt_cooking
prebuilt_resistant_materials prebuilt_textiles prebuilt_music prebuilt_horticulture prebuilt_retail
prebuilt_photography prebuilt_construction prebuilt_engineering prebuilt_design_technology
prebuilt_hair_beauty prebuilt_health_social_care prebuilt_public_services prebuilt_s_t_e_m
prebuilt_option_a prebuilt_option_b prebuilt_option_c prebuilt_tech_rotation prebuilt_sign_main
prebuilt_a-z_of_sign prebuilt_manners_greetings prebuilt_family_people prebuilt_animals_nature
prebuilt_transport_vehicles prebuilt_food_drink prebuilt_home_household prebuilt_feelings_health
prebuilt_school_instructions prebuilt_descriptions_attributes prebuilt_outside prebuilt_time_days
prebuilt_questions prebuilt_personal_actions prebuilt_shared_activities
prebuilt_leisure_activities_interests prebuilt_general_objects prebuilt_clothing_personal
prebuilt_personal_possessions prebuilt_personal_hygiene prebuilt_gender_sexuality prebuilt_sport
prebuilt_religion_customs prebuilt_other_countries prebuilt_public_notices prebuilt_computer_items
prebuilt_grammatical_elements prebuilt_quantity_measurement prebuilt_q_sign prebuilt_v_sign
prebuilt_x_sign prebuilt_y_sign prebuilt_z_sign prebuilt_small_words prebuilt_passover_keywords
"""

# Extract unique IDs
ids_from_log = set()
for word in log_text.split():
    word = word.strip()
    if word.startswith('prebuilt_'):
        ids_from_log.add(word)

# Now find all JSON files that actually exist on disk
existing = set()
existing_paths = {}
for root, dirs, files in os.walk(os.path.join(base, 'lib', 'data', 'boards')):
    for f in files:
        if f.endswith('.json'):
            name = f.replace('.json', '')
            existing.add(name)
            rel = os.path.join(root, f).replace(base + '\\', '').replace('\\', '/')
            existing_paths[name] = rel

# Find IDs referenced in log that DON'T exist on disk
missing = ids_from_log - existing
found = ids_from_log & existing

print(f'=== Board IDs from error log: {len(ids_from_log)} ===')
print(f'=== Found on disk: {len(found)} ===')
print(f'=== MISSING from disk: {len(missing)} ===')
print()

print('--- MISSING JSON files (need to be created) ---')
for m in sorted(missing):
    # Guess the board name from the ID
    nice_name = m.replace('prebuilt_', '').replace('_', ' ').title()
    print(f'  ID: {m}')
    print(f'    Expected flat path: lib/data/boards/<Area>/{m}.json')
    print()

print('--- FOUND JSON files (already on disk) ---')
for f in sorted(found):
    print(f'  {existing_paths[f]}')
