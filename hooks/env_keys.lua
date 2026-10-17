--- Configures environment variables for the installed tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook
--- @param ctx {path: string, runtimeVersion: string, sdkInfo: table} Context
--- @return table[] List of environment variable definitions
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    -- On Windows love.exe and lovec.exe sit next to their DLLs at the install root
    if RUNTIME.osType:lower() == "windows" then
        return {
            {
                key = "PATH",
                value = mainPath,
            },
        }
    end

    -- On Linux and macOS bin/love is a wrapper created by PostInstall
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
    }
end
