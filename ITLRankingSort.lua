-- This is a module for Simply Love that will generate and update playlist for ITL Online 2025
-- That sorts the songs in the pack by your achieved ranking points.
-- Songs that don't have any data yet will just be sorted by title after the songs that do have data.
-- One limitation is that this is based on the data available on your machine as per the itl json file in your profile.
-- This may not capture the most up to date info if you've last played on another machine.
-- Crash Cringle

-- Change this to true if you want unlocks to be listed in their own section/group separate from the main pack.
local separateUnlocksFromBase = false;
local year = 2025

local getITLRankingPath = function(player)
    local path = PROFILEMAN:GetProfileDir(
                     ProfileSlot[PlayerNumber:Reverse()[player] + 1]) ..
                     "Playlists/ITL " .. year .. " RP Sort.txt";
    return path;
end
local lastHash = "";
local generateITLForMusicWheel = function()
    for player in ivalues(GAMESTATE:GetEnabledPlayers()) do
        if PROFILEMAN:IsPersistentProfile(player) then
            local pn = ToEnumShortString(player)
            -- Check if the hash of their itl json has changed
            -- We get the hash by hashing SL[pn].ITLData as a string
            local hash = BinaryToHex(CRYPTMAN:SHA1String(TableToString(SL[pn].ITLData)))
            if lastHash ~= hash then
                lastHash = hash
                local strToWrite = ""
                -- declare itlRankingSongs inside the loop so that P1 and P2 can have independent lists
                local itlRankingSongs = {}
                local path = getITLRankingPath(player)
                -- Get all the songs in the ITL Group
                local group_name = "ITL Online " .. year
                local unlock_group_name = "ITL Online " .. year .. " Unlocks"
                local profileName = PROFILEMAN:GetPlayerName(player) == "" and pn or PROFILEMAN:GetPlayerName(player) 
                if ThemePrefs.Get("SeparateUnlocksByPlayer") then
                    profileName = "NoName"
                    if (PROFILEMAN:GetProfile(player)) then
                        profileName = PROFILEMAN:GetProfile(player):GetDisplayName()
                    end
                    unlock_group_name = "ITL Online " .. year .. " Unlocks - "..profileName
                end

                local itlRankingSongs = {}
                itlRankingSongs[1] = {
                    Name = ("%s's Ranking Points\n"):format(
                                        profileName),
                    Songs = {}
                }
                for _,song in ipairs(SONGMAN:GetSongsInGroup(group_name)) do
                    local arr = split("/", song:GetSongDir())
                    local songDir = arr[3] .. "/" .. arr[4]
                    local songTitle = song:GetDisplayFullTitle()
                    itlRankingSongs[1].Songs[#itlRankingSongs[1].Songs + 1] = {
                        Path = songDir,
                        fullPath = song:GetSongDir(),
                        Title = songTitle
                    }
                end
                if #SONGMAN:GetSongsInGroup(unlock_group_name) ~= 0 and separateUnlocksFromBase then
                    itlRankingSongs[#itlRankingSongs + 1] = {
                        Name = ("%s's Unlock Ranking Points\n"):format(
                                            profileName),
                        Songs = {}
                    }
                end
                for _,song in ipairs(SONGMAN:GetSongsInGroup(unlock_group_name)) do
                    local arr = split("/", song:GetSongDir())
                    local songDir = arr[3] .. "/" .. arr[4]
                    local songTitle = song:GetDisplayFullTitle()
                    itlRankingSongs[#itlRankingSongs].Songs[#itlRankingSongs[#itlRankingSongs].Songs + 1] = {
                        Path = songDir,
                        fullPath = song:GetSongDir(),
                        Title = songTitle
                    }
                end
                -- sort by ranking points
                for i = 1, #itlRankingSongs do
                    table.sort(itlRankingSongs[i].Songs, function(a, b)
                        if a.Title == nil then return false end
                        if b.Title == nil then return true end
                    
                        local dirA, dirB = a.fullPath, b.fullPath
                        local pathMap = SL[pn].ITLData["pathMap"]
                        local hashMap = SL[pn].ITLData["hashMap"]
                    
                        local hashA = pathMap[dirA]
                        local hashB = pathMap[dirB]
                    
                        local pointsA = (hashA and hashMap[hashA]) and (hashMap[hashA]["points"] / 100) or nil
                        local pointsB = (hashB and hashMap[hashB]) and (hashMap[hashB]["points"] / 100) or nil
                    
                        if pointsA and pointsB then
                            return pointsA > pointsB
                        elseif pointsA then
                            return true
                        elseif pointsB then
                            return false
                        else
                            return a.Title:lower() < b.Title:lower()
                        end
                    end)
                    
                end
                -- append each group/song string to the overall strToWrite
                for fav, _ in ivalues(itlRankingSongs) do
                    strToWrite = strToWrite .. ("---%s\n"):format(fav.Name)
                    for song, i in ivalues(fav.Songs) do
                        strToWrite = strToWrite .. ("%s\n"):format(song.Path)
                    end
                end          
                -- SM("ITL strToWrite: " .. strToWrite)
                if strToWrite ~= "" then
                    local path = getITLRankingPath(player)
                    local file = RageFileUtil.CreateRageFile()
                    if file:Open(path, 2) then
                        file:Write(strToWrite)
                        file:Close()
                        file:destroy()
                    else
                        SM("Could not open '" .. path ..
                                "' to write current playing info.")
                    end
                end 
            else
                -- do nothing as the hash has not changed.     
            end    
        end
    end
end


local t = {}

t["ScreenSelectMusic"] = Def.ActorFrame {
    ModuleCommand=function(self)
       generateITLForMusicWheel()
    end
}
return t;