import os
import re

def find_hardcoded_strings(directory):
    pattern1 = re.compile(r"Text\('([^']+)'\)")
    pattern2 = re.compile(r"label:\s*'([^']+)'")
    pattern3 = re.compile(r"title:\s*'([^']+)'")
    pattern4 = re.compile(r"hintText:\s*'([^']+)'")
    
    results = []
    
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart') or file.endswith('.g.dart') or file.endswith('.freezed.dart'):
                continue
                
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                
            for i, line in enumerate(lines):
                if 'AppLocalization' in line or 'strings[' in line:
                    continue # likely already localized
                
                matches = pattern1.findall(line) + pattern2.findall(line) + pattern3.findall(line) + pattern4.findall(line)
                for m in matches:
                    if len(m) > 1 and not m.startswith('http'):
                        results.append(f"{filepath}:{i+1}: {m}")
                        
    for r in results:
        print(r)

if __name__ == '__main__':
    find_hardcoded_strings('/home/younis/AndroidStudioProjects/setter project/untitled/lib')
