
local Services = {};
setmetatable(Services, {
  __index = function(_, serviceName)
    local service = game:GetService(serviceName);
    if service then
      Services[serviceName] = service
      return service
    end;
  end;
});

local Players           = Services.Players;
local ReplicatedStorage = Services.ReplicatedStorage;
local Player            = Players.LocalPlayer

local function IsClientAlive()
  if not Player.Character then
    return;
  end;
  local Humanoid = Player.Character:FindFirstChild("Humanoid");
  return ((Humanoid and Humanoid.Health > 0) and Humanoid);
end;

local function Teleport(Position)
  local Humanoid = IsClientAlive();
  if not Humanoid then
    return;
  end;
  ((Humanoid.SeatPart ~= nil and Humanoid.SeatPart.Parent) or Player.Character):PivotTo(Position)
end;

local function SendNotice(Message, Duration)
  return ReplicatedStorage.Notices.SendUserNotice:Fire(Message, Duration);
end;

local _CacheTreeRegions = {};
local function CacheTreeRegions()
  for _, Region in next, Services.Workspace:GetChildren() do
    if Region.Name == "TreeRegion" then
      table.insert(_CacheTreeRegions, Region);
    end;
  end;
end;

local LimitedTrees = {"Spooky", "SpookyNeon", "BlueSpruce"};
local function SearchForLimitedTrees()
  local AvailableTrees = {};
  for _, Region in next, _CacheTreeRegions do
    for _, Tree in next, Region:GetChildren() do
      local Owner     = Tree:FindFirstChild("Owner");
      local TreeClass = Tree:FindFirstChild("TreeClass");
      local InnerWood = Tree:FindFirstChild("InnerWood");
      if (Owner and Owner.Value == nil) and (TreeClass and table.find(LimitedTrees, TreeClass.Value)) and not InnerWood then
        table.insert(AvailableTrees, Tree);
      end;
    end;
  end;
  return AvailableTrees;
end;

CacheTreeRegions()

local AvailableTrees = SearchForLimitedTrees();
if #AvailableTrees >= 1 then
  for _, Tree in next, AvailableTrees do
    local TreeClass = Tree:FindFirstChild("TreeClass");
    SendNotice(string.format("Found %s.", TreeClass.Value), 5)
    if not _G.WebHook then
      Teleport(CFrame.new(Tree:GetPivot().Position) + Vector3.new(5, 5, 5))
      return;
    end;
    --send to discord when added
  end;
end;

if #AvailableTrees == 0 then
  SendNotice("Failed to find limited trees.")
end;

queue_on_teleport([[
  repeat task.wait() until game:IsLoaded() and game:GetService'Players'.LocalPlayer and game:GetService'Players'.LocalPlayer.CharacterAdded;
  loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Aurora-2004/AuroraNew/refs/heads/main/TreeFinder.lua"))()
]]);

loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Vcsk/RobloxScripts/refs/heads/main/ServerHop.lua"))()
