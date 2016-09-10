local E, L, P, G = unpack(select(2, ...));
local DT = E:GetModule("DataTexts");

local date = date;
local format, join = string.format, string.join;

local GetGameTime = GetGameTime;
local GetNumSavedInstances = GetNumSavedInstances;
local GetSavedInstanceInfo = GetSavedInstanceInfo;
local GetWintergraspWaitTime = GetWintergraspWaitTime;
local RequestRaidInfo = RequestRaidInfo;
local SecondsToTime = SecondsToTime;
local QUEUE_TIME_UNAVAILABLE = QUEUE_TIME_UNAVAILABLE;
local TIMEMANAGER_TOOLTIP_LOCALTIME = TIMEMANAGER_TOOLTIP_LOCALTIME;
local TIMEMANAGER_TOOLTIP_REALMTIME = TIMEMANAGER_TOOLTIP_REALMTIME;
local WINTERGRASP_IN_PROGRESS = WINTERGRASP_IN_PROGRESS;

local APM = {TIMEMANAGER_PM, TIMEMANAGER_AM};
local europeDisplayFormat = "";
local ukDisplayFormat = "";
local europeDisplayFormat_nocolor = join("", "%02d", ":|r%02d");
local ukDisplayFormat_nocolor = join("", "", "%d", ":|r%02d", " %s|r");
local lockoutInfoFormatNoEnc = "%s%s |cffaaaaaa(%s)";
local difficultyInfo = {"N", "N", "H", "H"};
local lockoutColorExtended, lockoutColorNormal = {r = 0.3, g = 1, b = 0.3}, {r = .8, g = .8, b = .8};
local curHr, curMin, curAmPm;
local enteredFrame = false;

local Update, lastPanel; -- UpValue
local name, _, reset, difficultyId, locked, extended, isRaid, maxPlayers;

local function ValueColorUpdate(hex)
	europeDisplayFormat = join("", "%02d", hex, ":|r%02d ", format("%s", date(hex .. "%d.%m.%y|r")));
	ukDisplayFormat = join("", "", "%d", hex, ":|r%02d", hex, " %s|r ", format("%s", date(hex .. "%d.%m.%y|r")));

	if(lastPanel ~= nil) then
		Update(lastPanel, 20000);
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true;

local function ConvertTime(h, m)
	local AmPm;
	if(E.db.datatexts.time24 == true) then
		return h, m, -1;
	else
		if(h >= 12) then
			if(h > 12) then h = h - 12; end
			AmPm = 1;
		else
			if(h == 0) then h = 12; end
			AmPm = 2;
		end
	end
	return h, m, AmPm;
end

local function CalculateTimeValues(tooltip)
	if(tooltip and E.db.datatexts.localtime) or (not tooltip and not E.db.datatexts.localtime) then
		return ConvertTime(GetGameTime());
	else
		local dateTable = date("*t");
		return ConvertTime(dateTable["hour"], dateTable["min"]);
	end
end

local function Click(_, btn)
	if(btn == "RightButton") then
 		TimeManagerClockButton_OnClick(TimeManagerClockButton);
 	else
 		GameTimeFrame:Click();
 	end
end

local function OnLeave()
	DT.tooltip:Hide();
	enteredFrame = false;
end

local function OnEvent(_, event)
	if(event == "UPDATE_INSTANCE_INFO" and enteredFrame) then
		RequestRaidInfo();
	end
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	if(not enteredFrame) then
		enteredFrame = true;
		RequestRaidInfo();
	end

	local wgtime = GetWintergraspWaitTime() or nil;
	inInstance, instanceType = IsInInstance();
	if not(instanceType == "none") then
		wgtime = QUEUE_TIME_UNAVAILABLE;
	elseif(wgtime == nil) then
		wgtime = WINTERGRASP_IN_PROGRESS;
	else
		wgtime = SecondsToTime(wgtime, false, nil, 3);
	end
	DT.tooltip:AddDoubleLine(L["Wintergrasp"], wgtime, 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b);

	local oneraid, lockoutColor
	for i = 1, GetNumSavedInstances() do
		name, _, reset, difficultyId, locked, extended, _, isRaid, maxPlayers = GetSavedInstanceInfo(i);
		if(isRaid and (locked or extended) and name) then
			if(not oneraid) then
				DT.tooltip:AddLine(" ");
				DT.tooltip:AddLine(L["Saved Raid(s)"]);
				oneraid = true;
			end
			if(extended) then 
				lockoutColor = lockoutColorExtended;
			else
				lockoutColor = lockoutColorNormal;
			end
			
			DT.tooltip:AddDoubleLine(format(lockoutInfoFormatNoEnc, maxPlayers, difficultyInfo[difficultyId], name), SecondsToTime(reset, false, nil, 3), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b);		
		end
	end

	local Hr, Min, AmPm = CalculateTimeValues(true);

	DT.tooltip:AddLine(" ");
	if(AmPm == -1) then
		DT.tooltip:AddDoubleLine(E.db.datatexts.localtime and TIMEMANAGER_TOOLTIP_REALMTIME or TIMEMANAGER_TOOLTIP_LOCALTIME, 
			format(europeDisplayFormat_nocolor, Hr, Min), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b);
	else
		DT.tooltip:AddDoubleLine(E.db.datatexts.localtime and TIMEMANAGER_TOOLTIP_REALMTIME or TIMEMANAGER_TOOLTIP_LOCALTIME,
			format(ukDisplayFormat_nocolor, Hr, Min, APM[AmPm]), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b);
	end

	DT.tooltip:Show();
end

local int = 3;
function Update(self, t)
	int = int - t;

	if(int > 0) then return; end

	if(GameTimeFrame.flashInvite) then
		E:Flash(self, 0.53);
	else
		E:StopFlash(self);
	end

	if(enteredFrame) then
		OnEnter(self)
	end

	local Hr, Min, AmPm = CalculateTimeValues(false);

	if(Hr == curHr and Min == curMin and AmPm == curAmPm) and not (int < -15000) then
		int = 5;
		return;
	end

	curHr = Hr;
	curMin = Min;
	curAmPm = AmPm;

	if(AmPm == -1) then
		self.text:SetFormattedText(europeDisplayFormat, Hr, Min);
	else
		self.text:SetFormattedText(ukDisplayFormat, Hr, Min, APM[AmPm]);
	end
	lastPanel = self;
	int = 5;
end

DT:RegisterDatatext("Time", {"UPDATE_INSTANCE_INFO"}, OnEvent, Update, Click, OnEnter, OnLeave);