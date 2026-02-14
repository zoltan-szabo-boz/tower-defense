#!/usr/bin/env python3
"""Injects Discord webhook notification into the Godot web export.
Run this after each Godot web export to docs/.

Usage: python post_web_build.py
"""

import sys
from pathlib import Path

# fmt: off
SNIPPET = (
    '    <script>\n'
    '      // CV visit notification\n'
    '      (function () {\n'
    '        const webhook =\n'
    '          "https://discord.com/api/webhooks/1470087961361125486/kSelDSTTN-pd6m_htUr0tjUBf3W3RRlKwJ7S0EYD7T6Dbg_puOCCGbE6hsDrb2W9Fw6m";\n'
    '        const time = new Date().toLocaleString("en-GB", { timeZone: "UTC" });\n'
    '        const ref = new URLSearchParams(window.location.search).get("ref");\n'
    '        const source = ref || document.referrer || "Direct / Unknown";\n'
    '        fetch(webhook, {\n'
    '          method: "POST",\n'
    '          headers: { "Content-Type": "application/json" },\n'
    '          body: JSON.stringify({\n'
    r'            content: `\u{1F3AE} **Tower Defense opened!**\n\u23F0 ${time} UTC\n\u{1F3E2} Source: **${source}**`,' '\n'
    '          }),\n'
    '        }).catch(() => {});\n'
    '      })();\n'
    '    </script>\n'
)
# fmt: on

file = Path(__file__).parent / "docs" / "index.html"

if not file.exists():
    print("Error: docs/index.html not found. Run the Godot web export first.", file=sys.stderr)
    sys.exit(1)

content = file.read_text(encoding="utf-8")

if "CV visit notification" in content:
    print("Webhook snippet already present, skipping.")
    sys.exit(0)

marker = '<script src="index.js"></script>'
if marker not in content:
    print(f'Error: could not find "{marker}" in docs/index.html', file=sys.stderr)
    sys.exit(1)

content = content.replace(marker, SNIPPET + "    " + marker)
file.write_text(content, encoding="utf-8")
print("Webhook snippet injected into docs/index.html")
