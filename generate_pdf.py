import os
from fpdf import FPDF
from pathlib import Path

# Files to include
django_dir = Path('OPAS_Django')
flutter_dir = Path('OPAS_Flutter')
forecasting_dir = Path('demand_and_price_forecasting')

def get_files():
    files_to_print = []
    
    # 1. OPAS_Django/apps, core, utils
    for folder in ['apps', 'core', 'utils']:
        d_path = django_dir / folder
        if d_path.exists():
            for root, _, files in os.walk(d_path):
                if '__pycache__' in root or 'migrations' in root:
                    continue
                for file in files:
                    if file.endswith('.py'):
                        files_to_print.append(os.path.join(root, file))
    
    # Django Docker/Requirements
    for f in ['Dockerfile', 'docker-compose.yml', 'requirements.txt']:
        p = django_dir / f
        if p.exists():
            files_to_print.append(str(p))

    # 2. OPAS_Flutter/lib and pubspec.yaml
    f_lib = flutter_dir / 'lib'
    if f_lib.exists():
        for root, _, files in os.walk(f_lib):
            for file in files:
                if file.endswith('.dart'):
                    files_to_print.append(os.path.join(root, file))
    
    p_yaml = flutter_dir / 'pubspec.yaml'
    if p_yaml.exists():
        files_to_print.append(str(p_yaml))
        
    # 3. demand_and_price_forecasting (*.py)
    if forecasting_dir.exists():
        for file in os.listdir(forecasting_dir):
            if file.endswith('.py'):
                files_to_print.append(str(forecasting_dir / file))
                
    return files_to_print

class CodePDF(FPDF):
    def header(self):
        self.set_font("Courier", "B", 12)
        self.cell(0, 10, "Thesis Source Code Documentation", border=False, align="C")
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font("Courier", "I", 8)
        self.cell(0, 10, f"Page {self.page_no()}", align="C")

def generate_pdf():
    pdf = CodePDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    files = get_files()
    
    for file_path in files:
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            continue
            
        pdf.add_page()
        
        # File header
        pdf.set_font("Courier", "B", 14)
        pdf.set_fill_color(200, 220, 255)
        # Replacing backslashes with forward slashes for cross-platform aesthetic
        display_name = file_path.replace('\\', '/')
        pdf.multi_cell(0, 10, f"File: {display_name}", fill=True)
        pdf.ln(5)
        
        # File content
        pdf.set_font("Courier", size=7)
        
        # Split content into lines and handle very long lines
        for line in content.split('\n'):
            line = line.replace('\t', '    ') # replace tabs
            # FPDF core fonts don't support full unicode, encode to ascii to drop/replace bad chars
            line = line.encode('latin-1', 'replace').decode('latin-1')
            
            # Split line into chunks of 100 chars
            while len(line) > 100:
                pdf.cell(0, 3, text=line[:100], new_x="LMARGIN", new_y="NEXT")
                line = "  " + line[100:]
            if line:
                pdf.cell(0, 3, text=line, new_x="LMARGIN", new_y="NEXT")
            
    output_path = "Source_Code_Ownership_Transfer.pdf"
    pdf.output(output_path)
    print(f"Successfully generated {output_path}")

if __name__ == '__main__':
    generate_pdf()
