local function __make__pairs(parent, child)
  return function(tbl)
    local _parent = true
    local function iter(child, k)
      if _parent then
        local v
        repeat
          k,v = next(parent, k)              
        until not child[k] or not k
        if k == nil then
          _parent = false
          return iter(child,k)
        end
        return k,v
      else
        return next(child, k)
      end
    end
    return iter, child, nil
  end
end

-- TODO fix name. compose? linked?
local function linked(parent, child)
  return setmetatable({}, {
      __index = function(tbl, index)
        local value = child[index]
        if value == nil then
          value = parent[index]
        end
        -- Allow for multiple chaining
        if value == nil and index == "linked" then value = linked end
        return value
      end,
      __pairs = __make__pairs(parent, child)
  })
end

-- inplace chaining
local function inherits(parent, child)
  return setmetatable(child, {
    __index = function(tbl, index)
      local value = parent[index]
      
      -- allow for chaining of inherits
      if value == nil and index == "inherits" then value = inherits end
      return value
    end,
    __pairs = __make__pairs(parent, child)
  })
end

-- An example Class system 
local function Class(tbl, ancestors)
  tbl = tbl or {}
  ancestors = ancestors or {}
  
  local inherit_chain = {}
  for i,v in ipairs(ancestors) do
    inherit_chain = linked(inherit_chain, v)
  end
  
  local class = inherits(inherit_chain, tbl)
  getmetatable(class).__call = function(class, ...)
    local instance = {}
    inherits(class, instance)
    
    if class.init then
      class.init(instance, ...)
    end
    
    return instance
  end
  return class
end

return {inherits=inherits, linked=linked, Class=Class}