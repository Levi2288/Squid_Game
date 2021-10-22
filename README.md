# Squid_Game

[Dod Zones]: https://forums.alliedmods.net/showthread.php?p=1992342
[Zeph Store]: https://forums.alliedmods.net/showthread.php?t=276677
[kartoss CaseOpening]: https://forums.alliedmods.net/showthread.php?t=334527&amp;goto=newpost

Squid game red light, green light gamemode.

This plugin do not prove the game setting so you have to do that yourself.



# Install

Install [Dod Zones]

Drop the smx into ```addons/sourcemod/plugins``` and the sound files to ```sound/```

Restart server


Optional:

Install [Zeph Store] or [kartoss CaseOpening] for reward support.


# Setup
Make a Zone with [Dod Zones] named ```SquidWin```

Change the cvars if you want to.



# Commands

```Admin CMDs```


sm_squidstop (Stop Game can be buggy)

sm_squidstart (Start Game can be buggy)

sm_sleave (Leave game)

sm_sjoin (Join game)


```Player CMDs```


sm_squidsettings (Turn on/off sounds & effects)

sm_ss (Turn on/off sounds & effects)

sm_squidinfo (Print plugin info)

sm_si (Print plugin info)



# Cvars
```
sm_squid_enable (Enable/Disable plugin)
sm_squid_reward (Reward mode 0 = disable | 1 = [Zeph Store] credit | 2 = [kartoss CaseOpening] cash)
sm_squid_disable_dmg (Enable/Disable anti damage)

sm_squid_credit_min (Min credit player can win "Only enabled if sm_squid_reward = 1")
sm_squid_credit_max (Max credit player can win "Only enabled if sm_squid_reward = 1")

sm_squid_case_min (Min case cash player can win "Only enabled if sm_squid_reward = 2")
sm_squid_case_max (Max case cash player can win "Only enabled if sm_squid_reward = 2")
```

# Todo

Maybe a help menu how to play or idk
