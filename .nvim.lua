local root_dir = vim.fn.getcwd()
local output_dir = root_dir .. "/test_output"
local scene = "Test/test_scene.tscn"
local godot = "godot"

-- ===== SCENARIO DEFINITIONS =====
local scenarios = {
    ["2p"] = {
        desc = "Two players",
        cmds = {
            godot .. " " .. scene .. " -- -p=lopdo -m=test -a=cm -pc=2",
            godot .. " " .. scene .. " -- -p=lopdo2 -m=test -a=jm",
        },
    },
    ["3players"] = {
        desc = "Three players",
        cmds = {
            godot .. " " .. scene .. " -- -p=lopdo -m=test -a=cm -pc=3",
            godot .. " " .. scene .. " -- -p=player2 -m=test -a=jm",
            godot .. " " .. scene .. " -- -p=player3 -m=test -a=jm",
        },
    },
}

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
        local parts = vim.fn.split(cmd, " ")
        local logfile = output_dir .. ("/player_%d.log"):format(i - 1)

        vim.fn.jobstart(parts, {
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
            stdout_buffered = true,
            stderr_buffered = true,
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
