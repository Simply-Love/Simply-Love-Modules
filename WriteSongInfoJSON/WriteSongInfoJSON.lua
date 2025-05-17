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
		--Game Data
		local style  = GAMESTATE:GetCurrentStyle():GetName():gsub("8", "")
		
        --Song Data
		local song   = GAMESTATE:GetCurrentSong()
        local name = song:GetTranslitFullTitle()
        local artist = song:GetTranslitArtist()
        local pack   = song:GetGroupName()
		local banner = song:GetBannerPath()
        local time   = (function(t) return string.format("%d:%02d", math.floor(t/60), math.floor(t%60)) end)(song:GetStepsSeconds())
		
        -- Step Data
        local stepData, diff, steps
        if (GAMESTATE:IsCourseMode()) then
            stepData   = GAMESTATE:GetCurrentCourse():GetCourseEntry(GAMESTATE:GetCourseSongIndex()):GetSong():GetOneSteps(0, 4)
			stepArtist = stepData:GetAuthorCredit()
        else
            stepData   = GAMESTATE:GetCurrentSteps(0)
			stepArtist = stepData:GetAuthorCredit()
        end

        if (stepData ~= nil) then
            blockRating = stepData:GetMeter() or "?"
			difficulty  = stepData:GetDifficulty() or ""
			stepDesc    = stepData:GetDescription() or ""
            stepCount   = stepData:GetRadarValues(0):GetValue(5) or ""
			if difficulty and difficulty ~= "" then
				diffColor   = DifficultyColor(difficulty)
			else
				diffColor = {0,0,0,0}
			end
        else
			blockRating = "?"
            difficulty  = "" 
            stepCount   = ""
			stepDesc    = ""
			diffColor   = {0,0,0,0}
        end

		-- Build lua table
		local data = {
			title       = name,
			artist      = artist,
			pack        = pack,
			stepArtist  = stepArtist,
			stepDesc    = stepDesc,
			banner      = banner,
			length      = time,
			style       = style,
			difficulty  = THEME:GetString("Difficulty",ToEnumShortString(difficulty)),
			blockRating = blockRating,
			diffColor   = diffColor,
			stepCount  = stepCount
		}

        -- Final
        local f = RageFileUtil.CreateRageFile()
        if f:Open("Save/SongInfo.json", 2) then  
            f:Write(JsonEncode(data))
        else    
            local fError = f:GetError()
            Trace( "[FileUtils] Error writing to file: ".. fError )
            f:ClearError()
        end
        f:destroy()
    end
}

return t