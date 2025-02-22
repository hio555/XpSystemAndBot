# XpSystemAndBot
 
Developed by [@hio555](https://www.roblox.com/users/9095598/profile) for [@Renewed](https://www.roblox.com/users/10205074/profile?friendshipSourceType=PlayerSearch) who unfortunately decided to charge back payment for this software. Due to this, I am open-sourcing it for anyone to use or learn from. The chargeback has been [independently verified](https://www.reddit.com/r/RobloxDevelopers/comments/1igsewm/comment/mdlxyf6/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1) by the r/robloxgamedev/ mod team.

This program fulfills the following requirements, provided by @Renewed: 

```
XP & Ranking System Overview

This system is designed to track player progress, distribute XP, and manage promotions automatically for enlisted personnel (E1–E9C) within a military-style Roblox group. It utilizes an in-game XP distribution GUI, a group ranking bot, and the Roblox API for seamless automation.

How the System Works

XP Distribution
 •    Eligible Players for XP: Only enlisted players (E1–E9C) can earn XP.
 •    XP Sources:
 •    Players automatically earn 25 XP per hour while in-game.
 •    XP can also be awarded manually by O2–O10 officers and designated staff members through a built-in GUI panel (as shown in the first image).
 •    XP is granted in increments of 25 XP per command execution.
 •    Who Can Give XP?
 •    Officers (O2–O10) and staff members have permission to distribute XP to enlisted personnel using the XP system.
 •    Staff members and officers do not earn XP themselves; they can only award it to others.

XP Tracking & Storage
 •    XP is stored in Roblox DataStores, ensuring persistence across sessions.
 •    The system logs all XP transactions, including who awarded XP, the amount, and the recipient.

Automated Ranking System
 •    Each enlisted rank (E1–E9C) has a predetermined XP threshold for promotion.
 •    Once a player reaches the required XP, they are automatically promoted by the group ranking bot (as seen in the second image).
 •    The bot interacts with the Roblox Group API, adjusting ranks without manual intervention.
 •    If a player does not meet the required XP, they remain at their current rank.

Group Ranking Bot
 •    The bot is responsible for handling promotions and rank updates based on XP progression.
 •    It operates in real-time, ensuring that as soon as a player meets the XP requirement, they are promoted.
 •    All rank changes are logged (as seen in the second image) to ensure transparency and prevent abuse.

System Benefits

Automated & Efficient – No manual intervention required for promotions.
Structured XP System – Only enlisted players (E1–E9C) earn XP, while officers (O2–O10) and staff can only distribute XP.
Real-Time Promotions – Players rank up as soon as they meet the XP requirement.
Logging & Security – Prevents abuse by tracking all XP transactions and rank changes.

```
### The repo at a glance:
- Node.js was deployed using [fly.io](https://fly.io)
- Lua code utilizes rojo, knit, profilestore, etc...
- There is a [place file](Roblox/demo-world.rbxl) called demo-world.rbxl included in the Roblox directory which includes the GUI component I built for this task

### IMPORTANT

- A settings file configures all values within the Roblox program. It is at Roblox/src/shared/Config/data.lua in the repo, or ReplicatedStorage/Common/Config/Data within the .rbxl file
- To display the gui in the .rbxl file, you will need to edit the group ID and group ranks in the data file to a group and rank you are in.
- Roblox/Services/BotService.lua has a unique auth token that is used to verify requests in Node.js. If you want to set up this code, modify it to match what you want to use on the server.
- Roblox/Services/BotService.lua also contains the server URL.
