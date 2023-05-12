package.path = package.path .. ";../lualibs/?.lua"
local mus = require 'mus'

local pentatonic = {0, 2, 4, 7, 9, 12}

TestMode = {
    testIonian = function ()
        Lu.assertEquals(mus.mode(6), 11)
        Lu.assertEquals(mus.mode(7), 12)
        Lu.assertEquals(mus.mode(-2), -3)
    end,
    testPhrygian = function ()
        Lu.assertEquals(mus.mode(6, 4), 10)
        Lu.assertEquals(mus.mode(-7, 4), -12)
        Lu.assertEquals(mus.mode(9, 4), 16)
        Lu.assertEquals(mus.mode(-2, 4), -3)
    end,
    testCustom = function ()
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
    Lu.assertAlmostEquals(mus.tors(1.5), 7.0195500, 1e-7)
    Lu.assertAlmostEquals(mus.tors(0.75), -4.98044999, 1e-7)
end

function TestTosr()
    Lu.assertAlmostEquals(mus.tosr(7), 1.49830708, 1e-7)
    Lu.assertAlmostEquals(mus.tosr(-5), 0.749153538, 1e-7)
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
    testNumeric = function ()
        Lu.assertEquals(mus.tokey(880), 81)
    end,
    testSymbolic = function ()
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

TestToHz = {
    testKeyNums = function ()
        Lu.assertEquals(mus.tohz(69), 440)
        Lu.assertEquals(mus.tohz(81), 880)
        Lu.assertAlmostEquals(mus.tohz(60), 261.6255653006, 2e-12)
    end,
    testNotes = function ()
        Lu.assertEquals(mus.tohz("a"), 440)
        Lu.assertAlmostEquals(mus.tohz("bs"), 523.2511306012, 2e-11)
        Lu.assertAlmostEquals(mus.tohz("c5"), 523.2511306012, 2e-11)
    end
}

function TestNote ()
    local testNotes = {{60, 60.5}, 61}
    Lu.assertEquals(mus.note(testNotes), {{"c4", "df<4"}, "df4"})
end

TestKeyNum = {
    testNumeric = function ()
        local testHz = {{440, 880}, 220}
        Lu.assertEquals(mus.keynum(testHz), {{69, 81}, 57})
    end,
    testSymbolic = function ()
        local testSyms = {{"bs<3", "cs>-1"}, "bf<-1"}
        Lu.assertEquals(mus.keynum(testSyms), {{59.5, 1.5}, 9.5})
    end,
    testMixed = function ()
        local testers = {"bs<3", {440, {"bf<-1"}, 880}}
        Lu.assertEquals(mus.keynum(testers), {59.5, {69, {9.5}, 81}})
    end
}

function TestToPc ()
    Lu.assertEquals(mus.topc(60), 0)
    Lu.assertAlmostEquals(mus.topc(71.99), 11.99, 1e-14)
    Lu.assertEquals(mus.topc(48.5), 0.5)
end

function TestPclass ()
    Lu.assertEquals(mus.pclass({60, 71.5, {48.5}}), {0, 11.5, {.5}})
end

function TestTrans ()
    Lu.assertEquals(mus.trans(60, 35), 95)
    Lu.assertEquals(mus.trans(-5, -8), -13)
    Lu.assertEquals(mus.trans("b0", -8), 15)
end

function TestTranspose ()
    local tester = {"bf0", 65, {"bf-1"}}
    Lu.assertEquals(mus.transpose(tester, -4), {18, 61, {6}})
end

