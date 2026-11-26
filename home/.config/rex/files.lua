local M = {}
local user_path

function M.env()
  if not user_path then
    local result = rex.exec({ "/bin/zsh", "-c", "print -r -- $PATH" })
    user_path = (result and result.ok and result.stdout:gsub("%s+$", "") or os.getenv("PATH"))
      .. ":" .. os.getenv("HOME")
      .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
  end
  return { PATH = user_path }
end

function M.result(argv, cwd)
  local result, err = rex.exec(argv, { cwd = cwd, env = M.env() })
  if not result then error(err, 0) end
  return result
end

function M.run(argv, cwd)
  local result = M.result(argv, cwd)
  if not result.ok then
    local message = result.stderr .. result.stdout
    error(message ~= "" and message or table.concat(argv, " ") .. " failed", 0)
  end
  return result.stdout
end

function M.trim(text)
  return text:match("^%s*(.-)%s*$")
end

function M.parent(path)
  local parent = path:gsub("/+$", ""):match("^(.*)/[^/]+$")
  return parent and parent ~= "" and parent or "/"
end

function M.name(path)
  return path:gsub("/+$", ""):match("([^/]+)$")
end

function M.under(path, root)
  return path == root or path:sub(1, #root + 1) == root .. "/" or root == "/"
end

function M.test(flag, path)
  local result = M.result({ "/bin/test", flag, path })
  if result.code ~= 0 and result.code ~= 1 then error(result.stderr, 0) end
  return result.ok
end

function M.read(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local contents = file:read("*a")
  file:close()
  return contents
end

function M.resolve(path, depth)
  depth = depth or 0
  if depth > 40 then error("Too many symbolic links: " .. path, 0) end
  if path:sub(1, 1) ~= "/" then path = M.trim(M.run({ "pwd", "-P" })) .. "/" .. path end
  -- cd -P and readlink without GNU flags also work on macOS.
  local result = M.run({ "/bin/sh", "-c", [[
if [ -d "$1" ]; then printf 'D'; cd -P "$1" && pwd -P
elif [ -L "$1" ]; then printf 'L'; readlink "$1"
else printf 'M'; fi]], "rex-path", path })
  local kind, value = result:sub(1, 1), result:sub(2):gsub("\n$", "")
  if kind == "D" then return value end
  if kind == "L" then
    return M.resolve(value:sub(1, 1) == "/" and value or M.parent(path) .. "/" .. value, depth + 1)
  end
  local parent = M.resolve(M.parent(path), depth)
  local name = M.name(path)
  if name == "." then return parent end
  if name == ".." then return M.parent(parent) end
  return (parent == "/" and "" or parent) .. "/" .. name
end

function M.entries(path)
  local output = M.run({ "find", path, "-mindepth", "1", "-maxdepth", "1", "-print0" })
  local entries = {}
  for entry in output:gmatch("([^%z]+)%z") do entries[#entries + 1] = entry end
  table.sort(entries)
  return entries
end

function M.prompt(message)
  io.stderr:write(message)
  io.stderr:flush()
  local terminal = assert(io.open("/dev/tty", "r"))
  local answer = terminal:read("*l") or ""
  terminal:close()
  return M.trim(answer)
end

return M
