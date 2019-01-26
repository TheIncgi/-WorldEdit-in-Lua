local Vector = {
  __class = "Vector"
}

function Vector:new( obj )
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  --log(obj)
  return obj
end

function Vector:add( v2 )
  --if not v2.__class=="Vector" then error("arg not a Vector") end
  local t = {}
  if type(v2)=="number"then
    for i=1, #self do
      t[i] = self[i] + v2
    end
    return Vector:new( t )
  elseif #self ~= #v2 then error("Dimension mismatch") end
    for i=1, #self do
      t[i] = self[i] + v2[i]
    end
  return Vector:new( t )
end

function Vector:sub( v2 )
  --if not v2.__class=="Vector" then error("arg not a Vector") end
  local t = {}
  if type(v2)=="number"then
    for i=1, #self do
      t[i] = self[i] - v2
    end
    return Vector:new( t )
  end
  if #self ~= #v2 then error("Dimension mismatch") end
    for i=1, #self do
      t[i] = self[i] - v2[i]
    end
  return Vector:new( t )
end

function Vector:scale( v2 )
  local t = {}
  if type(v2)=="number"then
    for i=1, #self do
      t[i] = self[i] * v2
    end
    return Vector:new( t )
  end
  if #self ~= #v2 then error("Dimension mismatch") end
    for i=1, #self do
      t[i] = self[i] * v2[i]
    end
  return Vector:new( t )
end

function Vector:cross( v2 )
  if #self ~= 3 then error("Vec 1 must be len 3") end
  if #b ~= 3 then error("Vec 2 must be len 3") end
  local t = {}

end

function Vector:dot( v2 )
  if #a ~= #b then error("Dimension mismatch") end
    local sum = 0
    for i=1, #a do
      sum = sum + a[i] * b[i]
    end
    return sum
end

function Vector:min( v2 )
  if #self ~= #v2 then error("Dimension mismatch") end
  local t = {}
  for i=1, #self do
    t[i] = math.min(self[i], v2[i])
  end
  return Vector:new( t )
end

function Vector:max( v2 )
  if #self ~= #v2 then error("Dimension mismatch") end
  local t = {}
  for i=1, #self do
    t[i] = math.max(self[i], v2[i])
  end
  return Vector:new( t )
end

function Vector:negate()
  return self:scale(-1)
end

--adds to end of this vector, good for later unpacking
function Vector:join(v2)
  local t = {}
  for _, b in pairs(self) do
    t[#t+1] = b
  end
  for _, b in pairs(v2) do
    t[#t+1] = b
  end
  return Vector:new( t )
end

function Vector:clone()
  local t = {}
  for i = 1, #self do
    t[i] = self[i]
  end
  return Vector:new(t)
end

function Vector:sum()
  local out = 0
  for i = 1, #self do
    out = out + self[i]
  end
  return out
end


Vector.__add = Vector.add
Vector.__sub = Vector.sub
Vector.__unm = Vector.negate
Vector.__concat = Vector.join
Vector.__mul    = function(a, b)
  if b == nil then error("vector * nil")
  if type(a) == "number" and not type(b) == "number" then
    a, b = b, a
  --else
  --  error("both numbers?")
  end

  elseif type(b) == "number" then
    return Vector.scale(a,b)
  elseif type(b)=="table" and not b.__class=="Vector" then
    if #a ~= #b then error("Dimension mismatch") end
    local t = {}
    for i=1, #a do
      t[i] = a[i] * b[i]
    end
    return Vector:new( t )
  elseif type(b)=="table" and b.__class=="Vector" then
    return a:cross(b)
  else
    error("Unimplemented for type "..((type(b)=="table" and table.__class) or type(b)))
  end
end

return Vector
