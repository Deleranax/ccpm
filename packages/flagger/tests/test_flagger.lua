-- Test suite for flagger library
-- Tests get, set, and make_flag functions

local flagger = require("source.lib.flagger")

-- Test helper function
local function assert_equal(actual, expected, test_name)
    if actual == expected then
        print(string.format("  [PASS] %s", test_name))
        return true
    else
        print(string.format("  [FAIL] %s", test_name))
        print(string.format("    Expected: %s", tostring(expected)))
        print(string.format("    Got:      %s", tostring(actual)))
        return false
    end
end

local function run_test_group(name, test_fn)
    print()
    print(string.rep("=", 80))
    print(name)
    print(string.rep("=", 80))
    return test_fn()
end

local total_passed = 0
local total_failed = 0

-- Test 1: flagger.get function
local function test_get()
    local passed = 0
    local failed = 0

    -- Test case 1: Get component at position 0 (base 3)
    -- Value 7 in base 3 is 21 (2*3 + 1), so position 0 should be 1
    if assert_equal(flagger.get(7, 0, 3), 1, "get(7, 0, 3) = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 2: Get component at position 1 (base 3)
    -- Value 7 in base 3 is 21, so position 1 should be 2
    if assert_equal(flagger.get(7, 1, 3), 2, "get(7, 1, 3) = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 3: Get component at position 2 (base 3)
    -- Value 7 doesn't have a component at position 2
    if assert_equal(flagger.get(7, 2, 3), 0, "get(7, 2, 3) = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 4: Get component at position 0 from value 0
    if assert_equal(flagger.get(0, 0, 3), 0, "get(0, 0, 3) = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 5: Get component from larger value (base 3)
    -- Value 27 in base 3 is 1000, so position 3 should be 1
    if assert_equal(flagger.get(27, 3, 3), 1, "get(27, 3, 3) = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 6: Get with base 10
    -- Value 123, position 0 (ones place) = 3
    if assert_equal(flagger.get(123, 0, 10), 3, "get(123, 0, 10) = 3") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 7: Get with base 10
    -- Value 123, position 1 (tens place) = 2
    if assert_equal(flagger.get(123, 1, 10), 2, "get(123, 1, 10) = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 8: Get with base 10
    -- Value 123, position 2 (hundreds place) = 1
    if assert_equal(flagger.get(123, 2, 10), 1, "get(123, 2, 10) = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 9: Binary (base 2)
    -- Value 5 (binary 101), position 0 = 1
    if assert_equal(flagger.get(5, 0, 2), 1, "get(5, 0, 2) = 1 (binary)") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 10: Binary (base 2)
    -- Value 5 (binary 101), position 1 = 0
    if assert_equal(flagger.get(5, 1, 2), 0, "get(5, 1, 2) = 0 (binary)") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 11: Binary (base 2)
    -- Value 5 (binary 101), position 2 = 1
    if assert_equal(flagger.get(5, 2, 2), 1, "get(5, 2, 2) = 1 (binary)") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    return passed, failed
end

-- Test 2: flagger.set function
local function test_set()
    local passed = 0
    local failed = 0

    -- Test case 1: Set position 0 to 1 (base 3)
    if assert_equal(flagger.set(0, 0, 1, 3), 1, "set(0, 0, 1, 3) = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 2: Set position 1 to 1 (base 3)
    if assert_equal(flagger.set(0, 1, 1, 3), 3, "set(0, 1, 1, 3) = 3") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 3: Set position 1 to 2 (base 3)
    if assert_equal(flagger.set(0, 1, 2, 3), 6, "set(0, 1, 2, 3) = 6") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 4: Set multiple positions (combine)
    local value = 0
    value = flagger.set(value, 0, 1, 3) -- set position 0 to 1
    value = flagger.set(value, 1, 2, 3) -- set position 1 to 2
    if assert_equal(value, 7, "set(set(0, 0, 1, 3), 1, 2, 3) = 7") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 5: Override existing value
    -- Start with 7 (position 0 = 1, position 1 = 2)
    -- Set position 0 to 2
    if assert_equal(flagger.set(7, 0, 2, 3), 8, "set(7, 0, 2, 3) = 8") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 6: Override existing value
    -- Start with 7 (position 0 = 1, position 1 = 2)
    -- Set position 1 to 1
    if assert_equal(flagger.set(7, 1, 1, 3), 4, "set(7, 1, 1, 3) = 4") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 7: Set to 0 (clear a position)
    if assert_equal(flagger.set(7, 0, 0, 3), 6, "set(7, 0, 0, 3) = 6") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 8: Set with base 10
    if assert_equal(flagger.set(0, 1, 5, 10), 50, "set(0, 1, 5, 10) = 50") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 9: Binary set
    if assert_equal(flagger.set(0, 2, 1, 2), 4, "set(0, 2, 1, 2) = 4 (binary)") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 10: Complex binary operations
    local bin_value = 0
    bin_value = flagger.set(bin_value, 0, 1, 2) -- bit 0
    bin_value = flagger.set(bin_value, 2, 1, 2) -- bit 2
    -- Should be binary 101 = decimal 5
    if assert_equal(bin_value, 5, "binary flags: set bits 0 and 2 = 5") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    return passed, failed
end

-- Test 3: flagger.make_flag function
local function test_make_flag()
    local passed = 0
    local failed = 0

    -- Test case 1: Basic flag creation
    local flags = flagger.make_flag({
        { "LEFT",  "CENTER", "RIGHT" },
        { "START", "MIDDLE", "END" }
    })

    if assert_equal(flags.LEFT, 0, "make_flag: LEFT = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags.CENTER, 1, "make_flag: CENTER = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags.RIGHT, 2, "make_flag: RIGHT = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags.START, 3, "make_flag: START = 3") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags.MIDDLE, 6, "make_flag: MIDDLE = 6") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags.END, 9, "make_flag: END = 9") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 2: Combining flags
    local combined = flags.CENTER + flags.MIDDLE
    if assert_equal(combined, 7, "CENTER + MIDDLE = 7") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 3: Verify combined value has correct components
    if assert_equal(flagger.get(combined, 0, 3), 1, "combined value position 0 = 1 (CENTER)") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flagger.get(combined, 1, 3), 2, "combined value position 1 = 2 (MIDDLE)") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 4: Different sized groups
    local flags2 = flagger.make_flag({
        { "A", "B" },
        { "X", "Y", "Z" }
    })

    if assert_equal(flags2.A, 0, "make_flag (different sizes): A = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags2.B, 1, "make_flag (different sizes): B = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Base should be 3 (max of group sizes)
    if assert_equal(flags2.X, 3, "make_flag (different sizes): X = 3") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags2.Y, 6, "make_flag (different sizes): Y = 6") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags2.Z, 9, "make_flag (different sizes): Z = 9") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 5: Single group
    local flags3 = flagger.make_flag({
        { "ONE", "TWO", "THREE", "FOUR" }
    })

    if assert_equal(flags3.ONE, 0, "make_flag (single group): ONE = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags3.TWO, 1, "make_flag (single group): TWO = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags3.THREE, 2, "make_flag (single group): THREE = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags3.FOUR, 3, "make_flag (single group): FOUR = 3") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 6: Three levels
    local flags4 = flagger.make_flag({
        { "SMALL", "MEDIUM", "LARGE" },
        { "TOP",   "BOTTOM" },
        { "RED",   "GREEN",  "BLUE" }
    })

    if assert_equal(flags4.SMALL, 0, "make_flag (3 levels): SMALL = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags4.MEDIUM, 1, "make_flag (3 levels): MEDIUM = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags4.TOP, 3, "make_flag (3 levels): TOP = 3") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags4.BOTTOM, 6, "make_flag (3 levels): BOTTOM = 6") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Base is 3, so level 2 multiplier is 3^2 = 9
    if assert_equal(flags4.RED, 9, "make_flag (3 levels): RED = 9") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags4.GREEN, 18, "make_flag (3 levels): GREEN = 18") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flags4.BLUE, 27, "make_flag (3 levels): BLUE = 27") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test combining three levels
    local triple_combined = flags4.MEDIUM + flags4.TOP + flags4.RED
    if assert_equal(triple_combined, 13, "MEDIUM + TOP + RED = 13") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    return passed, failed
end

-- Test 4: Round-trip tests (get/set consistency)
local function test_roundtrip()
    local passed = 0
    local failed = 0

    -- Test case 1: Set and get back the same value
    local value = flagger.set(0, 1, 2, 3)
    local retrieved = flagger.get(value, 1, 3)
    if assert_equal(retrieved, 2, "round-trip: set(0, 1, 2, 3) then get(..., 1, 3) = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 2: Multiple positions
    local multi = 0
    multi = flagger.set(multi, 0, 2, 3)
    multi = flagger.set(multi, 1, 1, 3)
    multi = flagger.set(multi, 2, 2, 3)

    if assert_equal(flagger.get(multi, 0, 3), 2, "multi-position get(0) = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flagger.get(multi, 1, 3), 1, "multi-position get(1) = 1") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flagger.get(multi, 2, 3), 2, "multi-position get(2) = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Test case 3: Update existing position
    local updated = flagger.set(multi, 1, 0, 3) -- Change position 1 from 1 to 0
    if assert_equal(flagger.get(updated, 1, 3), 0, "after update: get(1) = 0") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    -- Verify other positions unchanged
    if assert_equal(flagger.get(updated, 0, 3), 2, "after update: get(0) still = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    if assert_equal(flagger.get(updated, 2, 3), 2, "after update: get(2) still = 2") then
        passed = passed + 1
    else
        failed = failed + 1
    end

    return passed, failed
end

-- Run all tests
print("Flagger Library Test Suite")
print(string.rep("=", 80))

local p, f = run_test_group("Test Group 1: flagger.get", test_get)
total_passed = total_passed + p
total_failed = total_failed + f

p, f = run_test_group("Test Group 2: flagger.set", test_set)
total_passed = total_passed + p
total_failed = total_failed + f

p, f = run_test_group("Test Group 3: flagger.make_flag", test_make_flag)
total_passed = total_passed + p
total_failed = total_failed + f

p, f = run_test_group("Test Group 4: Round-trip tests", test_roundtrip)
total_passed = total_passed + p
total_failed = total_failed + f

-- Summary
print()
print(string.rep("=", 80))
print("SUMMARY")
print(string.rep("=", 80))
print(string.format("Total tests run: %d", total_passed + total_failed))
print(string.format("Passed:          %d", total_passed))
print(string.format("Failed:          %d", total_failed))
print(string.rep("=", 80))

if total_failed == 0 then
    print("\n✓ All tests passed!")
    os.exit(0)
else
    print(string.format("\n✗ %d test(s) failed!", total_failed))
    os.exit(1)
end
