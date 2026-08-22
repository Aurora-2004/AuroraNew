--[[
  Services is a utility module for caching and accessing Roblox services.
  It provides functions to clear the cache, list cached services, and access services by name.
  
  Usage:
    local Services = loadstring(game:HttpGetAsync('https://cdn.oneshot.wtf/Roblox-Utils/Services.lua'))();
    local Players = Services.Players -- Access Players service
    Services.clearCache('Players') -- Clear cache for Players service
    Services.clearCache() -- Clear all caches
    print(Services) -- Print cached services count
]]--

local Services = {};
local _cache   = {};

---Clears cached services.
---@param serviceName? string  -- If nil, clears everything.
function Services.clearCache(serviceName)
  assert(
    not serviceName or _cache[serviceName],
    string.format('No cache to clear for %q', tostring(serviceName))
  );

    if serviceName then
      _cache[serviceName] = nil;
      
      return;
    end;

    for name in pairs(_cache) do
        _cache[name] = nil;
    end;
end;

---Returns a list of currently cached service names.
---@return { [number]: string }
function Services.listCached()
    local list = {};

    for name in pairs(_cache) do
        table.insert(list, name);
    end;

    return list;
end;

setmetatable(Services, {
  __index = function(_, serviceName)
    assert(
      type(serviceName) == 'string' and serviceName ~= '',
      string.format('Invalid service name: %q', tostring(serviceName))
    );

    local svc = _cache[serviceName]
    
    if not svc then
      svc = game:GetService(serviceName)
      
      assert(svc, string.format('Service %q not found', serviceName));

      _cache[serviceName] = svc
    end;

    return svc;
  end,

  __newindex = function() error'Services is read-only'; end,

  __tostring = function()
    local n = 0; 
    
    for _ in pairs(_cache) do 
        n = n + 1;
    end;

    return string.format('Services(cache entries: %d)', n);
  end,

  __pairs = function()
    return next, _cache, nil;
  end,
});

return Services;
