# pyZoLoaner

A tool to help GMs more easily make use of Paizo's generous loander PDF policy, which states that everyone is entitled to two copies of a scenario PDF: one for themselves and one to loan to another GM.

This cross-platform tool removes the weak PDF password protection from the PDF and adds custom watermarks for loaning a scenario PDF to another GM before locking the file back down with a random password. Just ask the GM to delete the file when they're done and make sure you keep track of what you've loaned out!

## Features
- Removes weak password protection from PDFs using Ghostscript (print-to-file method)
- Adds two watermarks to each page:
  - A vertical, bold, opaque string in the left margin containing your name/identifier and that of the borrower.
  - A large, semi-transparent, diagonal "LOANER" watermark under the content
- Prompts user for PDF file and watermark string via a simple dialog
- Saves the final PDF with a randomized, unrevealed password
- Cross-platform: works on Windows, macOS, and Linux (with Ghostscript installed)

## Requirements
- [Ghostscript](https://www.ghostscript.com/) (must be installed and in PATH to remove PDF passwords)

## Installation
1. Download the appropriate executable from GitHub Releases: 
  - [MacOS](https://github.com/yorkshirelandscape/pyZoLoaner/releases/latest/pyZoLoaner.dmg)
  - [Windows](https://github.com/yorkshirelandscape/pyZoLoaner/releases/latest/pyZoLoaner.exe)
  - [Linux](https://github.com/yorkshirelandscape/pyZoLoaner/releases/latest/pyZoLoaner)
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
- The processed PDF will be saved as `!LOANER_<original_filename>.pdf` with watermarks and a random password

## Build Requirements
- [Python 3.7+](https://www.python.org/downloads/)
- Python packages:
  - `pymupdf`
  - `reportlab`

## Recommended Build Process
1. Install pipenv: `pip install --user pipenv`
2. Clone the repository: `git clone https://github.com/yorkshirelandscape/pyZoLoaner.git`
3. Navigate into the directory: `cd pyZoLoaner`
4. Install dependencies: `pipenv install`
5. ???
6. PROFIT!!!

## License
MIT License