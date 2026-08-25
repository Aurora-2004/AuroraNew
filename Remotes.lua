
local Remotes           = {};
local _cache            = {};
local ReplicatedStorage = game:GetService("ReplicatedStorage");

function Remotes.clearCache(remoteName: string?)
    assert(
        not remoteName or _cache[remoteName],
        string.format("Remote '%s' is not cached, so it cannot be cleared.", tostring(remoteName))
    );

    if remoteName then
        _cache[remoteName] = nil;

        return;
    end;

    table.clear(_cache);
end;

function Remotes.listCached()
    local list = {};

    for name in pairs(_cache) do
        table.insert(list, name);
    end;

    return list;
end;

local Methods = { RemoteEvent = "FireServer", RemoteFunction = "InvokeServer", BindableEvent = "Fire", BindableFunction = "Invoke" };

setmetatable(Remotes, {
    __index = function(_, remoteName: string)
        assert(
            typeof(remoteName) == "string" and remoteName ~= "",
            string.format("Remote name must be a non-empty string, got %s.", typeof(remoteName))
        );

        local Remote = ReplicatedStorage:FindFirstChild(remoteName, true);
        if Remote and not _cache[remoteName] then
            _cache[remoteName] = {

                Remote = Remote,
                Call   = function(_, ...)
                    return Remote[Methods[Remote.ClassName]](Remote, ...);
                end,

            };
        end;

        return _cache[remoteName];
    end;
});

return Remotes;
