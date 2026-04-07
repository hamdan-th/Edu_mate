import os
import re

directory = r"c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library"

# regex to match "const " before an uppercase letter (likely a class constructor), or before [ or {
pattern_class = re.compile(r'\bconst\s+(?=[A-Z])')
pattern_list = re.compile(r'\bconst\s+(?=\[)')
pattern_map = re.compile(r'\bconst\s+(?=\{)')

changed_files = 0

for root, dirs, files in os.walk(directory):
    for filename in files:
        if filename.endswith(".dart"):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            orig_content = content
            content = pattern_class.sub('', content)
            content = pattern_list.sub('', content)
            content = pattern_map.sub('', content)

            if content != orig_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                changed_files += 1

print(f"Removed const from {changed_files} files.")
