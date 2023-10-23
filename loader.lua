local targetWords = {"GetConvar", "print", "execute", "command", "txAdmin"}
local foundScripts = {}

function printColored(text, color)
    local colorCode = {
        red = "^1",
        green = "^2",
        yellow = "^3",
        blue = "^4",
        lightblue = "^5",
        purple = "^6",
        white = "^7",
        black = "^8"
    }
    
    local code = colorCode[color] or ""
    print(code .. text)
end

local resources = GetNumResources()

for i = 0, resources - 1 do
    local resourceName = GetResourceByFindIndex(i)
    local numFiles = GetNumResourceMetadata(resourceName, "server_script") or 0
    for j = 0, numFiles - 1 do
        local luaFilePath = GetResourceMetadata(resourceName, "server_script", j)
        if luaFilePath and not foundScripts[luaFilePath] then
            local fileContent = LoadResourceFile(resourceName, luaFilePath)
            
            for _, targetWord in ipairs(targetWords) do
                if fileContent and fileContent:find(targetWord) then
                    local snippet = fileContent:match(targetWord)
                    if snippet then
                        foundScripts[luaFilePath] = true
                        printColored("[script:" .. resourceName .. "] Found Word: " .. targetWord, "yellow")
                        printColored("Code Snippet: " .. snippet, "lightblue")
                    end
                end
            end
        end
    end
end


local Shared = {
    Enable = true,
    DiscordAnnounceDetection = true,
    DiscordWebhook = "", -- webhook add
    ConsolePrint = true,
    StopServer = true,
    BackdoorStrings = {
        "cipher-panel",
        "Enchanced_Tabs",
        "helperServer",
        "ketamin.cc",
        "\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65",
        "\x6b\x65\x74\x61\x6d\x69\x6e\x2e\x63\x63",
        "MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR"
    }
}

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not Shared.Enable then return end
    
    local detectedResources = scanForBackdoors()

    if #detectedResources > 0 then
        if Shared.ConsolePrint then 
            print("^1[DEBUG]^0 Found Backdoor in: ")
            for _, v in pairs(detectedResources) do
                print("^1[DEBUG]^0 Resource: " .. v.resource .. ", Detected String: " .. v.stringFound)
            end
        end

        if Shared.DiscordAnnounceDetection and Shared.DiscordWebhook ~= "" then 
            sendToDiscord(detectedResources)
        end 

        if Shared.StopServer then 
            Citizen.Wait(2000)
            os.exit()
        end
    end
end)

function scanForBackdoors()
    local detectedResources = {}

    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName ~= GetCurrentResourceName() then
            local numFiles = GetNumResourceMetadata(resourceName, 'server_script')
            for j = 0, numFiles-1 do
                local filePath = GetResourceMetadata(resourceName, 'server_script', j)
                local fileContent = LoadResourceFile(resourceName, filePath)
                
                for _, str in ipairs(Shared.BackdoorStrings) do
                    if fileContent and string.find(fileContent, str) then
                        table.insert(detectedResources, {resource = resourceName .. '/' .. filePath, stringFound = str})
                    end
                end
            end
        end
    end
    return detectedResources
end

function sendToDiscord(infectedResources)
    local descriptions = ""
    for _, v in pairs(infectedResources) do
        descriptions = descriptions .. "**Resource:** " .. v.resource .. " **Detected String:** " .. v.stringFound .. "\n"
    end

    local connect = {
        {
            ["color"] = 16711680,
            ["title"] = "Backdoor Detected!",
            ["description"] = descriptions,
            ["footer"] = {["text"] = "Developed By raider0101"}
        }
    }

    PerformHttpRequest(Shared.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "Anti Backdoor", embeds = connect}), {['Content-Type'] = 'application/json'})
end

