import os
import re
import sys

def check_file(path):
    print(f"--- {path} ---")
    try:
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines):
            if 'Theme.of(context)' in line and 'Brightness.dark' not in line:
                print(f"{i+1}: {line.strip()}")
    except Exception as e:
        print(f"Error reading {path}: {e}")

files_to_check = [
    "lib/screens/groups/group_chat_screen.dart",
    "lib/screens/groups/group_details_screen.dart",
    "lib/screens/groups/manage_members_screen.dart",
    "lib/screens/home/post_comments_screen.dart",
    "lib/screens/home/widgets/post_comments_sheet.dart",
    "lib/screens/library/my_library_screen.dart",
    "lib/screens/library/university_library_screen.dart",
    "lib/screens/library/upload_screen.dart",
    "lib/screens/library/edit_file_screen.dart",
    "lib/screens/library/pdf_viewer_screen.dart",
    "lib/screens/library/file_details_screen.dart",
]

for f in files_to_check:
    check_file(f)

