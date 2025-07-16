import os

# Skip these top-level directories unless they're 'lib' or 'assets'
IGNORED_DIRS = {
    'android', 'ios', 'macos', 'linux', 'windows', 'build', '.dart_tool',
    '.idea', '.vscode', '.git', 'web', 'logs', 'flutter'
}

# Only expand lib/ and assets/
EXPAND_DIRS = {'lib', 'assets'}

def generate_tree(path='.', prefix=''):
    try:
        entries = sorted(os.listdir(path))
    except PermissionError:
        return

    # Filter hidden/system files and ignored dirs (unless in EXPAND_DIRS)
    entries = [e for e in entries if not e.startswith('.') and (
        os.path.isfile(os.path.join(path, e)) or
        e in EXPAND_DIRS or path != '.'  # allow contents inside lib/assets
    ) and e not in IGNORED_DIRS]

    pointers = ['├── '] * (len(entries) - 1) + ['└── ']

    for i, entry in enumerate(entries):
        full_path = os.path.join(path, entry)
        is_dir = os.path.isdir(full_path)
        print(prefix + pointers[i] + entry)

        if is_dir and (entry in EXPAND_DIRS or path != '.'):
            extension = '│   ' if i < len(entries) - 1 else '    '
            generate_tree(full_path, prefix + extension)

if __name__ == '__main__':
    print("📁 Simplified Project Structure (root files + lib + assets):\n")
    generate_tree()
