local t = {}

local function round(x)
    return math.floor(x + 0.5)
end

local so = GAMESTATE:GetSongOptionsObject("ModsLevel_Song")

local function get_rate()
    return so:MusicRate()
end

local function compute_bpm()
    local mpn = GAMESTATE:GetMasterPlayerNumber()
    if not mpn then return nil end

    local player_state = GAMESTATE:GetPlayerState(mpn)
    if not player_state then return nil end

    local sp = player_state:GetSongPosition()
    if not sp then return nil end

    local rate = get_rate()
    return round(sp:GetCurBPS() * 60 * rate)
end

t["ScreenGameplay"] = Def.ActorFrame {
    Name="BPMChangeHighlight",

    InitCommand=function(self)
        -- Roughly matches the default BPM display placement from Simply Love
        self:xy(_screen.cx, 52):valign(1):zoom(1.33)

        local mpn = GAMESTATE:GetMasterPlayerNumber()
        if mpn == PLAYER_2 then
            self:x(_screen.w - self:GetX())
        end
    end,

    ModuleCommand=function(self)
        self.prev_bpm = compute_bpm()

        self:SetUpdateFunction(function(actor)
            local bpm = compute_bpm()
            if bpm ~= nil and actor.prev_bpm ~= nil then
                if bpm > actor.prev_bpm then
                    actor:GetChild("FlashPanel"):playcommand("FlashGreen")
                elseif bpm < actor.prev_bpm then
                    actor:GetChild("FlashPanel"):playcommand("FlashRed")
                end
            end
            actor.prev_bpm = bpm
        end)
    end,

    Def.Quad{
        Name="FlashPanel",
        InitCommand=function(self)
            -- Should be big enough to be noticeable, but not obnoxious (hopefully)
            self:zoomto(100, 30):diffusealpha(0)
        end,
        FlashGreenCommand=function(self)
            self:finishtweening():diffuse(color("0,1,0,1")):diffusealpha(0.6):linear(1):diffusealpha(0)
        end,
        FlashRedCommand=function(self)
            self:finishtweening():diffuse(color("1,0,0,1")):diffusealpha(0.6):linear(1):diffusealpha(0)
        end,
    }
}

return t

-- Copyright (c) 2025 sukibaby

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.