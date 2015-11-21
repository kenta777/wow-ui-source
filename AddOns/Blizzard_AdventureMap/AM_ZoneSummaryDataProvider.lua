AdventureMap_ZoneSummaryProviderMixin = CreateFromMixins(AdventureMapDataProviderMixin);

function AdventureMap_ZoneSummaryProviderMixin:OnAdded(adventureMap)
	AdventureMapDataProviderMixin.OnAdded(self, adventureMap);

	self:RegisterEvent("ADVENTURE_MAP_UPDATE_POIS");
	self:RegisterEvent("ADVENTURE_MAP_QUEST_UPDATE");
end

function AdventureMap_ZoneSummaryProviderMixin:OnEvent(event, ...)
	if event == "ADVENTURE_MAP_QUEST_UPDATE" then
		self:RefreshAllData();
	elseif event == "ADVENTURE_MAP_UPDATE_POIS" then
		self:RefreshAllData();
	end
end

function AdventureMap_ZoneSummaryProviderMixin:RemoveAllData()
	self:GetAdventureMap():RemoveAllPinsByTemplate("AdventureMap_ZoneSummaryPinTemplate");
	self:GetAdventureMap():RemoveAllPinsByTemplate("AdventureMap_ZoneSummaryInsetPinTemplate");
end

function AdventureMap_ZoneSummaryProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();

	if fromOnShow then
		-- We have to wait until the server sends us quest and mission data before we can continue
		self.playRevealAnims = true;
		return;
	end

	self:GatherQuests();
	self:GatherMissions();

	for zoneIndex = 1, C_AdventureMap.GetNumZones() do
		local zoneMapID, zoneName, left, right, top, bottom = C_AdventureMap.GetZoneInfo(zoneIndex);
		if self.questsByZone[zoneMapID] or self.missionsByZone[zoneMapID] then
			local centerX = left + (right - left) * .5;
			local centerY = top + (bottom - top) * .35;

			self:AddSummaryPin(zoneName, centerX, centerY, self.questsByZone[zoneMapID], self.missionsByZone[zoneMapID]);
		end
	end

	for insetIndex, quests in pairs(self.questsByInset) do
		local mapID, title, description, collapsedIcon, numDetailTiles, normalizedX, normalizedY = C_AdventureMap.GetMapInsetInfo(insetIndex);
		self:AddInsetSummaryPin(insetIndex, title, description, normalizedX, normalizedY, quests, nil);
	end

	self.playRevealAnims = false;
end

local function TryAddItem(container, x, y, item)
	local zoneMapID = C_AdventureMap.FindZoneAtPosition(x, y);
	if zoneMapID and not AdventureMap_IsZoneIDBlockedByZoneChoice(zoneMapID) then
		if not container[zoneMapID] then
			container[zoneMapID] = {}
		end
		table.insert(container[zoneMapID], item);
	end
end

function AdventureMap_ZoneSummaryProviderMixin:GatherQuests()
	self.questsByZone = {};
	self.questsByInset = {};

	for offerIndex = 1, C_AdventureMap.GetNumQuestOffers() do
		local questID, isTrivial, frequency, isLegendary, title, description, normalizedX, normalizedY, insetIndex = C_AdventureMap.GetQuestOfferInfo(offerIndex);
		if AdventureMap_IsQuestValid(questID, normalizedX, normalizedY) then
			if insetIndex then
				if not self.questsByInset[insetIndex] then
					self.questsByInset[insetIndex] = {}
				end
				table.insert(self.questsByInset[insetIndex], questID);
			else
				TryAddItem(self.questsByZone, normalizedX, normalizedY, questID);
			end
		end
	end
end

function AdventureMap_ZoneSummaryProviderMixin:GatherMissions()
	self.missionsByZone = {};

	local currentMissions = C_Garrison.GetAvailableMissions(nil, LE_FOLLOWER_TYPE_GARRISON_7_0);
	if currentMissions then
		for i, missionInfo in pairs(currentMissions) do
			TryAddItem(self.missionsByZone, missionInfo.mapPosX, missionInfo.mapPosY, missionInfo);
		end
	end

	local inProgressMissions = C_Garrison.GetInProgressMissions(LE_FOLLOWER_TYPE_GARRISON_7_0);
	if inProgressMissions then
		for i, missionInfo in pairs(inProgressMissions) do
			TryAddItem(self.missionsByZone, missionInfo.mapPosX, missionInfo.mapPosY, missionInfo);
		end
	end
end

function AdventureMap_ZoneSummaryProviderMixin:AddSummaryPin(zoneName, centerX, centerY, quests, missions)
	local pin = self:GetAdventureMap():AcquirePin("AdventureMap_ZoneSummaryPinTemplate", self.playRevealAnims);
	pin.Text:SetText(zoneName);
	pin.title = zoneName;
	pin.quests = quests;
	pin.missions = missions;
	pin:SetPosition(centerX, centerY);
	pin:Show();
end

function AdventureMap_ZoneSummaryProviderMixin:AddInsetSummaryPin(mapInsetIndex, title, description, centerX, centerY, quests, missions)
	local pin = self:GetAdventureMap():AcquirePin("AdventureMap_ZoneSummaryInsetPinTemplate", self.playRevealAnims);
	pin.mapInsetIndex = mapInsetIndex;
	pin.title = title;
	pin.description = description;
	
	pin.quests = quests;
	pin.missions = missions;
	pin:SetPosition(centerX, centerY);
	pin:SetShown(not self:GetAdventureMap():IsMapInsetExpanded(mapInsetIndex));
end

--[[ Zone Summary Pin ]]--
AdventureMap_ZoneSummaryPinMixin = CreateFromMixins(AdventureMapPinMixin);

function AdventureMap_ZoneSummaryPinMixin:OnLoad()
	self:SetAlphaStyle(AM_PIN_ALPHA_STYLE_VISIBLE_WHEN_ZOOMED_OUT);
	self:SetScalingLimits(1.25, 3.0, 1.5);
end

function AdventureMap_ZoneSummaryPinMixin:OnAcquired(playAnim)
	if playAnim then
		self.OnAddAnim:Play();
	end
end

function AdventureMap_ZoneSummaryPinMixin:OnClick(button)
	if button == "LeftButton" then
		self:PanAndZoomTo();
	end
end

function AdventureMap_ZoneSummaryPinMixin:OnMouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("LEFT", self, "RIGHT", 20, 0);

	GameTooltip:AddLine(self.title, 1, 1, 1);
	if self.description and #self.description > 0 then
		GameTooltip:AddLine(self.description, nil, nil, nil, true);
		GameTooltip:AddLine(" ");
	end
	if self.quests then
		GameTooltip:AddLine(ADVENTURE_MAP_AVAILABLE_QUESTS:format(#self.quests), nil, nil, nil, true);
	end
	if self.missions then
		GameTooltip:AddLine(ADVENTURE_MAP_AVAILABLE_MISSIONS:format(#self.missions), nil, nil, nil, true);
	end
	GameTooltip:Show();
end

function AdventureMap_ZoneSummaryPinMixin:OnMouseLeave()
	GameTooltip_Hide();
end

--[[ Zone Summary Inset Pin ]]--
AdventureMap_ZoneSummaryInsetPinMixin = CreateFromMixins(AdventureMap_ZoneSummaryPinMixin);

function AdventureMap_ZoneSummaryInsetPinMixin:OnLoad()

end

function AdventureMap_ZoneSummaryInsetPinMixin:OnCanvasScaleChanged()
	AdventureMap_ZoneSummaryPinMixin.OnCanvasScaleChanged(self);

	self:SetScale(1.0 / self:GetAdventureMap():GetCanvasScale());
	self:ApplyCurrentPosition();
end

function AdventureMap_ZoneSummaryInsetPinMixin:OnMapInsetSizeChanged(mapInsetIndex, expanded)
	if mapInsetIndex == self.mapInsetIndex then
		self:SetShown(not expanded);
	end
end

function AdventureMap_ZoneSummaryInsetPinMixin:OnMapInsetMouseEnter(mapInsetIndex)
	if mapInsetIndex == self.mapInsetIndex then
		self:OnMouseEnter();
		self.IconHighlight:Show();
	end
end

function AdventureMap_ZoneSummaryInsetPinMixin:OnMapInsetMouseLeave(mapInsetIndex)
	if mapInsetIndex == self.mapInsetIndex then
		self:OnMouseLeave();
		self.IconHighlight:Hide();
	end
end