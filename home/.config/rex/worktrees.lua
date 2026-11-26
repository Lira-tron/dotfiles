local fs = require("files")
local artifacts = require("artifacts")
local M = {}

function M.checkouts(repo)
  local output = fs.run({ "git", "-C", repo, "worktree", "list", "--porcelain", "-z" })
  local records, record = {}, {}
  for field in (output .. "\0"):gmatch("(.-)%z") do
    if field == "" then
      if record.worktree then records[#records + 1] = record end
      record = {}
    else
      local key, value = field:match("^(%S+)%s(.*)$")
      record[key or field] = value or ""
    end
  end
  return records
end

function M.token(selected)
  return "tree:" .. rex.json.encode(selected):gsub(".", function(byte) return ("%02x"):format(byte:byte()) end)
end

function M.decode(value)
  local hex = value:match("^tree:([0-9a-f]+)$")
  if not hex or #hex % 2 ~= 0 then error("Invalid worktree selection.", 0) end
  local selected = rex.json.decode((hex:gsub("..", function(pair) return string.char(tonumber(pair, 16)) end)))
  if type(selected.parent) ~= "string" or type(selected.path) ~= "string" then
    error("Invalid worktree selection.", 0)
  end
  return selected
end

function M.repositories(root)
  local command = { "fd", "--hidden", "--no-ignore", "--prune", "--absolute-path", "--print0" }
  for _, directory in ipairs({ "build", "env", "node_modules", ".ai", ".brazil", "brazil-pkg-cache", ".cache", ".venv" }) do
    command[#command + 1], command[#command + 2] = "--exclude", directory
  end
  command[#command + 1], command[#command + 2], command[#command + 3] = "--glob", ".git", root
  local repos = {}
  for marker in fs.run(command):gmatch("([^%z]+)%z") do repos[#repos + 1] = fs.parent(marker) end
  table.sort(repos)
  return repos
end

function M.workspace(root)
  while root ~= "/" do
    if fs.read(root .. "/packageInfo") then
      local owner = fs.parent(fs.parent(root))
      if fs.name(fs.parent(root)) == "worktrees" and fs.read(owner .. "/packageInfo") then return owner end
      return root
    end
    root = fs.parent(root)
  end
end

function M.rows(root)
  local entries, seen, workspaces = {}, {}, {}
  local repos, present = M.repositories(root), {}
  for _, repo in ipairs(repos) do present[repo] = true end
  for _, repo in ipairs(repos) do
    if not seen[repo] then
      local ok, records = pcall(M.checkouts, repo)
      if not ok then
        io.stderr:write(tostring(records) .. "\n")
      else
        local parent = records[1].worktree
        for _, record in ipairs(records) do
          local path = record.worktree
          seen[path] = true
          if path ~= parent and not record.bare and not record.prunable
            and (present[path] or fs.test("-d", path)) then
            local workspace, label = fs.parent(fs.parent(path))
            if fs.name(fs.parent(path)) == "src" and fs.read(workspace .. "/packageInfo") then
              if not workspaces[workspace] then
                workspaces[workspace] = true
                label = fs.name(fs.parent(fs.parent(workspace))) .. " · " .. fs.name(workspace)
              end
            else
              local branch = record.branch and record.branch:gsub("^refs/heads/", "")
              label = fs.name(parent) .. " · " .. (branch or "detached " .. (record.HEAD or ""):sub(1, 7))
            end
            if label then
              entries[#entries + 1] = "[tree] " .. label:gsub("[\t\n]", " "):gsub("'", "’")
                .. "\t" .. M.token({ parent = parent, path = path })
            end
          end
        end
      end
    end
  end
  return entries
end

function M.current(root)
  root = root or fs.trim(fs.run({ "pwd", "-P" }))
  root = fs.resolve(root)
  local workspace = M.workspace(root)
  if workspace then return M.rows(workspace) end
  while root ~= "/" do
    local entries = M.rows(root)
    if #entries > 0 then return entries end
    root = fs.parent(root)
  end
  return {}
end

function M.packages(workspace)
  local packages = {}
  for _, path in ipairs(fs.entries(workspace .. "/src")) do
    if fs.test("-e", path .. "/.git") then packages[#packages + 1] = path end
  end
  return packages
end

function M.current_parent(root)
  local result = fs.result({ "brazil-context", "package", "root" }, root)
  local repo = result.ok and fs.trim(result.stdout) or nil
  if not repo or not fs.test("-e", repo .. "/.git") then
    local workspace = M.workspace(fs.resolve(root))
    if not workspace then error(result.stderr, 0) end
    local packages = M.packages(workspace)
    if #packages == 0 then error("No Git packages in Brazil workspace: " .. workspace, 0) end
    repo = packages[1]
    for _, package in ipairs(packages) do
      if fs.name(package) == fs.name(workspace) then repo = package end
    end
  end
  return M.checkouts(repo)[1].worktree
end

function M.brazil_workspace(repo)
  if not fs.result({ "/bin/sh", "-c", "command -v brazil-context" }).ok then return nil end
  local result = fs.result({ "brazil-context", "package", "root" }, repo)
  if not result.ok or fs.resolve(fs.trim(result.stdout)) ~= repo then return nil end
  return fs.resolve(fs.trim(fs.run({ "brazil-context", "workspace", "root" }, repo)))
end

function M.create(selected, name)
  local parent = fs.resolve(fs.trim(fs.run({ "brazil-context", "package", "root" }, selected.parent)))
  local workspace = fs.resolve(fs.trim(fs.run({ "brazil-context", "workspace", "root" }, parent)))
  local base = fs.trim(fs.run({ "git", "-C", parent, "rev-parse", "HEAD" }))
  local branch = fs.trim(fs.run({ "git", "-C", parent, "branch", "--show-current" }))
  io.stderr:write("Repository: " .. parent .. "\nBase: " .. branch .. " @ " .. base:sub(1, 12)
    .. "\nBrazil parent: " .. workspace .. "\nAll parent packages use their current committed HEADs.\n"
    .. "Uncommitted edits stay in the original checkout.\n")
  if name == nil then name = fs.prompt("New worktree name (blank cancels): ") end
  if name == "" then return nil end
  local created = os.date("!%y-%m-%d")
  local feature = artifacts.feature(name, created)
  fs.run({ "git", "check-ref-format", "--branch", name })
  for _, package in ipairs(M.packages(workspace)) do
    if fs.result({ "git", "-C", package, "show-ref", "--verify", "--quiet", "refs/heads/" .. name }).ok then
      error("Branch " .. name .. " already exists in " .. fs.name(package) .. "; reuse it from the picker.", 0)
    end
  end
  fs.run({ "brazil", "worktree", "create", "--workspace", workspace, "--name", name, "--inheritAll" })
  local target = workspace .. "/worktrees/" .. name
  for _, package in ipairs(M.packages(target)) do artifacts.initialize(package, feature, created) end
  return { parent = parent, path = target .. "/src/" .. fs.name(parent) }
end

function M.delete(selected, force, confirm)
  local parent, path = fs.resolve(selected.parent), fs.resolve(selected.path)
  if path == parent then error("The primary checkout cannot be deleted from this picker.", 0) end
  local owner, workspace = M.brazil_workspace(parent), M.brazil_workspace(path)
  if (owner == nil) ~= (workspace == nil) then
    error("Cannot resolve the Brazil worktree and its parent; inspect them before cleanup.", 0)
  end
  local target = workspace or path
  local repos = workspace and M.repositories(workspace) or { path }
  for _, repo in ipairs(repos) do artifacts.check_deletion(repo, target) end
  local command, scope
  if workspace then
    if workspace ~= owner .. "/worktrees/" .. fs.name(workspace) then
      error("This is not a native Brazil task worktree; inspect it before cleanup.", 0)
    end
    for _, repo in ipairs(repos) do
      if fs.parent(repo) ~= workspace .. "/src" then
        error("Remove the nested Git checkouts before deleting this Brazil worktree.", 0)
      end
    end
    command = { "brazil", "worktree", "delete", "--workspace", owner, "--name", fs.name(workspace) }
    scope = "all package checkouts, branches (including unmerged branches), build outputs, and local artifact links"
  else
    command = { "git", "-C", parent, "worktree", "remove", path }
    scope = "this checkout and local artifact links; its Git branch and external artifacts are retained"
  end
  local dirty = {}
  for _, repo in ipairs(repos) do
    if fs.run({ "git", "-C", repo, "status", "--porcelain" }) ~= "" then dirty[#dirty + 1] = repo end
  end
  if workspace or force or #dirty > 0 then command[#command + 1] = "--force" end
  local message = "Delete " .. target .. "\nThis removes " .. scope .. ". Preserve needed work first."
  if #dirty > 0 then message = message .. "\nUncommitted changes will be discarded in: " .. table.concat(dirty, ", ") end
  if not confirm(message) then return false end
  -- find does not follow symlinks; shared caches outside the worktree keep their permissions.
  fs.run({ "find", target, "-type", "d", "!", "-perm", "-u+w", "-exec", "chmod", "u+w", "{}", "+" }, parent)
  fs.run(command, parent)
  return true
end

return M
