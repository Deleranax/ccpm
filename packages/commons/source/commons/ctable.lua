local ctable = {}

--- Copy a table recursively.
--- @param tab table: The table to copy.
--- @return table: A deep copy of the table.
function ctable.copy(tab)
    local new_table = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
            v = ctable.copy(v)
        end

        new_table[k] = v
    end
    return new_table
end

--- Collect values from an iterator into a table.
--- @param iter function: An iterator function.
--- @return table: A table containing the collected values.
function ctable.collect(iter)
    local result = {}
    for value in iter do
        table.insert(result, value)
    end
    return result
end

return ctable
