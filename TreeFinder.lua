

local Services = {};
setmetatable(Services, {
  __index = function(_, serviceName)
    local service = game:GetService(serviceName);
    if service then
      Services[serviceName] = service
      return service
    end;
	return false;
  end;
});

local Players           = Services.Players;
local ReplicatedStorage = Services.ReplicatedStorage;
local HttpService       = ServicesHttpService;
local Player            = Players.LocalPlayer;

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

local WEBHOOK_URL = _G.Webhook

local function SendTreeWebhook(TreeClass, JobId, Position, Credits)
    local PlaceId = game.PlaceId
    local InstanceId = JobId or game.JobId

    local JoinScript = string.format(
        [[game:GetService("TeleportService"):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)]],
        PlaceId,
        InstanceId
    )

    local TeleportScript = string.format(
        [[game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
            %.6f, %.6f, %.6f,
            %.6f, %.6f, %.6f,
            %.6f, %.6f, %.6f,
            %.6f, %.6f, %.6f
        )]],
        Position:GetComponents()
    )

    -- https link so Discord renders it as clickable
    local LaunchURL = string.format(
        "https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s",
        PlaceId,
        InstanceId
    )

    local Timestamp = os.date("%d/%m/%Y | %I:%M %p")

    local Embed = {
        title = string.format("We found a %s: tree", TreeClass.Value),

        description = table.concat({
            "**Anyone can join and claim these trees!**",
            "",

            "**Launch game**",
            string.format("[Click here](%s)", LaunchURL),
            "",

            "**Join script**",
            "```lua",
            JoinScript,
            "```",

            "**Teleport script**",
            "```lua",
            TeleportScript,
            "```",

            string.format("**%s**", Timestamp),
            string.format("Credits: %s", Credits or "Aurora"),
        }, "\n"),

        color = 0xD2692C
    }

    local Data = {
        username = "Aurora",
        embeds = { Embed }
    }

    local Success, Error = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(Data)
        })
    end)

    if not Success then
        warn("Webhook failed:", Error)
    end
end

CacheTreeRegions()

local AvailableTrees = SearchForLimitedTrees();
if #AvailableTrees >= 1 then
  if not _G.Webhook then SendNotice("Found limited tree.") return; end;
  for _, Tree in next, AvailableTrees do
    local TreeClass = Tree:FindFirstChild("TreeClass");
    local JobId = game.JobId;
    local Position = CFrame.new(Tree:GetPivot().Position);
	SendNotice("Found limited tree.")
    SendTreeWebhook(TreeClass.Value, JobId, Position)
  end;
end;

if #AvailableTrees == 0 then
  SendNotice("Failed to find limited trees.")
end;

queue_on_teleport([[
  repeat task.wait() until game:IsLoaded() and game:GetService'Players'.LocalPlayer and game:GetService'Players'.LocalPlayer.CharacterAdded;
  task.wait(10)
  loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Aurora-2004/AuroraNew/refs/heads/main/TreeFinder.lua"))()
]]);

loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Vcsk/RobloxScripts/refs/heads/main/ServerHop.lua"))()
