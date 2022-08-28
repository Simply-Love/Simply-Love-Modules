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

local function getScreenNameWriteActor(screenName)
    return Def.Actor {
        ModuleCommand = function(self)
            local f = RageFileUtil.CreateRageFile()
            if f:Open("Save/CurrentScreen.txt", 2) then
                f:Write(screenName)
            else
                -- do nothing
            end
            f:destroy()
        end
    }
end

t["ScreenTitleMenu"] = getScreenNameWriteActor("ScreenTitleMenu")
t["ScreenSelectMusic"] = getScreenNameWriteActor("ScreenSelectMusic")
t["ScreenGameplay"] = getScreenNameWriteActor("ScreenGameplay");
t["ScreenEvaluationStage"] = getScreenNameWriteActor("ScreenEvaluationStage")
t["ScreenEvaluationSummary"] = getScreenNameWriteActor("ScreenEvaluationSummary")

return t