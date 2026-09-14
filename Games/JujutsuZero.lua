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
	CloudBaseUrl = "", 
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

local ScriptChangelog = Tabs.Home:AddSubTab({ Name = "Changelog", Icon = "Lucide:file-text" })

ScriptChangelog:AddChangelogEntry({
	Version = "Reversal: Zero 5.4",
	Date    = os.date("%d.%m.%Y"),
	Changes = {
		{ Type = "Fixed",   Text = "Freeze now holds you in place without locking movement, so abilities stay usable" },
		{ Type = "Added",   Text = "Auto R/F/C/X/Z/V/Y/T now cast the equipped technique skills directly via SkillController (no more fake keypresses)" },
		{ Type = "Added",   Text = "Bypass tab: [1360LVL] Auto Claim Onmitsu Elite — claims the Lv.1360 quest via QuestService.AcceptQuest, skipping the client-side level gate" },
		{ Type = "Added",   Text = "Farming tab: AutoRaid — auto-enters The Honored One Overworld Raid (AGojo) with Easy..Calamity difficulty selection and auto re-entry if the game kicks you out" },
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

-- ==================== FARMING TAB ====================

Tabs.Farming = Window:AddTab({ Name = "Farming", Icon = "Lucide:wheat" })

Tabs.Farming:AddSection("Character Controls", "Lucide:user")

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

Tabs.Farming:AddToggle({
	Text        = "Freeze Character",
	Description = "Completely freezes your character (ignores hits/physics)",
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
		Tabs.Farming:AddToggle({
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

Tabs.Farming:AddLineText("AutoUse")
addAutoToggles(AutoSlots)

Tabs.Farming:AddLineText("Special AutoUse")
addAutoToggles(SpecialSlots)

-- ==================== AUTORAID ====================
-- Overworld Raid "The Honored One" (BossIslands.AGojo). Entering a world raid is
-- NOT a simple teleport: you call BossIslandService.CreateIslandQueue, which
-- spawns a portal (QueueZone) next to the raid NPC on the main map; then you have
-- to physically stand inside that portal's "Waiting for players..." zone
-- (MinPlayerCount=1, Duration=5s). When the countdown finishes the zone closes and
-- the server warps you onto the island. BossIslandController.ActiveIsland is set
-- ONLY after that warp, so it is a reliable "actually on the raid island, not at
-- spawn" check — and when the game kicks you out (raid ends, e.g. after a big
-- crate farm) it flips back to nil, which is what the auto loop watches.
local RaidControllerModule = nil

local function getBossIslandController()
	if RaidControllerModule then return RaidControllerModule end
	local ok, mod = pcall(require, LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.BossIslandController)
	if ok then RaidControllerModule = mod end
	return RaidControllerModule
end

local RaidDifficultyOptions = { "Easy", "Normal", "Hard", "Nightmare", "Calamity" }

local function raidDifficultyIndex(name)
	for i, n in ipairs(RaidDifficultyOptions) do
		if n == name then return i end
	end
	return 1
end

getgenv().AutoRaidDifficulty = raidDifficultyIndex(getgenv().AutoRaidDifficultyName) or 1

-- One full entry attempt: walk to the raid teleport point, create the queue
-- portal, step into its "waiting" zone and stay there until the island actually
-- starts. Returns true only when ActiveIsland confirms we are on the raid.
local function EnterTheHonoredOne()
	local ok, err = pcall(function()
		local Net = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.NetworkController)
		local Char = require(LocalPlayer:WaitForChild("PlayerScripts").Client.Controllers.CharacterController)
		local BIC = getBossIslandController()
		local QZ = require(game:GetService("ReplicatedStorage").Shared.Libraries.QueueZoneLib)

		if not BIC then error("BossIslandController not found") end
		if BIC.ActiveIsland then return true end -- already on a raid island

		local diff = tonumber(getgenv().AutoRaidDifficulty) or 1
		local diffName = RaidDifficultyOptions[diff] or "Easy"

		-- 1. Wait out a death so the server can count us in the zone.
		local hrp = Char.LocalCharacter and Char.LocalCharacter.ServerModel and Char.LocalCharacter.ServerModel:FindFirstChild("HumanoidRootPart")
		local humanoid = Char.LocalCharacter and Char.LocalCharacter.ServerModel and Char.LocalCharacter.ServerModel:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local waited = 0
			while humanoid.Health <= 0 and waited < 8 do
				task.wait(0.5)
				waited = waited + 0.5
			end
		end

		-- 2. Teleport to the "The Honored One" teleport point (the raid NPC).
		local npc = workspace.Map:FindFirstChild("StaticNPCs") and workspace.Map.StaticNPCs:FindFirstChild("BossIslands_AGojo")
		local lc = Char.LocalCharacter
		if npc and lc and lc.ServerModel then
			local part = npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
			if part then
				lc.ServerModel:SetPrimaryPartCFrame(part.CFrame * CFrame.new(0, 4, 0))
				task.wait(0.3)
			end
		end

		-- 3. Create the queue portal for [AGojo] at the chosen difficulty.
		local m = Net.GetRemoteMethod("BossIslandService", "CreateIslandQueue")
		local created, createErr = m:Call({ ConfigID = "AGojo", Difficulty = diff, Modifiers = {} }):await()
		if not created then
			error("CreateIslandQueue(" .. diffName .. ") refused: " .. tostring(createErr))
		end

		-- 4. Wait for the portal to appear, then snap into its waiting zone and
		--    stay there while the server counts down (Duration=5s, MinPlayerCount=1).
		task.wait(0.5)
		local zone
		for _ = 1, 50 do
			for _, v in pairs(QZ.QueueZones) do
				if v.BossIslandConfigID == "AGojo" then
					zone = v
					break
				end
			end
			if zone then break end
			task.wait(0.2)
		end
		if not zone then error("Queue zone did not appear") end

		local started = os.clock()
		while os.clock() - started < 25 and not BIC.ActiveIsland do
			task.wait(0.1)
			if lc and lc.ServerModel then
				lc.ServerModel:SetPrimaryPartCFrame(zone.Zone.CFrame * CFrame.new(0, 3, 0))
			end
			-- re-find the zone in case it was re-created by a new attempt
			local alive = false
			for _, v in pairs(QZ.QueueZones) do
				if v.BossIslandConfigID == "AGojo" then
					zone = v
					alive = true
					break
				end
			end
			if not alive and not BIC.ActiveIsland then
				error("Queue zone vanished before the island started")
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

local function StartTheHonoredOneRaid()
	stopAutoRaid()
	getgenv().AutoRaidEnabled = true
	task.spawn(function()
		-- Loop: on the island -> just wait; not on the island -> enter. If the game
		-- kicks you out of the raid (raid over, big crate farm), ActiveIsland goes
		-- nil and the loop walks you straight back in.
		local fails = 0
		while getgenv().AutoRaidEnabled do
			local BIC = getBossIslandController()
			if BIC and BIC.ActiveIsland then
				fails = 0
				task.wait(2)
			else
				local ok, err = EnterTheHonoredOne()
				if ok then
					fails = 0
					VindUI:Notify({ Title = "AutoRaid", Text = "Entered The Honored One raid", Type = "success", Duration = 3 })
				else
					fails = fails + 1
					VindUI:Notify({ Title = "AutoRaid", Text = "Entry failed: " .. tostring(err), Type = "error", Duration = 4 })
				end
				task.wait(fails >= 3 and 20 or 3) -- back off after repeated failures
			end
			task.wait(0.5)
		end
	end)
end

Tabs.Farming:AddLineText("AutoRaid")

Tabs.Farming:AddDropdown({
	Text        = "Raid Difficulty",
	Description = "Difficulty for The Honored One world raid (Easy .. Calamity)",
	Icon        = "Lucide:list",
	Options     = RaidDifficultyOptions,
	Default     = "Easy",
	Flag        = "autoRaidDifficulty",
	Callback    = function(v)
		getgenv().AutoRaidDifficulty = raidDifficultyIndex(v)
		getgenv().AutoRaidDifficultyName = v
	end,
})

Tabs.Farming:AddButton({
	Text        = "AutoTP The Honored One",
	Description = "Walks to the raid teleport point at the boss NPC, creates the [AGojo] queue via BossIslandService.CreateIslandQueue and holds you inside the 'Waiting for players...' portal until the island loads. One manual entry, no loop.",
	Icon        = "Lucide:map-pin",
	Callback    = function()
		local ok, err = EnterTheHonoredOne()
		VindUI:Notify({
			Title = "The Honored One",
			Text = ok and "Raid entered — on the island" or ("Entry failed: " .. tostring(err)),
			Type = ok and "success" or "error",
			Duration = 4,
		})
	end,
})

Tabs.Farming:AddToggle({
	Text        = "AutoRaid The Honored One",
	Description = "Auto-enters The Honored One world raid whenever you are not on the raid island, and re-enters automatically if the game kicks you out (e.g. after farming a large number of crates).",
	Icon        = "Lucide:swords",
	Flag        = "autoRaid",
	Default     = false,
	Callback    = function(value)
		if value then
			StartTheHonoredOneRaid()
		else
			stopAutoRaid()
		end
	end,
})

-- === AUTOTP ON BOSS ===
-- The raid boss ("The Honored One") lives as an AI: BossNPC.ServerModel is the
-- physics model (HumanoidRootPart = its position), and the real HP is NOT the
-- engine Humanoid — it lives in Character.CharacterStates.Health
-- (MaxHealth ~1.2e9 at high difficulty, a plain Humanoid.Health won't tell you
-- anything). A dead boss keeps its model for a moment, so "alive" is checked via
-- CharacterStates.Health > 0, not by whether a model exists.
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

		-- Place next to the boss, facing it, far enough that we don't sit inside the hitbox
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
		-- Watch for the boss: teleport when it spawns / respawns, skip it while dead.
		-- Trigger once on the first valid target, then only when the boss moves far
		-- from us (new spawn position, or a fresh boss model after it was killed).
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
					-- teleport on a new boss instance OR when out of melee range
					if root and (lastRoot ~= root or dist > 35) then
						local status = teleportToBossOnce()
						if status ~= "boss_dead" and status ~= "no_raid" then
							lastRoot = root
						end
					end
				else
					lastRoot = nil -- boss died: reset so we re-teleport on respawn
				end
			end
		end
	end)
end

local function StopBossTP()
	AutoBossTPEnabled = false
	getgenv().AutoBossTPEnabled = false
end

Tabs.Farming:AddToggle({
	Text        = "AutoTP On Boss NPC",
	Description = "Teleports you next to the raid boss (The Honored One) the moment it is alive: on spawn and again after a kill/respawn. Checks CharacterStates.Health so a dead boss is never targeted.",
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
	Description = "Claims the Onmitsu Elite quest (Lv 1360) from Mysterious Sorcerer. Calls QuestService.AcceptQuest directly, skipping the client-side level gate — works even below Lv 1360.",
	Icon        = "Lucide:zap",
	Callback    = AutoClaimOnmitsuElite,
})

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

-- Открываем окно
Window:SelectTab("Home")
Window:Open()

print("Reversal: Zero v5.3 loaded successfully")