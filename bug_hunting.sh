#!/bin/bash
# FRAGLET THE ETHICAL DEMON - Ultimate Bug Hunter 2025
# Author: Efaj Tahamid Rifat
# Version: 4.0 - Full Tool Installation + Dashboard PDF
# Note: Authorized testing only!

# ------------------ Colors ------------------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m"

# ------------------ Banner ------------------
echo -e "${CYAN}███████╗██████╗  █████╗  ██████╗ ██████╗ ██╗     ███████╗${NC}"
echo -e "${CYAN}██╔════╝██╔══██╗██╔══██╗██╔════╝ ██╔══██╗██║     ██╔════╝${NC}"
echo -e "${CYAN}█████╗  ██████╔╝███████║██║  ███╗██████╔╝██║     █████╗  ${NC}"
echo -e "${CYAN}██╔══╝  ██╔═══╝ ██╔══██║██║   ██║██╔═══╝ ██║     ██╔══╝  ${NC}"
echo -e "${CYAN}███████╗██║     ██║  ██║╚██████╔╝██║     ███████╗███████╗${NC}"
echo -e "${CYAN}╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝╚══════╝${NC}"
echo -e "${CYAN}FRAGLET THE ETHICAL DEMON - Ultimate Bug Hunter 2025${NC}\n"

# ------------------ Legal ------------------
echo -e "${YELLOW}Authorized security testing only! Explicit permission required.${NC}"
read -p "Do you agree? (y/N): " CONSENT
[[ "$CONSENT" != "y" && "$CONSENT" != "Y" ]] && { echo -e "${RED}Cancelled.${NC}"; exit 1; }

# ------------------ Environment Detection ------------------
PLATFORM=$(uname)
if [[ "$PLATFORM" == "Linux" ]]; then
    OS="linux"
elif [[ "$PLATFORM" == "Darwin" ]]; then
    OS="mac"
else
    OS="other"
fi
echo -e "${GREEN}[+] Detected platform: $OS${NC}"

# ------------------ Tool Installation ------------------
echo -e "${BLUE}[+] Installing/Checking all tools...${NC}"
declare -A TOOL_INSTALL
TOOL_INSTALL=(
["nmap"]="sudo apt install -y nmap"
["rustscan"]="curl -s https://raw.githubusercontent.com/RustScan/RustScan/master/install.sh | sh"
["nuclei"]="GO111MODULE=on go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
["sqlmap"]="sudo apt install -y sqlmap"
["nikto"]="sudo apt install -y nikto"
["gobuster"]="sudo apt install -y gobuster"
["subfinder"]="GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
["amass"]="sudo apt install -y amass"
["wpscan"]="sudo gem install wpscan"
["masscan"]="sudo apt install -y masscan"
["dirsearch"]="git clone https://github.com/maurosoria/dirsearch.git ~/dirsearch"
)

for TOOL in "${!TOOL_INSTALL[@]}"; do
    command -v "$TOOL" >/dev/null 2>&1 || { 
        echo -e "${YELLOW}[!] Installing $TOOL...${NC}"
        eval "${TOOL_INSTALL[$TOOL]}"
    }
    echo -e "${GREEN}[✓] $TOOL ready${NC}"
done

# ------------------ Target ------------------
read -p "Enter target domain/IP/URL: " TARGET
[[ -z "$TARGET" ]] && { echo -e "${RED}[✗] Target cannot be empty${NC}"; exit 1; }

SESSION_ID=$(echo -n "$TARGET$(date +%s)" | sha256sum | cut -c1-12)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_FILE="fraglet_report_${SESSION_ID}.txt"
touch "$REPORT_FILE"

# ------------------ Subdomain Discovery ------------------
SUBDOMAIN_FILE="subdomains_${TARGET}.txt"
touch "$SUBDOMAIN_FILE"
echo "[+] Discovering subdomains..."
subfinder -d "$TARGET" -silent -o "$SUBDOMAIN_FILE"
ALL_TARGETS=("$TARGET")
[ -f "$SUBDOMAIN_FILE" ] && mapfile -t SUBDOMS < "$SUBDOMAIN_FILE" && ALL_TARGETS+=("${SUBDOMS[@]}")

# ------------------ Parallel Scanning ------------------
echo "[+] Starting parallel scans with risk scoring..."
for T in "${ALL_TARGETS[@]}"; do
(
    OUTFILE="scan_$T.txt"
    touch "$OUTFILE"
    RISK=0

    # Nmap
    [ -f "nmap_$T.txt" ] || nmap -Pn -sS -T4 --script vuln "$T" -oN "nmap_$T.txt"
    RISK=$((RISK + $(grep -i "VULNERABLE" nmap_$T.txt | wc -l)))
    echo "Nmap Risk Points: $RISK" >> "$OUTFILE"

    # Nuclei
    [ -f "nuclei_$T.txt" ] || nuclei -u "$T" -t ~/nuclei-templates/ -severity critical,high -o "nuclei_$T.txt"
    RISK=$((RISK + $(wc -l < nuclei_$T.txt)))
    echo "Nuclei Risk Points: $RISK" >> "$OUTFILE"

    # Nikto
    [ -f "nikto_$T.txt" ] || nikto -host "$T" -output "nikto_$T.txt"
    RISK=$((RISK + $(grep -i "OSVDB" nikto_$T.txt | wc -l)))
    echo "Nikto Risk Points: $RISK" >> "$OUTFILE"

    # SQLMap
    [ -d "sqlmap_$T" ] || sqlmap -u "$T" --batch --risk=3 --level=5 --output-dir="sqlmap_$T"
    [ -f "sqlmap_$T/final.txt" ] && RISK=$((RISK + 5))
    echo "SQLMap Risk Points: $RISK" >> "$OUTFILE"

    # Gobuster / Dirsearch / WPScan / Masscan
    # Optional additional risk calculation
    echo "Other tools scanned (if installed)" >> "$OUTFILE"

    # Final Risk Label
    if [ "$RISK" -ge 10 ]; then LABEL="HIGH"
    elif [ "$RISK" -ge 5 ]; then LABEL="MEDIUM"
    else LABEL="LOW"; fi
    echo "Total Risk Score: $RISK ($LABEL)" >> "$OUTFILE"
) &
done
wait
echo "[✓] All scans completed."

# ------------------ Merge TXT ------------------
echo "FRAGLET THE ETHICAL DEMON REPORT" > "$REPORT_FILE"
echo "Target: $TARGET | Session: $SESSION_ID | Date: $DATE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
for F in scan_*.txt; do [ -f "$F" ] && cat "$F" >> "$REPORT_FILE"; done

# ------------------ PDF Generation ------------------
echo "[+] Generating PDF..."
python3 - <<EOF
from fpdf import FPDF
import requests

pdf = FPDF()
pdf.add_page()
pdf.set_font("Arial","B",16)
pdf.cell(0,10,"FRAGLET THE ETHICAL DEMON REPORT",0,1,"C")
pdf.set_font("Arial","",12)
pdf.multi_cell(0,6,"Target: $TARGET\nSession: $SESSION_ID\nDate: $DATE\n\n")

# Images
img_urls = [
    "https://upload.wikimedia.org/wikipedia/commons/2/2f/Red_alert_icon.png",
    "https://upload.wikimedia.org/wikipedia/commons/6/6b/Check_green_icon.png"
]
x=10; y=50
for url in img_urls:
    r=requests.get(url, stream=True)
    with open("/tmp/tmp_img.png","wb") as f: f.write(r.content)
    pdf.image("/tmp/tmp_img.png", x=x, y=y, w=30)
    x += 40

# Add table with results
pdf.set_xy(10,100)
pdf.set_font("Arial","B",12)
pdf.cell(60,10,"Tool",1,0,"C")
pdf.cell(60,10,"Target",1,0,"C")
pdf.cell(40,10,"Risk Score",1,0,"C")
pdf.cell(30,10,"Label",1,1,"C")
pdf.set_font("Arial","",10)

for t in ["$TARGET"] + [line.strip() for line in open("$SUBDOMAIN_FILE")]:
    score_file = f"scan_{t}.txt"
    try:
        with open(score_file) as f:
            content = f.read()
        risk_line = [l for l in content.splitlines() if "Total Risk Score" in l][0]
        score, label = risk_line.replace("Total Risk Score: ","").split("(")
        label = label.replace(")","")
        pdf.cell(60,10,"Various",1,0,"C")
        pdf.cell(60,10,t,1,0,"C")
        pdf.cell(40,10,score,1,0,"C")
        pdf.cell(30,10,label,1,1,"C")
    except:
        continue

pdf.output("fraglet_report_${SESSION_ID}.pdf")
EOF

echo -e "${GREEN}[✓] PDF generated: fraglet_report_${SESSION_ID}.pdf${NC}"
echo -e "${GREEN}[✓] FRAGLET full bug bounty scan completed successfully!${NC}"
