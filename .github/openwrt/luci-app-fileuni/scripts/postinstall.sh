#!/bin/sh

set -e

if [ -n "${IPKG_INSTROOT}" ]; then
	exit 0
fi

if ! uci -q get luci.languages >/dev/null 2>&1; then
	uci -q set luci.languages=internal
fi

uci -q batch <<'EOF'
set luci.languages.en='English'
set luci.languages.zh_cn='中文'
set luci.languages.ja='日本語'
set luci.languages.es='Español'
set luci.languages.de='Deutsch'
set luci.languages.fr='Français'
commit luci
EOF

rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/* 2>/dev/null || true
/etc/init.d/rpcd reload >/dev/null 2>&1 || true
/etc/init.d/uhttpd reload >/dev/null 2>&1 || true

exit 0
