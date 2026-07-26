import os

d = r'C:\Users\Craig\Downloads\Charlie Chat\assets\sign\00. A-Z of Sign'
files = [f for f in os.listdir(d) if f.lower().endswith('.png')]
with open(r'C:\Users\Craig\Downloads\Charlie Chat\tools\sign_image_count.txt', 'w') as out:
    out.write(f'Total PNG files: {len(files)}\n')
    out.write('First 10:\n')
    for f in files[:10]:
        out.write(f'  {f}\n')
