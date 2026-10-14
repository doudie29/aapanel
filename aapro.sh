#!/bin/bash
# ==============================================================================
# aaPanel Pro Activator for aaPanel v8.0.7 (Release: 2026-10-13 13:02:55)
# Compatible with Python 3.12, Debian 11/12, Ubuntu 20/22/24, AlmaLinux/Rocky 8/9
# ==============================================================================

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export LANG=en_US.UTF-8

red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1\033[0m"; }
blue(){ echo -e "\033[34m\033[01m$1\033[0m"; }
purple(){ echo -e "\033[35m\033[01m$1\033[0m"; }

if [ "$(whoami)" != "root" ]; then
    red "Error: Please run this script as root user (sudo bash aapro.sh)!"
    exit 1
fi

PANEL_PATH="/www/server/panel"
if [ ! -d "${PANEL_PATH}" ]; then
    red "Error: aaPanel directory ${PANEL_PATH} not found!"
    red "Please install aaPanel first."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_DIR="${SCRIPT_DIR}/resource"

blue "================================================================"
purple "            aaPanel Pro Activator (v8.0.7 Compatible)"
blue "================================================================"

# 1. Unlock existing attributes if previously locked by old crack scripts
yellow "[1/6] Unlocking file permissions..."
if command -v chattr >/dev/null 2>&1; then
    chattr -i "${PANEL_PATH}/data/plugin.json" 2>/dev/null
    chattr -i "${PANEL_PATH}/data/repair.json" 2>/dev/null
    chattr -i "${PANEL_PATH}/data/userInfo.json" 2>/dev/null
    chattr -i "${PANEL_PATH}/BTPanel/static/js/soft.js" 2>/dev/null
    chattr -i "${PANEL_PATH}/BTPanel/static/js/index.js" 2>/dev/null
    chattr -i "${PANEL_PATH}/class/public/common.py" 2>/dev/null
    chattr -i "${PANEL_PATH}/class/common.py" 2>/dev/null
fi

# 2. Locate Python binary
if [ -f "${PANEL_PATH}/pyenv/bin/python" ]; then
    PY_BIN="${PANEL_PATH}/pyenv/bin/python"
elif [ -f "/usr/bin/btpython" ]; then
    PY_BIN="/usr/bin/btpython"
else
    PY_BIN="python3"
fi
yellow "[2/6] Using Python runtime: ${PY_BIN}"

# 3. Patch backend authorization & plugin listing
yellow "[3/6] Applying Pro Lifetime authorization patch..."
$PY_BIN - << 'EOF'
import os, sys, re, json, time, shutil

PANEL_PATH = "/www/server/panel"
sys.path.insert(0, os.path.join(PANEL_PATH, "class"))

# Patch common.py (aaPanel 7.x/8.x uses class/public/common.py)
candidates = [
    os.path.join(PANEL_PATH, "class", "public", "common.py"),
    os.path.join(PANEL_PATH, "class", "common.py")
]

for cfile in candidates:
    if not os.path.exists(cfile):
        continue
    bak = cfile + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(cfile, bak)

    with open(cfile, "r", encoding="utf-8") as f:
        code = f.read()

    # Patch get_pd (Dashboard Lifetime PRO status)
    if "def get_pd(" in code:
        pattern = r"def get_pd\(args=None\):.*?(?=\ndef [a-zA-Z_]|\Z)"
        replacement = '''def get_pd(args=None):
    htm = '<span class="btpro">Expire:<span style="color: #fc6d26;font-weight: bold;">Lifetime</span></span>'
    return htm, 0, 0
'''
        code = re.sub(pattern, replacement, code, flags=re.DOTALL)

    # Patch load_soft_list (Software store PRO features & endtime)
    if "def load_soft_list(" in code and "# __AAPRO_PATCH__" not in code:
        target = "return plugin_list_data"
        patch_block = '''    # __AAPRO_PATCH__
    try:
        if isinstance(plugin_list_data, dict):
            plugin_list_data['pro'] = 0
            plugin_list_data['ltd'] = 0
            if 'list' in plugin_list_data and isinstance(plugin_list_data['list'], list):
                for _p in plugin_list_data['list']:
                    _p['endtime'] = 0
                    _p['panel_pro'] = 0
                    _p['panel_ltd'] = 0
                    _p['panel_free'] = 0
                    _p['panel_test'] = 0
    except:
        pass
    return plugin_list_data'''
        parts = code.rsplit(target, 1)
        if len(parts) == 2:
            code = parts[0] + patch_block + parts[1]

    with open(cfile, "w", encoding="utf-8") as f:
        f.write(code)

# Setup bound userInfo profile
user_info_file = os.path.join(PANEL_PATH, "data", "userInfo.json")
user_data = {
    "uid": 1000,
    "username": "Administrator",
    "server_id": "aa80700000000000000000000000000000000000000000000000000000000000",
    "token": "token"
}
with open(user_info_file, "w", encoding="utf-8") as f:
    json.dump(user_data, f, indent=4)

# Set bmac token in /tmp
try:
    import public
    p_token = 'bmac_' + public.Md5(public.get_mac_address())
    with open('/tmp/' + p_token, 'w', encoding='utf-8') as f:
        f.write('0')
    with open('/tmp/{}.time'.format(p_token), 'w', encoding='utf-8') as f:
        f.write(str(int(time.time())))
except Exception as e:
    pass

# Clear bytecode cache
for root, dirs, files in os.walk(PANEL_PATH):
    for f in files:
        if f.endswith('.pyc'):
            try: os.remove(os.path.join(root, f))
            except: pass
    for d in dirs:
        if d == '__pycache__':
            try: shutil.rmtree(os.path.join(root, d))
            except: pass
EOF

# 4. Deploy resources if available
yellow "[4/6] Synchronizing resource configurations..."
if [ -d "${RESOURCE_DIR}" ]; then
    if [ -f "${RESOURCE_DIR}/repair.json" ]; then
        \cp -f "${RESOURCE_DIR}/repair.json" "${PANEL_PATH}/data/repair.json"
    fi
    if [ -f "${RESOURCE_DIR}/plugin.json" ]; then
        \cp -f "${RESOURCE_DIR}/plugin.json" "${PANEL_PATH}/data/plugin.json"
    fi
    if [ -f "${RESOURCE_DIR}/soft.js" ]; then
        \cp -f "${RESOURCE_DIR}/soft.js" "${PANEL_PATH}/BTPanel/static/js/soft.js"
    fi
    if [ -f "${RESOURCE_DIR}/index.js" ]; then
        \cp -f "${RESOURCE_DIR}/index.js" "${PANEL_PATH}/BTPanel/static/js/index.js"
    fi
fi

# Ensure permissions
chmod 644 "${PANEL_PATH}/data/userInfo.json" 2>/dev/null
[ -f "${PANEL_PATH}/data/repair.json" ] && chmod 644 "${PANEL_PATH}/data/repair.json" 2>/dev/null
[ -f "${PANEL_PATH}/data/plugin.json" ] && chmod 644 "${PANEL_PATH}/data/plugin.json" 2>/dev/null

# 5. Clear session & temp caches
yellow "[5/6] Flushing caches..."
rm -f /tmp/bmac_*.time 2>/dev/null
rm -f /tmp/update_to*.pl 2>/dev/null

# 6. Restart aaPanel daemon
yellow "[6/6] Restarting aaPanel service..."
if [ -f "/etc/init.d/bt" ]; then
    /etc/init.d/bt restart
elif command -v bt >/dev/null 2>&1; then
    bt restart
fi

green "================================================================"
green " Congratulations! aaPanel Pro v8.0.7 activated successfully! "
green "================================================================"
green " Status: Lifetime PRO & LTD Unlocked"
green " Hard-refresh your browser (Ctrl + F5) or open in Incognito mode"
blue "================================================================"