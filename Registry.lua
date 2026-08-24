local Janitor     = {};
local Connections = {};

function Janitor:create(name, connection)
    assert(not Connections[name], `Connection "{name}" already exists`);

    Connections[name] = connection;

    return connection;
end;

function Janitor:remove(name)
    local connection = Connections[name];

    if connection then
        connection:Disconnect();
        Connections[name] = nil;
    end;
end;

return Janitor;
