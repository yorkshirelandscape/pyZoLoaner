# pyZoLoaner

A tool to help GMs more easily make use of Paizo Organized Play's generous loaner PDF policy, which permits GMs to lend one copy at a time of a scenario PDF which they own to another GM for their temporary use.

This cross-platform tool adds custom watermarks for loaning a scenario PDF to another GM. Run the app, answer a couple questions, pick the PDF, and pyZoLoaner will create a new PDF with the watermarks applied. Just ask the GM to delete the file when they're done and make sure you keep track of what you've loaned out!

## Features
- Adds two watermarks to each page:
  - A vertical, bold, opaque string in the left margin containing your name/identifier and that of the borrower.
  - A large, semi-transparent, diagonal "LOANER" watermark under the content
- Prompts user for PDF file and watermark string via a simple dialog
- Cross-platform: works on Windows, macOS, and Linux 
- Scenarios released before October 2025 require that [Ghostscript](https://www.ghostscript.com/) be installed

## Installation
1. Download the appropriate executable from GitHub Releases: 
  - [MacOS](https://github.com/yorkshirelandscape/pyZoLoaner/releases/latest/pyZoLoaner-macos.zip)
  - [Windows](https://github.com/yorkshirelandscape/pyZoLoaner/releases/latest/pyZoLoaner-windows.zip)
  - [Linux](https://github.com/yorkshirelandscape/pyZoLoaner/releases/latest/pyZoLoaner-linux.zip)
2. Install Ghostscript:
  - Run the executable and follow the instructions or...
    - **macOS:** `brew install ghostscript`
    - **Windows:** `scoop install ghostscript`
    - **Linux:** Use your package manager (e.g., `sudo apt install ghostscript`)
    - **Download** from [Ghostscript.com](https://www.ghostscript.com/)

## Usage
Run the executable and follow the prompts:
- Enter your name or other identifier for the watermark
- Do the same for the borrower
- Select the PDF file to process
- The processed PDF will be saved as `!LOANER_<original_filename>.pdf` with watermarks applied

## Run from source or build your own executable

### Requirements
- [Python 3.13+](https://www.python.org/downloads/)
- Python packages:
  - `pymupdf`
  - `reportlab`
  - `pyinstaller`

### Recommended Build Process
1. Install pipenv: `pip install --user pipenv`
2. Clone the repository: `git clone https://github.com/yorkshirelandscape/pyZoLoaner.git`
3. Navigate into the directory: `cd pyZoLoaner`
4. Install dependencies: `pipenv install`
5. Build the executable: `pipenv run pyinstaller --onefile --windowed pyZoLoaner.py`
6. ???
7. PROFIT!!!

## License
MIT License