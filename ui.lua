getfenv().getgenv().GameName = "Dead-Rails"

local defaults = {
	ESP = {
		["Money BagESP"] = false,
		["MonsterESP"] = false,
		["Dead MonsterESP"] = false,
		["AnimalESP"] = false,
		["Dead AnimalESP"] = false,
		["ItemESP"] = false,
		["Vault CodeESP"] = false,
		["Train (the most useful)ESP"] = false
	},
	ExtraPP = 1,
	AutoCollectBags = false,
	AutoPickTools = false,
	AutoPickOther = false,
	AutoPickArmor = false,
	AutoPickBonds = false,
	Noclip = false,
	NC = false,
	ShowTime = false,
	ShowDistance = false,
	ShowSpeed = false,
	ShowFuel = false,
	II = false,
	GKA = false,
	MA = false,
	ARG = false,
	Raycast = false, -- causing huge lags
	SilentAim = false,
	Mode = "Distance",
	NoVoid = false,
	SaveBulltets = false,
	AutoThrottle = false,
	FastKillaura = false,
	ATWC = false,
	AutoPlayAgain = false,

	AutoFuel = false,
	GreedyMode = false,
	
	ShowTimeLeft = false,
	ShowPlayingTimer = false,
	TimeMode = false,
	ShowMillis = false,
	ShortMode = false,
	
	SpeedBoost = 0,
	JumpBoost = 7.2,

	BandageUse = 0,
	OilUse = 0,
	OilUseCooldown = 5,
	KAR = 500,

	ThrowPower = 100,
	
	ForceNoclip = false,
	
	ReplaceMoney = false,
	ReplaceBond = false
}



local function getGlobalTable()
	return typeof(getfenv().getgenv) == "function" and typeof(getfenv().getgenv()) == "table" and getfenv().getgenv() or _G
end

getGlobalTable().FireHubLoaded = true

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/InfernusScripts/Null-Fire/main/Core/Libraries/Fire-Lib/Main.lua", true))()


local closed = false
local cons = {}
local prompts = {}
local oprompts = {}
local hooks = {}

local probablyDead = {}
local deathAmmo = {}

local function isDead(hum)
	if probablyDead[hum] and vals.FastKillaura then
		return true
	end

	if hum and hum.Parent then
		if not hum:IsA("Humanoid") then
			hum = hum:FindFirstChild("Humanoid")
		end

		if hum then
			if probablyDead[hum] and vals.FastKillaura then
				return true
			end

			local dead = hum.Health <= 0.01 and hum.PlatformStand
			if dead then
				probablyDead[hum] = true
			end

			return dead
		end
	end

	return true
end

local myGuns = {}
local melee = {}
local heals = {
	Bandage = {},
	["Snake Oil"] = {}
}

local function bp(v)
	if v and v:IsA("Tool") then
		if v:FindFirstChild("WeaponConfiguration") and not myGuns[v] then
			myGuns[v] = true
		elseif v:FindFirstChild("SwingEvent") and not melee[v] then
			melee[v] = true
		elseif heals[v.Name] and not heals[v.Name][v] then
			heals[v.Name][v] = true
		end
	end
end

local toolsMt = setmetatable({}, {
	__index = function(self, value)
		if value == "GetChildren" then
			local tools = plr.Backpack:GetChildren()

			if plr.Character then
				for i,v in plr.Character:GetChildren() do
					if v and v:IsA("Tool") then
						table.insert(tools, 1, v)
					end
				end
			end

			return tools
		end
		if plr and plr.Character and plr.Character:FindFirstChildOfClass("Tool") and plr.Character:FindFirstChildOfClass("Tool").Name == value then
			return plr.Character:FindFirstChildOfClass("Tool")
		end
		return plr.Backpack:FindFirstChild(value)
	end
})

for i,v in toolsMt.GetChildren do
	bp(v)
end
cons[#cons+1] = plr.Backpack.ChildAdded:Connect(bp)

local cooldown = {}
local function setCooldown(gun)
	cooldown[gun] = true
	task.wait((gun.WeaponConfiguration.FireDelay.Value * 1.5) + 0.25)
	cooldown[gun] = false
end

local function addFunction(t,v)
	if v == nil or typeof(t) ~= "table" then return end
	local i = 1
	while true do
		if v == nil or typeof(v) == "Instance" and v.Parent == nil then
			return -1
		end
		if t[i] == nil or typeof(t[i]) == "Instance" and t[i].Parent == nil then
			t[i] = v
			return i
		end
		i = i + 1
	end
end
local function add(t,v)
	task.spawn(addFunction, t, v)
end
local function remove(t,v)
	task.spawn(pcall, table.remove, t, table.find(t, v))
end
local function count(t)
	local amnt = 0
	for i,v in t do
		if typeof(v) == "Instance" and v.Parent ~= nil or typeof(v) ~= "Instance" and v ~= nil then
			amnt = amnt + 1
		end
	end
	return amnt
end
local function getFirst(t)
	for v,i in t do
		if typeof(v) == "Instance" and (v.Parent == plr.Character or v.Parent == plr.Backpack) or typeof(v) ~= "Instance" and v ~= nil then
			return v
		else
			remove(t, v)
		end
	end
end

local function fuseTables(t1, t2)
	for i,v in t2 do
		add(t1, v)
	end

	return t1
end

local function raycast(from, to, ignore)
	local raycastParams = RaycastParams.new()

	raycastParams.IgnoreWater = true
	raycastParams.FilterDescendantsInstances = fuseTables(plr.Character and plr.Character:GetDescendants() or {}, ignore or {})

	local result = workspace:Raycast(from, (to - from).Unit * (to - from).Magnitude, raycastParams)
	return result and result.Instance
end

local s = game:GetService("ReplicatedStorage"):FindFirstChild("Shoot", math.huge)
local r = game:GetService("ReplicatedStorage"):FindFirstChild("Reload", math.huge)
local function shoot(gun, target)
	if not isDead(target) and (vals.Raycast and not raycast(workspace.CurrentCamera.CFrame.Position, target:GetPivot().Position, target:GetDescendants()) or not vals.Raycast) and (workspace.CurrentCamera.CFrame.Position - target:GetPivot().Position).Magnitude <= vals.KAR then
		local head = target:FindFirstChild("Head") or target:GetPivot()

		local hits = {}
		for i=1, gun.WeaponConfiguration.PelletsPerBullet.Value do
			hits[tostring(i)] = target.Humanoid
		end

		if target.Humanoid.Health - gun.WeaponConfiguration.BulletDamage.Value < 0 and gun.ServerWeaponState.CurrentAmmo.Value >= 1 and not cooldown[gun] then
			deathAmmo[target.Humaoind] = (tonumber(deathAmmo[target.Humaoind]) or 3) - 1
			if deathAmmo[target.Humaoind] <= 0 then
				probablyDead[target.Humanoid] = true
			end
			task.spawn(setCooldown, gun)
		end

		s:FireServer(workspace:GetServerTimeNow(), gun, CFrame.lookAt(head.Position + (head.CFrame.LookVector * 10), head.Position), hits)
	end
end
local function reload(gun)
	r:FireServer(workspace:GetServerTimeNow(), gun)
end
local fireproximityprompt = function(...)
	return network.Other:FireProximityPrompt(...)
end


local esps = {}
local desps = {}
local monsters = {}

local tools = {}
local bonds = {}
local other = {}
local equippables = {}

local pickupable = { "Consumable", "Gun", "Weapon", "Melee", "Playable", "Tool" }
local armor = { "Equippable" }

local infoStored = {}

local function getInfo(object)
	renderWait()

	if not object or not object.Parent then return end
	if infoStored[object.Name] then return infoStored[object.Name] end

	local info = {}
	for i,v in object:WaitForChild("ObjectInfo", 9e9):GetChildren() do
		if v.Name ~= "Title" and v:IsA("TextLabel") then
			add(info, v.Text)
		end
	end

	infoStored[object.Name] = info
	return info
end

local function hasProperty(object, prop)
	if not object or not object:FindFirstChild("ObjectInfo") then return false end

	local info = getInfo(object)

	if not info then return false end

	for i,v in info do
		if v == prop then
			return true
		end
	end

	return false
end

local function getColor(v)
	local val = v and v:GetAttribute("Value")
	if v.Name == "Bond" then
		return Color3.fromRGB(255, 170)
	elseif v.Name == "Coal" then
		return Color3.new(0.2, 0.2, 0.2)
	elseif v.Name == "Bandage" then
		return Color3.fromRGB(255, 150, 255)
	elseif v.Name == "Snake Oil" then
		return Color3.fromRGB(0, 170)
	elseif hasProperty(v, "Ammo") then
		return Color3.fromRGB(255, 170, 125)
	elseif hasProperty(v, "Weapon") or hasProperty(v, "Gun") or hasProperty(v, "Melee") then
		return Color3.new(0.75, 0.5, 0.5)
	elseif val then
		if val <= 50 then
			return Color3.new(0.8, 0.8, 0.8):Lerp(Color3.fromRGB(255, 255, 75), val / 50)
		elseif val <= 175 then
			return Color3.fromRGB(255, 255, 75):Lerp(Color3.fromRGB(75, 255, 255), (val - 50) / 175)
		else
			return Color3.fromRGB(75, 255, 255):Lerp(Color3.fromRGB(255, 125, 255), (val - 175) / 325)
		end
	elseif v.Name:match("JadeTablet") then
		return Color3.fromRGB(125, 150, 100)
	end
	return Color3.new(0.8, 0.8, 0.8)
end

local function getText(obj)
	local n = obj:GetAttribute("EntityName") or obj.Name
	local l = n:lower():gsub(" ", ""):gsub("_", "")

	if l:match("vase") then
		return "Vase"
	elseif l:match("outlaw") then
		return "Outlaw"
	elseif l:match("zombie") then
		return "Zombie"
	elseif l:match("nikola") then
		return "OMFG, IT IS THE MOTHERFUCKER"
	elseif l:match("jadetablet") then
		return "Jade Tablet"
	end

	return insertCum(n):gsub("Model ", "") .. ""
end

local function getBase(obj)
	if not obj or not obj.Parent then return end

	return obj:FindFirstChild("Base") or obj:FindFirstChild("BasePart") or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", math.huge)
end



local checked = {}
local items = workspace.RuntimeItems

local function main(v)
	renderWait()

	if v and v.Parent and not checked[v] then
		if v:IsA("ProximityPrompt") and not oprompts[v] then
			oprompts[v] = v.MaxActivationDistance
			v.MaxActivationDistance = oprompts[v] * vals.ExtraPP
		elseif v:IsA("Humanoid") and not game:GetService("Players"):GetPlayerFromCharacter(v.Parent) and not print(v.Parent) then
			checked[v] = true
			checked[v.Parent] = true
			
			if v.Parent:GetAttribute("DangerScore") or v.Parent.Parent and (v.Parent.Parent.Name:lower():match("enemies") or v.Parent.Parent.Name:lower():match("enemy")) then
				local monster = esps[v.Parent.Name] or {HighlightEnabled = false, Color = Color3.new(0.35):Lerp(Color3.new(1), (v.Parent:GetAttribute("DangerScore") or 10) / 100), Text = getItemText(v.Parent), ESPName = "MonsterESP"}
				esps[v.Parent.Name] = monster

				espFunc(v.Parent, monster)
				add(monsters, v.Parent)

				repeat task.wait() until not v or not v.Parent or isDead(v)
				if not v or not v.Parent then return end
				
				pcall(espLib.DeapplyESP, v.Parent)

				local dead = desps[v.Parent.Name] or {HighlightEnabled = true, Color = Color3.fromRGB(200, 150, 50):Lerp(Color3.fromRGB(255, 75, 0), (v.Parent:GetAttribute("DangerScore") / 10) / 100), Text = getItemText(v.Parent), ESPName = "Dead MonsterESP"}
				desps[v.Parent.Name] = dead
				
				remove(monsters, v.Parent)

				return espFunc(v.Parent, dead)
			elseif v.Parent:GetAttribute("BloodColor") then
				local animal = esps[v.Parent.Name] or {HighlightEnabled = true, Color = getColor(v.Parent), Text = getItemText(v.Parent), ESPName = "AnimalESP"}
				esps[v.Name] = animal

				espFunc(v.Parent, animal)

				repeat task.wait() until not v or not v.Parent or isDead(v)
				if not v or not v.Parent then return end

				pcall(espLib.DeapplyESP, v.Parent)

				local dead = desps[v.Parent.Name] or {HighlightEnabled = true, Color = Color3.new(1, 0.7, 0.7), Text = getItemText(v.Parent), ESPName = "Dead AnimalESP"}
				desps[v.Parent.Name] = dead

				return espFunc(v.Parent, dead)
			end
		elseif v:IsA("Model") then
			checked[v] = true
			if v.Name == "Vault" and v:FindFirstChild("Combination") then
				espFunc(v, {HighlightEnabled = true, Color = Color3.fromRGB(85, 170, 0), Text = "[" .. tostring(v.Combination.Value):gsub("", " ") .. "]", ESPName = "Vault CodeESP"})
			elseif v.Parent == workspace and v:GetAttribute("Stopped") ~= nil then
				train = v
				espFunc(v:WaitForChild("Functional", 9e9), {HighlightEnabled = false, Color = Color3.fromRGB(55, 65, 65), Text = "Train", ESPName = "Train (the most useful)ESP"})
			end
		elseif v:IsA("MeshPart") and v.Name == "MoneyBag" then
			checked[v] = true
			checked[v.Parent] = true
			
			local price = tonumber(v:WaitForChild("BillboardGui", 9e9):WaitForChild("TextLabel", 9e9).Text:gsub("%$", "") .. "")
			local bag = esps[price] or {HighlightEnabled = true, Color = Color3.fromRGB(40, 85):Lerp(Color3.fromRGB(85, 255), math.min(price / 50, 1)), Text = price .. "$", ESPName = "Money BagESP"}

			esps[price] = bag

			espFunc(v, bag)
			add(prompts, v:WaitForChild("CollectPrompt", 9e9))
		end
	end
end

local fuels = {}
local function itemFunc(v)
	if not v or not v.Parent or v.Name == "Moneybag" then return end
	renderWait(0.01)
	if not v or not v.Parent then return end

	checked[v] = true
	local tool = esps[v.Name] or {HighlightEnabled = false, Color = getColor(v), Text = getItemText(v), ESPName = "ItemESP"}

	esps[v.Name] = tool
	espFunc(v, tool)
	
	if v:GetAttribute("Fuel") and v:GetAttribute("Fuel") > 0 and v.Name ~= "Chair" then
		add(fuels, v)
	end

	for i,va in pickupable do
		if hasProperty(v, va) then
			return add(tools, v)
		end
	end

	if v.Name == "Electrocutioner" or v.Name:lower():match("sword") then
		return add(tools, v)
	end

	if hasProperty(v, "Currency") then
		return add(bonds, v)
	end

	for i,va in armor do
		if hasProperty(v, va) then
			return add(equippables, v)
		end
	end

	if v:GetAttribute("ActivateText") then
		return add(other, v)
	end
end

for i,v in items:GetChildren() do
	task.spawn(itemFunc, v)
end
items.ChildAdded:Connect(itemFunc)

local getClosestMonster; getClosestMonster = function(mode)
	mode = mode or vals.Mode
	if mode == "Angle" and workspace.CurrentCamera then
		local a, d, m = math.huge, math.huge, nil
		for i,v in monsters do
			if v and v.Parent and not isDead(v) and not v:GetAttribute("Reanimated") and not v:GetAttribute("Tamed") then
				if vals.Raycast and raycast(workspace.CurrentCamera.CFrame.Position, v.GetPivot(v).Position, v.GetDescendants(v)) then
					continue
				end

				local di = (plr.Character.GetPivot(plr.Character).Position - v.GetPivot(v).Position).Magnitude
				local an = ((workspace.CurrentCamera.CFrame.Position + (workspace.CurrentCamera.CFrame.LookVector * di)) - v.GetPivot(v).Position).Magnitude

				if an <= a then
					d = di
					a = an
					m = v
				end
			else
				remove(monsters, v)
			end
		end

		return m, d
	elseif mode == "Random" then
		local allowedMonsters = {}
		for i,v in monsters do
			if v and v.Parent and not isDead(v) and not v:GetAttribute("Reanimated") and not v:GetAttribute("Tamed") then
				if vals.Raycast and raycast(workspace.CurrentCamera.CFrame.Position, v.GetPivot(v).Position, v.GetDescendants(v)) then
					continue
				end

				add(allowedMonsters, v)
			else
				remove(monsters, v)
			end
		end

		if #allowedMonsters > 0 then
			local monster = allowedMonsters[math.random(1, #allowedMonsters)]
			return monster, monster and (plr.Character.GetPivot(plr.Character).Position - monster.GetPivot(monster).Position).Magnitude
		end

		return getClosestMonster("Angle")
	else
		local d, m = math.huge, nil
		for i,v in monsters do
			if v and v.Parent and not isDead(v) and not v:GetAttribute("Reanimated") and not v:GetAttribute("Tamed") then
				if vals.Raycast and raycast(workspace.CurrentCamera.CFrame.Position, v.GetPivot(v).Position, v.GetDescendants(v)) then
					continue
				end

				local di = (plr.Character.GetPivot(plr.Character).Position - v.GetPivot(v).Position).Magnitude

				if di <= d then
					d = di
					m = v
				end
			else
				remove(monsters, v)
			end
		end

		return m, d
	end
end

local gncm, hmm = getfenv().getnamecallmethod, getfenv().hookmetamethod
if hmm and gncm then
	local old; old = hmm(game, "__namecall", function(self, ...)
		if vals.SilentAim and self == s and gncm() == "FireServer" then
			local args = { ... }

			local m, d = getClosestMonster()

			if m then
				local hits = {}
				for i=1, args[2].WeaponConfiguration.PelletsPerBullet.Value do
					hits[tostring(i)] = m.Humanoid
				end

				local head = m:FindFirstChild("Head") or m:GetPivot()

				args[3] = CFrame.lookAt(head.Position + Vector3.new(0, 1), head.Position)
				args[4] = hits
			elseif vals.SaveBullets then
				args[2].ClientWeaponState.CurrentAmmo.Value = args[2].ClientWeaponState.CurrentAmmo.Value + 1
				error("Cancel shoot", 0)
			end

			if d <= vals.KAR then
				return s.FireServer(s, unpack(args))
			end
		elseif vals.SaveBullets and self == s and gncm() == "FireServer" and not getClosestMonster() then
			local args = { ... }
			args[2].ClientWeaponState.CurrentAmmo.Value = args[2].ClientWeaponState.CurrentAmmo.Value + 1
			
			error("Cancel shoot", 0)
		end

		return old(self, ...)
	end)

	hooks[#hooks + 1] = function()
		hmm(game, "__namecall", old)
	end
end

task.spawn(function()
	while not closed and task.wait(0.01) do
		if vals.SpeedBoost ~= 0 and plr.Character and plr.Character:FindFirstChild("Humanoid") and not plr.Character.Humanoid.Sit and plr.Character.Humanoid.Health > 1 then
			plr.Character:PivotTo(plr.Character:GetPivot() + plr.Character.Humanoid.MoveDirection / ((101 - vals.SpeedBoost) * 15))
		end
	end
end)
task.spawn(function()
	while not closed and task.wait(0.1) do
		if vals.GKA and plr.Character and not vals.Running then
			local m, d = getClosestMonster()
			print(d, vals.KAR, d <= vals.KAR)
			if m and d <= vals.KAR then
				for v in myGuns do
					if v and v.Parent and v:FindFirstChild("WeaponConfiguration") and not vals.Running then
						pcall(shoot, v, m)
						if not vals.FastKillaura then
							task.wait(0.1)
						end
					end
				end
			end
		end
	end
end)
task.spawn(function()
	while not closed and task.wait(0.5) do
		if vals.ARG and plr.Character then
			for v in myGuns do
				if v and v.Parent and v:FindFirstChild("WeaponConfiguration") then
					pcall(reload, v)
				end
			end
		end
	end
end)

local ad = 30
local farEvents = {}

local function equipUntilNoZombie(tool, zombie)
	tool.Parent = plr.Character

	if not farEvents[zombie] then
		farEvents[zombie] = Instance.new("BindableEvent")
		repeat task.wait() until not vals.MA or isDead(zombie)

		farEvents[zombie]:Fire()

		farEvents[zombie]:Destroy()
		farEvents[zombie] = nil
	else
		farEvents[zombie].Event:Wait()
	end

	tool.Parent = plr.Backpack
end

task.spawn(function()
	while not closed and task.wait(0.1) do
		if vals.MA and plr.Character and not vals.Running then
			local m, d = getClosestMonster("Distance")
			if m and d <= ad then
				for v in melee do
					if v and v.Parent and v:FindFirstChild("SwingEvent") and not vals.Running then
						if v.Parent == plr.Backpack then
							task.spawn(equipUntilNoZombie, v, m)
						end

						v.SwingEvent:FireServer(CFrame.lookAt(plr.Character:GetPivot().Position, m:GetPivot().Position + Vector3.new(0, 2)).LookVector)
					end
				end
			end
		end
	end
end)

local endPosition = CFrame.new(-380, 40, -48885)
local function finish()
	if plr.Character and vals.AutoComplete and plr.Character:FindFirstChild("Humanoid") and (plr.Character:GetPivot().Position - endPosition.Position).Magnitude < 1000 then
		for i=1, 3 do
			--print("walking")
			vals.ForceNoclip = true
			if plr.Character and vals.AutoComplete and plr.Character:FindFirstChild("Humanoid") and (plr.Character:GetPivot().Position - endPosition.Position).Magnitude < 1000 then
				--print("walking 2")
				plr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				plr.Character.Humanoid:MoveTo(workspace.Baseplates.FinalBasePlate.OutlawBase.Bridge.BridgeControl.Part.Position + Vector3.new(13.5, 0, 5))
				task.wait(2)
				plr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			vals.ForceNoclip = true
		end
		if plr.Character and vals.AutoComplete and plr.Character:FindFirstChild("Humanoid") and (plr.Character:GetPivot().Position - endPosition.Position).Magnitude < 1000 then
			--print("hiding")
			local prompt = workspace.Baseplates:FindFirstChild("EndGame", math.huge)
			while not closed and vals.AutoComplete and task.wait(0.1) and plr.Character and plr.Character:FindFirstChild("Humanoid") and (plr.Character:GetPivot().Position - endPosition.Position).Magnitude < 1000 do
				--print("loop")
				prompt = prompt or workspace.Baseplates:FindFirstChild("EndGame", math.huge)
				vals.ForceNoclip = true
				if prompt and prompt.Parent then
					oprompts[prompt] = oprompts[prompt] or prompt.MaxActivationDistance
					prompt.MaxActivationDistance = oprompts[prompt] * 3
					
					fireproximityprompt(prompt)
				end
				plr.Character.Humanoid:MoveTo(workspace.Baseplates.FinalBasePlate.OutlawBase.Bridge.BridgeControl.Part.Position + Vector3.new(13.5, 0, 5))
				vals.ForceNoclip = true
			end
		end
	end
end

for i,v in workspace:GetDescendants() do
	task.spawn(main, v)
end
cons[#cons+1] = workspace.DescendantAdded:Connect(main)

local void = pcall(function()
	workspace.FallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
end)

local function formatTime(timeInSeconds)
	if not vals.TimeMode then
		local totalMilliseconds = math.floor(timeInSeconds * 1000 + 0.5)

		return string.format("%s:%02d" .. (vals.ShowMillis and ".%02d" or ""), math.floor(totalMilliseconds / 60000), math.floor((totalMilliseconds % 60000) / 1000), vals.ShowMillis and math.floor((totalMilliseconds % 1000) / 10))
	else
		local hours = math.floor(timeInSeconds / 3600)
		timeInSeconds = timeInSeconds % 3600
		local minutes = math.floor(timeInSeconds / 60)
		local secs = timeInSeconds % 60

		local result = ""

		if hours > 0 then
			result = result .. string.format(not vals.ShortMode and "%02d hours " or "%02d h; ", hours)
		end

		if minutes > 0 then
			result = result .. string.format(not vals.ShortMode and "%02d minutes " or "%02d m; ", minutes)
		end

		result = result .. string.format(not vals.ShortMode and "%02d seconds " or "%02d s" .. (vals.ShowMillis and ";" or "") .. " ", secs)

		if vals.ShowMillis then
			local milliseconds = math.floor((timeInSeconds - math.floor(timeInSeconds)) * 1000)
			result = result .. string.format(not vals.ShortMode and "%03d milliseconds" or "%03d ms", milliseconds)
		end

		return result
	end
end

local oilCooldown = false
local notified = false
local fired = false

local money = plr.PlayerGui.MoneyGui.Money
local bond = plr.PlayerGui.BondGui.BondInfo.BondCount
local bt = "Not refreshed"

cons[#cons+1] = game:GetService("RunService").RenderStepped:Connect(function()
	txtf("ClearText")
	if train and train.Parent and train:FindFirstChild("RequiredComponents") and train.RequiredComponents:FindFirstChild("Controls") and train.RequiredComponents.Controls:FindFirstChild("TimeDial") then
		if vals.ShowTime then
			txtf("UpdateLine", "Left", "Time: " .. train.RequiredComponents.Controls.TimeDial.SurfaceGui.TextLabel.Text)
		end
		if vals.ShowDistance then
			txtf("UpdateLine", "Left", "Traveled: " .. train.RequiredComponents.Controls.DistanceDial.SurfaceGui.TextLabel.Text)
		end
		if vals.ShowSpeed then
			txtf("UpdateLine", "Left", "Speed: " .. (math.round((train.RequiredComponents.Controls.Spedometer.SurfaceGui.ImageLabel.Gauge.Rotation - 120) / 163 * 650) / 10) .. " s/s")
		end
		if vals.ShowFuel then
			txtf("UpdateLine", "Left", "Fuel: " .. getFuelPercentage() .. "%")
		end
	end
	local t = workspace.DistributedGameTime
	
	if vals.ShowTimeLeft then
		if txtf("GetText", "Left") ~= "" then
			txtf("UpdateLine", "Left", "")
		end
		
		local time = math.max(601 - t, 0)
		txtf("UpdateLine", "Left", "Timer: " .. formatTime(time) .. " left")
		if time == 0 and not notified then
			notified = true
			lib.Notifications:Notification({Title = "Timer", Text = "You can finish game now!"})
		end
	end
	if vals.ShowPlayingTimer then
		if txtf("GetText", "Left") == "" and not vals.ShowTimeLeft then
			txtf("UpdateLine", "Left", "")
		end
		txtf("UpdateLine", "Left", "Playing: " .. formatTime(t))
	end

	money.Visible = not vals.ReplaceMoney
	bond.Parent.Parent.Enabled = not vals.ReplaceBond

	if vals.ReplaceMoney then
		if txtf("GetText", "Left") ~= "" then
			txtf("UpdateLine", "Left", "")
		end
		txtf("UpdateLine", "Left", "Money: " .. money.Text)
	end
	if vals.ReplaceBond then
		if txtf("GetText", "Left") == "" and not vals.ReplaceMoney then
			txtf("UpdateLine", "Left", "")
		end
		
		if bond.Text ~= "0" then
			bt = bond.Text
		end
		
		txtf("UpdateLine", "Left", "Bonds: " .. bt)
	end

	if vals.ATWC and not fired and (workspace.TeslaLab:GetPivot().Position - plr.Character:GetPivot().Position).Magnitude <= 1000 and workspace.TeslaLab:FindFirstChild("PowerPrompt", math.huge) then
		if fireproximityprompt(workspace.TeslaLab:FindFirstChild("PowerPrompt", math.huge)) then
			fired = true
		end
	end
	
	if vals.FB then
		game.Lighting.Ambient = Color3.new(1, 1, 1)
		game.Lighting.Brightness = 1.5
	end
	if vals.NC then
		plr.CameraMode = Enum.CameraMode.Classic
	end
	if void then
		workspace.FallenPartsDestroyHeight = vals.NoVoid and 0/0 or -500
	end
	plr.DevCameraOcclusionMode = vals.NC and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
	game.Lighting.GlobalShadows = not vals.FB
	if vals.AutoCollectBags then
		for i,v in prompts do
			if v and v.Parent then
				fireproximityprompt(v)
			else
				remove(prompts, v)
			end
		end
	end
	if vals.AutoThrottle and train and train.Parent and train:FindFirstChild("RequiredComponents") and train.RequiredComponents:FindFirstChild("Controls") and train.RequiredComponents.Controls.ConductorSeat:FindFirstChild("VehicleSeat") and math.abs(train.RequiredComponents.Controls.ConductorSeat.VehicleSeat.Throttle) == 0 then
		train.RequiredComponents.Controls.ConductorSeat.VehicleSeat.Throttle = 1
	end
	if vals.AutoPlayAgain and plr.PlayerGui.EndScreen.Enabled then
		game:GetService("ReplicatedStorage"):FindFirstChild("EndDecision", math.huge):FireServer(false)
	end
	if plr.Character then
		if (vals.NoVoid or vals.ForceNoclip) and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.HumanoidRootPart.Position.Y <= -10 then
			plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 10)
			plr.Character:PivotTo(plr.Character:GetPivot() + Vector3.new(0, 20))
		end
		if vals.Noclip or vals.ForceNoclip then
			for i,v in plr.Character:GetDescendants() do
				if v and v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
		elseif plr.Character:FindFirstChild("HumanoidRootPart") then
			plr.Character.HumanoidRootPart.CanCollide = true
		end

		local hum = plr.Character:FindFirstChildOfClass("Humanoid")

		if not hum or hum.Health <= 0.01 and hum.PlatformStand then return end
		
		hum.JumpHeight = vals.JumpBoost
		
		if vals.AutoPickTools then
			for i,v in tools do
				if v and v.Parent then
					if v.Parent == items and not v:GetAttribute("BuyPrice") and (v:GetPivot().Position - plr.Character:GetPivot().Position).Magnitude <= 30 then
						game:GetService("ReplicatedStorage"):FindFirstChild("PickUpTool", math.huge):FireServer(v)
					end
				else
					remove(prompts, v)
				end
			end
		end
		if vals.AutoPickOther then
			for i,v in other do
				if v and v.Parent then
					if v.Parent == items and not v:GetAttribute("BuyPrice") and (v:GetPivot().Position - plr.Character:GetPivot().Position).Magnitude <= 30 then
						game:GetService("ReplicatedStorage"):FindFirstChild("C_ActivateObject", math.huge):FireServer(v)
					end
				else
					remove(prompts, v)
				end
			end
		end
		if vals.AutoPickBonds then
			for i,v in bonds do
				if v and v.Parent then
					if v.Parent == items and not v:GetAttribute("BuyPrice") and (v:GetPivot().Position - plr.Character:GetPivot().Position).Magnitude <= 30 then
						game:GetService("ReplicatedStorage"):FindFirstChild("C_ActivateObject", math.huge):FireServer(v)
					end
				else
					remove(prompts, v)
				end
			end
		end
		if vals.AutoPickArmor then
			for i,v in equippables do
				if v and v.Parent then
					if v.Parent == items and not v:GetAttribute("BuyPrice") and (v:GetPivot().Position - plr.Character:GetPivot().Position).Magnitude <= 30 then
						game:GetService("ReplicatedStorage"):FindFirstChild("EquipObject", math.huge):FireServer(v)
					end
				else
					remove(prompts, v)
				end
			end
		end

		local bandage = getFirst(heals.Bandage)
		if bandage and bandage.Parent and plr.Character:FindFirstChildOfClass("Humanoid").Health <= vals.BandageUse then
			return bandage.Use:FireServer(bandage)
		end

		local oil = getFirst(heals["Snake Oil"])
		if not oilCooldown and oil and oil.Parent and plr.Character:FindFirstChildOfClass("Humanoid").Health <= vals.OilUse then
			oilCooldown = true
			oil.Use:FireServer(oil)
			task.wait(vals.OilUseCooldown)
			oilCooldown = false
		end
	end
	
cons[#cons+1] = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(pp)
	if vals.II then
		fireproximityprompt(pp, true)
	end
end)
