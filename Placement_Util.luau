--[[ Placement System ]]--

local Services         = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Aurora-2004/AuroraNew/refs/heads/main/Services.lua"))();

local Players          = Services.Players;
local Workspace        = Services.Workspace;
local RunService       = Services.RunService;
local UserInputService = Services.UserInputService;
local Player           = Players.LocalPlayer;
local Mouse            = Player:GetMouse();

local Placement = {};

Placement.GridSize     = 1;
Placement.RotationStep = 45;

function Placement:IsMobile()
  return UserInputService.TouchEnabled and not UserInputService.MouseEnabled;
end;

-- Returns Pos shifted so Model (rotated by Rot) stays inside Property on X/Z.
function Placement:ClampToProperty(Model, Property, Pos, Rot)
  local PropCF, PropSize = Property:GetBoundingBox();
  local HalfX, HalfZ = PropSize.X / 2, PropSize.Z / 2;

  Model:PivotTo(CFrame.new(Pos) * Rot);
  local BoundsCF, BoundsSize = Model:GetBoundingBox();
  local BX, BZ = BoundsSize.X / 2, BoundsSize.Z / 2;

  local MinX, MaxX, MinZ, MaxZ = math.huge, -math.huge, math.huge, -math.huge;
  for _, Corner in ipairs({ Vector3.new(BX, 0, BZ), Vector3.new(BX, 0, -BZ), Vector3.new(-BX, 0, BZ), Vector3.new(-BX, 0, -BZ) }) do
    local Local = PropCF:PointToObjectSpace(BoundsCF:PointToWorldSpace(Corner));
    MinX, MaxX = math.min(MinX, Local.X), math.max(MaxX, Local.X);
    MinZ, MaxZ = math.min(MinZ, Local.Z), math.max(MaxZ, Local.Z);
  end;

  local function Offset(MinV, MaxV, Half)
    if (MaxV - MinV) > 2 * Half then
      return -(MinV + MaxV) / 2;
    elseif MaxV > Half then
      return Half - MaxV;
    elseif MinV < -Half then
      return -Half - MinV;
    end;
    return 0;
  end;

  return Pos + PropCF:VectorToWorldSpace(Vector3.new(Offset(MinX, MaxX, HalfX), 0, Offset(MinZ, MaxZ, HalfZ)));
end;

-- Core loop shared by every backend.
-- GetTarget()            returns the raw world position the preview should follow.
-- BindControls(Controls) hooks input up to Controls.Place / Lock / Rotate / Cancel
--                        and returns a function that removes those hooks.
function Placement:Run(Model, Property, GetTarget, BindControls)
  local PropCF, PropHX, PropHZ, FloorY;
  if Property then
    local PCF, PSize = Property:GetBoundingBox();
    PropCF, PropHX, PropHZ = PCF, PSize.X / 2, PSize.Z / 2;
    FloorY = PCF.Position.Y + PSize.Y / 2;
  end;

  local Grid = self.GridSize;
  local Rot = CFrame.new();
  local Pos = Vector3.zero;
  local Locked, Chosen, Aborted = false, nil, false;

  local Unbind = BindControls({
    Place  = function() Chosen = Model:GetPivot(); end,
    Lock   = function() Locked = not Locked; print(Locked and "Preview locked" or "Preview unlocked"); end,
    Rotate = function() Rot = Rot * CFrame.Angles(0, math.rad(self.RotationStep), 0); end,
    Cancel = function() Aborted = true; end,
  });

  local Step = RunService.RenderStepped:Connect(function()
    if not Locked then
      local Target = GetTarget();
      local Y = FloorY or Target.Y;
      if PropCF then
        local Rel = PropCF:PointToObjectSpace(Target);
        if math.abs(Rel.X) <= PropHX and math.abs(Rel.Z) <= PropHZ then
          Y = Target.Y;
        end;
      end;
      Pos = Vector3.new(math.round(Target.X / Grid) * Grid, Y, math.round(Target.Z / Grid) * Grid);
    end;
    if Property then
      Pos = self:ClampToProperty(Model, Property, Pos, Rot);
    end;
    Model:PivotTo(CFrame.new(Pos) * Rot);
  end);

  repeat task.wait() until Chosen or Aborted;
  Step:Disconnect();
  Unbind();

  if Aborted then
    print("Placement cancelled");
    return nil;
  end;
  return Chosen;
end;

--// PC: follow the mouse, click to place.

function Placement:PC(Model, Property)
  print("Click to place | L to lock/unlock | R to rotate | B to cancel");
  return self:Run(Model, Property, function()
    return Mouse.Hit.Position;
  end, function(Controls)
    local Keys = {
      [Enum.KeyCode.L] = Controls.Lock,
      [Enum.KeyCode.R] = Controls.Rotate,
      [Enum.KeyCode.B] = Controls.Cancel,
    };
    local Conn = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
      if GameProcessed then
        return;
      elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Controls.Place();
      elseif Keys[Input.KeyCode] then
        Keys[Input.KeyCode]();
      end;
    end);
    return function()
      Conn:Disconnect();
    end;
  end);
end;

--// Mobile: follow the character, on-screen buttons.

function Placement:BuildMobileGui(Controls)
  local Gui = Instance.new("ScreenGui");
  Gui.Name = "PlacementControls";
  Gui.ResetOnSpawn = false;
  Gui.Parent = (gethui and gethui()) or Player:WaitForChild("PlayerGui");

  local Frame = Instance.new("Frame");
  Frame.AnchorPoint = Vector2.new(0.5, 1);
  Frame.Position = UDim2.new(0.5, 0, 1, -24);
  Frame.Size = UDim2.new(0, 380, 0, 44);
  Frame.BackgroundTransparency = 1;
  Frame.Parent = Gui;

  local Layout = Instance.new("UIListLayout");
  Layout.FillDirection = Enum.FillDirection.Horizontal;
  Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
  Layout.Padding = UDim.new(0, 8);
  Layout.Parent = Frame;

  local Buttons = {
    { "Place",  Color3.fromRGB(15, 179, 0),  Controls.Place  },
    { "Lock",   Color3.fromRGB(60, 60, 60),  Controls.Lock   },
    { "Rotate", Color3.fromRGB(60, 60, 60),  Controls.Rotate },
    { "Cancel", Color3.fromRGB(179, 30, 30), Controls.Cancel },
  };
  for Order, Info in ipairs(Buttons) do
    local Button = Instance.new("TextButton");
    Button.LayoutOrder = Order;
    Button.Size = UDim2.new(0, 88, 1, 0);
    Button.BackgroundColor3 = Info[2];
    Button.TextColor3 = Color3.new(1, 1, 1);
    Button.Font = Enum.Font.GothamBold;
    Button.TextSize = 16;
    Button.Text = Info[1];
    Button.Parent = Frame;
    Instance.new("UICorner").Parent = Button;
    Button.Activated:Connect(Info[3]);
  end;

  return Gui;
end;

function Placement:Mobile(Model, Property)
  local Params = RaycastParams.new();
  Params.FilterType = Enum.RaycastFilterType.Exclude;

  return self:Run(Model, Property, function()
    local Character = Player.Character;
    local Root = Character and Character:FindFirstChild("HumanoidRootPart");
    if not Root then
      return Model:GetPivot().Position;
    end;
    -- a few studs in front of the player, dropped onto whatever is below
    Params.FilterDescendantsInstances = { Character, Model };
    local Origin = Root.Position + Root.CFrame.LookVector * 4;
    local Hit = Workspace:Raycast(Origin, Vector3.new(0, -50, 0), Params);
    return Hit and Hit.Position or (Origin - Vector3.new(0, 3, 0));
  end, function(Controls)
    local Gui = self:BuildMobileGui(Controls);
    return function()
      Gui:Destroy();
    end;
  end);
end;

--// Entry

-- Positions Model on Property using the right backend for the device.
-- Returns the chosen CFrame, or nil if the user cancelled.
function Placement:Choose(Model, Property)
  if self:IsMobile() then
    return self:Mobile(Model, Property);
  end;
  return self:PC(Model, Property);
end;

return Placement;

--[[ Documentation ]]--

--[[
  PLACEMENT SYSTEM

  Lets the user position any preview Model (pivot at its min corner) on a property
  and returns the CFrame they chose. Wire art is one user of it; anything that needs
  "put this somewhere on my base" can use it.

  Loading
    local Placement = loadstring(game:HttpGetAsync("<url to Placement.lua>"))();

  Settings
    Placement.GridSize      number  Snap size on X/Z.                 (1)
    Placement.RotationStep  number  Degrees per rotate press.         (45)

  Placement:Choose(Model, Property)                -> CFrame | nil
    Main entry. Picks PC or Mobile based on the device and runs it.
    Property may be nil, in which case the preview is not clamped.

  Placement:PC(Model, Property)                    -> CFrame | nil
    Preview follows the mouse.
      Left click  place        L  lock / unlock position
      R           rotate       B  cancel

  Placement:Mobile(Model, Property)                -> CFrame | nil
    Preview sits a few studs in front of the character and follows them as they
    walk. A button bar at the bottom of the screen gives Place / Lock / Rotate /
    Cancel. Lock freezes the preview so the player can walk around it.

  Placement:Run(Model, Property, GetTarget, BindControls) -> CFrame | nil
    The shared loop. Snaps GetTarget() to the grid, keeps Y on the property floor
    unless the target is over the property, clamps the model inside the property
    and pivots it every frame. Add a new backend by supplying your own GetTarget
    and BindControls.

  Placement:ClampToProperty(Model, Property, Pos, Rot) -> Vector3
    Returns Pos nudged so Model stays inside Property on X/Z.

  Placement:IsMobile()                             -> boolean
    Touch enabled and no mouse.

  Placement:BuildMobileGui(Controls)               -> ScreenGui
    Builds the mobile button bar wired to Controls.
]]
