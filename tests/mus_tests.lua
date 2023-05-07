package.path = package.path .. ";../lualibs/?.lua"
local mus = require 'mus'

local pentatonic = {0, 2, 4, 7, 9, 12}

TestMode = {
    testIonian = function (_)
        Lu.assertEquals(mus.mode(6), 11)
        Lu.assertEquals(mus.mode(7), 12)
        Lu.assertEquals(mus.mode(-2), -3)
    end,
    testDorian = function (_)
        Lu.assertEquals(mus.mode(6, 4), 10)
        Lu.assertEquals(mus.mode(-7, 4), -12)
        Lu.assertEquals(mus.mode(9, 4), 16)
        Lu.assertEquals(mus.mode(-2, 4), -3)
    end,
    testCustom = function (_)
        Lu.assertEquals(mus.mode(3, 0, pentatonic), 7)
        Lu.assertEquals(mus.mode(-7, 2, pentatonic), -16)
        Lu.assertEquals(mus.mode(-3, 0, pentatonic), -8)
    end
}

function TestMakeMode()
    local myMode = mus.makemode(4)
    Lu.assertEquals(myMode(6), 10)
    Lu.assertEquals(myMode(-7), -12)
    myMode = mus.makemode(2, pentatonic)
    Lu.assertEquals(myMode(-7), -16)
end

local myScale = {0, 3, 5, 7, 10, 12}

function TestMakeScale()
    local thisScale = mus.scale(myScale)
    Lu.assertEquals(thisScale(-4), -9)
    Lu.assertEquals(thisScale(4), 10)
    Lu.assertEquals(thisScale(6), 15)
end

function TestFixScale()
    local aScale = {{7, 2}, 4, 5, 9}
    local expected = {0, 2, 3, 5, 7}
    Lu.assertEquals(mus.fixscale(aScale), expected)
end

function TestTors()
    Lu.assertAlmostEquals(mus.tors(1.5),
        7.019550008653874177688702928890052135102450847625732421875,
        9e-16)
    Lu.assertAlmostEquals(mus.tors(0.75),
        -4.9804499913461258227449779401041496385005302727222442626953125,
        9e-16)
end

function TestTosr()
    Lu.assertAlmostEquals(mus.tosr(7),
        1.4983070768766814988238664230202346061560092493891716003417968750,
        9e-16)
    Lu.assertAlmostEquals(mus.tosr(-5),
        0.7491535384383407494119332115101173030780046246945858001708984375,
        9e-16)
end

function TestRatioStep()
    Tester = {2, 4, {0.25, 0.5}}
    Lu.assertEquals(mus.ratiostep(Tester), {12, 24, {-24, -12}})
end

function TestStepRatio()
    Tester = {12, 24, {-24, -12}}
    Lu.assertEquals(mus.stepratio(Tester), {2, 4, {0.25, 0.5}})
end

function TestToNote()
    Lu.assertEquals(mus.tonote(60), "c4")
    Lu.assertEquals(mus.tonote(60.5), "df<4")
    Lu.assertEquals(mus.tonote(61), "df4")
end

TestToKey = {
    testNumeric = function (_)
        Lu.assertEquals(mus.tokey(880), 81)
    end,
    testSymbolic = function (_)
        Lu.assertEquals(mus.tokey("c"), 60)
        Lu.assertEquals(mus.tokey("cs"), 61)
        Lu.assertEquals(mus.tokey("df"), 61)
        Lu.assertEquals(mus.tokey("cf"), 59)
        Lu.assertEquals(mus.tokey("b3"), 59)
        Lu.assertEquals(mus.tokey("bs3"), 60)
        Lu.assertEquals(mus.tokey("bs<3"), 59.5)
        Lu.assertEquals(mus.tokey("cs>"), 61.5)
        Lu.assertEquals(mus.tokey("cs>-1"), 1.5)
        Lu.assertEquals(mus.tokey("bf<-1"), 9.5)
    end
}


