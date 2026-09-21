-- Reversal: Zero Script v5.4 (Freeze via game-native MovementComponent, Onmitsu Elite level bypass)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Конфигурация
local CONFIG = {
	SourceUrl = "https://raw.githubusercontent.com/ReversalReside/ReversalHub/refs/heads/main/src/ui/ReversalUI.lua",
	CloudBaseUrl = "https://node-server-cloud-base.vercel.app/api",
	DISCORD_INVITE = "https://discord.gg/UPZAXQ6tTm",
}

local VindUI = loadstring(game:HttpGet(CONFIG.SourceUrl))()
VindUI:PreloadIcons({ "Lucide", "Material", "Phosphor", "SF" })

local TOGGLE_KEY = Enum.KeyCode.RightShift
local Tabs = {}

-- Создание основного окна
local Window = VindUI:CreateWindow({
	Title = "ReversalHub",
	Subtitle = "Reversal: Zero · v5.3",
	Icon = "rbxassetid://137033858433374",
	Size = UDim2.fromOffset(640, 455),
	MinSize = Vector2.new(500, 360),
	Draggable = true,
	Resizable = true,
	UseBlur = true,
	DefaultTab = "Home",
})

VindUI:Notify({
	Title = "Reversal: Zero",
	Text = "Interface loaded successfully.",
	Type = "success",
	Duration = 4,
})

-- ==================== CLOUD SERVICE & CONFIGS PANEL ====================

local Cloud = VindUI:CloudService({
	BaseUrl = CONFIG.CloudBaseUrl,
	Script = "reversal-zero",
})

local ConfigsPanel = Window:AddCloudPanel({
	Service = Cloud,
	Title = "Configs",
	Icon = "Lucide:folder-cog",
	OnToggle = function(open)
		if ConfigsDockButton then 
			ConfigsDockButton:SetActive(open) 
		end
	end,
})

local ConfigsDockButton = Window:AddDockButton({
	Icon = "Lucide:folder-cog",
	Callback = function() 
		ConfigsPanel.Toggle() 
	end,
})


-- ==================== HOME TAB ====================

Tabs.Home = Window:AddTab({ Name = "Home", Icon = "Lucide:layout-dashboard" })

local Homepage = Tabs.Home:AddSubTab({ Name = "Homepage", Icon = "Lucide:info" })

local function greeting()
	local hour = tonumber(os.date("%H"))
	if hour < 5 then return "Good night." end
	if hour < 12 then return "Good morning." end
	if hour < 18 then return "Good afternoon." end
	return "Good evening."
end

Homepage:AddCard({
	UserId      = LocalPlayer.UserId,
	Title       = "Hello, " .. LocalPlayer.DisplayName,
	Description = greeting(),
})

Homepage:AddButton({
	Text        = "Discord Server",
	Description = "Join our community Discord for script support, updates, bug reports and giveaways",
	Icon        = "Lucide:message-circle",
	Callback    = function()
		local copied = false
		pcall(function()
			copied = pcall(setclipboard, CONFIG.DISCORD_INVITE)
		end)
		if not copied then
			pcall(function()
				copied = pcall(function()
					clipboard.set(CONFIG.DISCORD_INVITE)
					return true
				end)
			end)
		end
		VindUI:Notify({
			Title = "Discord",
			Text  = copied and "Invite link copied to clipboard!" or "Copy failed — link: " .. CONFIG.DISCORD_INVITE,
			Type  = copied and "success" or "error",
			Duration = 3,
		})
	end,
})

Homepage:AddSection("Server Information", "Lucide:server")
Homepage:AddInfoGrid({
	Title = "Server Stats",
	Description = "Current server details",
	Color = Color3.fromRGB(115, 145, 255),
	Columns = 2,
	Items = {
		{ Label = "Place ID", Value = tostring(game.PlaceId) },
		{ Label = "Job ID", Value = game.JobId:sub(1, 8) .. "..." },
		{ Label = "Players Online", Value = tostring(#Players:GetPlayers()) },
		{ Label = "Server Region", Value = "Unknown" },
	},
})

local systemGrid = Homepage:AddSystemInfoGrid({
	Description = "Client performance info",
})

local ScriptChangelog = Tabs.Home:AddSubTab({ Name = "What's New", Icon = "Lucide:file-text" })

ScriptChangelog:AddChangelogEntry({
	Version = "Reversal: Zero 5.4",
	Date    = os.date("%d.%m.%Y"),
	Changes = {
		{ Type = "Added",   Text = "Collector tab: Auto Collect Chest — teleports to every enabled chest type and opens it through the game's own interact flow (prompt -> Interact -> OpenCrate). Per-type toggles for all chests; crate-rain-only chests sit under the 'Admin Events' divider. Settings toggle 'Insta proximity prompt' controls instant vs. waited prompt activation." },
		{ Type = "Added",   Text = "Settings tab: Anti AFK — answers Roblox's idle check (Idled -> VirtualUser:CaptureController) so the server never idle-kicks you." },
		{ Type = "Fixed",   Text = "Freeze now holds you in place without locking movement, so abilities stay usable" },
		{ Type = "Added",   Text = "Auto R/F/C/X/Z/V/Y/T now cast the equipped technique skills directly via SkillController (no more fake keypresses)" },
		{ Type = "Added",   Text = "Bypass tab: [1360LVL] Auto Claim Onmitsu Elite — claims the Lv.1360 quest via QuestService.AcceptQuest, skipping the client-side level gate" },
		{ Type = "Added",   Text = "Farming tab: AutoWorldRaid — auto-enters ANY Overworld Raid from a dropdown selection (16 raids including boss, wave and infinite) with Easy..Calamity difficulty and auto re-entry" },
		{ Type = "Added",   Text = "Farming tab: AutoTP On Boss NPC — teleports next to the raid boss on spawn and after each kill/respawn, checking CharacterStates.Health (real boss HP, not the engine Humanoid)" },
	},
})

-- ==================== GENERAL TAB ====================
Window:AddTabLine()

Tabs.General = Window:AddTab({ Name = "General", Icon = "Lucide:settings-2" })

-- ==================== AUTO JUDGEMAN MINIGAME ====================
-- Deadly Sentencing (Judgeman domain expansion) runs a minigame bar where an arrow
-- bounces across zones: Weaken, Confiscation, Death Penalty. Result determines the
-- debuff applied server-side. Exactly one result happens per run, so the three
-- toggles are mutually exclusive: each forces AutoJudgemanState.Result to its value
-- and silently switches the other two off. We hook the minigame bar constructor so
-- that when a mode is active, Result is always forced regardless of arrow position.
-- The hook intercepts every call to the bar constructor; for non-Judgeman minigames
-- (SFA) it passes through unchanged.
local AutoJudgemanState = { Result = nil }

local function SetToggleSilently(flag, value)
	local api = VindUI.Flags[flag]
	if api then
		api:Set(value, true)
	end
end

do
	local ok, err = pcall(function()
		local Client = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
		local HUD = Client:WaitForChild("Controllers"):WaitForChild("InterfaceController"):WaitForChild("Components"):WaitForChild("HUD")
		local MinigameBar = require(HUD:WaitForChild("JudgemanMinigameBar"))

		local CleanBar
		local wrapper

		wrapper = function(config)
			local bar = CleanBar(config)
			local forced = AutoJudgemanState.Result

			if forced and (not config.UIName or config.UIName == "Judgeman") then
				bar.Result = forced
				local origStop = bar.StopGame
				-- The bar's StopGame is declared with ZERO parameters, so Luau compiles
				-- `bar.StopGame()` as a direct free call: a reassigned hook receives NO
				-- receiver (self is nil). Force through the captured `bar` upvalue.
				bar.StopGame = function(self)
					pcall(origStop, bar)
					bar.Result = forced
				end
			end

			return bar
		end

		-- Chain to the un-hooked constructor from the heap, never onto an earlier
		-- hookfunction (the module is mutated in place, so the returned original of a
		-- previous hook would be garbage). Exclude the module's own current closure.
		for _, f in filtergc("function", { Constants = { "StopGame", "FadeIn", "DisplayResult", "StartGame" } }) do
			if f ~= MinigameBar then
				CleanBar = f
				break
			end
		end

		if not CleanBar then
			-- Fresh client: the module itself is still the clean constructor. Hook it
			-- and chain to the original that hookfunction hands back.
			CleanBar = hookfunction(MinigameBar, wrapper)
		else
			hookfunction(MinigameBar, wrapper)
		end
	end)

	if not ok then
		warn("[AutoJudgeman] Hook failed:", err)
	end
end

Tabs.General:AddSection("Judgeman", "Lucide:scale")

local function JudgemanResultNotify(value, title, mode)
	if value then
		AutoJudgemanState.Result = mode
	elseif AutoJudgemanState.Result == mode then
		AutoJudgemanState.Result = nil
	end
	getgenv().AutoJudgemanResult = AutoJudgemanState.Result
	VindUI:Notify({
		Title = title,
		Text = value and ("Enabled — " .. mode .. " guaranteed") or "Disabled",
		Type = value and "success" or "info",
		Duration = 2,
	})
end

Tabs.General:AddToggle({
	Text        = "Auto Death Penalty",
	Description = "Guarantees Death Penalty result during Deadly Sentencing for maximum impact",
	Icon        = "Lucide:skull",
	Flag        = "autoDeathPenalty",
	Default     = false,
	Callback    = function(value)
		if value then
			SetToggleSilently("autoConfiscation", false)
			SetToggleSilently("autoWeaken", false)
		end
		JudgemanResultNotify(value, "Auto Death Penalty", "DeathPenalty")
	end,
})

Tabs.General:AddToggle({
	Text        = "Auto Confiscation",
	Description = "Guarantees Confiscation result during Deadly Sentencing — severs the target's technique",
	Icon        = "Lucide:shield-ban",
	Flag        = "autoConfiscation",
	Default     = false,
	Callback    = function(value)
		if value then
			SetToggleSilently("autoDeathPenalty", false)
			SetToggleSilently("autoWeaken", false)
		end
		JudgemanResultNotify(value, "Auto Confiscation", "Confiscation")
	end,
})

Tabs.General:AddToggle({
	Text        = "Auto Weaken",
	Description = "Guarantees Weaken result during Deadly Sentencing — mild defensive debuff",
	Icon        = "Lucide:heart-crack",
	Flag        = "autoWeaken",
	Default     = false,
	Callback    = function(value)
		if value then
			SetToggleSilently("autoDeathPenalty", false)
			SetToggleSilently("autoConfiscation", false)
		end
		JudgemanResultNotify(value, "Auto Weaken", "Weaken")
	end,
})

Tabs.General:AddLineText("Im IDK what here add")

-- ==================== FARMING TAB ====================

Tabs.Farming = Window:AddTab({ Name = "Farming", Icon = "Lucide:wheat" })

local FarmingMain = Tabs.Farming:AddSubTab({ Name = "Controller", Icon = "Lucide:wheat" })
local RaidWorldTab = Tabs.Farming:AddSubTab({ Name = "World Raid", Icon = "Lucide:swords" })

FarmingMain:AddSection("Settings Farm", "Lucide:user")

-- === FREEZE CHARACTER IMPLEMENTATION ===
-- Jujutsu: Zero moves the visible (Visual/World) model by pivoting it to the
-- physics model (ServerModel) every frame, so snapping the WorldModel does
-- nothing. We anchor the real physics root inside ServerModel instead.
--
-- WARNING: we deliberately do NOT use the game's MovementComponent:LockMovement()
-- or Character.PhysicsDisabled. LockMovement raises the gate that SkillController
-- checks before casting (only skills flagged CanUseWhileMovementLocked pass),
-- and PhysicsDisabled makes GroundComponent stop updating. Both would brick
-- ability usage. A physical freeze (anchor + frame snap) holds the character
-- in place while keeping every skill condition intact.
local isFrozen = false
local freezeLoop = nil
local lastFrozenChar = nil
local frozenCFrame = nil

local function getCharacterController()
	local ok, mod = pcall(require, LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("CharacterController"))
	if ok and type(mod) == "table" then
		return mod
	end
	return nil
end

local function findLocalCharacter()
	local cc = getCharacterController()
	if cc then
		return cc.LocalCharacter
	end
	return nil
end

local function forceFreeze(char)
	if not char then return end
	pcall(function()
		local mc = char.MovementComponent
		if mc then
			mc.MovingDirection = Vector3.new(0, 0, 0)
			mc.WishMovingDirection = Vector3.new(0, 0, 0)
			mc.AbsoluteMovingDirection = Vector3.new(0, 0, 0)
		end

		local sm = char.ServerModel
		if sm and sm.PrimaryPart then
			if not frozenCFrame then
				frozenCFrame = sm.PrimaryPart.CFrame
			end
			sm.PrimaryPart.Anchored = true
			sm.PrimaryPart.CFrame = frozenCFrame
			sm.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

local function releaseFreeze(char)
	if not char then return end
	pcall(function()
		local sm = char.ServerModel
		if sm and sm.PrimaryPart then
			sm.PrimaryPart.Anchored = false
			sm.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

local function applyFreeze(freeze)
	if freeze then
		if freezeLoop then return end

		lastFrozenChar = nil
		frozenCFrame = nil
		forceFreeze(findLocalCharacter())

		-- Держим заморозку каждый кадр + автоматически пере-замораживаем после респауна
		freezeLoop = RunService.Heartbeat:Connect(function()
			local char = findLocalCharacter()
			if char then
				if char ~= lastFrozenChar then
					lastFrozenChar = char
					frozenCFrame = nil
				end
				forceFreeze(char)
			end
		end)
	else
		if freezeLoop then
			freezeLoop:Disconnect()
			freezeLoop = nil
		end
		releaseFreeze(lastFrozenChar)
		releaseFreeze(findLocalCharacter())
		lastFrozenChar = nil
		frozenCFrame = nil
		print("[DEBUG] Freeze DISABLED")
	end
end

FarmingMain:AddToggle({
	Text        = "Freeze Character",
	Description = "Completely freezes your character (ignores velocity/physics)",
	Icon        = "Lucide:snowflake",
	Flag        = "freezeChar",
	Default     = false,
	Callback    = function(value)
		isFrozen = value
		applyFreeze(value)
	end,
})

-- === AUTOCAST SYSTEM ===
-- Вместо эмуляции нажатия клавиш напрямую дёргаем SkillController:PlayerStartSkill("<слот>").
-- Это ровно то, что игра вызывает при нажатии клавиши (SKILL_1..6 / SPECIAL_SKILL /
-- DOMAIN_EXPANSION), так что кастуется именно способность эквипнутого техники-оружия
-- из того слота — никаких фейковых кликов по клавиатуре.
local SkillControllerModule = nil

local function getSkillController()
	if SkillControllerModule then return SkillControllerModule end
	local ok, mod = pcall(require, LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("SkillController"))
	if ok then SkillControllerModule = mod end
	return SkillControllerModule
end

-- Дефолтные привязки игры: R/F/C/X = Skill 1-4, Z/V = Skill 5-6, Y = Special, T = Domain
local AutoSlots = {
	{ Key = "R", Keybind = "SKILL_1",        Enabled = false, LastCast = 0, Interval = 0.4 },
	{ Key = "F", Keybind = "SKILL_2",        Enabled = false, LastCast = 0, Interval = 0.4 },
	{ Key = "C", Keybind = "SKILL_3",        Enabled = false, LastCast = 0, Interval = 0.4 },
	{ Key = "X", Keybind = "SKILL_4",        Enabled = false, LastCast = 0, Interval = 0.4 },
}

local SpecialSlots = {
	{ Key = "Z", Keybind = "SKILL_5",        Enabled = false, LastCast = 0, Interval = 0.5 },
	{ Key = "V", Keybind = "SKILL_6",        Enabled = false, LastCast = 0, Interval = 0.5 },
	{ Key = "Y", Keybind = "SPECIAL_SKILL",  Enabled = false, LastCast = 0, Interval = 0.5 },
	{ Key = "T", Keybind = "DOMAIN_EXPANSION", Enabled = false, LastCast = 0, Interval = 0.5 },
}

local AllSlots = {}
for _, slot in ipairs(AutoSlots) do table.insert(AllSlots, slot) end
for _, slot in ipairs(SpecialSlots) do table.insert(AllSlots, slot) end

local function addAutoToggles(group)
	for _, slot in ipairs(group) do
		local key = slot.Key
FarmingMain:AddToggle({
			Text        = "Auto " .. key,
			Description = "Auto-cast " .. slot.Keybind .. " (" .. key .. ")",
			Icon        = "Lucide:refresh-cw",
			Flag        = "auto" .. key,
			Default     = false,
			Callback    = function(value)
				slot.Enabled = value
				slot.LastCast = 0
				VindUI:Notify({
					Title = "Auto " .. key,
					Text = value and "Enabled" or "Disabled",
					Type = value and "success" or "info",
					Duration = 2,
				})
			end,
		})
	end
end

-- Общий цикл: кастуем НЕ чаще одного слота за тик, чтобы не упираться во
-- внутренний 0.1s throttle SkillController. Каждый слот соблюдает свой интервал.
task.spawn(function()
	while true do
		task.wait(0.08)
		local sc = getSkillController()
		if sc then
			local now = os.clock()
			for _, slot in ipairs(AllSlots) do
				if slot.Enabled and now - slot.LastCast >= slot.Interval then
					slot.LastCast = now
					pcall(sc.PlayerStartSkill, sc, slot.Keybind)
					break
				end
			end
		end
	end
end)

FarmingMain:AddLineText("AutoUse")
addAutoToggles(AutoSlots)

FarmingMain:AddLineText("Special AutoUse")
addAutoToggles(SpecialSlots)

-- ==================== AUTORAID ====================
-- Generic Overworld Raid auto-entry: supports ALL BossIslands in the game.
-- The entry flow is the same for every raid:
--   1) Teleport to the raid NPC (workspace.Map.StaticNPCs["BossIslands_<ConfigID>"])
--   2) Call BossIslandService.CreateIslandQueue({ConfigID=..., Difficulty=N, Modifiers={}})
--   3) Wait for the QueueZone to appear, snap into it, wait ~5s for the warp
--   4) BossIslandController.ActiveIsland flips non-nil once on the island
--   5) When the raid ends / game kicks you out, ActiveIsland → nil → re-enter
local RaidControllerModule = nil

local function getBossIslandController()
	if RaidControllerModule then return RaidControllerModule end
	local ok, mod = pcall(require, LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.BossIslandController)
	if ok then RaidControllerModule = mod end
	return RaidControllerModule
end

-- === RAID DATABASE ===
-- All Overworld Raids available in the game (boss raids, wave raids, infinite raids).
local OverworldRaids = {
	{ ConfigID = "Jogo",           Name = "Disaster Flame Curse",   MinLv = 100,  Type = "Boss" },
	{ ConfigID = "Toji",           Name = "Sorcerer Killer",        MinLv = 200,  Type = "Boss" },
	{ ConfigID = "TojiInf",        Name = "Sorcerer Killer (Inf)",  MinLv = 300,  Type = "Infinite" },
	{ ConfigID = "Kashimo",        Name = "God of Lightning",       MinLv = 400,  Type = "Boss" },
	{ ConfigID = "Judge",          Name = "Deadly Judge",           MinLv = 500,  Type = "Boss" },
	{ ConfigID = "Sukuna",         Name = "King of Curses",         MinLv = 650,  Type = "Boss" },
	{ ConfigID = "Maki",           Name = "Awakened Zen'in",        MinLv = 900,  Type = "Boss" },
	{ ConfigID = "ZeninSiege",     Name = "Zenin Siege",            MinLv = 1000, Type = "Wave" },
	{ ConfigID = "CurseCalamity",  Name = "Curse Calamity",         MinLv = 1000, Type = "Wave" },
	{ ConfigID = "AKashimo",       Name = "Awakened Lightning God", MinLv = 1250, Type = "Boss" },
	{ ConfigID = "AGojo",          Name = "The Honored One",        MinLv = 1500, Type = "Boss" },
	{ ConfigID = "Yuta",           Name = "Cursed Prodigy",         MinLv = 1750, Type = "Boss" },
	{ ConfigID = "AToji",          Name = "Awakened Toji",          MinLv = 2000, Type = "Boss" },
	{ ConfigID = "Choso",          Name = "Eldest Womb",            MinLv = 2500, Type = "Boss" },
	{ ConfigID = "SukunaInf",      Name = "King of Curses (Inf)",   MinLv = 3000, Type = "Infinite" },
	{ ConfigID = "StarRage",       Name = "The Manifested Star",    MinLv = 3500, Type = "Boss" },
}

-- Display names for the dropdown (sorted by MinLv for easy scanning)
local RaidDisplayNames = {}
local RaidByDisplayName = {}
for _, raid in ipairs(OverworldRaids) do
	local label = string.format("[%d] %s", raid.MinLv, raid.Name)
	table.insert(RaidDisplayNames, label)
	RaidByDisplayName[label] = raid
end

local RaidDifficultyOptions = { "Easy", "Normal", "Hard", "Nightmare", "Calamity" }

local function raidDifficultyIndex(name)
	for i, n in ipairs(RaidDifficultyOptions) do
		if n == name then return i end
	end
	return 1
end

-- State: which raid is selected
getgenv().AutoRaidSelectedRaid = getgenv().AutoRaidSelectedRaid or RaidDisplayNames[1]
getgenv().AutoRaidDifficulty = raidDifficultyIndex(getgenv().AutoRaidDifficultyName) or 1

local function getSelectedRaidConfig()
	local label = getgenv().AutoRaidSelectedRaid or RaidDisplayNames[1]
	return RaidByDisplayName[label] or OverworldRaids[1]
end

-- One full entry attempt for ANY raid ConfigID: teleport to NPC, create queue
-- portal, step into its waiting zone and stay until the island starts.
-- Returns true only when ActiveIsland confirms we are on the raid.
local function EnterRaid(configID)
	local ok, err = pcall(function()
		local Net = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.NetworkController)
		local Char = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.CharacterController)
		local BIC = getBossIslandController()
		local QZ = require(game:GetService("ReplicatedStorage").Shared.Libraries.QueueZoneLib)

		if not BIC then error("BossIslandController not found") end
		if BIC.ActiveIsland then return true end

		local diff = tonumber(getgenv().AutoRaidDifficulty) or 1
		local diffName = RaidDifficultyOptions[diff] or "Easy"

		-- 1. Wait out a death so the server can count us in the zone.
		local lc = Char.LocalCharacter
		if lc and lc.ServerModel then
			local humanoid = lc.ServerModel:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				local waited = 0
				while humanoid.Health <= 0 and waited < 8 do
					task.wait(0.5)
					waited = waited + 0.5
				end
			end
		end

		-- 2. Teleport to the raid NPC.
		local npcPath = "BossIslands_" .. configID
		local npc = workspace.Map:FindFirstChild("StaticNPCs") and workspace.Map.StaticNPCs:FindFirstChild(npcPath)
		lc = Char.LocalCharacter
		if npc and lc and lc.ServerModel then
			local part = npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
			if part then
				lc.ServerModel:SetPrimaryPartCFrame(part.CFrame * CFrame.new(0, 4, 0))
				task.wait(0.3)
			end
		end

		-- 3. Create the queue portal for this ConfigID at the chosen difficulty.
		local m = Net.GetRemoteMethod("BossIslandService", "CreateIslandQueue")
		local created, createErr = m:Call({ ConfigID = configID, Difficulty = diff, Modifiers = {} }):await()
		if not created then
			error("CreateIslandQueue(" .. configID .. ", " .. diffName .. ") refused: " .. tostring(createErr))
		end

		-- 4. Wait for the portal to appear, snap into its waiting zone, stay until warp.
		task.wait(0.5)
		local zone
		for _ = 1, 50 do
			for _, v in pairs(QZ.QueueZones) do
				if v.BossIslandConfigID == configID then
					zone = v
					break
				end
			end
			if zone then break end
			task.wait(0.2)
		end
		if not zone then error("Queue zone for " .. configID .. " did not appear") end

		local started = os.clock()
		while os.clock() - started < 25 and not BIC.ActiveIsland do
			task.wait(0.1)
			if lc and lc.ServerModel then
				lc.ServerModel:SetPrimaryPartCFrame(zone.Zone.CFrame * CFrame.new(0, 3, 0))
			end
			local alive = false
			for _, v in pairs(QZ.QueueZones) do
				if v.BossIslandConfigID == configID then
					zone = v
					alive = true
					break
				end
			end
			if not alive and not BIC.ActiveIsland then
				error("Queue zone for " .. configID .. " vanished before the island started")
			end
		end

		return BIC.ActiveIsland ~= nil
	end)
	return ok, err
end

getgenv().AutoRaidEnabled = false

local function stopAutoRaid()
	getgenv().AutoRaidEnabled = false
end

local function StartAutoRaid()
	stopAutoRaid()
	getgenv().AutoRaidEnabled = true
	task.spawn(function()
		local fails = 0
		while getgenv().AutoRaidEnabled do
			local BIC = getBossIslandController()
			if BIC and BIC.ActiveIsland then
				fails = 0
				task.wait(2)
			else
				local raid = getSelectedRaidConfig()
				local ok, err = EnterRaid(raid.ConfigID)
				if ok then
					fails = 0
					VindUI:Notify({ Title = "AutoRaid", Text = "Entered " .. raid.Name .. " raid", Type = "success", Duration = 3 })
				else
					fails = fails + 1
					VindUI:Notify({ Title = "AutoRaid", Text = raid.Name .. " entry failed: " .. tostring(err), Type = "error", Duration = 4 })
				end
				task.wait(fails >= 3 and 20 or 3)
			end
			task.wait(0.5)
		end
	end)
end

RaidWorldTab:AddLineText("AutoWorldRaid")

RaidWorldTab:AddDropdown({
	Text        = "Select World Raid",
	Description = "Choose which Overworld Raid to auto-farm",
	Icon        = "Lucide:swords",
	Options     = RaidDisplayNames,
	Default     = RaidDisplayNames[1],
	Flag        = "autoRaidSelection",
	Callback    = function(v)
		getgenv().AutoRaidSelectedRaid = v
	end,
})

RaidWorldTab:AddDropdown({
	Text        = "Raid Difficulty",
	Description = "Difficulty for the selected world raid (Easy .. Calamity)",
	Icon        = "Lucide:list",
	Options     = RaidDifficultyOptions,
	Default     = "Easy",
	Flag        = "autoRaidDifficulty",
	Callback    = function(v)
		getgenv().AutoRaidDifficulty = raidDifficultyIndex(v)
		getgenv().AutoRaidDifficultyName = v
	end,
})

RaidWorldTab:AddToggle({
	Text        = "AutoRaid",
	Description = "Auto-enters the selected Overworld Raid. Re-enters automatically if the game kicks you out.",
	Icon        = "Lucide:swords",
	Flag        = "autoRaid",
	Default     = false,
	Callback    = function(value)
		if value then
			StartAutoRaid()
		else
			stopAutoRaid()
		end
	end,
})

-- === AUTOTP ON BOSS ===
-- Generic boss TP: works for any raid that has a BossNPC (boss raids, not wave raids).
-- BossNPC.ServerModel is the physics model; real HP is in CharacterStates.Health.
-- A dead boss keeps its model for a moment, so "alive" = CharacterStates.Health > 0.
local AutoBossTPEnabled = false

local function getRaidBoss()
	local BIC = getBossIslandController()
	if not BIC or not BIC.ActiveIsland then return nil end
	return BIC.ActiveIsland.BossNPC, BIC
end

local function isRaidBossAlive(boss)
	if not boss then return false end
	local cs = boss.Character and boss.Character.CharacterStates
	return cs ~= nil and (cs.Health or 0) > 0
end

local function getBossRootPart(boss)
	local sm = boss.ServerModel
	if not sm then return nil end
	return sm.PrimaryPart or sm:FindFirstChild("HumanoidRootPart")
end

local function teleportToBossOnce()
	local pcallOK, status = pcall(function()
		local boss = getRaidBoss()
		if not boss then return "no_raid" end
		if not isRaidBossAlive(boss) then return "boss_dead" end

		local root = getBossRootPart(boss)
		if not root then return "no_root" end

		local CC = getCharacterController()
		local lc = CC and CC.LocalCharacter
		if not (lc and lc.ServerModel and lc.ServerModel.PrimaryPart) then return "no_char" end

		local target = CFrame.lookAt(root.Position + Vector3.new(10, 4, 10), root.Position)
		lc.ServerModel:SetPrimaryPartCFrame(target)
		return "tp"
	end)
	return pcallOK and status
end

local function StartBossTP()
	AutoBossTPEnabled = true
	getgenv().AutoBossTPEnabled = true
	task.spawn(function()
		local lastRoot = nil
		while AutoBossTPEnabled do
			task.wait(0.6)
			local boss = getRaidBoss()
			if not boss then
				lastRoot = nil
			else
				if isRaidBossAlive(boss) then
					local root = getBossRootPart(boss)
					local CC = getCharacterController()
					local myPos = CC and CC.LocalCharacter and CC.LocalCharacter.ServerModel and CC.LocalCharacter.ServerModel.PrimaryPart and CC.LocalCharacter.ServerModel.PrimaryPart.Position
					local dist = myPos and root and (myPos - root.Position).Magnitude or 9999
					if root and (lastRoot ~= root or dist > 35) then
						local status = teleportToBossOnce()
						if status ~= "boss_dead" and status ~= "no_raid" then
							lastRoot = root
						end
					end
				else
					lastRoot = nil
				end
			end
		end
	end)
end

local function StopBossTP()
	AutoBossTPEnabled = false
	getgenv().AutoBossTPEnabled = false
end

RaidWorldTab:AddToggle({
	Text        = "AutoTP On Boss NPC",
	Description = "Teleports you next to the raid boss the moment it is alive (on spawn and after kill/respawn). Only works for boss raids (not wave raids).",
	Icon        = "Lucide:crosshair",
	Flag        = "autoTPBoss",
	Default     = false,
	Callback    = function(value)
		if value then
			StartBossTP()
		else
			StopBossTP()
		end
	end,
})

-- ==================== BYPASS TAB ====================

Tabs.Bypass = Window:AddTab({ Name = "Bypass", Icon = "Lucide:shield" })

Tabs.Bypass:AddSection("Quest Level Bypass", "Lucide:target")

-- === [1360LVL] AUTO CLAIM ONMITSU ELITE ===
-- Onmitsu Elite = MysteriousSorcerer3 (defeat 4x OnmitsuElite, reward Cursed Crate III).
-- Normally the dialogue UI blocks anyone below Lv 1360 ("You must be level 1360...").
-- That level gate lives ONLY in the dialogue interface: the real claim is the
-- QuestService.AcceptQuest remote, which the UI fires AFTER the check. So calling
-- the remote directly skips the level restriction entirely (verified live: the
-- quest flips to active with one direct call). Caveat: the game stores quests per
-- character with IsFinished=true once done, so a character that already finished
-- the Onmitsu chain cannot re-claim it — that is the game's own state, not the
-- bypass. Works on characters that have never taken this quest (e.g. a fresh alt).
local function AutoClaimOnmitsuElite()
	task.spawn(function()
		local ok, err = pcall(function()
			local Net = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.NetworkController)
			local Quest = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.QuestController)
			local Char = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.CharacterController)
			local PlayerData = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.PlayerDataController)
			local PlaceHelper = require(game:GetService("ReplicatedStorage").Shared.Libraries.PlaceHelper)

			if PlaceHelper:IsSystemDisabled("Quest") then
				VindUI:Notify({ Title = "[1360LVL]", Text = "Quest system is disabled here", Type = "error", Duration = 3 })
				return
			end

			-- Сбрасываем текущий квест, чтобы новый можно было взять
			local current = Quest:GetActiveQuest()
			if current then
				Quest:CancelQuest(current.ID)
				task.wait(0.6)
			end

			-- Подходим к NPC "Mysterious Sorcerer" (Quest26), если квест принимается не с любой дистанции
			local npc = workspace.Map:FindFirstChild("StaticNPCs") and workspace.Map.StaticNPCs:FindFirstChild("Quest26")
			if npc then
				local part = npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
				local lc = Char.LocalCharacter
				if part and lc and lc.ServerModel then
					lc.ServerModel:SetPrimaryPartCFrame(CFrame.new(part.Position + Vector3.new(2, 3, 2)))
					task.wait(0.3)
				end
			end

			-- Клейм напрямую на сервере — точно тот же вызов, что делает игра после проверки уровня
			local qs = Net.GetNamespace("QuestService")
			local accept = Net.GetRemoteMethod(qs, "AcceptQuest")
			accept:Call("MysteriousSorcerer3")
			task.wait(1.2)

			local claimed = Quest:GetActiveQuest()
			if claimed and claimed.ID == "MysteriousSorcerer3" then
				VindUI:Notify({ Title = "[1360LVL]", Text = "Onmitsu Elite claimed!", Type = "success", Duration = 4 })
			else
				VindUI:Notify({ Title = "[1360LVL]", Text = "Claim failed — server did not activate the quest", Type = "error", Duration = 4 })
			end
		end)
		if not ok then
			VindUI:Notify({ Title = "[1360LVL]", Text = "Error: " .. tostring(err), Type = "error", Duration = 5 })
		end
	end)
end

Tabs.Bypass:AddButton({
	Text        = "[1360LVL] Auto Claim Onmitsu Elite",
	Description = "Claims the Onmitsu Elite quest (Lv 1360) from Mysterious Sorcerer. Calls QuestService.AcceptQuest directly, skipping the client-side level gate — works even below Lv 1360. (Now dont work)",
	Icon        = "Lucide:zap",
	Callback    = AutoClaimOnmitsuElite,
})

-- ==================== COMPARATOR TAB ====================

Tabs.Comparator = Window:AddTab({ Name = "Comparator", Icon = "Lucide:scale" })

Tabs.Comparator:AddParagraph({
	Title = "Gear Comparator",
	Text = "Scans all gears in your inventory (incl. equipped), computes a weighted score, and ranks them. Click any column header to sort. ★ = best in category.",
})

Tabs.Comparator:AddDropdown({
	Text        = "Score Weighting",
	Description = "Changes how stats are weighted when ranking gears",
	Icon        = "Lucide:sliders",
	Options     = {"Balanced", "Crit DMG", "ATK"},
	Default     = "Balanced",
	Flag        = "cmpPreset",
})

local cmpSummaryLabel = Tabs.Comparator:AddLabel("Press 'Scan & Compare' to analyze your gears.")

local SCORE_WEIGHTS = {
	Balanced = {
		["CD%"] = 4, ["CR%"] = 3, ["ATK%"] = 3, ["ATK"] = 0.06,
		["CDR%"] = 2, ["CER%"] = 2, ["CE%"] = 1.5, ["CE"] = 0.02,
		["HP%"] = 1, ["HP"] = 0.01, ["DR%"] = 1.5,
	},
	["Crit DMG"] = {
		["CD%"] = 8, ["CR%"] = 4, ["ATK%"] = 2, ["ATK"] = 0.04,
		["CDR%"] = 1, ["CER%"] = 0.5, ["CE%"] = 0.5, ["CE"] = 0.01,
		["HP%"] = 0.3, ["HP"] = 0.003, ["DR%"] = 0.5,
	},
	ATK = {
		["CD%"] = 2, ["CR%"] = 1, ["ATK%"] = 6, ["ATK"] = 0.12,
		["CDR%"] = 1, ["CER%"] = 0.5, ["CE%"] = 0.5, ["CE"] = 0.01,
		["HP%"] = 0.3, ["HP"] = 0.003, ["DR%"] = 0.5,
	},
}

local PCT_STATS = { ["CD%"] = true, ["CR%"] = true, ["ATK%"] = true, ["CDR%"] = true, ["CER%"] = true, ["CE%"] = true, ["HP%"] = true, ["DR%"] = true }

local cmpTable = Tabs.Comparator:AddTable({
	Title       = "Gear Ranking",
	Description = "All gears ranked by weighted score. Click a column header to sort.",
	Columns     = {
		{ Key = "Name",   Label = "Gear",     Weight = 2.4, Emphasized = true },
		{ Key = "Slot",   Label = "Slot",     Weight = 0.6, Align = "Center" },
		{ Key = "Set",    Label = "Set",      Weight = 1.0 },
		{ Key = "CD%",    Label = "CD%",      Weight = 0.9, Align = "Right" },
		{ Key = "CR%",    Label = "CR%",      Weight = 0.8, Align = "Right" },
		{ Key = "ATK%",   Label = "ATK%",     Weight = 0.9, Align = "Right" },
		{ Key = "ATK",    Label = "ATK",      Weight = 0.8, Align = "Right" },
		{ Key = "CDR%",   Label = "CDR%",     Weight = 0.8, Align = "Right" },
		{ Key = "CER%",   Label = "CER%",     Weight = 0.8, Align = "Right" },
		{ Key = "Score",  Label = "Score",    Weight = 1.0, Align = "Right" },
	},
	Rows    = {},
	Height  = 140,
	Sortable = true,
	Striped  = true,
})

Tabs.Comparator:AddButton({
	Text        = "Scan & Compare",
	Description = "Rescan inventory, recalculate scores, and rank all gears",
	Icon        = "Lucide:refresh-cw",
	Callback    = function()
		local ok, err = pcall(function()
			local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
			local iconv = require(PlayerScripts.Client.Controllers.InventoryController)
			local ci = iconv.CurrentInventory
			if not ci or not ci.Items then
				VindUI:Notify({ Title = "Comparator", Text = "Inventory not loaded yet", Type = "error", Duration = 3 })
				return
			end

			local sc = require(game:GetService("ReplicatedStorage").Configs.StatsConfig)
			local itemConfig = require(game:GetService("ReplicatedStorage").Configs.ItemConfig)
			local pctSet = {}
			for _, s in ipairs(sc.PercentageStats or {}) do pctSet[s] = true end

			local presetName = "Balanced"
			if VindUI.Flags.cmpPreset then
				presetName = VindUI.Flags.cmpPreset:Get() or "Balanced"
			end
			local weights = SCORE_WEIGHTS[presetName] or SCORE_WEIGHTS.Balanced

			local slotMap = ci.GearSlots or {}
			local emblemSet = {}
			for _, name in ipairs(itemConfig.GearSlot4Items or {}) do emblemSet[name] = true end

			local rows = {}
			local equippedSlotIds = {}
			for s, eid in pairs(slotMap) do equippedSlotIds[eid] = tostring(s) end

			for id, item in pairs(ci.Items or {}) do
				if item and item.Type == "Gear" then
					local sv = {}
					for _, e in ipairs(item.Stats or {}) do sv[e[1]] = (sv[e[1]] or 0) + e[2] end
					if item.MainStat and item.MainStat[1] then
						sv[item.MainStat[1]] = (sv[item.MainStat[1]] or 0) + item.MainStat[2]
					end
					if item.SubStat and item.SubStat[1] then
						sv[item.SubStat[1]] = (sv[item.SubStat[1]] or 0) + item.SubStat[2]
					end
					for _, e in ipairs(item.Passives or {}) do sv[e[1]] = (sv[e[1]] or 0) + e[2] end

					local score = 0
					for sn, sv2 in pairs(sv) do
						local w = weights[sn]
						if w then
							score = score + (PCT_STATS[sn] and (sv2 * 100 * w) or (sv2 * w))
						end
					end

					local slotStr = "-"
					local eqSlot = equippedSlotIds[id]
					if eqSlot then slotStr = "E" .. eqSlot end

					local row = {
						Name  = item.Name,
						Slot  = slotStr,
						Set   = (#(item.Sets or {}) > 0) and item.Sets[1] or "",
						Score = math.floor(score * 10 + 0.5) / 10,
						_E    = emblemSet[item.ConfigID] or false,
						_ID   = id,
					}
					for _, sn in ipairs({"CD%", "CR%", "ATK%", "ATK", "CDR%", "CER%"}) do
						local v = sv[sn]
						if v then
							row[sn] = PCT_STATS[sn] and (math.floor(v * 10000 + 0.5) / 100) or (math.floor(v * 100 + 0.5) / 100)
						else
							row[sn] = 0
						end
					end
					rows[#rows + 1] = row
				end
			end

			if #rows == 0 then
				VindUI:Notify({ Title = "Comparator", Text = "No gear items found", Type = "error", Duration = 3 })
				return
			end

			table.sort(rows, function(a, b) return a.Score > b.Score end)

			local bestRegIdx, bestEmbIdx
			for i, r in ipairs(rows) do
				if r._E and not bestEmbIdx then bestEmbIdx = i
				elseif not r._E and not bestRegIdx then bestRegIdx = i end
				if bestRegIdx and bestEmbIdx then break end
			end

			local displayRows = {}
			for i, r in ipairs(rows) do
				local dr = {}
				for k, v in pairs(r) do
					if k ~= "_E" and k ~= "_ID" then dr[k] = v end
				end
				if i == bestRegIdx or i == bestEmbIdx then
					dr.Name = "★ " .. dr.Name
				end
				displayRows[#displayRows + 1] = dr
			end
			cmpTable:SetRows(displayRows)

			local summary = string.format("Found %d gears | Weighting: %s", #rows, presetName)
			if bestRegIdx then
				local r = rows[bestRegIdx]
				local tag = r.Slot ~= "-" and " (equipped " .. r.Slot .. ")" or " (unequipped)"
				summary = summary .. "\n★ Best gear (slots 1-3): " .. r.Name .. tag
			end
			if bestEmbIdx then
				local r = rows[bestEmbIdx]
				local tag = r.Slot ~= "-" and " (equipped " .. r.Slot .. ")" or " (unequipped)"
				summary = summary .. "\n★ Best emblem (slot 4):  " .. r.Name .. tag
			end
			cmpSummaryLabel:Set(summary)

			VindUI:Notify({
				Title    = "Comparator",
				Text     = string.format("Ranked %d gears", #rows),
				Type     = "success",
				Duration = 3,
			})
		end)
		if not ok then
			VindUI:Notify({ Title = "Comparator", Text = "Error: " .. tostring(err), Type = "error", Duration = 5 })
		end
	end,
})

Tabs.Comparator:AddButton({
	Text        = "Equip Best Gear",
	Description = "Unequips every current gear first, then equips the 3 best regular gears plus the best emblem (by the selected weighting)",
	Icon        = "Lucide:sparkles",
	Callback    = function()
		local ok, err = pcall(function()
			local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
			local iconv = require(PlayerScripts.Client.Controllers.InventoryController)
			local ci = iconv.CurrentInventory
			if not ci or not ci.Items then
				VindUI:Notify({ Title = "Comparator", Text = "Inventory not loaded yet", Type = "error", Duration = 3 })
				return
			end

			local itemConfig = require(game:GetService("ReplicatedStorage").Configs.ItemConfig)
			local pdc = require(PlayerScripts.Client.Controllers.PlayerDataController)
			local pd = pdc.PlayerData or {}
			local myLevel = (pd.Stats or {}).Level or 0
			local gear4Unlocked = (pd.Flags or {}).IsGear4Unlocked

			local presetName = "Balanced"
			if VindUI.Flags.cmpPreset then
				presetName = VindUI.Flags.cmpPreset:Get() or "Balanced"
			end
			local weights = SCORE_WEIGHTS[presetName] or SCORE_WEIGHTS.Balanced

			local emblemSet = {}
			for _, name in ipairs(itemConfig.GearSlot4Items or {}) do emblemSet[name] = true end

			local regular, emblems = {}, {}
			local toUnequip = {}
			for id, item in pairs(ci.Items or {}) do
				if item and item.Type == "Gear" then
					local sv = {}
					for _, e in ipairs(item.Stats or {}) do sv[e[1]] = (sv[e[1]] or 0) + e[2] end
					if item.MainStat and item.MainStat[1] then
						sv[item.MainStat[1]] = (sv[item.MainStat[1]] or 0) + item.MainStat[2]
					end
					if item.SubStat and item.SubStat[1] then
						sv[item.SubStat[1]] = (sv[item.SubStat[1]] or 0) + item.SubStat[2]
					end
					for _, e in ipairs(item.Passives or {}) do sv[e[1]] = (sv[e[1]] or 0) + e[2] end

					local score = 0
					for sn, sv2 in pairs(sv) do
						local w = weights[sn]
						if w then
							score = score + (PCT_STATS[sn] and (sv2 * 100 * w) or (sv2 * w))
						end
					end

					local entry = {
						ID       = id,
						Name     = item.Name,
						Score    = score,
						CanEquip = not (item.LevelReq and myLevel < item.LevelReq),
					}
					if emblemSet[item.ConfigID] then
						emblems[#emblems + 1] = entry
					else
						regular[#regular + 1] = entry
					end

					if item.Equipped then
						toUnequip[#toUnequip + 1] = id
					end
				end
			end

			table.sort(regular, function(a, b) return a.Score > b.Score end)
			table.sort(emblems, function(a, b) return a.Score > b.Score end)

			local pickRegular, pickEmblem = {}, nil
			for _, e in ipairs(regular) do
				if e.CanEquip and #pickRegular < 3 then
					pickRegular[#pickRegular + 1] = e
				end
			end
			if gear4Unlocked then
				for _, e in ipairs(emblems) do
					if e.CanEquip then
						pickEmblem = e
						break
					end
				end
			end

			local unequipped = #toUnequip
			for _, id in ipairs(toUnequip) do
				iconv:UnequipItem(id)
			end

			local equipped = {}
			for _, e in ipairs(pickRegular) do
				iconv:EquipItem(e.ID)
				equipped[#equipped + 1] = e.Name
			end
			if pickEmblem then
				iconv:EquipItem(pickEmblem.ID)
				equipped[#equipped + 1] = pickEmblem.Name .. " (emblem)"
			end

			local summary = string.format("Unequipped %d | Equipped %d best | %s", unequipped, #equipped, presetName)
			if #equipped > 0 then
				summary = summary .. "\nNow on: " .. table.concat(equipped, ", ")
			else
				summary = summary .. "\nNothing to equip"
			end
			cmpSummaryLabel:Set(summary)

			VindUI:Notify({
				Title    = "Comparator",
				Text     = string.format("Unequipped %d, equipped %d best gears", unequipped, #equipped),
				Type     = "success",
				Duration = 3,
			})
		end)
		if not ok then
			VindUI:Notify({ Title = "Comparator", Text = "Error: " .. tostring(err), Type = "error", Duration = 5 })
		end
	end,
})

-- ==================== COLLECTOR TAB ====================
-- Collects EVERY chest type. Live crates are Parts under
-- workspace.Map.ActiveCrates named "<Type>_<index>" — the config key is the part
-- name prefix before the first underscore. MapController.AddCrate spawns a
-- ProximityPrompt on each unopened crate and InteractCrate destroys that prompt
-- and calls OpenCrate(part.Name). We drive that exact path: teleport
-- ServerModel + WorldModel next to the crate, then fire
-- InterfaceController.Interfaces.Interact.Interacted with the crate's RAW prompt
-- instance (MapController matches it by reference, so running InteractCrate is
-- guaranteed). Crates already in PlayerData.ExplorationCrates get skipped.
getgenv().AutoCollectChest = getgenv().AutoCollectChest or false
getgenv().AutoCollectTypes = getgenv().AutoCollectTypes or {}
getgenv().InstaProxPrompt = getgenv().InstaProxPrompt or true

-- Normal open-world crates on top; crate-rain-only chests (Admin Events) at the
-- very bottom under a divider line, per feature spec.
local CollectorTypes = {
	{ ID = "Expl1",            Label = "Grade 3 Crate (Expl1)" },
	{ ID = "Expl2",            Label = "Grade 2 Crate (Expl2)" },
	{ ID = "Expl3",            Label = "Grade 1 Crate (Expl3)" },
	{ ID = "SpecialCrate",     Label = "Special Crate" },
	{ ID = "OverworldFinal-1", Label = "Final Crate I" },
	{ ID = "OverworldFinal-2", Label = "Final Crate II" },
	{ ID = "OverworldFinal-3", Label = "Final Crate III" },
	{ ID = "OverworldFinal-4", Label = "Final Crate IV" },
	{ ID = "OverworldFinal-5", Label = "Final Crate V" },
	{ ID = "OverworldFinal-6", Label = "Final Crate VI" },
	{ ID = "Invest1",          Label = "Hidden Crate (Invest1)" },
	{ ID = "SummerExpl",       Label = "Beach Ball (SummerExpl)" },
	{ ID = "SummerSpecial",    Label = "Beach Ball (SummerSpecial)" },
}

local CollectorAdminEventTypes = {
	{ ID = "LiveEventCrate1",  Label = "Event Crate" },
	{ ID = "LiveEventCrate2",  Label = "Lucky Event Crate" },
	{ ID = "LiveEventCrate3",  Label = "Boosted Event Crate" },
	{ ID = "TechniqueCrate",   Label = "Technique Crate" },
	{ ID = "DivineCrate",      Label = "Divine Crate" },
	{ ID = "LevelTestCrate",   Label = "Level Test Crate" },
}

for _, t in ipairs(CollectorTypes) do
	if getgenv().AutoCollectTypes[t.ID] == nil then
		getgenv().AutoCollectTypes[t.ID] = true
	end
end
for _, t in ipairs(CollectorAdminEventTypes) do
	if getgenv().AutoCollectTypes[t.ID] == nil then
		getgenv().AutoCollectTypes[t.ID] = true
	end
end

local function setCollectType(id, value)
	getgenv().AutoCollectTypes[id] = value
end

local localCharacter = nil

local function collectorTeleportTo(cratePos)
	if not localCharacter then return end
	local target = cratePos + Vector3.new(0, 1, 0)
	local spot = CFrame.lookAt(target + Vector3.new(4, 5, 4), target)
	if localCharacter.ServerModel and localCharacter.ServerModel.PrimaryPart then
		localCharacter.ServerModel:SetPrimaryPartCFrame(spot)
	end
	if localCharacter.WorldModel and localCharacter.WorldModel.PrimaryPart then
		localCharacter.WorldModel.PrimaryPart.CFrame = spot
	end
end

local function collectOnce()
	local ok, err = pcall(function()
		local PlayerDataController = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.PlayerDataController)
		local Interact = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.InterfaceController.Interfaces.Interact)
		local CC = getCharacterController()
		localCharacter = CC and CC.LocalCharacter

		local folder = workspace.Map:FindFirstChild("ActiveCrates")
		if not (folder and localCharacter and localCharacter.ServerModel and Interact.Interacted) then return end

		for _, crate in folder:GetChildren() do
			if not getgenv().AutoCollectChest then break end
			local typeID = crate.Name:split("_")[1]

			local prompt = crate:FindFirstChildWhichIsA("ProximityPrompt")
			local inOpened = PlayerDataController.PlayerData.ExplorationCrates[crate.Name] ~= nil

			if getgenv().AutoCollectTypes[typeID]
				and not inOpened
				and prompt
				and prompt.Enabled
			then
				collectorTeleportTo(crate.Position)

				if getgenv().InstaProxPrompt then
					task.wait(0.25)
					Interact.Interacted:Fire(prompt)
				else
					-- Wait for the game to actually show this prompt, then open it.
					local PPS = game:GetService("ProximityPromptService")
					local shown = false
					local conn = PPS.PromptShown:Connect(function(p)
						if p == prompt then shown = true end
					end)
					local t0 = os.clock()
					while not shown and os.clock() - t0 < 2.5 and getgenv().AutoCollectChest do
						task.wait(0.05)
					end
					conn:Disconnect()
					if shown then
						Interact.Interacted:Fire(prompt)
					end
				end

				-- Wait for the server to confirm (crate removed from opened set / node gone).
				local t1 = os.clock()
				while os.clock() - t1 < 2.2 and getgenv().AutoCollectChest do
					if PlayerDataController.PlayerData.ExplorationCrates[crate.Name] then break end
					if not folder:FindFirstChild(crate.Name) then break end
					task.wait(0.1)
				end
			end
		end
	end)
	if not ok then
		warn("Reversal Collect: " .. tostring(err))
	end
end

local function StartCollector()
	getgenv().AutoCollectChest = true
	task.spawn(function()
		while getgenv().AutoCollectChest do
			collectOnce()
			task.wait(0.8)
		end
	end)
end

local function StopCollector()
	getgenv().AutoCollectChest = false
end

Tabs.Collector = Window:AddTab({ Name = "Collector", Icon = "Lucide:gift" })

Tabs.Collector:AddSection("Crate Collection", "Lucide:box")

Tabs.Collector:AddToggle({
	Text        = "Auto Collect Chest",
	Description = "Teleports to every enabled chest type and opens it through the game's own interact flow (prompt -> Interact -> OpenCrate).",
	Icon        = "Lucide:gift",
	Flag        = "autoCollectChest",
	Default     = false,
	Callback    = function(value)
		if value then StartCollector() else StopCollector() end
	end,
})

for _, t in ipairs(CollectorTypes) do
	Tabs.Collector:AddToggle({
		Text        = t.Label,
		Icon        = "Lucide:package",
		Flag        = "collect_" .. t.ID:gsub("[^%w]", "_"),
		Default     = getgenv().AutoCollectTypes[t.ID],
		Callback    = function(value)
			setCollectType(t.ID, value)
		end,
	})
end

Tabs.Collector:AddLineText("Admin Events")

for _, t in ipairs(CollectorAdminEventTypes) do
	Tabs.Collector:AddToggle({
		Text        = t.Label,
		Icon        = "Lucide:star",
		Flag        = "collect_" .. t.ID:gsub("[^%w]", "_"),
		Default     = getgenv().AutoCollectTypes[t.ID],
		Callback    = function(value)
			setCollectType(t.ID, value)
		end,
	})
end

-- ==================== DIVIDER LINE ====================
Window:AddTabLine()

-- ==================== SETTINGS TAB ====================

Tabs.Settings = Window:AddTab({ Name = "Settings", Icon = "Lucide:sliders-horizontal" })

Tabs.Settings:AddSection("Performance", "Lucide:zap")

Tabs.Settings:AddButton({
	Text        = "Apply Low Graphics",
	Description = "Lowers graphics quality for better FPS",
	Icon        = "Lucide:monitor-down",
	Callback    = function()
		game.Lighting.GlobalShadows = false
		game.Lighting.FogEnd = 100000
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.Plastic
			end
		end
		VindUI:Notify({
			Title = "Graphics",
			Text = "Low Graphics mode applied",
			Type = "success",
			Duration = 3
		})
	end,
})

-- ==================== ANTI-AFK ====================
-- The kick is triggered by Roblox firing Players.LocalPlayer.Idled after a
-- stretch of no input — that's what lets the server mark you idle and TP/kick
-- you. The standard fix is to answer that idle check the INSTANT it fires via
-- VirtualUser:CaptureController (plus ClickButton2, matching the canonical
-- anti-AFK). No movement, no teleports.
local AntiAFKConn = nil
local VirtualUser = game:GetService("VirtualUser")

local function SetAntiAFK(on)
	getgenv().AntiAFKEnabled = on
	if on and not AntiAFKConn then
		AntiAFKConn = LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
		VindUI:Notify({ Title = "Anti AFK", Text = "Enabled", Type = "success", Duration = 2 })
	elseif not on then
		if AntiAFKConn then
			AntiAFKConn:Disconnect()
			AntiAFKConn = nil
		end
		VindUI:Notify({ Title = "Anti AFK", Text = "Disabled", Type = "info", Duration = 2 })
	end
end

Tabs.Settings:AddToggle({
	Text        = "Anti AFK",
	Description = "Answers Roblox's idle check (Idled -> VirtualUser) the instant it fires, so the server never idle-kicks you.",
	Icon        = "Lucide:activity",
	Flag        = "antiAfk",
	Default     = true,
	Callback    = SetAntiAFK,
})

Tabs.Settings:AddToggle({
	Text        = "Insta proximity prompt",
	Description = "Auto Collect Chest: instantly triggers the crate's ProximityPrompt right after teleport, instead of waiting for the game to draw the prompt/interact option first.",
	Icon        = "Lucide:mouse-pointer-click",
	Flag        = "instaProxPrompt",
	Default     = getgenv().InstaProxPrompt,
	Callback    = function(value)
		getgenv().InstaProxPrompt = value
	end,
})

-- Открываем окно
Window:SelectTab("Home")
Window:Open()

print("Reversal: Zero v5.3 loaded successfully")
