# Launches the repro in the booted simulator with the given environment, then
# counts the tab buttons UIKit has drawn. Usage: probe.py <udid> KEY=VAL ...
import os, re, subprocess, sys, time
sys.path.insert(0, subprocess.check_output(['lldb', '-P']).decode().strip())
import lldb
udid, pairs = sys.argv[1], sys.argv[2:]
BUNDLE = os.environ.get('BUNDLE', 'com.example.DuoTabBarRepro')
env = dict(os.environ, **{f'SIMCTL_CHILD_{k}': v for k, v in (p.split('=', 1) for p in pairs)})
if os.environ.get('NOLAUNCH') == '1':  # read the running app as it is
    pid = int(subprocess.check_output(['xcrun', 'simctl', 'spawn', udid, 'launchctl', 'list']).decode()
              .split(f'UIKitApplication:{BUNDLE}')[0].splitlines()[-1].split()[0])
else:
    subprocess.run(['xcrun', 'simctl', 'terminate', udid, BUNDLE], capture_output=True)
    out = subprocess.check_output(['xcrun', 'simctl', 'launch', udid, BUNDLE], env=env).decode()
    pid = int(out.split(':')[-1])
    time.sleep(float(os.environ.get('WAIT', '4')))
dbg = lldb.SBDebugger.Create(); dbg.SetAsync(False); ci = dbg.GetCommandInterpreter()
def run(c):
    r = lldb.SBCommandReturnObject(); ci.HandleCommand(c, r); return (r.GetOutput() or '') + (r.GetError() or '')
run(f'process attach --pid {pid}'); run('expr -l objc -O -- @import UIKit')
h = run('expr -l objc -O -- [[[[[UIApplication sharedApplication] connectedScenes] anyObject] keyWindow] rootViewController] _printHierarchy]')
tbc = re.search(r'<(?:UI|RNS)TabBarController: (0x[0-9a-f]+)>', h).group(1)
v = run(f'expr -l objc -O -- [[(UIViewController *){tbc} view] recursiveDescription]')
geo = run('expr -l objc -O -- [[[[UIApplication sharedApplication] connectedScenes] anyObject] effectiveGeometry]')
size = re.search(r'bounds: \{\{0, 0\}, \{([\d.]+), ([\d.]+)\}\}', geo)
print(' '.join(pairs) or '(defaults)', f'window={size.group(1)}x{size.group(2)}',
      'floating' if '_UIFloatingBarContainerView' in v else '-', f'tabButtons={v.count("<_UITabButton")}', flush=True)
run('process detach')
