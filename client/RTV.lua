--RTV Client Software 0.1.0
local modem = peripheral.wrap("bottom")
local mon = peripheral.wrap("top")
local sR = peripheral.wrap("right")
local sL = peripheral.wrap("left")
mon.setTextScale(0.5)
modem.open(20000)

function getBits(char, start, len)
    local num = 0
    num = string.byte(char)
    num = num % math.pow(2, 9 - start)
    num = math.floor(num / math.pow(2, 9 - (start + len)))
    return num
end

function sideBar()
    local xs, ys = mon.getSize()
    mon.setBackgroundColour(colours.white)
    mon.setTextColour(colours.black)
    for y = 1, ys do
        mon.setCursorPos(xs - 2, y)
        mon.write("   ")
    end
end

function renderFrame(frame)
    if frame.audio then
        if frame.mono then
            sL.playAudio(frame.audioM)
            sR.playAudio(frame.audioM)
        else
            sL.playAudio(frame.audioL)
            sR.playAudio(frame.audioR)
        end
    elseif frame.video then
        local textTW = {}
        local fgcTW = {}
        local bgcTW = {}
        local index = 1
        if frame.video[1] == 3 then
            for x = 1, 54 do
                for y = 1, 24, 8 do
                    local text = frame.video[2]:sub(index, index + 12)
                    index = index + 13
                    local bits = {}
                    for i = 1, 5 do
                        local byte = text:sub(i, i)
                        for b = 1, 8 do
                            table.insert(bits, getBits(byte, b, 1))
                        end
                    end
                    local cols = {}
                    for i = 6, 13 do
                        local byte = text:sub(i, i)
                        table.insert(cols, math.pow(2, getBits(byte, 1, 4)))
                        table.insert(cols, math.pow(2, getBits(byte, 5, 4)))
                    end
                    
                    for i = 1, 8 do
                        local char = 128
                        local toAdd = 16
                        for j = 1, 5 do
                            if bits[(i - 1) * 5 + j] == 1 then char = char + toAdd end
                            toAdd = toAdd / 2
                        end
                        --mon.setBackgroundColour(cols[(i - 1) * 2 + 1])
                        --mon.setTextColour(cols[(i - 1) * 2 + 2])
                        --mon.setCursorPos(x, y + (i - 1))
                        --mon.write(string.char(char))
                        if textTW[y + (i - 1)] == nil then
                            textTW[y + (i - 1)] = ""
                            fgcTW[y + (i - 1)] = ""
                            bgcTW[y + (i - 1)] = ""
                        end
                        textTW[y + (i - 1)] = textTW[y + (i - 1)]..string.char(char)
                        fgcTW[y + (i - 1)] = fgcTW[y + (i - 1)]..colours.toBlit(cols[(i - 1) * 2 + 2])
                        bgcTW[y + (i - 1)] = bgcTW[y + (i - 1)]..colours.toBlit(cols[(i - 1) * 2 + 1])
                    end
                end
            end
        end
        for y = 1, 24 do
            mon.setCursorPos(1, y)
            mon.blit(textTW[y], fgcTW[y], bgcTW[y])
        end
    end
end

sideBar()

while true do
    local _, _, _, _, msg = os.pullEvent("modem_message")
    renderFrame(msg)
end
