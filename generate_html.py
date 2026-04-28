import os
import html
from pathlib import Path

django_dir = Path('OPAS_Django')
flutter_dir = Path('OPAS_Flutter')
forecasting_dir = Path('demand_and_price_forecasting')

def get_files():
    files_to_print = []
    
    for folder in ['apps', 'core', 'utils']:
        d_path = django_dir / folder
        if d_path.exists():
            for root, _, files in os.walk(d_path):
                if '__pycache__' in root or 'migrations' in root:
                    continue
                for file in files:
                    if file.endswith('.py'):
                        files_to_print.append(os.path.join(root, file))
    
    for f in ['Dockerfile', 'docker-compose.yml', 'requirements.txt']:
        p = django_dir / f
        if p.exists():
            files_to_print.append(str(p))

    f_lib = flutter_dir / 'lib'
    if f_lib.exists():
        for root, _, files in os.walk(f_lib):
            for file in files:
                if file.endswith('.dart'):
                    files_to_print.append(os.path.join(root, file))
    
    p_yaml = flutter_dir / 'pubspec.yaml'
    if p_yaml.exists():
        files_to_print.append(str(p_yaml))
        
    if forecasting_dir.exists():
        for file in os.listdir(forecasting_dir):
            if file.endswith('.py'):
                files_to_print.append(str(forecasting_dir / file))
                
    return files_to_print

def generate_html():
    files = get_files()
    
    html_content = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Thesis Source Code</title>
    <style>
        body { font-family: monospace; font-size: 11px; line-height: 1.4; padding: 20px; }
        .file-header { background-color: #f0f0f0; padding: 10px; font-weight: bold; margin-top: 30px; border-bottom: 1px solid #ccc; font-size: 14px; page-break-before: always; }
        .file-header:first-child { page-break-before: avoid; margin-top: 0; }
        pre { white-space: pre-wrap; word-wrap: break-word; margin: 10px 0; }
        @media print {
            .file-header { background-color: #e0e0e0 !important; -webkit-print-color-adjust: exact; }
        }
    </style>
</head>
<body>
    <h1 style="text-align: center; margin-bottom: 50px; font-family: sans-serif;">Thesis Source Code Documentation</h1>
"""
    
    for file_path in files:
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            continue
            
        display_name = file_path.replace('\\', '/')
        escaped_content = html.escape(content)
        
        html_content += f"""
    <div class="file-header">File: {display_name}</div>
    <pre><code>{escaped_content}</code></pre>
"""
        
    html_content += """
</body>
</html>
"""
    
    output_path = "Source_Code_Ownership_Transfer.html"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    print(f"Successfully generated {output_path}")

if __name__ == '__main__':
    generate_html()
