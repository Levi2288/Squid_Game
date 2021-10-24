/*IDEA
Squid Game Reg & Green Light

if player move on red light he will get enliminated


-
TODO

get red & green light sound from the series &hud text

Some player model

rules 

no dmg to all

*/


#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <store>

#pragma semicolon 1
#pragma newdecls required

#define Sound_Green "squidgame/green_light.mp3"
#define Sound_Red "squidgame/red_light.mp3"
#define Prefix "[\x02Squid\x01Game]"

#define PLUGIN_VERSION "1.00 BETA"
#define PLUGIN_BUILD "43"

bool g_bRedLight = false;
bool g_bSquidGameIsActive;
bool g_bIsClientPlayingSquid[MAXPLAYERS + 1] = true;
bool g_bIsPlayerWon[MAXPLAYERS + 1] = false;
bool g_bClientKilledByGame[MAXPLAYERS + 1] = false;
bool g_bWarmupExecuted = false;

bool g_bSoundEnabled[MAXPLAYERS + 1];
bool g_bScreenColorEnabled[MAXPLAYERS + 1];

Handle TimerStop, TimerStart, TimerDelay, TimerWarmup;
Handle FadeRed, FadeGreen;

int g_iInterval;

Handle g_cClientCookieSound, g_cClientCookieScreen;

ConVar sm_squid_disable_dmg, sm_squid_enable, sm_squid_credit_min, sm_squid_credit_max, sm_squid_reward, sm_squid_case_min, sm_squid_case_max, sm_squid_warmuptime;


public Plugin myinfo = 
{
	name = "Squid Game",
	author = "Levi2288",
	description = "Squid Game Red Light Green Light",
	version = PLUGIN_VERSION,
	url = "https://github.com/Levi2288"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	
	// No need for the old GetGameFolderName setup.
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_CSGO)
	{
		SetFailState("This plugin was made for use with Counter-Strike: Global Offensive only.");
	}
	
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteShort");

	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetColor");

	return APLRes_Success;
} 

public void OnPluginStart()
{
	
	RegAdminCmd("sm_squidstop", CMD_SquidStop, ADMFLAG_BAN);
	RegAdminCmd("sm_squidstart", CMD_SquidStart, ADMFLAG_BAN);
	RegAdminCmd("sm_sleave", CMD_LeaveGame, ADMFLAG_BAN);
	RegAdminCmd("sm_sjoin", CMD_JoinGame, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_squidsettings", CMD_SquidSettings);
	RegConsoleCmd("sm_ss", CMD_SquidSettings);
	RegConsoleCmd("sm_squidinfo", CMD_SquidInfo);
	RegConsoleCmd("sm_sinfo", CMD_SquidInfo);
	
		
	sm_squid_enable = CreateConVar("sm_squid_enable", "1", "Enable/Disable plugin");
	sm_squid_reward = CreateConVar("sm_squid_reward", "1", "Reward mode 0 = disable | 1 = Zeph store credit | 2 = kartoss CaseOpening cash");
	sm_squid_disable_dmg = CreateConVar("sm_squid_disable_dmg", "1", "Enable/Disable anti damage");
	sm_squid_warmuptime = CreateConVar("sm_squid_warmuptime", "30", "Warmup time (recommended: 30)");
	
	sm_squid_credit_min = CreateConVar("sm_squid_credit_min", "200", "Min credit player can win (Only enabled if sm_squid_reward = 1)");
	sm_squid_credit_max = CreateConVar("sm_squid_credit_max", "1000", "Max credit player can win (Only enabled if sm_squid_reward = 1)");
	
	sm_squid_case_min = CreateConVar("sm_squid_case_min", "150", "Min case cash player can win (Only enabled if sm_squid_reward = 2)");
	sm_squid_case_min = CreateConVar("sm_squid_case_max", "600", "Max case cash player can win (Only enabled if sm_squid_reward = 2)");
	
	CreateConVar("sm_pluginnamehere_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cClientCookieSound = RegClientCookie("squidsounds", "Squid Game Sound Cookie", CookieAccess_Private);
	g_cClientCookieScreen = RegClientCookie("squidscreen", "Squid Game screen Cookie", CookieAccess_Private);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		
		if (!IsClientInGame(i))
    	{
			continue;
		}
		
		
		if (AreClientCookiesCached(i))
		{
            OnClientCookiesCached(i);
        }
		else 
		{
			g_bSoundEnabled[i] = true;
			g_bScreenColorEnabled[i] = false;
			
		}
	}
}

/////////////////////////////////////
///////////////INIT//////////////////
/////////////////////////////////////


public void OnMapStart()
{
	
	g_bRedLight = false;
	delete TimerStart;
	delete TimerStop;
	delete TimerDelay;
	delete TimerWarmup;
	PrecacheSound(Sound_Green);
	PrecacheSound(Sound_Red);
	
	AddFileToDownloadsTable(Sound_Green);
	AddFileToDownloadsTable(Sound_Red);
	
	if(sm_squid_enable)
	{
		g_bSquidGameIsActive = true;
	}
	else
	{
		g_bSquidGameIsActive = false;
	}
}

public void OnClientCookiesCached(int client)
{
	
	char sValue[32];
	
	GetClientCookie(client, g_cClientCookieSound, sValue, sizeof(sValue));
	g_bSoundEnabled[client] = (sValue[0] != '\0' && StringToInt(sValue));
	
	GetClientCookie(client, g_cClientCookieScreen, sValue, sizeof(sValue));
	g_bScreenColorEnabled[client] = (sValue[0] != '\0' && StringToInt(sValue));
	
}

public void OnClientPutInServer(int client)
{
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	ResetPlayerVars(client);
}

public void OnClientDisconnect(int client)
{
	
	ResetPlayerVars(client);
	
}
/////////////////////////////////////
////////////////CMDS/////////////////
/////////////////////////////////////

public Action CMD_SquidStop(int client, int args)
{
	
	g_bSquidGameIsActive = false;
	PrintToChatAll("%s The game is paused from the next round!", Prefix);
	
}

public Action CMD_SquidStart(int client, int args)
{
	
	g_bSquidGameIsActive = true;
	PrintToChatAll("%s The game is started from the next round!", Prefix);
	
}
public Action CMD_LeaveGame(int client, int args)
{
	
	
	g_bIsClientPlayingSquid[client] = false;
	PrintToChat(client, "%s You Left the game", Prefix);
	
	
}

public Action CMD_JoinGame(int client, int args)
{
	
	
	g_bIsClientPlayingSquid[client] = true;
	PrintToChat(client, "%s You Joined the game", Prefix);
	
	
}

public Action CMD_SquidSettings(int client, int args)
{
	
	SettingsMenu(client);
}

public Action CMD_SquidInfo(int client, int args)
{
	
	PrintToChat(client, "\x02----------------------");
	PrintToChat(client, "Developer: \x02Levi2288");
	PrintToChat(client, "Version: \x02%s", PLUGIN_VERSION);
	PrintToChat(client, "Build: \x02%s", PLUGIN_BUILD);
	PrintToChat(client, "Found a bug? Report it to me on discord: \x02Levi2288#3444");
	PrintToChat(client, "\x02----------------------");
}

/////////////////////////////////////
///////////////MENUS////////////////
/////////////////////////////////////

public void SettingsMenu(int client)
{
	
	char sSounds[128];
	char sScreen[128];
	Handle SettingMenu = CreateMenu(SettingMenuHandler);
	
	SetMenuTitle(SettingMenu, "Squid Game Settings",client);
	
	Format( sSounds , sizeof( sSounds ) , "Sounds: %s" ,  g_bSoundEnabled[ client ] ? "On":"Off" );
	Format( sScreen , sizeof( sScreen ) , "Screen Effect: %s" ,  g_bScreenColorEnabled[ client ] ? "On":"Off" );
	
	AddMenuItem(SettingMenu, "Sounds", sSounds);
	AddMenuItem(SettingMenu, "Screen", sScreen);
	
	
	DisplayMenu(SettingMenu, client, MENU_TIME_FOREVER);
	
	
}

public int SettingMenuHandler(Menu menu, MenuAction action, int client, int param2)
{	
	

	if(action == MenuAction_Select)
	{
		char items[32];
		menu.GetItem(param2, items, sizeof(items));
		
		if (StrEqual(items, "Sounds")) 
		{
			char sValue[8];
			g_bSoundEnabled[client] = !g_bSoundEnabled[client];
			IntToString(g_bSoundEnabled[client], sValue, sizeof(sValue));
			SetClientCookie(client, g_cClientCookieSound, sValue);
			PrintToChat(client, "%s Sounds: %s", Prefix, g_bSoundEnabled[ client ] ? "\x04On":"\x02Off");
		}
		if (StrEqual(items, "Screen")) 
		{
			char sValue[8];
			g_bScreenColorEnabled[client] = !g_bScreenColorEnabled[client];
			IntToString(g_bScreenColorEnabled[client], sValue, sizeof(sValue));
			SetClientCookie(client, g_cClientCookieScreen, sValue);
			PrintToChat(client, "%s Screen Effect: %s", Prefix, g_bScreenColorEnabled[ client ] ? "\x04On":"\x02Off");
			
		}
		SettingsMenu(client);
	}
} 

/////////////////////////////////////
//////////BCK GROUND TASKS///////////
/////////////////////////////////////


public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	
	if((GetConVarInt(sm_squid_disable_dmg) == 1) && g_bSquidGameIsActive)
	{
		if(IsValidClient(attacker)) //Only prevent players damage
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}



public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bSquidGameIsActive)
	{
		
		if(g_bWarmupExecuted == false)
		{
			g_iInterval = sm_squid_warmuptime.IntValue;
			TimerWarmup = CreateTimer(1.0, Timer_Warmup, _, TIMER_REPEAT);
			
		}
		else
		{
			
			g_bRedLight = false;
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && g_bIsClientPlayingSquid[i])
				{
					g_bIsPlayerWon[i] = false;
					ColorGreen(i);
					if(g_bSoundEnabled[i])
					{
						EmitSoundToClient(i, Sound_Green);	
					}
					if(g_bScreenColorEnabled[i])
					{
						ColorGreen(i);
					}
					PrintHintText(i, "<span style='color:green;'>Green</span> Light!");
				}
			}
			RedLightPrepair();
		}
	}
	else
	{
			
		delete TimerStart;
		delete TimerStop;
		delete TimerDelay;
			
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	
	char VictimName[MAX_NAME_LENGTH];
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	GetClientName(client, VictimName, sizeof(VictimName));

	if(g_bClientKilledByGame[client] && g_bSquidGameIsActive == true)
	{
		
		PrintToChatAll("%s Player %s has been \x02enliminated", Prefix, VictimName);
		
	}
}

public Action Timer_Warmup(Handle timer)
{
	if (g_iInterval <= 0)
	{
		g_bWarmupExecuted = true;
		CS_TerminateRound(1.0, CSRoundEnd_Draw);
		KillTimer(TimerWarmup);
	}
	
	//We print out our global variable which is our count down timer
	PrintHintTextToAll("Warmup time: %d ", g_iInterval);	
	
	//We subtract 1 every second from global variable
	g_iInterval--;
	//Continue running the repeated timer
	return Plugin_Continue;
}

public void RedLightPrepair()
{
	bool bGameEnd = CheckGameEnd();
	if(bGameEnd == true)
	{	
		CS_TerminateRound(7.0, CSRoundEnd_Draw);
		g_bRedLight = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(g_bIsPlayerWon[i] == true)
			{
				RewardPlayer(i, sm_squid_reward.IntValue);
			}
			else
			{
				PrintHintText(i, "You lost better luck next time :D");
				PrintToChat(i, "%s \x02You lost, better luck next time :D", Prefix);
				
			}
		}
	}
	else
	{
		float Random = GetRandomFloat(4.0, 6.0);
		TimerStart = CreateTimer(Random, Timer_Red_Start);
	}
	
	
}


public Action Timer_Red_Start(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && g_bIsClientPlayingSquid[i])
		{
			if(g_bSoundEnabled[ i ])
			{
				EmitSoundToClient(i, Sound_Red);
			}
			if(g_bScreenColorEnabled[i])
			{
				ColorRed(i);
			}
			PrintHintText(i, "<span style='color:red;'>Red</span> Light!");
		}
	}
	
	TimerDelay = CreateTimer(0.5, Timer_DelayRedLight);
	float Random = GetRandomFloat(3.0, 5.0);
	TimerStop = CreateTimer(Random, Timer_Red_Stop);
	KillTimer(timer);	
}


public Action Timer_DelayRedLight(Handle timer, any data)
{
	
	g_bRedLight = true;
	KillTimer(timer);
}

public Action Timer_Red_Stop(Handle timer, any data)
{
	
	g_bRedLight = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && g_bIsClientPlayingSquid[i])
		{
			if(g_bSoundEnabled[ i ])
			{
				EmitSoundToClient(i, Sound_Green);	
			}
			if(g_bScreenColorEnabled[i])
			{
				ColorGreen(i);
			}
			PrintHintText(i, "<span style='color:green;'>Green</span> Light!");
		}
	}
	RedLightPrepair();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	
	if (g_bRedLight && g_bIsClientPlayingSquid[client])
	{
		if (vel[0] != 0.0 || vel[1] != 0.0 || buttons & IN_JUMP)
		{
        //using wasd keys or jumping
			if(g_bIsPlayerWon[client] == false)
			{
			ForcePlayerSuicide(client);
			g_bClientKilledByGame[client] = true;
			
			
			}
		}	
	}
}

public Action OnEnteredProtectedZone(int zone, int client, const char[] prefix)
{
	static Handle ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		char m_iName[MAX_NAME_LENGTH*2];
		char ClientName[MAX_NAME_LENGTH];
		GetEntPropString(zone, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
		GetClientName(client, ClientName, sizeof(ClientName));

		// Skip the first 8 characters of zone name to avoid comparing the "sm_zone " prefix.
		if (StrEqual(m_iName[8], "SquidWin", false))
		{
			if(g_bWarmupExecuted == false)
			{
				
				PrintToChatAll("%s Warmup is active so zones are disabled!", Prefix);
				
			}
			else
			{
				if (GetConVarBool(ShowZones) && g_bIsClientPlayingSquid[client] && g_bSquidGameIsActive && g_bIsPlayerWon[client] == false)
				{
				PrintToChatAll("%s Player \x04%s\x01 has completed the round!", Prefix, ClientName);
				g_bIsPlayerWon[client] = true;
				
				}
			}
		}
	}
}

public Action OnLeftProtectedZone(int zone, int client, const char[] prefix)
{ 
	static Handle ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		char m_iName[MAX_NAME_LENGTH*2];
		GetEntPropString(zone, Prop_Data, "m_iName", m_iName, sizeof(m_iName));

		if (StrEqual(m_iName[8], "SquidWin", false))
		{
			// It's also called whenever player dies within a zone, so dont show a message if player died there
			if (GetConVarBool(ShowZones) && IsPlayerAlive(client) && g_bIsClientPlayingSquid[client] && g_bSquidGameIsActive && g_bWarmupExecuted == true)
			{
				PrintToChatAll("%s You cant leave the win zone!", Prefix);
				
				float EntPos[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", EntPos);
				
				float PlayerPos[3];
				GetClientAbsOrigin(client, PlayerPos);
				
				float vecVelocity[3];
				MakeVectorFromPoints(EntPos, PlayerPos, vecVelocity);
				NormalizeVector(vecVelocity, vecVelocity);
				ScaleVector(vecVelocity, 1000.0); // push speed here
				
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity); 
			}
		}
	}
}




/////////////////////////////////////
///////////////OTHER/////////////////
/////////////////////////////////////

stock bool IsValidClient(int client)
{
	
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public void ResetPlayerVars(int client)
{
	
	g_bIsClientPlayingSquid[client] = true;
	g_bIsPlayerWon[client] = false;
	
	
}

public bool CheckGameEnd()
{
	
	bool bGameEnded = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			if(g_bIsPlayerWon[i] == false)
			{
				
				bGameEnded = false;
				break;
			}
		}
	}
	
	return bGameEnded;
	
	
}

public void ColorGreen(int client)
{
	
	int iColor[4];
	int iclients[1];
	iclients[0] = client;
	
	FadeGreen = StartMessage("Fade", iclients, 1); 
	int FadeDur = RoundToCeil(1.5*1000.0);
	iColor[0] = 14;
	iColor[1] = 153;
	iColor[2] = 14;
	iColor[3] = 50;
	
	
	if(GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(FadeGreen, "duration", FadeDur);
		PbSetInt(FadeGreen, "hold_time", 0);
		PbSetInt(FadeGreen, "flags", 0x0001);
		PbSetColor(FadeGreen, "clr", iColor);
	}
	else
	{
		BfWriteShort(FadeGreen, FadeDur);
		BfWriteShort(FadeGreen, 0);
		BfWriteShort(FadeGreen, (0x0001));
		BfWriteByte(FadeGreen, iColor[0]);
		BfWriteByte(FadeGreen, iColor[1]);
		BfWriteByte(FadeGreen, iColor[2]);
		BfWriteByte(FadeGreen, iColor[3]);
	}
	
	EndMessage();
}

public void ColorRed(int client)
{
	
	int iColor[4];
	int iclients[1];
	iclients[0] = client;
	
	FadeRed = StartMessage("Fade", iclients, 1); 
	int FadeDur = RoundToCeil(1.5*1000.0);
	iColor[0] = 171;
	iColor[1] = 5;
	iColor[2] = 5;
	iColor[3] = 50;
	
	
	if(GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(FadeRed, "duration", FadeDur);
		PbSetInt(FadeRed, "hold_time", 0);
		PbSetInt(FadeRed, "flags", 0x0001);
		PbSetColor(FadeRed, "clr", iColor);
	}
	else
	{
		BfWriteShort(FadeRed, FadeDur);
		BfWriteShort(FadeRed, 0);
		BfWriteShort(FadeRed, (0x0001));
		BfWriteByte(FadeRed, iColor[0]);
		BfWriteByte(FadeRed, iColor[1]);
		BfWriteByte(FadeRed, iColor[2]);
		BfWriteByte(FadeRed, iColor[3]);
	}
	
	EndMessage();
}

public void RewardPlayer(int client, int rewardtype)
{
	if(IsValidClient(client))
	{
		if(rewardtype == 0)
		{
			PrintHintText(client, "<span style='color:green;'>You survived the round! Good job</span>");
			PrintToChat(client, "%s \x04You survived the round! Good job", Prefix);
				
		}
		if(rewardtype == 1)
		{
			int iCreditWon = GetRandomInt(GetConVarInt(sm_squid_credit_min), GetConVarInt(sm_squid_credit_max));
			PrintHintText(client, "<span style='color:green;'>U survived the round! U won: %i credit</span>", iCreditWon);
			PrintToChat(client, "%s \x04You survived the round! U won: \x02%i\x01 credit", Prefix, iCreditWon);
			PrintToChat(client, "%s \x04%i credit added to your balance", Prefix, iCreditWon);
			Store_SetClientCredits(client, Store_GetClientCredits(client) + iCreditWon);	
		}
		else if (rewardtype == 2)
		{
			int iCaseWon = GetRandomInt(GetConVarInt(sm_squid_case_min), GetConVarInt(sm_squid_case_max));
			ServerCommand("sm_cases_addcash %i %i", client, iCaseWon);
			PrintHintText(client, "<span style='color:green;'>U survived the round! U won: %i cash</span>", iCaseWon);
			PrintToChat(client, "%s \x04You survived the round! U won: \x02%i\x01 cash", Prefix, iCaseWon);
			PrintToChat(client, "%s \x04%i added to your cash balance", Prefix, iCaseWon);
		}
	}
}