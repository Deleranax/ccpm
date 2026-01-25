--[[
    libccpm - Library for CCPM
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

local database = require("ccpm.database")
local package = require("ccpm.package")
local event = require("ccpm.eventutils")
local expect = require("cc.expect")
local Digest = require("lockbox.digest.sha2_256")
local Stream = require("lockbox.util.stream")

--- @export
local transaction = {}

-- TODO: Add "check_file_conflicts" to detect file conflicts with local storage and other packages.
-- TODO: Add support for local ccp packages install (move download out of commit?[<-- Prefered] add download list?).

transaction.TRANSACTION_STATUSES = {
    IDLE = "idle",
    PENDING = "pending",
    COMMITTING = "committing",
    COMMITTED = "committed",
    ABORTED = "aborted",
    FAILED = "failed",
    ROLLED_BACK = "rolled_back"
}
transaction.PROGRESS_STATUSES = {
    PENDING = "pending",
    STARTED = "started",
    COMPLETED = "completed"
}
transaction.TRANSACTION_DIR = database.STORAGE_DIR .. "transaction/"
transaction.DOWNLOAD_DIR = transaction.TRANSACTION_DIR .. "download/"
transaction.INSTALL_ROOT = transaction.TRANSACTION_DIR .. "install/"
transaction.UNINSTALL_ROOT = transaction.TRANSACTION_DIR .. "uninstall/"
transaction.INIT_FILE = transaction.TRANSACTION_DIR .. "init.json"
transaction.PROGRESS_FILE = transaction.TRANSACTION_DIR .. "progress.json"

local current_transaction = nil
local current_progress = nil

--- Load a transaction from a file.
--- @param path string: The path to the transaction file.
--- @return table | nil: The transaction data or nil if the file does not exist.
local function load(path)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local data = file.readAll()
        file.close()
        return textutils.unserializeJSON(data)
    else
        return nil
    end
end

--- Save a transaction to a file.
--- @param path string: The path to the transaction file.
--- @param data table: The transaction data to save.
local function save(path, data)
    local file = fs.open(path, "w")
    file.write(textutils.serializeJSON(data))
    file.close()
end

--- Begin a transaction.
--- @return string|nil: Error message or nil if successful.
function transaction.begin()
    if current_transaction and current_transaction.status ~= transaction.TRANSACTION_STATUSES.ABORTED then
        local err = transaction.abort()
        if err then
            return err
        end
    end

    current_transaction = {
        ["time_begin"] = os.epoch(),
        ["time_commit"] = nil,
        ["status"] = transaction.TRANSACTION_STATUSES.PENDING,
        ["install"] = {},
        ["uninstall"] = {}
    }
    save(transaction.INIT_FILE, current_transaction)
end

--- Rollback a transaction.
--- @return string|nil: Error message or nil if successful.
function transaction.abort()
    if current_transaction then
        if current_transaction.status == transaction.TRANSACTION_STATUSES.COMMITTING
            or current_transaction.status == transaction.TRANSACTION_STATUSES.FAILED then
            return "transaction is committing or failed: can only be recovered or rolled back"
        end

        if current_transaction.status == transaction.TRANSACTION_STATUSES.ABORTED then
            return "transaction is already aborted"
        end
    end

    current_transaction = nil
    current_progress = nil

    fs.delete(transaction.TRANSACTION_DIR)
end

function transaction.get_status()
    if current_transaction then
        return current_transaction.status
    else
        return transaction.TRANSACTION_STATUSES.IDLE
    end
end

--- Install a package.
--- @param name string: The name of the package to install.
--- @param version? string | nil: The version of the package to install or nil for latest.
--- @param wanted? boolean: Whether the package is wanted or not (wanted = explicitly installed by user). If nil, defaults to true.
--- @return nil | string: Error message or nil if successful.
function transaction.install(name, version, wanted)
    expect(1, name, "string")
    expect(2, version, "string", "nil")
    expect(3, wanted, "boolean", "nil")

    if wanted == nil then
        wanted = true
    end

    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        local pack, err = database.get_package(name)
        if not pack then
            return "cannot install package: " .. err
        end

        if not version then
            version = pack.latest_version
        end

        if not pack.versions[version] then
            return "package version not found: " .. version
        end

        table.insert(current_transaction.install, { name = name, version = version, wanted = wanted })
        save(transaction.INIT_FILE, current_transaction)
    else
        return "transaction is not pending"
    end
end

--- Uninstall a package.
--- @param name string The name of the package to uninstall.
function transaction.uninstall(name)
    expect(1, name, "string")

    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        local p, err = database.get_installed_package(name)
        if not p then
            return "cannot uninstall package: " .. err
        end

        table.insert(current_transaction.uninstall, {
            name = name,
            version = p.version,
            files = p.files,
            dependencies = p.dependencies,
            description = p.description,
            license = p.license,
            authors = p.authors,
            maintainers = p.maintainers,
            wanted = p.wanted
        })
        save(transaction.INIT_FILE, current_transaction)
    else
        return "transaction is not pending"
    end
end

--- Check that packages in the uninstall list are actually installed.
--- @return string | nil Error message or nil if no error.
local function do_check_installed()
    local installed_packages = database.get_installed_packages()

    for _, uninstall_pkg in ipairs(current_transaction.uninstall) do
        if not installed_packages[uninstall_pkg.name] then
            return "cannot uninstall '" .. uninstall_pkg.name .. "': package not installed"
        end
    end

    return nil
end

--- Check that packages in the install list are not already installed.
--- @return string | nil Error message or nil if no error.
local function do_check_already_installed()
    local installed_packages = database.get_installed_packages()

    for _, install_pkg in ipairs(current_transaction.install) do
        if installed_packages[install_pkg.name] then
            -- Check if package is being uninstalled in same transaction (upgrade scenario)
            local being_uninstalled = false
            for _, uninstall_pkg in ipairs(current_transaction.uninstall) do
                if uninstall_pkg.name == install_pkg.name then
                    being_uninstalled = true
                    break
                end
            end

            if not being_uninstalled then
                return "cannot install '" ..
                    install_pkg.name .. "': package already installed (uninstall first or use upgrade)"
            end
        end
    end

    return nil
end

--- Check that the uninstalled package is not required by any other installed package.
--- @return string | nil Error message or nil if no error.
local function do_check_reverse_dependencies()
    -- Check installed packages
    local installed_packages = database.get_installed_packages()

    -- Build set of packages in uninstall list
    local to_uninstall = {}
    for _, pkg in ipairs(current_transaction.uninstall) do
        to_uninstall[pkg.name] = true
    end

    for _, uninstall_pkg in ipairs(current_transaction.uninstall) do
        -- Check if package is being reinstalled (upgrade scenario)
        local being_reinstalled = false
        for _, install_pkg in ipairs(current_transaction.install) do
            if install_pkg.name == uninstall_pkg.name then
                being_reinstalled = true
                break
            end
        end

        -- Skip reverse dependency check if package is being reinstalled
        if not being_reinstalled then
            -- Check if any installed package depends on this package
            for pkg_name, pkg_data in pairs(installed_packages) do
                -- Skip packages that are also being uninstalled
                if not to_uninstall[pkg_name] then
                    local dependencies = pkg_data.dependencies or {}
                    for _, dep in ipairs(dependencies) do
                        if dep == uninstall_pkg.name then
                            return "cannot uninstall '" ..
                                uninstall_pkg.name .. "': required by installed package '" .. pkg_name .. "'"
                        end
                    end
                end
            end

            -- Check if any package in install list depends on this package
            for _, install_pkg in ipairs(current_transaction.install) do
                local pkg_info, err = database.get_package(install_pkg.name)
                if not pkg_info then
                    return "cannot get package info: " .. err
                end
                if not pkg_info.versions[install_pkg.version] then
                    return "version not found in database: " .. install_pkg.name .. " " .. install_pkg.version
                end
                local dependencies = pkg_info.versions[install_pkg.version].dependencies or {}
                for _, dep in ipairs(dependencies) do
                    if dep == uninstall_pkg.name then
                        return "cannot uninstall '" ..
                            uninstall_pkg.name .. "': required by package to install '" .. install_pkg.name .. "'"
                    end
                end
            end
        end
    end

    return nil
end

--- Check that the new packages have all their dependencies installed or in the transaction.
--- @return string | nil Error message or nil if no error.
local function do_check_dependencies()
    local installed_packages = database.get_installed_packages()

    for _, install_pkg in ipairs(current_transaction.install) do
        local pkg_info, err = database.get_package(install_pkg.name)
        if not pkg_info then
            return err
        end

        if not pkg_info.versions[install_pkg.version] then
            return "version not found: " .. install_pkg.name .. " " .. install_pkg.version
        end

        local dependencies = pkg_info.versions[install_pkg.version].dependencies or {}
        for _, dep in ipairs(dependencies) do
            local dep_installed = installed_packages[dep] ~= nil
            local dep_in_transaction = false

            -- Check if dependency is in transaction's install list
            for _, trans_pkg in ipairs(current_transaction.install) do
                if trans_pkg.name == dep then
                    dep_in_transaction = true
                    break
                end
            end

            if not dep_installed and not dep_in_transaction then
                return "missing dependency: '" .. dep .. "' required by '" .. install_pkg.name .. "'"
            end
        end
    end

    return nil
end

--- Log progress of a package in the transaction.
--- @param number number The index of the package in the transaction.
--- @param status string The status of the package.
local function log_progress(number, status)
    current_progress[number] = { status = status }
    save(transaction.PROGRESS_FILE, current_progress)
end

--- Remove empty directories recursively.
--- @param path string The path to the directory to remove.
local function bubble_remove_empty_dirs(path)
    local dir = fs.getDir(path)
    if dir ~= "" and fs.exists(dir) then
        local contents = fs.list(dir)
        if #contents == 0 then
            fs.delete(dir)
            bubble_remove_empty_dirs(dir)
        end
    end
end

--- Check the hash of a file.
--- @param path string The path to the file to check.
--- @param hash string The expected hash of the file.
--- @return boolean True if the hash matches, false otherwise.
local function check_hash(path, hash)
    if fs.exists(path) then
        local content = ""
        do
            local file = fs.open(path, "r")
            content = file.readAll()
            file.close()
        end

        local digest = Digest()
            .init()
            .update(Stream.fromString(content))
            .finish()
            .asHex()
        return digest == hash
    else
        return false
    end
end

--- Do download new packages.
--- @return string | nil Error message or nil if no error.
local function do_download()
    if not fs.exists(transaction.DOWNLOAD_DIR) then
        fs.makeDir(transaction.DOWNLOAD_DIR)
    end

    for i, install_pkg in ipairs(current_transaction.install) do
        local err = package.download(install_pkg.name, install_pkg.version, transaction.DOWNLOAD_DIR)
        if err then
            return "failed to download '" .. install_pkg.name .. "': " .. err
        end
    end

    return nil
end

--- Do uninstall a package.
--- @param number number The index of the package to uninstall in the transaction.
--- @return string | nil Error message or nil if no error.
local function do_uninstall(number)
    log_progress(number, transaction.PROGRESS_STATUSES.STARTED)

    local uninstall_pkg = current_transaction.uninstall[number]
    event.dispatch("ccpm_package_uninstalling", uninstall_pkg.name, uninstall_pkg.version)

    local installed_pkg, err = database.get_installed_package(uninstall_pkg.name)
    if not installed_pkg then
        event.dispatch("ccpm_package_not_uninstalled", uninstall_pkg.name, uninstall_pkg.version, err)
        return err
    end

    -- Move each installed file to uninstall directory
    for file_path, hash in pairs(installed_pkg.files or {}) do
        fs.move(file_path, transaction.UNINSTALL_ROOT .. file_path)
        bubble_remove_empty_dirs(file_path)
    end

    -- Remove package from database
    local installed_packages = database.get_installed_packages()
    installed_packages[uninstall_pkg.name] = nil
    database.set_packages_database(installed_packages)

    event.dispatch("ccpm_package_uninstalled", uninstall_pkg.name, uninstall_pkg.version)
    log_progress(number, transaction.PROGRESS_STATUSES.COMPLETED)
    return nil
end

--- Do install a package.
--- @param number number The index of the package to install in the transaction.
--- @return string | nil Error message or nil if no error.
local function do_install(number)
    local progress_index = #current_transaction.uninstall + number
    log_progress(progress_index, transaction.PROGRESS_STATUSES.STARTED)

    local install_pkg = current_transaction.install[number]
    event.dispatch("ccpm_package_installing", install_pkg.name, install_pkg.version)

    local download_path = transaction.DOWNLOAD_DIR .. install_pkg.name .. "." .. install_pkg.version .. ".ccp"

    if not fs.exists(download_path) then
        local err = "package file not found: " .. download_path
        event.dispatch("ccpm_package_not_installed", install_pkg.name, install_pkg.version, err)
        return err
    end

    -- Unpack package
    local manifest, err = package.unpack(download_path, transaction.INSTALL_ROOT)
    if not manifest then
        local error_msg = "failed to unpack '" .. install_pkg.name .. "': " .. err
        event.dispatch("ccpm_package_not_installed", install_pkg.name, install_pkg.version, error_msg)
        return error_msg
    end

    local files = {}
    for file_path, file_data in pairs(manifest.files) do
        files[file_path] = file_data.digest
    end

    -- Update packages database with installed package info
    local installed_packages = database.get_installed_packages()
    installed_packages[install_pkg.name] = {
        version = install_pkg.version,
        files = files,
        dependencies = manifest.dependencies,
        description = manifest.description,
        license = manifest.license,
        authors = manifest.authors,
        maintainers = manifest.maintainers,
        wanted = install_pkg.wanted
    }

    -- Save updated database
    database.set_packages_database(installed_packages)

    event.dispatch("ccpm_package_installed", install_pkg.name, install_pkg.version)
    log_progress(progress_index, transaction.PROGRESS_STATUSES.COMPLETED)
    return nil
end

--- Move files from one directory to another, recursively, merging them.
local function merge_move_files(from, to)
    if fs.exists(from) then
        for _, file in ipairs(fs.list(from)) do
            local path_from = fs.combine(from, file)
            local path_to = fs.combine(to, file)
            if fs.isDir(path_from) then
                merge_move_files(path_from, path_to)
            else
                -- TODO: Handle file conflicts
                if fs.exists(path_to) then
                    fs.delete(path_to)
                end
                fs.move(path_from, path_to)
            end
        end
    end
end

--- Commit a transaction.
--- @return string | nil: Error message or nil if no error.
function transaction.commit()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        event.dispatch("ccpm_transaction_checking")
        local err = do_check_installed()
        if err then
            event.dispatch("ccpm_transaction_failed", err)
            return err
        end

        local err = do_check_already_installed()
        if err then
            event.dispatch("ccpm_transaction_failed", err)
            return err
        end

        local err = do_check_reverse_dependencies()
        if err then
            event.dispatch("ccpm_transaction_failed", err)
            return err
        end

        err = do_check_dependencies()
        if err then
            event.dispatch("ccpm_transaction_failed", err)
            return err
        end

        current_progress = {}
        for i = 1, #current_transaction.install + #current_transaction.uninstall do
            log_progress(i, transaction.PROGRESS_STATUSES.PENDING)
        end

        current_transaction.status = transaction.TRANSACTION_STATUSES.COMMITTING
        save(transaction.INIT_FILE, current_transaction)

        event.dispatch("ccpm_transaction_downloading", #current_transaction.install)
        err = do_download()
        if err then
            event.dispatch("ccpm_transaction_failed", err)
            transaction.rollback()
            return err
        end

        event.dispatch("ccpm_transaction_uninstalling", #current_transaction.uninstall)
        for i = 1, #current_transaction.uninstall do
            err = do_uninstall(i)
            if err then
                event.dispatch("ccpm_transaction_failed", err)
                transaction.rollback()
                return err
            end
        end

        event.dispatch("ccpm_transaction_installing", #current_transaction.install)
        for i = 1, #current_transaction.install do
            err = do_install(i)
            if err then
                event.dispatch("ccpm_transaction_failed", err)
                transaction.rollback()
                return err
            end
        end

        -- Move files from INSTALL_ROOT to /
        merge_move_files(transaction.INSTALL_ROOT, "/")

        -- Delete all temporary folders
        if fs.exists(transaction.DOWNLOAD_DIR) then
            fs.delete(transaction.DOWNLOAD_DIR)
        end
        if fs.exists(transaction.INSTALL_ROOT) then
            fs.delete(transaction.INSTALL_ROOT)
        end
        if fs.exists(transaction.UNINSTALL_ROOT) then
            fs.delete(transaction.UNINSTALL_ROOT)
        end

        current_transaction.status = transaction.TRANSACTION_STATUSES.COMMITTED
        save(transaction.INIT_FILE, current_transaction)

        event.dispatch("ccpm_transaction_completed", #current_transaction.install, #current_transaction.uninstall)
        return nil
    else
        return "transaction is not pending"
    end
end

--- Rollback a transaction.
--- @return string | nil: Error message or nil if successful
function transaction.rollback()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.COMMITTING
            and current_transaction.status ~= transaction.TRANSACTION_STATUSES.FAILED then
            return "transaction is not committing or failed"
        end

        local installed_packages = database.get_installed_packages()

        -- Remove installed packages from database and delete their files
        for i, install_pkg in ipairs(current_transaction.install) do
            local progress_index = #current_transaction.uninstall + i

            -- Check if package was actually installed (progress shows COMPLETED)
            if current_progress and current_progress[progress_index]
                and current_progress[progress_index].status == transaction.PROGRESS_STATUSES.COMPLETED then
                -- Get package info from database to get file list
                local pkg_data = installed_packages[install_pkg.name]
                if pkg_data then
                    -- Remove from database
                    installed_packages[install_pkg.name] = nil
                end
            end
        end

        -- Restore uninstalled packages: move files back from UNINSTALL_ROOT
        merge_move_files(transaction.UNINSTALL_ROOT, "/")

        -- Restore uninstalled packages to database
        for i, uninstall_pkg in ipairs(current_transaction.uninstall) do
            -- Check if package was actually uninstalled (progress shows COMPLETED)
            if current_progress and current_progress[i]
                and current_progress[i].status == transaction.PROGRESS_STATUSES.COMPLETED then
                -- Restore package to database with stored info from transaction
                installed_packages[uninstall_pkg.name] = {
                    version = uninstall_pkg.version,
                    files = uninstall_pkg.files or {},
                    dependencies = uninstall_pkg.dependencies,
                    description = uninstall_pkg.description,
                    license = uninstall_pkg.license,
                    authors = uninstall_pkg.authors,
                    maintainers = uninstall_pkg.maintainers
                }
            end
        end

        -- Save updated database
        database.set_packages_database(installed_packages)

        -- Delete all temporary folders
        if fs.exists(transaction.DOWNLOAD_DIR) then
            fs.delete(transaction.DOWNLOAD_DIR)
        end
        if fs.exists(transaction.INSTALL_ROOT) then
            fs.delete(transaction.INSTALL_ROOT)
        end
        if fs.exists(transaction.UNINSTALL_ROOT) then
            fs.delete(transaction.UNINSTALL_ROOT)
        end

        current_transaction.status = transaction.TRANSACTION_STATUSES.ROLLED_BACK
        save(transaction.INIT_FILE, current_transaction)

        event.dispatch("ccpm_transaction_rolled_back")
        return nil
    else
        return "transaction is not committing or failed"
    end
end

--- Check if a transaction needs recovery.
function transaction.needs_recovery()
    return current_transaction and (
        current_transaction.status == transaction.TRANSACTION_STATUSES.COMMITTING
    )
end

--- Recover a transaction.
function transaction.recover()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.COMMITTING then
            return "transaction is not committing"
        end

        local err

        -- Check if downloads are complete
        local downloads_complete = true
        for i = 1, #current_transaction.install do
            local progress_index = #current_transaction.uninstall + i
            if not current_progress[progress_index] or
                current_progress[progress_index].status ~= transaction.PROGRESS_STATUSES.COMPLETED then
                downloads_complete = false
                break
            end
        end

        if not downloads_complete then
            -- Resume downloading
            event.dispatch("ccpm_transaction_downloading", #current_transaction.install)
            err = do_download()
            if err then
                event.dispatch("ccpm_transaction_failed", err)
                transaction.rollback()
                return err
            end
        end

        -- Resume uninstalls from where we left off
        event.dispatch("ccpm_transaction_uninstalling", #current_transaction.uninstall)
        for i = 1, #current_transaction.uninstall do
            if not current_progress[i] or
                current_progress[i].status ~= transaction.PROGRESS_STATUSES.COMPLETED then
                err = do_uninstall(i)
                if err then
                    event.dispatch("ccpm_transaction_failed", err)
                    transaction.rollback()
                    return err
                end
            end
        end

        -- Resume installs from where we left off
        event.dispatch("ccpm_transaction_installing", #current_transaction.install)
        for i = 1, #current_transaction.install do
            local progress_index = #current_transaction.uninstall + i
            if not current_progress[progress_index] or
                current_progress[progress_index].status ~= transaction.PROGRESS_STATUSES.COMPLETED then
                err = do_install(i)
                if err then
                    event.dispatch("ccpm_transaction_failed", err)
                    transaction.rollback()
                    return err
                end
            end
        end

        -- Move install files to root if they haven't been moved yet
        merge_move_files(transaction.INSTALL_ROOT, "/")

        -- Delete all temporary folders
        if fs.exists(transaction.DOWNLOAD_DIR) then
            fs.delete(transaction.DOWNLOAD_DIR)
        end
        if fs.exists(transaction.INSTALL_ROOT) then
            fs.delete(transaction.INSTALL_ROOT)
        end
        if fs.exists(transaction.UNINSTALL_ROOT) then
            fs.delete(transaction.UNINSTALL_ROOT)
        end

        current_transaction.status = transaction.TRANSACTION_STATUSES.COMMITTED
        save(transaction.INIT_FILE, current_transaction)

        event.dispatch("ccpm_transaction_completed", #current_transaction.install, #current_transaction.uninstall)
        return nil
    else
        return "transaction is not committing"
    end
end

--- Resolve dependencies for the install list and add it to the transaction.
--- @return nil|string: Error message or nil if successful.
function transaction.resolve_dependencies()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        local installed_packages = database.get_installed_packages()
        local to_install = {} -- Track packages already in install list

        -- Build set of packages already in install list
        for _, pkg in ipairs(current_transaction.install) do
            to_install[pkg.name] = true
        end

        -- Queue of packages to process (start with current install list)
        local queue = {}
        for _, pkg in ipairs(current_transaction.install) do
            table.insert(queue, pkg)
        end

        -- Process queue to resolve dependencies recursively
        while #queue > 0 do
            local current_pkg = table.remove(queue, 1)

            -- Get package info
            local pkg_info, err = database.get_package(current_pkg.name)
            if not pkg_info then
                return "cannot resolve dependencies: " .. err
            end

            if not pkg_info.versions[current_pkg.version] then
                return "version not found: " .. current_pkg.name .. " " .. current_pkg.version
            end

            -- Process dependencies
            local dependencies = pkg_info.versions[current_pkg.version].dependencies or {}
            for _, dep_name in ipairs(dependencies) do
                -- Check if dependency is already installed or in install list
                if not installed_packages[dep_name] and not to_install[dep_name] then
                    -- Get dependency package info
                    local dep_pkg_info, dep_err = database.get_package(dep_name)
                    if not dep_pkg_info then
                        return "cannot resolve dependency '" .. dep_name .. "': " .. dep_err
                    end

                    -- Use latest_version for the dependency
                    local dep_version = dep_pkg_info.latest_version
                    if not dep_version then
                        return "no version available for dependency: " .. dep_name
                    end

                    -- Add to install list and queue
                    local dep_pkg = {
                        name = dep_name,
                        version = dep_version,
                        wanted = false
                    }
                    table.insert(current_transaction.install, dep_pkg)
                    table.insert(queue, dep_pkg)
                    to_install[dep_name] = true
                end
            end
        end

        save(transaction.INIT_FILE, current_transaction)
        return nil
    else
        return "transaction is not pending"
    end
end

--- Resolve reverse dependencies for the uninstall list and add it to the transaction.
--- @return nil|string: Error message or nil if successful.
function transaction.resolve_required_by()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        local installed_packages = database.get_installed_packages()
        local to_uninstall = {} -- Track packages already in uninstall list
        local to_install = {}   -- Track packages in install list

        -- Build set of packages already in uninstall list
        for _, pkg in ipairs(current_transaction.uninstall) do
            to_uninstall[pkg.name] = true
        end

        -- Build set of packages already in install list
        for _, pkg in ipairs(current_transaction.install) do
            to_install[pkg.name] = true
        end

        -- Queue of packages to process (start with current uninstall list)
        local queue = {}
        for _, pkg in ipairs(current_transaction.uninstall) do
            table.insert(queue, pkg.name)
        end

        -- Process queue to find reverse dependencies recursively
        while #queue > 0 do
            local current_pkg_name = table.remove(queue, 1)

            -- Check if package is in install list (upgrade scenario)
            if not to_install[current_pkg_name] then
                -- Check all installed packages to find which ones depend on current_pkg_name
                for pkg_name, pkg_data in pairs(installed_packages) do
                    -- Skip if already in uninstall list
                    if not to_uninstall[pkg_name] then
                        local dependencies = pkg_data.dependencies or {}

                        -- Check if this package depends on the one being uninstalled
                        for _, dep in ipairs(dependencies) do
                            if dep == current_pkg_name then
                                -- This package depends on one being uninstalled, add it to uninstall list
                                table.insert(current_transaction.uninstall, {
                                    name = pkg_name,
                                    version = pkg_data.version,
                                    files = pkg_data.files,
                                    dependencies = pkg_data.dependencies,
                                    description = pkg_data.description,
                                    license = pkg_data.license,
                                    authors = pkg_data.authors,
                                    maintainers = pkg_data.maintainers,
                                    wanted = pkg_data.wanted
                                })
                                table.insert(queue, pkg_name)
                                to_uninstall[pkg_name] = true
                                break
                            end
                        end
                    end
                end
            end
        end

        save(transaction.INIT_FILE, current_transaction)
        return nil
    else
        return "transaction is not pending"
    end
end

--- Resolve all packages that will become orphans because of the uninstall list and add it to the transaction.
--- @return nil|string: Error message or nil if successful.
function transaction.auto_remove()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        local installed_packages = database.get_installed_packages()
        local to_uninstall = {} -- Track packages already in uninstall list

        -- Build set of packages already in uninstall list
        for _, pkg in ipairs(current_transaction.uninstall) do
            to_uninstall[pkg.name] = true
        end

        -- Build initial queue of candidate packages (unwanted packages)
        local queue = {}
        for pkg_name, pkg_data in pairs(installed_packages) do
            if not to_uninstall[pkg_name] and not pkg_data.wanted then
                table.insert(queue, pkg_name)
            end
        end

        -- Process queue recursively to find orphans
        while #queue > 0 do
            local pkg_name = table.remove(queue, 1)
            local pkg_data = installed_packages[pkg_name]

            -- Skip if already processed or if package was explicitly wanted
            if not to_uninstall[pkg_name] and pkg_data and not pkg_data.wanted then
                local is_required = false

                -- Check if any other installed package (that's not being uninstalled) requires this one
                for other_pkg_name, other_pkg_data in pairs(installed_packages) do
                    if other_pkg_name ~= pkg_name and not to_uninstall[other_pkg_name] then
                        local dependencies = other_pkg_data.dependencies or {}

                        for _, dep in ipairs(dependencies) do
                            if dep == pkg_name then
                                is_required = true
                                break
                            end
                        end

                        if is_required then
                            break
                        end
                    end
                end

                -- Also check if any package in the install list requires this one
                if not is_required then
                    for _, install_pkg in ipairs(current_transaction.install) do
                        local install_pkg_info, err = database.get_package(install_pkg.name)
                        if not install_pkg_info then
                            return "cannot get package info: " .. err
                        end
                        if not install_pkg_info.versions[install_pkg.version] then
                            return "version not found in database: " .. install_pkg.name .. " " .. install_pkg.version
                        end
                        local dependencies = install_pkg_info.versions[install_pkg.version].dependencies or {}

                        for _, dep in ipairs(dependencies) do
                            if dep == pkg_name then
                                is_required = true
                                break
                            end
                        end

                        if is_required then
                            break
                        end
                    end
                end

                -- If not required by anyone, add to uninstall list
                if not is_required then
                    table.insert(current_transaction.uninstall, {
                        name = pkg_name,
                        version = pkg_data.version,
                        files = pkg_data.files,
                        dependencies = pkg_data.dependencies,
                        description = pkg_data.description,
                        license = pkg_data.license,
                        authors = pkg_data.authors,
                        maintainers = pkg_data.maintainers,
                        wanted = pkg_data.wanted
                    })
                    to_uninstall[pkg_name] = true

                    -- Add dependencies of this package to queue as they might now be orphans too
                    local dependencies = pkg_data.dependencies or {}
                    for _, dep in ipairs(dependencies) do
                        if not to_uninstall[dep] and installed_packages[dep] and not installed_packages[dep].wanted then
                            table.insert(queue, dep)
                        end
                    end
                end
            end
        end

        save(transaction.INIT_FILE, current_transaction)
        return nil
    else
        return "transaction is not pending"
    end
end

--- Review the current transaction pending changes.
--- @return table | string, table | nil: Uninstall list and install list or error message and nil.
function transaction.get_pending_changes()
    if current_transaction then
        if current_transaction.status ~= transaction.TRANSACTION_STATUSES.PENDING then
            return "transaction is not pending"
        end

        local uninstall_list = {}
        local install_list = {}

        for _, pkg in ipairs(current_transaction.uninstall) do
            uninstall_list[pkg.name] = pkg.version
        end

        for _, pkg in ipairs(current_transaction.install) do
            install_list[pkg.name] = pkg.version
        end

        return uninstall_list, install_list
    else
        return "transaction is not pending"
    end
end

-- Load current transaction and progress
current_transaction = load(transaction.INIT_FILE)
current_progress = load(transaction.PROGRESS_FILE)

return transaction
