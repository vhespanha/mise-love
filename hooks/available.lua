--- Returns a list of available versions for the tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
--- @param ctx {args: string[]} Context (args = user arguments)
--- @return table[] List of available versions
function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")
    local releases = require("releases")

    local result = {}
    local url = "https://api.github.com/repos/" .. releases.REPO .. "/releases?per_page=100"

    while url ~= nil do
        local resp, err = http.get({ url = url })
        if err ~= nil then
            error("Failed to fetch versions: " .. err)
        end
        if resp.status_code ~= 200 then
            error("GitHub API returned status " .. resp.status_code .. ": " .. resp.body)
        end

        for _, release in ipairs(json.decode(resp.body)) do
            local version = release.tag_name:gsub("^v", "")
            if not release.draft and releases.is_supported(version) then
                table.insert(result, {
                    version = version,
                    note = release.prerelease and "pre-release" or nil,
                })
            end
        end

        url = resp.headers["link"] and resp.headers["link"]:match('<([^>]+)>;%s*rel="next"')
    end

    return result
end
