#!/bin/bash
# ==============================================================================
# aaPanel Toolbox & Pro Manager (v8.0.7 Compatible - Release 2026-10-13 13:02:55)
# Supported OS: Debian 11/12, Ubuntu 20/22/24 LTS, CentOS/AlmaLinux/Rocky 8/9
# Python Environment: Python 3.12 (pyenv)
# ==============================================================================

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export LANG=en_US.UTF-8

red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1\033[0m"; }
blue(){ echo -e "\033[34m\033[01m$1\033[0m"; }
purple(){ echo -e "\033[35m\033[01m$1\033[0m"; }

PANEL_PATH="/www/server/panel"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_DIR="${SCRIPT_DIR}/resource"

function get_py_bin(){
    if [ -f "${PANEL_PATH}/pyenv/bin/python" ]; then
        echo "${PANEL_PATH}/pyenv/bin/python"
    elif [ -f "/usr/bin/btpython" ]; then
        echo "/usr/bin/btpython"
    else
        echo "python3"
    fi
}

function aapanel-install(){
    blue "Installing the official latest aaPanel (v8.0.7) from official servers..."
    local INSTALL_URL="https://www.aapanel.com/script/install_panel_en.sh"
    if command -v curl >/dev/null 2>&1; then
        curl -ksSO "${INSTALL_URL}"
    else
        wget --no-check-certificate -O install_panel_en.sh "${INSTALL_URL}"
    fi

    if [ -f "install_panel_en.sh" ]; then
        bash install_panel_en.sh
    else
        red "Error: Failed to download official installer script."
    fi
}

function aapanel-update(){
    blue "Updating existing aaPanel to latest v8.0.7..."
    rm -f /tmp/update_to7.pl 2>/dev/null
    if command -v curl >/dev/null 2>&1; then
        curl -k https://node.aapanel.com/install/update_7.x_en.sh | bash
    else
        wget -qO- https://node.aapanel.com/install/update_7.x_en.sh | bash
    fi
    green "Update procedure finished. Please check the panel status."
}

function panel-happy(){
    if [ ! -d "${PANEL_PATH}" ]; then
        red "Error: aaPanel directory ${PANEL_PATH} was not found."
        red "Please install aaPanel first before activating Pro."
        read -p "Press Enter to return to menu..."
        return
    fi

    blue "Activating aaPanel Pro (v8.0.7 Compatible)..."

    # Unlock previously immutable files if any
    if command -v chattr >/dev/null 2>&1; then
        chattr -i "${PANEL_PATH}/data/plugin.json" 2>/dev/null
        chattr -i "${PANEL_PATH}/data/repair.json" 2>/dev/null
        chattr -i "${PANEL_PATH}/data/userInfo.json" 2>/dev/null
        chattr -i "${PANEL_PATH}/BTPanel/static/js/soft.js" 2>/dev/null
        chattr -i "${PANEL_PATH}/BTPanel/static/js/index.js" 2>/dev/null
        chattr -i "${PANEL_PATH}/class/public/common.py" 2>/dev/null
        chattr -i "${PANEL_PATH}/class/common.py" 2>/dev/null
    fi

    local PY_BIN
    PY_BIN="$(get_py_bin)"
    yellow "Running patcher using Python: ${PY_BIN}..."

    $PY_BIN - << 'EOF'
import os, sys, re, json, time, shutil

PANEL_PATH = "/www/server/panel"
sys.path.insert(0, os.path.join(PANEL_PATH, "class"))

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

    # Patch get_pd
    if "def get_pd(" in code:
        pattern = r"def get_pd\(args=None\):.*?(?=\ndef [a-zA-Z_]|\Z)"
        replacement = '''def get_pd(args=None):
    htm = '<span class="btpro">Expire:<span style="color: #fc6d26;font-weight: bold;">Lifetime</span></span>'
    return htm, 0, 0
'''
        code = re.sub(pattern, replacement, code, flags=re.DOTALL)

    # Patch load_soft_list
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

# Bound userInfo profile
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

    # Sync resource configs
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

    chmod 644 "${PANEL_PATH}/data/userInfo.json" 2>/dev/null
    [ -f "${PANEL_PATH}/data/repair.json" ] && chmod 644 "${PANEL_PATH}/data/repair.json" 2>/dev/null
    [ -f "${PANEL_PATH}/data/plugin.json" ] && chmod 644 "${PANEL_PATH}/data/plugin.json" 2>/dev/null

    rm -f /tmp/bmac_*.time 2>/dev/null
    rm -f /tmp/update_to*.pl 2>/dev/null

    yellow "Restarting aaPanel daemon..."
    if [ -f "/etc/init.d/bt" ]; then
        /etc/init.d/bt restart
    elif command -v bt >/dev/null 2>&1; then
        bt restart
    fi

    green "================================================================"
    green " aaPanel Pro v8.0.7 activated successfully! "
    green " Status: Lifetime PRO & LTD Unlocked"
    green " Hard-refresh your browser (Ctrl + F5) or use Incognito mode"
    green "================================================================"
    read -p "Press Enter to return to menu..."
}

function log(){
    blue "Cleaning request logs and disabling site expiration task..."
    if [ -f "${PANEL_PATH}/script/site_task.py" ]; then
        echo "#!/usr/bin/env python" > "${PANEL_PATH}/script/site_task.py"
        echo "# Disabled auto site expiration stopper" >> "${PANEL_PATH}/script/site_task.py"
        if command -v chattr >/dev/null 2>&1; then
            chattr +i "${PANEL_PATH}/script/site_task.py" 2>/dev/null
        fi
    fi

    rm -rf "${PANEL_PATH}/logs/request"/* 2>/dev/null
    green "Logs cleaned and expiration auto-stop disabled."
    read -p "Press Enter to return to menu..."
}

function clean-up-trash(){
    blue "Cleaning up temporary files and caches..."
    rm -f /tmp/*.zip /tmp/*.tar.gz 2>/dev/null
    rm -f /tmp/panelExec.log /tmp/aapanel-install.log /tmp/update_to*.pl 2>/dev/null
    rm -rf "${PANEL_PATH}/temp"/* 2>/dev/null

    # Clear old session files
    if [ -d "${PANEL_PATH}/data/session" ]; then
        find "${PANEL_PATH}/data/session" -type f -mtime +7 -delete 2>/dev/null
    fi

    # Clear Python cache
    find "${PANEL_PATH}" -type f -name "*.pyc" -delete 2>/dev/null
    find "${PANEL_PATH}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null

    green "System cache and temporary files cleaned up."
    read -p "Press Enter to return to menu..."
}

function uninstall(){
    red "Are you sure you want to uninstall aaPanel? (y/n)"
    read -p "Confirm uninstall: " confirmUninstall
    if [ "$confirmUninstall" != "y" ] && [ "$confirmUninstall" != "Y" ]; then
        yellow "Uninstallation cancelled."
        read -p "Press Enter to return to menu..."
        return
    fi

    wget -O "/root/bt-uninstall.sh" "https://node.aapanel.com/install/bt-uninstall.sh"
    if [ -f "/root/bt-uninstall.sh" ]; then
        bash "/root/bt-uninstall.sh"
        green "Panel uninstalled successfully."
    else
        red "Error: Could not download uninstaller script."
    fi
    read -p "Press Enter to return to menu..."
}

function restart-service(){
    blue "Restarting aaPanel service..."
    if [ -f "/etc/init.d/bt" ]; then
        /etc/init.d/bt restart
    elif command -v bt >/dev/null 2>&1; then
        bt restart
    fi
    green "Service restart initiated."
    read -p "Press Enter to return to menu..."
}

function start_menu(){
    clear
    purple "================================================================"
    purple "       aaPanel Toolbox & Pro Manager (v8.0.7 Compatible)       "
    purple "       Release: 2026-10-13 13:02:55 | Python 3.12 Ready        "
    purple "================================================================"
    yellow " 1. Install aaPanel (Official Latest v8.0.7)"
    yellow " 2. Update / Repair aaPanel to Latest (v8.0.7)"
    green  " 3. Activate aaPanel Pro (v8.0.7 Compatible)"
    yellow " 4. Disable Site Expiration Lock & Clear Request Logs"
    yellow " 5. Cleanup Cache & Junk Files"
    yellow " 6. Restart aaPanel Service"
    red    " 7. Uninstall aaPanel"
    blue   " 0. Exit"
    purple "================================================================"

    read -p "Please enter your choice [0-7]: " menuNumberInput
    case "$menuNumberInput" in
        1 )
            aapanel-install
            start_menu
        ;;
        2 )
            aapanel-update
            start_menu
        ;;
        3 )
            panel-happy
            start_menu
        ;;
        4 )
            log
            start_menu
        ;;
        5 )
            clean-up-trash
            start_menu
        ;;
        6 )
            restart-service
            start_menu
        ;;
        7 )
            uninstall
            start_menu
        ;;
        0 )
            exit 0
        ;;
        * )
            red "Please enter a valid option!"
            sleep 1
            start_menu
        ;;
    esac
}

start_menu
