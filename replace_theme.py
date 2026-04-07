import os
import re

directory = r"c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library"
pattern = re.compile(r'LibraryTheme\.(primary|secondary|bg|surface|text|muted|border|danger|success|accent)\b(?!\()')

changed_files = 0
total_replacements = 0

for root, dirs, files in os.walk(directory):
    for filename in files:
        if filename == "library_theme.dart":
            continue
        if filename.endswith(".dart"):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content, count = pattern.subn(r'LibraryTheme.\1(context)', content)
            
            if count > 0:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filename}: {count} replacements")
                changed_files += 1
                total_replacements += count

print(f"Done. Changed {changed_files} files with {total_replacements} total replacements.")
