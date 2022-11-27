-- bit.numberlua - Bitwise operations implemented in pure Lua as numbers,
-- with Lua 5.2 'bit32' and (LuaJIT) LuaBitOp 'bit' compatibility interfaces.

-- original source https://github.com/chenxuuu/lua-online/blob/master/lua/bit.lua
-- secondary source Community Leveling Guides, https://www.esoui.com/downloads/info2062-CommunityLevelingGuides.html

local bitwise = { _TYPE = 'module', _NAME = 'bit.numberlua', _VERSION = '0.3.1.20120131' }
_G["MasterMerchant_Writs_Bitwise"] = bitwise

local floor = math.floor

local MOD = 2 ^ 32
local MODM = MOD - 1

local function memoize(f)
  local mt = {}
  local t = setmetatable({}, mt)
  function mt:__index(k)
    local v = f(k);
    t[k] = v
    return v
  end
  return t
end

local function make_bitop_uncached(t, m)
  local function bitop(a, b)
    local res, p = 0, 1
    while a ~= 0 and b ~= 0 do
      local am, bm = a % m, b % m
      res = res + t[am][bm] * p
      a = (a - am) / m
      b = (b - bm) / m
      p = p * m
    end
    res = res + (a + b) * p
    return res
  end
  return bitop
end

local function make_bitop(t)
  local op1 = make_bitop_uncached(t, 2 ^ 1)
  local op2 = memoize(function(a)
    return memoize(function(b)
      return op1(a, b)
    end)
  end)
  return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end

function bitwise.tobit(x)
  return x % 2 ^ 32
end

bitwise.bxor = make_bitop { [0] = { [0] = 0, [1] = 1 }, [1] = { [0] = 1, [1] = 0 }, n = 4 }
local bxor = bitwise.bxor

function bitwise.bnot(a) return MODM - a end
local bnot = bitwise.bnot

function bitwise.band(a, b) return ((a + b) - bxor(a, b)) / 2 end
local band = bitwise.band

function bitwise.bor(a, b) return MODM - band(MODM - a, MODM - b) end
local bor = bitwise.bor

local lshift, rshift

function bitwise.rshift(a, disp)
  if disp < 0 then return lshift(a, -disp) end
  return floor(a % 2 ^ 32 / 2 ^ disp)
end
rshift = bitwise.rshift

function bitwise.lshift(a, disp)
  if disp < 0 then return rshift(a, -disp) end
  return (a * 2 ^ disp) % 2 ^ 32
end
lshift = bitwise.lshift

function bitwise.tohex(x, n)
  n = n or 8
  local up
  if n <= 0 then
    if n == 0 then return '' end
    up = true
    n = -n
  end
  x = band(x, 16 ^ n - 1)
  return ('%0' .. n .. (up and 'X' or 'x')):format(x)
end
local tohex = bitwise.tohex

function bitwise.extract(n, field, width)
  width = width or 1
  return band(rshift(n, field), 2 ^ width - 1)
end
local extract = bitwise.extract

function bitwise.replace(n, v, field, width)
  width = width or 1
  local mask1 = 2 ^ width - 1
  v = band(v, mask1)
  local mask = bnot(lshift(mask1, field))
  return band(n, mask) + lshift(v, field)
end
local replace = bitwise.replace

function bitwise.bswap(x)
  local a = band(x, 0xff);
  x = rshift(x, 8)
  local b = band(x, 0xff);
  x = rshift(x, 8)
  local c = band(x, 0xff);
  x = rshift(x, 8)
  local d = band(x, 0xff)
  return lshift(lshift(lshift(a, 8) + b, 8) + c, 8) + d
end
local bswap = bitwise.bswap

function bitwise.rrotate(x, disp)
  disp = disp % 32
  local low = band(x, 2 ^ disp - 1)
  return rshift(x, disp) + lshift(low, 32 - disp)
end
local rrotate = bitwise.rrotate

function bitwise.lrotate(x, disp)
  return rrotate(x, -disp)
end
local lrotate = bitwise.lrotate

bitwise.rol = bitwise.lrotate
bitwise.ror = bitwise.rrotate

function bitwise.arshift(x, disp)
  local z = rshift(x, disp)
  if x >= 0x80000000 then z = z + lshift(2 ^ disp - 1, 32 - disp) end
  return z
end
local arshift = bitwise.arshift

function bitwise.btest(x, y)
  return band(x, y) ~= 0
end

bitwise.bit32 = {}

local function bit32_bnot(x)
  return (-1 - x) % MOD
end
bitwise.bit32.bnot = bit32_bnot

local function bit32_bxor(a, b, c, ...)
  local z
  if b then
    a = a % MOD
    b = b % MOD
    z = bxor(a, b)
    if c then
      z = bit32_bxor(z, c, ...)
    end
    return z
  elseif a then
    return a % MOD
  else
    return 0
  end
end
bitwise.bit32.bxor = bit32_bxor

local function bit32_band(a, b, c, ...)
  local z
  if b then
    a = a % MOD
    b = b % MOD
    z = ((a + b) - bxor(a, b)) / 2
    if c then
      z = bit32_band(z, c, ...)
    end
    return z
  elseif a then
    return a % MOD
  else
    return MODM
  end
end
bitwise.bit32.band = bit32_band

local function bit32_bor(a, b, c, ...)
  local z
  if b then
    a = a % MOD
    b = b % MOD
    z = MODM - band(MODM - a, MODM - b)
    if c then
      z = bit32_bor(z, c, ...)
    end
    return z
  elseif a then
    return a % MOD
  else
    return 0
  end
end
bitwise.bit32.bor = bit32_bor

function bitwise.bit32.btest(...)
  return bit32_band(...) ~= 0
end

function bitwise.bit32.lrotate(x, disp)
  return lrotate(x % MOD, disp)
end

function bitwise.bit32.rrotate(x, disp)
  return rrotate(x % MOD, disp)
end

function bitwise.bit32.lshift(x, disp)
  if disp > 31 or disp < -31 then return 0 end
  return lshift(x % MOD, disp)
end

function bitwise.bit32.rshift(x, disp)
  if disp > 31 or disp < -31 then return 0 end
  return rshift(x % MOD, disp)
end

function bitwise.bit32.arshift(x, disp)
  x = x % MOD
  if disp >= 0 then
    if disp > 31 then
      return (x >= 0x80000000) and MODM or 0
    else
      local z = rshift(x, disp)
      if x >= 0x80000000 then z = z + lshift(2 ^ disp - 1, 32 - disp) end
      return z
    end
  else
    return lshift(x, -disp)
  end
end

function bitwise.bit32.extract(x, field, ...)
  local width = ... or 1
  if field < 0 or field > 31 or width < 0 or field + width > 32 then error 'out of range' end
  x = x % MOD
  return extract(x, field, ...)
end

function bitwise.bit32.replace(x, v, field, ...)
  local width = ... or 1
  if field < 0 or field > 31 or width < 0 or field + width > 32 then error 'out of range' end
  x = x % MOD
  v = v % MOD
  return replace(x, v, field, ...)
end

bitwise.bit = {}

function bitwise.bit.tobit(x)
  x = x % MOD
  if x >= 0x80000000 then x = x - MOD end
  return x
end
local bit_tobit = bitwise.bit.tobit

function bitwise.bit.tohex(x, ...)
  return tohex(x % MOD, ...)
end

function bitwise.bit.bnot(x)
  return bit_tobit(bnot(x % MOD))
end

local function bit_bor(a, b, c, ...)
  if c then
    return bit_bor(bit_bor(a, b), c, ...)
  elseif b then
    return bit_tobit(bor(a % MOD, b % MOD))
  else
    return bit_tobit(a)
  end
end
bitwise.bit.bor = bit_bor

local function bit_band(a, b, c, ...)
  if c then
    return bit_band(bit_band(a, b), c, ...)
  elseif b then
    return bit_tobit(band(a % MOD, b % MOD))
  else
    return bit_tobit(a)
  end
end
bitwise.bit.band = bit_band

local function bit_bxor(a, b, c, ...)
  if c then
    return bit_bxor(bit_bxor(a, b), c, ...)
  elseif b then
    return bit_tobit(bxor(a % MOD, b % MOD))
  else
    return bit_tobit(a)
  end
end
bitwise.bit.bxor = bit_bxor

function bitwise.bit.lshift(x, n)
  return bit_tobit(lshift(x % MOD, n % 32))
end

function bitwise.bit.rshift(x, n)
  return bit_tobit(rshift(x % MOD, n % 32))
end

function bitwise.bit.arshift(x, n)
  return bit_tobit(arshift(x % MOD, n % 32))
end

function bitwise.bit.rol(x, n)
  return bit_tobit(lrotate(x % MOD, n % 32))
end

function bitwise.bit.ror(x, n)
  return bit_tobit(rrotate(x % MOD, n % 32))
end

function bitwise.bit.bswap(x)
  return bit_tobit(bswap(x % MOD))
end
