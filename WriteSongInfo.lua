-- Twitch chat module for Simply Love
--
-- Copyright (c) 2022 Vincent Nguyen
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
-- OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
-- CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

local t = {}

t["ScreenGameplay"] = Def.Actor {
    ModuleCommand = function(self)
        local song = GAMESTATE:GetCurrentSong()

        --Song Data
        local name   = "SONG: "..song:GetTranslitFullTitle().." | "
        local artist = "ARTIST: "..song:GetTranslitArtist().." | "
        local pack   = "PACK: "..song:GetGroupName().." | "
        local time = song:GetStepsSeconds()
        time = string.format("LENGTH: %d:%02d | ", math.floor(time/60), math.floor(time%60))

        -- Step Data
        local stepData, diff, steps
        if (GAMESTATE:IsCourseMode()) then
            stepData = GAMESTATE:GetCurrentCourse():GetCourseEntry(GAMESTATE:GetCourseSongIndex()):GetSong():GetOneSteps(0, 4)
        else
            stepData = GAMESTATE:GetCurrentSteps(0)
        end

        if (stepData ~= nil) then
            diff   =  "DIFF: "..stepData:GetMeter().." ["..stepData:GetDescription().."] | "
            steps  = "STEPS:  "..stepData:GetRadarValues(0):GetValue(5).." | "
        else
            diff   = "DIFF: --- | " 
            steps  = "STEPS: --- | "
        end

        -- Final
        local f = RageFileUtil.CreateRageFile()
        if f:Open("Save/SongInfo.txt", 2) then  
            f:Write(name..artist..pack..diff..steps..time)
        else    
            local fError = f:GetError()
            Trace( "[FileUtils] Error writing to file: ".. fError )
            f:ClearError()
        end
        f:destroy()
    end
}

t["ScreenSelectMusic"] = Def.Actor {
    ModuleCommand = function(self)
        local f = RageFileUtil.CreateRageFile()
        if f:Open("Save/SongInfo.txt", 2) then
            f:Write("SONG: --- | ARTIST: ---  | PACK: --- | LENGTH: --- | DIFF: --- | STEPS: --- | ")
        else
            -- do nothing
        end
        f:destroy()
    end
}

return t