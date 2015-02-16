CSGO Retakes Weapon update
===================
For my own purpose, i first used [this sourcemod plugin](https://forums.alliedmods.net/showthread.php?t=251829)

Unfortunately, this is not maintained anymore and the code is very different from the original one. What i liked in this **RETAKES** plugin was : 

 - gun rounds at the beginning of the map
 - guns'choice

The original plugin is [this repository](https://github.com/splewis/csgo-retakes).

This guy made cool stuffs like [1v1 plugin](https://github.com/splewis/csgo-multi-1v1) and the retakes plugin.

The problem of the [not maintened plugin](https://forums.alliedmods.net/showthread.php?t=251829) is that spawns are not updated and are stored in SQLite database, which sucks for updates from [the original one](https://github.com/splewis/csgo-retakes) who stores spawns into raw files

*So i decided to fork [the original plugin](https://github.com/splewis/csgo-retakes) and get into the wonderful world of Sourcemod plugin compilation*

Goal of this plugin
-------------

This is **NOT a brand new RETAKES plugin at all**. I just wanted to add cool stuff from the original plugin, without changing much codes :
> - 5 first rounds are **GUN only**
> - Smoke forbidden for terrorists
> - Players can chose their gun between 3 slots :
    - Glock / Usp / Hkp2000
    - P250 
    - Tec9 / Fiveseven / CZ
> - Only  1 AWP per team. 
> *Not always the same player from what i read in the original plugin !*

Releases
-------------
**There is no release YET**. I just write some codes but i need to test it on [my server](http://betweenyoureyes.com).

Links related
------------------
 - [Original plugin](https://github.com/splewis/csgo-retakes)
 - [Not maintained plugin](https://forums.alliedmods.net/showthread.php?t=251829)