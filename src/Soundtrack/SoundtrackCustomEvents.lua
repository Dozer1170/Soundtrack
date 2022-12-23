--[[
    Soundtrack addon for World of Warcraft

    Custom events functions.
    Functions that manage misc. and custom events.
]]

st_arg1, st_arg2, st_arg3, st_arg4, st_arg5, st_arg6, st_arg7, st_arg8, st_arg9, st_arg10, st_arg11, st_arg12, st_arg13, st_arg14, st_arg15, st_arg16, st_arg17, st_arg18, st_arg19, st_arg20, st_arg21, st_arg22, st_arg23, st_arg24 = nil

local function debug(msg)
	Soundtrack.TraceCustom(msg)
end

Soundtrack.CustomEvents = {
}

Soundtrack.ActionHouse = false
Soundtrack.Bank = false
Soundtrack.Merchant = false
Soundtrack.FlightMaster = false
Soundtrack.Barbershop = false
Soundtrack.Trainer = false

Soundtrack.CurrentStance = 0;
Soundtrack.ActiveAuras = {};

local ST_CLASS_STEALTH


function Soundtrack.CustomEvents.RenameEvent(tableName, oldEventName, newEventName)
    if Soundtrack.IsNullOrEmpty(tableName) then
        Soundtrack.Error("Custom RenameEvent: Nil table")
        return
    end
    if Soundtrack.IsNullOrEmpty(oldEventName) then
        Soundtrack.Error("Custom RenmeEvent: Nil old event")
        return
    end
	if Soundtrack.IsNullOrEmpty(newEventName) then
        Soundtrack.Error("Custom RenameEvent: Nil new event " .. oldEventName)
        return
    end
	
    local eventTable = Soundtrack.Events.GetTable(tableName)
    
    if not eventTable then
        Soundtrack.Error("Custom RenameEvent: Cannot find table : " .. tableName)
        return
    end
	
	if eventTable[oldEventName] == nil then
		return -- old event DNE
	end
	
	debug("RenameEvent: " .. tableName .. ": " .. oldEventName .. " to " .. newEventName)
    
    eventTable[newEventName] = eventTable[oldEventName]

	-- Now that we changed the name of the event, delete the old event
	Soundtrack.CustomEvents.DeleteEvent(tableName, oldEventName)
end
function Soundtrack.CustomEvents.DeleteEvent(tableName, eventName)
    
    local eventTable = Soundtrack.Events.GetTable(tableName)
    if eventTable then
        if eventTable[eventName] then
            debug("Removing event: "..eventName)
            eventTable[eventName] = nil
        end
    end
end

-- table can be Custom or Misc. 
function Soundtrack.CustomEvents.RegisterUpdateScript(self, name, tableName, _priority, _continuous, _script, _soundEffect)
    if tableName == ST_CUSTOM then
        SoundtrackAddon.db.profile.customEvents[name] = { script = _script, eventtype = "Update Script", priority=_priority, continuous=_continuous, soundEffect=_soundEffect };
    elseif tableName == ST_MISC then
        Soundtrack_MiscEvents[name] = { script = _script, eventtype = "Update Script", priority=_priority, continuous=_continuous, soundEffect=_soundEffect };
    end
    
    Soundtrack.AddEvent(tableName, name, _priority, _continuous, _soundEffect)
end

-- table can be Custom or Misc. 
function Soundtrack.CustomEvents.RegisterEventScript(self, name, tableName, _trigger, _priority, _continuous, _script, _soundEffect)
    if tableName == ST_CUSTOM then
        SoundtrackAddon.db.profile.customEvents[name] = { trigger = _trigger, script = _script, eventtype = "Event Script", priority=_priority, continuous=_continuous, soundEffect=_soundEffect };
    elseif tableName == ST_MISC then
        Soundtrack_MiscEvents[name] = { trigger = _trigger, script = _script, eventtype = "Event Script", priority=_priority, continuous=_continuous, soundEffect=_soundEffect }; 
    end
    self:RegisterEvent(_trigger);
    
    Soundtrack.AddEvent(tableName, name, _priority, _continuous, _soundEffect)
end


function Soundtrack.CustomEvents.UpdateActiveAuras()
	Soundtrack.ActiveAuras = {}
	for i=1,40 do
		local n, __, __, __, __, __, __, __, __, spellId = UnitBuff("player", i)
		if spellId ~= nil then	
			Soundtrack.ActiveAuras[spellId] = spellId
			debug("Adding active buff aura spellid: "..spellId)
		end
		local n, __, __, __, __, __, __, __, __, spellId = UnitDebuff("player", i)
		if spellId ~= nil then	
			Soundtrack.ActiveAuras[spellId] = spellId
			debug("Adding active debuff aura spellid: "..spellId)
		end
	end
end --]]

-- Returns the spellID of the buff, else nil
function Soundtrack.CustomEvents.IsAuraActive(spellId)
	debug("Is aura active spellid: "..spellId)
	return Soundtrack.ActiveAuras[spellId]
end

function Soundtrack.CustomEvents.RegisterBuffEvent(eventName, tableName, _spellId, _priority, _continuous, _soundEffect)
    if tableName == ST_CUSTOM then
        SoundtrackAddon.db.profile.customEvents[eventName] =
        { 
			spellId=_spellId, 
            stackLevel=_priority, 
            active=false,
            eventtype="Buff",
            priority=_priority, 
            continuous=_continuous,
			soundEffect=_soundEffect
        }    
    elseif tableName == ST_MISC then
        Soundtrack_MiscEvents[eventName] = 
        { 
            spellId=_spellId, 
            stackLevel=_priority, 
            active=false,
            eventtype="Buff",
            priority=_priority, 
            continuous=_continuous,
			soundEffect = _soundEffect
        }  
    end
    Soundtrack.AddEvent(tableName, eventName, _priority, _continuous, _soundEffect);
end

function Soundtrack_Custom_PlayEvent(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName ~= currentEvent then
		Soundtrack.PlayEvent(tableName, eventName);
	end
end

function Soundtrack_Custom_StopEvent(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	
	if eventName == currentEvent then
		Soundtrack.StopEvent(tableName, eventName);
	end
end

local jumpDelayTime = 0;
local jumpUpdateTime = .7

hooksecurefunc("JumpOrAscendStart",
	function()
		if HasFullControl() and not IsFlying() and not IsSwimming() and not UnitInVehicle("player") then 
			local currentTime = GetTime()
			if currentTime >= jumpDelayTime then
				jumpDelayTime = currentTime + jumpUpdateTime;
				if SoundtrackEvents_EventHasTracks(ST_MISC, SOUNDTRACK_JUMP) then
					Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_JUMP)
				end
			end
		end
	end
);

-- MiscEvents
function Soundtrack.CustomEvents.MiscInitialize(self)

	debug("Initializing misc. events...")
	
	self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")
    self:RegisterEvent("AUCTION_HOUSE_SHOW")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("TAXIMAP_CLOSED")
    self:RegisterEvent("TAXIMAP_OPENED")
    self:RegisterEvent("BARBER_SHOP_OPEN")
    self:RegisterEvent("BARBER_SHOP_CLOSE")
    self:RegisterEvent("TRAINER_SHOW")
    self:RegisterEvent("TRAINER_CLOSED")
	
    -- Add fixed custom events
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Jump
		self,
        SOUNDTRACK_JUMP, 
        ST_MISC,
        ST_SFX_LVL,
        false,
        function()
			-- hooksecurefunc for "JumpOrAscendStart"
		end,
		true
	);
    Soundtrack.CustomEvents.RegisterUpdateScript(	-- Swimming
		self,
        SOUNDTRACK_SWIMMING, 
        ST_MISC,
        ST_STATUS_LVL,
        true,
        function()
            if SNDCUSTOM_IsSwimming == nil then 
                SNDCUSTOM_IsSwimming = false 
            end

            if SNDCUSTOM_IsSwimming and not IsSwimming() then
				Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_SWIMMING)
                SNDCUSTOM_IsSwimming = false
            elseif not SNDCUSTOM_IsSwimming and IsSwimming() then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_SWIMMING)
                SNDCUSTOM_IsSwimming = true;
            end
        end,
		false
	);
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Auction House  
		self,
        SOUNDTRACK_AUCTION_HOUSE, 
        ST_MISC,
        ST_NPC_LVL,
        true,
        function()
            if SNDCUSTOM_AuctionHouse == nil then 
                SNDCUSTOM_AuctionHouse = false 
            end

            if SNDCUSTOM_AuctionHouse and not Soundtrack.AuctionHouse then
                Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_AUCTION_HOUSE)
                SNDCUSTOM_AuctionHouse = false
            elseif not SNDCUSTOM_AuctionHouse and Soundtrack.AuctionHouse then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_AUCTION_HOUSE)
                SNDCUSTOM_AuctionHouse = true;
            end
        end,
		false
	    );
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Bank  
		self,
        SOUNDTRACK_BANK, 
        ST_MISC,
        ST_NPC_LVL,
        true,
        function()
            if SNDCUSTOM_Bank == nil then 
                SNDCUSTOM_Bank = false 
            end

			-- Soundtrack.* does not deal with localization
            if SNDCUSTOM_Bank and not Soundtrack.Bank then
                Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_BANK)
                SNDCUSTOM_Bank = false
            elseif not SNDCUSTOM_Bank and Soundtrack.Bank then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_BANK)
                SNDCUSTOM_Bank = true;
            end
        end,
		false
	    );
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Merchant
		self,
        SOUNDTRACK_MERCHANT, 
        ST_MISC,
        ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
        true,
        function()
            if SNDCUSTOM_Merchant == nil then 
                SNDCUSTOM_Merchant = false 
            end
			
            if SNDCUSTOM_Merchant and not Soundtrack.Merchant then
                Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_MERCHANT)
                SNDCUSTOM_Merchant = false
            elseif not SNDCUSTOM_Merchant and Soundtrack.Merchant then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_MERCHANT)
                SNDCUSTOM_Merchant = true
            end
        end,
		false
	    );	   
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- FlightMaster
		self,
        SOUNDTRACK_FLIGHTMASTER, 
        ST_MISC,
        ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
        true,
        function()
            if SNDCUSTOM_FlightMaster == nil then 
                SNDCUSTOM_FlightMaster = false 
            end
			
            if SNDCUSTOM_FlightMaster and not Soundtrack.FlightMaster then
                Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_FLIGHTMASTER)
                SNDCUSTOM_FlightMaster = false
            elseif not SNDCUSTOM_FlightMaster and Soundtrack.FlightMaster then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_FLIGHTMASTER)
                SNDCUSTOM_FlightMaster = true
            end
        end,
		false
	    );	   
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Trainer
		self,
        SOUNDTRACK_TRAINER, 
        ST_MISC,
        ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
        true,
        function()
            if SNDCUSTOM_Trainer == nil then 
                SNDCUSTOM_Trainer = false 
            end
			
            if SNDCUSTOM_Trainer and not Soundtrack.Trainer then
                Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_TRAINER)
                SNDCUSTOM_Trainer = false
            elseif not SNDCUSTOM_Trainer and Soundtrack.Trainer then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_TRAINER)
                SNDCUSTOM_Trainer = true
            end
        end,
		false
	    );	   

	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Barbershop
		self,
		SOUNDTRACK_BARBERSHOP,
		ST_MISC,
		ST_NPC_LVL,
		true,
		function()
			if SNDCUSTOM_Barbershop == nil then
				SNDCUSTOM_Barbershop = false
			end
			
			if SNDCUSTOM_Barbershop and not Soundtrack.Barbershop then
				Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_BARBERSHOP)
				SNDCUSTOM_Barbershop = false
			elseif not SNDCUSTOM_Barbershop and Soundtrack.Barbershop then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_BARBERSHOP)
				SNDCUSTOM_Barbershop = true
			end
		end,
		false
		);
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Cinematic
		self,
		SOUNDTRACK_CINEMATIC,
		ST_MISC,
		ST_NPC_LVL,
		true,
		function()
			if SNDCUSTOM_Cinematic == nil then
				SNDCUSTOM_Cinematic = false
			end
			
			if SNDCUSTOM_Cinematic and not Soundtrack.Cinematic then
				Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_CINEMATIC)
				SNDCUSTOM_Cinematic = false
			elseif not SNDCUSTOM_Cinematic and Soundtrack.Cinematic then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_CINEMATIC)
				SNDCUSTOM_Cinematic = true
			end
		end,
		false
		);
	
	Soundtrack.CustomEvents.RegisterEventScript(	-- NPC Emote
		self,
		SOUNDTRACK_NPC_EMOTE,
		ST_MISC,
		"CHAT_MSG_MONSTER_EMOTE",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_NPC_EMOTE)
		end,
		true
		);
	Soundtrack.CustomEvents.RegisterEventScript(	-- NPC Say
		self,
		SOUNDTRACK_NPC_SAY,
		ST_MISC,
		"CHAT_MSG_MONSTER_SAY",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_NPC_SAY)
		end,
		true
		);
	Soundtrack.CustomEvents.RegisterEventScript(	-- NPC Whisper
		self,
		SOUNDTRACK_NPC_WHISPER,
		ST_MISC,
		"CHAT_MSG_MONSTER_WHISPER",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_NPC_WHISPER)
		end,
		true
		);
	Soundtrack.CustomEvents.RegisterEventScript(	-- NPC Yell
		self,
		SOUNDTRACK_NPC_YELL,
		ST_MISC,
		"CHAT_MSG_MONSTER_YELL",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_NPC_YELL)
		end,
		true
		);
	
	Soundtrack.CustomEvents.RegisterEventScript(	-- Level Up
		self,
	    SOUNDTRACK_LEVEL_UP,
	    ST_MISC,
	    "PLAYER_LEVEL_UP",
	    ST_SFX_LVL,
	    false,
	    function()
	        Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_LEVEL_UP);
	    end,
		true
	    );
	Soundtrack.CustomEvents.RegisterEventScript(	-- Join Party
		self,
	    SOUNDTRACK_JOIN_PARTY,
	    ST_MISC,
	    "GROUP_ROSTER_UPDATE",
	    ST_SFX_LVL,
	    false,
	    function()
	        if SOUNDTRACK_InParty == nil then 
                SOUNDTRACK_InParty = false 
            end
	        if not SOUNDTRACK_InParty and GetNumSubgroupMembers() == 0 and GetNumSubgroupMembers() > 0 then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_JOIN_PARTY)
                SOUNDTRACK_InParty = true
	        elseif SOUNDTRACK_InParty and GetNumSubgroupMembers() == 0 then
                SOUNDTRACK_InParty = false
	        end
	    end,
		true
	    );
	Soundtrack.CustomEvents.RegisterEventScript(	-- Join Raid
		self,
	    SOUNDTRACK_JOIN_RAID,
	    ST_MISC,
	    "GROUP_ROSTER_UPDATE",
	    ST_SFX_LVL,
	    false,
	    function()
	        if SOUNDTRACK_InRaid == nil then 
                SOUNDTRACK_InRaid = false 
            end
	        if not SOUNDTRACK_InRaid and GetNumSubgroupMembers() > 0 then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_JOIN_RAID)
                SOUNDTRACK_InRaid = true
	        elseif SOUNDTRACK_InRaid and not GetNumSubgroupMembers() == 0 then
                SOUNDTRACK_InRaid = false
	        end
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Death Knight Change Presence
		self,
	    SOUNDTRACK_DK_CHANGE,
	    ST_MISC,
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Death Knight" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_DK_CHANGE)
				Soundtrack.CurrentStance = stance;
			end
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Druid Change Form
		self,
	    SOUNDTRACK_DRUID_CHANGE,
	    "Misc",
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Druid" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
				Soundtrack_Custom_PlayEvent("Misc", SOUNDTRACK_DRUID_CHANGE)
				Soundtrack.CurrentStance = stance;
			elseif class == "Druid" and stance == 0 and stance ~= Soundtrack.CurrentStance then
				Soundtrack.CurrentStance = stance;
			end
	    end,
		true
	);
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Druid Prowl
		self,
        SOUNDTRACK_DRUID_PROWL, 
        ST_MISC,
        ST_BUFF_LVL,
        true,
        function()
			local class = UnitClass("player")
            if ST_CLASS_STEALTH == nil then 
                ST_CLASS_STEALTH = false 
            end
            if ST_CLASS_STEALTH and not IsStealthed() and class == "Druid" then
					Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_DRUID_PROWL)
					ST_CLASS_STEALTH = false 
            elseif not ST_CLASS_STEALTH and IsStealthed() and class == "Druid" then
				if Soundtrack.CustomEvents.IsAuraActive(5215) then
					Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_DRUID_PROWL)
					ST_CLASS_STEALTH = true;
				end
            end
        end,
		false
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Paladin Change Auras
		self,
	    SOUNDTRACK_PALADIN_CHANGE,
	    ST_MISC,
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Paladin" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_PALADIN_CHANGE)
				Soundtrack.CurrentStance = stance;
			end
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Priest Change Shadowform
		self,
	    SOUNDTRACK_PRIEST_CHANGE,
	    ST_MISC,
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Priest" and stance ~= 0 then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_PRIEST_CHANGE)
				Soundtrack.CurrentStance = stance;
			end
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Rogue Change Stealth
		self,
	    SOUNDTRACK_ROGUE_CHANGE,
	    ST_MISC,
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Rogue" and stance ~= 0 and stance ~= 2 and not IsStealthed() then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_ROGUE_CHANGE)
				Soundtrack.CurrentStance = stance;
			end
	    end,
		true
	);
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Rogue Stealth
		self,
        SOUNDTRACK_ROGUE_STEALTH, 
        ST_MISC,
        ST_BUFF_LVL,
        true,
        function()
			local class = UnitClass("player")
            if ST_CLASS_STEALTH == nil then 
                ST_CLASS_STEALTH = false 
            end
            if ST_CLASS_STEALTH and not IsStealthed() and class == "Rogue" then
					Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_ROGUE_STEALTH)
					ST_CLASS_STEALTH = false 
            elseif not ST_CLASS_STEALTH and IsStealthed() and class == "Rogue" then
				if Soundtrack.CustomEvents.IsAuraActive(1784) then
					Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_ROGUE_STEALTH)
					ST_CLASS_STEALTH = true;
				end
            end
        end,
		false
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Shaman Change Ghost Wolf
		self,
	    SOUNDTRACK_SHAMAN_CHANGE,
	    ST_MISC,
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Shaman" and stance ~= 0 then
				Soundtrack.CurrentStance = stance;
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_SHAMAN_CHANGE)
			end
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Warrior Change Stances
		self,
	    SOUNDTRACK_WARRIOR_CHANGE,
	    ST_MISC,
	    "UPDATE_SHAPESHIFT_FORM",
	    ST_SFX_LVL,
	    false,
	    function()
	        local class = UnitClass("player")
			local stance = GetShapeshiftForm();
			if class == "Warrior" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
				Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_WARRIOR_CHANGE)
				Soundtrack.CurrentStance = stance;
			end
	    end,
		true
	);
	
	Soundtrack.CustomEvents.RegisterEventScript(	-- Duel Requested
		self,
	    SOUNDTRACK_DUEL_REQUESTED,
	    ST_MISC,
	    "DUEL_REQUESTED",
	    ST_SFX_LVL,
	    false,
	    function()
	        Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_DUEL_REQUESTED)
	    end,
		true
	    );
	Soundtrack.CustomEvents.RegisterEventScript(	-- Quest Complete
		self,
	    SOUNDTRACK_QUEST_COMPLETE,
	    ST_MISC,
	    "QUEST_COMPLETE",
	    ST_SFX_LVL,
	    false,
	    function()
	        Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_QUEST_COMPLETE)
	    end,
		true
	);    

	-- Thanks to zephus67 for the code!
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- Stealthed
		self,
        SOUNDTRACK_STEALTHED, 
        ST_MISC,
        ST_AURA_LVL,
        true,
        function()
            if SNDCUSTOM_IsStealthed == nil then 
                SNDCUSTOM_IsStealthed = false 
            end
            if SNDCUSTOM_IsStealthed and not IsStealthed() then
                Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_STEALTHED)
                SNDCUSTOM_IsStealthed = false 
            elseif not SNDCUSTOM_IsStealthed and IsStealthed() then
                Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_STEALTHED)
                SNDCUSTOM_IsStealthed = true;
            end
        end,
		false
	);
	
	
	-- Thanks to sgtrama!
	Soundtrack.CustomEvents.RegisterEventScript(	-- LFG Complete
		self,
	    SOUNDTRACK_LFG_COMPLETE,
	    ST_MISC,
	    "LFG_COMPLETION_REWARD",
	    ST_SFX_LVL,
	    false,
	    function()
	        Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_LFG_COMPLETE)
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterEventScript(	-- Achievement
		self,
	    SOUNDTRACK_ACHIEVEMENT,
	    ST_MISC,
	    "ACHIEVEMENT_EARNED",
	    ST_SFX_LVL,
	    false,
	    function()
	        Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_ACHIEVEMENT)
	    end,
		true
	);

	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRAGONRIDING_RACE, ST_MISC, 369968, ST_BUFF_LVL, true, false)

	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DK, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_PALADIN, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_PRIEST, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_ROGUE, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_SHAMAN, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_WARRIOR, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_HUNTER, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_EVOKER, ST_MISC, 0, 1, false, false);

	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_COMBAT_EVENTS, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_GROUP_EVENTS, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_NPC_EVENTS, ST_MISC, 0, 1, false, false);
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_STATUS_EVENTS, ST_MISC, 0, 1, false, false);

	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_HUNTER_CAMO, ST_MISC, 90954, ST_BUFF_LVL, true, false)

	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_EVOKER_SOAR, ST_MISC, 369536, ST_BUFF_LVL, true, false)

	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_ROGUE_SPRINT, ST_MISC, 2983, ST_BUFF_LVL, true, false)
	
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_DASH, ST_MISC, 1850, ST_BUFF_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_TIGER_DASH, ST_MISC, 252216, ST_BUFF_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_CAT, ST_MISC, 768, ST_AURA_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_BEAR, ST_MISC, 5487, ST_AURA_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_MOONKIN, ST_MISC, 24858, ST_AURA_LVL, true, false)
	
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_TREE, ST_MISC, 33891, ST_BUFF_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_BEAR, ST_MISC, 102558, ST_BUFF_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_CAT, ST_MISC, 102543, ST_BUFF_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_MOONKIN, ST_MISC, 102560, ST_BUFF_LVL, true, false)
	
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_AQUATIC, ST_MISC, 0, ST_AURA_LVL, true, false)
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_FLIGHT, ST_MISC, 0, ST_AURA_LVL, true, false)
	Soundtrack.CustomEvents.RegisterUpdateScript(	-- SOUNDTRACK_DRUID_TRAVEL
	    self, 
		SOUNDTRACK_DRUID_TRAVEL, 
		ST_MISC, 
		--"UNIT_AURA",
		ST_AURA_LVL, 
		true,
	    function()
	        local buff = Soundtrack.CustomEvents.IsAuraActive(783)
			--local isFlying = IsFlying()
			local canFly = IsFlyableArea()
			local isSwimming = IsSwimming()
			if buff == 783 then
				if isSwimming then
					Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_DRUID_AQUATIC)
				elseif canFly then
					Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_DRUID_FLIGHT)
				else
					Soundtrack_Custom_PlayEvent(ST_MISC, SOUNDTRACK_DRUID_TRAVEL)
				end
			else
				Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_DRUID_AQUATIC)
				Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_DRUID_FLIGHT)
				Soundtrack_Custom_StopEvent(ST_MISC, SOUNDTRACK_DRUID_TRAVEL)
			end
	    end,
		false
	);
	
	Soundtrack.CustomEvents.RegisterBuffEvent(SOUNDTRACK_SHAMAN_GHOST_WOLF, ST_MISC, 2645, ST_AURA_LVL, true, false)
	
    Soundtrack_SortEvents(ST_MISC)
end
-- CustomEvents
function Soundtrack.CustomEvents.CustomInitialize(self)
	self:RegisterEvent("UNIT_AURA")
	
	-- Register events for custom events
	for k,v in pairs(SoundtrackAddon.db.profile.customEvents) do

		-- Fix for buff or debuff events that have the spellId stored as string
		if (v.eventtype == "Buff" or v.eventtype == "Debuff") and type(v.spellId) == "string" then
			local parsedSpellId = tonumber(v.spellId)
			if parsedSpellId then
				v.spellId = parsedSpellId
			end
		end

	    Soundtrack.AddEvent(ST_CUSTOM, k, v.priority, v.continuous, v.soundEffect)
		if v.eventtype == "Event Script" then
			self:RegisterEvent(v.trigger)
		end
	end 
	
    Soundtrack_SortEvents(ST_CUSTOM)
end

-- MiscEvents
function Soundtrack.CustomEvents.MiscOnLoad(self)
	self:RegisterEvent("VARIABLES_LOADED")
end
-- CustomEvents
function Soundtrack.CustomEvents.CustomOnLoad(self)
	self:RegisterEvent("VARIABLES_LOADED")
end

-- MiscEvents
function Soundtrack.CustomEvents.MiscOnUpdate(self, elapsed)
    if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
        for k,v in pairs(Soundtrack_MiscEvents) do
            if v.eventtype == "Update Script" and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				v.script()
            end
        end
    end
end
-- CustomEvents
function Soundtrack.CustomEvents.CustomOnUpdate(self, elapsed)
    if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
        for k,v in pairs(SoundtrackAddon.db.profile.customEvents) do
            if v.eventtype == "Update Script" and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
				v.script()
            end
        end
    end

end


-- MiscEvents
function Soundtrack.CustomEvents.MiscOnEvent(self, event, ...)
	st_arg1, st_arg2, st_arg3, st_arg4, st_arg5, st_arg6, st_arg7, st_arg8, st_arg9, st_arg10, st_arg11, st_arg12, st_arg13, st_arg14, st_arg15, st_arg16, st_arg17, st_arg18, st_arg19, st_arg20, st_arg21, st_arg22, st_arg23, st_arg24 = ...

	debug("MiscOnEvent called")
	Soundtrack.CustomEvents.UpdateActiveAuras()
	
	if event == "VARIABLES_LOADED" then	
		Soundtrack.CustomEvents.MiscInitialize(self)
		event = "UNIT_AURA"
		st_arg1 = "player"
    end
	
    if event == "AUCTION_HOUSE_SHOW" then
        Soundtrack.AuctionHouse = true
    elseif event == "AUCTION_HOUSE_CLOSED" then
        Soundtrack.AuctionHouse = false
    elseif event == "BANKFRAME_OPENED" then
        Soundtrack.Bank = true
    elseif event == "BANKFRAME_CLOSED" then
        Soundtrack.Bank = false
    elseif event == "MERCHANT_SHOW" then
        Soundtrack.Merchant = true
    elseif event == "MERCHANT_CLOSED" then
        Soundtrack.Merchant = false
	elseif event == "TAXIMAP_OPENED" then
        Soundtrack.FlightMaster = true
    elseif event == "TAXIMAP_CLOSED" then
        Soundtrack.FlightMaster = false
	elseif event == "BARBER_SHOP_OPEN" then
		Soundtrack.Barbershop = true
	elseif event == "BARBER_SHOP_CLOSE" then
		Soundtrack.Barbershop = false
    elseif event == "CINEMATIC_START" then
		Soundtrack.Cinematic = true
	elseif event == "CINEMATIC_STOP" then
		Soundtrack.Cinematic = false
	elseif event == "TRAINER_SHOW" then
        Soundtrack.Trainer = true
    elseif event == "TRAINER_CLOSED" then
        Soundtrack.Trainer = false
		
    -- Handle buff/debuff events
    elseif (event == "UNIT_AURA" and st_arg1 == "player") or event == "UPDATE_SHAPESHIFT_FORM" then
		if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
			for k,v in pairs(Soundtrack_MiscEvents) do
				if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
					local isActive = Soundtrack.CustomEvents.IsAuraActive(v.spellId)
					if not v.active and isActive then
						v.active = true
						Soundtrack_Custom_PlayEvent(ST_MISC, k)
					elseif v.active and not isActive then
						v.active = false
						Soundtrack_Custom_StopEvent(ST_MISC, k)
					end
				end
			end
		end
    end
    
    -- Handle custom script events
    if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
        for k,v in pairs(Soundtrack_MiscEvents) do
            if v.eventtype == "Event Script" and event == v.trigger and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				v.script();
            end
        end
    end
end
-- CustomEvents
function Soundtrack.CustomEvents.CustomOnEvent(self, event, ...)
	st_arg1, st_arg2, st_arg3, st_arg4, st_arg5, st_arg6, st_arg7, st_arg8, st_arg9, st_arg10, st_arg11, st_arg12, st_arg13, st_arg14, st_arg15, st_arg16, st_arg17, st_arg18, st_arg19, st_arg20, st_arg21, st_arg22, st_arg23, st_arg24 = ...

	debug("CustomOnEvent called")
	Soundtrack.CustomEvents.UpdateActiveAuras()
	
	if event == "VARIABLES_LOADED" then	
		Soundtrack.CustomEvents.CustomInitialize(self)
    end
	
	if event == "UNIT_AURA" and st_arg1 == "player" then
		debug("UNIT_AURA event")
		if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
			debug("Custom music enabled")
			for k,v in pairs(SoundtrackAddon.db.profile.customEvents) do
				if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
					debug("Has spell id and tracks: "..k)
					local isActive = Soundtrack.CustomEvents.IsAuraActive(v.spellId)
					if not v.active and isActive then
						debug("Not active and has aura: "..k)
						v.active = true
						Soundtrack_Custom_PlayEvent(ST_CUSTOM, k)
					elseif v.active and not isActive then
						debug("Active and doesnt have aura: "..k)
						v.active = false
						Soundtrack_Custom_StopEvent(ST_CUSTOM, k)
					end
				end
			end
		end
	end
	
    -- Handle custom events
    if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
        for k,v in pairs(SoundtrackAddon.db.profile.customEvents) do
            if v.eventtype == "Event Script" and event == v.trigger and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
				RunScript(v.script)
            end
        end
    end
	
end
