#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

#pragma semicolon 1

#define PLUGIN	"Defeat Mod"
#define VERSION	"1.0"
#define AUTHOR	"Rap"

#define ZERO	0
#define TR	1
#define CT	2

#define DMG_GRENADE (1<<24)

#define MAX_HEALTH 255

#define TASK_RECALL	50

enum Color
{
	NORMAL = 1,
	GREEN,
	RED,
	BLUE
};
enum _:Calldown
{
	NEXUS = 1,
	RECALL
}
enum _:STUFFS
{
	ZEN,
	XP,
	KILLS,
	NEXUS_DAMAGE,
}
enum _:RUNES
{
	SPEED = 1,
	ATTACK_POWER,
	DEFENSE,
	CALLDOWN,
	MAGIC_ATTACK,
	RENCARNATION,
	MAGIC_RESIST,
	GRAVITY,
	HEALTH_PROTECTION,
	ARMOR_PROTECTION,
	EXPERIENCE,
	RANGE,
	ATTACK_SPEED,
	STORE,
	NEXUS_DEFENSE,
	NEXUS_MAGIC_RESIST,
	NEXUS_HEALTH,
	NEXUS_ARMOR
}
new TeamName[ ][ ] =
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};
new const g_szRunesName[ ][ ] =
{
	"",
	"Rune of speed",
	"Rune of attack power",
	"Rune of defense",
	"Rune of calldown",
	"Rune of magic attack",
	"Rune of rencarnation",
	"Rune of magic resist",
	"Rune of gravity",
	"Rune of health protectoin",
	"Rune of armor protetcion",
	"Rune of experience",
	"Rune of range",
	"Rune of attack speed",
	"Rune of store",
	"Rune of nexus defense",
	"Rune of nexus magic resist",
	"Rune of nexus health",
	"Rune of nexus armor"
};
new const g_szInfoTarget[ ]	= "info_target";
new const g_szPlayerClassname[ ]	= "player";

new const TR_BOT[ ]		= "Terrorist BOT";
new const CT_BOT[ ]		= "Counter-Terrorist BOT";

new const g_szNexusSound[ ]	= "Defeat/NexusDefeated.wav";
new const g_szNexusModel[ ]	= "models/Defeat/Nexus.mdl";
new const g_szRecallModel[ ]	= "models/Defeat/Recall.mdl";

new Float: g_flNexusMins[3]	= {-32.0,-32.0,-4.0};
new Float: g_flNexusMaxs[3]	= {32.0, 32.0, 4.0};
new Float: g_flNexusAngles[3]	= {0.0, 0.0, 0.0};

new Float: g_flRecallMins[3]	= {-32.0,-32.0,-4.0};
new Float: g_flRecallMaxs[3]	= {32.0, 32.0, 4.0};
new Float: g_flRecallAngles[3]	= {0.0, 0.0, 0.0};

new Float: g_flGrablength[33];
new Float: g_flCooldown[32];
new Float: g_flDefeatedOrigins[3];
new Float: g_flGrabOffset[33][3];
new Float: g_flRecallOrigins[3][3];
new Float: user_calldown[33][Calldown];

new bool: CanAttack[33];

new g_szViewModel[33][32];
new g_iMenuOwner = ZERO;
new g_iNexus[3] = {ZERO, ZERO, ZERO};
new g_iRecall[3] = {ZERO, ZERO, ZERO};
new g_iGrabbed[33];
new user[33][STUFFS];
new user_Runes[33][RUNES];

new g_iNexusDefeated;

new g_iMaxPlayers;
new g_iMsgSayText;
new g_iMsgTeamInfo;
new g_iBarTime;

new nexus_health;
new recall_time;
new recall_calldown;
new recall_regeneration;


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /menu",	"EntityMenu");
	register_clcmd("+grab",		"cmdGrab");
	register_clcmd("-grab",		"cmdRelease");
	register_clcmd("reload",	"cmdRecall");
	
	register_event("HLTV",		"EventNewRound", "a", "1=0", "2=0");
	register_event("DeathMsg",	"EventDeathMsg", "a");
	
	register_forward(FM_Touch,	"FwdTouch");
	
	RegisterHam(Ham_Spawn,		"player",	"HamSpawn");
	RegisterHam(Ham_Killed,		"info_target",	"HamKilled");
	RegisterHam(Ham_TakeDamage,	"player",	"HamTakeDamage");
	RegisterHam(Ham_ObjectCaps,	"player",	"HamObjectCaps", 1);
	
	g_iMaxPlayers	= get_maxplayers( );
	g_iMsgSayText	= get_user_msgid("SayText");
	g_iMsgTeamInfo	= get_user_msgid("TeamInfo");
	g_iBarTime	= get_user_msgid("BarTime");
	
	nexus_health = register_cvar("defeat_nexus_health", "500");
	recall_time = register_cvar("defeat_recall_time", "8");
	recall_calldown = register_cvar("defeat_recall_calldown", "1");
	recall_regeneration = register_cvar("defeat_recall_regeneration", "25");
	
	EventNewRound( );
}
public plugin_precache( )
{
	precache_sound(g_szNexusSound);
	precache_model(g_szNexusModel);
}
public plugin_cfg( )
{	
	LoadNexus( );
	LoadRecall( );
}
public client_putinserver(id)
{
	CanAttack[id] = true;
}
public client_disconnect(id)
{
	if( id == g_iMenuOwner )
		g_iMenuOwner = ZERO;
	
	if( task_exists(id) )
		remove_task(id);
}
public client_PreThink(id)
{
	new button = get_user_button(id);
	new oldbutton = get_user_oldbutton(id);
	
	if( g_iGrabbed[id] > 0 )
	{
		if( button & IN_ATTACK && !(oldbutton & IN_ATTACK) ) cmdAttack(id);
			
		if( button & IN_ATTACK2 && !(oldbutton & IN_ATTACK2) ) cmdAttack2(id);
		
		button &= ~IN_ATTACK;
		entity_set_int(id, EV_INT_button, button);
		
		if( is_valid_ent(g_iGrabbed[id]) )
			MoveGrabbedEnt(id);
		
		else
			cmdRelease(id);
	}
}
cmdAttack(id)
{
	g_flGrablength[id] += 16.0;
}
cmdAttack2(id)
{
	if( g_flGrablength[id] > 72.0)
		g_flGrablength[id] -= 16.0;
}
public cmdRecall(id)
{
	CreateBarTime(id, get_pcvar_num(recall_time));
	
	taskRecall(id + TASK_RECALL);
	
	return PLUGIN_HANDLED_MAIN;
}
public cmdGrab(id)
{
	new iEnt, Body;
	
	g_flGrablength[id] = get_user_aiming(id, iEnt, Body);
	
	if( isNexus(iEnt) )
	{
		new iGrabber = entity_get_int(iEnt, EV_INT_iuser1);
		
		if( iGrabber == 0 || iGrabber == id )
		{
			new Float: flOrigin[3];
			new iAiming[3];
			
			entity_get_string(id, EV_SZ_viewmodel, g_szViewModel[id], 32);
			entity_set_string(id, EV_SZ_viewmodel, "");
			
			get_user_origin(id, iAiming, 3);
			entity_get_vector(iEnt, EV_VEC_origin, flOrigin);
			
			g_iGrabbed[id] = iEnt;
			g_flGrabOffset[id][0] = flOrigin[0] - iAiming[0];
			g_flGrabOffset[id][1] = flOrigin[1] - iAiming[1];
			g_flGrabOffset[id][2] = flOrigin[2] - iAiming[2];
			
			entity_set_int(iEnt, EV_INT_iuser1, id);
		}
	}
	return PLUGIN_HANDLED;
}
public cmdRelease(id)
{
	if( g_iGrabbed[id] )
	{
		if( isNexus(g_iGrabbed[id]))
		{
			if( isStuck(g_iGrabbed[id]) )
			{
				if( g_iGrabbed[id] == g_iNexus[TR] )
					g_iNexus[TR] = ZERO;
				
				else if( g_iGrabbed[id] == g_iNexus[CT] )
					g_iNexus[CT] = ZERO;
				
				remove_entity(g_iGrabbed[id]);
				
				PrintChat(id, "Nexus deleted because it was stuck.");
			}
			else
				entity_set_int(g_iGrabbed[id], EV_INT_iuser1, ZERO);
			
			entity_set_string(id, EV_SZ_viewmodel, g_szViewModel[id]);
			
			g_iGrabbed[id] = ZERO;
		}
	}
	return PLUGIN_HANDLED;
}
public EventNewRound( )
{
	for( new i = TR; i <= CT; i++ )
	{
		if( isNexus(g_iNexus[i]) )
		{
			if( g_iNexusDefeated == g_iNexus[i] )
			{
				entity_set_float(g_iNexus[i], EV_FL_takedamage, 1.0);
				
				entity_set_origin(g_iNexus[i], g_flDefeatedOrigins);
				
				g_iNexusDefeated = ZERO;
			}
			entity_set_float(g_iNexus[i], EV_FL_health, get_pcvar_float(nexus_health));
		}
	}
}
public EventDeathMsg( )
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	
	if( iKiller == iVictim || iKiller == 0 )
		return PLUGIN_CONTINUE;
	
	user[iKiller][KILLS]++;
	
	taskRevive(iVictim);
	
	set_task(5.0, "taskSpec", iVictim);
	
	FadeScreen(iVictim, 5.0, ZERO, ZERO, ZERO, 255);
	
	set_hudmessage(255, 255, 255, -1.0, -1.0, ZERO, 6.0, 5.0);
	show_hudmessage(iVictim, "AI MURIT^nAI FACUT %d KILL-URI", user[iVictim][KILLS]);
	
	return PLUGIN_CONTINUE;
}
public HamSpawn(id)
{
	set_view(id, CAMERA_NONE);
}
public HamKilled(iEnt)
{
	if( !isNexus(iEnt) )
		return HAM_IGNORED;
	
	if( !g_iNexusDefeated )
	{
		new Float: flOrigins[3];
		
		entity_get_vector(iEnt, EV_VEC_origin, flOrigins);
		
		g_iNexusDefeated = iEnt;
		g_flDefeatedOrigins[0] = flOrigins[0];
		g_flDefeatedOrigins[1] = flOrigins[1];
		g_flDefeatedOrigins[2] = flOrigins[2];
		
		entity_set_float(iEnt, EV_FL_takedamage, 0.0);
		
		emit_sound(iEnt, CHAN_VOICE, g_szNexusSound,  VOL_NORM, ATTN_NORM, ZERO, PITCH_NORM);
		
		if( g_iNexus[TR] == iEnt )
			PrintChat(0, "TR's Nexus was Defeated.");
		
		else if( g_iNexus[CT] == iEnt )
			PrintChat(0, "CT's Nexus was Defeated.");
		
		//Efect de explozie + mutare nexus in coltul mapei dupa treminarea exploziei
	}
	return HAM_SUPERCEDE;
}
public HamTakeDamage(id, inflictor, iAttacker, Float: damage, damagebits)
{
	if( !iAttacker || id == iAttacker || !is_user_connected(iAttacker) || !is_user_connected(id)
	|| get_user_team(id) == get_user_team(iAttacker) || is_user_inRecall(iAttacker)
	|| !CanAttack[iAttacker] || damagebits & DMG_GRENADE )
		return HAM_IGNORED;
	
	return HAM_IGNORED;
}
public HamObjectCaps(id)
{
	if( !is_user_alive(id) )
		return;
	
	if( get_user_button(id) & IN_USE )
	{
		static Float: gametime;
		gametime = get_gametime( );
		
		if( gametime - 1.0 > g_flCooldown[id] )
		{
			static iEnt, iBody;
			get_user_aiming(id, iEnt, iBody, 75);
			
			if( isNexus(iEnt) )
			{
				if( (iEnt == g_iNexus[TR] && cs_get_user_team(id) == CS_TEAM_T)
				|| (iEnt == g_iNexus[CT] && cs_get_user_team(id) == CS_TEAM_CT) )
					ShopMenu(id);
				
				else
				{
					new iHealth = pev(iEnt, pev_health);
					
					PrintChat(id, "Nexus Health: %d", iHealth);
				}
			}
			g_flCooldown[id] = gametime;
		}
	}
}
public FwdTouch(iEnt, id)
{
	static iEntClassname[32], idClassname[32], iTeam;
	
	pev(iEnt, pev_classname, iEntClassname, charsmax(iEntClassname));
	pev(id, pev_classname, idClassname, charsmax(idClassname));
	
	iTeam = get_user_team(id);
	
	if( equal(idClassname, g_szPlayerClassname) )
	{
		if( iEnt == g_iRecall[iTeam] )
		{
			static Float: flGameTime;
			
			flGameTime = get_gametime( );
			
			if( user_calldown[id][RECALL] + get_pcvar_float(recall_calldown) < flGameTime)
			{
				PrintChat(id, "REGENERARE");
				
				new iHealth = pev(id, pev_health);
				
				set_pev(id, pev_health, clamp(iHealth + get_pcvar_num(recall_regeneration), ZERO, MAX_HEALTH));
				
				user_calldown[id][RECALL] = flGameTime;
			}
		}
	}
}
public EntityMenu(id)
{
	if( g_iMenuOwner > ZERO && g_iMenuOwner != id )
	{
		PrintChat(id, "Cineva foloseste deja acest meniu");
		
		return PLUGIN_HANDLED;
	}
	new menu = menu_create("Main Menu", "EntityHandler");
	
	menu_additem(menu, "Nexus Menu",	"1");
	menu_additem(menu, "Recall Menu^n",	"2");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu);
	
	g_iMenuOwner = id;
	
	return PLUGIN_HANDLED;
}
public EntityHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		g_iMenuOwner = ZERO;
		
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	
	new iKey = str_to_num(info);
	
	switch( iKey )
	{
		case 1: NexusMenu(id);
		case 2: RecallMenu(id);
	}
}
public NexusMenu(id)
{
	new menu = menu_create("Nexus Menu", "NexusHandler");
	
	menu_additem(menu, "Create TR Nexus",	"1");
	menu_additem(menu, "Create CT Nexus^n",	"2");
	
	menu_additem(menu, "Delete TR Nexus",	"3");
	menu_additem(menu, "Delete CT Nexus^n",	"4");
	
	menu_additem(menu, "Drop to floor",	"5");
	menu_additem(menu, "Save all Nexus^n",	"6");
	
	menu_setprop(menu, MPROP_EXITNAME, "\yBack");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public NexusHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		EntityMenu(id);
		
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	
	new iKey = str_to_num(info);
	
	switch( iKey )
	{
		case 1, 2:
		{
			new iOrigin[3];
			new Float: flOrigin[3];
			
			get_user_origin(id, iOrigin, 3);
			IVecFVec(iOrigin, flOrigin);
			
			flOrigin[2] += g_flNexusMaxs[2];
			
			if( g_iNexus[iKey] != 0 )
			{
				PrintChat(id, "You cannot create two Nexus on the same team.");
				
				NexusMenu(id);
				
				return;
			}
			CreateNexus(iKey, flOrigin);
		}
		case 3, 4:
		{
			remove_entity(g_iNexus[iKey - 2]);
			g_iNexus[iKey - 2] = ZERO;
			
			PrintChat(0, "%s's Nexus was deleted.", iKey - 2 == TR ? "TR":"CT");
		}
		case 5:
		{
			new iEnt, iBody;
			get_user_aiming(id, iEnt, iBody);
			
			if( isNexus(iEnt) )
			{
				drop_to_floor(iEnt);
				
				PrintChat(0, "Nexus was dropped to floor.");
			}
		}
		case 6:
		{
			PrintChat(0, "All Nexus was succesfully saved.");
			
			SaveNexus( );
		}
	}
	NexusMenu(id);
}
public RecallMenu(id)
{
	new menu = menu_create("Recall Menu", "RecallHandler");
	
	menu_additem(menu, "Create TR Recall",	"1");
	menu_additem(menu, "Create CT Recall^n","2");
	
	menu_additem(menu, "Delete TR Recall",	"3");
	menu_additem(menu, "Delete CT Recall^n","4");
	
	menu_additem(menu, "Drop to floor",	"5");
	menu_additem(menu, "Save all Recall^n",	"6");
	
	menu_setprop(menu, MPROP_EXITNAME, "\yBack");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public RecallHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		EntityMenu(id);
		
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	
	new iKey = str_to_num(info);
	
	switch( iKey )
	{
		case 1, 2:
		{
			new iOrigin[3];
			new Float: flOrigin[3];
			
			get_user_origin(id, iOrigin, 3);
			IVecFVec(iOrigin, flOrigin);
			
			flOrigin[2] += g_flRecallMaxs[2];
			
			if( g_iRecall[iKey] != 0 )
			{
				PrintChat(id, "You cannot create two Recall on the same team.");
				
				RecallMenu(id);
				
				return;
			}
			CreateRecall(iKey, flOrigin);
		}
		case 3, 4:
		{
			remove_entity(g_iRecall[iKey - 2]);
			
			g_iRecall[iKey - 2] = ZERO;
			g_flRecallOrigins[iKey - 2][0] = 0.0;
			g_flRecallOrigins[iKey - 2][1] = 0.0;
			g_flRecallOrigins[iKey - 2][2] = 0.0;
			
			PrintChat(0, "%s's Recall was deleted.", iKey - 2 == TR ? "TR":"CT");
		}
		case 5:
		{
			new iEnt, iBody;
			get_user_aiming(id, iEnt, iBody);
			
			if( isRecall(iEnt) )
			{
				drop_to_floor(iEnt);
				
				PrintChat(0, "Recall was dropped to floor.");
			}
		}
		case 6:
		{
			PrintChat(0, "All Recall was succesfully saved.");
			
			SaveRecall( );
		}
	}
	RecallMenu(id);
}
public ShopMenu(id)
{
	new menu = menu_create("Shop Menu", "ShopHandler");
	
	menu_additem(menu, "Nuclear silo",	"1");
	menu_additem(menu, "Runes Shop",	"2");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public ShopHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	
	new iKey = str_to_num(info);
	
	switch( iKey )
	{
		case 1: PrintChat(id, "Nuclear silo");
		case 2: RunesMenu(id);
	}
}
public RunesMenu(id)
{
	new menu = menu_create("Runes Menu", "RunesHandler");
	new callback = menu_makecallback("RunesCallback");
	
	new szRuneName[51], szI[3];
	
	for( new i = SPEED; i <= RUNES; i++ )
	{
		formatex(szI, sizeof(szI) - 1, "%d", i);
		formatex(szRuneName, sizeof(szRuneName) - 1, "\w%s \r[\yLevel: \w%d\r]", g_szRunesName[i], user_Runes[id][i] + 1);
		
		menu_additem(menu, g_szRunesName[i], szI, _, callback);
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public RunesHandler(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
		
		return;
	}
	static  _access, info[4], callback;
	
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	
	new iKey = str_to_num(info);
	
	user_Runes[id][iKey]++;
}
public RunesCallback(id, menu, item)
{
	static _access, info[4], callback;
	menu_item_getinfo(menu, item, _access, info, sizeof(info) - 1, _, _, callback);
	
	new iKey = str_to_num(info);
	
	if( user_Runes[id][iKey] >= 2
	 || user[id][ZEN] < 100 )
		return ITEM_DISABLED;
		
	return ITEM_ENABLED;
}
CreateBarTime(id, iSeconds)  
{  
	message_begin(MSG_ONE_UNRELIABLE, g_iBarTime, .player=id);
	write_short(iSeconds);
	message_end( );
}
CreateNexus(const iNexusType, Float: flOrigin[3])
{
	new szName[32];
	
	switch( iNexusType )
	{
		case TR: copy(szName, sizeof(szName) - 1, TR_BOT);
		case CT: copy(szName, sizeof(szName) - 1, CT_BOT);
	}
	new iEnt = engfunc(EngFunc_CreateFakeClient, szName);
	
	if( !iEnt )
		return PLUGIN_HANDLED;
	
	engfunc(EngFunc_FreeEntPrivateData, iEnt);
	
	static szRejectReason[128];
	dllfunc(DLLFunc_ClientConnect, iEnt, szName, "127.0.0.1", szRejectReason);
	dllfunc(DLLFunc_ClientPutInServer, iEnt);
	
	set_pev(iEnt, pev_spawnflags, pev(iEnt, pev_spawnflags) | FL_FAKECLIENT);
	set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_FAKECLIENT);
	set_pev(iEnt, pev_solid, SOLID_NOT);
	
	new szTeam[32];
	num_to_str(iNexusType, szTeam, sizeof(szTeam) - 1);
	
	engclient_cmd(iEnt, "jointeam",  szTeam);
	engclient_cmd(iEnt, "joinclass", "1");
	
	ExecuteHamB(Ham_CS_RoundRespawn, iEnt);
	
	g_iNexus[iNexusType] = iEnt;
		
	entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NONE);
	entity_set_model(iEnt, g_szNexusModel);
	entity_set_vector(iEnt, EV_VEC_angles, g_flNexusAngles);
	entity_set_size(iEnt, g_flNexusMins, g_flNexusMaxs);
	entity_set_float(iEnt, EV_FL_takedamage, 1.0);
	entity_set_float(iEnt, EV_FL_health, get_pcvar_float(nexus_health));
	entity_set_origin(iEnt, flOrigin);
	
	/*message_begin(MSG_ALL, get_user_msgid("TeamInfo"), _, 0);
	write_byte(iEnt);
	write_string("TERRORIST");
	write_string("CT");
	message_end( );*/
	
	return PLUGIN_HANDLED;
}
CreateRecall(const iRecallType, Float: flOrigin[3])
{
	new iEnt = create_entity(g_szInfoTarget);
	
	if( is_valid_ent(iEnt) )
	{
		g_iRecall[iRecallType] = iEnt;
		
		g_flRecallOrigins[iRecallType][0] = flOrigin[0];
		g_flRecallOrigins[iRecallType][1] = flOrigin[1];
		g_flRecallOrigins[iRecallType][2] = flOrigin[2];
		
		entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
		entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_model(iEnt, g_szRecallModel);
		entity_set_vector(iEnt, EV_VEC_angles, g_flRecallAngles);
		entity_set_size(iEnt, g_flRecallMins, g_flRecallMaxs);
		entity_set_float(iEnt, EV_FL_takedamage, 0.0);
		entity_set_origin(iEnt, flOrigin);
	}
}
LoadNexus( )
{
	new szConfigDir[256], szFile[256], szNexusDir[256];
	
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szNexusDir, charsmax(szNexusDir),"%s/Nexus", szConfigDir);
	formatex(szFile, charsmax(szFile),  "%s/%s.cfg", szNexusDir, szMapName);
	
	if( !dir_exists(szNexusDir) )
		mkdir(szNexusDir);
	
	if( !file_exists(szFile) )
		write_file(szFile, "");
	
	new szFileOrigin[3][32];
	new szOrigin[128], szAngle[128];
	new Float: flOrigin[3], Float: flAngles[3];
	new iLine, iType, iLength, szBuffer[256];
	
	new const szTero[5] = "TR:";
	new const szCT[5] = "CT:";
	
	while( read_file(szFile, iLine++, szBuffer, charsmax(szBuffer), iLength) )
	{
		if( (szBuffer[0]== ';') || !iLength )
			continue;
		
		if( containi(szBuffer, szTero) != -1 )
		{
			replace(szBuffer, 255, szTero, "");
			iType = TR;
		}
		else if( containi(szBuffer, szCT) != -1 )
		{
			replace(szBuffer, 255, szCT, "");
			iType = CT;
		}
		trim(szBuffer);
		
		strtok(szBuffer, szOrigin, charsmax(szOrigin), szAngle, charsmax(szAngle), '|', ZERO);
		
		parse(szOrigin, szFileOrigin[0], charsmax(szFileOrigin[ ]), szFileOrigin[1], charsmax(szFileOrigin[ ]), szFileOrigin[2], charsmax(szFileOrigin[ ]));
		
		flOrigin[0] = str_to_float(szFileOrigin[0]);
		flOrigin[1] = str_to_float(szFileOrigin[1]);
		flOrigin[2] = str_to_float(szFileOrigin[2]);
		
		flAngles[1] = str_to_float(szAngle[1]);
		
		CreateNexus(iType, flOrigin);
	}
}
LoadRecall( )
{
	new szConfigDir[256], szFile[256], szRecallDir[256];
	
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szRecallDir, charsmax(szRecallDir),"%s/Recall", szConfigDir);
	formatex(szFile, charsmax(szFile),  "%s/%s.cfg", szRecallDir, szMapName);
	
	if( !dir_exists(szRecallDir) )
		mkdir(szRecallDir);
	
	if( !file_exists(szFile) )
		write_file(szFile, "");
	
	new szFileOrigin[3][32];
	new szOrigin[128], szAngle[128];
	new Float: flOrigin[3], Float: flAngles[3];
	new iLine, iType, iLength, szBuffer[256];
	
	new const szTero[5] = "TR:";
	new const szCT[5] = "CT:";
	
	while( read_file(szFile, iLine++, szBuffer, charsmax(szBuffer), iLength) )
	{
		if( (szBuffer[0]== ';') || !iLength )
			continue;
		
		if( containi(szBuffer, szTero) != -1 )
		{
			replace(szBuffer, 255, szTero, "");
			iType = TR;
		}
		else if( containi(szBuffer, szCT) != -1 )
		{
			replace(szBuffer, 255, szCT, "");
			iType = CT;
		}
		trim(szBuffer);
		
		strtok(szBuffer, szOrigin, charsmax(szOrigin), szAngle, charsmax(szAngle), '|', ZERO);
		
		parse(szOrigin, szFileOrigin[0], charsmax(szFileOrigin[ ]), szFileOrigin[1], charsmax(szFileOrigin[ ]), szFileOrigin[2], charsmax(szFileOrigin[ ]));
		
		flOrigin[0] = str_to_float(szFileOrigin[0]);
		flOrigin[1] = str_to_float(szFileOrigin[1]);
		flOrigin[2] = str_to_float(szFileOrigin[2]);
		
		flAngles[1] = str_to_float(szAngle[1]);
		
		CreateRecall(iType, flOrigin);
	}
}
SaveNexus( )
{
	new szConfigsDir[256], szFile[256], szNexusDir[256];
	
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szNexusDir, charsmax(szNexusDir), "%s/Nexus", szConfigsDir);
	formatex(szFile, charsmax(szFile), "%s/%s.cfg", szNexusDir, szMapName);
	
	if( file_exists(szFile) )
		delete_file(szFile);
	
	new Float: flEntOrigin[3], Float: flEntAngles[3];
	new szBuffer[256];
	
	for( new i = TR; i <= CT; i++ )
	{
		if( isNexus(g_iNexus[i]) )
		{
			entity_get_vector(g_iNexus[i], EV_VEC_origin, flEntOrigin);
			entity_get_vector(g_iNexus[i], EV_VEC_angles, flEntAngles);
			
			if( i == TR )
				formatex(szBuffer, charsmax(szBuffer), "TR: %d %d %d | %d", floatround(flEntOrigin[0]), floatround(flEntOrigin[1]), floatround(flEntOrigin[2]), floatround(flEntAngles[1]));
			
			else if( i == CT )
				formatex(szBuffer, charsmax(szBuffer), "CT: %d %d %d | %d", floatround(flEntOrigin[0]), floatround(flEntOrigin[1]), floatround(flEntOrigin[2]), floatround(flEntAngles[1]));
			
			write_file(szFile, szBuffer, -1);
		}
	}
}
SaveRecall( )
{
	new szConfigsDir[256], szFile[256], szRecallDir[256];
	
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szRecallDir, charsmax(szRecallDir), "%s/Recall", szConfigsDir);
	formatex(szFile, charsmax(szFile), "%s/%s.cfg", szRecallDir, szMapName);
	
	if( file_exists(szFile) )
		delete_file(szFile);
	
	new Float: flEntOrigin[3], Float: flEntAngles[3];
	new szBuffer[256];
	
	for( new i = TR; i <= CT; i++ )
	{
		if( isRecall(g_iRecall[i]) )
		{
			entity_get_vector(g_iRecall[i], EV_VEC_origin, flEntOrigin);
			entity_get_vector(g_iRecall[i], EV_VEC_angles, flEntAngles);
			
			if( i == TR )
				formatex(szBuffer, charsmax(szBuffer), "TR: %d %d %d | %d", floatround(flEntOrigin[0]), floatround(flEntOrigin[1]), floatround(flEntOrigin[2]), floatround(flEntAngles[1]));
			
			else if( i == CT )
				formatex(szBuffer, charsmax(szBuffer), "CT: %d %d %d | %d", floatround(flEntOrigin[0]), floatround(flEntOrigin[1]), floatround(flEntOrigin[2]), floatround(flEntAngles[1]));
			
			write_file(szFile, szBuffer, -1);
		}
	}
}
MoveGrabbedEnt(id, Float: vMoveTo[3] = {0.0, 0.0, 0.0})
{
	new iOrigin[3], iLook[3];
	new Float: flOrigin[3], Float: flLook[3], Float: flDirection[3], Float: flLength;
	
	get_user_origin(id, iOrigin, 1);
	get_user_origin(id, iLook, 3);
	IVecFVec(iOrigin, flOrigin);
	IVecFVec(iLook, flLook);
	
	flDirection[0] = flLook[0] - flOrigin[0];
	flDirection[1] = flLook[1] - flOrigin[1];
	flDirection[2] = flLook[2] - flOrigin[2];
	flLength = get_distance_f(flLook, flOrigin);
	
	if( flLength == 0.0 ) flLength = 1.0;
	
	vMoveTo[0] = (flOrigin[0] + flDirection[0] * g_flGrablength[id] / flLength) + g_flGrabOffset[id][0];
	vMoveTo[1] = (flOrigin[1] + flDirection[1] * g_flGrablength[id] / flLength) + g_flGrabOffset[id][1];
	vMoveTo[2] = (flOrigin[2] + flDirection[2] * g_flGrablength[id] / flLength) + g_flGrabOffset[id][2];
	vMoveTo[2] = float(floatround(vMoveTo[2], floatround_floor));
	
	entity_set_origin(g_iGrabbed[id], vMoveTo);
}
public FadeScreen(id, const Float: seconds, const red, const green, const blue, const alpha)
{      
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
	write_short(floatround(4096.0 * seconds, floatround_round));
	write_short(floatround(4096.0 * seconds, floatround_round));
	write_short(0x0000);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end( );
}
PrintChat(id, const szMessage[ ], {Float, Sql, Result, _}:...)
{
	if( get_playersnum( ) < 1)
		return;
	
	new message[256];
	
	message[0] = 0x04;
	
	format(message, sizeof(message) - 1, "%s[Defeat]^1 ", message);
	
	vformat(message[11], 251, szMessage, 3);
	
	message[192] = '^0';
	
	replace_all(message, 191, "\YEL", "^1");
	replace_all(message, 191, "\GRN", "^4");
	replace_all(message, 191, "\TEM", "^3");
	
	new iTeam, ColorChange, index, MSG_Type;
	
	if( id )
	{
		index = id;
		MSG_Type = MSG_ONE_UNRELIABLE;
	}
	else
	{
		index = CC_FindPlayer( );
		MSG_Type = MSG_BROADCAST;
	}
	iTeam = get_user_team(index);
	new Color: type = NORMAL;
	
	ColorChange = CC_ColorSelection(index, MSG_Type, type);
	
	CC_ShowColorMessage(index, MSG_Type, message);
	
	if( ColorChange )
		CC_Team_Info(index, MSG_Type, TeamName[iTeam]);
}
CC_ShowColorMessage(id, type, message[ ])
{
	message_begin(type, g_iMsgSayText, _, id);
	write_byte(id);	
	write_string(message);
	message_end( );	
}
CC_Team_Info(id, type, team[ ])
{
	message_begin(type, g_iMsgTeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end( );
	
	return 1;
}
CC_ColorSelection(index, type, Color: Type)
{
	switch( Type )
	{
		case RED:  return CC_Team_Info(index, type, TeamName[1]);
		case BLUE: return CC_Team_Info(index, type, TeamName[2]);
	}
	return 0;
}
CC_FindPlayer( )
{
	for( new i = 1; i <= g_iMaxPlayers; i++ )
		if( is_user_connected(i) )
			return i;
		
	return -1;
}
public taskSpec(id)
{
	set_view(id, CAMERA_3RDPERSON);
	
	FadeScreen(id, 15.0, 255, 255, 255, 50);
}
public taskRevive(id)
{
	static iCount[33];
	
	if( g_iNexusDefeated )
	{
		iCount[id] = ZERO;
		
		return PLUGIN_HANDLED;
	}
	if( iCount[id] == ZERO )
	{
		iCount[id] = 31;
		set_task(1.0, "taskRevive", id);
	}
	else if( iCount[id] == 1 )
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
		iCount[id] = ZERO;
	}
	else
	{
		PrintChat(id, "Vei reveni la viata in %d secunde.", iCount[id]);
		
		iCount[id]--;
		
		set_task(1.0, "taskRevive", id);
	}
	return PLUGIN_HANDLED;
}
public taskRecall(id)
{
	id -= TASK_RECALL;
	
	static iRecall[33];
	static Float: flOrigins[33][3];
	
	if( g_iNexusDefeated )
	{
		iRecall[id] = ZERO;
		CanAttack[id] = true;
		
		CreateBarTime(id + TASK_RECALL, ZERO);
		
		return PLUGIN_HANDLED;
	}
	if( iRecall[id] == ZERO )
	{
		iRecall[id] = get_pcvar_num(recall_time);
		
		pev(id, pev_origin, flOrigins[id]);
		
		CanAttack[id] = false;
		
		set_task(1.0, "taskRecall", id);
		
		return PLUGIN_HANDLED;
	}
	else if( iRecall[id] == 1 )
	{
		new iTeam = get_user_team(id);
		
		flOrigins[id][0] = g_flRecallOrigins[iTeam][0];
		flOrigins[id][1] = g_flRecallOrigins[iTeam][1];
		flOrigins[id][2] = g_flRecallOrigins[iTeam][2] + g_flRecallMaxs[2] + 36.0;
		
		entity_set_origin(id, flOrigins[id]);
		
		iRecall[id] = ZERO;
		CanAttack[id] = true;
		
		return PLUGIN_HANDLED;
	}
	else
	{
		new Float: cflOrigins[3];
		pev(id, pev_origin, cflOrigins);
		
		if( flOrigins[id][0] == cflOrigins[0]
		&& flOrigins[id][1] == cflOrigins[1]
		&& flOrigins[id][2] == cflOrigins[2] )
		{
			iRecall[id]--;
			
			set_task(1.0, "taskRecall", id + TASK_RECALL);
			
			return PLUGIN_HANDLED;
		}
		else
		{
			iRecall[id] = ZERO;
			CanAttack[id] = true;
			
			CreateBarTime(id + TASK_RECALL, ZERO);
			
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}
stock is_user_inRecall(id)
{
	new Float: flOrigins[3];
	pev(id, pev_origin, flOrigins);
	
	new iTeam = get_user_team(id);
	
	if( g_flRecallOrigins[iTeam][0] + g_flRecallMins[0] < flOrigins[0]
	&& g_flRecallOrigins[iTeam][1] + g_flRecallMins[1] < flOrigins[1]
	&& g_flRecallOrigins[iTeam][2] + g_flRecallMins[2] < flOrigins[2]
	&& g_flRecallOrigins[iTeam][0] + g_flRecallMaxs[0] > flOrigins[0]
	&& g_flRecallOrigins[iTeam][1] + g_flRecallMaxs[1] > flOrigins[1]
	&& g_flRecallOrigins[iTeam][2] + g_flRecallMaxs[2] > flOrigins[2] )
		return true;

	return false;
}
bool: isNexus(iEnt)
{
	if( is_valid_ent(iEnt) )
	{
		if( iEnt == g_iNexus[TR]
		 || iEnt == g_iNexus[CT] )
			return true;
	}
	return false;
}
bool: isRecall(iEnt)
{
	if( is_valid_ent(iEnt) )
	{
		if( iEnt == g_iRecall[TR]
		 || iEnt == g_iRecall[CT] )
			return true;
	}
	return false;
}
bool: isStuck(iEnt)
{
	if( is_valid_ent(iEnt) )
	{
		new content;
		new Float: vOrigin[3];
		new Float: vPoint[3];
		new Float: flSizeMin[3];
		new Float: flSizeMax[3];
		
		entity_get_vector(iEnt, EV_VEC_mins, flSizeMin);
		entity_get_vector(iEnt, EV_VEC_maxs, flSizeMax);
		entity_get_vector(iEnt, EV_VEC_origin, vOrigin);
		
		flSizeMin[0] += 1.0;
		flSizeMax[0] -= 1.0;
		flSizeMin[1] += 1.0;
		flSizeMax[1] -= 1.0; 
		flSizeMin[2] += 1.0;
		flSizeMax[2] -= 1.0;
		
		for( new i = 0; i < 14; ++i )
		{
			vPoint = vOrigin;
			
			switch( i )
			{
				case 0: { vPoint[0] += flSizeMax[0]; vPoint[1] += flSizeMax[1]; vPoint[2] += flSizeMax[2]; }
				case 1: { vPoint[0] += flSizeMin[0]; vPoint[1] += flSizeMax[1]; vPoint[2] += flSizeMax[2]; }
				case 2: { vPoint[0] += flSizeMax[0]; vPoint[1] += flSizeMin[1]; vPoint[2] += flSizeMax[2]; }
				case 3: { vPoint[0] += flSizeMin[0]; vPoint[1] += flSizeMin[1]; vPoint[2] += flSizeMax[2]; }
				case 4: { vPoint[0] += flSizeMax[0]; vPoint[1] += flSizeMax[1]; vPoint[2] += flSizeMin[2]; }
				case 5: { vPoint[0] += flSizeMin[0]; vPoint[1] += flSizeMax[1]; vPoint[2] += flSizeMin[2]; }
				case 6: { vPoint[0] += flSizeMax[0]; vPoint[1] += flSizeMin[1]; vPoint[2] += flSizeMin[2]; }
				case 7: { vPoint[0] += flSizeMin[0]; vPoint[1] += flSizeMin[1]; vPoint[2] += flSizeMin[2]; }
				
				case 8: { vPoint[0] += flSizeMax[0]; }
				case 9: { vPoint[0] += flSizeMin[0]; }
				case 10: { vPoint[1] += flSizeMax[1]; }
				case 11: { vPoint[1] += flSizeMin[1]; }
				case 12: { vPoint[2] += flSizeMax[2]; }
				case 13: { vPoint[2] += flSizeMin[2]; }
			}
			content = point_contents(vPoint);
			
			if( content == CONTENTS_EMPTY || content == 0 )
				return false;
		}
	}
	else
		return false;

	return true;
}
