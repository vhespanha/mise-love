--- Returns download information for a specific version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx)
    local releases = require("releases")

    local version = ctx.version
    local release = releases.resolve(version)

    return {
        version = version,
        url = release.url,
        sha256 = release.sha256,
        note = "Downloading LÖVE " .. version,
    }
end
