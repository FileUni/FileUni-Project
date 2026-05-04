local fs = require "nixio.fs"
local sys = require "luci.sys"
local json_available, json_module = pcall(require, "luci.jsonc")
local json = json_available and json_module or nil

local M = {}

local BINARY_PATH = "/usr/bin/fileuni"
local DEFAULT_RUNTIME_DIR = "/var/lib/fileuni"
local PACKAGE_NAME = "fileuni"
local RELEASES_URL = "https://fileuni.com/api/downloads/releases"
local SERVICE_SCRIPT = "/etc/init.d/fileuni"

local function shellquote(value)
	return "'" .. tostring(value or ""):gsub("'", "'\"'\"'") .. "'"
end

local function command_exists(name)
	return sys.call("command -v " .. shellquote(name) .. " >/dev/null 2>&1") == 0
end

local function trim(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function first_line(value)
	return trim((tostring(value or ""):match("([^\r\n]+)") or ""))
end

local function run_shell(script)
	local marker = "__FILEUNI_EXIT__"
	local wrapped = "( " .. script .. " ) 2>&1\nstatus=$?\nprintf '\\n" .. marker .. "%s' \"$status\""
	local output = sys.exec(wrapped)
	local status = tonumber(output:match(marker .. "(%d+)%s*$")) or 1
	local body = output:gsub("\n?" .. marker .. "%d+%s*$", "")
	return status == 0, trim(body), status
end

local function fetch_text(url)
	if not command_exists("uclient-fetch") and not command_exists("wget") and not command_exists("curl") then
		return nil, "No supported download tool found"
	end

	local quoted_url = shellquote(url)
	local commands = {
		"uclient-fetch -T 15 -qO- " .. quoted_url,
		"wget -T 15 -qO- " .. quoted_url,
		"curl --connect-timeout 15 --max-time 30 -fsSL " .. quoted_url,
	}
	local last_detail = nil

	for _, command in ipairs(commands) do
		local ok, output = run_shell(command)
		if ok and output ~= "" then
			return output
		end
		if output ~= "" then
			last_detail = output
		end
	end
	return nil, last_detail
end

local function download_file(url, destination)
	if not command_exists("uclient-fetch") and not command_exists("wget") and not command_exists("curl") then
		return nil, "No supported download tool found"
	end

	local quoted_url = shellquote(url)
	local quoted_destination = shellquote(destination)
	local commands = {
		"uclient-fetch -T 30 -O " .. quoted_destination .. " " .. quoted_url,
		"wget -T 30 -qO " .. quoted_destination .. " " .. quoted_url,
		"curl --connect-timeout 15 --max-time 180 -fL " .. quoted_url .. " -o " .. quoted_destination,
	}
	local last_detail = nil

	for _, command in ipairs(commands) do
		local ok, output = run_shell(command)
		if ok and fs.access(destination) then
			return true
		end
		if output ~= "" then
			last_detail = output
		end
	end
	return nil, last_detail
end

local function make_temp_dir()
	local ok, output = run_shell("mktemp -d /tmp/fileuni-luci.XXXXXX 2>/dev/null || mktemp -d")
	if not ok then
		return nil
	end
	local path = trim(output)
	if path == "" then
		return nil
	end
	return path
end

local function cleanup_path(path)
	if trim(path) == "" then
		return
	end
	run_shell("rm -rf " .. shellquote(path))
end

local function normalize_channel(channel)
	local normalized = trim(channel):lower()
	if normalized == "pre" then
		normalized = "prerelease"
	end
	if normalized == "stable" or normalized == "prerelease" then
		return normalized
	end
	return nil
end

local function service_running()
	return fs.access(SERVICE_SCRIPT)
		and sys.call(SERVICE_SCRIPT .. " running >/dev/null 2>&1") == 0
end

local function service_boot_enabled()
	return fs.access(SERVICE_SCRIPT)
		and sys.call(SERVICE_SCRIPT .. " enabled >/dev/null 2>&1") == 0
end

local function binary_version()
	if not fs.access(BINARY_PATH) then
		return nil
	end
	local ok, output = run_shell(shellquote(BINARY_PATH) .. " --version")
	if not ok then
		return nil
	end
	local version = first_line(output)
	if version == "" then
		return nil
	end
	return version
end

local function package_installed()
	if not command_exists("opkg") then
		return false
	end

	return sys.call("opkg status " .. PACKAGE_NAME .. " >/dev/null 2>&1") == 0
end

local function opkg_environment()
	local state = {
		available = command_exists("opkg"),
		architectures = {},
		primary_arch = nil,
	}

	if not state.available then
		return state
	end

	local output = trim(sys.exec("opkg print-architecture 2>/dev/null"))
	for line in output:gmatch("[^\r\n]+") do
		local arch = trim((line:match("^arch%s+([^%s]+)") or ""))
		if arch ~= "" then
			state.architectures[#state.architectures + 1] = arch
		end
	end

	state.primary_arch = state.architectures[1] or nil
	return state
end

local function detect_architecture()
	local machine = trim(sys.exec("uname -m 2>/dev/null"))
	local opkg_state = opkg_environment()
	local state = {
		machine = machine ~= "" and machine or "unknown",
		label = machine ~= "" and machine or "unknown",
		supported = false,
		target_id = nil,
		opkg_architectures = opkg_state.architectures,
		opkg_primary_arch = opkg_state.primary_arch,
	}

	if machine == "x86_64" or machine == "amd64" then
		state.label = "x86_64"
		state.supported = true
		state.target_id = "cli-openwrt-x64"
	elseif machine == "aarch64" or machine == "arm64" then
		state.label = "aarch64"
		state.supported = true
		state.target_id = "cli-openwrt-arm64"
	elseif machine == "i386" or machine == "i486" or machine == "i586" or machine == "i686" or machine == "x86" then
		state.label = "i686"
		state.supported = true
		state.target_id = "cli-openwrt-x86"
	elseif machine:match("^armv[5-7]") or machine == "armhf" or machine == "arm" then
		state.label = "armv7"
		state.supported = true
		state.target_id = "cli-openwrt-armv7"
	end

	if not state.supported and opkg_state.primary_arch then
		local arch = opkg_state.primary_arch
		if arch:match("aarch64") or arch:match("arm64") then
			state.label = "aarch64"
			state.supported = true
			state.target_id = "cli-openwrt-arm64"
		elseif arch:match("x86_64") or arch:match("amd64") then
			state.label = "x86_64"
			state.supported = true
			state.target_id = "cli-openwrt-x64"
		elseif arch:match("i386") or arch:match("i486") or arch:match("i586") or arch:match("i686") or arch == "x86" then
			state.label = "i686"
			state.supported = true
			state.target_id = "cli-openwrt-x86"
		elseif arch:match("arm") then
			state.label = "armv7"
			state.supported = true
			state.target_id = "cli-openwrt-armv7"
		end
	end

	return state
end

local function check_runtime_requirements()
	local has_download_tool = command_exists("uclient-fetch") or command_exists("wget") or command_exists("curl")
	local has_ca_bundle = fs.access("/etc/ssl/certs") or fs.access("/etc/ssl/cert.pem") or fs.access("/etc/ssl/ca-bundle.pem")
	return {
		opkg_available = command_exists("opkg"),
		has_download_tool = has_download_tool,
		has_ca_bundle = has_ca_bundle,
		has_json_parser = json ~= nil and type(json.parse) == "function",
	}
end

local function fetch_release_catalog()
	if json == nil or type(json.parse) ~= "function" then
		return nil, {
			code = "json_parser_missing",
			detail = "luci.jsonc is unavailable",
		}
	end

	local raw, detail = fetch_text(RELEASES_URL)
	if not raw then
		return nil, {
			code = "release_fetch_failed",
			detail = detail,
		}
	end
	local parsed = json.parse(raw)
	if type(parsed) ~= "table" then
		return nil, {
			code = "release_fetch_failed",
			detail = "Invalid release catalog JSON",
		}
	end
	return parsed
end

local function resolve_release_channel(catalog, channel)
	if type(catalog) ~= "table" then
		return nil
	end
	if channel == "stable" then
		return catalog.stable
	end
	if channel == "prerelease" then
		return catalog.prerelease
	end
	return nil
end

local function build_release_state(release, arch_state)
	if type(release) ~= "table" then
		return {
			available = false,
			has_matching_asset = false,
			asset = nil,
		}
	end
	local asset = nil
	if arch_state.supported and type(release.targets) == "table" and arch_state.target_id then
		asset = release.targets[arch_state.target_id]
		if type(asset) ~= "table" or trim(asset.browserDownloadUrl) == "" then
			asset = nil
		end
	end
	return {
		available = true,
		has_matching_asset = asset ~= nil,
		version = trim(release.version),
		title = trim(release.title),
		published_at = trim(release.publishedAt),
		html_url = trim(release.htmlUrl),
		asset = asset and {
			name = trim(asset.name),
			url = trim(asset.browserDownloadUrl),
			size = tonumber(asset.size) or nil,
		} or nil,
	}
end

local function set_boot_enabled(cursor, enabled)
	cursor:set("fileuni", "main", "enabled", enabled and "1" or "0")
	cursor:commit("fileuni")
end

local function restart_service_if_running()
	if not service_running() then
		return
	end
	run_shell(shellquote(SERVICE_SCRIPT) .. " restart >/dev/null 2>&1 || " .. shellquote(SERVICE_SCRIPT) .. " start >/dev/null 2>&1 || true")
end

function M.runtime_dir(cursor)
	return cursor:get("fileuni", "main", "runtime_dir")
		or cursor:get("fileuni", "main", "app_data_dir")
		or cursor:get("fileuni", "main", "config_dir")
		or DEFAULT_RUNTIME_DIR
end

function M.dashboard_state(cursor)
	local arch_state = detect_architecture()
	local releases = {
		fetch_error = nil,
		stable = {
			available = false,
			has_matching_asset = false,
		},
		prerelease = {
			available = false,
			has_matching_asset = false,
		},
	}
	local catalog, release_error = fetch_release_catalog()
	if catalog then
		releases.stable = build_release_state(resolve_release_channel(catalog, "stable"), arch_state)
		releases.prerelease = build_release_state(resolve_release_channel(catalog, "prerelease"), arch_state)
	else
		releases.fetch_error = release_error
	end
	return {
		architecture = arch_state,
		requirements = check_runtime_requirements(),
		service = {
			running = service_running(),
			boot_enabled = service_boot_enabled(),
		},
		binary = {
			path = BINARY_PATH,
			exists = fs.access(BINARY_PATH),
			version = binary_version(),
			package_installed = package_installed(),
		},
		releases = releases,
		release_source = RELEASES_URL,
		runtime_dir = M.runtime_dir(cursor),
	}
end

function M.perform_service_action(cursor, action)
	if not fs.access(SERVICE_SCRIPT) then
		return {
			ok = false,
			code = "service_script_missing",
		}
	end

	if action == "start" then
		if not fs.access(BINARY_PATH) then
			return {
				ok = false,
				code = "binary_missing",
			}
		end

		local ok, detail = run_shell(shellquote(SERVICE_SCRIPT) .. " start")
		if not ok then
			return {
				ok = false,
				code = "service_action_failed",
				detail = detail,
			}
		end

		return {
			ok = true,
			code = "service_started",
		}
	end

	if action == "stop" then
		local ok, detail = run_shell(shellquote(SERVICE_SCRIPT) .. " stop")
		if not ok then
			return {
				ok = false,
				code = "service_action_failed",
				detail = detail,
			}
		end

		return {
			ok = true,
			code = "service_stopped",
		}
	end

	if action == "install_service" then
		if not fs.access(BINARY_PATH) then
			return {
				ok = false,
				code = "binary_missing",
			}
		end

		set_boot_enabled(cursor, true)
		local ok, detail = run_shell(shellquote(SERVICE_SCRIPT) .. " enable && " .. shellquote(SERVICE_SCRIPT) .. " start")
		if not ok then
			set_boot_enabled(cursor, false)
			run_shell(shellquote(SERVICE_SCRIPT) .. " disable >/dev/null 2>&1 || true")
			return {
				ok = false,
				code = "service_action_failed",
				detail = detail,
			}
		end

		return {
			ok = true,
			code = "service_installed",
		}
	end

	if action == "disable_service" then
		set_boot_enabled(cursor, false)
		local ok, detail = run_shell(shellquote(SERVICE_SCRIPT) .. " stop >/dev/null 2>&1 || true\n" .. shellquote(SERVICE_SCRIPT) .. " disable")
		if not ok then
			return {
				ok = false,
				code = "service_action_failed",
				detail = detail,
			}
		end

		return {
			ok = true,
			code = "service_disabled",
		}
	end

	return {
		ok = false,
		code = "invalid_action",
	}
end

function M.perform_binary_action(action, channel)
	if action == "remove" then
		if not command_exists("opkg") and not fs.access(BINARY_PATH) then
			return {
				ok = false,
				code = "binary_missing",
			}
		end

		if fs.access(SERVICE_SCRIPT) then
			run_shell(shellquote(SERVICE_SCRIPT) .. " stop >/dev/null 2>&1 || true")
		end

		if package_installed() then
			local ok, detail = run_shell("opkg remove " .. shellquote(PACKAGE_NAME))
			if not ok then
				return {
					ok = false,
					code = "binary_remove_failed",
					detail = detail,
				}
			end
		elseif fs.access(BINARY_PATH) then
			if not fs.remove(BINARY_PATH) then
				return {
					ok = false,
					code = "binary_remove_failed",
				}
			end
		end

		return {
			ok = true,
			code = "binary_removed",
		}
	end

	if action ~= "install" then
		return {
			ok = false,
			code = "invalid_action",
		}
	end

	local normalized_channel = normalize_channel(channel)
	if not normalized_channel then
		return {
			ok = false,
			code = "invalid_channel",
		}
	end

	if not command_exists("opkg") then
		return {
			ok = false,
			code = "opkg_missing",
		}
	end

	if not (command_exists("uclient-fetch") or command_exists("wget") or command_exists("curl")) then
		return {
			ok = false,
			code = "download_tool_missing",
		}
	end

	local arch_state = detect_architecture()
	if not arch_state.supported then
		return {
			ok = false,
			code = "unsupported_arch",
			detail = arch_state.machine,
		}
	end

	local catalog, release_error = fetch_release_catalog()
	if not catalog then
		return {
			ok = false,
			code = release_error.code,
			detail = release_error.detail,
		}
	end

	local release_state = build_release_state(resolve_release_channel(catalog, normalized_channel), arch_state)
	if not release_state.available then
		return {
			ok = false,
			code = "release_unavailable",
		}
	end

	if not release_state.has_matching_asset or not release_state.asset or release_state.asset.url == "" then
		return {
			ok = false,
			code = "release_no_matching_asset",
		}
	end

	local temp_dir = make_temp_dir()
	if not temp_dir then
		return {
			ok = false,
			code = "binary_install_failed",
			detail = "Failed to create a temporary directory",
		}
	end

	local package_path = temp_dir .. "/" .. (release_state.asset.name ~= "" and release_state.asset.name or "fileuni.ipk")
	local downloaded, download_detail = download_file(release_state.asset.url, package_path)
	if not downloaded then
		cleanup_path(temp_dir)
		return {
			ok = false,
			code = "download_failed",
			detail = download_detail,
		}
	end

	local installed, install_detail = run_shell("opkg install --force-reinstall --force-downgrade " .. shellquote(package_path))
	cleanup_path(temp_dir)
	if not installed then
		return {
			ok = false,
			code = "opkg_install_failed",
			detail = install_detail,
		}
	end

	restart_service_if_running()

	return {
		ok = true,
		code = "binary_installed",
		version = release_state.version,
		channel = normalized_channel,
	}
end

return M
