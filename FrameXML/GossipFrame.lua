
NUMGOSSIPBUTTONS = 32;

function GossipFrame_OnLoad()
	this:RegisterEvent("GOSSIP_SHOW");
	this:RegisterEvent("GOSSIP_CLOSED");
end

function GossipFrame_OnEvent()
	if ( event == "GOSSIP_SHOW" ) then
		-- if there is only a non-gossip option, then go to it directly
		if ( (GetNumGossipAvailableQuests() == 0) and (GetNumGossipActiveQuests() == 0) and (GetNumGossipOptions() == 1) ) then
			local text, gossipType = GetGossipOptions();
			if ( gossipType ~= "gossip" ) then
				SelectGossipOption(1);
				return;
			end
		end

		if ( not GossipFrame:IsShown() ) then
			ShowUIPanel(GossipFrame);
			if ( not GossipFrame:IsShown() ) then
				CloseGossip();
				return;
			end
		end
		GossipFrameUpdate();
	elseif ( event == "GOSSIP_CLOSED" ) then
		HideUIPanel(GossipFrame);
	end
end

function GossipFrameUpdate()
	GossipFrame.buttonIndex = 1;
	GossipGreetingText:SetText(GetGossipText());
	GossipFrameAvailableQuestsUpdate(GetGossipAvailableQuests());
	GossipFrameActiveQuestsUpdate(GetGossipActiveQuests());
	GossipFrameOptionsUpdate(GetGossipOptions());
	for i=GossipFrame.buttonIndex, NUMGOSSIPBUTTONS do
		getglobal("GossipTitleButton" .. i):Hide();
	end
	GossipFrameNpcNameText:SetText(UnitName("npc"));
	if ( UnitExists("npc") ) then
		SetPortraitTexture(GossipFramePortrait, "npc");
	else
		GossipFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
	end

	-- Set Spacer
	if ( GossipFrame.buttonIndex > 1 ) then
		GossipSpacerFrame:SetPoint("TOP", "GossipTitleButton"..GossipFrame.buttonIndex-1, "BOTTOM", 0, 0);
		GossipSpacerFrame:Show();
	else
		GossipSpacerFrame:Hide();
	end

	-- Update scrollframe
	GossipGreetingScrollFrame:SetVerticalScroll(0);
end

function GossipTitleButton_OnClick()
	if ( this.type == "Available" ) then
		SelectGossipAvailableQuest(this:GetID());
	elseif ( this.type == "Active" ) then
		SelectGossipActiveQuest(this:GetID());
	else
		SelectGossipOption(this:GetID());
	end
end

function GossipFrameAvailableQuestsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	local titleButtonIcon;
	for i=1, select("#", ...), 3 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			message("This NPC has too many quests and/or gossip options.");
		end
		titleButton = getglobal("GossipTitleButton" .. GossipFrame.buttonIndex);
		titleButtonIcon = getglobal(titleButton:GetName() .. "GossipIcon");
		titleButtonIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon");
		if ( select(i+2, ...) ) then
			titleButton:SetFormattedText(TRIVIAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(0.5,0.5,0.5);
		else
			titleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(1,1,1);
		end
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Available";
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
	end
	if ( GossipFrame.buttonIndex > 1 ) then
		titleButton = getglobal("GossipTitleButton" .. GossipFrame.buttonIndex);
		titleButton:Hide();
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
	end
end

function GossipFrameActiveQuestsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	local titleButtonIcon;
	for i=1, select("#", ...), 3 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			message("This NPC has too many quests and/or gossip options.");
		end
		titleButton = getglobal("GossipTitleButton" .. GossipFrame.buttonIndex);
		titleButtonIcon = getglobal(titleButton:GetName() .. "GossipIcon");
		if ( select(i+2, ...) ) then
			titleButton:SetFormattedText(TRIVIAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(0.5,0.5,0.5);
		else
			titleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(1,1,1);
		end
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Active";
		titleButtonIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon");
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
	end
	if ( titleIndex > 1 ) then
		titleButton = getglobal("GossipTitleButton" .. GossipFrame.buttonIndex);
		titleButton:Hide();
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
	end
end

function GossipFrameOptionsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	local titleButtonIcon;
	for i=1, select("#", ...), 2 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			message("This NPC has too many quests and/or gossip options.");
		end
		titleButton = getglobal("GossipTitleButton" .. GossipFrame.buttonIndex);
		titleButton:SetText(select(i, ...));
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Gossip";
		titleButtonIcon = getglobal(titleButton:GetName() .. "GossipIcon")
		titleButtonIcon:SetTexture("Interface\\GossipFrame\\" .. select(i+1, ...) .. "GossipIcon");
		titleButtonIcon:SetVertexColor(1, 1, 1, 1);
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
	end
end

function GossipResize(titleButton)
	titleButton:SetHeight( titleButton:GetTextHeight() + 2);
end
