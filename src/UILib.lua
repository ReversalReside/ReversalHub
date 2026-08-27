--[[
		Sealz.UI
	Author: 4lpaca
	License: MIT
	Github: https://github.com/4lpaca-pin/Sealz
]]

local Args = {...};

-- Error reporting: prints which named script errored, the message, and a
-- stack trace that includes the line number where the error was thrown.
local function SealzReportError(scriptName, err)
	print(("=== [Sealz] ERROR in script \"%s\" ==="):format(scriptName));
	print(tostring(err));
	print(debug.traceback("", 3));
end;

-- Run `func` safely. On error, report the script name + message + line via
-- print, then return ok + result so the caller can decide what to do.
local function SealzTry(scriptName, func, ...)
	local n = select("#", ...);
	local args = { ... };
	local ok, res = xpcall(func, function(e)
		local msg = ("=== [Sealz] ERROR in script \"%s\" ===\n%s"):format(scriptName, tostring(e));
		if typeof(debug) == "table" and typeof(debug.traceback) == "function" then
			msg = msg .. "\n" .. debug.traceback(tostring(e), 2);
		end;
		print(msg);
		return e;
	end, table.unpack(args, 1, n));
	return ok, res;
end;

local function __SealzMain()
local DefaultConfig = {
	Icons = {
		Type = "Asset",
		Data = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
	},
	SignalLibrary = {
		Type = "Url",
		Data = "https://raw.githubusercontent.com/ReversalReside/ReversalHub/refs/heads/testingofcleanup-fix-2918/src/signal.luau",
		Name = "Signal.luau",
	},
	Fonts = {
		Primary = Enum.Font.RobotoMono,
		Second = Enum.Font.RobotoMono
	},
	AccentColor = Color3.fromRGB(255, 94, 97),
};

local LibraryConfig = _G.SealzConfig or Args[1] or DefaultConfig;

LibraryConfig.AccentColor = LibraryConfig.AccentColor or DefaultConfig.AccentColor;
LibraryConfig.Fonts = LibraryConfig.Fonts or DefaultConfig.Fonts;
LibraryConfig.SignalLibrary = LibraryConfig.SignalLibrary or DefaultConfig.SignalLibrary;
LibraryConfig.Icons = LibraryConfig.Icons or DefaultConfig.Icons;

-- Load File System (Studio Only)
if game:GetService('RunService'):IsStudio() and script and script:WaitForChild('Environment') then
	local status , func = pcall(require , script:WaitForChild('Environment'));

	if status then
		SealzTry("env.luau", func, getfenv());
	end;
end;

local IconsPath, SignalPath , SignalName;

if LibraryConfig.Icons then
	-- Custom Icons
	local cfg = LibraryConfig.Icons;

	if cfg.Type == "Asset" then
		IconsPath = cfg.Data;
	end;
else
	-- Default
	IconsPath = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json";
end;

if LibraryConfig.SignalLibrary then
	local cfg = LibraryConfig.SignalLibrary;

	SignalName = cfg.Name;

	if cfg.Type == "Url" then
		SignalPath = cfg.Data
	elseif cfg.Type == "Source" then
		SignalPath = "-- signal\n"..cfg.Data;
	elseif cfg.Type == "File" then
		SignalPath = readfile(cfg.Data);
	end;
else
	SignalPath = "https://raw.githubusercontent.com/ReversalReside/ReversalHub/refs/heads/testingofcleanup-fix-2918/src/signal.luau";
	SignalName = "Signal.luau";
end

-- Tween Info
local BasedTween = TweenInfo.new(0.3,Enum.EasingStyle.Quint);
local InstantTween = TweenInfo.new(0);
local Based2Twenn = TweenInfo.new(0.15);
local ScaleTween = TweenInfo.new(0.5,Enum.EasingStyle.Quint);

-- Library
local Sealz = {
	Icons = (Font ~= nil and Font.new or function() end)(IconsPath,Enum.FontWeight.Bold,Enum.FontStyle.Normal),
	Version = "1.0.1"
};

-- Shared connection registry so a re-execution can tear down everything the
-- previous run left running (threads, signals, loops) before building fresh.
_G.__SealzConnections = _G.__SealzConnections or {};
Sealz._connections = _G.__SealzConnections;

-- Register a teardown function (usually a :Disconnect() / task.cancel wrapper)
-- that the next cleanup will call when this UI is replaced.
Sealz.Track = function(teardown)
	table.insert(Sealz._connections, teardown);
end;

Sealz.Sizes = {
	Default = UDim2.new(0, 640, 0, 480),
	Small = UDim2.new(0, 600,0, 335),
	Large = UDim2.fromOffset(800 , 600),
};

if LibraryConfig.Fonts then
	Sealz.Font = LibraryConfig.Fonts.Primary or Enum.Font.GothamBold;
	Sealz.SecondFont = LibraryConfig.Fonts.Second or Enum.Font.GothamMedium;
else
	Sealz.Font = DefaultConfig.Fonts.Primary or Enum.Font.GothamBold;
	Sealz.SecondFont = DefaultConfig.Fonts.Second or Enum.Font.GothamMedium;
end;

Sealz.cloneref = cloneref or function(f) return f end;
Sealz.get_service = function(name: string): ServiceProvider
	local n,nm = pcall(function()
		return game.GetService(game, name);
	end);

	return (n and nm) or game.FindFirstChild(game, name);
end;

local function HttpGet(url)
	if typeof(game) == "table" and typeof(game.HttpGet) == "function" then
		return game:HttpGet(url);
	elseif typeof(httpget) == "function" then
		return httpget(url);
	elseif typeof(request) == "function" then
		local r = request({ Url = url, Method = "GET" });
		return (r and (r.Body or r.body)) or "";
	elseif typeof(syn) == "table" and typeof(syn.request) == "function" then
		local r = syn.request({ Url = url, Method = "GET" });
		return (r and (r.Body or r.body)) or "";
	end;
	error("no HTTP method available to fetch \"" .. tostring(url) .. "\"");
end;

Sealz.import = function(url: string , module: string)
	local scriptName = module or "import";

	local function loadAndRun(src)
		local chunk = loadstring(src);
		if typeof(chunk) ~= "function" then
			error(("\"%s\" failed to compile (empty or invalid source)"):format(scriptName));
		end;
		return chunk();
	end;

	if string.sub(url,1,3) ~= "htt" then
		local ok, res = SealzTry(scriptName, loadAndRun, url);
		if ok then
			return res;
		end;

		return require(script:FindFirstChild(module));
	end;

	local ok, res = SealzTry(scriptName, loadAndRun, HttpGet(url));
	if ok then
		return res;
	end;

	return require(script:FindFirstChild(module));
end;

local Players: Players = Sealz.get_service("Players");
local LocalPlayer: Player = Players.LocalPlayer;
local Mouse: Mouse = LocalPlayer:GetMouse();
local UserInputService: UserInputService = Sealz.get_service("UserInputService");
local Lighting: Lighting = Sealz.get_service("Lighting");
local RunService: RunService = Sealz.get_service("RunService");
local HttpService: HttpService = Sealz.get_service("HttpService");
local TweenService: TweenService = Sealz.get_service("TweenService");
local TextService: TextService = Sealz.get_service("TextService");
local CoreGui: PlayerGui = (gethui and gethui()) or Sealz.get_service("CoreGui") or LocalPlayer.PlayerGui;
local ProtectGui = protect_gui or protectgui or (syn and syn.protect_gui) or function(s) return s; end;
local CurrentCamera: Camera = Sealz.cloneref(workspace.CurrentCamera);
local okSignal, sig = SealzTry(SignalName or "Signal.luau", function()
	return Sealz.import(SignalPath, SignalName);
end);

local CreateSignal = okSignal and sig or nil;

-- Track every signal we create so a re-execution tears down the previous
-- run's connections (otherwise stale TabSignal/BlockSignal callbacks keep
-- firing against already-destroyed instances and spam the console).
if typeof(CreateSignal) == "function" then
	local RealCreateSignal = CreateSignal;
	CreateSignal = function(...)
		local sig = RealCreateSignal(...);
		Sealz:Track(function()
			if typeof(sig) == "table" and typeof(sig.Destroy) == "function" then
				sig:Destroy();
			end;
		end);
		return sig;
	end;
end;

-- Cleanup: tear down any existing Sealz UI before building a fresh one,
-- so re-executing the script does not stack duplicate interfaces.
do
	-- Disconnect every connection/thread the previous run registered. This
	-- kills the blur loops, dropdown runtime threads and other long-lived
	-- signals so they don't keep firing against destroyed instances.
	local oldConns = _G.__SealzConnections;
	if typeof(oldConns) == "table" then
		for i = 1, #oldConns do
			local ok, err = pcall(function()
				local conn = oldConns[i];
				if typeof(conn) == "function" then
					conn();
				elseif typeof(conn) == "table" and typeof(conn.Disconnect) == "function" then
					conn:Disconnect();
				end;
			end);
			if not ok then
				SealzReportError("UILib.lua (cleanup)", err);
			end;
		end;
		table.clear(oldConns);
	end;

	-- Destroy the previous ScreenGui by direct reference first (works no
	-- matter where ProtectGui moved it), then as a fallback search every
	-- container the GUI could have been parented into.
	local prev = _G.__SealzUI;
	if typeof(prev) == "Instance" then
		if prev.Parent then
			prev:Destroy();
		else
			pcall(function()
				prev:Destroy();
			end);
		end;
	end;

	local parents = { CoreGui };
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui);
		if ok and hui then parents[#parents + 1] = hui; end;
	end;
	local ok, cg = pcall(game.GetService, game, "CoreGui");
	if ok and cg then parents[#parents + 1] = cg; end;
	if LocalPlayer:FindFirstChild("PlayerGui") then
		parents[#parents + 1] = LocalPlayer.PlayerGui;
	end;

	for i = 1, #parents do
		local ok, existing = pcall(parents[i].FindFirstChild, parents[i], "sealz");
		if ok and existing then
			existing:Destroy();
		end;
	end;
end;

local SealzUI = Instance.new("ScreenGui")

SealzUI.Name = "sealz";
SealzUI.Parent = CoreGui;
SealzUI.ResetOnSpawn = false;
SealzUI.ZIndexBehavior = Enum.ZIndexBehavior.Global;
SealzUI.IgnoreGuiInset = true;

ProtectGui(SealzUI);

-- Keep a persistent reference so the next execution can destroy this UI
-- directly, no matter where ProtectGui ended up parenting it.
_G.__SealzUI = SealzUI;

Sealz.BlurringHandle = CurrentCamera;
Sealz.ScreenGui = SealzUI;
Sealz.AccentColor = LibraryConfig.AccentColor or Color3.fromRGB(255, 94, 97);
Sealz.Flags = {};
Sealz.ColorRegisitry = {};
Sealz.InsetSize = math.abs(SealzUI.AbsolutePosition.Y);

Sealz.RandomString = function()
	return string.char(math.random(32,120));
end;

Sealz.IsMobile = UserInputService.TouchEnabled;

function Sealz:GetTimeString(a)
	local OsTime = os.date("*t",a);

	return string.format("%d:%d:%d",OsTime.hour,OsTime.min,OsTime.sec)
end;

function Sealz:AddFlag(name: string, data)
	if not name then
		return;
	end;

	assert(not Sealz.Flags[name],"same flag cannot be use.");

	Sealz.Flags[name] = data;
end;

Sealz.Base64 = {} do
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	Sealz.Base64.Encode = function(data)
		return ((data:gsub('.', function(x) 
			local r,b='',x:byte()
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r;
		end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
			return b:sub(c+1,c+1)
		end)..({ '', '==', '=' })[#data%3+1])
	end;

	Sealz.Base64.Decode = function(data)
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',(b:find(x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r;
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end;
end;

-- Core API
function Sealz:IsMouseOverFrame(UI: Frame)
	if not UI then
		return;
	end;

	local AbsPos: Vector2, AbsSize: Vector2 = UI.AbsolutePosition, UI.AbsoluteSize;

	if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
		return true;
	end;
end;

function Sealz:AddInput(UI: Frame , Callback: ()->any)
	local Button = Instance.new('ImageButton',UI);

	Button.ZIndex = UI.ZIndex + 10;
	Button.Size = UDim2.fromScale(1,1);
	Button.BackgroundTransparency = 1;
	Button.ImageTransparency = 1;
	Button.Image = "";

	if Callback then
		local Signal = Button.Activated:Connect(Callback);

		return Button , Signal;
	end;

	return Button;
end;

function Sealz:Tween(UI: Frame , Info: TweenInfo , Property: {[string]:any})
	local Tween = TweenService:Create(UI , Info or BasedTween , Property);

	Tween:Play();

	return Tween;
end;

function Sealz:AddDrag(InputFrame: Frame, MoveFrame: Frame, Speed : number)
	local dragToggle: boolean = false;
	local dragStart: Vector3 = nil;
	local startPos: UDim2 = nil;
	local Tween = TweenInfo.new(Speed);

	local updateInput = function(input)
		local CurrentScreenSize = Vector2.new(CurrentCamera.ViewportSize.X,CurrentCamera.ViewportSize.Y);

		local delta = input.Position - dragStart;
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y);

		Sealz:Tween(MoveFrame,Tween,{
			Position = position
		});
	end;

	InputFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then 
			dragToggle = true;
			dragStart = input.Position;
			startPos = MoveFrame.Position;

			local input_end;
			input_end = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false;

					input_end:Disconnect();
				end
			end)
		end
	end);

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input)
			end
		end
	end);
end;

function Sealz:Rounding(num: number, numDecimalPlaces: number)
	local mult = 10 ^ (numDecimalPlaces or 0);
	return math.floor(num * mult + 0.5) / mult;
end;


function Sealz:Format(Params,Fixed)
	Params = Params or {};

	local k = Params or {};

	for i,v in next , Fixed do
		k[i] = Params[i] or v;
	end;

	table.clear(Fixed);

	return k;
end;


function Sealz:GetCalculatePosition(planePos, planeNormal, rayOrigin, rayDirection)
	local n = planeNormal;
	local d = rayDirection;
	local v = rayOrigin - planePos;

	local num = (n.x * v.x) + (n.y * v.y) + (n.z * v.z);
	local den = (n.x * d.x) + (n.y * d.y) + (n.z * d.z);
	local a = -num / den;

	return rayOrigin + (a * rayDirection);
end;


function Sealz:AddBlurring(Frame , Signal)
	local Part = Instance.new('Part',Sealz.BlurringHandle);
	local DepthOfField = Instance.new('DepthOfFieldEffect',Sealz.cloneref(game:GetService('Lighting')));
	local BlockMesh = Instance.new("BlockMesh");

	BlockMesh.Parent = Part;
	BlockMesh.Name = "dx"

	Part.Material = Enum.Material.Glass;
	Part.Transparency = 1;
	Part.Reflectance = 1;
	Part.CastShadow = false;
	Part.Anchored = true;
	Part.CanCollide = false;
	Part.CanQuery = false;
	Part.CollisionGroup = Sealz.RandomString();
	Part.Size = Vector3.new(1, 1, 1) * 0.01;
	Part.Color = Color3.fromRGB(0,0,0);

	local generate_new_part = function()
		Part = Part:Clone()
		BlockMesh = Instance.new("BlockMesh",Part);
	end;

	DepthOfField.Enabled = true;
	DepthOfField.FarIntensity = 0;
	DepthOfField.FocusDistance = 0;
	DepthOfField.InFocusRadius = 1000;
	DepthOfField.NearIntensity = 1;
	DepthOfField.Name = Sealz.RandomString();

	Part.Name = Sealz.RandomString();

	local disconnect;

	local UpdateFunction = function()
		local IsWindowActive = Signal:Get();

		if IsWindowActive then

			Sealz:Tween(DepthOfField,TweenInfo.new(0.1),{
				NearIntensity = 1
			})

			Sealz:Tween(Part,TweenInfo.new(0.1),{
				Transparency = 0.97,
				Size = Vector3.new(1, 1, 1) * 0.01;
			})

			local status = pcall(function()
				Part.Parent = Sealz.BlurringHandle;
			end);

			if not status then
				SealzReportError("UILib.lua (AddBlurring)", "failed to parent blur Part to camera");
			end;
		else
			Sealz:Tween(DepthOfField,TweenInfo.new(0.1),{
				NearIntensity = 0
			})

			Sealz:Tween(Part,TweenInfo.new(0.1),{
				Size = Vector3.zero,
				Transparency = 1.5,
			})

			Part.Parent = nil;

			return;
		end;

		if IsWindowActive then
			local corner0 = Frame.AbsolutePosition;
			local corner1 = corner0 + Frame.AbsoluteSize;

			local ray0 = CurrentCamera.ScreenPointToRay(CurrentCamera,corner0.X, corner0.Y, 1);
			local ray1 = CurrentCamera.ScreenPointToRay(CurrentCamera,corner1.X, corner1.Y, 1);

			local planeOrigin = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * (0.05 - CurrentCamera.NearPlaneZ);

			local planeNormal = CurrentCamera.CFrame.LookVector;

			local pos0 = Sealz:GetCalculatePosition(planeOrigin, planeNormal, ray0.Origin, ray0.Direction);
			local pos1 = Sealz:GetCalculatePosition(planeOrigin, planeNormal, ray1.Origin, ray1.Direction);

			pos0 = CurrentCamera.CFrame:PointToObjectSpace(pos0);
			pos1 = CurrentCamera.CFrame:PointToObjectSpace(pos1);

			local size   = pos1 - pos0;
			local center = (pos0 + pos1) / 2;

			BlockMesh.Offset = center
			BlockMesh.Scale  = size / 0.0101;
			Part.CFrame = CurrentCamera.CFrame;
		end;
	end;

	local rbxsignal = CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(UpdateFunction)
	local loopThread = UserInputService.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			pcall(UpdateFunction);
		end;
	end);

	local THREAD = task.spawn(function()
		while true do task.wait(0.1)
			pcall(UpdateFunction);
		end;
	end);

	disconnect = function()
		rbxsignal:Disconnect();
		loopThread:Disconnect();
		task.cancel(THREAD);
		Part:Destroy();
		DepthOfField:Destroy();
	end;

	Sealz:Track(disconnect);

	Frame.Destroying:Connect(disconnect);

	return rbxsignal;
end;

function Sealz:AddVisibleSignal(UI: Frame , Property: string , Trigger: number , HideParent: boolean , OriginalParent: Object)
	local Ps = UI.Parent or OriginalParent;

	Trigger = Trigger or 0.95;

	return UI:GetPropertyChangedSignal(Property):Connect(function()
		if UI[Property] < Trigger then
			UI.Visible = true;
			UI.Parent = Ps;
		else
			UI.Visible = false;

			if HideParent then
				UI.Parent = nil
			end
		end;
	end);
end;

function Sealz:SET_SCROLLING(UI: ScrollingFrame,LIST: UIListLayout)
	local Callback = function()
		UI.CanvasSize = UDim2.fromOffset(0,LIST.AbsoluteContentSize.Y)
	end;

	Callback();

	return LIST:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(Callback);
end;

function Sealz:OnOverFrame(UI: Frame , Func: () -> any): (Key: InputObject , Processed: boolean) -> any
	return function(Key: InputObject,Processed: boolean)
		if not Sealz:IsMouseOverFrame(UI) then
			if Key.UserInputType == Enum.UserInputType.MouseButton1 or Key.UserInputType == Enum.UserInputType.Touch then
				return Func();
			end;
		end
	end;
end;

function Sealz:AddHoverSignal(UI: Frame , Property: string , Trigger: any , Default: any , MainObject: Object)
	Default = Default or UI[Property];
	UI = MainObject or UI;

	return {
		Down = UI.MouseEnter:Connect(function()
			Sealz:Tween(UI,BasedTween,{[Property] = Trigger})
		end),
		Up = UI.MouseLeave:Connect(function()
			Sealz:Tween(UI,BasedTween,{[Property] = Default})
		end)
	};
end;

-- Transparent Effect Manager
Sealz.Properties = {
	["Frame"] = {"BackgroundTransparency"},
	["ScrollingFrame"] = {"BackgroundTransparency",'ScrollBarImageTransparency'},
	["UIShadow"] = {"Transparency"},
	["UIStroke"] = {"Transparency"},
	["TextLabel"] = {"TextTransparency","TextStrokeTransparency",'BackgroundTransparency'},
	["TextButton"] = {"TextTransparency","TextStrokeTransparency",'BackgroundTransparency'},
	['TextBox'] = {"TextTransparency","TextStrokeTransparency",'BackgroundTransparency'},
	["ImageLabel"] = {"ImageTransparency",'BackgroundTransparency'}
};

function Sealz.Transparent()
	local items = {};

	items._c = {};

	function items:Add(Item: Frame , org: {[string]: number})
		local props = Sealz.Properties[Item.ClassName];

		local defaults,off = {},{} for i,v in next , props do
			defaults[v] = (org and org[v]) or Item[v];
			off[v] = 1;
		end;

		local index = #items._c + 1;

		table.insert(items._c , {
			a = Item,
			b = defaults,
			c = off,
		});

		return function(prop: string, new_value: number)
			items._c[index].b[prop] = new_value;
		end;
	end;

	function items:Fire(bool: boolean,Instant: boolean)
		local Tween = (Instant and InstantTween) or BasedTween;

		if bool then
			for i,v in next , items._c do
				Sealz:Tween(v.a,Tween,v.b);
			end;
		else
			for i,v in next , items._c do
				Sealz:Tween(v.a,Tween,v.c);
			end;
		end;
	end;

	return items;
end;

function Sealz:SET_CONNECT(a: RBXScriptSignal,b: RBXScriptSignal): RBXScriptConnection
	return a:Connect(function(t) if not t then return b:Fire(false) end; end);
end;

Sealz.KeyCodeReplace = {
	One = '1',
	Two = '2',
	Three = '3',
	Four = '4',
	Five = '5',
	Six = '6',
	Seven = '7',
	Eight = '8',
	Nine = '9',
	Zero = '0',
	Minus = "-",
	Plus = "+",
	BackSlash = "\\",
	Slash = "/",
	Period = '.',
	Semicolon = ';',
	Colon = ":",
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftShift = "LShift",
	RightShift = "RShift",
	Return = "Enter",
	LeftBracket = "[",
	RightBracket = "]",
	Quote = "'",
	Comma = ",",
	Equals = "=",
	LeftSuper = "Super",
	RightSuper = "Super",
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	Escape = "Esc",
};

function Sealz:GetKeyName(Key: Enum.KeyCode): string
	Key = Key or "None";

	if typeof(Key) == "EnumItem" and Key.EnumType == Enum.UserInputType then
		if Key == Enum.UserInputType.MouseButton1 then
			return "Mouse 1"
		elseif Key == Enum.UserInputType.MouseButton2 then
			return "Mouse 2"
		end
	end;

	if typeof(Key) == "EnumItem" and Sealz.KeyCodeReplace[Key.Name] then
		return Sealz.KeyCodeReplace[Key.Name];
	end

	return (typeof(Key) == "EnumItem" and Key.Name) or Key;
end;

function Sealz:GetTextSize(Label: TextLabel): Vector2
	return TextService:GetTextSize(Label.Text,Label.TextSize,Sealz.Font,Vector2.new(math.huge,math.huge));	
end;

Sealz.GetSliderSize = function(def,min,max)
	return (def - min) / (max - min);
end

Sealz.Parse = function(Value , Numeric)
	if not Value then
		return (Numeric and nil) or "";	
	end;

	if Numeric then
		local out = string.gsub(tostring(Value), '[^0-9.%-]', '')

		if tonumber(out) then
			return tonumber(out);
		end;

		return nil;
	end;

	return Value;
end;

Sealz.FormatDropdown = function(value)
	if typeof(value) == 'table' then
		local data = {};

		for i,v in next , value do
			if typeof(v) == 'boolean' and typeof(i) ~= 'number' then
				data[i] = v;
			else
				data[v] = true;
			end;
		end;

		return data;
	else
		return value;
	end;
end

Sealz.ParseDropdown = function(Data)
	if not Data then return "None" end;

	local Result;

	if typeof(Data) == 'table' then
		if #Data > 0 then
			local x = {};

			for i,v in next , Data do
				table.insert(x , tostring(v))
			end;

			Result = table.concat(x,' , ');

			table.clear(x);
		else
			local x = {};

			for i,v in next , Data do
				if v == true then
					table.insert(x , tostring(i));
				end			
			end;

			Result = table.concat(x,' , ');

			table.clear(x)

			if not Result:byte() then
				Result = 'None';
			end
		end;
	else
		Result = tostring(Data or 'None');
	end;

	return Result;
end;

Sealz.FormatAudioTimer = function(sec: number)
	local hrs , mins , sec = math.round(sec / 3600),math.round((sec % 3600) / 60),math.round(sec % 60);

	return (hrs > 0 and string.format("%02d:%02d:%02d",hrs,mins,sec)) or string.format("%02d:%02d",mins,sec)
end;

Sealz.EmptyFunction = function() end;

-- Window UI
function Sealz:CreateColorPickerWindow(Core)
	local CoreSelf = {};
	local TransManager = Sealz.Transparent();
	local CurrentColor: Color3, Root: Frame = Core.Value , Core.Root;
	local CurrentIndex = Root.ZIndex;

	local ColorHandlerFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIStroke = Instance.new("UIStroke")
	local UIShadow = Instance.new("UIShadow")
	local Saturation = Instance.new("Frame")
	local UIStroke_2 = Instance.new("UIStroke")
	local UICorner_2 = Instance.new("UICorner")
	local BlackFrame = Instance.new("Frame")
	local UICorner_3 = Instance.new("UICorner")
	local UIGradient = Instance.new("UIGradient")
	local ColorFrame = Instance.new("Frame")
	local UICorner_4 = Instance.new("UICorner")
	local UIGradient_2 = Instance.new("UIGradient")
	local CircleMark = Instance.new("Frame")
	local UICorner_5 = Instance.new("UICorner")
	local UIStroke_3 = Instance.new("UIStroke")
	local MapFrame = Instance.new("Frame")
	local UIGradient_3 = Instance.new("UIGradient")
	local UICorner_6 = Instance.new("UICorner")
	local UIStroke_4 = Instance.new("UIStroke")
	local TextInput = Instance.new("Frame")
	local UICorner_7 = Instance.new("UICorner")
	local TextBox = Instance.new("TextBox")
	local UIStroke_5 = Instance.new("UIStroke")
	local MapMarker = Instance.new("Frame")

	MapMarker.Name = "MapMarker"
	MapMarker.Parent = MapFrame
	MapMarker.AnchorPoint = Vector2.new(0.5, 0)
	MapMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MapMarker.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MapMarker.BorderSizePixel = 0
	MapMarker.Position = UDim2.new(0.5, 0, 0, 0)
	MapMarker.Size = UDim2.new(0, 20, 0, 2)
	MapMarker.ZIndex = CurrentIndex + 109;
	TransManager:Add(MapMarker)

	ColorHandlerFrame.Active = true;
	ColorHandlerFrame.Name = "ColorHandlerFrame"
	ColorHandlerFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	ColorHandlerFrame.AnchorPoint = Vector2.new(0.5,0.5)
	ColorHandlerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ColorHandlerFrame.BorderSizePixel = 0
	ColorHandlerFrame.Size = UDim2.new(0, 190, 0, 200)
	ColorHandlerFrame.ZIndex = CurrentIndex + 100;
	ColorHandlerFrame.BackgroundTransparency = 0;

	TransManager:Add(ColorHandlerFrame)
	Sealz:AddVisibleSignal(ColorHandlerFrame,"BackgroundTransparency",0.95,true,Sealz.ScreenGui);

	ColorHandlerFrame.Visible = false;

	UICorner.Parent = ColorHandlerFrame

	UIStroke.Color = Color3.fromRGB(34, 34, 34)
	UIStroke.Parent = ColorHandlerFrame
	TransManager:Add(UIStroke)

	UIShadow.Transparency = 0.500
	UIShadow.BlurRadius = UDim.new(0, 20)
	UIShadow.Parent = ColorHandlerFrame
	TransManager:Add(UIShadow)

	Saturation.Name = "Saturation"
	Saturation.Parent = ColorHandlerFrame
	Saturation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Saturation.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Saturation.BorderSizePixel = 0
	Saturation.Position = UDim2.new(0, 10, 0, 10)
	Saturation.Size = UDim2.new(0, 150, 0, 150)
	Saturation.ZIndex = CurrentIndex + 105;
	TransManager:Add(Saturation)

	UIStroke_2.Color = Color3.fromRGB(34, 34, 34)
	UIStroke_2.Parent = Saturation
	TransManager:Add(UIStroke_2)

	UICorner_2.Parent = Saturation

	BlackFrame.Name = "BlackFrame"
	BlackFrame.Parent = Saturation
	BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	BlackFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlackFrame.BorderSizePixel = 0
	BlackFrame.Size = UDim2.new(1, 0, 1, 0)
	BlackFrame.ZIndex = CurrentIndex + 107;
	TransManager:Add(BlackFrame)

	UICorner_3.Parent = BlackFrame

	UIGradient.Rotation = 90
	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
	UIGradient.Parent = BlackFrame

	ColorFrame.Name = "ColorFrame"
	ColorFrame.Parent = Saturation
	ColorFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
	ColorFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ColorFrame.BorderSizePixel = 0
	ColorFrame.Size = UDim2.new(1, 0, 1, 0)
	ColorFrame.ZIndex = CurrentIndex + 106;
	TransManager:Add(ColorFrame)

	UICorner_4.Parent = ColorFrame

	UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
	UIGradient_2.Parent = ColorFrame

	CircleMark.Name = "CircleMark"
	CircleMark.Parent = Saturation
	CircleMark.AnchorPoint = Vector2.new(0.5, 0.5)
	CircleMark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	CircleMark.BackgroundTransparency = 1.000
	CircleMark.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CircleMark.BorderSizePixel = 0
	CircleMark.Position = UDim2.new(0.5, 0, 0.5, 0)
	CircleMark.Size = UDim2.new(0, 7, 0, 7)
	CircleMark.ZIndex = CurrentIndex + 110;

	UICorner_5.CornerRadius = UDim.new(1, 0)
	UICorner_5.Parent = CircleMark

	UIStroke_3.Color = Color3.fromRGB(255, 255, 255)
	UIStroke_3.Parent = CircleMark
	TransManager:Add(UIStroke_3)

	MapFrame.Name = "MapFrame"
	MapFrame.Parent = ColorHandlerFrame
	MapFrame.AnchorPoint = Vector2.new(1, 0)
	MapFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MapFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MapFrame.BorderSizePixel = 0
	MapFrame.Position = UDim2.new(1, -10, 0, 10)
	MapFrame.Size = UDim2.new(0, 10, 0, 150)
	MapFrame.ZIndex = CurrentIndex + 106;
	TransManager:Add(MapFrame)

	UIGradient_3.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.10, Color3.fromRGB(255, 153, 0)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(203, 255, 0)), ColorSequenceKeypoint.new(0.30, Color3.fromRGB(50, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(0, 255, 102)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 101, 255)), ColorSequenceKeypoint.new(0.70, Color3.fromRGB(50, 0, 255)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(204, 0, 255)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 153)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))}
	UIGradient_3.Rotation = 90
	UIGradient_3.Parent = MapFrame

	UICorner_6.CornerRadius = UDim.new(0, 2)
	UICorner_6.Parent = MapFrame

	UIStroke_4.Color = Color3.fromRGB(34, 34, 34)
	UIStroke_4.Parent = MapFrame
	TransManager:Add(UIStroke_4)

	TextInput.Name = "TextInput"
	TextInput.Parent = ColorHandlerFrame
	TextInput.AnchorPoint = Vector2.new(0.5, 1)
	TextInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	TextInput.BackgroundTransparency = 0.250
	TextInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextInput.BorderSizePixel = 0
	TextInput.ClipsDescendants = true
	TextInput.Position = UDim2.new(0.5, 0, 1, -10)
	TextInput.Size = UDim2.new(1, -20, 0, 20)
	TextInput.ZIndex = CurrentIndex + 110;
	TransManager:Add(TextInput)

	UICorner_7.CornerRadius = UDim.new(0, 5)
	UICorner_7.Parent = TextInput

	TextBox.Parent = TextInput
	TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
	TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.BackgroundTransparency = 1.000
	TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextBox.BorderSizePixel = 0
	TextBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextBox.Size = UDim2.new(1, -5, 1, 0)
	TextBox.ZIndex = CurrentIndex + 111;
	TextBox.ClearTextOnFocus = false
	TextBox.Font = Sealz.Font
	TextBox.Text = "#ffff"
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.TextSize = 10.000
	TransManager:Add(TextBox)

	UIStroke_5.Color = Color3.fromRGB(34, 34, 34)
	UIStroke_5.Parent = TextInput
	TransManager:Add(UIStroke_5)

	TransManager:Fire(false,true);

	CoreSelf.Root = ColorHandlerFrame;

	CoreSelf.H = 1;
	CoreSelf.S = 1;
	CoreSelf.V = 1;

	CoreSelf.TextboxSignal = TextBox.FocusLost:Connect(function()
		local met,hex = pcall(Color3.fromHex,TextBox.Text:gsub('#',''));
		if met and hex then
			CurrentColor = hex;
			CoreSelf.LoadCurrentColor();
			CoreSelf.Render();
		else
			TextBox.Text = "#"..CurrentColor:ToHex();
		end;
	end);

	CoreSelf.SetColor = function(Color)
		CurrentColor = Color;
		CoreSelf.LoadCurrentColor();
		CoreSelf.Render();
	end;

	CoreSelf.LoadCurrentColor = function()
		local H,S,V = CurrentColor:ToHSV();

		CoreSelf.H = H;
		CoreSelf.S = S;
		CoreSelf.V = V;
	end;

	CoreSelf.Render = function()
		CurrentColor = Color3.fromHSV(CoreSelf.H,CoreSelf.S,CoreSelf.V);
		MapMarker.Position = UDim2.fromScale(0.5,CoreSelf.H);
		ColorFrame.BackgroundColor3 = Color3.fromHSV(CoreSelf.H,1,1);
		CircleMark.Position = UDim2.fromScale(CoreSelf.S,1-CoreSelf.V);

		TextBox.Text = "#"..CurrentColor:ToHex();

		if Core.OnRender then
			Core.OnRender(CurrentColor);
		end;
	end;

	CoreSelf.ClearOnOverFrame = function()
		if CoreSelf.OnOverFrame then
			CoreSelf.OnOverFrame:Disconnect();
		end
	end;

	local mainSize = UDim2.new(0, 190, 0, 200);

	local UIScale = Instance.new('UIScale',ColorHandlerFrame);

	CoreSelf.TweenScale = function(bool)
		if bool then
			Sealz:Tween(UIScale,ScaleTween,{
				Scale = 1;
			})
		else
			Sealz:Tween(UIScale,ScaleTween,{
				Scale = 0.1;
			})
		end;
	end;

	CoreSelf.TweenScale(false);

	CoreSelf.Wake = function(bool)
		CoreSelf.ClearOnOverFrame();

		TransManager:Fire(bool);


		if bool then

			CoreSelf.TweenScale(true);

			ColorHandlerFrame.Position = UDim2.fromOffset(Root.AbsolutePosition.X + (Root.AbsoluteSize.X / 2),Root.AbsolutePosition.Y + (Root.AbsoluteSize.Y / 2) + Sealz.InsetSize);

			CoreSelf.OnOverFrame = UserInputService.InputBegan:Connect(Sealz:OnOverFrame(ColorHandlerFrame,function()
				CoreSelf.ClearOnOverFrame();

				CoreSelf.Wake(false);
			end));
		else
			CoreSelf.TweenScale(false);
		end;
	end;

	CoreSelf.IsHolding = false;
	CoreSelf.Wait = task.wait;

	CoreSelf.Signals = {
		ColorHandlerFrame.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				CoreSelf.IsHolding = true;
			end
		end),
		ColorHandlerFrame.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				CoreSelf.IsHolding = false;
			end
		end),
		MapFrame.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				CoreSelf.IsHolding = true;

				while (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or CoreSelf.IsHolding) do CoreSelf.Wait()
					local ColorY = MapFrame.AbsolutePosition.Y
					local ColorYM = ColorY + MapFrame.AbsoluteSize.Y;
					local Value = math.clamp(Mouse.Y, ColorY, ColorYM)
					local Code = ((Value - ColorY) / (ColorYM - ColorY));

					CoreSelf.H = Code;
					CoreSelf.Render();
				end;
			end
		end),
		Saturation.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				CoreSelf.IsHolding = true;

				while (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or CoreSelf.IsHolding) do CoreSelf.Wait()
					local PosX = Saturation.AbsolutePosition.X;
					local ScaleX = PosX + Saturation.AbsoluteSize.X;
					local Value, PosY = math.clamp(Mouse.X, PosX, ScaleX), Saturation.AbsolutePosition.Y;
					local ScaleY = PosY + Saturation.AbsoluteSize.Y;
					local Vals = math.clamp(Mouse.Y, PosY, ScaleY);

					CoreSelf.S = (Value - PosX) / (ScaleX - PosX);
					CoreSelf.V = (1 - ((Vals - PosY) / (ScaleY - PosY)));
					CoreSelf.Render();
				end;
			end
		end),
	};

	CoreSelf.LoadCurrentColor();
	CoreSelf.Render();

	return CoreSelf;
end;

function Sealz:CreateDropdown(Core)
	local SizeX: number = Core.Size;
	local Root: Frame = Core.Root;
	local ZIndex = Root.ZIndex;

	local DropdownSelf = {};
	local TransManager = Sealz.Transparent();
	local DropdownHandlerFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIStroke = Instance.new("UIStroke")
	local UIShadow = Instance.new("UIShadow")
	local TextInput = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local TextBox = Instance.new("TextBox")
	local UIStroke_2 = Instance.new("UIStroke")
	local ScrollingFrame = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local UICorner_3 = Instance.new("UICorner")
	local UIStroke_3 = Instance.new("UIStroke")

	DropdownHandlerFrame.Name = "DropdownHandlerFrame"
	DropdownHandlerFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	DropdownHandlerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DropdownHandlerFrame.BorderSizePixel = 0
	DropdownHandlerFrame.AnchorPoint = Vector2.new(0.5,0.5);
	DropdownHandlerFrame.ZIndex = ZIndex + 100

	TransManager:Add(DropdownHandlerFrame)
	Sealz:AddVisibleSignal(DropdownHandlerFrame,"BackgroundTransparency",0.95,true,Sealz.ScreenGui);

	UICorner.Parent = DropdownHandlerFrame

	UIStroke.Color = Color3.fromRGB(34, 34, 34)
	UIStroke.Parent = DropdownHandlerFrame
	TransManager:Add(UIStroke)
	UIShadow.Transparency = 0.500
	UIShadow.BlurRadius = UDim.new(0, 20)
	UIShadow.Parent = DropdownHandlerFrame
	TransManager:Add(UIShadow)
	TextInput.Name = "TextInput"
	TextInput.Parent = DropdownHandlerFrame
	TextInput.AnchorPoint = Vector2.new(0.5, 0)
	TextInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	TextInput.BackgroundTransparency = 0.250
	TextInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextInput.BorderSizePixel = 0
	TextInput.ClipsDescendants = true
	TextInput.Position = UDim2.new(0.5, 0, 0, 10)
	TextInput.Size = UDim2.new(1, -20, 0, 20)
	TextInput.ZIndex = ZIndex + 107
	TransManager:Add(TextInput)
	UICorner_2.CornerRadius = UDim.new(0, 5)
	UICorner_2.Parent = TextInput

	TextBox.Parent = TextInput
	TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
	TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.BackgroundTransparency = 1.000
	TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextBox.BorderSizePixel = 0
	TextBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextBox.Size = UDim2.new(1, -5, 1, 0)
	TextBox.ZIndex = ZIndex + 108
	TextBox.ClearTextOnFocus = false
	TextBox.Font = Sealz.Font
	TextBox.PlaceholderText = "Search"
	TextBox.Text = ""
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.TextSize = 10.000
	TransManager:Add(TextBox)
	UIStroke_2.Color = Color3.fromRGB(34, 34, 34)
	UIStroke_2.Parent = TextInput
	TransManager:Add(UIStroke_2)
	ScrollingFrame.Parent = DropdownHandlerFrame
	ScrollingFrame.Active = true
	ScrollingFrame.AnchorPoint = Vector2.new(0.5, 0)
	ScrollingFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	ScrollingFrame.BackgroundTransparency = 0.250
	ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScrollingFrame.BorderSizePixel = 0
	ScrollingFrame.Position = UDim2.new(0.5, 0, 0, 40)
	ScrollingFrame.Size = UDim2.new(1, -20, 1, -50)
	ScrollingFrame.ZIndex = ZIndex + 109
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
	ScrollingFrame.ScrollBarThickness = 1
	ScrollingFrame.ScrollBarImageColor3 = Sealz.AccentColor
	TransManager:Add(ScrollingFrame);

	UIListLayout.Parent = ScrollingFrame
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	Sealz:SET_SCROLLING(ScrollingFrame,UIListLayout)

	UICorner_3.CornerRadius = UDim.new(0, 5)
	UICorner_3.Parent = ScrollingFrame

	UIStroke_3.Color = Color3.fromRGB(34, 34, 34)
	UIStroke_3.Parent = ScrollingFrame
	TransManager:Add(UIStroke_3)

	TransManager:Fire(false,true)

	DropdownSelf.ClearOnOverFrame = function()
		if DropdownSelf.RuntimeThread then
			task.cancel(DropdownSelf.RuntimeThread);
		end;

		if DropdownSelf.OnOverFrame then
			DropdownSelf.OnOverFrame:Disconnect()
		end
	end;
	
	DropdownSelf.SetSearchBar = function()
		local currentItem = #ScrollingFrame:GetChildren() - 3;
		
		if currentItem > 10 then
			DropdownSelf.SearchEnabled = true;
			
			TextBox.Text = "";
			TextBox.Visible = true;
			ScrollingFrame.Position = UDim2.new(0.5, 0, 0, 40)
			ScrollingFrame.Size = UDim2.new(1, -20, 1, -50)
		else
			DropdownSelf.SearchEnabled = false;
			
			TextBox.Text = "";
			TextBox.Visible = false;
			ScrollingFrame.Position = UDim2.new(0.5,0,0,10);
			ScrollingFrame.Size = UDim2.new(1,-20,1,-20);
		end;
	end;

	DropdownSelf.ItemTransManager = Sealz.Transparent();

	DropdownSelf.SeachSignal = TextBox:GetPropertyChangedSignal('Text'):Connect(function()
		if TextBox.Text:byte() then
			for i,v in next , ScrollingFrame:GetChildren() do
				if v:IsA('Frame') then
					local content: string = v:GetAttribute('content');

					if string.find(content:lower(),TextBox.Text:lower(),1,true) then
						v.Visible = true;
					else
						v.Visible = false;
					end;
				end
			end;
		else
			for i,v in next , ScrollingFrame:GetChildren() do
				if v:IsA('Frame') then
					v.Visible = true;
				end
			end;
		end;
	end);

	local uiscale = Instance.new('UIScale',DropdownHandlerFrame);

	DropdownSelf.ScaleTween = function(bool)
		if bool then
			Sealz:Tween(uiscale,ScaleTween,{
				Scale = 1
			})
		else
			Sealz:Tween(uiscale,ScaleTween,{
				Scale = 0.5
			})
		end;
	end;

	DropdownSelf.ScaleTween(false);

	DropdownSelf.Visible = false;
	DropdownSelf.Wake = function()
		DropdownSelf.ClearOnOverFrame();

		DropdownSelf.Visible = true;

		DropdownSelf.SetSearchBar();

		TransManager:Fire(true);

		DropdownSelf.ItemTransManager:Fire(true);

		DropdownSelf.ScaleTween(true)

		DropdownSelf.RuntimeThread = task.spawn(function()
			while DropdownSelf.Visible do task.wait()
				local Extra = (DropdownSelf.SearchEnabled and 50) or 25;
				local SizeY = math.clamp(UIListLayout.AbsoluteContentSize.Y + Extra, 25,255);


				Sealz:Tween(DropdownHandlerFrame,BasedTween,{
					Size = UDim2.fromOffset(SizeX,SizeY);
				})
				--DropdownHandlerFrame.Size = UDim2.fromOffset(SizeX,SizeY);
				DropdownHandlerFrame.Position = UDim2.fromOffset(Root.AbsolutePosition.X + (Root.AbsoluteSize.X / 2),Root.AbsolutePosition.Y + (Root.AbsoluteSize.Y / 2) + Sealz.InsetSize);
			end;
		end);

		DropdownSelf.OnOverFrame = UserInputService.InputBegan:Connect(Sealz:OnOverFrame(DropdownHandlerFrame,function()
			DropdownSelf.Visible = false;

			DropdownSelf.ClearOnOverFrame();
			TransManager:Fire(false);
			DropdownSelf.ScaleTween(false);
			DropdownSelf.ItemTransManager:Fire(false);
		end))
	end;

	DropdownSelf.ItemSignals = {};

	DropdownSelf.Clear = function()
		if DropdownSelf.ItemTransManager then
			table.clear(DropdownSelf.ItemTransManager);
			DropdownSelf.ItemTransManager = nil;
		end;

		DropdownSelf.ItemTransManager = Sealz.Transparent();

		for i,v in next , ScrollingFrame:GetChildren() do
			if v:IsA('Frame') then
				v:Destroy();
			end
		end;

		for i,v in next , DropdownSelf.ItemSignals do
			v:Disconnect();
		end;

		table.clear(DropdownSelf.ItemSignals);
	end;

	DropdownSelf.DrawImage = function(Image,Text,Desc)
		local ImageTextFrame = Instance.new("Frame")
		local TextLabel = Instance.new("TextLabel")
		local UICorner = Instance.new("UICorner")
		local LineFrame = Instance.new("Frame")
		local ImageLabel = Instance.new("ImageLabel")
		local UICorner_2 = Instance.new("UICorner")
		local SecLabel = Instance.new("TextLabel")

		ImageTextFrame.Name = "ImageTextFrame"
		ImageTextFrame.Parent = ScrollingFrame
		ImageTextFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		ImageTextFrame.BackgroundTransparency = 1.000
		ImageTextFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageTextFrame.BorderSizePixel = 0
		ImageTextFrame.ClipsDescendants = true
		ImageTextFrame.Size = UDim2.new(1, 0, 0, 70)
		ImageTextFrame.ZIndex = ZIndex + 120
		ImageTextFrame:SetAttribute("content",Text..' '..Desc);

		TextLabel.Parent = ImageTextFrame
		TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextLabel.BorderSizePixel = 0
		TextLabel.Position = UDim2.new(0, 85, 0, 5)
		TextLabel.Size = UDim2.new(0, 200, 0, 15)
		TextLabel.ZIndex = ZIndex + 121
		TextLabel.Font = Sealz.Font
		TextLabel.Text = Text
		TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.TextSize = 12.000
		TextLabel.TextTransparency = 0.150
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		local LabelRef = DropdownSelf.ItemTransManager:Add(TextLabel)

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = ImageTextFrame

		LineFrame.Name = "LineFrame"
		LineFrame.Parent = ImageTextFrame
		LineFrame.AnchorPoint = Vector2.new(0.5, 1)
		LineFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
		LineFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LineFrame.BorderSizePixel = 0
		LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
		LineFrame.Size = UDim2.new(1, -1, 0, 1)
		LineFrame.ZIndex = ZIndex + 125
		DropdownSelf.ItemTransManager:Add(LineFrame)

		ImageLabel.Parent = ImageTextFrame
		ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
		ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel.BackgroundTransparency = 1.000
		ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel.BorderSizePixel = 0
		ImageLabel.Position = UDim2.new(0, 10, 0.5, 0)
		ImageLabel.Size = UDim2.new(0, 65, 0, 65)
		ImageLabel.ZIndex = ZIndex + 123
		ImageLabel.Image = Image
		ImageLabel.ScaleType = Enum.ScaleType.Crop
		local ImageRef = DropdownSelf.ItemTransManager:Add(ImageLabel)

		UICorner_2.Parent = ImageLabel

		SecLabel.Name = "SecLabel"
		SecLabel.Parent = ImageTextFrame
		SecLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SecLabel.BackgroundTransparency = 1.000
		SecLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SecLabel.BorderSizePixel = 0
		SecLabel.Position = UDim2.new(0, 85, 0, 20)
		SecLabel.Size = UDim2.new(1, -100, 1, 0)
		SecLabel.ZIndex = ZIndex + 122
		SecLabel.Font = Sealz.Font
		SecLabel.Text = Desc
		SecLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		SecLabel.TextSize = 11.000
		SecLabel.TextTransparency = 0.500
		SecLabel.TextWrapped = true
		SecLabel.TextXAlignment = Enum.TextXAlignment.Left
		SecLabel.TextYAlignment = Enum.TextYAlignment.Top
		local SecRef = DropdownSelf.ItemTransManager:Add(SecLabel)

		return {
			on = function()
				Sealz:Tween(TextLabel,BasedTween,{
					TextTransparency = 0.150,
					TextColor3 = Sealz.AccentColor
				})

				Sealz:Tween(ImageLabel,BasedTween,{
					ImageTransparency = 0
				})

				Sealz:Tween(SecLabel,BasedTween,{
					TextTransparency = 0.5,
					TextColor3 = Sealz.AccentColor
				})

				ImageRef("ImageTransparency",0)
				SecRef("TextTransparency",0.5)
				LabelRef("TextTransparency",0.15)
			end,
			off = function()
				Sealz:Tween(TextLabel,BasedTween,{
					TextTransparency = 0.5,
					TextColor3 = Color3.fromRGB(255, 255, 255)
				})

				Sealz:Tween(ImageLabel,BasedTween,{
					ImageTransparency = 0.5
				})

				Sealz:Tween(SecLabel,BasedTween,{
					TextTransparency = 0.75,
					TextColor3 = Color3.fromRGB(255, 255, 255)
				})

				ImageRef("ImageTransparency",0.5)
				SecRef("TextTransparency",0.75)
				LabelRef("TextTransparency",0.5)
			end,
			root = ImageTextFrame
		}
	end;

	DropdownSelf.DrawText = function(Text)
		local TextFrame = Instance.new("Frame")
		local TextLabel = Instance.new("TextLabel")
		local UICorner = Instance.new("UICorner")
		local LineFrame = Instance.new("Frame")

		TextFrame.Name = "TextFrame"
		TextFrame.Parent = ScrollingFrame
		TextFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		TextFrame.BackgroundTransparency = 1.000
		TextFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextFrame.BorderSizePixel = 0
		TextFrame.Size = UDim2.new(1, 0, 0, 20)
		TextFrame.ZIndex = ZIndex + 120
		TextFrame:SetAttribute("content",Text);

		DropdownSelf.ItemTransManager:Add(TextFrame)
		TextLabel.Parent = TextFrame
		TextLabel.AnchorPoint = Vector2.new(0, 0.5)
		TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextLabel.BorderSizePixel = 0
		TextLabel.Position = UDim2.new(0, 8, 0.5, 0)
		TextLabel.Size = UDim2.new(0, 200, 0, 15)
		TextLabel.ZIndex = ZIndex + 121
		TextLabel.Font = Sealz.Font
		TextLabel.Text = Text
		TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.TextSize = 11.000
		TextLabel.TextTransparency = 0.150
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left

		local rd = DropdownSelf.ItemTransManager:Add(TextLabel)

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = TextFrame

		LineFrame.Name = "LineFrame"
		LineFrame.Parent = TextFrame
		LineFrame.AnchorPoint = Vector2.new(0.5, 1)
		LineFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
		LineFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LineFrame.BorderSizePixel = 0
		LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
		LineFrame.Size = UDim2.new(1, -1, 0, 1)
		LineFrame.ZIndex = ZIndex + 125

		DropdownSelf.ItemTransManager:Add(LineFrame);

		return {
			on = function()
				Sealz:Tween(TextLabel,BasedTween,{
					TextTransparency = 0.150,
					TextColor3 = Sealz.AccentColor
				})

				rd("TextTransparency",0.15)
			end,
			off = function()
				Sealz:Tween(TextLabel,BasedTween,{
					TextTransparency = 0.5,
					TextColor3 = Color3.fromRGB(255, 255, 255)
				})
				rd("TextTransparency",0.5)
			end,
			root = TextFrame
		}
	end;

	return DropdownSelf;
end;

function Sealz:CreateBlockWindow(Core)
	local Root: Frame = Core.Root;
	local IndexLayer = Root.ZIndex;

	local BlockSelf = {};
	local TransManager = Sealz.Transparent();

	BlockSelf.Signal = CreateSignal(false);

	local BlockHandlerFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIStroke = Instance.new("UIStroke")
	local UIShadow = Instance.new("UIShadow")
	local UIListLayout = Instance.new("UIListLayout")

	BlockHandlerFrame.Name = "BlockHandlerFrame"
	BlockHandlerFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	BlockHandlerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockHandlerFrame.BorderSizePixel = 0
	BlockHandlerFrame.Size = UDim2.new(0, 175, 0, 50)
	BlockHandlerFrame.ZIndex = IndexLayer + 200
	BlockHandlerFrame.ClipsDescendants = true;
	BlockHandlerFrame.AnchorPoint = Vector2.new(0,0);

	TransManager:Add(BlockHandlerFrame)
	Sealz:AddVisibleSignal(BlockHandlerFrame,'BackgroundTransparency',0.95,true,Sealz.ScreenGui);

	UICorner.Parent = BlockHandlerFrame

	UIStroke.Color = Color3.fromRGB(34, 34, 34)
	UIStroke.Parent = BlockHandlerFrame
	TransManager:Add(UIStroke)

	UIShadow.Transparency = 0.500
	UIShadow.BlurRadius = UDim.new(0, 20)
	UIShadow.Parent = BlockHandlerFrame
	TransManager:Add(UIShadow)

	UIListLayout.Parent = BlockHandlerFrame
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	TransManager:Fire(false,true);
	
	local UIScale = Instance.new('UIScale',BlockHandlerFrame);
	
	UIScale.Scale = 0;
	
	BlockSelf.SetSize = function()
		BlockHandlerFrame.Size = UDim2.new(0, 250, 0, UIListLayout.AbsoluteContentSize.Y)
	end;
	
	UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(BlockSelf.SetSize);

	BlockSelf.ClearOnOverFrame = function()
		if BlockSelf.OnOverFrame then
			BlockSelf.OnOverFrame:Disconnect();
		end;
	end;

	BlockSelf.Wake = function()
		Sealz:Tween(UIScale,ScaleTween,{
			Scale = 1
		});
		
		BlockSelf.ClearOnOverFrame();

		TransManager:Fire(true);

		BlockSelf.Signal:Fire(true);
		
		BlockHandlerFrame.Position = UDim2.fromOffset(Root.AbsolutePosition.X + (Root.AbsoluteSize.X / 2) + 15, Root.AbsolutePosition.Y + (Root.AbsoluteSize.Y / 2) + Sealz.InsetSize)

		BlockSelf.OnOverFrame = UserInputService.InputBegan:Connect(Sealz:OnOverFrame(BlockHandlerFrame,function()
			Sealz:Tween(UIScale,ScaleTween,{
				Scale = 0
			});
			
			BlockSelf.ClearOnOverFrame();

			BlockSelf.Signal:Fire(false);
			TransManager:Fire(false);
		end));
	end;

	local Regisiter = Sealz:Regisiter(BlockHandlerFrame,BlockSelf.Signal);

	Regisiter.Root = BlockSelf;

	function Regisiter:Wake()
		BlockSelf.Wake();
	end;

	return Regisiter;
end;

-- About panel (script info). Styled to match the Sealz UI.
-- Usage: Sealz:CreateAbout({ Root = settingsFrame, Version = "...", Author = "...",
--          Status = "Работает", Updated = "27.08.2026", Discord = "invite", GitHub = "url" })
-- Returns AboutSelf with .Root (the panel) so the caller can set LayoutOrder / position.
function Sealz:CreateAbout(Core)
	Core = Sealz:Format(Core, {
		Version = "?",
		Author = "?",
		Status = "Работает",
		Updated = "?",
		Discord = "",
		GitHub = "",
	});

	local Parent = Core.Root or Sealz.ScreenGui
	if typeof(Parent) == "table" then
		-- Accept a Sealz object (e.g. a tool returned by Window:AddTool) and
		-- resolve it to the actual GUI frame it renders into.
		Parent = Parent.Content or Parent.Root or Parent.Frame or Parent
	end
	if typeof(Parent) ~= "Instance" then
		Parent = Sealz.ScreenGui
	end
	local Root: Frame = Parent
	local IndexLayer = 10
	if typeof(Root) == "Instance" then
		local ok, z = pcall(function() return Root.ZIndex end)
		if ok and typeof(z) == "number" then
			IndexLayer = z
		end
	end

	local AboutSelf = {};
	local TransManager = Sealz.Transparent();

	-- Native Sealz palette, minimal
	local C_BG      = Color3.fromRGB(24, 24, 24)
	local C_BORDER  = Color3.fromRGB(34, 34, 34)
	local C_DIVIDER = Color3.fromRGB(34, 34, 34)
	local C_VALUE   = Color3.fromRGB(255, 255, 255)
	local C_GREEN   = Color3.fromRGB(46, 204, 113)
	local C_BTN     = Sealz.AccentColor

	-- 2px lower than the top border of the settings list
	local Spacer = Instance.new("Frame")
	Spacer.Name = "AboutSpacer"
	Spacer.BackgroundTransparency = 1
	Spacer.BorderSizePixel = 0
	Spacer.Size = UDim2.new(1, 0, 0, 2)
	Spacer.ZIndex = IndexLayer
	Spacer.LayoutOrder = -1000
	Spacer.Parent = Root

	local Panel = Instance.new("Frame")
	local PCorner = Instance.new("UICorner")
	local PStroke = Instance.new("UIStroke")
	local PLayout = Instance.new("UIListLayout")
	local Title = Instance.new("TextLabel")

	Panel.Name = "AboutPanel"
	Panel.BackgroundColor3 = C_BG
	Panel.BorderSizePixel = 0
	Panel.AutomaticSize = Enum.AutomaticSize.Y
	Panel.Size = UDim2.new(1, -14, 0, 0)
	Panel.ZIndex = IndexLayer
	Panel.LayoutOrder = -999
	Panel.Parent = Root

	TransManager:Add(Panel)
	PCorner.CornerRadius = UDim.new(0, 4)
	PCorner.Parent = Panel

	PStroke.Color = C_BORDER
	PStroke.Thickness = 1
	PStroke.Parent = Panel
	TransManager:Add(PStroke)

	Title.Name = "Title"
	Title.Parent = Panel
	Title.BackgroundTransparency = 1
	Title.BorderSizePixel = 0
	Title.Size = UDim2.new(1, 0, 0, 15)
	Title.ZIndex = IndexLayer + 1
	Title.Font = Sealz.Font
	Title.Text = "О скрипте"
	Title.TextColor3 = C_VALUE
	Title.TextSize = 11
	Title.TextXAlignment = Enum.TextXAlignment.Center
	Title.TextYAlignment = Enum.TextYAlignment.Center
	TransManager:Add(Title)

	PLayout.Parent = Panel
	PLayout.SortOrder = Enum.SortOrder.LayoutOrder
	PLayout.Padding = UDim.new(0, 3)
	PLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	PLayout.FillDirection = Enum.FillDirection.Vertical

	local rows = {
		{ "Версия:", Core.Version, nil },
		{ "Автор:", Core.Author, nil },
		{ "Статус:", Core.Status, Color3.fromRGB(46, 204, 113) },
		{ "Обновлено:", Core.Updated, nil },
	};

	for i, v in next, rows do
		local label, value, color = v[1], v[2], v[3]

		local Row = Instance.new("Frame")
		Row.Name = "Row"
		Row.BackgroundTransparency = 1
		Row.BorderSizePixel = 0
		Row.Size = UDim2.new(1, 0, 0, 19)
		Row.ZIndex = IndexLayer + 1
		Row.LayoutOrder = i
		Row.Parent = Panel

		local L = Instance.new("TextLabel")
		L.Parent = Row
		L.BackgroundTransparency = 1
		L.BorderSizePixel = 0
		L.Size = UDim2.new(0.5, 0, 1, 0)
		L.ZIndex = IndexLayer + 2
		L.Font = Sealz.SecondFont
		L.Text = label
		L.TextColor3 = C_VALUE
		L.TextTransparency = 0.5
		L.TextSize = 10
		L.TextXAlignment = Enum.TextXAlignment.Left
		L.TextYAlignment = Enum.TextYAlignment.Center
		TransManager:Add(L)

		local V = Instance.new("TextLabel")
		V.Parent = Row
		V.BackgroundTransparency = 1
		V.BorderSizePixel = 0
		V.Position = UDim2.new(0.5, 0, 0, 0)
		V.Size = UDim2.new(0.5, 0, 1, 0)
		V.ZIndex = IndexLayer + 2
		V.Font = Sealz.Font
		V.Text = value
		V.TextColor3 = color or C_VALUE
		V.TextSize = 10
		V.TextXAlignment = Enum.TextXAlignment.Right
		V.TextYAlignment = Enum.TextYAlignment.Center
		TransManager:Add(V)

		if i < #rows then
			local Div = Instance.new("Frame")
			Div.Name = "Divider"
			Div.AnchorPoint = Vector2.new(0.5, 1)
			Div.BackgroundColor3 = C_DIVIDER
			Div.BorderSizePixel = 0
			Div.Position = UDim2.new(0.5, 0, 1, 0)
			Div.Size = UDim2.new(1, 0, 0, 1)
			Div.ZIndex = IndexLayer + 1
			Div.Parent = Row
			TransManager:Add(Div)
		end
	end

	local Social = Instance.new("Frame")
	Social.Name = "Social"
	Social.BackgroundTransparency = 1
	Social.BorderSizePixel = 0
	Social.AutomaticSize = Enum.AutomaticSize.Y
	Social.Size = UDim2.new(1, -2, 0, 0)
	Social.ZIndex = IndexLayer + 1
	Social.LayoutOrder = #rows + 2
	Social.Parent = Panel

	local SLayout = Instance.new("UIListLayout")
	SLayout.Parent = Social
	SLayout.FillDirection = Enum.FillDirection.Horizontal
	SLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SLayout.Padding = UDim.new(0, 1)

	local makeBtn = function(name, link)
		local Btn = Instance.new("TextButton")
		Btn.Name = name
		Btn.BackgroundColor3 = C_BTN
		Btn.BackgroundTransparency = 0.5
		Btn.BorderSizePixel = 0
		Btn.Size = UDim2.new(0.5, -0.5, 0, 19)
		Btn.ZIndex = IndexLayer + 2
		Btn.Font = Sealz.Font
		Btn.Text = name
		Btn.TextColor3 = C_VALUE
		Btn.TextSize = 10
		Btn.Parent = Social

		local BC = Instance.new("UICorner")
		BC.CornerRadius = UDim.new(0, 4)
		BC.Parent = Btn

		TransManager:Add(Btn)
		Sealz:AddHoverSignal(Btn, "BackgroundTransparency", 0.25, 0.5)

		Btn.Activated:Connect(function()
			if link and link ~= "" then
				pcall(function()
					if setclipboard then setclipboard(link) end
				end)

				local orig = Btn.Text
				Btn.Text = "Скопировано!"

				task.delay(1, function()
					if Btn and Btn.Parent then
						Btn.Text = orig
					end
				end)
			end
		end)

		return Btn
	end

	makeBtn("Discord", Core.Discord)
	makeBtn("GitHub", Core.GitHub)

	AboutSelf.Root = Panel
	AboutSelf.TransManager = TransManager

	return AboutSelf
end;

-- Element & Inputs
function Sealz:CreateInputs(UI: Frame , Signal)
	local IndexLayer = UI.ZIndex;
	local Inputs = {};

	Inputs.set_layout = function(ITEM: Frame)
		ITEM.LayoutOrder = -(#UI:GetChildren() + 1);
	end;

	function Inputs:AddButton(Config)
		Config = Sealz:Format(Config,{
			Name = "Button",
			Icon = false,
			Callback = Sealz.EmptyFunction,
		});

		local ButtonSelf = {};
		local TransManager = Sealz.Transparent();

		local ButtonInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local Button = Instance.new("TextButton")

		Inputs.set_layout(ButtonInput);

		ButtonInput.Name = "ButtonInput"
		ButtonInput.Parent = UI
		ButtonInput.BackgroundColor3 = Sealz.AccentColor
		ButtonInput.BackgroundTransparency = 0.500
		ButtonInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ButtonInput.BorderSizePixel = 0
		ButtonInput.Size = UDim2.new(0, 100, 0, 20)
		ButtonInput.ZIndex = IndexLayer + 1

		TransManager:Add(ButtonInput)
		Sealz:AddHoverSignal(ButtonInput , "BackgroundTransparency" , 0.25,0.5);

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = ButtonInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = ButtonInput
		TransManager:Add(UIShadow)

		Button.Name = "Button"
		Button.Parent = ButtonInput
		Button.AnchorPoint = Vector2.new(0.5, 0.5)
		Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundTransparency = 1.000
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BorderSizePixel = 0
		Button.Position = UDim2.new(0.5, 0, 0.5, 0)
		Button.Size = UDim2.new(1, 0, 1, 0)
		Button.ZIndex = IndexLayer + 2;

		if Config.Icon then
			Button.FontFace = Sealz.Icons;
			Button.Text = Config.Name
		else
			Button.Font = Sealz.Font
			Button.Text = Config.Name
		end;

		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.TextSize = 11.000
		Button.TextTransparency = 0.500;
		TransManager:Add(Button)

		TransManager:Fire(Signal:Get(),true);

		local IconSize = Vector2.new(5,0);
		ButtonSelf.Update = function()
			local size = (Config.Icon and IconSize) or Sealz:GetTextSize(Button);

			ButtonInput.Size = UDim2.new(0, size.X + 25, 0, 20)
		end;

		function ButtonSelf:SetText(new)
			Button.Text = new;

			ButtonSelf.Update();
		end;


		ButtonSelf.Activated = Button.Activated:Connect(function(...)
			SealzTry(Config.Name or "Button", Config.Callback, ...);
		end)
		ButtonSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		ButtonSelf.Update();

		return ButtonSelf;
	end;

	function Inputs:AddToggle(Config)
		Config = Sealz:Format(Config,{
			Default = false,
			Callback = Sealz.EmptyFunction,
			--Flag = "idx",
		});
		local ToggleSelf = {
			Value = Config.Default
		};

		local TransManager = Sealz.Transparent();

		local ToggleInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Circle = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")

		Inputs.set_layout(ToggleInput);

		ToggleInput.Name = "ToggleInput"
		ToggleInput.Parent = UI
		ToggleInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		ToggleInput.BackgroundTransparency = 0.200
		ToggleInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ToggleInput.BorderSizePixel = 0
		ToggleInput.Size = UDim2.new(0, 40, 0, 20)
		ToggleInput.ZIndex = IndexLayer + 1
		TransManager:Add(ToggleInput)

		UICorner.CornerRadius = UDim.new(1, 0)
		UICorner.Parent = ToggleInput

		Circle.Name = "Circle"
		Circle.Parent = ToggleInput
		Circle.AnchorPoint = Vector2.new(0.5, 0.5)
		Circle.BackgroundColor3 = Sealz.AccentColor
		Circle.BackgroundTransparency = 0.500
		Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Circle.BorderSizePixel = 0
		Circle.Position = UDim2.new(0.275000006, 0, 0.5, 0)
		Circle.Size = UDim2.new(0.75, 0, 0.75, 0)
		Circle.SizeConstraint = Enum.SizeConstraint.RelativeYY
		Circle.ZIndex = IndexLayer + 2
		local circle = TransManager:Add(Circle)
		UICorner_2.CornerRadius = UDim.new(1, 0)
		UICorner_2.Parent = Circle

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = ToggleInput
		TransManager:Add(UIShadow)

		TransManager:Fire(Signal:Get(),true);

		ToggleSelf.Root = ToggleInput
		ToggleSelf.OnChanged = function(bool)
			if ToggleSelf.Value then
				Sealz:Tween(Circle , BasedTween , {
					BackgroundTransparency = 0.25,
					Position = UDim2.fromScale(0.725,0.5),
					BackgroundColor3 = Sealz.AccentColor
				})

				Sealz:Tween(ToggleInput , BasedTween , {
					BackgroundColor3 = Color3.fromRGB(43, 43, 43)
				})

				circle("BackgroundTransparency",0.25)
			else

				Sealz:Tween(Circle , BasedTween , {
					BackgroundTransparency = 0.5,
					Position = UDim2.fromScale(0.275,0.5),
					BackgroundColor3 = Color3.fromRGB(41, 41, 41)
				})

				Sealz:Tween(ToggleInput , BasedTween , {
					BackgroundColor3 = Color3.fromRGB(33, 33, 33)
				})

				circle("BackgroundTransparency",0.5)
			end;
		end;

		ToggleSelf.OnChanged(ToggleSelf.Value)

		ToggleSelf.Activated = Sealz:AddInput(ToggleInput,function()
			ToggleSelf.Value = not ToggleSelf.Value;

			ToggleSelf.OnChanged(ToggleSelf.Value);

			Config.Callback(ToggleSelf.Value)
		end);

		ToggleSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		function ToggleSelf:SetValue(a)
			ToggleSelf.Value = a;

			ToggleSelf.OnChanged(ToggleSelf.Value);

			Config.Callback(ToggleSelf.Value)
		end;

		function ToggleSelf:GetValue()
			return ToggleSelf.Value;
		end;

		function ToggleSelf:AutoKeybind(Default: Enum.KeyCode, Type: string, Enabled: boolean)
			local GlobalDefault,GlobalType,GlobalEnabled = Default,Type,Enabled;

			local KeybindOpt = Sealz:CreateBlockWindow(ToggleSelf);
			local FlagEnabled = Config.Flag and Config.Flag.."AutoBindx0Enabledx0";
			local FlagKeybind = Config.Flag and Config.Flag.."AutoBindx0Keyx0";
			local FlagType = Config.Flag and Config.Flag.."AutoBindx0Typex0";

			KeybindOpt:AddLabel("Enabled"):AddToggle({
				Default = GlobalEnabled,
				Flag = FlagEnabled,
				Callback = function(Value)
					GlobalEnabled = Value;
				end,
			});

			KeybindOpt:AddLabel("Key"):AddKeybind({
				Default = GlobalDefault,
				Flag = FlagKeybind,
				Callback = function(Value)
					GlobalDefault = Value;
				end,
			});

			KeybindOpt:AddLabel("Type"):AddDropdown({
				Default = GlobalType,
				Flag = FlagType,
				Values = {"Hold","Toggle"},
				Callback = function(Value)
					GlobalType = Value;
				end,
			});

			local Lib = {};

			Lib.Activated = false;

			Lib.Signals = {
				UserInputService.InputBegan:Connect(function(Input)
					if GlobalEnabled then
						if Input.KeyCode == GlobalDefault or Input.UserInputType == GlobalDefault then
							if GlobalType == "Toggle" then
								Lib.Activated = not Lib.Activated;
							else
								Lib.Activated = true;
							end;
						end;
					end;

					if Input.UserInputType == Enum.UserInputType.MouseButton2 then
						if Sealz:IsMouseOverFrame(ToggleInput) then
							KeybindOpt:Wake();
						end;
					end;
				end),

				UserInputService.InputEnded:Connect(function(Input)
					if Input.KeyCode == GlobalDefault or Input.UserInputType == GlobalDefault then
						if GlobalType == "Hold" then
							Lib.Activated = false;
						end;
					end;
				end)
			};

			function Lib:IsActive()
				return GlobalEnabled and Lib.Activated;
			end;

			return Lib;
		end;

		Sealz:AddFlag(Config.Flag,ToggleSelf);

		return ToggleSelf;
	end;

	function Inputs:AddSlider(Config)
		Config = Sealz:Format(Config , {
			-- Flag = "idx",
			Min = 0,
			Max = 100,
			Default = 50,
			Type = "",
			Rounding = 0,
			Size = 100,
			Nums = {},
			Callback = Sealz.EmptyFunction,
		});

		local SliderSelf = {
			Value = Config.Default
		};
		local TransManager = Sealz.Transparent();
		local SliderInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local SlideFrame = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local SlideIndicator = Instance.new("TextBox")
		local UIGradient = Instance.new("UIGradient")

		Inputs.set_layout(SliderInput);

		SliderInput.Name = "SliderInput"
		SliderInput.Parent = UI
		SliderInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		SliderInput.BackgroundTransparency = 0.200
		SliderInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SliderInput.BorderSizePixel = 0
		SliderInput.ClipsDescendants = true
		SliderInput.Size = UDim2.new(0, Config.Size, 0, 15)
		SliderInput.ZIndex = IndexLayer + 1

		Sealz:AddHoverSignal(SliderInput,"BackgroundTransparency",0.25,0.5,SlideFrame)

		TransManager:Add(SliderInput)

		UICorner.CornerRadius = UDim.new(1, 0)
		UICorner.Parent = SliderInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = SliderInput

		TransManager:Add(UIShadow)

		SlideFrame.Name = "SlideFrame"
		SlideFrame.Parent = SliderInput
		SlideFrame.AnchorPoint = Vector2.new(0, 0.5)
		SlideFrame.BackgroundColor3 = Sealz.AccentColor
		SlideFrame.BackgroundTransparency = 0.500
		SlideFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SlideFrame.BorderSizePixel = 0
		SlideFrame.Position = UDim2.new(0, 0, 0.5, 0)
		SlideFrame.Size = UDim2.new(1, 0, 1, 0)
		SlideFrame.ZIndex = IndexLayer + 2

		UIGradient.Offset = Vector2.new(0, 0)
		UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.01, 1.00), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient.Parent = SlideFrame

		TransManager:Add(SlideFrame);

		UICorner_2.CornerRadius = UDim.new(1, 0)
		UICorner_2.Parent = SlideFrame

		SlideIndicator.Name = "SlideIndicator"
		SlideIndicator.Parent = SliderInput
		SlideIndicator.Active = false
		SlideIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
		SlideIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SlideIndicator.BackgroundTransparency = 1.000
		SlideIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SlideIndicator.BorderSizePixel = 0
		SlideIndicator.Position = UDim2.new(0.5, 0, 0.5, 0)
		SlideIndicator.Size = UDim2.new(0.25, 0, 1, 0)
		SlideIndicator.ZIndex = IndexLayer + 5
		SlideIndicator.ClearTextOnFocus = false
		SlideIndicator.Font = Sealz.Font
		SlideIndicator.Text = string.format('%d%s',SliderSelf.Value,Config.Type or "");
		SlideIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
		SlideIndicator.TextSize = 10.000
		SlideIndicator.TextTransparency = 0.250

		TransManager:Add(SlideIndicator)

		SliderSelf.OnChanged = function()
			local size = Sealz.GetSliderSize(SliderSelf.Value , Config.Min,Config.Max);

			if Config.Nums[SliderSelf.Value] then
				SlideIndicator.Text = Config.Nums[SliderSelf.Value];
			else
				SlideIndicator.Text = tostring(SliderSelf.Value)..(Config.Type or "");
			end;

			Sealz:Tween(UIGradient,BasedTween, {
				Offset = Vector2.new(size, 0)
			})

			Config.Callback(SliderSelf.Value)
		end;

		SliderSelf.TextBox = SlideIndicator.FocusLost:Connect(function()
			local Result = Sealz.Parse(SlideIndicator.Text , true);

			if Result then
				local rx = math.clamp(Result , Config.Min , Config.Max);
				local Value = Sealz:Rounding(rx,Config.Rounding);

				if Value then
					SliderSelf.Value = Value;

					SliderSelf.OnChanged()
				else
					SliderSelf.OnChanged()
				end;
			else
				SliderSelf.OnChanged()
			end;
		end);

		local IsHolding = false;

		SliderSelf.OnChanged()

		SliderSelf.Update = function(Input)
			local SizeScale = math.clamp((((Input.Position.X) - SliderInput.AbsolutePosition.X) / SliderInput.AbsoluteSize.X), 0, 1);
			local Main = ((Config.Max - Config.Min) * SizeScale) + Config.Min;
			local Value = Sealz:Rounding(Main,Config.Rounding);

			SliderSelf.Value = Value;

			SliderSelf.OnChanged()
		end;

		SliderSelf.SetupInput = function()
			IsHolding = false;

			return SliderInput.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					IsHolding = true
					SliderSelf.Update(Input)
				end
			end),
				SliderInput.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						if UserInputService.TouchEnabled then
							if not Sealz:IsMouseOverFrame(SliderInput) then
								IsHolding = false
							end;
						else
							IsHolding = false
						end;
					end
				end),
				UserInputService.InputChanged:Connect(function(Input)
					if IsHolding then
						if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)  then
							if UserInputService.TouchEnabled then
								if not Sealz:IsMouseOverFrame(SliderInput) then
									IsHolding = false
								else
									SliderSelf.Update(Input)
								end;
							else
								SliderSelf.Update(Input)
							end;
						end;
					end;
				end);
		end;

		SliderSelf.SignalController = function(a)
			if a then
				for i,v in next , SliderSelf.Signals do
					v:Disconnect();
				end;

				table.clear(SliderSelf.Signals);

				SliderSelf.Signals = {SliderSelf.SetupInput()};
			else

				for i,v in next , SliderSelf.Signals do
					v:Disconnect();
				end;

				table.clear(SliderSelf.Signals);
			end;
		end;

		SliderSelf.Signals = {SliderSelf.SetupInput()};

		SliderSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
			SliderSelf.SignalController(b)
		end);

		function SliderSelf:SetValue(a)
			SliderSelf.Value = a;

			SliderSelf.OnChanged()
		end;

		function SliderSelf:GetValue()
			return SliderSelf.Value;
		end;

		TransManager:Fire(Signal:Get(),true);

		Sealz:AddFlag(Config.Flag,SliderSelf);

		return SliderSelf;
	end;

	function Inputs:AddInput(Config)
		Config = Sealz:Format(Config , {
			Default = "",
			Placeholder = "Placeholder",
			Callback = Sealz.EmptyFunction,
			--Flag = "idx",
			Size = 75,
			Numeric = false,
		});

		local InputSelf = {
			Value = Config.Default
		};
		local TransManager = Sealz.Transparent();
		local TextInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local TextBox = Instance.new("TextBox")

		Inputs.set_layout(TextInput)

		TextInput.Name = "TextInput"
		TextInput.Parent = UI
		TextInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		TextInput.BackgroundTransparency = 0.250
		TextInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextInput.BorderSizePixel = 0
		TextInput.ClipsDescendants = true
		TextInput.Size = UDim2.new(0, Config.Size, 0, 20)
		TextInput.ZIndex = IndexLayer + 1
		TransManager:Add(TextInput)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = TextInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = TextInput
		TransManager:Add(UIShadow)

		TextBox.Parent = TextInput
		TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
		TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.BackgroundTransparency = 1.000
		TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextBox.BorderSizePixel = 0
		TextBox.Position = UDim2.new(0.5, 0, 0.5, 0)
		TextBox.Size = UDim2.new(1, -5, 1, 0)
		TextBox.ZIndex = IndexLayer + 2
		TextBox.ClearTextOnFocus = false
		TextBox.Font = Sealz.Font
		TextBox.PlaceholderText = Config.Placeholder
		TextBox.Text = Config.Default
		TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.TextSize = 10.000
		TransManager:Add(TextBox)

		TransManager:Fire(Signal:Get(),true);

		InputSelf.OnChanged = function(result)
			InputSelf.Value = result or ((Config.Numeric and (tonumber(TextBox.Text) or Config.Default)) or TextBox.Text);

			Config.Callback(InputSelf.Value)
		end;

		local placeholder = TextService:GetTextSize(TextBox.PlaceholderText,TextBox.TextSize,TextBox.Font,Vector2.new(math.huge,math.huge));

		InputSelf.UpdateSize = function()
			if typeof(Config.Size) ~= "number" then
				local size = Sealz:GetTextSize(TextBox);

				TextInput.Size = UDim2.new(0, math.max(size.X + 15 , placeholder.X + 15), 0, 20)
			end;
		end;

		InputSelf.UpdateSize();

		InputSelf.Activated = TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			InputSelf.UpdateSize();

			local result = Sealz.Parse(TextBox.Text , Config.Numeric);

			if Config.Numeric then
				TextBox.Text = string.gsub(TextBox.Text , '[^0-9.]','')

				return InputSelf.OnChanged();
			end;

			if result then
				InputSelf.OnChanged(result)
			end
		end);

		InputSelf.OnChanged(Config.Default)

		InputSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		function InputSelf:SetValue(a)
			InputSelf.Value = a;

			InputSelf.OnChanged(a)
		end;

		function InputSelf:GetValue()
			return InputSelf.Value;
		end;

		TransManager:Fire(Signal:Get(),true);

		Sealz:AddFlag(Config.Flag,InputSelf);

		return InputSelf;
	end;

	function Inputs:AddKeybind(Config)
		Config = Sealz:Format(Config , {
			Default = nil,
			Blacklist = {},
			Callback = Sealz.EmptyFunction,
			--Flag = "idx"
		});

		local KeybindSelf = {
			Value = Config.Default	
		};

		local TransManager = Sealz.Transparent();
		local KeybindInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local ValueText = Instance.new("TextLabel")
		local IconText = Instance.new("TextLabel")

		Inputs.set_layout(KeybindInput)
		KeybindInput.Name = "KeybindInput"
		KeybindInput.Parent = UI
		KeybindInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		KeybindInput.BackgroundTransparency = 0.250
		KeybindInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		KeybindInput.BorderSizePixel = 0
		KeybindInput.ClipsDescendants = true
		KeybindInput.Size = UDim2.new(0, 75, 0, 20)
		KeybindInput.ZIndex = IndexLayer + 1

		TransManager:Add(KeybindInput)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = KeybindInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = KeybindInput
		TransManager:Add(UIShadow)

		ValueText.Name = "ValueText"
		ValueText.Parent = KeybindInput
		ValueText.AnchorPoint = Vector2.new(0, 0.5)
		ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ValueText.BackgroundTransparency = 1.000
		ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ValueText.BorderSizePixel = 0
		ValueText.Position = UDim2.new(0, 5, 0.5, 0)
		ValueText.Size = UDim2.new(0, 200, 0, 15)
		ValueText.ZIndex = IndexLayer + 2
		ValueText.Font = Sealz.Font
		ValueText.Text = Sealz:GetKeyName(Config.Default)
		ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
		ValueText.TextSize = 10.000
		ValueText.TextTransparency = 0.250
		ValueText.TextXAlignment = Enum.TextXAlignment.Left
		TransManager:Add(ValueText)

		IconText.Name = "IconText"
		IconText.Parent = KeybindInput
		IconText.AnchorPoint = Vector2.new(1, 0.5)
		IconText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		IconText.BackgroundTransparency = 1.000
		IconText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		IconText.BorderSizePixel = 0
		IconText.Position = UDim2.new(1, -5, 0.5, 0)
		IconText.Size = UDim2.new(0, 25, 0, 15)
		IconText.ZIndex = IndexLayer + 2
		IconText.FontFace = Sealz.Icons
		IconText.Text = "keyboard"
		IconText.TextColor3 = Color3.fromRGB(255, 255, 255)
		IconText.TextSize = 10.000
		IconText.TextTransparency = 0.250
		IconText.TextXAlignment = Enum.TextXAlignment.Right
		TransManager:Add(IconText)

		KeybindSelf.Update = function()
			local size = Sealz:GetTextSize(ValueText);

			Sealz:Tween(KeybindInput,BasedTween,{
				Size = UDim2.new(0, size.X + 35, 0, 20)
			})
		end;

		KeybindSelf.Update()

		KeybindSelf.OnChanged = function(value)
			local result = (value or KeybindSelf.Value or Config.Default);

			if not table.find(Config.Blacklist,value) and not Config.Blacklist[value] then
				KeybindSelf.Value = result;

				ValueText.Text = Sealz:GetKeyName(result);

				KeybindSelf.Update();

				task.spawn(Config.Callback , result);

				return true;
			else
				ValueText.Text = Sealz:GetKeyName(KeybindSelf.Value);

				KeybindSelf.Update();
			end;
		end;



		KeybindSelf.Binding = false;
		KeybindSelf.Activated = Sealz:AddInput(KeybindInput,function()
			if KeybindSelf.Binding then
				return;
			end;

			KeybindSelf.Binding = true;

			ValueText.Text = "...";

			KeybindSelf.Update();

			local Once;
			while not Once do
				local Key = UserInputService.InputBegan:Wait();

				if Key.KeyCode ~= Enum.KeyCode.Unknown and (not table.find(Config.Blacklist,Key) and not Config.Blacklist[Key]) then
					Once = Key.KeyCode;
				elseif Key.UserInputType == Enum.UserInputType.MouseButton1 and (not table.find(Config.Blacklist,Enum.UserInputType.MouseButton1) and not Config.Blacklist[Enum.UserInputType.MouseButton1]) then
					Once = Enum.UserInputType.MouseButton1;
				elseif Key.UserInputType == Enum.UserInputType.MouseButton2 and (not table.find(Config.Blacklist,Enum.UserInputType.MouseButton2) and not Config.Blacklist[Enum.UserInputType.MouseButton2]) then
					Once = Enum.UserInputType.MouseButton2;
				end;
			end;

			KeybindSelf.Binding = false;

			KeybindSelf.OnChanged(Once);
		end);

		KeybindSelf.OnChanged(Config.Default)

		KeybindSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		function KeybindSelf:SetValue(a)
			KeybindSelf.Value = a;

			KeybindSelf.OnChanged(a)
		end;

		function KeybindSelf:GetValue()
			return KeybindSelf.Value;
		end;

		TransManager:Fire(Signal:Get(),true);

		Sealz:AddFlag(Config.Flag,KeybindSelf);

		return KeybindSelf;
	end;

	function Inputs:AddColorPicker(Config)
		Config = Sealz:Format(Config , {
			Default = Color3.fromRGB(255,255,255),
			Callback = Sealz.EmptyFunction,
			--Flag = "idx"
		});

		if typeof(Config.Default)=="string" then
			Config.Default = Color3.fromHex(string.gsub(Config.Default , "#",''));
		end;

		local ColorPickerSelf = {
			Value = Config.Default	
		};
		local TransManager = Sealz.Transparent();

		local ColorPickerInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")

		Inputs.set_layout(ColorPickerInput);
		ColorPickerInput.Name = "ColorPickerInput"
		ColorPickerInput.Parent = UI
		ColorPickerInput.BackgroundColor3 = Color3.fromRGB(143, 255, 162)
		ColorPickerInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ColorPickerInput.BorderSizePixel = 0
		ColorPickerInput.Size = UDim2.new(0, 20, 0, 20)
		ColorPickerInput.ZIndex = IndexLayer + 2;

		TransManager:Add(ColorPickerInput);

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = ColorPickerInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = ColorPickerInput

		TransManager:Add(UIShadow);

		ColorPickerSelf.OnChanged = function(color)
			ColorPickerSelf.Value = color;

			Config.Callback(color);
		end;

		ColorPickerSelf.OnRender = function(c)

			ColorPickerInput.BackgroundColor3 = c;

			ColorPickerSelf.OnChanged(c);
		end;

		ColorPickerSelf.OnRender(Config.Default)

		ColorPickerSelf.Root = ColorPickerInput;

		ColorPickerSelf.Handler = Sealz:CreateColorPickerWindow(ColorPickerSelf);

		ColorPickerSelf.WakeSignal = Sealz:AddInput(ColorPickerInput,function()
			ColorPickerSelf.Handler.Wake(true);
		end);

		ColorPickerSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		function ColorPickerSelf:SetValue(a)
			ColorPickerSelf.Value = a;

			ColorPickerSelf.OnRender(a);

			ColorPickerSelf.Handler.SetColor(a);
		end;

		function ColorPickerSelf:GetValue()
			return ColorPickerSelf.Value;
		end;

		TransManager:Fire(Signal:Get(),true);

		Sealz:AddFlag(Config.Flag,ColorPickerSelf);

		return ColorPickerSelf;
	end;

	function Inputs:AddDropdown(Config)
		Config = Sealz:Format(Config , {
			Default = nil,
			Values = {},

			--[[# Text 
			"str"
			
				# Image
			{
				Image: id,
				Name: str,
				Description: str
			}
			]]

			Multi = false,
			Callback = Sealz.EmptyFunction,
			Flag = nil,
			Type = "Text", -- Text , Image
			Size = 145,
		});

		Config.Default = Sealz.FormatDropdown(Config.Default)

		local DropdownSelf = {
			Value = Config.Default	
		};

		local TransManager = Sealz.Transparent();
		local DropdownInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local ValueText = Instance.new("TextLabel")
		local IconText = Instance.new("TextLabel")

		Inputs.set_layout(DropdownInput)
		DropdownInput.Name = "DropdownInput"
		DropdownInput.Parent = UI
		DropdownInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		DropdownInput.BackgroundTransparency = 0.250
		DropdownInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DropdownInput.BorderSizePixel = 0
		DropdownInput.ClipsDescendants = true
		DropdownInput.Size = UDim2.new(0, 75, 0, 20)
		DropdownInput.ZIndex = IndexLayer + 1
		TransManager:Add(DropdownInput)
		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = DropdownInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = DropdownInput
		TransManager:Add(UIShadow)
		ValueText.Name = "ValueText"
		ValueText.Parent = DropdownInput
		ValueText.AnchorPoint = Vector2.new(0, 0.5)
		ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ValueText.BackgroundTransparency = 1.000
		ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ValueText.BorderSizePixel = 0
		ValueText.Position = UDim2.new(0, 5, 0.5, 0)
		ValueText.Size = UDim2.new(1, -25, 0, 15)
		ValueText.ZIndex = IndexLayer + 2
		ValueText.Font = Sealz.Font
		ValueText.Text = Sealz.ParseDropdown(DropdownSelf.Value)
		ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
		ValueText.TextSize = 10.000
		ValueText.TextTruncate = Enum.TextTruncate.SplitWord;
		ValueText.TextTransparency = 0.250
		ValueText.TextXAlignment = Enum.TextXAlignment.Left

		TransManager:Add(ValueText)
		IconText.Name = "IconText"
		IconText.Parent = DropdownInput
		IconText.AnchorPoint = Vector2.new(1, 0.5)
		IconText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		IconText.BackgroundTransparency = 1.000
		IconText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		IconText.BorderSizePixel = 0
		IconText.Position = UDim2.new(1, -5, 0.5, 0)
		IconText.Size = UDim2.new(0, 25, 0, 15)
		IconText.ZIndex = IndexLayer + 3
		IconText.FontFace = Sealz.Icons
		IconText.Text = "chevron-large-down"
		IconText.TextColor3 = Color3.fromRGB(255, 255, 255)
		IconText.TextSize = 10.000
		IconText.TextTransparency = 0.250
		IconText.TextXAlignment = Enum.TextXAlignment.Right
		TransManager:Add(IconText);
		DropdownSelf.Size = Config.Size;
		DropdownSelf.Root = DropdownInput;

		DropdownSelf.Handler = Sealz:CreateDropdown(DropdownSelf);

		Sealz:AddInput(DropdownInput,function()
			DropdownSelf.Handler.Wake()
		end)

		DropdownSelf.Update = function()
			local Size = Sealz:GetTextSize(ValueText);

			Sealz:Tween(DropdownInput , BasedTween,{
				Size = UDim2.new(0, math.clamp(Size.X + 35,55,150), 0, 20)
			})
		end;

		DropdownSelf.IsMatch = function(v1)	
			if typeof(DropdownSelf.Value) == 'table' then
				if DropdownSelf.Value[v1] or table.find(DropdownSelf.Value , v1) then
					return true;
				end
			end

			if DropdownSelf.Value == v1 then
				return true;
			end;
		end;

		DropdownSelf.OnChanged = function()
			ValueText.Text = Sealz.ParseDropdown(DropdownSelf.Value)

			DropdownSelf.Update();


			Config.Callback(DropdownSelf.Value)
		end

		DropdownSelf.Generate = function()
			DropdownSelf.Handler.Clear();

			local LastPointer;
			for i,v in next , Config.Values do
				local itd = (Config.Type == "Text" and DropdownSelf.Handler.DrawText(tostring(v))) or DropdownSelf.Handler.DrawImage(v.Image,v.Name , v.Description);
				local Name;

				if Config.Type == "Text" then
					Name = tostring(v);
				else
					Name = rawget(v,'Name');
				end;

				if Config.Multi then
					if DropdownSelf.IsMatch(Name) then
						itd.on()
					else
						itd.off()
					end;

					local _,Signal = Sealz:AddInput(itd.root,function()
						DropdownSelf.Value[Name] = not DropdownSelf.Value[Name];

						if DropdownSelf.IsMatch(Name) then
							itd.on()
						else
							itd.off()
						end;

						DropdownSelf.OnChanged()
					end);

					table.insert(DropdownSelf.Handler.ItemSignals,Signal)
				else
					if DropdownSelf.IsMatch(Name) then
						itd.on()
						LastPointer = itd;
					else
						itd.off()
					end;

					local _,Signal = Sealz:AddInput(itd.root,function()
						if LastPointer then
							LastPointer.off();
						end;

						LastPointer = itd;
						itd.on()
						DropdownSelf.Value = Name;

						DropdownSelf.OnChanged()
					end);

					table.insert(DropdownSelf.Handler.ItemSignals,Signal)
				end;
			end
		end;

		DropdownSelf.Generate();

		DropdownSelf.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		function DropdownSelf:SetValue(a)
			DropdownSelf.Value = a;

			DropdownSelf.Generate()

			DropdownSelf.OnChanged()
		end;

		function DropdownSelf:SetValues(a)
			Config.Values = a;

			DropdownSelf.Generate()
		end;

		function DropdownSelf:GetValue()
			return DropdownSelf.Value;
		end;

		TransManager:Fire(Signal:Get(),true);

		DropdownSelf.Update();

		Sealz:AddFlag(Config.Flag,DropdownSelf);

		return DropdownSelf;
	end;

	function Inputs:AddOption()
		local Self = {};

		local TransManager = Sealz.Transparent();
		local OptionInput = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local Button = Instance.new("TextButton")

		Inputs.set_layout(OptionInput)
		OptionInput.Name = "OptionInput"
		OptionInput.Parent = UI
		OptionInput.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		OptionInput.BackgroundTransparency = 0.200
		OptionInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		OptionInput.BorderSizePixel = 0
		OptionInput.Size = UDim2.new(0, 20, 0, 20)
		OptionInput.ZIndex = IndexLayer + 1
		TransManager:Add(OptionInput)
		Self.Root = OptionInput;

		local Handler = Sealz:CreateBlockWindow(Self)

		UICorner.CornerRadius = UDim.new(1, 0)
		UICorner.Parent = OptionInput

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = OptionInput
		TransManager:Add(UIShadow);

		Button.Name = "Button"
		Button.Parent = OptionInput
		Button.AnchorPoint = Vector2.new(0.5, 0.5)
		Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundTransparency = 1.000
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BorderSizePixel = 0
		Button.Position = UDim2.new(0.5, 0, 0.5, 0)
		Button.Size = UDim2.new(1, 0, 1, 0)
		Button.ZIndex = IndexLayer + 2
		Button.FontFace = Sealz.Icons
		Button.Text = "three-dots-vertical"
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.TextSize = 14.000
		Button.TextTransparency = 0.500
		TransManager:Add(Button);

		TransManager:Fire(Signal:Get(),true);
		Self.Activated = Button.Activated:Connect(function()
			Handler:Wake()
		end);

		Self.Signal = Signal:Connect(function(b)
			TransManager:Fire(b)	
		end);

		Handler.OptRoot = Self;

		return Handler;
	end;

	-- This feature can be detect by anti-cheat
	function Inputs:AddAudio(Config)
		Config = Sealz:Format(Config,{
			Audio = "",
			Volume = 1,
			Speed = 1,
		});

		local AudioInstance = Instance.new('Sound');

		AudioInstance.SoundId = Config.Audio;
		AudioInstance.PlaybackSpeed = Config.Speed;
		AudioInstance.Volume = Config.Volume;

		local AudioSelf = {};

		local TransManager = Sealz.Transparent();
		local Audio = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local ControlButton = Instance.new("TextButton")
		local UIListLayout = Instance.new("UIListLayout")
		local Timer = Instance.new("TextLabel")

		AudioInstance.Parent = Audio;

		Audio.Name = "Audio"
		Audio.Parent = UI
		Audio.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		Audio.BackgroundTransparency = 0.250
		Audio.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Audio.BorderSizePixel = 0
		Audio.ClipsDescendants = true
		Audio.Size = UDim2.new(0, 95, 0, 20)
		Audio.ZIndex = IndexLayer + 1

		TransManager:Add(Audio)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Audio

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 5)
		UIShadow.Parent = Audio
		TransManager:Add(UIShadow)

		ControlButton.Name = "ControlButton"
		ControlButton.Parent = Audio
		ControlButton.AnchorPoint = Vector2.new(0, 0.5)
		ControlButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ControlButton.BackgroundTransparency = 1.000
		ControlButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ControlButton.BorderSizePixel = 0
		ControlButton.Position = UDim2.new(0, 0, 0.5, 0)
		ControlButton.Size = UDim2.new(0, 20, 0, 20)
		ControlButton.ZIndex = IndexLayer + 2
		ControlButton.FontFace = Sealz.Icons
		ControlButton.Text = "play-small"
		ControlButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		ControlButton.TextSize = 11.000
		ControlButton.TextTransparency = 0.500
		TransManager:Add(ControlButton)

		UIListLayout.Parent = Audio
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.Padding = UDim.new(0, 5)

		Timer.Name = "Timer"
		Timer.Parent = Audio
		Timer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Timer.BackgroundTransparency = 1.000
		Timer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Timer.BorderSizePixel = 0
		Timer.Size = UDim2.new(0, 65, 0, 20)
		Timer.ZIndex = IndexLayer + 3
		Timer.Font = Enum.Font.Code
		Timer.Text = string.format("%s / %s",Sealz.FormatAudioTimer(AudioInstance.TimePosition),Sealz.FormatAudioTimer(AudioInstance.TimeLength));
		Timer.TextColor3 = Color3.fromRGB(255, 255, 255)
		Timer.TextSize = 6.000
		Timer.TextTransparency = 0.350

		TransManager:Add(Timer);

		TransManager:Fire(Signal:Get(),true);

		AudioSelf.Update = function()
			Timer.Text = string.format("%s / %s",Sealz.FormatAudioTimer(AudioInstance.TimePosition),Sealz.FormatAudioTimer(AudioInstance.TimeLength));
			local size = Sealz:GetTextSize(Timer);

			Sealz:Tween(Audio,BasedTween,{
				Size = UDim2.new(0, UIListLayout.AbsoluteContentSize.X + 10, 0, 20)
			})

			Timer.Size = UDim2.new(0, size.X, 0, 20)
		end;

		AudioSelf.Activated = Sealz:AddInput(ControlButton,function()
			AudioInstance.Playing = not AudioInstance.Playing;
		end)

		AudioSelf.Thread = task.spawn(function()
			while true do task.wait(0.1)
				if not AudioInstance.Playing then
					ControlButton.Text = "play-small";

					if not Sealz:IsMouseOverFrame(Audio) then
						AudioInstance.TimePosition = 0;
					end;
				else
					ControlButton.Text = "pause-small"
				end;

				AudioSelf.Update();
			end;
		end)

		AudioSelf.Update()

		AudioSelf.Signal = Signal:Connect(function(bool)
			if not bool then
				AudioInstance.Playing = false;
				AudioInstance.TimePosition = 0;
			end;

			TransManager:Fire(bool);
		end);

		function AudioSelf:SetAudio(value)
			if AudioInstance.SoundId ~= value then
				AudioInstance.Playing = false;
			end;

			AudioInstance.SoundId = value;
		end

		function AudioSelf:SetVolume(value)
			AudioInstance.Volume = value;
		end

		function AudioSelf:SetSpeed(value)
			AudioInstance.PlaybackSpeed = value;
		end

		return AudioSelf;
	end;

	return Inputs;
end;

function Sealz:CreateToolTipHandler(UI: Frame, Text: string)
	local ToolTip = Instance.new("TextLabel")

	ToolTip.Name = "ToolTip"
	ToolTip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ToolTip.BackgroundTransparency = 1.000
	ToolTip.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ToolTip.BorderSizePixel = 0
	ToolTip.Size = UDim2.new(0, 200, 0, 5)
	ToolTip.Font = Enum.Font.Code
	ToolTip.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToolTip.TextSize = 10.000
	ToolTip.TextStrokeTransparency = 0.500
	ToolTip.TextTransparency = 0.25
	ToolTip.TextWrapped = true;
	ToolTip.Text = Text;
	ToolTip.TextXAlignment = Enum.TextXAlignment.Left
	ToolTip.TextYAlignment = Enum.TextYAlignment.Top
	ToolTip.ZIndex = UI.ZIndex + 20;

	local size = Sealz:GetTextSize(ToolTip);

	ToolTip.Size = UDim2.new(0, size.X, 0, size.Y)

	local Hover,TH = false,nil;

	UI.MouseEnter:Connect(function()
		if TH then
			task.cancel(TH)
			TH = nil
		end;

		Hover = true;

		TH = task.spawn(function()
			while Hover do task.wait()
				local location = UserInputService:GetMouseLocation();

				ToolTip.Visible = true;
				ToolTip.Parent = Sealz.ScreenGui;
				ToolTip.Position = UDim2.fromOffset(location.X + 10,location.Y + 10)
			end;
		end);
	end);

	UI.MouseLeave:Connect(function()
		if TH then
			task.cancel(TH)
			TH = nil
		end;

		ToolTip.Visible = false;
		ToolTip.Parent = nil;

		Hover = false;
	end);
end;

function Sealz:Regisiter(UI: Frame , Signal)
	local IndexLayer = UI.ZIndex;
	local Items = {};

	function Items:AddLabel(Name: string)
		local LabelSelf = {};
		local TransManager = Sealz.Transparent();

		local ItemFrame = Instance.new("Frame")
		local TextLabel = Instance.new("TextLabel")
		local UICorner = Instance.new("UICorner")
		local LineFrame = Instance.new("Frame")
		local InputsFrame = Instance.new("Frame")
		local UIListLayout = Instance.new("UIListLayout")

		ItemFrame.Name = "ItemFrame"
		ItemFrame.Parent = UI
		ItemFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		ItemFrame.BackgroundTransparency = 1.000
		ItemFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ItemFrame.BorderSizePixel = 0
		ItemFrame.Size = UDim2.new(1, 0, 0, 30)
		ItemFrame.ZIndex = IndexLayer + 1

		TextLabel.Parent = ItemFrame
		TextLabel.AnchorPoint = Vector2.new(0, 0.5)
		TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextLabel.BorderSizePixel = 0
		TextLabel.Position = UDim2.new(0, 10, 0.5, 0)
		TextLabel.Size = UDim2.new(1, -20, 0, 15)
		TextLabel.ZIndex = IndexLayer + 2
		TextLabel.Font = Sealz.SecondFont
		TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.TextSize = 13.000
		TextLabel.TextTransparency = 0.45
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Text = Name;

		Sealz:AddHoverSignal(ItemFrame,"TextTransparency",0.2,0.45,TextLabel)

		TransManager:Add(TextLabel)

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = ItemFrame

		LineFrame.Name = "LineFrame"
		LineFrame.Parent = ItemFrame
		LineFrame.AnchorPoint = Vector2.new(0.5, 1)
		LineFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
		LineFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LineFrame.BorderSizePixel = 0
		LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
		LineFrame.Size = UDim2.new(1, -1, 0, 1)
		LineFrame.ZIndex = IndexLayer + 4

		TransManager:Add(LineFrame)

		InputsFrame.Name = "InputsFrame"
		InputsFrame.Parent = ItemFrame
		InputsFrame.AnchorPoint = Vector2.new(1, 0.5)
		InputsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		InputsFrame.BackgroundTransparency = 1.000
		InputsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		InputsFrame.BorderSizePixel = 0
		InputsFrame.Position = UDim2.new(1, -10, 0.5, 0)
		InputsFrame.Size = UDim2.new(1, -10, 0, 25)
		InputsFrame.ZIndex = IndexLayer + 3

		TransManager:Add(InputsFrame)

		UIListLayout.Parent = InputsFrame
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.Padding = UDim.new(0, 5)

		TransManager:Fire(Signal:Get(),true);
		LabelSelf.Frame = ItemFrame;

		LabelSelf.Signal = Signal:Connect(function(bool)
			TransManager:Fire(bool);
		end);

		local Inputs = Sealz:CreateInputs(InputsFrame,Signal);
		Inputs.Root = LabelSelf;

		function Inputs:SetText(new)
			TextLabel.Text = new;
		end;

		function Inputs:ToolTip(Text: string)
			Sealz:CreateToolTipHandler(ItemFrame,Text);

			return Inputs;
		end

		return Inputs;
	end;

	function Items:AddImage(Config)
		Config = Sealz:Format(Config,{
			Image = "",
			Type = "Crop", -- Crop , Fit , Stretch
			Size = 150,
		})

		local TransManager = Sealz.Transparent();

		local ImageSelf = {};
		local ImageFrame = Instance.new("Frame")
		local LineFrame = Instance.new("Frame")
		local ImageLabel = Instance.new("ImageLabel")

		ImageFrame.Name = "ImageFrame"
		ImageFrame.Parent = UI
		ImageFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageFrame.BackgroundTransparency = 1.000
		ImageFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageFrame.BorderSizePixel = 0
		ImageFrame.Size = UDim2.new(1, 0, 0, Config.Size or 150)
		ImageFrame.ZIndex = IndexLayer + 1

		TransManager:Add(ImageLabel)

		LineFrame.Name = "LineFrame"
		LineFrame.Parent = ImageFrame
		LineFrame.AnchorPoint = Vector2.new(0.5, 1)
		LineFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
		LineFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LineFrame.BorderSizePixel = 0
		LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
		LineFrame.Size = UDim2.new(1, -1, 0, 1)
		LineFrame.ZIndex = IndexLayer + 5

		TransManager:Add(LineFrame)

		ImageLabel.Parent = ImageFrame
		ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel.BackgroundTransparency = 1.000
		ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel.BorderSizePixel = 0
		ImageLabel.Size = UDim2.new(1, 0, 1, 0)
		ImageLabel.ZIndex = IndexLayer + 2
		ImageLabel.Image = Config.Image
		ImageLabel.ScaleType = Enum.ScaleType[Config.Type or "Crop"]

		TransManager:Add(ImageLabel)

		TransManager:Fire(Signal:Get(),true);

		ImageSelf.Signal = Signal:Connect(function(bool)
			TransManager:Fire(bool);
		end);

		function ImageSelf:SetImage(image: string)
			ImageLabel.Image = image;
		end;

		function ImageSelf:SetSize(size)
			ImageFrame.Size = UDim2.new(1, 0, 0, size or 150)
		end;

		return ImageSelf;
	end;

	return Items;
end;

-- Start Up
function Sealz:StartUp(UI: Frame)
	local StartUpSlide = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIGradient = Instance.new("UIGradient")

	StartUpSlide.Name = "StartUpSlide"
	StartUpSlide.Parent = UI
	StartUpSlide.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	StartUpSlide.BackgroundTransparency = 1;
	StartUpSlide.BorderColor3 = Color3.fromRGB(0, 0, 0)
	StartUpSlide.BorderSizePixel = 0
	StartUpSlide.Size = UDim2.new(1, 0, 1, 0)
	StartUpSlide.AnchorPoint = Vector2.new(0.5,0.5);
	StartUpSlide.Position = UDim2.fromScale(0.5,0.5);
	StartUpSlide.ZIndex = 1000

	Sealz:Tween(StartUpSlide,ScaleTween,{
		BackgroundTransparency = 0;
		Size = UDim2.new(1, 0, 1, 0)
	});

	UICorner.Parent = StartUpSlide

	UIGradient.Offset = Vector2.new(-1, 0)
	UIGradient.Rotation = 45
	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.50, 1.00), NumberSequenceKeypoint.new(0.50, 0.00), NumberSequenceKeypoint.new(1.00, 0.00)}
	UIGradient.Parent = StartUpSlide

	task.delay(0.5,function()
		Sealz:Tween(UIGradient,TweenInfo.new(2,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
			Offset = Vector2.new(1, 0)
		}).Completed:Connect(function()
			StartUpSlide:Destroy();
		end)
	end);

	task.wait(0.5)
end;

function Sealz:EncodeData(data)
	if typeof(data) == "number" then
		return {
			a = "Number",
			b = data,
		};
	elseif typeof(data) == "string" then
		return {
			a = "String",
			b = data
		};
	elseif typeof(data) == "boolean" then
		return {
			a = "Boolean",
			b = data
		};
	elseif typeof(data) == "Color3" then
		return {
			a = "Color",
			b = {
				[1] = data.R,
				[2] = data.G,
				[3] = data.B
			}
		};
	elseif typeof(data) == "table" then
		return {
			a = "Table",
			b = data
		};
	elseif typeof(data) == "EnumItem" then
		if data.EnumType == Enum.KeyCode then
			return {
				a = "KeyCode",
				b = data.Name,
			};
		elseif data.EnumType == Enum.UserInputType then
			return {
				a = "UserInputType",
				b = data.Name,
			};
		end;

		warn('invalid enum type')
	elseif typeof(data) == "nil" then
		return {
			a = "Nil",
			b = nil,
		};
	else
		warn(data);
		error("Invalid Data "..debug.traceback());
	end;
end;

function Sealz:DecodeData(data)
	if data.a == "Number" or data.a == "String" or data.a == "Boolean" or data.a == "Table" or data.a == "Nil" then
		return data.b
	elseif data.a == "Color" then
		return Color3.new(data.b[1],data.b[2],data.b[3])
	elseif data.a == "KeyCode" then
		return Enum.KeyCode[data.b]
	elseif data.a == "UserInputType" then
		return Enum.UserInputType[data.b]
	end
end

-- Creating Window
function Sealz.new(config)
	config = Sealz:Format(config , {
		Title = "Sealz.ui", -- title of the window
		Description = "Userinterface", -- description of the window
		Path = "sealz.ui", -- directory path for config/save
		Scale = 1, -- UI scale
		Keybind = "RightControl", -- ui keybind
		OnStartUp = true,
		Size = UDim2.new(0, 640, 0, 480)
	});

	config.Keybind = config.Keybind;

	local winSelf = {
		Signal = CreateSignal(true),
		Keybind = config.Keybind
	};

	if not isfolder(config.Path) then
		makefolder(config.Path);
	end;

	local MainFrame = Instance.new("Frame")
	local UIScale = Instance.new("UIScale")
	local UICorner = Instance.new("UICorner")
	local TopFrame = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local MenuTitle = Instance.new("TextLabel")
	local MenuDesc = Instance.new("TextLabel")
	local TabButtons = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")
	local LineFollower = Instance.new("Frame")
	local BottomFrame = Instance.new("Frame")
	local UICorner_3 = Instance.new("UICorner")
	local ToolsFrame = Instance.new("Frame")
	local UIListLayout_2 = Instance.new("UIListLayout")
	local UICorner_4 = Instance.new("UICorner")
	local ScrollingFrame = Instance.new("ScrollingFrame")
	local UIListLayout_3 = Instance.new("UIListLayout")
	local ContainerTabFrame = Instance.new("Frame")
	local UIStroke = Instance.new("UIStroke")
	local UIShadow = Instance.new("UIShadow")

	local WindowTransparent = Sealz.Transparent();

	-- Save config
	function winSelf:Save(Delay: boolean)
		local Data = {
			time = tick(),
			data = {},
		};

		local count = 1;
		for i,v in next , Sealz.Flags do
			if Delay then
				if count % 50 == 1 then
					task.wait();
				end;

				count += 1;
			end;

			local value = v:GetValue();
			local encoded = Sealz:EncodeData(value)

			Data.data[i] = encoded;
		end;

		local JSON = HttpService:JSONEncode(Data);

		table.clear(Data);

		writefile(config.Path..'/config.json',JSON);

		return true;
	end;

	-- load config from path
	function winSelf:Load(Path: string)
		Path = Path or config.Path..'/config.json';

		if not isfile(Path) then
			return;
		end;

		local DATA = HttpService:JSONDecode(readfile(Path));

		for i,v in next , DATA.data do
			local data = Sealz.Flags[i];

			task.spawn(data.SetValue,data,Sealz:DecodeData(v))
		end;

		return true
	end;

	-- Load config from string
	function winSelf:LoadFromString(JSON: string)
		local DATA = HttpService:JSONDecode(JSON);

		for i,v in next , DATA.data do
			local data = Sealz.Flags[i];

			task.spawn(data.SetValue,data,Sealz:DecodeData(v))
		end;

		return true
	end;

	function winSelf:AutoSave()
		return task.spawn(function()
			while true do task.wait(5);
				if winSelf.Signal:Get() then
					winSelf:Save(true)
				end;
			end;
		end)
	end;

	UIShadow.Transparency = 0.500
	UIShadow.BlurRadius = UDim.new(0, 20)
	UIShadow.Parent = MainFrame;

	WindowTransparent:Add(UIShadow)

	MainFrame.Name = "MainFrame"
	MainFrame.Active = true
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	MainFrame.BackgroundTransparency = 1
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = config.Size
	MainFrame.Parent = Sealz.ScreenGui;

	Sealz:AddVisibleSignal(MainFrame,"BackgroundTransparency",0.95,true)

	WindowTransparent:Add(MainFrame,{
		BackgroundTransparency = 0.1
	})

	UIScale.Parent = MainFrame
	UICorner.Parent = MainFrame
	UIScale.Scale = config.Scale;

	TopFrame.Name = "TopFrame"
	TopFrame.Parent = MainFrame
	TopFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	TopFrame.BackgroundTransparency = 0.500
	TopFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TopFrame.BorderSizePixel = 0
	TopFrame.Size = UDim2.new(1, 0, 0, 40)
	TopFrame.ZIndex = 15

	WindowTransparent:Add(TopFrame)

	Sealz:AddDrag(TopFrame,MainFrame,0.2);
	Sealz:AddBlurring(MainFrame,winSelf.Signal)

	UICorner_2.Parent = TopFrame

	MenuTitle.Name = "MenuTitle"
	MenuTitle.Parent = TopFrame
	MenuTitle.AnchorPoint = Vector2.new(0, 0.5)
	MenuTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MenuTitle.BackgroundTransparency = 1.000
	MenuTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MenuTitle.BorderSizePixel = 0
	MenuTitle.Position = UDim2.new(0, 10, 0.275, 0)
	MenuTitle.Size = UDim2.new(0, 200, 0, 10)
	MenuTitle.ZIndex = 17
	MenuTitle.Font = Sealz.Font
	MenuTitle.Text = config.Title
	MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	MenuTitle.TextSize = 13.000
	MenuTitle.TextTransparency = 0.100
	MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
	WindowTransparent:Add(MenuTitle)

	MenuDesc.Name = "MenuDesc"
	MenuDesc.Parent = TopFrame
	MenuDesc.AnchorPoint = Vector2.new(0, 0.5)
	MenuDesc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MenuDesc.BackgroundTransparency = 1.000
	MenuDesc.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MenuDesc.BorderSizePixel = 0
	MenuDesc.Position = UDim2.new(0, 10, 0.7, 0)
	MenuDesc.Size = UDim2.new(0, 200, 0, 5)
	MenuDesc.ZIndex = 17
	MenuDesc.Font = Sealz.Font
	MenuDesc.Text = config.Description
	MenuDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
	MenuDesc.TextSize = 10.000
	MenuDesc.TextTransparency = 0.500
	MenuDesc.TextXAlignment = Enum.TextXAlignment.Left
	WindowTransparent:Add(MenuDesc)

	TabButtons.Name = "TabButtons"
	TabButtons.Parent = TopFrame
	TabButtons.AnchorPoint = Vector2.new(1, 0.5)
	TabButtons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabButtons.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabButtons.BorderSizePixel = 0
	TabButtons.Position = UDim2.new(1, -10, 0.5, 0)
	TabButtons.Size = UDim2.new(0, 0, 1, 0)
	TabButtons.ZIndex = 20
	WindowTransparent:Add(TabButtons)

	UIListLayout.Parent = TabButtons
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.Padding = UDim.new(0, 5)

	LineFollower.Name = "LineFollower"
	LineFollower.Parent = TopFrame
	LineFollower.AnchorPoint = Vector2.new(0.5, 0)
	LineFollower.BackgroundColor3 = Sealz.AccentColor
	LineFollower.BorderColor3 = Color3.fromRGB(0, 0, 0)
	LineFollower.BorderSizePixel = 0
	LineFollower.Position = UDim2.new(0, 580, 0, 30)
	LineFollower.Size = UDim2.new(0, 50, 0, 2)
	LineFollower.ZIndex = 25
	WindowTransparent:Add(LineFollower)

	BottomFrame.Name = "BottomFrame"
	BottomFrame.Parent = MainFrame
	BottomFrame.AnchorPoint = Vector2.new(0, 1)
	BottomFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	BottomFrame.BackgroundTransparency = 0.500
	BottomFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BottomFrame.BorderSizePixel = 0
	BottomFrame.Position = UDim2.new(0, 0, 1, 0)
	BottomFrame.Size = UDim2.new(1, 0, 0, 25)
	BottomFrame.ZIndex = 45
	WindowTransparent:Add(BottomFrame)

	UICorner_3.Parent = BottomFrame

	ToolsFrame.Name = "ToolsFrame"
	ToolsFrame.Parent = BottomFrame
	ToolsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ToolsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ToolsFrame.BackgroundTransparency = 1.000
	ToolsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ToolsFrame.BorderSizePixel = 0
	ToolsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	ToolsFrame.Size = UDim2.new(1, -10, 1, 0)
	ToolsFrame.ZIndex = 46
	WindowTransparent:Add(ToolsFrame)

	UIListLayout_2.Parent = ToolsFrame
	UIListLayout_2.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout_2.VerticalAlignment = Enum.VerticalAlignment.Center

	UIListLayout_3.Parent = ScrollingFrame
	UIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder

	ContainerTabFrame.Name = "ContainerTabFrame"
	ContainerTabFrame.Parent = MainFrame
	ContainerTabFrame.Active = true
	ContainerTabFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ContainerTabFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ContainerTabFrame.BackgroundTransparency = 1.000
	ContainerTabFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ContainerTabFrame.BorderSizePixel = 0
	ContainerTabFrame.ClipsDescendants = true
	ContainerTabFrame.Position = UDim2.new(0.5, 0, 0.5, 10)
	ContainerTabFrame.Size = UDim2.new(1, -5, 1, -85)
	WindowTransparent:Add(ContainerTabFrame)

	UIStroke.Color = Color3.fromRGB(34, 34, 34)
	UIStroke.Parent = MainFrame
	WindowTransparent:Add(UIStroke)

	WindowTransparent:Fire(false,true);

	winSelf.Signal:Connect(function(bool)
		WindowTransparent:Fire(bool);
	end);

	function winSelf:SetKeybind(Key: Enum.KeyCode)
		winSelf.Keybind = Key;
	end;

	function winSelf:SetSize(UD: UDim2)
		Sealz:Tween(MainFrame,ScaleTween,{
			Size = UD;
		});

		task.delay(0.5,function()
			winSelf.Menu.EventChange:Fire()
		end)
	end;

	function winSelf:ForceCenter()
		Sealz:Tween(MainFrame,ScaleTween,{
			Position = UDim2.fromScale(0.5,0.5)
		})
	end;

	winSelf.Menu = {
		CurrentIndex = nil,
		Menu = {},
		EventChange = CreateSignal();
	};

	winSelf.Runtime = task.spawn(function()
		local Refresh = function()
			if winSelf.Menu.CurrentIndex and winSelf.Menu.Menu and winSelf.Menu.Menu[winSelf.Menu.CurrentIndex] then
				local CurrentScale = UIScale.Scale;

				if CurrentScale ~= 1 then
					LineFollower.Visible = false;
				else
					LineFollower.Visible = true;
					local data = winSelf.Menu.Menu[winSelf.Menu.CurrentIndex];
					local post = data.BthRoot.AbsolutePosition;
					local size = data.BthRoot.AbsoluteSize;
					local target = post - TopFrame.AbsolutePosition;

					Sealz:Tween(LineFollower,BasedTween,{
						Position = UDim2.fromOffset((target.X + (size.X / 2)),target.Y + 24),
						Size = UDim2.fromOffset(size.X - 25, 2)
					});
				end;
			end;
		end;

		while true do 
			Refresh();

			winSelf.Menu.EventChange:Wait();
		end;
	end);

	function winSelf:AddMenu(Config)
		Config = Sealz:Format(Config , {
			Name = "Menu"
		});

		local MenuSelf = {};
		local TabSignal = CreateSignal(false);

		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local TextLabel = Instance.new("TextLabel")

		Frame.Parent = TabButtons
		Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
		Frame.BackgroundTransparency = 0.200
		Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Frame.BorderSizePixel = 0
		Frame.Size = UDim2.new(0, 100, 0, 24)
		Frame.ZIndex = 22

		MenuSelf.BthRoot = Frame;

		local bthf = WindowTransparent:Add(Frame);

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = Frame

		TextLabel.Parent = Frame
		TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextLabel.BorderSizePixel = 0
		TextLabel.Position = UDim2.new(0.5, 0, 0.449999988, 0)
		TextLabel.Size = UDim2.new(1, 0, 0.5, 0)
		TextLabel.ZIndex = 25
		TextLabel.Font = Sealz.Font
		TextLabel.Text = Config.Name
		TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextLabel.TextSize = 11.000
		TextLabel.TextTransparency = 0.100

		MenuSelf.Update = function()
			local size = Sealz:GetTextSize(TextLabel);

			Frame.Size = UDim2.new(0, size.X + 20, 0, 24)
		end;

		MenuSelf.Update()

		local bthb = WindowTransparent:Add(TextLabel);

		local OnUpdate = function(bool)
			if not winSelf.Signal:Get() then
				return;	
			end;

			pcall(MenuSelf.Update);

			if bool then
				Sealz:Tween(Frame,BasedTween,{
					BackgroundTransparency = 0.2
				})
				Sealz:Tween(TextLabel,BasedTween,{
					TextTransparency = 0.1
				})

				bthf("BackgroundTransparency",0.200)
				bthb("TextTransparency",0.1)

			else


				Sealz:Tween(Frame,BasedTween,{
					BackgroundTransparency = 0.5
				})
				Sealz:Tween(TextLabel,BasedTween,{
					TextTransparency = 0.5
				})

				bthf("BackgroundTransparency",0.5)
				bthb("TextTransparency",0.5)
			end
		end;

		TabSignal:Connect(OnUpdate);

		local BIndex = #winSelf.Menu.Menu + 1;

		MenuSelf.Signal = TabSignal;

		MenuSelf.Activated = Sealz:AddInput(Frame,function()
			winSelf.Menu.CurrentIndex = BIndex;

			for i,v in next , winSelf.Menu.Menu do
				if i == BIndex then
					v.Signal:Fire(true);
				else
					v.Signal:Fire(false);
				end;
			end;

			winSelf.Menu.EventChange:Fire()
		end);

		local TabFrame = Instance.new("Frame")
		local UIListLayout = Instance.new("UIListLayout")


		TabFrame.Name = "TabFrame"
		TabFrame.Parent = ContainerTabFrame
		TabFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		TabFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TabFrame.BackgroundTransparency = 1.000
		TabFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabFrame.BorderSizePixel = 0
		TabFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		TabFrame.Size = UDim2.new(1, -5, 1, -5)
		TabFrame.ZIndex = 35

		if not winSelf.Menu.CurrentIndex then
			winSelf.Menu.CurrentIndex = 1;
			TabSignal:Fire(true);

			OnUpdate(true)
		else
			OnUpdate(false);
			TabFrame.Visible = false;
			TabFrame.Parent = nil;
		end;

		TabSignal:Connect(function(bool)
			pcall(function()
				if bool then
					TabFrame.Visible = true;
					TabFrame.Parent = ContainerTabFrame
				else
					task.delay(0.45,function()
						if not TabSignal:Get() then
							TabFrame.Visible = false;
							TabFrame.Parent = nil
						end
					end)
				end
			end)
		end);

		UIListLayout.Parent = TabFrame
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
		UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
		UIListLayout.Padding = UDim.new()


		function MenuSelf:AddTab()
			local TabSelf = {};
			local ScrollingFrame = Instance.new("ScrollingFrame")
			local UIListLayout = Instance.new("UIListLayout")

			ScrollingFrame.Parent = TabFrame
			ScrollingFrame.Active = true
			ScrollingFrame.AnchorPoint = Vector2.new(0.5, 0)
			ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ScrollingFrame.BackgroundTransparency = 1.000
			ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ScrollingFrame.BorderSizePixel = 0
			ScrollingFrame.ClipsDescendants = false
			ScrollingFrame.Size = UDim2.new(0, 100, 0, 100)
			ScrollingFrame.ZIndex = 36
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
			ScrollingFrame.ScrollBarThickness = 0

			UIListLayout.Parent = ScrollingFrame
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout.Padding = UDim.new(0, 10)
			UIListLayout.VerticalFlex = Enum.UIFlexAlignment.Fill


			TabSelf.ListSignal = UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				if UIListLayout.AbsoluteContentSize.Y >= (ScrollingFrame.AbsoluteSize.Y * 2) then
					ScrollingFrame.CanvasSize = UDim2.fromOffset(0,UIListLayout.AbsoluteContentSize.Y / 1.5);
				end;
			end);

			TabSelf.SectionCount = 0;

			function TabSelf:AddSection(Name: string)
				local TransManager = Sealz.Transparent();
				local SectionSelf = {};

				local SectionFrame = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local HeaderFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local TextLabel = Instance.new("TextLabel")
				local LineFrame = Instance.new("Frame")
				local Shadow = Instance.new("Frame")
				local UIGradient = Instance.new("UIGradient")
				local ScrollingFrameInner = Instance.new("ScrollingFrame")
				local UIListLayout = Instance.new("UIListLayout")
				local UIStroke = Instance.new("UIStroke")

				SectionFrame.Name = "SectionFrame"
				SectionFrame.Parent = ScrollingFrame
				SectionFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
				SectionFrame.BackgroundTransparency = 0.200
				SectionFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				SectionFrame.BorderSizePixel = 0
				SectionFrame.Size = UDim2.new(1, -7, 0, 150)
				SectionFrame.ZIndex = 37

				TransManager:Add(SectionFrame)

				UICorner.Parent = SectionFrame

				HeaderFrame.Name = "HeaderFrame"
				HeaderFrame.Parent = SectionFrame
				HeaderFrame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
				HeaderFrame.BackgroundTransparency = 1.000
				HeaderFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				HeaderFrame.BorderSizePixel = 0
				HeaderFrame.Size = UDim2.new(1, 0, 0, 30)
				HeaderFrame.ZIndex = 55
				TransManager:Add(HeaderFrame)
				UICorner_2.Parent = HeaderFrame

				TextLabel.Parent = HeaderFrame
				TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextLabel.BackgroundTransparency = 1.000
				TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextLabel.BorderSizePixel = 0
				TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextLabel.Size = UDim2.new(1, -15, 1, -10)
				TextLabel.ZIndex = 56
				TextLabel.Font = Sealz.Font
				TextLabel.Text = Name
				TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextLabel.TextSize = 12.000
				TextLabel.TextTransparency = 0.250
				TransManager:Add(TextLabel)
				LineFrame.Name = "LineFrame"
				LineFrame.Parent = HeaderFrame
				LineFrame.AnchorPoint = Vector2.new(0.5, 1)
				LineFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
				LineFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LineFrame.BorderSizePixel = 0
				LineFrame.Position = UDim2.new(0.5, 0, 1, 0)
				LineFrame.Size = UDim2.new(1, 0, 0, 1)
				LineFrame.ZIndex = 56
				TransManager:Add(LineFrame)
				Shadow.Name = "Shadow"
				Shadow.Parent = HeaderFrame
				Shadow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				Shadow.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Shadow.BorderSizePixel = 0
				Shadow.Position = UDim2.new(0, 0, 1, 0)
				Shadow.Size = UDim2.new(1, 0, 0, 10)
				Shadow.ZIndex = 57
				TransManager:Add(Shadow)
				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = Shadow

				ScrollingFrameInner.Parent = SectionFrame
				ScrollingFrameInner.Active = true
				ScrollingFrameInner.AnchorPoint = Vector2.new(0.5, 0)
				ScrollingFrameInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ScrollingFrameInner.BackgroundTransparency = 1.000
				ScrollingFrameInner.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ScrollingFrameInner.BorderSizePixel = 0
				ScrollingFrameInner.Position = UDim2.new(0.5, 0, 0, 30)
				ScrollingFrameInner.Size = UDim2.new(1, 0, 1, -35)
				ScrollingFrameInner.ZIndex = 40
				ScrollingFrameInner.BottomImage = ""
				ScrollingFrameInner.ScrollBarImageColor3 = Sealz.AccentColor;
				ScrollingFrameInner.ScrollBarThickness = 1
				ScrollingFrameInner.TopImage = ""

				TransManager:Add(ScrollingFrameInner);

				Sealz:SET_SCROLLING(ScrollingFrameInner,UIListLayout);

				UIListLayout.Parent = ScrollingFrameInner
				UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

				UIStroke.Color = Color3.fromRGB(34, 34, 34)
				UIStroke.Parent = SectionFrame

				TransManager:Add(UIStroke)

				local CurrentSectionCount = TabSelf.SectionCount;
				SectionSelf.Signal = TabSignal:Connect(function(bool)
					TransManager:Fire(bool)
				end);

				TabSelf.SectionCount += 1;

				SectionSelf.WinSignal = winSelf.Signal:Connect(function(bool)
					if bool then
						if winSelf.Menu.CurrentIndex == BIndex then
							TabSignal:Fire(bool)
						end
					else
						TabSignal:Fire(bool)
					end;
				end);

				local Reg = Sealz:Regisiter(ScrollingFrameInner,TabSignal);
				Reg.Section = SectionSelf;

				return Reg;
			end;

			return TabSelf;
		end;

		table.insert(winSelf.Menu.Menu,MenuSelf);

		winSelf.Menu.EventChange:Fire()

		return MenuSelf;
	end;

	function winSelf:AddTool(Icon: string)
		local ToolButton = Instance.new("TextButton")

		ToolButton.Name = "ToolButton"
		ToolButton.Parent = ToolsFrame
		ToolButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ToolButton.BackgroundTransparency = 1.000
		ToolButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ToolButton.BorderSizePixel = 0
		ToolButton.Size = UDim2.new(0, 20, 0, 20)
		ToolButton.ZIndex = 47
		ToolButton.FontFace = Sealz.Icons
		ToolButton.Text = Icon or "two-switches-horizontal"
		ToolButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		ToolButton.TextSize = 13.000
		ToolButton.TextTransparency = 0.500

		WindowTransparent:Add(ToolButton);
		Sealz:AddHoverSignal(ToolButton,"TextTransparency",0.25);

		local toolSelf = {
			Signal = CreateSignal(false)	
		};

		local TransManager = Sealz.Transparent();

		local ToolFrame = Instance.new("Frame")
		local UIShadow = Instance.new("UIShadow")
		local UICorner = Instance.new("UICorner")
		local ScrollingFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")

		ToolFrame.Name = "ToolFrame"
		ToolFrame.Parent = MainFrame
		ToolFrame.Active = true
		ToolFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		ToolFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
		ToolFrame.BackgroundTransparency = 0.025
		ToolFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ToolFrame.BorderSizePixel = 0
		ToolFrame.ClipsDescendants = true
		ToolFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		ToolFrame.Size = UDim2.new(0, 450, 0, 300)
		ToolFrame.ZIndex = 300
		ToolFrame.Visible = false;

		TransManager:Add(ToolFrame)
		Sealz:AddVisibleSignal(ToolFrame,'BackgroundTransparency',0.95,true);

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 20)
		UIShadow.Parent = ToolFrame

		TransManager:Add(UIShadow)

		UICorner.Parent = ToolFrame

		ScrollingFrame.Parent = ToolFrame
		ScrollingFrame.Active = true
		ScrollingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ScrollingFrame.BackgroundTransparency = 1.000
		ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.ClipsDescendants = false
		ScrollingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		ScrollingFrame.Size = UDim2.new(1, -5, 1, -5)
		ScrollingFrame.ZIndex = 308
		ScrollingFrame.ScrollBarThickness = 0

		Sealz:SET_SCROLLING(ScrollingFrame , UIListLayout);
		TransManager:Add(ScrollingFrame);

		UIListLayout.Parent = ScrollingFrame
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

		TransManager:Fire(false);

		toolSelf.Signal:Connect(function(bool)
			TransManager:Fire(bool);
		end);

		toolSelf.clear_signal = function()
			if toolSelf.OnOverFrame then
				toolSelf.OnOverFrame:Disconnect();
			end;
		end;

		ToolButton.Activated:Connect(function()
			toolSelf.clear_signal();

			toolSelf.Signal:Toggle();

			toolSelf.OnOverFrame = UserInputService.InputBegan:Connect(Sealz:OnOverFrame(ToolFrame , function()
				toolSelf.clear_signal();

				toolSelf.Signal:Fire(false);
			end));
		end);

		Sealz:SET_CONNECT(winSelf.Signal , toolSelf.Signal);

		local Items = Sealz:Regisiter(ScrollingFrame,toolSelf.Signal)
		Items.Content = ScrollingFrame;

		Items.Root = toolSelf;

		return Items;
	end;

	function winSelf:Toggle()
		winSelf.Signal:Toggle();
	end;

	WindowTransparent:Fire(true);

	winSelf.WindowInput = UserInputService.InputBegan:Connect(function(Key,Processed)
		if not Processed and (Key.KeyCode == winSelf.Keybind or Key.KeyCode.Name == winSelf.Keybind) then
			winSelf:Toggle()
		end;
	end);

	function winSelf:GetScale()

		return UIScale.Scale
	end

	function winSelf:SetScale(d)
		winSelf.Menu.EventChange:Fire();

		Sealz:Tween(UIScale,BasedTween, {
			Scale = d or 1;
		})
	end

	if config.OnStartUp then
		Sealz:StartUp(MainFrame);
	end

	return winSelf;
end;

function Sealz.Indicator()
	local IndicatorFrame = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")

	IndicatorFrame.Name = "IndicatorFrame"
	IndicatorFrame.Parent = Sealz.ScreenGui;
	IndicatorFrame.AnchorPoint = Vector2.new(0, 0.5)
	IndicatorFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	IndicatorFrame.BackgroundTransparency = 1.000
	IndicatorFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	IndicatorFrame.BorderSizePixel = 0
	IndicatorFrame.Position = UDim2.new(0, 10, 0.5, 0)
	IndicatorFrame.Size = UDim2.new(0, 5, 0, 5)

	UIListLayout.Parent = IndicatorFrame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.Padding = UDim.new(0, 0)

	local Indicator = {};
	local Order = 0;

	Indicator.Root = IndicatorFrame;

	Indicator.new = function(icon: string,name: string,color: Color3 | string)

		local Layout = Order + 1;
		local PadLayout = Order + 2;
		local TransManager = Sealz.Transparent();
		local IndicatorItem = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIShadow = Instance.new("UIShadow")
		local ColroFrame = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local UIGradient = Instance.new("UIGradient")
		local Icon = Instance.new("TextLabel")
		local Text = Instance.new("TextLabel")
		local Padding = Instance.new('Frame')

		Order += 5;

		Padding.LayoutOrder = PadLayout;
		Padding.BackgroundTransparency = 1;
		Padding.Size = UDim2.fromOffset(0,0)
		Padding.Parent = IndicatorFrame

		IndicatorItem.Name = "IndicatorItem"
		IndicatorItem.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
		IndicatorItem.BackgroundTransparency = 0.250
		IndicatorItem.BorderColor3 = Color3.fromRGB(0, 0, 0)
		IndicatorItem.BorderSizePixel = 0
		IndicatorItem.Size = UDim2.new(0, 0, 0, 0)
		IndicatorItem.ClipsDescendants = true;
		IndicatorItem.ZIndex = -4
		IndicatorItem.LayoutOrder = Layout;

		TransManager:Add(IndicatorItem)

		UICorner.CornerRadius = UDim.new(0, 10)
		UICorner.Parent = IndicatorItem

		UIShadow.Transparency = 0.500
		UIShadow.BlurRadius = UDim.new(0, 20)
		UIShadow.Parent = IndicatorItem
		TransManager:Add(UIShadow);

		ColroFrame.Name = "ColroFrame"
		ColroFrame.Parent = IndicatorItem
		ColroFrame.AnchorPoint = Vector2.new(0, 0.5)
		ColroFrame.BackgroundColor3 = Color3.fromRGB(255, 89, 92)
		ColroFrame.BackgroundTransparency = 0.250
		ColroFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ColroFrame.BorderSizePixel = 0
		ColroFrame.Position = UDim2.new(0, 0, 0.5, 0)
		ColroFrame.Size = UDim2.new(1, 0, 1, 0)
		ColroFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
		ColroFrame.ZIndex = -3
		TransManager:Add(ColroFrame);

		UICorner_2.CornerRadius = UDim.new(0, 10)
		UICorner_2.Parent = ColroFrame

		UIGradient.Offset = Vector2.new(-0.375, 0)
		UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.49, 0.00), NumberSequenceKeypoint.new(0.51, 1.00), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient.Parent = ColroFrame

		Icon.Name = "Icon"
		Icon.Parent = ColroFrame
		Icon.AnchorPoint = Vector2.new(0, 0.5)
		Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon.BackgroundTransparency = 1.000
		Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Icon.BorderSizePixel = 0
		Icon.Position = UDim2.new(0, 5, 0.5, 0)
		Icon.Size = UDim2.new(0, 25, 0, 2)
		Icon.FontFace = Sealz.Icons
		Icon.Text = icon
		Icon.TextColor3 = Color3.fromRGB(255, 89, 92)
		Icon.TextSize = 17.000
		Icon.ZIndex = -2
		TransManager:Add(Icon)

		Text.Name = "Text"
		Text.Parent = ColroFrame
		Text.AnchorPoint = Vector2.new(0, 0.5)
		Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Text.BackgroundTransparency = 1.000
		Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Text.BorderSizePixel = 0
		Text.Position = UDim2.new(0, 30, 0.5, 0)
		Text.Size = UDim2.new(0, 30, 0, 2)
		Text.Font = Sealz.Font
		Text.Text = name or "";
		Text.TextColor3 = Color3.fromRGB(255, 89, 92)
		Text.TextSize = 14.000
		Text.TextXAlignment = Enum.TextXAlignment.Left
		Text.ZIndex = -2
		TransManager:Add(Text);

		TransManager:Fire(false,true);

		IndicatorItem.Parent = IndicatorFrame

		local IndiItem = {};

		IndiItem.Update = function()
			if IndiItem.delay_thread then
				pcall(task.cancel,IndiItem.delay_thread);	
			end;

			local size = Sealz:GetTextSize(Text);

			Sealz:Tween(IndicatorItem,BasedTween,{
				Size = UDim2.new(0, size.X + 45, 0, 35)
			});

			Sealz:Tween(Padding,ScaleTween,{
				Size = UDim2.new(0, 0, 0, 7)
			})

			return true
		end;

		IndiItem.Hide = function()
			if IndiItem.delay_thread then
				pcall(task.cancel,IndiItem.delay_thread);	
			end;

			Sealz:Tween(IndicatorItem,BasedTween,{
				Size = UDim2.new(0, 0, 0, 35)
			});

			Sealz:Tween(Padding,ScaleTween,{
				Size = UDim2.new(0, 0, 0, 0)
			})

			IndiItem.delay_thread = task.delay(BasedTween.Time / 1.2,function()
				if IndicatorItem.AbsoluteSize.X < 5 then
					Sealz:Tween(IndicatorItem,BasedTween,{
						Size = UDim2.new(0, 0, 0, 0)
					});
				end;
			end)

			return true;
		end;

		function IndiItem:SetText(TextStr: string)
			Text.Text = TextStr;

			if IndiItem.Visible then
				IndiItem.Update();
			end
		end

		function IndiItem:SetColor(color: string | Color3)
			if typeof(color) == "string" then
				color = Sealz.ColorMode[color] or Sealz.ColorMode.Red;	
			end;

			Sealz:Tween(ColroFrame,BasedTween,{
				BackgroundColor3 = color
			});

			Sealz:Tween(Text,BasedTween,{
				TextColor3 = color
			});

			Sealz:Tween(Icon,BasedTween,{
				TextColor3 = color
			});

			if IndiItem.Visible then
				IndiItem.Update();
			end
		end;

		IndiItem.Visible = false;

		function IndiItem:Render(bool)
			if IndiItem.Visible == bool then
				return;
			end;

			if IndiItem.delay_thread then
				pcall(task.cancel,IndiItem.delay_thread);	
			end;

			IndiItem.Visible = bool;

			TransManager:Fire(bool);

			return (bool and IndiItem.Update()) or IndiItem.Hide()
		end;

		if color then
			IndiItem:SetColor(color);
		end;

		return IndiItem;
	end;

	return Indicator;
end;

function Sealz.Watermark(Position: string)
	Position = Position or 2;

	if Position == 1 then
		Position = "Left"
	elseif Position == 2 then
		Position = "Middle"
	elseif Position == 3 then
		Position = "Right"
	end

	local TransManager = Sealz.Transparent();
	local WatermarkSelf = {};
	local BasedWatermarkLayer = 500;
	local PaddingX,PaddingY = 15 , 30;
	
	local WatermarkFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIShadow = Instance.new("UIShadow")
	local UIListLayout = Instance.new("UIListLayout")
	local UIScale = Instance.new("UIScale")

	WatermarkFrame.Name = "WatermarkFrame"
	WatermarkFrame.Parent = Sealz.ScreenGui;
	WatermarkFrame.AnchorPoint = Vector2.new(0.5, 0)
	WatermarkFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	WatermarkFrame.BackgroundTransparency = 0.250
	WatermarkFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WatermarkFrame.BorderSizePixel = 0
	WatermarkFrame.Position = UDim2.new(0.5, 0, 0, 15)
	WatermarkFrame.Size = UDim2.new(0, 0, 0, 20)
	WatermarkFrame.ClipsDescendants = true;
	WatermarkFrame.ZIndex = BasedWatermarkLayer;

	TransManager:Add(WatermarkFrame);

	UICorner.CornerRadius = UDim.new(0, 5)
	UICorner.Parent = WatermarkFrame

	UIShadow.Transparency = 0.500
	UIShadow.BlurRadius = UDim.new(0, 20)
	UIShadow.Parent = WatermarkFrame

	TransManager:Add(UIShadow);

	UIListLayout.Parent = WatermarkFrame
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.Padding = UDim.new(0, 2)

	WatermarkSelf.OnUpdate = UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		Sealz:Tween(WatermarkFrame,BasedTween, {
			Size = UDim2.new(0, UIListLayout.AbsoluteContentSize.X + PaddingX, 0, PaddingY)
		})
	end);

	UIScale.Parent = WatermarkFrame

	function WatermarkSelf:SetPosition(Position)
		if Position == 1 then
			Position = "Left"
		elseif Position == 2 or Position == "Center" then
			Position = "Middle"
		elseif Position == 3 then
			Position = "Right"
		end

		if Position == "Left" then
			Sealz:Tween(WatermarkFrame,BasedTween, {
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0, 25, 0, 15)
			})
		elseif Position == "Middle" then
			Sealz:Tween(WatermarkFrame,BasedTween, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 15)
			})
		else
			Sealz:Tween(WatermarkFrame,BasedTween, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -25, 0, 15)
			})
		end;
	end;

	WatermarkSelf:SetPosition(Position)

	local CurrentLayout = 1;
	function WatermarkSelf.new(IconStr: string,TextStr: string)
		local WatermarkItemSelf = {};

		local Layout = CurrentLayout;
		local Block = Instance.new("Frame")
		local Icon = Instance.new("TextLabel")
		local Text = Instance.new("TextLabel")

		CurrentLayout += 1;

		Block.Name = "Block"
		Block.Parent = WatermarkFrame
		Block.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Block.BackgroundTransparency = 1.000
		Block.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Block.BorderSizePixel = 0
		Block.Size = UDim2.new(0, 0, 0, 15)
		Block.ZIndex = BasedWatermarkLayer + 1
		Block.LayoutOrder = Layout
		Block.ClipsDescendants = true;

		Icon.Name = "Icon"
		Icon.Parent = Block
		Icon.AnchorPoint = Vector2.new(0, 0.5)
		Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon.BackgroundTransparency = 1.000
		Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Icon.BorderSizePixel = 0
		Icon.Position = UDim2.new(0, 2, 0.5, 0)
		Icon.Size = UDim2.new(0, 15, 0, 15)
		Icon.FontFace = Sealz.Icons
		Icon.Text = IconStr or "crosshairs"
		Icon.TextColor3 = Sealz.AccentColor
		Icon.TextSize = 12.000
		Icon.ZIndex = BasedWatermarkLayer + 2
		TransManager:Add(Icon);

		Text.Name = "Text"
		Text.Parent = Block
		Text.AnchorPoint = Vector2.new(0, 0.5)
		Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Text.BackgroundTransparency = 1.000
		Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Text.BorderSizePixel = 0
		Text.Position = UDim2.new(0, 20, 0.5, 0)
		Text.Size = UDim2.new(0, 5, 0, 2)
		Text.Font = Sealz.Font
		Text.Text = TextStr or "Watermark"
		Text.TextColor3 = Color3.fromRGB(255, 255, 255)
		Text.TextSize = 10.000
		Text.ZIndex = BasedWatermarkLayer + 3
		Text.TextXAlignment = Enum.TextXAlignment.Left
		TransManager:Add(Text);
		
		Block:GetPropertyChangedSignal('Size'):Connect(function()
			Block.Visible = (Block.AbsoluteSize.X > 2);
		end);

		WatermarkItemSelf.Update = function()
			local size = Sealz:GetTextSize(Text);
			Sealz:Tween(Block,BasedTween,{
				Size = UDim2.new(0, size.X + 30, 0, 15)
			})
		end

		function WatermarkItemSelf:SetIcon(icon: string)
			Icon.Text = icon;

			WatermarkItemSelf.Update();
		end;

		function WatermarkItemSelf:SetText(str: string)
			Text.Text = str;

			WatermarkItemSelf.Update();
		end;

		WatermarkItemSelf.Visible = true;

		function WatermarkItemSelf:Render(bool: boolean)
			local state = WatermarkItemSelf.Visible;

			WatermarkItemSelf.Visible = bool;

			if not bool and state then
				Sealz:Tween(Block,BasedTween,{
					Size = UDim2.new(0, 0, 0, 15)
				});
			elseif bool and not state then
				WatermarkItemSelf.Update();
			end;
		end;

		WatermarkItemSelf.Update();

		return WatermarkItemSelf;
	end;

	function WatermarkSelf:AddButton(Name: string ,Callback: ()->any)
		local CurrentLayoutrd = CurrentLayout;
		local Button = Instance.new("Frame")
		local Text = Instance.new("TextLabel")
		local UICorner = Instance.new("UICorner")

		CurrentLayout += 1;

		Button.Name = "Button"
		Button.Active = true;
		Button.Parent = WatermarkFrame
		Button.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
		Button.BackgroundTransparency = 0.250
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BorderSizePixel = 0
		Button.Size = UDim2.new(0, 80, 0, 15)
		Button.ZIndex = BasedWatermarkLayer + 1
		Button.LayoutOrder = CurrentLayoutrd;

		TransManager:Add(Button)

		Text.Name = "Text"
		Text.Parent = Button
		Text.AnchorPoint = Vector2.new(0.5, 0.5)
		Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Text.BackgroundTransparency = 1.000
		Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Text.BorderSizePixel = 0
		Text.Position = UDim2.new(0.5, 0, 0.5, 0)
		Text.Size = UDim2.new(0, 5, 0, 2)
		Text.Font = Enum.Font.Code
		Text.Text = Name
		Text.TextColor3 = Color3.fromRGB(255, 255, 255)
		Text.TextTransparency = 0.500
		Text.ZIndex = BasedWatermarkLayer + 2

		Sealz:AddHoverSignal(Button , "TextTransparency" , 0.25 , 0.5 ,Text)

		local size = Sealz:GetTextSize(Text);

		Button.Size = UDim2.new(0, size.X + 10, 0, 15)

		TransManager:Add(Text);

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Button

		Sealz:AddInput(Button,Callback)
	end;

	WatermarkSelf.Visible = true;
	function WatermarkSelf:Render(bool)
		if WatermarkSelf.Visible == bool then
			return
		end;

		WatermarkSelf.Visible = bool;

		TransManager:Fire(WatermarkSelf.Visible);
	end

	return WatermarkSelf;
end;

function Sealz.Logger()
	local NotificationFrame = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")

	NotificationFrame.Name = "NotificationFrame"
	NotificationFrame.Parent = Sealz.ScreenGui
	NotificationFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotificationFrame.BackgroundTransparency = 1.000
	NotificationFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NotificationFrame.BorderSizePixel = 0
	NotificationFrame.Position = UDim2.new(0, 10, 0, 50)
	NotificationFrame.Size = UDim2.new(0, 25, 0, 25)

	UIListLayout.Parent = NotificationFrame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0,7)

	return {
		new = function(text: string , duration: number)
			duration = duration or 5;

			local LogItem = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local UIShadow = Instance.new("UIShadow")
			local ColorFrame = Instance.new("Frame")
			local UICorner_2 = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")
			local Text = Instance.new("TextLabel")

			LogItem.Name = "LogItem"
			LogItem.Parent = NotificationFrame
			LogItem.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
			LogItem.BackgroundTransparency = 0.250
			LogItem.BorderColor3 = Color3.fromRGB(0, 0, 0)
			LogItem.BorderSizePixel = 0
			LogItem.ClipsDescendants = true;
			LogItem.Size = UDim2.new(0, 0, 0, 20)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = LogItem

			UIShadow.Transparency = 0.500
			UIShadow.BlurRadius = UDim.new(0, 20)
			UIShadow.Parent = LogItem

			ColorFrame.Name = "ColorFrame"
			ColorFrame.Parent = LogItem
			ColorFrame.AnchorPoint = Vector2.new(0, 0.5)
			ColorFrame.BackgroundColor3 = Sealz.AccentColor
			ColorFrame.BackgroundTransparency = 0.250
			ColorFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ColorFrame.BorderSizePixel = 0
			ColorFrame.Position = UDim2.new(0, 0, 0.5, 0)
			ColorFrame.Size = UDim2.new(0, 25, 1, 0)
			ColorFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY

			UICorner_2.CornerRadius = UDim.new(0, 4)
			UICorner_2.Parent = ColorFrame

			UIGradient.Offset = Vector2.new(-0.35, 0)
			UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.49, 0.00), NumberSequenceKeypoint.new(0.51, 1.00), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient.Parent = ColorFrame

			Text.Name = "Text"
			Text.Parent = LogItem
			Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Text.BackgroundTransparency = 1.000
			Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Text.BorderSizePixel = 0
			Text.Position = UDim2.new(0, 10, 0, 5)
			Text.Size = UDim2.new(0, 30, 1, 0)
			Text.Font = Sealz.Font
			Text.Text = text
			Text.TextColor3 = Sealz.AccentColor
			Text.TextSize = 10.000
			Text.TextXAlignment = Enum.TextXAlignment.Left
			Text.TextYAlignment = Enum.TextYAlignment.Top

			local update = function()
				local size = Sealz:GetTextSize(Text);
				Sealz:Tween(LogItem,BasedTween,{
					Size = UDim2.new(0, size.X + 35, 0, size.Y + 10);
				});
			end

			update();

			task.delay(duration,function()
				Sealz:Tween(LogItem,BasedTween,{
					Size = UDim2.new(0, 0, 0, LogItem.AbsoluteSize.Y);
				}).Completed:Connect(function()
					LogItem:Destroy();
				end)
			end)
		end,
	};
end;

Sealz.ColorMode = {
	Red = Color3.fromRGB(255, 89, 92),
	Green = Color3.fromRGB(92, 255, 146),
	White = Color3.fromRGB(255, 255, 255),
};

	return Sealz;
end;

local __okLib, __SealzLib = SealzTry("UILib.lua", __SealzMain);
print("UI Version: v0.1bp27");
return __SealzLib;
