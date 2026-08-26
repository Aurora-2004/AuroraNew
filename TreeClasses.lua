
local Month       = os.date("%B");
local TreeClasses = {

    ["Generic"]     = true,
    ["Cherry"]      = true,
    ["Oak"]         = true,
    ["SnowGlow"]    = true,
    ["Fir"]         = true,
    ["Pine"]        = true,
    ["Birch"]       = true,
    ["Volcano"]     = true,
    ["Frost"]       = true,
    ["GreenSwampy"] = true,
    ["GoldSwampy"]  = true,
    ["Walnut"]      = true,
    ["Koa"]         = true,
    ["CaveCrawler"] = true,
    ["LoneCave"]    = true,
    ["BlueSpruce"]  = Month == "December",
    ["Spooky"]      = Month == "October",
    ["SpookyNeon"]  = Month == "October",

};

return TreeClasses;
