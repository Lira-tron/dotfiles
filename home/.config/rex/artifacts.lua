local fs = require("files")
local M = {}

function M.feature(name, created)
  if name:find("[/\\]") or name:sub(1, 1) == "-" then
    error("Use a worktree name without slashes or a leading dash.", 0)
  end
  local suffix = "-" .. created:sub(4, 5) .. created:sub(7, 8)
  local feature = name:sub(-#suffix) == suffix and name:sub(1, -#suffix - 1) or name
  if not feature:match("^[a-z0-9][a-z0-9%-]*$") or feature:find("%-%-") or feature:sub(-1) == "-" then
    error("Use a lowercase kebab-case feature name for artifact storage.", 0)
  end
  return feature
end

function M.initialize(checkout, feature, created)
  local config = fs.read(checkout .. "/Config") or ""
  local package_name = ("\n" .. config):match("\n%s*package%.([%w_.%-]+)%s*=") or fs.name(checkout)
  if not package_name:match("^[A-Za-z0-9][A-Za-z0-9._%-]*$") then
    error("Invalid artifact package: " .. package_name, 0)
  end
  local root = fs.resolve(os.getenv("HOME") .. "/knowledge/ai/artifacts")
  local target = root .. "/" .. package_name .. "/" .. created .. "-" .. feature
  if fs.resolve(target) ~= target then
    error("Artifact package/feature directories must not redirect through symlinks: " .. target, 0)
  end
  local link = checkout .. "/.ai"
  if fs.test("-L", link) then
    if fs.resolve(link) ~= target or not fs.test("-d", target) then
      error("Preserve the existing artifact selection before creating: " .. link, 0)
    end
    return target
  end
  if fs.test("-e", link) then
    error("Preserve and migrate the existing " .. link .. " before creating a feature link.", 0)
  end
  fs.run({ "/bin/sh", "-c", 'umask 077; mkdir -p "$1" "$2" "$3"', "rex-artifacts",
    root, fs.parent(target), target })
  fs.run({ "ln", "-s", target, link })
  return target
end

function M.check_deletion(repo, target)
  local path = repo .. "/.ai"
  if fs.test("-L", path) then
    if fs.under(fs.resolve(path), target) then
      error("Move artifact storage outside the worktree before deleting: " .. path, 0)
    end
  elseif fs.test("-e", path) and (not fs.test("-d", path) or #fs.entries(path) > 0) then
    error("Preserve and migrate " .. path .. " before deleting this worktree.", 0)
  end
end

return M
