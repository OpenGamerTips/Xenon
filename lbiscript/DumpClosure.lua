-- Hey H3x0R, remember to not be an idiot and to run this in vanilla Lua 5.1....why am i talking to myself?
local F = function() -- Function to dump
    glob = "lol"
    for i = 1, 1000000 do
        i = i + 1;
        i = i * 1;
        i = i ^ 1;
        i = i / 1;
        i = i % 1;
        i = -i;
        i = "abc"..i
        print(i)
        local k = string.format("%s....%s", i, "lol")
        glob = k.."xd"
    end
end

string.gsub(string.dump(F), ".", function(C)
    io.write("\\"..string.byte(C))
end)
