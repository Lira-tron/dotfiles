-- Runtime tests: rex do ./tests/test_<module>.lua from the Rex config directory.
package.path = "./?.lua;" .. package.path
local fs = require("files")
local T = { fs = fs }
local patches, temporary = {}, {}

function T.patch(object, key, value)
  patches[#patches + 1] = { object, key, object[key] }
  object[key] = value
end

function T.temp()
  local path = fs.trim(fs.run({ "mktemp", "-d", "/tmp/rex-lua-test.XXXXXXXX" }))
  temporary[#temporary + 1] = path
  return path
end

function T.write(path, content)
  fs.run({ "mkdir", "-p", fs.parent(path) })
  local file = assert(io.open(path, "w"))
  file:write(content or "")
  file:close()
end

function T.raises(pattern, fn)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(pattern, 1, true), tostring(err))
end

function T.test(name, fn)
  local ok, err = pcall(fn)
  for i = #patches, 1, -1 do
    local patch = patches[i]
    patch[1][patch[2]] = patch[3]
  end
  patches = {}
  for _, path in ipairs(temporary) do
    fs.run({ "chmod", "-R", "u+w", path })
    fs.run({ "rm", "-rf", path })
  end
  temporary = {}
  assert(ok, name .. ": " .. tostring(err))
  print("PASS: " .. name)
end

return T
