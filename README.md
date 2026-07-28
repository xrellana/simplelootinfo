<p align="center">
  <img src="assets/logo-a-chat-gem.png" width="160" alt="Simple Loot Info">
</p>

<h1 align="center">Simple Loot Info</h1>

<p align="center">
  Adds armor type, equipment slot and item level in front of every gear link in chat.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WoW-Retail%2012.0-e6b243" alt="Retail 12.0">
  <img src="https://img.shields.io/badge/license-MIT-8a5710" alt="MIT">
</p>

---

## What it does

When somebody links a piece of gear, you normally have to hover over it to find out
whether it is even relevant to you. Simple Loot Info answers that question inline.

**Before**

```
You receive loot: [Sabatons of the Silent Vigil]
```

**After**

```
You receive loot: Plate/Legs/639: [Sabatons of the Silent Vigil]
```

The format is `Type/Slot/ItemLevel: [link]`, where *Type* is the item's subtype — the
armor class for armor (`Plate`, `Leather`, …) and the weapon class for weapons
(`Sword`, `Staff`, …). Whatever the client cannot resolve yet is simply left out, so you
never get a broken prefix.

## Features

- Works on loot messages **and** on links other players post in chat.
- Only touches weapons and armor. Consumables, quest items, crafting mats and
  everything else are left untouched.
- Localized slot names — the addon reads them from the game client, so `Legs` shows up
  as `腿部` on a Chinese client, `Beine` on a German one, and so on.
- Pure chat filter. No frames, no taint, no saved variables, no memory footprint worth
  measuring.
- Registers its filters ~2 seconds after login on purpose, so it layers cleanly on top
  of other chat and item-link addons instead of fighting them.

## Monitored channels

| Category | Events |
| --- | --- |
| Loot | `CHAT_MSG_LOOT` |
| Local | Say, Yell |
| Group | Party, Party Leader, Raid, Raid Leader |
| Instance | Instance Chat, Instance Chat Leader |
| Guild | Guild, Officer |
| Private | Whisper, Whisper Inform |
| Other | Custom channels |

## Installation

**CurseForge App** — search for *Simple Loot Info* and hit Install.

**Manual** — download the release zip and extract it so the folder structure is:

```
World of Warcraft/_retail_/Interface/AddOns/SimpleLootInfo/
├── SimpleLootInfo.toc
└── SimpleLootInfo.lua
```

Then `/reload` or restart the client.

## Commands

| Command | Description |
| --- | --- |
| `/sli` | Show the command list |
| `/sli debug` | Toggle debug output (prints why a link was or was not modified) |

Debug mode is the first thing to try if a link is not being decorated — it will tell you
whether the item was skipped as non-equipment or whether the item data had not been
cached yet.

## Compatibility

Built against Interface `120000` (Retail). It uses `C_Item.GetItemInfoInstant` and
`C_Item.GetDetailedItemLevelInfo` with a `GetItemInfo` fallback, and requests item data
asynchronously when the client has not cached it yet.

## Known limitations

- The very first time you see an item in a session, the client may not have its data
  cached. The addon requests it in the background, so a subsequent link of the same item
  will be decorated correctly.
- Only weapons (class ID 2) and armor (class ID 4) are decorated. This is intentional.

## License

MIT — see [LICENSE](LICENSE).
