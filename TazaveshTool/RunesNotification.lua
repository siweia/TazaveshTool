-- 348450, 1323035 蓝
-- 348451, 1323037 紫
-- 348447, 1323038 黄
-- 348437, 1323039 橙
local texes = {1323035, 1323037, 1323038, 1323039}
local direcs = {"↖", "↗", "↙", "↘"}
local colors = {"蓝", "紫", "黄", "橙"}
local iconString = "|T%s:16:16:0:0:64:64:5:59:5:59|t %s"
local ticks = 0

local TRIGGER_SPELL = 346427 -- 触发法术
local BOSS_ID = 2426 -- 希尔布兰德
local width = 200
local spacing, iconSpacing = 30, 1
local slotWidth = 60
local iconWidth = (slotWidth-iconSpacing)/2

local f = CreateFrame("Frame", "NDuiTazaConsole", UIParent)
f:SetSize(width, width)
f:SetPoint("RIGHT", -300, 0)
f:SetMovable(true)
f:SetUserPlaced(true)
f:SetClampedToScreen(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() f:StartMoving() end)
f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

local tex = f:CreateTexture(nil, "BACKGROUND")
tex:SetAllPoints()
tex:SetTexture("Interface\\Addons\\TazaveshTool\\Media\\gambit")
f:Hide()

local function onEnter(bu)
	bu.text:SetTextColor(1, .8, 0)
end

local function onLeave(bu)
	bu.text:SetTextColor(1, 1, 1)
end

local function CreateButton(parent, width, height, text, fontSize)
	local bu = CreateFrame("Button", nil, parent)
	bu:SetSize(width, height)
	if type(text) == "boolean" then
		local tex = bu:CreateTexture()
		tex:SetAllPoints()
		tex:SetTexCoord(.08, .92, .08, .92)
		tex:SetTexture(fontSize)
		local hl = bu:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 1, .25)
		bu.tex = tex
	else
		local fs = bu:CreateFontString()
		fs:SetPoint("CENTER")
		fs:SetFontObject(Game16Font)
		fs:SetText(text)
		bu.text = fs
		bu:SetScript("OnEnter", onEnter)
		bu:SetScript("OnLeave", onLeave)
	end
	return bu
end

local function showTooltip(icon)
	GameTooltip:SetOwner(icon, "ANCHOR_TOP")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(format(iconString, texes[icon.id], colors[icon.id]))
	GameTooltip:Show()
end

local slots = {}

local function clickIcon(self)
	for i = 1, 4 do
		slots[i].icons[self.id].tex:SetAlpha(i ~= self.index and .2 or 1)
		slots[i].icons[self.id].tex:SetDesaturated(i ~= self.index)
	end
	for j = 1, 4 do
		slots[self.index].icons[j].tex:SetAlpha(j ~= self.id and .2 or 1)
		slots[self.index].icons[j].tex:SetDesaturated(j ~= self.id)
	end
	ticks = ticks + 1
end

local anchor = {
	[1] = {"TOPLEFT", 5, -5},
	[2] = {"TOPRIGHT", -5, -5},
	[3] = {"BOTTOMLEFT", 5, 5},
	[4] = {"BOTTOMRIGHT", -5, 5},
}
for i = 1, 4 do
	local slot = CreateFrame("Frame", nil, f)
	slot:SetSize(slotWidth, slotWidth)
	slot:SetPoint(unpack(anchor[i]))
	slots[i] = slot

	slot.icons = {}
	for j = 1, 4 do
		local icon = CreateButton(slot, iconWidth, iconWidth, true, texes[j])
		icon:SetPoint("TOPLEFT", (j-1)%2 * (iconWidth+iconSpacing), - (j>2 and (iconWidth+iconSpacing) or 0))
		icon.index = i
		icon.id = j
		slot.icons[j] = icon
		icon:SetScript("OnClick", clickIcon)
		icon:SetScript("OnEnter", showTooltip)
		icon:SetScript("OnLeave", GameTooltip_Hide)
	end
end

local reset = CreateButton(f, slotWidth, 22, RESET, 16)
reset:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 10, 0)
reset:SetScript("OnClick", function()
	for i = 1, 4 do
		for j = 1, 4 do
			slots[i].icons[j].tex:SetAlpha(1)
			slots[i].icons[j].tex:SetDesaturated(false)
		end
	end
	ticks = 0
end)

local function GetSlotString(order)
	local text = ""
	for i = 1, 4 do
		local icon = slots[order].icons[i].tex
		if icon:GetAlpha() == 1 then
			text = direcs[order]..colors[i]
			break
		end
	end
	return text
end

local send = CreateButton(f, slotWidth, 22, SEND_LABEL, 16)
send:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -10, 0)
send:SetScript("OnClick", function()
	if ticks < 3 then return end

	local channel = IsPartyLFG() and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"
	SendChatMessage(GetSlotString(1).."   "..GetSlotString(2), channel)
	SendChatMessage(GetSlotString(3).."   "..GetSlotString(4), channel)
end)

local lastShown = 0

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "PLAYER_ENTERING_WORLD" then
		local instID = select(8, GetInstanceInfo())
		if instID == 2441 then
			eventFrame:RegisterEvent("ENCOUNTER_START")
			eventFrame:RegisterEvent("ENCOUNTER_END")
		else
			eventFrame:UnregisterEvent("ENCOUNTER_START")
			eventFrame:UnregisterEvent("ENCOUNTER_END")
		end
	elseif event == "ENCOUNTER_START" and arg1 == BOSS_ID then
		eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
	elseif event == "ENCOUNTER_END" and arg1 == BOSS_ID then
		eventFrame:UnregisterEvent("UNIT_AURA")
	elseif event == "UNIT_AURA" then
		f:Hide()

		local now = GetTime()
		for i = 1, 40 do
			local name, _, _, _, _, _, _, _, _, spellID = UnitDebuff("player", i)
			if not name then break end
			if spellID == TRIGGER_SPELL then
				f:Show()
				-- 距离上次显示超过30秒时重置
				if now - lastShown > 30 then
					reset:Click()
					lastShown = now
				end
				return
			end
		end
	end
end)