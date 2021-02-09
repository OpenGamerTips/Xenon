-- Hey H3x0R, remember to not be an idiot and to run this in vanilla Lua 5.1....why am i talking to myself?
local F = function() -- Function to dump
    print("Hello!")
end

string.gsub(string.dump(f), ".", function(C)
    io.write("\\"..string.byte(C))
end)
