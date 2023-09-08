--[[
* Ashita - Copyright (c) 2014 - 2022 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

addon.author   = 'Almavivaconte';
addon.name     = 'ticker';
addon.version  = '0.0.1';

require 'common'
--require 'timer'
local settings = require('settings');
local socket = require'socket'

local colors = {   
    4279301120,
    4280084480,
    4280867840,
    4281651200,
    4282434560,
    4283217920,
    4284001280,
    4284784640,
    4285568000,
    4286351360,
    4287134720,
    4287918080,
    4288701440,
    4289484800,
    4290268160,
    4291051520,
    4291834880,
    4292618240,
    4293401600,
    4294184960,
    4294901760
}

local ticker_config =
{
    font =
    {
        family      = 'Arial',
        size        = 8,
        color       = 0xFFFFFFFF,
        position    = { 30, 30 },
        bgcolor     = 0x80000000,
        bgvisible   = true
    },
};

local function getCurrentMp()
	return AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);
end

local function getCurrentHp()
	return AshitaCore:GetMemoryManager():GetParty():GetMemberHP(0);
end

local tickerBlocked = false;
local entityBlocked = false;
local tickTime = 21;
local currentMP = getCurrentMp();
local currentHP = getCurrentHp();
local prevStatus = 0;
local currentStatus = 0;
local lastTime = 0;

local currentLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
local levelMod;

local function calcLevelMod()
    if(currentLevel <= 25) then
        levelMod = 0;
    elseif(currentLevel <= 40) then
        levelMod = 5;
    elseif(currentLevel <= 60) then
        levelMod = 12;
    else
        levelMod = 16;
    end
end
calcLevelMod();

local function getStatus(index)
    return GetEntity(index).Status;
end

local function errHandler()
    return;
end
    

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('load', 'load', function()
    -- Attempt to load the configuration..
    ticker_config = settings.load(ticker_config);
	ticker_config = settings.load(ticker_config);

    -- Create our font object..
    local f = AshitaCore:GetFontManager():Create('__ticker_addon');
    f:SetColor(ticker_config.font.color);
    f:SetFontFamily(ticker_config.font.family);
    f:SetFontHeight(ticker_config.font.size);
    f:SetBold(false);
    f:SetPositionX(ticker_config.font.position[1]);
    f:SetPositionY(ticker_config.font.position[2]);
    f:SetVisible(false);
    f:GetBackground():SetColor(ticker_config.font.bgcolor);
    f:GetBackground():SetVisible(ticker_config.font.bgvisible);
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('unload', 'unload', function()
    local f = AshitaCore:GetFontManager():Get('__ticker_addon');
    ticker_config.font.position = { f:GetPositionX(), f:GetPositionY() };
    -- Save the configuration..
    settings.save();
    
    -- Unload the font object..
    AshitaCore:GetFontManager():Delete('__ticker_addon');
end );

---------------------------------------------------------------------------------------------------
-- func: Render
-- desc: Called when our addon is rendered.
---------------------------------------------------------------------------------------------------
ashita.events.register('d3d_present', 'render', function()
    local f = AshitaCore:GetFontManager():Get('__ticker_addon');
    local selfIndex;

    if not entityBlocked then
        selfIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
        currentStatus = GetEntity(selfIndex).Status;
    end

    if tickTime >= 1 and tickTime <= 21 then
        f:SetColor(colors[math.floor(tickTime)]);
    end

    if currentStatus ~= nil then
        if currentStatus == 33 then
            if(prevStatus ~= currentStatus) then
                prevStatus = currentStatus;
                currentMP = getCurrentMp();
                currentHP = getCurrentHp();
                tickTime = 21;
            end
            if not ((AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0) == 100 or AshitaCore:GetMemoryManager():GetPlayer():GetMPMax() == 0)
                and AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(0) == 100) then
                f:SetVisible(true);
                local curTime = socket.gettime();
                if curTime - lastTime > 0.250 then
                    lastTime = curTime;
                    tickTime = tickTime - 0.25;
                end 
                if getCurrentMp() - currentMP > (10 + levelMod) or getCurrentHp() - currentHP > (10 + levelMod) then
                    tickTime = 10;
                    currentMP = getCurrentMp();
                    currentHP = getCurrentHp();
                end
                --f:SetText("["+math.floor(tickTime) + "] " + (getCurrentMp() - currentMP) +">"+ (10 + levelMod) + " / " + (getCurrentHp() - currentHP) +">"+ (10 + levelMod));
                f:SetText(""+math.floor(tickTime));
            else
                tickTime = 21;
                f:SetVisible(false);
                --f:SetText(AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0) + "% / " + AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(0) + "%")
            end
        else
            prevStatus = 0;
            tickTime = 21;
            f:SetVisible(false);
        end
    end
    
    return;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.events.register('packet_out', 'out', function(e)
    local id = e.id;
    if (id == 0x00D) then
	    local player = AshitaCore:GetMemoryManager():GetPlayer();		
        currentLevel = player:GetMainJobLevel();
        calcLevelMod();
        local f = AshitaCore:GetFontManager():Get('__ticker_addon');
		if(f ~= nil and player ~= nil and not player.isZoning and player:GetIsZoning() == 0) then
			entityBlocked = true;
			f:SetVisible(false);
		end
    elseif (id == 0x0E8) then
        entityBlocked = false;
    end
    return false;
    
end);


ashita.events.register('mouse', 'mouse_cb', function (e)
	local function hit_test(x, y)
        local e_x = ticker_config.font.position[1];
        local e_y = ticker_config.font.position[2];
        local e_w = (32 * ticker_config.font.size) * 4;
        local e_h = (32 * ticker_config.font.size) * 4;
        return ((e_x <= x) and (e_x + e_w) >= x) and ((e_y <= y) and (e_y + e_h) >= y);
    end
	switch(e.message, {
	-- Event: Mouse Wheel Scroll
        [522] = (function ()
            if (e.delta < 0) then
                ticker_config.font.size = ticker_config.font.size - 1;
            else
                ticker_config.font.size = ticker_config.font.size + 1;
            end
            ticker_config.font.size = ticker_config.font.size:clamp(6, 20);
			local f = AshitaCore:GetFontManager():Get('__ticker_addon');
			f:SetFontHeight(ticker_config.font.size);
            --e.blocked = true;
        end):cond(hit_test:bindn(e.x, e.y)),
	});
end);