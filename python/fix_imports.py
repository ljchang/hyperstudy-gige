#!/usr/bin/env python3
"""
Fix import paths after moving to python directory
"""

import os
import re

def fix_imports_in_file(filepath):
    """Fix sys.path.append statements in a file"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Pattern to match sys.path.append lines
    pattern = r'sys\.path\.append\(str\(Path\(__file__\)\.parent(?:\.parent)?\)\)'
    
    # Check if file is in examples, src, or root of python dir
    rel_path = os.path.relpath(filepath, '/Users/lukechang/Github/hyperstudy-gige/python')
    depth = len(rel_path.split('/')) - 1
    
    if depth == 0:  # Files in python/ root
        new_import = 'sys.path.append(str(Path(__file__).parent))'
    elif depth == 1:  # Files in subdirectories like examples/, src/
        new_import = 'sys.path.append(str(Path(__file__).parent.parent))'
    else:
        new_import = 'sys.path.append(str(Path(__file__).parent.parent.parent))'
    
    # Replace the import
    new_content = re.sub(pattern, new_import, content)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Fixed: {filepath}")
    else:
        print(f"No changes needed: {filepath}")

# Fix all Python files
python_files = [
    './quick_test.py',
    './debug_camera.py',
    './test_aravis_camera.py',
    './test_harvesters_sim.py',
    './examples/list_cameras.py',
    './examples/basic_viewer.py',
    './examples/livekit_streamer.py',
    './view_camera_ip.py',
    './src/gige_viewer.py',
    './src/gige_livekit_streamer.py'
]

os.chdir('/Users/lukechang/Github/hyperstudy-gige/python')

for file in python_files:
    if os.path.exists(file):
        fix_imports_in_file(file)

print("\nDone!")