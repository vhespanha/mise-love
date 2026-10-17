--- Resolves LÖVE release assets for the current platform.
local http = require("http")
local json = require("json")
local log = require("log")
local checksums = require("checksums")

local M = {}

M.REPO = "love2d/love"

-- Oldest major version with prebuilt binaries for every supported platform
M.MIN_MAJOR = 11

-- Asset name patterns, used for versions missing from lib/checksums.lua.
-- Keep in sync with mise-tasks/update-checksums.
local PATTERNS = {
    ["linux-amd64"] = "x86_64%.AppImage$",
    ["linux-386"] = "i686%.AppImage$",
    ["darwin"] = "macos%.zip$",
    ["windows-amd64"] = "win64%.zip$",
    ["windows-386"] = "win32%.zip$",
}

--- Returns true if the version has prebuilt binaries this plugin can install
--- @param version string
--- @return boolean
function M.is_supported(version)
    local major = tonumber(version:match("^(%d+)%."))
    return major ~= nil and major >= M.MIN_MAJOR
end

--- Returns the platform key for the platform being installed
--- @return string
function M.platform_key()
    local os_name = RUNTIME.osType:lower()
    -- The macOS build is a universal binary
    if os_name == "darwin" then
        return "darwin"
    end
    return os_name .. "-" .. RUNTIME.archType
end

--- Finds an asset for an unknown version by querying the GitHub release
--- @param version string
--- @param platform string
--- @return string|nil asset name
local function find_asset(version, platform)
    local pattern = PATTERNS[platform]
    if pattern == nil then
        return nil
    end

    local resp, err = http.get({
        url = "https://api.github.com/repos/" .. M.REPO .. "/releases/tags/" .. version,
    })
    if err ~= nil then
        error("Failed to fetch LÖVE release " .. version .. ": " .. err)
    end
    if resp.status_code == 404 then
        error("LÖVE release " .. version .. " does not exist")
    end
    if resp.status_code ~= 200 then
        error("GitHub API returned status " .. resp.status_code .. ": " .. resp.body)
    end

    for _, asset in ipairs(json.decode(resp.body).assets) do
        if asset.name:match(pattern) then
            return asset.name
        end
    end
    return nil
end

--- Returns the download URL and checksum (if known) for a version
--- @param version string
--- @return {url: string, sha256: string|nil}
function M.resolve(version)
    if not M.is_supported(version) then
        error("LÖVE " .. version .. " is not supported; this plugin installs " .. M.MIN_MAJOR .. ".0 and newer")
    end

    local platform = M.platform_key()
    local known = checksums[version] and checksums[version][platform]
    local asset, sha256
    if known ~= nil then
        asset, sha256 = known.file, known.sha256
    else
        asset = find_asset(version, platform)
        if asset ~= nil then
            log.warn("No bundled checksum for " .. asset .. "; the download will not be verified")
        end
    end

    if asset == nil then
        error(
            "LÖVE "
                .. version
                .. " has no prebuilt binary for "
                .. platform
                .. "; build it from source or use your system package manager"
        )
    end

    return {
        url = "https://github.com/" .. M.REPO .. "/releases/download/" .. version .. "/" .. asset,
        sha256 = sha256,
    }
end

return M
