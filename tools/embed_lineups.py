# -*- coding: utf-8 -*-
"""把 lineups.json 编译进 Tweak.xm（CI 里自动跑）"""
import io, json, os, re, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg_path = os.path.join(root, "lineups.json")
tweak = os.path.join(root, "Tweak.xm")

if not os.path.exists(cfg_path):
    print("no lineups.json, keep embedded as-is"); sys.exit(0)
if not os.path.exists(tweak):
    print("no Tweak.xm"); sys.exit(1)

data = json.load(io.open(cfg_path, encoding="utf-8"))
mini = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
esc = mini.replace("\\", "\\\\").replace('"', '\\"')
stmt = 'static const char *tft_lineups_json = "%s";' % esc

src = io.open(tweak, encoding="utf-8").read()
mark = 'static const char *tft_lineups_json = "'
i = src.find(mark)
if i < 0:
    print("marker not found"); sys.exit(1)
j = src.find('";', i + len(mark))
if j < 0:
    print("terminator not found"); sys.exit(1)
src = src[:i] + stmt + src[j+2:]
io.open(tweak, "w", encoding="utf-8").write(src)
print("embedded %d lineups, %d chars" % (len(data.get("lineups", [])), len(mini)))
