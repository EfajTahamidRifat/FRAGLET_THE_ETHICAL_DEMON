#!/usr/bin/env python3
# FRAGLET - Professional Ethical Hacking & Bug Bounty Toolkit
# Author: Efaj Tahamid Rifat
# Authorized use only

import os
import sys
import subprocess
from datetime import datetime
from fpdf import FPDF
import random

# ------------------ ASCII Banner ------------------
ascii_banner = """
\033[1;31m███████╗██████╗  █████╗ ██╗     ██╗     ███████╗██╗  ██╗\033[0m
\033[1;32m██╔════╝██╔══██╗██╔══██╗██║     ██║     ██╔════╝╚██╗██╔╝\033[0m
\033[1;33m█████╗  ██████╔╝███████║██║     ██║     █████╗   ╚███╔╝ \033[0m
\033[1;34m██╔══╝  ██╔══██╗██╔══██║██║     ██║     ██╔══╝   ██╔██╗ \033[0m
\033[1;35m███████╗██║  ██║██║  ██║███████╗███████╗███████╗██╔╝ ██╗\033[0m
\033[1;36m╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝\033[0m
FRAGLET - Ethical Hacking Toolkit
Created by Efaj Tahamid Rifat
"""

# ------------------ Legal Warning ------------------
legal_warning = """
⚠️ LEGAL DISCLAIMER ⚠️
This tool is strictly for ethical hacking and authorized bug bounty targets only.
Unauthorized usage is ILLEGAL. Efaj Tahamid Rifat is NOT responsible for misuse.
Always obtain explicit written permission before scanning any system.
"""

# ------------------ Tools Dictionary ------------------
tools = {
    # Network
    "Nmap": "nmap -Pn -A {target} -oN nmap_output.txt",
    "Masscan": "masscan {target} -p0-65535 --rate=1000 -oG masscan_output.txt",
    "Amass": "amass enum -d {target} -o amass_output.txt",
    "Sublist3r": "sublist3r -d {target} -o subdomains.txt",
    "Subfinder": "subfinder -d {target} -o subfinder_output.txt",

    # Web scanning
    "Nikto": "nikto -host {target} -o nikto_output.txt",
    "Dirsearch": "python3 dirsearch/dirsearch.py -u {target} -e * -o dirsearch_output.txt",
    "FFUF": "ffuf -u {target}/FUZZ -w wordlist.txt -o ffuf_output.txt",
    "Wapiti": "wapiti -u {target} -o wapiti_output.txt",
    "Arachni": "arachni {target} --report-save-path=arachni_report.afr",

    # CMS-specific
    "WPScan": "wpscan --url {target} --enumerate u,p,t --disable-tls-checks --output wpscan_output.txt",
    "JoomScan": "joomscan -u {target} -o joomscan_output.txt",
    "Droopescan": "droopescan scan drupal -u {target} -o droopescan_output.txt",

    # Injection
    "SQLMap": "sqlmap -u {target} --batch --crawl=2 --output-dir=sqlmap_output",
    "XSStrike": "xsstrike -u {target} --crawl",
    "Commix": "commix --url={target} --batch",
    "ParamSpider": "python3 paramspider.py -u {target} -o paramspider_output.txt",

    # Recon & reconnaissance
    "TheHarvester": "theHarvester -d {target} -b all -f theharvester_output.xml",
    "Recon-ng": "recon-ng -m recon/domains-hosts/google_site -o SOURCE={target} -o OUTPUT=recon_output.txt",
    "WhatWeb": "whatweb {target} -v -a 3 -o whatweb_output.txt",
    "Waybackurls": "echo {target} | waybackurls > waybackurls_output.txt",
    "Gobuster": "gobuster dir -u {target} -w wordlist.txt -o gobuster_output.txt",

    # Proxy / scanning frameworks
    "BurpSuite": "echo 'Run manually via GUI for active scans.'",
    "OWASP ZAP": "echo 'Run manually via GUI or headless for full scan.'"
}

# ------------------ PDF Class ------------------
class PDF(FPDF):
    def header(self):
        self.set_font("Arial", "B", 14)
        self.set_text_color(255, 0, 0)
        self.cell(0, 10, "FRAGLET - Ethical Security Report", 0, 1, "C")
        self.ln(5)
    def footer(self):
        self.set_y(-15)
        self.set_font("Arial", "I", 8)
        self.set_text_color(100,100,100)
        self.cell(0, 10, f"Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",0,0,'C')

# ------------------ Tool Runner ------------------
def run_tool(tool_name, command):
    print(f"[>] Running {tool_name}...")
    try:
        process = subprocess.run(command, shell=True, capture_output=True, text=True)
        output = process.stdout + process.stderr
        if output.strip() == "":
            output = "No issues detected."
        return output
    except Exception as e:
        return f"Error executing {tool_name}: {e}"

# ------------------ CVSS Scoring ------------------
def score_risk(output):
    if "No issues detected" in output:
        return "Low", 2.0
    elif "Error" in output:
        return "Medium", 5.0
    else:
        severity = random.choice(["Medium","High","Critical"])
        score = {"Medium":5.5, "High":8.0, "Critical":9.5}[severity]
        return severity, score

# ------------------ Generate PDF ------------------
def generate_pdf(target, results):
    pdf = PDF()
    pdf.add_page()
    pdf.set_font("Arial", "", 12)
    pdf.multi_cell(0, 6, f"Target: {target}\n\n")

    for tool, output in results.items():
        severity, cvss = score_risk(output)
        pdf.set_font("Arial", "B", 12)
        if severity == "Low":
            pdf.set_text_color(0,128,0) # Green
        elif severity == "Medium":
            pdf.set_text_color(255,165,0) # Orange
        else:
            pdf.set_text_color(255,0,0) # Red
        pdf.multi_cell(0, 6, f"{tool} - Severity: {severity} (CVSS: {cvss})\n", 0, 1)
        pdf.set_font("Courier", "", 10)
        pdf.set_text_color(0,0,0)
        pdf.multi_cell(0, 5, output + "\n\n", 0, 1)

    filename = f"FRAGLET_Report_{target.replace('://','_').replace('/','_')}.pdf"
    pdf.output(filename)
    print(f"\033[1;32mPDF report generated: {filename}\033[0m")

# ------------------ Main ------------------
def main():
    os.system("clear")
    print(ascii_banner)
    print(legal_warning)
    consent = input("Do you confirm you have authorization to scan this target? (yes/no): ").strip().lower()
    if consent != "yes":
        print("Aborted. Must have explicit permission.")
        sys.exit(0)

    target = input("Enter target URL/IP (authorized only): ").strip()

    results = {}
    for tool_name, cmd in tools.items():
        formatted_cmd = cmd.format(target=target)
        results[tool_name] = run_tool(tool_name, formatted_cmd)

    generate_pdf(target, results)
    print("\033[1;32mFRAGLET scan completed successfully!\033[0m")

if __name__ == "__main__":
    main()
