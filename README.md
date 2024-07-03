# DO NOT USE RELEASES TO DOWNLOAD, I USE GITHUB ACTIONS FOR UPDATES, THE RELEASE IS FROM 2022 AND IS NO LONGER SUPPORTED
## To download: 
Click on [Actions](https://github.com/superpowers04/Super-Engine/actions), select a commit and go to the artifacts to download, you need a github account to download artifacts

# Super Engine (Unstable) [![Build](https://github.com/superpowers04/FunkinBattleRoyale-Mod/actions/workflows/main.yml/badge.svg)](https://github.com/superpowers04/FunkinBattleRoyale-Mod/actions/workflows/main.yml)
A custom engine based on [Funkin Battle Royale](https://github.com/XieneDev/FunkinBattleRoyale/) and very loosely based on [Kade Engine](https://github.com/KadeDev/Kade-Engine) to add a whole bunch of features such as
- No base game bloat
- No hardcoding(Except for BF, GF and the default stage to provide fallbacks)
- Scriptable songs, states, stages and characters using HScript that allows you extensive control over the game allowing for new mechanics, custom features, overhauls and more(Eventually I'll add lua support. it's technically implemented but extremely broken)
- Customizability for most of the features in the engine to make the engine how you want it
- Basic support for Psych Engine, VSlice, and base game mod folders(In some cases you can just symlink or drag and drop a folder for a mod into your `mods/packs` folder and all of the charts will just appear)
- Error handling that'll never have you restart the game because a chart was missing(why is this an issue in other engines :sob:)
- Drag and drop charts into the game's window to play them
- Multikey support

All without recompiling the game at all or editing source code.
<br>Infact, editing source code is discouraged unless you're going to directly contribute to the engine or make a fork of the engine.

This is powered by a modded version of [Kade Engine](https://github.com/KadeDev/Kade-Engine) with a hint of [FPSPlus](https://github.com/ThatRozebudDude/FPS-Plus-Public/) added in and with some inspiration from [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine)/[FNF Multi](https://shadowmario.itch.io/funkinmulti) <br>
I do not own Friday Night Funkin, Kade Engine or Funkin Battle Royale, I'd highly recommend checking them out.


<br>You can find downloads, custom content, get help and more at the [Super Engine Discord server](https://discord.gg/28GPGTRuuR)
<br><br>Note that due to the setup on my end, I push commits all at once, so pull requests and other things might be out of date and need to be merged manually
# Modding information
Read the [mods/readme.txt](https://github.com/superpowers04/Super-Engine/blob/nightly/example_mods/readme.txt) for info about installing/making custom characters, charts, stages and more. 
<br>**Anything beyond bf and gf SHOULD NOT be hardcoded into this engine.** This engine is meant to be a 1 time install with updates, Please do not package this engine inside of a mod. 
<br>If you *have* to include an engine/exe in your mod, [Crowplexus' fork of Forever Engine](https://github.com/crowplexus/Forever-Engine), [Forever Engine Legacy](https://github.com/crowplexus/Forever-Engine-Legacy) and [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) are far more fit for this

## Compiling
- Follow the guide on the Funkin github page [here](https://github.com/ninjamuffin99/Funkin#build-instructions), this should be completely compatible with that guide. 
  Although you will also need to use the installDeps.bat file. While it is a bat file, it works on Windows, Mac and Linux. I only named it .bat so it can work properly on Windows machines or whatever

# Information
## Friday Night Funkin'
**Friday Night Funkin'** is a rhythm game originally made for Ludum Dare 47 "Stuck In a Loop".

Links: **[itch.io page](https://ninja-muffin24.itch.io/funkin) ⋅ [Newgrounds](https://www.newgrounds.com/portal/view/770371) ⋅ [source code on GitHub](https://github.com/ninjamuffin99/Funkin)**
> Uh oh! Your tryin to kiss ur hot girlfriend, but her MEAN and EVIL dad is trying to KILL you! He's an ex-rockstar, the only way to get to his heart? The power of music... 

## Kade Engine
**Kade Engine** is a mod for Friday Night Funkin', including a full engine rework, replays, and more.

Links: **[GameBanana mod page](https://gamebanana.com/gamefiles/16761) ⋅ [play in browser](https://funkin.puyo.xyz) ⋅ [latest stable release](https://github.com/KadeDev/Kade-Engine/releases/latest)
## Friday Night Funkin' Modding Plus
Friday Night Funkin' Modding Plus is a mod of Friday Night Funkin' that aims to make modding easier.
Links: **[GameBanana mod page](https://gamebanana.com/gamefiles/14264) ⋅ [latest stable release](https://github.com/FunkinModdingPlus/ModdingPlus/releases/)
# Credits for everything
<small>I think I got everyone, lemmie know if I missed anyone</small>
## Friday Night Funkin'
 - [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programming
 - [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
 - [Kawai Sprite](https://twitter.com/kawaisprite) - Music

This game was made with love to Newgrounds and its community. Extra love to Tom Fulp.

## Super Engine
- [Superpowers04](https://github.com/superpowers04) - Pretty much everything specific to Super Engine/Lead Developer
- [NayToon](https://github.com/cartoon032) - Some help and providing early Windows builds
- [XieneDev](https://github.com/XieneDev/) - Made Battle Royale. This engine actually wouldn't exist if it wasn't for this pog FNF mod
## Kade Engine (The base engine)
- [KadeDeveloper](https://twitter.com/KadeDeveloper) - Maintainer and lead programmer
- [The contributors](https://github.com/KadeDev/Kade-Engine/graphs/contributors)

## Modding Plus (Several improvements and base for HScript capability)
- [BulbyVR](https://github.com/TheDrawingCoder-Gamer) - Owner/Programmer
- [DJ Popsicle](https://gamebanana.com/members/1780306) - Co-Owner/Additional Programmer
- [Matheus L/Mlops](https://gamebanana.com/members/1767306), [AndreDoodles](https://gamebanana.com/members/1764840), riko, Raf, ElBartSinsoJaJa, and [plum](https://www.youtube.com/channel/UCXbiI4MJD9Y3FpjW61lG8ZQ) - Artist & Animation
- [ThePinkPhantom/JuliettePink](https://gamebanana.com/members/1892442) - Portrait Artist
- [Alex Director](https://gamebanana.com/members/1701629) - Icon Fixer
- [TrafficKid](https://github.com/TrafficKid) - GitHub Wikipedia
- [GwebDev](https://github.com/GrowtopiaFli) - Edited WebM code
- [Axy](https://github.com/AxyGitPoggers) - Poggers help

## FPS Plus (Some improvements)
- [Rozebud](https://twitter.com/helpme_thebigt) - *Everything*

## Embedded Libraries
- [TJSON](https://github.com/JWambaugh/TJSON) - The JSON decoder/encoder SE uses. It's fast and less error-prone than haxe.Json

### Special Thanks
- [JWambaugh](https://github.com/JWambaugh) - The epic tjson library that I copied and modified for Super Engine
- [NoLime](https://gamebanana.com/members/1762727) - Giving permission to have [BF Girlfriend mode](https://gamebanana.com/mods/185105) as a built-in character

## Shoutouts
- [GWebDev](https://twitter.com/GFlipaclip) - Haxeflixel Video
- [Ethab Taxi](https://twitter.com/EthabTaxi) - He's just sorta chillin'.<br>
- [V.S. Ex Tabi](https://gamebanana.com/mods/286388) - The arrow examples are from here
- [Shadow Mario](https://github.com/ShadowMario/) - A whole bunch of inspiration. Both from [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) and [FNF Multi 3.X](https://shadowmario.itch.io/funkinmulti)
