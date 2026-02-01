--[[
    ccpm - ComputerCraft Package Manager
    Copyright (C) 2026  Alexandre Leconte <aleconte@dwightstudio.fr>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses>.
--]]

local database    = require("ccpm.database")
local ctextutils  = require("commons.textutils")
local ctable      = require("commons.table")
local repo        = require("ccpm.repository")
local transaction = require("ccpm.transaction")
local eventutils  = require("ccpm.eventutils")
local args        = { ... }

-- TODO: Add version specifier in the install command

--- Print help message
local function printHelp(args)
    if not args or #args == 0 then
        print("Usage: ccpm help [command]")
        print("Commands:")
        print("  install     Install packages.")
        print("  uninstall   Uninstall packages.")
        print("  update      Update package index.")
        print("  upgrade     Upgrade packages.")
        print("  recover     Recover a stopped transaction.")
        print("  repo        Manage repositories.")
        print("  list        List available or installed packages.")
        print("  status      Show the current status.")
        print("  help        Show this help message")
    elseif args[1] == "install" then
        print("Usage: ccpm install <query1> [query2] ...")
        print("Install packages. The query can be a complete name or a pattern.")
    elseif args[1] == "uninstall" then
        print("Usage: ccpm uninstall <query1> [query2] ...")
        print("Uninstall packages. The query can be a complete name or a pattern.")
    elseif args[1] == "update" then
        print("Usage: ccpm update")
        print("Update package index and repositories manifests.")
    elseif args[1] == "upgrade" then
        print("Usage: ccpm upgrade [query1] [query2] ...")
        print("Upgrade packages. The query can be a complete name or a pattern.")
        print("Upgrade all packages. If no query is provided, all packages will be upgraded.")
    elseif args[1] == "recover" then
        print("Usage: ccpm recover")
        print("Recover stopped transaction (continue).")
    elseif args[1] == "repo" then
        if #args == 1 then
            print("Usage: ccpm repo <add|remove|list> [url1] [url2] ...")
            print("Manage repositories.")
        elseif args[2] == "add" then
            print("Usage: ccpm repo add <url1> [url2] ...")
            print("Add repositories.")
        elseif args[2] == "remove" then
            print("Usage: ccpm repo remove <url1> [url2] ...")
            print("Remove repositories.")
        elseif args[2] == "list" then
            print("Usage: ccpm repo list")
            print("List registered repositories.")
        else
            print("Invalid subcommand.")
        end
    elseif args[1] == "list" then
        print("Usage: ccpm list <available|installed> <query>")
        print("List available or installed packages. The query can be a complete name or a pattern.")
        print("If no query is provided, all packages will be listed.")
    elseif args[1] == "status" then
        print("Usage: ccpm status")
        print("Show the current status.")
    elseif args[1] == "help" then
        print("Usage: ccpm help [command]")
        print("Show this help message.")
    else
        printError("Invalid command.")
    end
end

--- Confirm a user action.
local function confirm()
    write("Proceed? (y/N): ")
    local answer = read()
    if answer == "y" or answer == "Y" then
        return true
    else
        return false
    end
end

local function repo_add()
    local urls = ctable.slice(args, 3)
    local added = 0

    for _, url in ipairs(urls) do
        local err = repo.add(url)
        if err then
            printError("Error: " .. err)
        else
            added = added + 1
        end
    end
    if added == 1 then
        print("Repository added.")
    elseif added > 1 then
        print(added .. " repositories added.")
    end
end

local function repo_remove()
    local queries = ctable.slice(args, 3)
    local ids = {}
    local removed = 0

    local header = { "Repositories removed" }
    local modes = { 0 }
    local rows = {}
    for _, query in ipairs(queries) do
        local r, err = database.search_repositories(query)
        if not r then
            printError("Error: " .. err)
            return
        end
        for id, re in pairs(r) do
            table.insert(rows, { re.name })
            table.insert(ids, id)
        end
    end

    if #rows == 0 then
        printError("No repositories found.")
        return
    end

    ctextutils.print_table(header, modes, rows)
    if not confirm() then
        printError("Operation canceled.")
        return
    end

    for _, id in ipairs(ids) do
        local err = database.remove_repository(id)
        if err then
            printError("Error: " .. err)
        else
            removed = removed + 1
        end
    end
    if removed == 1 then
        print("Repository removed.")
    elseif removed > 1 then
        print(removed .. " repositories removed.")
    end
end

local function repo_list()
    local repos = database.get_repositories()
    if not next(repos) then
        print("No repositories found.")
    else
        local header = { "Name", "UUID" }
        local modes = { 0, 8 }
        local rows = {}
        for id, r in pairs(repos) do
            table.insert(rows, { r.name, id })
        end
        table.sort(rows, function(a, b) return a[1] < b[1] end)
        ctextutils.print_table(header, modes, rows)
    end
end

local function update()
    local err = nil

    parallel.waitForAny(
        function()
            err = repo.update()
        end,
        function()
            local total = 1 / 0
            local count = 0
            local progress = eventutils.make_progress("Updating index")

            while true do
                local event = { os.pullEvent() }

                if event[1] == "ccpm_index_update_start" then
                    total = event[2]
                    progress(total, count)
                elseif event[1] == "ccpm_index_updated" then
                    count = count + 1
                    progress(total, count)
                elseif event[1] == "ccpm_index_not_updated" then
                    printError("Error while updating " .. event[2] .. ": " .. event[3])
                end
            end
        end
    )

    if err then
        printError("Error: " .. err)
    end
end

local function list_installed()
    local installed, count = database.get_installed_packages()
    if count == 0 then
        print("No packages installed.")
    else
        local header = { "Name", "Version" }
        local modes = { 0, -15 }
        local rows = {}
        for name, pkg in pairs(installed) do
            table.insert(rows, { name, pkg.version })
        end
        table.sort(rows, function(a, b) return a[1] < b[1] end)
        ctextutils.print_table(header, modes, rows)
    end
end

--- @return nil | string: Nil or error message.
local function transaction_summary()
    local header = { "", "Name", "Version" }
    local modes = { 2, 0, -15 }
    local rows = {}

    local un, ins = transaction.get_pending_changes()
    if not ins then
        return un
    end

    for name, version in pairs(un) do
        if not ins[name] then
            table.insert(rows, { " -", name, version })
        end
    end

    for name, version in pairs(ins) do
        if not un[name] then
            table.insert(rows, { " +", name, version })
        else
            table.insert(rows, { " \24", name, version })
        end
    end

    table.sort(rows, function(a, b)
        if a[1] == b[1] then
            return a[2] < b[2]
        else
            return a[1] > b[1]
        end
    end)

    if #rows == 0 then
        return ""
    end

    ctextutils.print_table(header, modes, rows)
end

local function list_available()
    local available, count = database.get_packages()
    if count == 0 then
        print("No packages available.")
    else
        local header = { "Name", "Latest version" }
        local modes = { 0, -15 }
        local rows = {}
        for name, pkg in pairs(available) do
            table.insert(rows, { name, pkg.latest_version })
        end
        table.sort(rows, function(a, b) return a[1] < b[1] end)
        ctextutils.print_table(header, modes, rows)
    end
end

local function install()
    local queries = ctable.slice(args, 2)
    local err = transaction.begin()
    if err then
        printError("Error: " .. err)
        return
    end

    for _, query in ipairs(queries) do
        local packages = database.search_packages(query)
        if next(packages) == nil then
            printError("No package found for query '" .. query .. "'")
        end
        for name, _ in pairs(packages) do
            if not database.get_installed_package(name) then
                local err = transaction.install(name)
                if err then
                    printError("Error: " .. err)
                end
            else
                local installed = database.get_installed_packages()
                if installed[name] and not installed[name].wanted then
                    installed[name].wanted = true
                    print("Marking package '" .. name .. "' as wanted")
                    database.set_packages_database(installed)
                end
            end
        end
    end

    err = transaction.resolve_dependencies()
    if err then
        printError("Error: " .. err)
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    err = transaction_summary()
    if err then
        if err == "" then
            print("Nothing to install.")
        else
            printError("Error: " .. err)
        end
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    if not confirm() then
        print("Operation canceled.")
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    parallel.waitForAny(
        function()
            err = transaction.commit()
        end,
        eventutils.process_transaction_events
    )

    if err then
        printError("Error: " .. err)
        return
    else
        print("Transaction completed.")
    end
end

local function uninstall()
    local queries = ctable.slice(args, 2)
    local err = transaction.begin()
    if err then
        printError("Error: " .. err)
        return
    end

    for _, query in ipairs(queries) do
        local packages = database.search_installed_packages(query)
        if next(packages) == nil then
            printError("No package found for query '" .. query .. "'")
        end
        for name, _ in pairs(packages) do
            local err = transaction.uninstall(name)
            if err then
                printError("Error: " .. err)
            end
        end
    end

    err = transaction.resolve_required_by()
    if err then
        printError("Error: " .. err)
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    err = transaction.auto_remove()
    if err then
        printError("Error: " .. err)
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    err = transaction_summary()
    if err then
        if err == "" then
            print("Nothing to uninstall.")
        else
            printError("Error: " .. err)
        end
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    if not confirm() then
        print("Operation canceled.")
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    parallel.waitForAny(
        function()
            err = transaction.commit()
        end,
        eventutils.process_transaction_events
    )

    if err then
        printError("Error: " .. err)
        return
    else
        print("Transaction completed.")
    end
end

--- Check for updates
local function check_for_update()
    local count = 0
    local installed = database.get_installed_packages()
    for name, pkg_data in pairs(installed) do
        local package = database.get_package(name)
        if package and pkg_data.version ~= package.latest_version then
            count = count + 1
        end
    end


    if count == 1 then
        print("1 package is pending upgrade.")
    elseif count > 0 then
        print(count .. " packages are pending upgrade.")
    else
        print("All packages are up to date.")
    end
end

local function upgrade()
    local err = transaction.begin()
    if err then
        printError("Error: " .. err)
        return
    end

    if #args > 2 then
        local queries = ctable.slice(args, 2)

        for _, query in ipairs(queries) do
            local installed = database.search_installed_packages(query)
            if next(installed) == nil then
                printError("No package found for query '" .. query .. "'")
            end
            for name, pkg_data in pairs(installed) do
                local package = database.get_package(name)
                if package and pkg_data.version ~= package.latest_version then
                    local err = transaction.uninstall(name)
                    if err then
                        printError("Error: " .. err)
                    end
                    err = transaction.install(name, package.latest_version, pkg_data.wanted)
                    if err then
                        printError("Error: " .. err)
                    end
                end
            end
        end
    else
        local installed = database.get_installed_packages()
        for name, pkg_data in pairs(installed) do
            local package = database.get_package(name)
            if package and pkg_data.version ~= package.latest_version then
                local err = transaction.uninstall(name)
                if err then
                    printError("Error: " .. err)
                end
                err = transaction.install(name, package.latest_version, pkg_data.wanted)
                if err then
                    printError("Error: " .. err)
                end
            end
        end
    end

    err = transaction.resolve_dependencies()
    if err then
        printError("Error: " .. err)
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    err = transaction.resolve_required_by()
    if err then
        printError("Error: " .. err)
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    err = transaction.auto_remove()
    if err then
        printError("Error: " .. err)
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    err = transaction_summary()
    if err then
        if err == "" then
            print("Everything is up to date.")
        else
            printError("Error: " .. err)
        end
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    if not confirm() then
        print("Operation canceled.")
        err = transaction.abort()
        if err then
            printError("Error: " .. err)
        end
        return
    end

    parallel.waitForAny(
        function()
            err = transaction.commit()
        end,
        eventutils.process_transaction_events
    )

    if err then
        printError("Error: " .. err)
        return
    else
        print("Transaction completed.")
    end
end

local function recover()
    local err = nil

    parallel.waitForAny(
        function()
            err = transaction.recover()
        end,
        eventutils.process_transaction_events
    )

    if err then
        printError("Error: " .. err)
    else
        print("Transaction recovered.")
    end
end

if #args == 0 then
    printHelp({})
elseif args[1] == "help" then
    table.remove(args, 1)
    printHelp(args)
elseif args[1] == "install" then
    if #args == 1 then
        printHelp(args)
    else
        install()
    end
elseif args[1] == "uninstall" then
    if #args == 1 then
        printHelp(args)
    else
        uninstall()
    end
elseif args[1] == "update" then
    update()
    check_for_update()
elseif args[1] == "upgrade" then
    upgrade()
elseif args[1] == "recover" then
    recover()
elseif args[1] == "repo" then
    if #args == 1 then
        printHelp(args)
    elseif args[2] == "add" then
        if #args == 3 then
            repo_add()
        else
            printHelp(args)
        end
    elseif args[2] == "remove" then
        if #args == 3 then
            repo_remove()
        else
            printHelp(args)
        end
    elseif args[2] == "list" then
        repo_list()
    else
        print("Invalid subcommand.")
    end
elseif args[1] == "list" then
    if #args == 1 then
        printHelp(args)
    else
        if args[2] == "installed" then
            list_installed()
        elseif args[2] == "available" then
            list_available()
        else
            printError("Invalid subcommand.")
        end
    end
elseif args[1] == "status" then
    if transaction.needs_recovery() then
        printError("Transaction needs recovery. Run 'ccpm recover' to recover.")
    end

    local status = transaction.get_status()
    print("Transaction status: " .. status)

    transaction_summary()
end
