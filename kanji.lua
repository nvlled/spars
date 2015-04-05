#!/usr/bin/lua
local spars = require "./spars"

local hiragana = {
    header = {"roman", "hiragana"},
    body = spars.pairList{
        a="あ",  ra="ら", ma="ま", ha="は", na="な", ta="た",  sa="さ",  ka="か",
        i="い",  ri="り", mi="み", hi="ひ", ni="に", chi="ち", shi="し", ki="き",
        u="う",  ru="る", mu="む", fu="ふ", nu="ぬ", tsu="つ", su="す",  ku="く",
        e="え",  re="れ", me="め", he="へ", ne="ね", te="て",  se="せ",  ke="け",
        o="お",  ro="ろ", mo="も", ho="ほ", no="の", to="と",  so="そ",  ko="こ",

                                   pa="ぱ", ba="ば",  da="だ",    za="ざ",  ga="が",
                                   pi="ぴ", bi="び",  ji="ぢ",    ji="じ",  gi="ぎ",
                                   pu="ぷ", bu="ぶ",  dzu="づ",   zu="ず",  gu="ぐ",
                                   pe="ぺ", be="べ",  de="で",    ze="ぜ",  ge="げ",
                                   po="ぽ", bo="ぼ", ["do"]="ど", zo="ぞ",  go="ご",

        ya="や", yu="ゆ", yo="よ",
        wa="わ", wo="を",
        n="ん",
    }
}

local session = spars.create{
    table = hiragana,
    --question = "hiragana",
    --answer = "roman",
    numChoices = 4,
}

session:repl{
    showChoices = true,
    showCorrect = false,
    formatQuestion = function(question, qcol, acol)
        return acol .. " of " .. question
    end,
    formatPrompt = function(_)
        return "> "
    end
}
