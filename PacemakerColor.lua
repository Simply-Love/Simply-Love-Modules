-- ============================================================================
-- PacemakerColor.lua
--
-- FOR SIMPLY LOVE 5.9.0 (and forks using it as a base) AND ABOVE ONLY!!
--
-- If you want to use this on older SIMPLY LOVE versions you must
-- modify some files
-- https://github.com/Simply-Love/Simply-Love-SM5/pull/730
--
-- This recolors the pacemaker from just white to better help distinguish
-- if you are ahead or behind.
--
-- Default is green for ahead, red for behind and white for even.
--
-- Made by Kuro, https://github.com/pogof/
--
-- ============================================================================

local module = {}

local AHEAD_COLOR = color("#00ff00") -- Default: GREEN #00ff00
local BEHIND_COLOR = color("#ff0000") -- Default: RED #ff0000
local EVEN_COLOR = color("#f5f5f5") -- Default: Almost WHITE #f5f5f5
local STROKE_COLOR = color("#101010") -- Default: Almost BLACK #101010

local PLAYER_NUMBERS = { PLAYER_1, PLAYER_2 }

local function safe_call(fn)
	local ok, result = pcall(fn)
	if ok then return result end
	return nil
end

local function parse_signed_number(text)
	if not text then return nil end

	local cleaned = tostring(text):gsub("%%", ""):gsub("%s+", "")
	cleaned = cleaned:gsub(",", ".")

	local numeric = cleaned:match("[+-]?%d+%.?%d*") or cleaned:match("[+-]?%.%d+")
	if not numeric then return nil end

	return tonumber(numeric)
end

local function get_pacemaker_actor(player)
	local screen = SCREENMAN:GetTopScreen()
	if not screen then return nil end

	local underlay = safe_call(function() return screen:GetChild("Underlay") end)
	if not underlay then return nil end

	local pn = ToEnumShortString(player)
	local target_af = safe_call(function() return underlay:GetChild("TargetScore" .. pn) end)
	if not target_af then return nil end

	return safe_call(function() return target_af:GetChild("Pacemaker" .. pn) end)
end

local function recolor_pacemaker(actor)
	if not actor then return end

	local text = safe_call(function() return actor:GetText() end)
	local value = parse_signed_number(text)
	if value == nil then return end

	local current_alpha = safe_call(function() return actor:GetDiffuseAlpha() end)
	if current_alpha == nil then current_alpha = 1 end

	if value > 0 then
		actor:diffuse(AHEAD_COLOR)
	elseif value < 0 then
		actor:diffuse(BEHIND_COLOR)
	else
		actor:diffuse(EVEN_COLOR)
	end

	actor:strokecolor(STROKE_COLOR)
	-- Preserve built-in dimming set by Pacemaker.lua when target is unreachable.
	actor:diffusealpha(current_alpha)
end

local function refresh_player(player)
	local pn = ToEnumShortString(player)
	if not (GAMESTATE:IsPlayerEnabled(player) and SL[pn].ActiveModifiers.Pacemaker) then
		return
	end

	recolor_pacemaker(get_pacemaker_actor(player))
end

module.ScreenGameplay = Def.Actor{
	ModuleCommand=function(self)
		self:queuecommand("Refresh")

	end,
	RefreshCommand=function(self)
		for player in ivalues(PLAYER_NUMBERS) do
			refresh_player(player)
		end
	end,
	JudgmentMessageCommand=function(self)
		self:queuecommand("Refresh")
	end,
	ExCountsChangedMessageCommand=function(self)
		self:queuecommand("Refresh")
	end,
	CurrentSongChangedMessageCommand=function(self)
		self:queuecommand("Refresh")
	end
}

return module
