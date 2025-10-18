import webbrowser
import shutil
import platform
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.colors import black, white
import fitz  # PyMuPDF
import tkinter as tk
from tkinter import filedialog, simpledialog
import webbrowser
import sys
import os
import random
import string
import subprocess
import datetime

#!/usr/bin/env python3
# loan_stamper.py
# Accepts a PDF file and a string, processes the PDF as described.

def check_ghostscript():
  system = platform.system()
  gs_exe = 'gswin64c' if system == 'Windows' else 'gs'
  gs_path = shutil.which(gs_exe)
  if gs_path:
    return True, gs_exe, gs_path

  sys_pms = {
    "Darwin": [
      { "exec": "brew", "install": "brew install ghostscript" },
      { "exec": "port", "install": "sudo port install ghostscript" },
    ],
    "Windows": [
      { "exec": "scoop", "install": "scoop install ghostscript" },
      { "exec": "choco", "install": "choco install ghostscript" },
    ],
    "Linux": [
      { "exec": "apt", "install": "sudo apt install ghostscript" },
      { "exec": "rpm", "install": "sudo rpm -i ghostscript" },
      { "exec": "pacman", "install": "sudo pacman -S ghostscript" },
    ]
  }

  pm_list = sys_pms.get(system, [])
  if pm_list:
    for pm in pm_list:
      pm_exec = pm["exec"]
      pm_install = pm["install"]
      if shutil.which(pm_exec):
        return False, pm_exec, pm_install
  else:
    return False, None, None
  # Ensure a tuple is always returned
  return False, None, None

def ghostscript_install_dialog(package_manager, install_cmd):
    root = tk.Tk()
    root.title("Ghostscript Required")
    root.geometry("400x180")
    label = tk.Label(root, text="Ghostscript is not installed.\nChoose an option:", pady=10)
    label.pack()
    text_install_or_info = f"Install ({package_manager})" if install_cmd else "More Info"
    def install_or_info():
        if install_cmd:
            try:
              subprocess.run(install_cmd, shell=True, check=True)
            except Exception as e:
              tk.Label(root, text=f"Install failed: {e}", fg="red").pack()
        else:
            webbrowser.open("https://ghostscript.com/")
        root.destroy()
    def download_gs():
        webbrowser.open("https://ghostscript.com/download/gsdnld.html")
        root.destroy()
    def close_app():
        root.destroy()
        sys.exit(1)
    btn_install = tk.Button(root, text=text_install_or_info, command=install_or_info, width=20)
    btn_install.pack(pady=5)
    btn_site = tk.Button(root, text="Download Ghostscript", command=download_gs, width=20)
    btn_site.pack(pady=5)
    btn_close = tk.Button(root, text="Close", command=close_app, width=20)
    btn_close.pack(pady=5)
    root.mainloop()

def ghostscript_print(input_pdf, output_pdf):
  gs_executable = 'gswin64c' if sys.platform.startswith('win') else 'gs'
  cmd = [
      gs_executable,
      '-q',
      '-dNOPAUSE',
      '-dBATCH',
        '-sDEVICE=pdfwrite',
        f'-sOutputFile={output_pdf}',
        input_pdf
    ]
  subprocess.run(cmd, check=True)

def random_password(length=16):
    chars = string.ascii_letters + string.digits + string.punctuation
    return ''.join(random.choices(chars, k=length))

def prompt_and_copy_pdf():
  root = tk.Tk()
  root.withdraw()
  lender = simpledialog.askstring("User", "Enter your full name, Discord, or email:")
  borrower = simpledialog.askstring("User", "Enter borrower full name, Discord, or email:")
  if not borrower or not lender: # if not a borrower or not a lender be... -- Polonius the Coder
    print("Required string not provided. Exiting.")
    sys.exit(1)
  pdf_path = filedialog.askopenfilename(
    title="Select PDF file to watermark",
    filetypes=[("PDF files", "*.pdf")]
  )
  if not pdf_path:
    print("No PDF file selected. Exiting.")
    sys.exit(1)
  # Prepend !LOANER_ to filename
  dir_name, base_name = os.path.split(pdf_path)
  temp_name = f"!TEMP_{base_name}"
  temp_pdf_path = os.path.join(dir_name, temp_name)
  loaner_name = f"!LOANER_{base_name}"
  loaner_pdf_path = os.path.join(dir_name, loaner_name)

  # Check if the PDF is encrypted
  is_encrypted = False
  try:
    with fitz.open(pdf_path) as test_doc:
      is_encrypted = test_doc.is_encrypted
  except Exception:
    is_encrypted = True  # If can't open, assume encrypted

  if is_encrypted:
    # Check for Ghostscript
    is_installed, exec, exec_path = check_ghostscript()

    if not is_installed:
      ghostscript_install_dialog(exec, exec_path)
      is_installed, exec, exec_path = check_ghostscript()
      if not is_installed:
        print("Ghostscript is required but not installed. Exiting.")
        sys.exit(1)
    # Print to file without encryption
    ghostscript_print(pdf_path, temp_pdf_path)
    print(f"Printed unencrypted PDF to {temp_pdf_path}")
    return lender, borrower, temp_pdf_path, loaner_pdf_path
  else:
    # No need to print to file, just use the original
    shutil.copy(pdf_path, temp_pdf_path)
    print("PDF is not encrypted; proceeding without Ghostscript.")
    return lender, borrower, temp_pdf_path, loaner_pdf_path

def create_diagonal_loaner_watermark(page_width, page_height):
  packet = BytesIO()
  c = canvas.Canvas(packet, pagesize=(page_width, page_height))
  font_name = "Helvetica-Bold"
  font_size = int(min(page_width, page_height) * 0.32)
  c.saveState()
  c.setFont(font_name, font_size)
  # Set semi-transparent gray
  c.setFillColorRGB(0.5, 0.5, 0.5, alpha=0.4)
  margin = 53  # px from left edge
  # Diagonal: rotate about center
  c.translate(page_width/2 + margin, page_height/2)
  c.rotate(52)
  c.drawCentredString(0, 0, "LOANER")
  c.restoreState()
  c.save()
  packet.seek(0)
  return packet.read()

def create_vertical_watermark(lender, borrower, page_width, page_height):
  today = datetime.date.today().strftime("%Y-%m-%d")
  full_text = "On loan to " + borrower + " from " + lender + ", " + today
  packet = BytesIO()
  c = canvas.Canvas(packet, pagesize=(page_width, page_height))
  font_name = "Helvetica-Bold"
  font_size = 15
  margin = 20  # px from left edge
  c.saveState()
  c.setFont(font_name, font_size)
  c.setFillColor(black, alpha=0.6)
  c.setStrokeColor(white, alpha=0.6)
  c.setLineWidth(0.35)
  c.translate(0, page_height/2)
  c.rotate(90)
  c.drawCentredString(0, -margin, full_text, mode=2)
  c.restoreState()
  c.save()
  packet.seek(0)
  return packet.read()

def main():
  # Step 0: Prompt for user string and PDF file
  lender, borrower, temp_pdf_path, loaner_pdf_path = prompt_and_copy_pdf()

  # Step 2: Open the input PDF (decrypted or original) for watermarking
  with fitz.open(temp_pdf_path) as doc_temp:
    # Get page dimensions from first page
    first_page = doc_temp[0]
    page_width, page_height = first_page.rect.width, first_page.rect.height

    # Create watermark PDFs once
    wm_loaner_pdf_bytes = create_diagonal_loaner_watermark(page_width, page_height)
    wm_loaner_pdf = fitz.open("pdf", wm_loaner_pdf_bytes)
    wm_user_pdf_bytes = create_vertical_watermark(lender, borrower, page_width, page_height)
    wm_user_pdf = fitz.open("pdf", wm_user_pdf_bytes)

    for page_num in range(len(doc_temp)):
        page = doc_temp[page_num]
        # --- Insert LOANER watermark beneath content ---
        page.show_pdf_page(page.rect, wm_loaner_pdf, 0, overlay=False)
        # --- Insert left-margin vertical watermark on top ---
        page.show_pdf_page(page.rect, wm_user_pdf, 0, overlay=True)

    # Save after watermarking to a temp file (unprotected)
    doc_temp.save(temp_pdf_path, encryption=0, incremental=1)

  # Step 3: Always save the final output with a random password
  with fitz.open(temp_pdf_path) as doc_loaner:
    pw = random_password()
    doc_loaner.save(loaner_pdf_path, encryption=4, owner_pw=pw)
    print(f"Watermarked PDF saved to: {loaner_pdf_path}")

  os.remove(temp_pdf_path)
  print(f"Temporary file {temp_pdf_path} removed.")

  # open file for display
  if sys.platform.startswith('win'):
    getattr(os, 'startfile', lambda x: None)(loaner_pdf_path)
  elif sys.platform.startswith('darwin'):
    subprocess.run(['open', loaner_pdf_path])
  else:
    subprocess.run(['xdg-open', loaner_pdf_path])

if __name__ == "__main__":
    main()
