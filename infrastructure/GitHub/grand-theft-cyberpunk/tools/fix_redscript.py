#!/usr/bin/env python3
"""
REDscript Syntax Fixer for MSN Integration
Fixes C# patterns that are invalid in REDscript:
- using statements → removed
- ++/-- → = ... + 1 / = ... - 1
- for (item: Type : array) → for (let i = 0; i < ArraySize(array); i = i + 1)
- @Property without parens → @Property()
"""

import re
from pathlib import Path


def fix_redscript(content: str) -> str:
    """Apply all REDscript syntax fixes."""
    lines = content.split('\n')
    fixed = []
    
    for line in lines:
        # Skip using statements entirely
        stripped = line.strip()
        if stripped.startswith('using '):
            continue
        
        # Fix @Property public let → @Property() public let
        if '@Property public let' in line and '@Property() public let' not in line:
            line = line.replace('@Property public let', '@Property() public let')
        
        # Fix ++ and -- in various contexts
        # For loop increment: i++ → i = i + 1
        # For loop decrement: i-- → i = i - 1
        # Standalone: x++ → x = x + 1; x-- → x = x - 1
        
        # Pattern: for (var i = 0; i < X; i++) or for (i: Int32 = 0; i < X; i++)
        # Fix the third expression
        # This is tricky - need to handle the for loop third clause
        
        # First, handle standalone ++/-- on separate lines
        # x++ → x = x + 1
        # x-- → x = x - 1
        
        # Match patterns like: var++ or obj.field++ or arr[i]++
        def repl_increment(m):
            var = m.group(1)
            return f"{var} = {var} + 1"
        
        def repl_decrement(m):
            var = m.group(1)
            return f"{var} = {var} - 1"
        
        # Standalone increments/decrements (at end of line or before semicolon/brace)
        line = re.sub(r'(\b\w+(?:\[\w+\]|\.\w+)*)\+\+(?=\s*[;}])', repl_increment, line)
        line = re.sub(r'(\b\w+(?:\[\w+\]|\.\w+)*)--(?=\s*[;}])', repl_decrement, line)
        
        # For loop third clause: i++) or i--) -- check inside for()
        # Pattern: for (...; ...; var++)  or for (...; ...; var--)
        def repl_for_increment(m):
            prefix = m.group(1)
            var = m.group(2)
            suffix = m.group(4)  # group 3 is the ++, group 4 is the optional )
            return f"{prefix}{var} = {var} + 1{suffix}"
        
        def repl_for_decrement(m):
            prefix = m.group(1)
            var = m.group(2)
            suffix = m.group(4)  # group 3 is the --, group 4 is the optional )
            return f"{prefix}{var} = {var} - 1{suffix}"
        
        # Match for(...; ...; var++) or for(...; ...; var--)
        line = re.sub(r'(for\s*\([^;]*;[^;]*;\s*)(\w+)(\+\+)(\)?)', repl_for_increment, line)
        line = re.sub(r'(for\s*\([^;]*;[^;]*;\s*)(\w+)(--)(\)?)', repl_for_decrement, line)
        
        # Fix C# foreach pattern: for (item : array) or for (item in array)
        # REDscript doesn't support this - use index-based loop
        # Pattern: for (name : array_expression) or for (name in array_expression)
        foreach_match = re.match(r'^(\s*)for\s*\(\s*(\w+)\s*[:in]+\s+([^\)]+)\)\s*{?\s*$', line)
        if foreach_match:
            indent = foreach_match.group(1)
            item_var = foreach_match.group(2)
            array_expr = foreach_match.group(3).strip()
            
            # Generate index-based loop
            loop_var = f"i_{item_var}"
            fixed.append(f"{indent}for (let {loop_var}: Int32 = 0; {loop_var} < ArraySize({array_expr}); {loop_var} = {loop_var} + 1) {{")
            fixed.append(f"{indent}    let {item_var} = {array_expr}[{loop_var}];")
            continue
        
        # Also handle foreach without opening brace on same line
        foreach_match2 = re.match(r'^(\s*)for\s*\(\s*(\w+)\s*[:in]+\s+([^\)]+)\)\s*$', line)
        if foreach_match2 and not line.strip().endswith('{'):
            indent = foreach_match2.group(1)
            item_var = foreach_match2.group(2)
            array_expr = foreach_match2.group(3).strip()
            loop_var = f"i_{item_var}"
            fixed.append(f"{indent}for (let {loop_var}: Int32 = 0; {loop_var} < ArraySize({array_expr}); {loop_var} = {loop_var} + 1) {{")
            fixed.append(f"{indent}    let {item_var} = {array_expr}[{loop_var}];")
            continue
        
        # Fix C# foreach pattern: for (key, value : map) or for (key, value in map)
        # Pattern: for (key, value : map_expression) or for (key, value in map_expression)
        foreach_kv_match = re.match(r'^(\s*)for\s*\(\s*(\w+)\s*,\s*(\w+)\s*[:in]+\s*([^\)]+)\)\s*{?\s*$', line)
        if foreach_kv_match:
            indent = foreach_kv_match.group(1)
            key_var = foreach_kv_match.group(2)
            val_var = foreach_kv_match.group(3)
            map_expr = foreach_kv_match.group(4).strip()
            
            loop_var = f"i_{key_var}"
            fixed.append(f"{indent}for (let {loop_var}: Int32 = 0; {loop_var} < ArraySize({map_expr}.Keys()); {loop_var} = {loop_var} + 1) {{")
            fixed.append(f"{indent}    let {key_var} = {map_expr}.Keys()[{loop_var}];")
            fixed.append(f"{indent}    let {val_var} = {map_expr}.Values()[{loop_var}];")
            continue
        
        foreach_kv_match2 = re.match(r'^(\s*)for\s*\(\s*(\w+)\s*,\s*(\w+)\s*[:in]+\s*([^\)]+)\)\s*$', line)
        if foreach_kv_match2 and not line.strip().endswith('{'):
            indent = foreach_kv_match2.group(1)
            key_var = foreach_kv_match2.group(2)
            val_var = foreach_kv_match2.group(3)
            map_expr = foreach_kv_match2.group(4).strip()
            
            loop_var = f"i_{key_var}"
            fixed.append(f"{indent}for (let {loop_var}: Int32 = 0; {loop_var} < ArraySize({map_expr}.Keys()); {loop_var} = {loop_var} + 1) {{")
            fixed.append(f"{indent}    let {key_var} = {map_expr}.Keys()[{loop_var}];")
            fixed.append(f"{indent}    let {val_var} = {map_expr}.Values()[{loop_var}];")
            continue
        
        fixed.append(line)
    
    # Post-process: Need to add closing braces for converted foreach loops
    # This is a simplification - we assume each foreach gets a closing brace
    # A more robust approach would track indentation
    result_lines = []
    foreach_depth = 0
    
    for i, line in enumerate(fixed):
        result_lines.append(line)
        # Track opening braces from converted loops
        if 'for (let i_' in line and '= 0; i_' in line and 'ArraySize' in line:
            foreach_depth += 1
        if line.strip() == '}' and foreach_depth > 0:
            # Check if this might close a foreach block
            # Heuristic: if previous non-empty line doesn't have {
            pass
    
    return '\n'.join(fixed)


def fix_file(filepath: Path, dry_run: bool = False) -> bool:
    """Fix a single REDscript file."""
    content = filepath.read_text()
    fixed = fix_redscript(content)
    
    if content == fixed:
        return False
    
    if not dry_run:
        filepath.write_text(fixed)
        print(f"  ✓ Fixed: {filepath.name}")
    else:
        print(f"  [DRY RUN] Would fix: {filepath.name}")
    return True


def main():
    import sys
    
    script_dir = Path("/mnt/d/Games/steamapps/common/Cyberpunk 2077/r6/scripts/msn_integration")
    if not script_dir.exists():
        script_dir = Path(__file__).resolve().parents[1] / "scripts"
    
    dry_run = '--dry-run' in sys.argv or '-n' in sys.argv
    
    if dry_run:
        print("=== DRY RUN MODE ===")
    
    scripts = list(script_dir.rglob("*.reds"))
    print(f"Found {len(scripts)} REDscript files")
    
    fixed_count = 0
    for script in scripts:
        if fix_file(script, dry_run):
            fixed_count += 1
    
    print(f"\n{'Would fix' if dry_run else 'Fixed'} {fixed_count} files")
    
    if dry_run:
        print("\nRun without --dry-run to apply fixes")
    
    return 0 if fixed_count >= 0 else 1


if __name__ == "__main__":
    exit(main())