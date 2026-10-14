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
    chattr -i "${PANEL_PATH}/class_v2/panel_plugin_v2.py" 2>/dev/null
    chattr -i "${PANEL_PATH}/class/panelPlugin.py" 2>/dev/null
    chattr -i "${PANEL_PATH}/class_v2/panel_auth_v2.py" 2>/dev/null
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

# 1. Patch panel_auth_v2.py (Safeguard KeyError 'id')
auth_file = os.path.join(PANEL_PATH, "class_v2", "panel_auth_v2.py")
if os.path.exists(auth_file):
    try:
        with open(auth_file, "r", encoding="utf-8") as f:
            auth_code = f.read()
        if "data['uid'] = data['id']" in auth_code:
            auth_code = auth_code.replace("data['uid'] = data['id']", "data['uid'] = data.get('id', data.get('uid', 1000)); data['id'] = data.get('id', data.get('uid', 1000))")
            with open(auth_file, "w", encoding="utf-8") as f:
                f.write(auth_code)
    except:
        pass

# 2. Patch common.py (aaPanel 7.x/8.x uses class/public/common.py)
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

    # Patch load_soft_list (Completely prevent 'failed to parse soft list' exception)
    soft_list_pat = r"def load_soft_list\(force: bool = True, retry_count: int = 0\):.*?(?=\n# =+|\ndef [a-zA-Z_]|\Z)"
    new_soft_list = '''def load_soft_list(force: bool = True, retry_count: int = 0):
    local_cache_file = '{}/data/plugin_bin.pl'.format(get_panel_path())
    local_json_file = '{}/data/plugin.json'.format(get_panel_path())

    if force or not os.path.exists(local_cache_file) or os.path.getsize(local_cache_file) < 10:
        try:
            cloudUrl = '{}/api/panel/getSoftListEn'.format(OfficialApiBase())
            from panel_auth_v2 import panelAuth
            import requests
            pdata = panelAuth().create_serverid(None)
            url_headers = {'user-agent': 'aaPanel/1.0'}
            if isinstance(pdata, dict) and 'token' in pdata:
                url_headers['authorization'] = "bt {}".format(pdata['token'])
            if isinstance(pdata, dict):
                pdata['environment_info'] = json.dumps(fetch_env_info())
                resp = requests.post(cloudUrl, params=pdata, headers=url_headers, verify=False, timeout=8)
                if resp.ok and len(resp.text) > 10:
                    with open(local_cache_file, 'w', encoding='utf-8') as fp:
                        fp.write(resp.text)
        except:
            pass

    plugin_list_data = None
    try:
        import PluginLoader
        if force:
            try:
                if hasattr(PluginLoader, 'parse_plugin_list'):
                    PluginLoader.parse_plugin_list(1)
            except:
                pass
        try:
            plugin_list_data = PluginLoader.get_plugin_list(0)
        except:
            pass
    except:
        pass

    if not isinstance(plugin_list_data, dict) or not plugin_list_data.get('list'):
        if os.path.exists(local_json_file):
            try:
                plugin_list_data = json.loads(readFile(local_json_file))
            except:
                pass

    if not isinstance(plugin_list_data, dict):
        plugin_list_data = {'type': [], 'pro': 0, 'ltd': 0, 'list': []}

    try:
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

    return plugin_list_data
'''
    code = re.sub(soft_list_pat, new_soft_list, code, flags=re.DOTALL)

    with open(cfile, "w", encoding="utf-8") as f:
        f.write(code)

# 3. Patch class_v2/panel_plugin_v2.py
plugin_v2_file = os.path.join(PANEL_PATH, "class_v2", "panel_plugin_v2.py")
if os.path.exists(plugin_v2_file):
    try:
        with open(plugin_v2_file, "r", encoding="utf-8") as f:
            pv2_code = f.read()

        if "self.__ensure_plugin_list_obtained(True)" in pv2_code:
            pv2_code = pv2_code.replace("self.__ensure_plugin_list_obtained(True)", "self.__ensure_plugin_list_obtained(False)")

        ensure_pat = r"def __ensure_plugin_list_obtained\(self,\s*force:\s*bool\s*=\s*False\):.*?(?=\n\s*def|\n#+|\Z)"
        new_ensure = '''def __ensure_plugin_list_obtained(self, force: bool = False):
        if not self.__plugin_list or (force and not self.__plugin_list.get('list')):
            try:
                self.__plugin_list = public.load_soft_list(force)
            except:
                pass
        if not self.__plugin_list or not self.__plugin_list.get('list'):
            local_json = '{}/data/plugin.json'.format(public.get_panel_path())
            if os.path.exists(local_json):
                try:
                    self.__plugin_list = json.loads(public.readFile(local_json))
                except:
                    pass
'''
        pv2_code = re.sub(ensure_pat, new_ensure, pv2_code, flags=re.DOTALL)

        old_sync_call = "return self.__install_plugin(pluginInfo['name'], get.get('version', ''))"
        new_sync_call = '''res = self.__install_plugin(pluginInfo['name'], get.get('version', ''))
            if isinstance(res, dict) and (not res.get('status') or 'err_no' in res or 'res' in res):
                try:
                    p_name = pluginInfo['name']
                    sh_url = 'https://node.aapanel.com/install/plugin/{}/install.sh'.format(p_name)
                    sh_file = '/tmp/{}_install.sh'.format(p_name)
                    public.downloadFile(sh_url, sh_file)
                    if os.path.exists(sh_file) and os.path.getsize(sh_file) > 100:
                        self.set_pyenv(sh_file)
                        public.ExecShell('/bin/bash ' + sh_file + ' install &> /tmp/panelShell.pl')
                        if os.path.exists(sh_file): os.remove(sh_file)
                        if os.path.exists(pluginInfo.get('install_checks', '')):
                            public.write_log_gettext('Installer', 'Successfully installed plugin [{}]', (pluginInfo.get('title', p_name),))
                            return public.return_message(0, 0, public.lang("Installation succeeded!"))
                except:
                    pass
            return res'''
        if old_sync_call in pv2_code:
            pv2_code = pv2_code.replace(old_sync_call, new_sync_call)

        with open(plugin_v2_file, "w", encoding="utf-8") as f:
            f.write(pv2_code)
    except:
        pass

# 4. Patch class/panelPlugin.py
plugin_v1_file = os.path.join(PANEL_PATH, "class", "panelPlugin.py")
if os.path.exists(plugin_v1_file):
    try:
        with open(plugin_v1_file, "r", encoding="utf-8") as f:
            pv1_code = f.read()

        old_v1_call = "return self.__install_plugin(pluginInfo['name'], get.version)"
        new_v1_call = '''res = self.__install_plugin(pluginInfo['name'], get.version)
            if isinstance(res, dict) and (not res.get('status') or 'err_no' in res or 'res' in res):
                try:
                    p_name = pluginInfo['name']
                    sh_url = 'https://node.aapanel.com/install/plugin/{}/install.sh'.format(p_name)
                    sh_file = '/tmp/{}_install.sh'.format(p_name)
                    public.downloadFile(sh_url, sh_file)
                    if os.path.exists(sh_file) and os.path.getsize(sh_file) > 100:
                        self.set_pyenv(sh_file)
                        public.ExecShell('/bin/bash ' + sh_file + ' install &> /tmp/panelShell.pl')
                        if os.path.exists(sh_file): os.remove(sh_file)
                        if os.path.exists(pluginInfo.get('install_checks', '')):
                            public.write_log_gettext('Installer', 'Successfully installed plugin [{}]', (pluginInfo.get('title', p_name),))
                            return public.return_message(0, 0, public.lang("Installation succeeded!"))
                except:
                    pass
            return res'''
        if old_v1_call in pv1_code:
            pv1_code = pv1_code.replace(old_v1_call, new_v1_call)
            with open(plugin_v1_file, "w", encoding="utf-8") as f:
                f.write(pv1_code)
    except:
        pass

# 5. Setup bound userInfo profile (both 'id' and 'uid' to avoid KeyError)
user_info_file = os.path.join(PANEL_PATH, "data", "userInfo.json")
user_data = {
    "id": 1000,
    "uid": 1000,
    "username": "Administrator",
    "server_id": "aa80700000000000000000000000000000000000000000000000000000000000",
    "token": "token",
    "status": True
}
with open(user_info_file, "w", encoding="utf-8") as f:
    json.dump(user_data, f, indent=4)

# 6. Set bmac token in /tmp
try:
    import public
    p_token = 'bmac_' + public.Md5(public.get_mac_address())
    with open('/tmp/' + p_token, 'w', encoding='utf-8') as f:
        f.write('0')
    with open('/tmp/{}.time'.format(p_token), 'w', encoding='utf-8') as f:
        f.write(str(int(time.time())))
except Exception as e:
    pass

# 7. Clear bytecode cache
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
rm -f /tmp/bmac_* 2>/dev/null
rm -f /tmp/update_to*.pl 2>/dev/null
rm -f /tmp/*_pre 2>/dev/null
rm -f /tmp/multi_service_install.log 2>/dev/null
rm -f "${PANEL_PATH}/data/plugin_bin.pl" 2>/dev/null

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