package.path = package.path .. ";../lualibs/?.lua"
local mus = require 'mus'

TestMode = {
    testIonian = function (_)
        Lu.assertEquals(mus.mode(6), 11)
        Lu.assertEquals(mus.mode(7), 12)
        Lu.assertEquals(mus.mode(-2), -3)
    end,
    testDorian = function (_)
        Lu.assertEquals(mus.mode(6, 4), 10)
        Lu.assertEquals(mus.mode(-7, 4), -12)
        Lu.assertEquals(mus.mode(-2, 4), -3)
    end
}
