module("luci.controller.fileuni", package.seeall)

function index()
	local fs = require "nixio.fs"
	if not fs.access("/etc/config/fileuni") then
		return
	end

	entry({"admin", "services", "fileuni"}, cbi("fileuni"), _("FileUni"), 60).dependent = true
	entry({"admin", "services", "fileuni", "set_lang"}, call("action_set_lang")).leaf = true
end

function action_set_lang()
	local dispatcher = require "luci.dispatcher"
	local http = require "luci.http"
	local i18n = require "fileuni.i18n"
	local cursor = require "luci.model.uci".cursor()
	local lang = http.formvalue("lang") or "auto"

	if not i18n.is_supported_config_language(lang) then
		http.status(400, i18n.translate("en", "unsupported_language"))
		http.prepare_content("text/plain")
		http.write(i18n.translate("en", "unsupported_language"))
		return
	end

	i18n.ensure_luci_languages(cursor)
	if not cursor:get("luci", "main") then
		cursor:section("luci", "core", "main", { lang = "auto" })
	end
	cursor:set("luci", "main", "lang", lang)
	cursor:commit("luci")

	local redirect = http.formvalue("redirect") or dispatcher.build_url("admin", "services", "fileuni")
	if redirect:sub(1, 1) ~= "/" then
		redirect = dispatcher.build_url("admin", "services", "fileuni")
	end

	http.redirect(redirect)
end
