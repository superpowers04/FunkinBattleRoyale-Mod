# FunkinBattleRoyale-Mod
This is a mod of [Funkin Battle Royale](https://github.com/XieneDev/FunkinBattleRoyale/) to allow custom characters, and has some other changes.<br>
This is powered by a modded version of [Kade Engine](https://github.com/KadeDev/Kade-Engine) with some of [FPSPlus](https://github.com/ThatRozebudDude/FPS-Plus-Public/) added in.<br>
I do not own Friday Night Funkin, Kade Engine or Funkin Battle Royale, I'd highly recommend checking them out.
This is client aims for customisability besides providing backwards compatibility with normal Funkin Battle Royale servers

## Compiling
To prevent assets from being outdated and for compatibility with custom assets, this repo does not contain any assets besides note splashes. You need to grab assets from Kade Engine and then replace them with the assets from Funkin Battle Royale, then replace Funkin Battle Royale's assets with the ones from here. Then compile like any other mod, You can find compilation instructions in the readme for [the original source code for Friday Night Funkin on Github](https://github.com/ninjamuffin99/Funkin)

How it should be layered:

This(Installed into the folder last)<br>
Funkin Battle Royale<br>
Kade Engine(Installed into the folder first)


# [Kade Engine](https://github.com/KadeDev/Kade-Engine)
![Kade Engine logo](https://user-images.githubusercontent.com/26305836/110529589-4b4eb600-80ce-11eb-9c44-e899118b0bf0.png)

[![AppVeyor](https://img.shields.io/appveyor/build/KadeDev/Kade-Engine-Windows?label=windows%20build)](https://ci.appveyor.com/project/KadeDev/kade-engine-windows/build/artifacts) [![AppVeyor](https://img.shields.io/appveyor/build/KadeDev/Kade-Engine-Macos?label=macOS%20build)](https://ci.appveyor.com/project/KadeDev/kade-engine-macos/build/artifacts)  [![AppVeyor](https://img.shields.io/appveyor/build/KadeDev/Kade-Engine-Linux?label=linux%20build)](https://ci.appveyor.com/project/KadeDev/kade-engine-linux/build/artifacts) [![AppVeyor](https://img.shields.io/appveyor/build/daniel11420/KadeEngineWeb?label=html5&20build)](https://ci.appveyor.com/project/daniel11420/KadeEngineWeb) [![Discord](https://img.shields.io/discord/808039740464300104?label=discord)](https://discord.gg/MG6GQFh52U) [![GitHub issues](https://img.shields.io/github/issues/KadeDev/Kade-Engine)](https://github.com/KadeDev/Kade-Engine/issues) [![GitHub pull requests](https://img.shields.io/github/issues-pr/KadeDev/Kade-Engine)](https://github.com/KadeDev/Kade-Engine/pulls) []() []()

![GitHub commits since latest release (by date)](https://img.shields.io/github/commits-since/KadeDev/Kade-Engine/latest) ![GitHub repo size](https://img.shields.io/github/repo-size/KadeDev/Kade-Engine) ![Lines of code](https://img.shields.io/tokei/lines/github/KadeDev/Kade-Engine) ![Supported platforms](https://img.shields.io/badge/supported%20platforms-windows%2C%20macOS%2C%20linux%2C%20html5-blue) ![GitHub all releases](https://img.shields.io/github/downloads/KadeDev/Kade-Engine/total) ![GitHub](https://img.shields.io/github/license/KadeDev/Kade-Engine) ![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/KadeDev/Kade-Engine?include_prereleases&label=latest%20version) 

# Friday Night Funkin': Kade Engine
## Friday Night Funkin'
**Friday Night Funkin'** is a rhythm game originally made for Ludum Dare 47 "Stuck In a Loop".

Links: **[itch.io page](https://ninja-muffin24.itch.io/funkin) ⋅ [Newgrounds](https://www.newgrounds.com/portal/view/770371) ⋅ [source code on GitHub](https://github.com/ninjamuffin99/Funkin)**
> Uh oh! Your tryin to kiss ur hot girlfriend, but her MEAN and EVIL dad is trying to KILL you! He's an ex-rockstar, the only way to get to his heart? The power of music... 

## Kade Engine
**Kade Engine** is a mod for Friday Night Funkin', including a full engine rework, replays, and more.

Links: **[GameBanana mod page](https://gamebanana.com/gamefiles/16761) ⋅ [play in browser](https://funkin.puyo.xyz) ⋅ [latest stable release](https://github.com/KadeDev/Kade-Engine/releases/latest) ⋅ [latest development build (windows)](https://ci.appveyor.com/project/KadeDev/kade-engine-windows/build/artifacts) ⋅ [latest development build (macOS)](https://ci.appveyor.com/project/KadeDev/kade-engine-macos/build/artifacts) ⋅ [latest development build (linux)](https://ci.appveyor.com/project/KadeDev/kade-engine-linux/build/artifacts)**

**REMEMBER**: This is a **mod**. This is not the vanilla game and should be treated as a **modification**. This is not and probably will never be official, so don't get confused.

## Website ([KadeDev.github.io/kade-engine/](https://KadeDev.github.io/Kade-Engine/))
If you're looking for documentation, changelogs, or guides, you can find those on the Kade Engine website.

# Features

 - **New Input System**
	 - An improved input system, similar to Quaver or Etterna, with less delays, less dropped inputs and other improvements.
 - **More information during gameplay**
	 - While you're playing, we show you information about how you're doing, such as your accuracy, combo break count, notes per second, and your grade/rating.
 - **Better key layouts**
	 - Instead of being forced to use WASD and the arrow keys, now you can play with DFJK!
 - **Replays** (in beta)
	 - Have you ever gotten a crazy score but didn't record? The replay system solves that: it automatically saves a "replay" of your gameplay every time you complete a song, which you can play back inside of the game. 
	 - Replays just store information about what you're doing, they don't actually record the screen -- so they take up way less space on your disk than videos.
 - **Audio offset**
	 - If your headphones are delayed, you can set an offset in the options menu to line the game up with the delay and play with synced audio like intended.

# Credits
### Friday Night Funkin'
 - [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programming
 - [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
 - [Kawai Sprite](https://twitter.com/kawaisprite) - Music

This game was made with love to Newgrounds and its community. Extra love to Tom Fulp.
### Kade Engine
- [KadeDeveloper](https://twitter.com/KadeDeveloper) - Maintainer and lead programmer
- [The contributors](https://github.com/KadeDev/Kade-Engine/graphs/contributors)
