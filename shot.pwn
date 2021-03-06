#include <a_samp>
#include <core>
#include <float>

// command libraries
#include <smartcmd>
#include <sscanf2>

// basic privileged commands
#include "admin/tempobject.pwn"

#pragma tabsize 0



// player interaction
#define PLAYER_KILL_MONEY_REWARD	250
#define PLAYER_KILL_XP_REWARD    	5

// colors
#define COLOR_DEFAULT				0xAAAAAAFF
#define COLOR_FAILURE           	0xD62B20FF
#define COLOR_ERROR					0xEA9888FF
#define COLOR_ADMINCHAT           	0x2A74D6FF
#define COLOR_STATS					0xFCE68FFF
#define COLOR_WHISPER				0xFFF64CFF
#define COLOR_PRIVILEGE_LOWMODERATOR           	"E0914C"
#define COLOR_PRIVILEGE_MIDMODERATOR           	"E67E22"
#define COLOR_PRIVILEGE_HIGHMODERATOR           "C96A16"
#define COLOR_PRIVILEGE_ADMINISTRATOR           "E74C3C"
#define COLOR_PRIVILEGE_FOUNDER           		"CC392A"

// strings
#define SHOOT_TEXTDRAW_URL	"www.~Y~p~W~hoenix~Y~n~W~etwork.net"
#define SHOOT_COMMANDS_ERR_UNAVAILABLE	"You can not input commands right now."
#define SHOOT_COMMANDS_ERR_DENIED		"You do not met the requirements to execute this command."
#define SHOOT_COMMANDS_ERR_NOTFOUND	"Command %s not found."
#define SHOOT_COMMANDS_ERR_NOPARAMS	"No parameters required."
#define SHOOT_COMMANDS_ERR_PLAYERNOTFOUND	"Player not found."


// enums
#include "core/enums/dialogs.pwn"
#include "core/enums/playerdata.pwn"
#include "core/enums/privileges.pwn"
#include "core/enums/memberships.pwn"
#include "core/enums/disconnects.pwn"

new DB: Database;
new gPData[MAX_PLAYERS][playerdata];
new Text:websiteUrlTextDraw, PlayerText:playerLevelTextDraw[MAX_PLAYERS];

stock getPname(playerid)  
{  
	new pname[24];  
	GetPlayerName(playerid, pname, sizeof(pname));  
	return pname;  
}

stock calcRequiredXP(lvl)  
{  
	new value = 25*lvl*(1+lvl);
	return value;  
}

public increaseLevel(playerid)  
{  
	new string[128];
	gPData[playerid][level] += 1;

	PlayerTextDrawDestroy(playerid, playerLevelTextDraw[playerid]);
	format(string, sizeof(string), "Level %d", gPData[playerid][level])
	playerLevelTextDraw[playerid] = CreatePlayerTextDraw(playerid, 553.000000, 101.000000, string);
	PlayerTextDrawAlignment(playerid, playerLevelTextDraw[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, playerLevelTextDraw[playerid], 0x000000ff);
	PlayerTextDrawFont(playerid, playerLevelTextDraw[playerid], 2);
	PlayerTextDrawLetterSize(playerid, playerLevelTextDraw[playerid], 0.299999, 1.300000);
	PlayerTextDrawColor(playerid, playerLevelTextDraw[playerid], 0xffffffff);
	PlayerTextDrawSetProportional(playerid, playerLevelTextDraw[playerid], 1);
	PlayerTextDrawSetShadow(playerid, playerLevelTextDraw[playerid], 1);
	PlayerTextDrawShow(playerid, playerLevelTextDraw[playerid]);

	SetPlayerScore(playerid,gPData[playerid][level]);

	SendClientMessage(playerid,COLOR_DEFAULT,"Congratulations, you have leveled up!");
}

public pullData(playerid)
{
	new DBResult: Result, buf[129];

	format(buf, sizeof buf, "SELECT * FROM playerdata WHERE name = '%q' LIMIT 1", gPData[playerid][name]);
	Result = db_query(Database, buf);

	if (db_num_rows(Result))
	{
		gPData[playerid][id] = db_get_field_assoc_int(Result, "id");
		gPData[playerid][privilege] = db_get_field_assoc_int(Result, "privilege");
		gPData[playerid][membership] = db_get_field_assoc_int(Result, "membership");
		gPData[playerid][level] = db_get_field_assoc_int(Result, "level");
		gPData[playerid][xp] = db_get_field_assoc_int(Result, "xp");
		gPData[playerid][balance] = db_get_field_assoc_int(Result, "balance");
		gPData[playerid][skinid] = db_get_field_assoc_int(Result, "skinid");
		gPData[playerid][dr] = db_get_field_assoc_int(Result, "dr");
		gPData[playerid][pposx] = db_get_field_assoc_int(Result, "pposx");
		gPData[playerid][pposy] = db_get_field_assoc_int(Result, "pposy");
		gPData[playerid][pposz] = db_get_field_assoc_int(Result, "pposz");
		gPData[playerid][pposa] = db_get_field_assoc_int(Result, "pposa");
	} 
	db_free_result(Result);
}

public submitData(playerid)
{
	new Query[320];

	GetPlayerPos(playerid, gPData[playerid][pposx], gPData[playerid][pposy], gPData[playerid][pposz]);
	GetPlayerFacingAngle(playerid, gPData[playerid][pposa]);
	format(Query, sizeof Query, "UPDATE playerdata SET level=%d, xp=%d, balance=%d, dr=%d, pposx=%f, pposy=%f, pposz=%f, pposa=%f, skinid=%d WHERE id = %d", gPData[playerid][level], gPData[playerid][xp], gPData[playerid][balance], gPData[playerid][dr], gPData[playerid][pposx], gPData[playerid][pposy], gPData[playerid][pposz], gPData[playerid][pposa], gPData[playerid][skinid], gPData[playerid][id]);
	db_query(Database, Query);
}

public sendToAdminChat(playerid, msg[])
{
	new pname[MAX_PLAYER_NAME], string[128];
	GetPlayerName(playerid, pname, sizeof(pname));
	for(new i; i < MAX_PLAYERS; i++)
	{
		if(isStaff(i))
		{
			format(string, sizeof string, "Administration: %s: %s", pname, msg);
			SendClientMessage(i,COLOR_ADMINCHAT,string);
		}
	}
}

public isStaff(playerid)
{
	if(gPData[playerid][privilege] >= PRIVILEGE_LOWMODERATOR)
	{
		return 1;
	}
	return 0;
}

public isCash(playerid)
{
	if(gPData[playerid][membership] >= MEMBERSHIP_CASH)
	{
		return 1;
	}
	return 0;
}

stock getPrivilegeName(playerid)
{
	new prname[64];
	switch(gPData[playerid][privilege])
	{
		case PRIVILEGE_LOWMODERATOR:{prname = "Novice Staff";}
		case PRIVILEGE_MIDMODERATOR:{prname = "Staff";}
		case PRIVILEGE_HIGHMODERATOR:{prname = "High Staff";}
		case PRIVILEGE_ADMINISTRATOR:{prname = "Administrator";}
		case PRIVILEGE_FOUNDER:{prname = "Founder";}
		default:{prname = "None";}
	}
	return prname;
}

stock getPrivilegeColor(playerid)
{
	new prcolor[64];
	switch(gPData[playerid][privilege])
	{
		case PRIVILEGE_LOWMODERATOR:{prcolor = COLOR_PRIVILEGE_LOWMODERATOR;}
		case PRIVILEGE_MIDMODERATOR:{prcolor = COLOR_PRIVILEGE_MIDMODERATOR;}
		case PRIVILEGE_HIGHMODERATOR:{prcolor = COLOR_PRIVILEGE_HIGHMODERATOR;}
		case PRIVILEGE_ADMINISTRATOR:{prcolor = COLOR_PRIVILEGE_ADMINISTRATOR;}
		case PRIVILEGE_FOUNDER:{prcolor = COLOR_PRIVILEGE_FOUNDER;}
		default:{prcolor = "";}
	}
	return prcolor;
}

stock getMembershipName(playerid)
{
	new mbname[64];
	switch(gPData[playerid][membership])
	{
		case MEMBERSHIP_CASH:{mbname = "VIP";}
		case MEMBERSHIP_BIGCASH:{mbname = "VIP+";}
		default:{mbname = "None";}
	}
	return mbname;
}

public getDisconnectReason(pname)
{
	new DBResult: Result, buf[129], dcr;
	format(buf, sizeof buf, "SELECT * FROM playerdata WHERE name = '%q' LIMIT 1", pname);
	Result = db_query(Database, buf);
	dcr = db_get_field_assoc_int(Result, "dr");
	if(dcr >= 0)
	{
		db_free_result(Result);
		return dcr;
	}
	else
	{
		db_free_result(Result);
		return 8;
	}
}

forward increaseLevel(playerid);
forward pullData(playerid);
forward submitData(playerid);
forward sendToAdminChat(playerid, msg[]);
forward isStaff(playerid);
forward isCash(playerid);
forward getPrivilegeName(playerid);
forward getMembershipName(playerid);
forward getDisconnectReason(pname);
native WP_Hash(buffer[], len, const str[]); // required to work with WP hashes on register/login.

main()
{
	aAbB();
	print("Initializing project-shoot...\n");
}

public OnGameModeInit()
{	
	SetGameModeText("Deathmatch/Freeroam");
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
	ShowNameTags(1);
	SetNameTagDrawDistance(40.0);
	EnableStuntBonusForAll(0);
	DisableInteriorEnterExits();
	SetWeather(2);
	SetWorldTime(11);
	UsePlayerPedAnims();

	websiteUrlTextDraw = TextDrawCreate(70.000000,432.000000,SHOOT_TEXTDRAW_URL);
	TextDrawAlignment(websiteUrlTextDraw,2);
	TextDrawBackgroundColor(websiteUrlTextDraw,0x000000ff);
	TextDrawFont(websiteUrlTextDraw,2);
	TextDrawLetterSize(websiteUrlTextDraw,0.199999,1.300000);
	TextDrawColor(websiteUrlTextDraw,0xffffffff);
	TextDrawSetOutline(websiteUrlTextDraw,1);
	TextDrawSetProportional(websiteUrlTextDraw,1);
	TextDrawSetShadow(websiteUrlTextDraw,1);

	if ((Database = db_open("players.db")) == DB: 0)
	{
		print("Failed to open a connection to playerdata database."); 
	} 
	else
	{ 
		db_query(Database, "PRAGMA synchronous = OFF");
		new createTable[620] = "CREATE TABLE IF NOT EXISTS playerdata (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(24) COLLATE NOCASE, password VARCHAR(129), privilege INTEGER DEFAULT 0 NOT NULL, membership INTEGER DEFAULT 0 NOT NULL, level INTEGER DEFAULT 1 NOT NULL, xp INTEGER DEFAULT 0 NOT NULL,";
		strcat(createTable, " balance INTEGER DEFAULT 2500 NOT NULL, skinid INTEGER DEFAULT 73 NOT NULL, dr INTEGER DEFAULT 0 NOT NULL, pposx REAL DEFAULT 0.0 NOT NULL, pposy REAL DEFAULT 0.0 NOT NULL, pposz REAL DEFAULT 0.0 NOT NULL, pposa REAL DEFAULT 0.0 NOT NULL)");
		db_query(Database, createTable);
	} 
	return 1; 
}

public OnGameModeExit() 
{ 
	for(new i; i < MAX_PLAYERS; i++)
	{
		submitData(i);
	}
	db_close(Database);
	return 1; 
}  

public OnPlayerConnect(playerid)
{
	new tmp[playerdata]; 

	gPData[playerid] = tmp; 
	gPData[playerid][loggedin] = 0;
	gPData[playerid][statsSet] = 0;
	TogglePlayerSpectating(playerid,true);

	new Query[82], DBResult: Result;

	GetPlayerName(playerid, gPData[playerid][name], MAX_PLAYER_NAME);
	format(Query, sizeof Query, "SELECT password FROM playerdata WHERE name = '%q' LIMIT 1", gPData[playerid][name]);
	Result = db_query(Database, Query);

	if (db_num_rows(Result))
	{ 
		db_get_field_assoc(Result, "password", gPData[playerid][password], 129);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "It seems you're already registered, please type in your password:", "Login", "Exit");
	} 
	else
	{  
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "It appears to be your first time around, welcome! Please type in a password for your account below.", "Register", "Exit"); 
	} 
	db_free_result(Result);
	TextDrawShowForPlayer(playerid, websiteUrlTextDraw);
	return 1;
}

public OnPlayerDisconnect(playerid, reason) 
{
	switch(reason)
	{
		case 0:{gPData[playerid][dr] = DISCONNECT_CONN_LOST_OR_CRASH;}
		case 1:{gPData[playerid][dr] = DISCONNECT_VOLUNTARILY;}
		case 2:{gPData[playerid][dr] = DISCONNECT_KICKBAN;}
	}
	submitData(playerid);
	
	new tmp[playerdata]; 
	gPData[playerid] = tmp;
	return 1;
}  

public OnPlayerSpawn(playerid)
{
	if(IsPlayerNPC(playerid)) return 1;
	
	if(gPData[playerid][statsSet] < 1)
	{
		SetPlayerPos(playerid, gPData[playerid][pposx], gPData[playerid][pposy], gPData[playerid][pposz]);
		SetPlayerFacingAngle(playerid, gPData[playerid][pposa]);
		SetPlayerScore(playerid,gPData[playerid][level]);
		ResetPlayerMoney(playerid);
		GivePlayerMoney(playerid, gPData[playerid][balance]);

		new string[128];
		format(string, sizeof(string), "Level %d", gPData[playerid][level])
		playerLevelTextDraw[playerid] = CreatePlayerTextDraw(playerid, 553.000000, 101.000000, string);
		PlayerTextDrawAlignment(playerid, playerLevelTextDraw[playerid], 2);
		PlayerTextDrawBackgroundColor(playerid, playerLevelTextDraw[playerid], 0x000000ff);
		PlayerTextDrawFont(playerid, playerLevelTextDraw[playerid], 2);
		PlayerTextDrawLetterSize(playerid, playerLevelTextDraw[playerid], 0.299999, 1.300000);
		PlayerTextDrawColor(playerid, playerLevelTextDraw[playerid], 0xffffffff);
		PlayerTextDrawSetProportional(playerid, playerLevelTextDraw[playerid], 1);
		PlayerTextDrawSetShadow(playerid, playerLevelTextDraw[playerid], 1);
		PlayerTextDrawShow(playerid, playerLevelTextDraw[playerid]);

		gPData[playerid][statsSet] = 1;
	}
	else
	{
		SetPlayerPos(playerid, 2493.9133, -1682.3986, 13.3382);
	}

	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	SetPlayerSkin(playerid, gPData[playerid][skinid]);
	GivePlayerWeapon(playerid,WEAPON_MP5,9999);
	GivePlayerWeapon(playerid,WEAPON_SILENCED,9999);
	GivePlayerWeapon(playerid,WEAPON_AK47,9999);
	GivePlayerWeapon(playerid,WEAPON_SPRAYCAN,9999);

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{ 	
	SendDeathMessage(killerid, playerid, reason);
	gPData[playerid][skinid] = GetPlayerSkin(playerid);
	
	GivePlayerMoney(playerid, 100); // GTA automatically deducts $100 on death.
	
	if(killerid != INVALID_PLAYER_ID)
	{
		gPData[killerid][balance] += PLAYER_KILL_MONEY_REWARD;
		GivePlayerMoney(killerid, PLAYER_KILL_MONEY_REWARD);
		gPData[killerid][xp] += PLAYER_KILL_XP_REWARD;

		new string[128], pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, sizeof pname);
		format(string, sizeof string, "+$%d and +%d XP awarded for killing %s.", PLAYER_KILL_MONEY_REWARD, PLAYER_KILL_XP_REWARD, pname)
		SendClientMessage(killerid, COLOR_DEFAULT, string)

		new requiredXP = calcRequiredXP(gPData[killerid][level]);
		if(gPData[killerid][xp] >= requiredXP)
		{
			increaseLevel(killerid);
		}	
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid){
		case DIALOG_REGISTER:
		{
			if(!response) return Kick(playerid);
			if(!(5 <= strlen(inputtext) <= 20))
			{
				ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "It appears to be your first time around, welcome! Please type in a password for your account below.\n{D62B20}Password must at least have 5 characters, and it can not exceed 20.", "Register", "Exit");
				return 1;
			}

			new Query[208]; 

			WP_Hash(gPData[playerid][password], 129, inputtext);
			format(Query, sizeof Query, "INSERT INTO playerdata (name, password) VALUES ('%q', '%s')", gPData[playerid][name], gPData[playerid][password]);
			db_query(Database, Query);

			new DBResult: Result;

			Result = db_query(Database, "SELECT last_insert_rowid()"); 
			gPData[playerid][id] = db_get_field_int(Result);

			db_free_result(Result);

			pullData(playerid);
			gPData[playerid][loggedin] = 1;
			TogglePlayerSpectating(playerid,false);
		}
		case DIALOG_LOGIN:
		{
			if(!response) return Kick(playerid);
			
			new buf[129];
			
			WP_Hash(buf, 129, inputtext);
			if (strcmp(buf, gPData[playerid][password]))
			{
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "It seems you're already registered, please type in your password:\n{D62B20}Password did not match, try again.", "Login", "Exit");
				return 1;
			}
			pullData(playerid);
			gPData[playerid][loggedin] = 1;
			TogglePlayerSpectating(playerid,false);
		}
		default: return 0;
	}
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(!IsPlayerConnected(playerid)) return 0;
	if(IsPlayerNPC(playerid)) return 1;
	
	// minecraft good, minigun bad
	if(GetPlayerWeapon(playerid) == WEAPON_MINIGUN && gPData[playerid][privilege] < PRIVILEGE_ADMINISTRATOR) {
		Kick(playerid);
		return 0;
	}

	return 1;
}

public OnPlayerText(playerid, text[])
{
	SetPlayerChatBubble(playerid, text, 0xFFFFFFFF, 40.0, 10000);
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	
	if(gPData[damagedid][adminEnabled])
	{
		return 0;
	}
	else
	{
		if (bodypart == 9)
		{
			new Float:hp;
			GetPlayerHealth(damagedid, hp);
			SetPlayerHealth(damagedid, hp-95);
		}
		return 1;
	}
}

// ~-------------~
// C O M M A N D S
// ~-------------~



// ~--------------~
// Command handlers
// ~--------------~



public OnPlayerCommandReceived(cmdid, playerid, cmdtext[])
{
	new playerState = GetPlayerState(playerid);
	if (playerState != PLAYER_STATE_SPECTATING && playerState != PLAYER_STATE_WASTED)
	{
		if(GetCommandFlags(cmdid) <= gPData[playerid][privilege] || GetCommandFlags(cmdid) <= gPData[playerid][membership])
		{
			return 1;
		}
		else
		{
			SendClientMessage(playerid, COLOR_FAILURE, SHOOT_COMMANDS_ERR_DENIED);
			return 0;
		}
	}
	SendClientMessage(playerid, COLOR_FAILURE, SHOOT_COMMANDS_ERR_UNAVAILABLE);
	return 0;
}

public OnPlayerCommandPerformed(cmdid, playerid, cmdtext[], success) {
	if (!success)
	{
		new string[128];
		format(string, sizeof(string), SHOOT_COMMANDS_ERR_NOTFOUND, cmdtext);
		SendClientMessage(playerid, COLOR_FAILURE, string);
	}
	return 1;
}



// ~-----------------~
// Privileged commands
// ~-----------------~



/*
	Command: /restart
	Description: Restarts gamemode.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_FOUNDER>:restart(cmdid, params[])
{
	for(new i; i < MAX_PLAYERS; i++)
	{
		submitData(i);
	}
	SendClientMessageToAll(COLOR_DEFAULT, "Server: Stats saved. Restarting server...");
	SendRconCommand("gmx");
	return CMD_SUCCESS;
}



/*
	Command: /a [message]
	Description: Sends a message to administration private chat.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:a(cmdid, playerid, params[])
{
	sendToAdminChat(playerid, params);
	return CMD_SUCCESS;
}



/*
	Command: /adminmode
	Description: Enables admin mode on command invoker,
	granting godmode along other moderation benefits.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:adminmode(cmdid, playerid, params[])
{
	if(gPData[playerid][adminEnabled])
	{
		SetPlayerHealth(playerid, 100);
		SendClientMessage(playerid,COLOR_DEFAULT,"Administration: Admin mode toggled OFF.");
		SetPlayerColor(playerid, COLOR_DEFAULT);
		gPData[playerid][adminEnabled] = 0;
	}
	else
	{
		SetPlayerHealth(playerid, Float:0x7F800000);
		SendClientMessage(playerid,COLOR_DEFAULT,"Administration: Admin mode toggled ON.");
		SetPlayerColor(playerid, COLOR_FAILURE);
		gPData[playerid][adminEnabled] = 1;
	}
	return CMD_SUCCESS;
}

/* Shortcuts for /adminmode */
ALT:am = CMD:adminmode;



/*
	Command: /setprivilege [player id] [value]
	Description: Sets a player's privilege to a specific value.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_ADMINISTRATOR>:setprivilege(cmdid, playerid, params[])
{
	new pid, priv;
	if (sscanf(params, "ud", pid, priv)) SendClientMessage(playerid, COLOR_ERROR, "Usage: /setprivilege [player id] [privilege]");
	{
		if(pid == INVALID_PLAYER_ID)
		{
			SendClientMessage(playerid, COLOR_ERROR, SHOOT_COMMANDS_ERR_PLAYERNOTFOUND);
			return CMD_SUCCESS;
		}
		new Query[128], string[128], pname[MAX_PLAYER_NAME], tname[MAX_PLAYER_NAME];
		gPData[pid][privilege] = priv;
		format(Query, sizeof Query, "UPDATE playerdata SET privilege=%d WHERE id = %d", gPData[pid][privilege], gPData[pid][id]);
		db_query(Database, Query);
		GetPlayerName(pid, pname, sizeof(pname));
		GetPlayerName(playerid, tname, sizeof(tname));
		format(string, sizeof string, "Administration: %s has set your rank to %s.", tname, getPrivilegeName(pid));
		SendClientMessage(pid, COLOR_DEFAULT, string);
		format(string, sizeof string, "Administration: You have set %s rank to %s.", pname, getPrivilegeName(pid));
		SendClientMessage(playerid, COLOR_DEFAULT, string);
	}
	return CMD_SUCCESS;
}



/*
	Command: /staffpromote [player id]
	Description: Increases a player's privilege by 1.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_ADMINISTRATOR>:staffpromote(cmdid, playerid, params[])
{
	new pid;
	if (sscanf(params, "u", pid)) SendClientMessage(playerid, COLOR_ERROR, "Usage: /staffpromote [player id]");
	{
		if(pid == INVALID_PLAYER_ID)
		{
			SendClientMessage(playerid, COLOR_ERROR, SHOOT_COMMANDS_ERR_PLAYERNOTFOUND);
			return CMD_SUCCESS;
		}
		new Query[128], string[128], pname[MAX_PLAYER_NAME], tname[MAX_PLAYER_NAME];
		gPData[pid][privilege] += 1;
		format(Query, sizeof Query, "UPDATE playerdata SET privilege=%d WHERE id = %d", gPData[pid][privilege], gPData[pid][id]);
		db_query(Database, Query);
		GetPlayerName(pid, pname, sizeof(pname));
		GetPlayerName(playerid, tname, sizeof(tname));
		format(string, sizeof string, "Administration: %s has promoted you to %s.", tname, getPrivilegeName(pid));
		SendClientMessage(pid, COLOR_DEFAULT, string);
		format(string, sizeof string, "Administration: You have promoted %s to %s.", pname, getPrivilegeName(pid));
		SendClientMessage(playerid, COLOR_DEFAULT, string);
	}
	return CMD_SUCCESS;
}



/*
	Command: /staffadd [player id]
	Description: Uppers a player's privilege up to minimum required to appear as staff.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_ADMINISTRATOR>:staffadd(cmdid, playerid, params[])
{
	new pid;
	if (sscanf(params, "u", pid)) SendClientMessage(playerid, COLOR_ERROR, "Usage: /staffadd [player id]");
	{
		if(pid == INVALID_PLAYER_ID)
		{
			SendClientMessage(playerid, COLOR_ERROR, SHOOT_COMMANDS_ERR_PLAYERNOTFOUND);
			return CMD_SUCCESS;
		}
		new Query[128], string[128], pname[MAX_PLAYER_NAME], tname[MAX_PLAYER_NAME];
		gPData[pid][privilege] = 4;
		format(Query, sizeof Query, "UPDATE playerdata SET privilege=%d WHERE id = %d", gPData[pid][privilege], gPData[pid][id]);
		db_query(Database, Query);
		GetPlayerName(pid, pname, sizeof(pname));
		GetPlayerName(playerid, tname, sizeof(tname));
		format(string, sizeof string, "Administration: %s has added you to the Staff team, welcome! (/help admin)", tname);
		SendClientMessage(pid, COLOR_DEFAULT, string);
		format(string, sizeof string, "Administration: You have added %s to the Staff team.", pname);
		SendClientMessage(playerid, COLOR_DEFAULT, string);
	}
	return CMD_SUCCESS;
}



/*
	Command: /tp [player name]
	Description: Teleports to a player.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:tp(cmdid, playerid, params[])
{
    if(isnull(params))
	{
        return SendClientMessage(playerid, COLOR_ERROR, "Usage: /tp [player name]");
    }

    new found, result, target[MAX_PLAYER_NAME], invoker[MAX_PLAYER_NAME], string[128], Float:x, Float:y, Float:z;
    for(new i; i < MAX_PLAYERS; i++)
    {
        new pname[MAX_PLAYER_NAME];
        GetPlayerName(i, pname, sizeof(pname));
        if(strfind(pname, params, true) != -1) {
            result = i;
            found++;
        }
    }
    if(found == 0)
	{
        SendClientMessage(playerid, COLOR_ERROR, "No players found.");
        return CMD_SUCCESS;
    }
    if(found > 1)
	{
        SendClientMessage(playerid, COLOR_ERROR, "More than one player was found with that input, please be specific.");
        return CMD_SUCCESS;
    }
    if(found == 1)
	{
        GetPlayerPos(result, x, y, z);
        if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == 2)
        {
            SetVehiclePos(GetPlayerVehicleID(playerid), x+2, y, z+2);
        }
        else
        {
            SetPlayerPos(playerid, x+2, y, z+2);
        }
        GetPlayerName(result, target, sizeof(target));
        GetPlayerName(playerid, invoker, sizeof(invoker));
        format(string, sizeof string, "Administration: You were teleported to %s.", target); 
        SendClientMessage(playerid,COLOR_DEFAULT,string);
        format(string, sizeof string, "Administration: %s has teleported to your position.", invoker); 
        SendClientMessage(result,COLOR_DEFAULT,string);
        return CMD_SUCCESS;
    }
    return CMD_SUCCESS;
}



/*
	Command: /bring [player name]
	Description: Brings a player to your position.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:bring(cmdid, playerid, params[])
{
    if(isnull(params))
	{
        return SendClientMessage(playerid, COLOR_ERROR, "Usage: /bring [player name]");
    }

    new found, result, target[MAX_PLAYER_NAME], invoker[MAX_PLAYER_NAME], string[128], Float:x, Float:y, Float:z;
    for(new i; i < MAX_PLAYERS; i++)
    {
        new pname[MAX_PLAYER_NAME];
        GetPlayerName(i, pname, sizeof(pname));
        if(strfind(pname, params, true) != -1)
		{
            result = i;
            found++;
        }
    }
    if(found == 0)
	{
        SendClientMessage(playerid, COLOR_ERROR, "No players found.");
        return CMD_SUCCESS;
    }
    if(found > 1)
	{
        SendClientMessage(playerid, COLOR_ERROR, "More than one player was found with that input, please be specific.");
        return CMD_SUCCESS;
    }
    if(found == 1)
	{
        GetPlayerPos(playerid, x, y, z);
        if(IsPlayerInAnyVehicle(result) && GetPlayerState(result) == 2)
        {
            SetVehiclePos(GetPlayerVehicleID(result), x+2, y, z+2);
        }
        else
        {
            SetPlayerPos(result, x+2, y, z+2);
        }
        GetPlayerName(result, target, sizeof(target));
        GetPlayerName(playerid, invoker, sizeof(invoker));
        format(string, sizeof string, "Administration: You brought %s to your position.", target); 
        SendClientMessage(playerid,COLOR_DEFAULT,string);
        format(string, sizeof string, "Administration: %s brought you to his position.", invoker); 
        SendClientMessage(result,COLOR_DEFAULT,string);
        return CMD_SUCCESS;
    }
    return CMD_SUCCESS;
}



/*
	Command: /otp [player id]
	Description: Teleports to a player.
	Notes: Legacy command.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:otp(cmdid, playerid, params[])
{
    new pid, target[MAX_PLAYER_NAME], invoker[MAX_PLAYER_NAME], string[128], Float:x, Float:y, Float:z;
    
    if(pid == INVALID_PLAYER_ID)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Player not found.");
        return CMD_SUCCESS;
    }
    
    if(sscanf(params,"i",pid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /otp [player id]");
    GetPlayerPos(pid, x, y, z);
    SetPlayerPos(playerid, x+2, y, z+2);
    GetPlayerName(pid, target, sizeof(target));
    GetPlayerName(playerid, invoker, sizeof(invoker));
    format(string, sizeof string, "Administration: You were teleported to %s.", target); 
    SendClientMessage(playerid,COLOR_DEFAULT,string);
    format(string, sizeof string, "Administration: %s has teleported to your position.", invoker); 
    SendClientMessage(pid,COLOR_DEFAULT,string);
    return CMD_SUCCESS;
}



/*
	Command: /obring [player id]
	Description: Brings a player to your position.
	Notes: Legacy command.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:obring(cmdid, playerid, params[])
{
    new pid, target[MAX_PLAYER_NAME], invoker[MAX_PLAYER_NAME], string[128], Float:x, Float:y, Float:z;
    
    if(pid == INVALID_PLAYER_ID)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Player not found.");
        return CMD_SUCCESS;
    }
    
    if(sscanf(params,"i",pid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /obring [player id]");
    GetPlayerPos(playerid, x, y, z);
    SetPlayerPos(pid, x+2, y, z+2);
    GetPlayerName(pid, target, sizeof(target));
    GetPlayerName(playerid, invoker, sizeof(invoker));
    format(string, sizeof string, "Administration: You brought %s to your position.", target); 
    SendClientMessage(playerid,COLOR_DEFAULT,string);
    format(string, sizeof string, "Administration: %s brought you to his position.", invoker); 
    SendClientMessage(pid,COLOR_DEFAULT,string);
    return CMD_SUCCESS;
}



/*
	Command: /bringveh [vehicle id]
	Description: Brings a vehicle to your position.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:bringveh(cmdid, playerid, params[])
{
    new vid, distance, string[128], Float:x, Float:y, Float:z, Float:a;
    if(sscanf(params,"i",vid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /bringveh [vehicle id]");
    
    distance = 5;
    
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID(playerid))
    {
        distance += 2;
        GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
    }

    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));
    
    SetVehiclePos(vid, x, y, z);
    
    format(string, sizeof string, "Administration: You brought vehicle ID %d to your position.", vid); 
    SendClientMessage(playerid,COLOR_DEFAULT,string);
    return CMD_SUCCESS;
}



/*
	Command: /kill [player id]
	Description: Kills a player.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_ADMINISTRATOR>:kill(cmdid, playerid, params[])
{
    new pid;
    if(sscanf(params,"i",pid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /kill [player id]");
    
    if(pid == INVALID_PLAYER_ID)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Player not found.");
        return CMD_SUCCESS;
    }
    
    else SetPlayerHealth(pid,0.0);
    return CMD_SUCCESS;
}



/*
	Command: /timeset [time id]
	Description: Sets world time.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_ADMINISTRATOR>:timeset(cmdid, playerid, params[])
{
    new timeid;
    if(sscanf(params,"i",timeid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /timeset [time id]");
    else SetWorldTime(timeid);
    return CMD_SUCCESS;
}



/*
	Command: /weatherset [weather id]
	Description: Sets world weather.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_ADMINISTRATOR>:weatherset(cmdid, playerid, params[])
{
    new weatherid;
    if(sscanf(params,"i",weatherid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /weatherset [weather id]");
    else SetWeather(weatherid);
    return CMD_SUCCESS;
}



/*
	Command: /dr [player name]
	Description: Checks player disconnect reason.
	Notes: N/A.
*/
COMMAND<PRIVILEGE_LOWMODERATOR>:dr(cmdid, playerid, params[])
{
	new dcr, reason[64];
	dcr = getDisconnectReason(params[0]);
	if(dcr < 8)
	{
		switch(dcr)
		{
			case DISCONNECT_VOLUNTARILY:{reason = "Voluntarily";}
			case DISCONNECT_CONN_LOST_OR_CRASH:{reason = "Connection Lost or Crash";}
			case DISCONNECT_ANTICHEAT:{reason = "Kicked by Anticheat";}
			case DISCONNECT_KICKBAN:{reason = "Kicked/Banned by Admin";}
			default:{reason = "Unknown";}
		}
		new string[128];
		format(string, sizeof string, "Administration: %s DR: %s.", params[0], reason);
		SendClientMessage(playerid, COLOR_DEFAULT, string);
	}
	else
	{
		SendClientMessage(playerid, COLOR_ERROR, SHOOT_COMMANDS_ERR_PLAYERNOTFOUND);
		return CMD_SUCCESS;
	}
	return CMD_SUCCESS;
}



// ~-------------~
// Player commands
// ~-------------~



/*
	Command: /veh [vehicle id]
	Description: Spawns a vehicle.
	Notes: N/A.
*/
COMMAND:veh(cmdid, playerid, params[])
{
    new vid, distance, string[128], Float:x, Float:y, Float:z, Float:a;
    distance = 5;

    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    if (GetPlayerVehicleID(playerid))
    {
        distance += 2;
        GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
    }

    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));

    if(sscanf(params,"i",vid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /veh [vehicle id]");
    {
        CreateVehicle(vid, x, y, z, a, -1, -1, 60);
        new str_vid[24];
        valstr(str_vid, vid);
        format(string, sizeof string, "You have spawned a vehicle with ID %s.", str_vid);
        SendClientMessage(playerid,COLOR_DEFAULT,string);
    }
    return CMD_SUCCESS;
}



/*
	Command: /skin [skin id]
	Description: Sets your skin.
	Notes: N/A.
*/
COMMAND:skin(cmdid, playerid, params[])
{
    new sid, string[128];
    if(sscanf(params,"i",sid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /skin [skin id]");
    SetPlayerSkin(playerid, sid);
    new str_sid[24];
    valstr(str_sid, sid);
    format(string, sizeof string, "You have changed your skin to ID %s.", str_sid); 
    SendClientMessage(playerid,COLOR_DEFAULT,string);
    return CMD_SUCCESS;
}



/*
	Command: /wep [weapon id]
	Description: Gives yourself a weapon.
	Notes: N/A.
*/
COMMAND:wep(cmdid, playerid, params[])
{
    new wid, string[128];
    if(sscanf(params,"i",wid)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /wep [weapon id]");
    GivePlayerWeapon(playerid,wid,9999);
    new str_wid[24];
    valstr(str_wid, wid);
    format(string, sizeof string, "You have given yourself weapon ID %s.", str_wid); 
    SendClientMessage(playerid, COLOR_DEFAULT, string);
    return CMD_SUCCESS;
}



/*
	Command: /repair
	Description: Repairs your current vehicle.
	Requires you to be in the driver seat.
	on command input.
	Notes: N/A.
*/
COMMAND:repair(cmdid, playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_ERROR, "You are not in a vehicle.");
    if(GetPlayerState(playerid) != 2) return SendClientMessage(playerid, COLOR_ERROR, "You are not in the driver seat.");
    RepairVehicle(GetPlayerVehicleID(playerid));
    SendClientMessage(playerid, COLOR_DEFAULT, "Your vehicle has been successfully repaired.");
    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
    return 1;
}



/*
	Command: /nitro
	Description: Attaches x10 nitro to your current vehicle (if applicable).
	Requires you to be in the driver seat.
	Notes: N/A.
*/
COMMAND:nitro(cmdid, playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_ERROR, "You are not in a vehicle.");
    if(GetPlayerState(playerid) != 2) return SendClientMessage(playerid, COLOR_ERROR, "You are not in the driver seat.");
    AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
    SendClientMessage(playerid, COLOR_DEFAULT, "Your vehicle now has x10 nitro.");
    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
    return 1;
}



/*
	Command: /id [input]
	Description: Searches for any matching online players based
	on command input.
	Notes: N/A.
*/
COMMAND:id(cmdid, playerid, params[])
{
	if(isnull(params))
	{
		return SendClientMessage(playerid,COLOR_FAILURE,"Usage: /id [player name]");
	}

	new string[128], found;

	for(new i; i < MAX_PLAYERS; i++)
	{
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(i, pname, sizeof(pname));
		if(strfind(pname, params, true) != -1)
		{
			format(string, sizeof(string), "%s (ID %d) (Level: %d)", pname, i, gPData[i][level]);
			SendClientMessage(playerid,COLOR_DEFAULT,string);
			found++;
		}
	}
	if(found == 0)
	{
		SendClientMessage(playerid, COLOR_DEFAULT, SHOOT_COMMANDS_ERR_PLAYERNOTFOUND);
	}
	return CMD_SUCCESS;
}



/*
	Command: /w [player/staff id] [message]
	Description: Privately whispers some message to a certain player.
	Regular users can only whisper staff members with this command.
	Notes: N/A.
*/
COMMAND:w(cmdid, playerid, params[])
{
	new pid, msg[128];
	if(sscanf(params, "us", pid, msg)) SendClientMessage(playerid, COLOR_FAILURE, "Usage: /w [staff id] [message]");
	{
		if(pid == INVALID_PLAYER_ID)
		{
			SendClientMessage(playerid, COLOR_FAILURE, SHOOT_COMMANDS_ERR_PLAYERNOTFOUND);
			return CMD_SUCCESS;
		}
		if(isStaff(pid) || isStaff(playerid))
		{
			new string[128], pname[MAX_PLAYER_NAME];
			GetPlayerName(playerid, pname, sizeof(pname));
			format(string, sizeof string, "Administration: %s (ID %d) whispers: %s", pname, playerid, msg);
			SendClientMessage(pid, COLOR_WHISPER, string);
			GetPlayerName(pid, pname, sizeof(pname));
			format(string, sizeof string, "Administration: you whispered %s (ID %d): %s", pname, pid, msg);
			SendClientMessage(playerid, COLOR_WHISPER, string);
		}
		else
		{
			SendClientMessage(playerid, COLOR_ERROR, "You can only whisper staff members. (/staff)");
		}
	}
	return CMD_SUCCESS;
}



/*
	Command: /staff
	Description: Displays current online staff members.
	Notes: N/A.
*/
COMMAND:staff(cmdid, playerid, params[])
{
	if(!isnull(params))
	{
		return SendClientMessage(playerid, COLOR_ERROR, SHOOT_COMMANDS_ERR_NOPARAMS);
	}

	new string[128], found;
	format(string, sizeof(string), "* Online Staff:");
	SendClientMessage(playerid,COLOR_DEFAULT,string);

	for(new i; i < MAX_PLAYERS; i++)
	{
		if(gPData[i][privilege] >= PRIVILEGE_LOWMODERATOR)
		{
			new pname[MAX_PLAYER_NAME];
			GetPlayerName(i, pname, sizeof(pname));
			format(string, sizeof(string), "{%s}** %s %s (ID %d)", getPrivilegeColor(i), getPrivilegeName(i), pname, i);
			SendClientMessage(playerid,COLOR_DEFAULT,string);
			found++;
		}
	}
	if(found == 0)
	{
		SendClientMessage(playerid, COLOR_DEFAULT, "There are no staff members online.");
	}
	return CMD_SUCCESS;
}



/*
	Command: /stats
	Description: Displays your account stats.
	Notes: N/A.
*/
COMMAND:stats(cmdid, playerid, params[])
{
	new string[128];
	SendClientMessage(playerid, COLOR_STATS, "* Your stats:");
	format(string, sizeof(string), "ID DB: %d | Rank: %s | Membership: %s | Level: %d | Experience: %d/%d | Balance: %d | Skin ID: %d", gPData[playerid][id], getPrivilegeName(playerid), getMembershipName(playerid), gPData[playerid][level], gPData[playerid][xp], calcRequiredXP(gPData[playerid][level]), gPData[playerid][balance], gPData[playerid][skinid]);
	SendClientMessage(playerid, COLOR_STATS, string);
	return CMD_SUCCESS;
}

aAbB()
{
    new a[][] =
    {
        "Unarmed (Fist)",
        "Brass K"
    };
    #pragma unused a
}