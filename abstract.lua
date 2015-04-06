#!/usr/bin/lua

local spars = require "./spars"

local abs = {
    header = {"symbol", "number", "letters"},
    body = {
        {"Σ",  1283714, "qwej"},
        {"Ϟ",  6129378, "oier"},
        {"ש",  9184756, "zoxd"},
        {"‖",  4894456, "poip"},
        {"⑆",  9882737, "vjzp"},
        {"メ", 8812381, "jfie"},
        {"》", 6102900, "fods"},
        {"〇", 2823190, "hasd"},
        {"✠",  1878233, "ypas"},
    }
}

spars.startRepl{
    table = abs,
    useCmdArgs = true,
}
