--RTV Server 0.1.0
local modem = peripheral.wrap("back")
local speaker = peripheral.wrap("right")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
print("RTV Broadcaster")
while true do
    print("Please Insert a disk")
    os.pullEvent("disk")
    print("mono (m) or stereo (s) ?")
    local ms = read()
    local mono = false
    if ms == "m" then mono = true end
    local frame = 1
    local moreAudio = true
    
    local al = 0
    local ar = 0
    local video = 0
    if mono then
        local fh = fs.open("/disk/1/mono.dfpwm", "rb")
        al = fh.readAll()
        fh.close()
    else
        local fh = fs.open("/disk/1/left.dfpwm", "rb")
        al = fh.readAll()
        fh.close()
        fh = fs.open("/disk/1/right.dfpwm", "rb")
        ar = fh.readAll()
        fh.close()
    end
    local fh = fs.open("/disk/1/show.rtv", "rb")
    video = fh.readAll()
    fh.close()
    local vs = string.byte(video:sub(1, 1))
    video = video:sub(2)
    local vq = math.floor(vs / 64)
    local fpses = {2, 5, 10, 20}
    local fps = fpses[math.floor(vs / 8) % 4]
    local frSi = 2106
    if vq == 2 then
        frSi = 1458
    elseif vq < 2 then
        frSi = 972
    end    
    parallel.waitForAll(function()
    local ac = 1
    while true do
        tosend = {}
        tosend.audio = true
        tosend.mono = mono
        if mono then
            tosend.audioM = decoder(al:sub(6000 * (ac - 1) + 1, 6000 * ac))
            speaker.playAudio(tosend.audioM)
        else
            tosend.audioL = decoder(al:sub(6000 * (ac - 1) + 1, 6000 * ac))
            tosend.audioR = decoder(ar:sub(6000 * (ac - 1) + 1, 6000 * ac))
            speaker.playAudio(tosend.audioL)
        end
        modem.transmit(20000, 1, tosend)
        --print("Audio chunk "..ac.." sent")
        ac = ac + 1
        if #al < 6000 * (ac - 1) + 1 then return end
        os.pullEvent("speaker_audio_empty")
    end
    end, function()
    local frame = 1
    local prevT = 0
    
    local lowest = math.huge
    local highest = 0
    local sum = 0
    local cont = true
    while cont do
        tosend = {}
        
        tosend.video = {vq, video:sub(frSi * (frame - 1) + 1, frSi * frame)}
        
        modem.transmit(20000, 1, tosend)
        local time = os.epoch("utc")
        if prevT ~= 0 then
            local delay = time - prevT
            print("Delay of "..delay.." millis between frames!")
            if delay < lowest then lowest = delay end
            if delay > highest then highest = delay end
            sum = sum + delay
        end
        prevT = time
        --print("Frame "..frame.." sent")
        frame = frame + 1
        if #video < frSi * frame then cont = false end
        local taf = os.epoch() - time
        os.sleep()
        while sum + taf < (1000 / fps) * frame do
            taf = os.epoch("utc") - time
        end
    end
    print("Highest delay: "..highest.." milllis")
    print("Lowest delay: "..lowest.." millis")
    print("Averege delay: "..sum / (frame - 1).." millis")
    print("Expected Average delay: "..1000 / fps.." millis")
    end)
    disk.eject("left")
end
