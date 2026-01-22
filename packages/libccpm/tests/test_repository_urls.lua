-- Standalone test script for repository URL conversion logic
-- This tests the URL conversion patterns without loading the full module

-- Simulate the extract_raw_url function logic
local function extract_raw_url(url)
    -- Add https:// if no scheme is present (but preserve other schemes like file://)
    if not url:match("^%w+://") then
        url = "https://" .. url
    end

    -- Remove trailing slashes
    url = url:gsub("/+$", "")

    -- GitHub: https://github.com/user/repo -> https://raw.githubusercontent.com/user/repo/refs/heads/dist/
    local user, repo = url:match("^https?://[www%.]*github%.com/([^/]+)/([^/]+)/?$")
    if user and repo then
        -- Remove .git suffix if present
        repo = repo:gsub("%.git$", "")
        return string.format("https://raw.githubusercontent.com/%s/%s/refs/heads/dist/", user, repo)
    end

    -- GitLab: https://gitlab.com/user/repo -> https://gitlab.com/user/repo/-/raw/dist/
    local gitlab_url = url:match("^(https?://[^/]*gitlab[^/]*/[^/]+/[^/]+)/?$")
    if gitlab_url then
        gitlab_url = gitlab_url:gsub("%.git$", "")
        return gitlab_url .. "/-/raw/dist/"
    end

    -- Bitbucket: https://bitbucket.org/user/repo -> https://bitbucket.org/user/repo/raw/dist/
    user, repo = url:match("^https?://[www%.]*bitbucket%.org/([^/]+)/([^/]+)/?$")
    if user and repo then
        repo = repo:gsub("%.git$", "")
        return string.format("https://bitbucket.org/%s/%s/raw/dist/", user, repo)
    end

    -- Codeberg: https://codeberg.org/user/repo -> https://codeberg.org/user/repo/raw/branch/dist/
    user, repo = url:match("^https?://[www%.]*codeberg%.org/([^/]+)/([^/]+)/?$")
    if user and repo then
        repo = repo:gsub("%.git$", "")
        return string.format("https://codeberg.org/%s/%s/raw/branch/dist/", user, repo)
    end

    -- SourceHut: https://git.sr.ht/~user/repo -> https://git.sr.ht/~user/repo/blob/dist/
    local srht_user, srht_repo = url:match("^https?://git%.sr%.ht/(~[^/]+)/([^/]+)/?$")
    if srht_user and srht_repo then
        srht_repo = srht_repo:gsub("%.git$", "")
        return string.format("https://git.sr.ht/%s/%s/blob/dist/", srht_user, srht_repo)
    end

    -- If no pattern matches, assume it's already a raw URL
    -- Ensure it ends with a slash for consistency
    if not url:match("/$") then
        url = url .. "/"
    end

    return url
end

-- Test cases
local tests = {
    -- GitHub tests
    {
        input = "https://github.com/user/repo",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub"
    },
    {
        input = "https://www.github.com/user/repo",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub (www)"
    },
    {
        input = "http://github.com/user/repo",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub (http)"
    },
    {
        input = "https://github.com/user/repo.git",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub (.git)"
    },
    {
        input = "https://github.com/user/repo/",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub (trailing slash)"
    },
    {
        input = "https://github.com/deleranax/ccpm",
        expected = "https://raw.githubusercontent.com/deleranax/ccpm/refs/heads/dist/",
        service = "GitHub (example from spec)"
    },
    {
        input = "github.com/user/repo",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub (no scheme)"
    },
    {
        input = "www.github.com/user/repo",
        expected = "https://raw.githubusercontent.com/user/repo/refs/heads/dist/",
        service = "GitHub (no scheme with www)"
    },

    -- GitLab tests
    {
        input = "https://gitlab.com/user/repo",
        expected = "https://gitlab.com/user/repo/-/raw/dist/",
        service = "GitLab"
    },
    {
        input = "https://gitlab.com/user/repo.git",
        expected = "https://gitlab.com/user/repo/-/raw/dist/",
        service = "GitLab (.git)"
    },
    {
        input = "https://gitlab.example.com/user/repo",
        expected = "https://gitlab.example.com/user/repo/-/raw/dist/",
        service = "GitLab (self-hosted)"
    },
    {
        input = "https://gitlab.com/user/repo/",
        expected = "https://gitlab.com/user/repo/-/raw/dist/",
        service = "GitLab (trailing slash)"
    },
    {
        input = "gitlab.com/user/repo",
        expected = "https://gitlab.com/user/repo/-/raw/dist/",
        service = "GitLab (no scheme)"
    },

    -- Bitbucket tests
    {
        input = "https://bitbucket.org/user/repo",
        expected = "https://bitbucket.org/user/repo/raw/dist/",
        service = "Bitbucket"
    },
    {
        input = "https://www.bitbucket.org/user/repo",
        expected = "https://bitbucket.org/user/repo/raw/dist/",
        service = "Bitbucket (www)"
    },
    {
        input = "https://bitbucket.org/user/repo.git",
        expected = "https://bitbucket.org/user/repo/raw/dist/",
        service = "Bitbucket (.git)"
    },
    {
        input = "bitbucket.org/user/repo",
        expected = "https://bitbucket.org/user/repo/raw/dist/",
        service = "Bitbucket (no scheme)"
    },

    -- Codeberg tests
    {
        input = "https://codeberg.org/user/repo",
        expected = "https://codeberg.org/user/repo/raw/branch/dist/",
        service = "Codeberg"
    },
    {
        input = "https://codeberg.org/user/repo.git",
        expected = "https://codeberg.org/user/repo/raw/branch/dist/",
        service = "Codeberg (.git)"
    },
    {
        input = "https://www.codeberg.org/user/repo",
        expected = "https://codeberg.org/user/repo/raw/branch/dist/",
        service = "Codeberg (www)"
    },
    {
        input = "codeberg.org/user/repo",
        expected = "https://codeberg.org/user/repo/raw/branch/dist/",
        service = "Codeberg (no scheme)"
    },

    -- SourceHut tests
    {
        input = "https://git.sr.ht/~user/repo",
        expected = "https://git.sr.ht/~user/repo/blob/dist/",
        service = "SourceHut"
    },
    {
        input = "https://git.sr.ht/~user/repo.git",
        expected = "https://git.sr.ht/~user/repo/blob/dist/",
        service = "SourceHut (.git)"
    },
    {
        input = "http://git.sr.ht/~user/repo",
        expected = "https://git.sr.ht/~user/repo/blob/dist/",
        service = "SourceHut (http)"
    },
    {
        input = "git.sr.ht/~user/repo",
        expected = "https://git.sr.ht/~user/repo/blob/dist/",
        service = "SourceHut (no scheme)"
    },

    -- Fallback tests (unknown/raw URLs)
    {
        input = "https://example.com/raw/files",
        expected = "https://example.com/raw/files/",
        service = "Unknown (fallback)"
    },
    {
        input = "https://example.com/raw/files/",
        expected = "https://example.com/raw/files/",
        service = "Unknown (fallback with slash)"
    },
    {
        input = "https://custom-git.company.com/repos/project",
        expected = "https://custom-git.company.com/repos/project/",
        service = "Unknown (custom URL)"
    },
    {
        input = "file:///path/to/local/repo",
        expected = "file:///path/to/local/repo/",
        service = "File scheme (preserved)"
    },
    {
        input = "ftp://example.com/repo",
        expected = "ftp://example.com/repo/",
        service = "FTP scheme (preserved)"
    },
}

-- Helper function to check for double slashes (except in protocol)
local function has_double_slashes(url)
    -- Remove the protocol part (including the ://)
    local without_protocol = url:gsub("^%w+://", "")
    -- For file:// URLs, also remove the leading slash (file:/// is valid)
    if url:match("^file://") then
        without_protocol = without_protocol:gsub("^/", "")
    end
    -- Check if there are any double slashes remaining
    return without_protocol:match("//") ~= nil
end

print("Testing repository URL conversion...")
print(string.rep("=", 80))

local passed = 0
local failed = 0
local double_slash_errors = 0

for i, test in ipairs(tests) do
    local result = extract_raw_url(test.input)
    local matches = result == test.expected
    local has_dbl_slash = has_double_slashes(result)

    local status = "PASS"
    if not matches then
        status = "FAIL"
        failed = failed + 1
    elseif has_dbl_slash then
        status = "WARN"
        double_slash_errors = double_slash_errors + 1
    else
        passed = passed + 1
    end

    if status == "PASS" then
        print(string.format("[%s] %s", status, test.service))
    else
        print(string.format("[%s] %s", status, test.service))
        print(string.format("  Input:    %s", test.input))
        print(string.format("  Expected: %s", test.expected))
        print(string.format("  Got:      %s", result))
        if has_dbl_slash then
            print("  WARNING: Result contains double slashes!")
        end
        print()
    end
end

print(string.rep("=", 80))
print(string.format("Results: %d passed, %d failed, %d double-slash warnings",
    passed, failed, double_slash_errors))
print(string.format("Total tests: %d", #tests))

if failed == 0 and double_slash_errors == 0 then
    print("\n✓ All tests passed! No double slashes detected.")
    os.exit(0)
else
    print("\n✗ Some tests failed or have warnings!")
    os.exit(1)
end
