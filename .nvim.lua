local output_dir = vim.fn.getcwd() .. "/test_output"

local scenarios = dofile(vim.fn.getcwd() .. "/scenarios.lua")

local function run_scenario(scenario)
    local s = scenarios[scenario]
    if not s then
        vim.notify("Unknown scenario: " .. scenario, vim.log.levels.ERROR)
        return
    end

    vim.fn.mkdir(output_dir, "p")
    local total = #s.cmds
    local done = 0
    local failed = 0
    vim.notify(("Scenario [%s] starting %d instances..."):format(scenario, total), vim.log.levels.INFO)

    for i, cmd in ipairs(s.cmds) do
        local logfile = output_dir .. ("/player_%d.log"):format(i - 1)
        local shell_cmd = cmd .. " > " .. logfile .. " 2>&1"

        vim.fn.jobstart({"bash", "-c", shell_cmd}, {
            on_exit = function(_, exit_code)
                done = done + 1
                if exit_code ~= 0 then
                    failed = failed + 1
                end
                if done == total then
                    if failed == 0 then
                        vim.notify(("Scenario [%s] finished. Logs: %s"):format(scenario, output_dir), vim.log.levels.INFO)
                    else
                        vim.notify(("Scenario [%s] finished with %d/%d failures. Logs: %s"):format(scenario, failed, total, output_dir), vim.log.levels.WARN)
                    end
                end
            end,
        })
    end
end

vim.api.nvim_create_user_command("Run", function(opts)
    run_scenario(opts.args)
end, {
    nargs = 1,
    complete = function()
        return vim.tbl_keys(scenarios)
    end,
    desc = "Run a multiplayer test scenario",
})
