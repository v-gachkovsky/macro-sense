-- Real macros of a Classic warlock (shared by the project's author), used as test cases.
return {
    agony = "#showtooltip\n/cast [@mouseover,harm,nodead] Bane of Agony; Bane of Agony",
    bh = "#showtooltip ",
    curruption = "#showtooltip\n/cast [@mouseover,harm,nodead] Corruption; Corruption",
    demons = "#showtooltip\n/cast [nomod] Summon Voidwalker(Summon)\n/cast [mod:alt] Summon Imp(Summon)\n"
        .. "/cast [mod:cmd] Summon Succubus(Summon)",
    drains = "#showtooltip\n/cast [nomod] Drain Life\n/cast [mod:alt] Drain Soul\n/cast [mod:cmd] Drain Mana",
    fear = "#showtooltip\n/stopcasting\n/cast [@mouseover,harm,nodead] Fear; Fear",
    healthstone = "#showtooltip\n/use [nomod] Lesser Healthstone\n"
        .. "/cast [mod:alt] Create Healthstone;[mod:shift] Create Soulstone;[mod:ctrl] Health Funnel",
    improved = "#showtooltip\n/cast [@mouseover,harm,nodead] Immolate; Immolate",
    magic = "#showtooltip\n/cast [@mouseover,harm,nodead] Curse of the Elements; Curse of the Elements",
    petCC = "#showtooltip\n/cast [pet:Felhunter,@mouseover,harm][pet:Felhunter] Spell Lock;"
        .. "[pet:Succubus,@mouseover,harm][pet:Incubus,@mouseover,harm][pet:Succubus][pet:Incubus] Seduction",
    petSpells = "#showtooltip\n/cast [pet:Voidwalker,mod:alt] Sacrifice;[pet:Voidwalker] Consume Shadows;"
        .. "[pet:Imp,@player] Fire Shield;[pet:Succubus][pet:Incubus] Lash of Pain;"
        .. "[pet:Felhunter,mod:alt,@player][pet:Felhunter,@mouseover,exists][pet:Felhunter] Devour Magic",
    slow = "#showtooltip\n/cast [mod:alt,@mouseover,harm,nodead] Curse of Tongues; [mod:alt] Curse of Tongues; "
        .. "[@mouseover,harm,nodead] Curse of Exhaustion; Curse of Exhaustion",
    soulstone = "#showtooltip\n/use [nomod] Minor Soulstone\n/cast [mod:alt] Create Soulstone",
    weakness = "#showtooltip\n/cast [mod:alt,@mouseover,harm,nodead] Curse of Recklessness; [mod:alt] Curse of "
        .. "Recklessness; [@mouseover,harm,nodead] Curse of Weakness; Curse of Weakness",
    yfyt = "",
    cannibalize = "#showtooltip\n/use [nomod] Wool Bandage\n/cast [mod:alt] Cannibalize(Racial)",
    joke = "/silly",
    kiss = "/kiss",
    lol = "/lol",
    petControl = "#showtooltip\n/petmoveto [nomod]\n/petattack [mod:ctrl,@mouseover,harm,nodead][mod:ctrl,harm,nodead]\n"
        .. "/petstay [mod:shift,nomod:ctrl]\n/petfollow [mod:alt,nomod:ctrl,nomod:shift]",
    rude = "/rude",
    shot = "#showtooltip\n/cast [@mouseover,harm,nodead][] !Shoot",
    spit = "/spit",
    test = "#showtooltip\n/cast [mod:cmd] Bane of Agony",
    wave = "/wave",
}
