engine.name = "PolyPerc"

Mu = require("musicutil")
Util = require("util")
Lfo = require("lib/lfo")
Lattice = require("lattice")

DIVISION_NAMES = {
    "1",
    "1/2.",
    "1/2",
    "1/2t",
    "1/4.",
    "1/4",
    "1/4t",
    "1/8.",
    "1/8",
    "1/8t",
    "1/16.",
    "1/16",
    "1/16t",
    "1/32",
}

DIVISION_VALUES = {
    1,      -- whole
    2 / 3,  -- dotted half
    1 / 2,  -- half
    1 / 3,  -- half triplet
    3 / 8,  -- dotted quarter
    1 / 4,  -- quarter
    1 / 6,  -- quarter triplet
    3 / 16, -- dotted eighth
    1 / 8,  -- eighth
    1 / 12, -- eighth triplet
    3 / 32, -- dotted sixteenth
    1 / 16, -- sixteenth
    1 / 24, -- sixteenth triplet
    1 / 32, -- thirty-second
}

State = {
    mode_transition_active = false
}

Params = include("lib/params")
Gui = include("lib/gui")
Midi_util = include("lib/midi_util")
Seq = include("lib/sequencer")
Stars = include("lib/stars")
Actions = include("lib/actions")
Crosshair = include("lib/crosshair")
StarFactory = include("lib/starfactory")
LFOs = include("lib/lfos");
CosmicDust = include("lib/cosmicdust")
