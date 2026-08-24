local Registry    = {};
local Connections = {};

function Registry:create(name, callback)
    if Connections[name] then
        Connections[name]:Disconnect();
    end;

    Connections[name] = callback();

    return Connections[name];
end;

function Registry:remove(name)
    local connection = Connections[name];

    if connection then
        connection:Disconnect();
        Connections[name] = nil;
    end;
end;

return Registry;
