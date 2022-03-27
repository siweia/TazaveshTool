local _, ns = ...

local mult = 1/8
local NUMBER_DOTS_TEXTURE = "Interface\\Worldmap\\UI-QuestPoi-NumberIcons"
local unitIDs = {"player", "party1", "party2", "party3", "party4"}
local cache = {}

local NUMBER_MAPS = {
	[1] = {50, -40, "外环左上角，裁缝商人。"},
	[2] = {157, -30, "外环右上角，武器商人。"},
	[3] = {157, -87, "外环右侧，宝石商人。"},
	[4] = {125, -150, "外环右下角，料理商人。"},
	[5] = {55, -160, "外环左下角，化石商人"},
	[6] = {20, -120, "外环左侧，乐器商人。"},
	[7] = {75, -70, "内环上方，文书商人。"},
	[8] = {45, -95, "内环左侧，香料商人。"},
	[9] = {75, -125, "内环下方，炼金商人。"},
}

local spellToIndex = {
	-- 赛·阿其达，裁缝
	[352127] = 1, -- 布料
	[358905] = 1, -- 丝卷
	[358906] = 1, -- 格里恩耀纹布卷
	-- 赛·迦希德，武器
	[352131] = 2, -- 战锤
	[358917] = 2, -- 平衡之剑
	[358918] = 2, -- 蕾茉妮雅的完美复制品
	-- 赛·加纳，宝石
	[352125] = 3, -- 蛋白石
	[358911] = 3, -- 玉石
	[358912] = 3, -- 瓦里诺之眼
	-- 赛·塔迪尔，料理
	[352128] = 4, -- 面包
	[358907] = 4, -- 榴莲
	[358908] = 4, -- 蛋糕
	-- 赛·扎洛，化石
	[352134] = 5, -- 积灰的徽记
	[358909] = 5, -- 恶魔之颅
	[358910] = 5, -- 莫塔尼斯之骨
	-- 赛·哈尔，乐器
	[352133] = 6, -- 战鼓
	[358913] = 6, -- 笛子
	[358914] = 6, -- 竖琴
	-- 赛·基塔布，文书
	[352132] = 7, -- 古旧的日志
	[358903] = 7, -- 玛卓通史
	[358904] = 7, -- 德纳修斯私人日记
	-- 赛·娜拉，香料
	[352129] = 8, -- 廉价香料
	[358915] = 8, -- 芬芳香料
	[358916] = 8, -- 特制香料
	-- 赛·玛尔，炼金
	[352130] = 9, -- 合剂
	[358900] = 9, -- 隐形药水
	[358901] = 9, -- 血瓶
	--[118922] = 9,
}

local function GetNumberTexCoord(n)
	local x = (n-1)%8 * mult
	local y = n < 9 and 0 or mult
	return x, x+mult, y, y+mult
end

local function AddNewNumber(parent, n)
	local bu = CreateFrame("Button", nil, parent)
	bu:SetSize(30, 30)

	local bg = bu:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(NUMBER_DOTS_TEXTURE)
	bg:SetTexCoord(.25, .375, .375, .5)
	bg:SetAllPoints()
	bg:SetDesaturated(true)
	bg:SetAlpha(.5)
	bu.bg = bg

	local num = bu:CreateTexture(nil, "OVERLAY")
	num:SetTexture(NUMBER_DOTS_TEXTURE)
	num:SetTexCoord(GetNumberTexCoord(n))
	num:SetAllPoints()

	return bu
end

local function onClick(bu)
	SendChatMessage(NUMBER_MAPS[bu.__idx][3], IsPartyLFG() and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY")
end

local f = CreateFrame("Frame", "Tazavesh_TradeMaps", UIParent)
f:SetSize(200, 200)
f:SetPoint("RIGHT", -300, 0)
f:SetMovable(true)
f:SetUserPlaced(true)
f:SetClampedToScreen(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() f:StartMoving() end)
f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

local tex = f:CreateTexture()
tex:SetAllPoints()
tex:SetTexture("Interface\\Addons\\TazaveshTool\\Media\\TAZAVESH")
f:Hide()

local buttons = {}
for index, value in pairs(NUMBER_MAPS) do
	local bu = AddNewNumber(f, index)
	bu:SetPoint("TOPLEFT", value[1], value[2])
	bu.__idx = index
	bu:SetScript("OnClick", onClick)
	buttons[index] = bu
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		local instID = select(8, GetInstanceInfo())
		if instID == 2441 then
			eventFrame:RegisterEvent("UNIT_AURA")
		else
			eventFrame:UnregisterEvent("UNIT_AURA")
		end
	elseif event == "UNIT_AURA" then
		f:Hide()
		for i = 1, 9 do
			buttons[i].bg:SetDesaturated(true)
			buttons[i].bg:SetAlpha(.5)
		end

		for i = 1, 5 do
			local unit = unitIDs[i]
			if UnitExists(unit) then
				for j = 1, 20 do
					local name, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, j)
					if not name then break end

					local index = spellToIndex[spellID]
					if index then
						buttons[index].bg:SetDesaturated(false)
						buttons[index].bg:SetAlpha(1)

						local now = GetTime()
						if not cache[spellID] or cache[spellID] - now > 120 then
							cache[spellID] = now
							onClick(buttons[index])
						end
						f:Show()
						return
					end
				end
			end
		end
	end
end)