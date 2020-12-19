#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <ColorChat>

#pragma semicolon 1

#define Tero 1
#define CT 2

static const PLUGIN[ ]		= "Nexus";
static const VERSION[ ]		= "1.0";
static const AUTHOR[ ]		= "Rappy O.o-";

new const g_Nexus_T[ ]		= "Nexus_T"; 
new const g_Nexus_CT[ ]		= "Nexus_CT"; 
new const g_NexusModel[ ]	= "models/aura.mdl"; 

new const g_NexusDeath[ ][ ] =
{ 
	"barney/ba_die1.wav", 
	"barney/ba_die2.wav", 
	"barney/ba_die3.wav" 
};
new bool: g_Hit[32];
new bool: MenuON[33];
new bool: g_NexusSpawn[256]; 
new bool: g_NexusDead[256]; 

new spr_blood_drop;
new spr_blood_spray;
new g_Grabbed[33];
new g_ViewModel[33];

new Float: g_Cooldown[32];
new Float: g_fGrablength[33];
new Float: g_fSnappingGap[33];
new Float: g_fGrabOffset[33][3];
const Float: g_fSnapDistance = 10.0;

new nexus_health;


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /nexus",	"cmdNexus");
	register_clcmd("+grab",		"cmdGrab");
	register_clcmd("-grab",		"cmdRelease");
	
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
		
	RegisterHam(Ham_TakeDamage,	"info_target",	"HamTakeDamage");
	RegisterHam(Ham_Killed,		"info_target",	"HamKilled");
	RegisterHam(Ham_Think,		"info_target",	"HamThink");
	RegisterHam(Ham_TraceAttack,	"info_target",	"HamTraceAttack");
	RegisterHam(Ham_ObjectCaps,	"player",	"HamObjectCaps", 1);
	
	nexus_health = register_cvar("defeat_nexus_health", "10000");
	
	EventNewRound( );
}
public plugin_precache( )
{
	spr_blood_drop = precache_model("sprites/blood.spr");
	spr_blood_spray = precache_model("sprites/bloodspray.spr");
		
	for( new i = 0; i < sizeof(g_NexusDeath); i++ )
		precache_sound(g_NexusDeath[i]);

	precache_model(g_NexusModel);
}
public plugin_cfg( )
{
	LoadNexus( );
}
public client_putinserver(id)
{
	MenuON[id] = false;
}
public client_disconnect(id)
{
	if( g_Grabbed[id] )
	{
		if( is_valid_ent(g_Grabbed[id]) )
		{
			entity_set_int(g_Grabbed[id], EV_INT_iuser1, 0);
		}
		g_Grabbed[id] = 0;
	}
}
public cmdGrab(id)
{
	//if( !MenuON[id] )
		//return PLUGIN_CONTINUE;
	
	new iEnt, body;
	new bool: bIsNexus = isNexus(iEnt);
	
	g_fGrablength[id] = get_user_aiming(id, iEnt, body);
	
	new iGrabber = entity_get_int(iEnt, EV_INT_iuser1);
	
	if( (iGrabber == 0 || iGrabber == id) && bIsNexus )
	{
		new Float: fpOrigin[3];
		new Float: fbOrigin[3];
		new Float: fAiming[3];
		new iAiming[3];
		new bOrigin[3];
		
		entity_get_string(id, EV_SZ_viewmodel, g_ViewModel[id], 32);
		entity_set_string(id, EV_SZ_viewmodel, "");
		
		get_user_origin(id, bOrigin, 1);
		get_user_origin(id, iAiming, 3);
		entity_get_vector(id, EV_VEC_origin, fpOrigin);
		entity_get_vector(iEnt, EV_VEC_origin, fbOrigin);
		IVecFVec(iAiming, fAiming);
		FVecIVec(fbOrigin, bOrigin);
		
		g_Grabbed[id] = iEnt;
		g_fGrabOffset[id][0] = fbOrigin[0] - iAiming[0];
		g_fGrabOffset[id][1] = fbOrigin[1] - iAiming[1];
		g_fGrabOffset[id][2] = fbOrigin[2] - iAiming[2];
		
		entity_set_int(iEnt, EV_INT_iuser1, id);
	}
	return PLUGIN_HANDLED;
}
public cmdRelease(id)
{
	//if( !MenuON[id] )
		//return PLUGIN_CONTINUE;
	
	if( isNexus(g_Grabbed[id]) )
	{
		if( isStuck(g_Grabbed[id]) )
		{
			remove_entity(g_Grabbed[id]);
		}
		else
		{
			entity_set_int(g_Grabbed[id], EV_INT_iuser1, 0);
		}
		entity_set_string(id, EV_SZ_viewmodel, g_ViewModel[id]);
			
		g_Grabbed[id] = 0;
	}
	return PLUGIN_HANDLED;
}
public cmdAttack(id)
{
	if( g_fGrablength[id] > 72.0 )
	{
		g_fGrablength[id] -= 16.0;
	}
}
public cmdAttack2(id)
{
	g_fGrablength[id] += 16.0;
}
/*public client_PreThink(id)
{
	new buttons = get_user_button(id);
	new oldbuttons = get_user_oldbutton(id);
	
	if( g_Grabbed[id] > 0 )
	{
		if( buttons & IN_ATTACK && !(oldbuttons & IN_ATTACK) ) cmdAttack(id);
		if( buttons & IN_ATTACK2 && !(oldbuttons & IN_ATTACK2) ) cmdAttack2(id);
		
		buttons &= ~IN_ATTACK;
		entity_set_int(id, EV_INT_button, buttons);
			
		if( is_valid_ent(g_Grabbed[id]) )
		{
			new iOrigin[3], iLook[3];
			new Float: fOrigin[3], Float: fLook[3], Float: fDirection[3], Float: fLength;
			
			get_user_origin(id, iOrigin, 1);
			get_user_origin(id, iLook, 3);
			IVecFVec(iOrigin, fOrigin);
			IVecFVec(iLook, fLook);
			
			fDirection[0] = fLook[0] - fOrigin[0];
			fDirection[1] = fLook[1] - fOrigin[1];
			fDirection[2] = fLook[2] - fOrigin[2];
			fLength = get_distance_f(fLook, fOrigin);
			
			if( fLength == 0.0 ) fLength = 1.0;
			
			new Float: vMoveTo[3] = {0.0, 0.0, 0.0};
			
			vMoveTo[0] = (fOrigin[0] + fDirection[0] * g_fGrablength[id] / fLength) + g_fGrabOffset[id][0];
			vMoveTo[1] = (fOrigin[1] + fDirection[1] * g_fGrablength[id] / fLength) + g_fGrabOffset[id][1];
			vMoveTo[2] = (fOrigin[2] + fDirection[2] * g_fGrablength[id] / fLength) + g_fGrabOffset[id][2];
			vMoveTo[2] = float(floatround(vMoveTo[2], floatround_floor));
			
			entity_set_origin(g_Grabbed[id], vMoveTo);
			
			new Float: fSnapSize = g_fSnapDistance + g_fSnappingGap[id];
			new Float: vReturn[3];
			new Float: dist;
			new Float: distOld = 9999.9;
			new Float: vTraceStart[3];
			new Float: vTraceEnd[3];
			new tr;
			new trClosest = 0;
			new blockFace;
			
			new Float: fSizeMin[3];
			new Float: fSizeMax[3];
			entity_get_vector(g_Grabbed[id], EV_VEC_mins, fSizeMin);
			entity_get_vector(g_Grabbed[id], EV_VEC_maxs, fSizeMax);
			
			for( new i = 0; i < 6; ++i )
			{
				vTraceStart = vMoveTo;
				
				switch( i )
				{
					case 0: vTraceStart[0] += fSizeMin[0];
					case 1: vTraceStart[0] += fSizeMax[0];
					case 2: vTraceStart[1] += fSizeMin[1];
					case 3: vTraceStart[1] += fSizeMax[1];
					case 4: vTraceStart[2] += fSizeMin[2];
					case 5: vTraceStart[2] += fSizeMax[2];
				}
				vTraceEnd = vTraceStart;
				
				switch( i )
				{
					case 0: vTraceEnd[0] -= fSnapSize;
					case 1: vTraceEnd[0] += fSnapSize;
					case 2: vTraceEnd[1] -= fSnapSize;
					case 3: vTraceEnd[1] += fSnapSize;
					case 4: vTraceEnd[2] -= fSnapSize;
					case 5: vTraceEnd[2] += fSnapSize;
				}
				tr = trace_line(g_Grabbed[id], vTraceStart, vTraceEnd, vReturn);
				
				if( isNexus(tr) )
				{
					dist = get_distance_f(vTraceStart, vReturn);
					
					if( dist < distOld )
					{
						trClosest = tr;
						distOld = dist;
						
						blockFace = i;
					}
				}
			}
			if( is_valid_ent(trClosest) )
			{
				new Float: vOrigin[3];
				entity_get_vector(trClosest, EV_VEC_origin, vOrigin);
				
				new Float: fTrSizeMin[3];
				new Float: fTrSizeMax[3];
				entity_get_vector(trClosest, EV_VEC_mins, fTrSizeMin);
				entity_get_vector(trClosest, EV_VEC_maxs, fTrSizeMax);
				
				vMoveTo = vOrigin;
				
				if( blockFace == 0 ) vMoveTo[0] += (fTrSizeMax[0] + fSizeMax[0]) + g_fSnappingGap[id];
				if( blockFace == 1 ) vMoveTo[0] += (fTrSizeMin[0] + fSizeMin[0]) - g_fSnappingGap[id];
				if( blockFace == 2 ) vMoveTo[1] += (fTrSizeMax[1] + fSizeMax[1]) + g_fSnappingGap[id];
				if( blockFace == 3 ) vMoveTo[1] += (fTrSizeMin[1] + fSizeMin[1]) - g_fSnappingGap[id];
				if( blockFace == 4 ) vMoveTo[2] += (fTrSizeMax[2] + fSizeMax[2]) + g_fSnappingGap[id];
				if( blockFace == 5 ) vMoveTo[2] += (fTrSizeMin[2] + fSizeMin[2]) - g_fSnappingGap[id];
			}
			else
			{
				cmdRelease(id);
			}
		}
	}
}*/
public cmdNexus(id)
{
	new menu = menu_create("Nexus Menu", "Menu_Handler");
		
	menu_additem(menu, "Create Nexus Tero", "1");
	menu_additem(menu, "Create Nexus CT^n", "2");
	
	menu_additem(menu, "Drop to floor", "3");
	menu_additem(menu, "Save all Nexus^n", "4");
		
	menu_additem(menu, "Delete Nexus", "5");
	menu_additem(menu, "Delete all Nexus", "6");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu);
	
	MenuON[id] = true;
}
public Menu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		MenuON[id] = false;
		
		return PLUGIN_HANDLED;
	}
	new info[6], szName[64];
	new _access, callback;
	
	menu_item_getinfo(menu, item, _access, info, charsmax(info), szName, charsmax(szName), callback);
	
	new key = str_to_num(info);
	
	switch(key)
	{
		case 1:
		{
			CreateNexus(id, Tero);
		}
		case 2:
		{
			CreateNexus(id, CT);
		}
		case 3:
		{
			new iEnt, iBody;
			get_user_aiming(id, iEnt, iBody);
			
			if( isNexus(iEnt) )
			{
				drop_to_floor(iEnt);
			}
		}
		case 4:
		{
			SaveNexus( );
			
			ColorChat(id, RED, "^x04[Defeat]^x01 All^x03 Nexus^x01 are now saved.");
		}
		case 5:
		{
			new iEnt, iBody;
			get_user_aiming(id, iEnt, iBody);
			
			if( isNexus(iEnt) )
			{
				remove_entity(iEnt);
			}
		}
		case 6:
		{
			remove_entity_name(g_Nexus_T);
			remove_entity_name(g_Nexus_CT);
			
			ColorChat(id, RED, "^x04[Defeat]^x01 All^x03 Nexus^x01 are now deleted.");
		}
	}
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}
public HamTakeDamage(iEnt, Inflictor, Attacker, Float: Damage, Bits)
{
	if( !isNexus(iEnt) )
		return;
	
	g_Hit[Attacker] = true;
}
public HamKilled(iEnt)
{
	if( !isNexus(iEnt) )
		return HAM_IGNORED;
		
	entity_set_int(iEnt, EV_INT_solid, SOLID_NOT);
	
	emit_sound(iEnt, CHAN_VOICE, g_NexusDeath[random(sizeof g_NexusDeath)],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	entity_set_float(iEnt, EV_FL_takedamage, 0.0);
	
	g_NexusDead[iEnt] = true;
	
	return HAM_SUPERCEDE;
}
public HamThink(iEnt)
{
	if( !is_valid_ent(iEnt) )
		return;
	
	if( !isNexus(iEnt) )
		return;
	
	if( g_NexusDead[iEnt] )
	{
		return;
	}
	if( g_NexusSpawn[iEnt] )
	{
		static Float: mins[3], Float: maxs[3];
		pev(iEnt, pev_absmin, mins);
		pev(iEnt, pev_absmax, maxs);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BOX);
		engfunc(EngFunc_WriteCoord, mins[0]);
		engfunc(EngFunc_WriteCoord, mins[1]);
		engfunc(EngFunc_WriteCoord, mins[2]);
		engfunc(EngFunc_WriteCoord, maxs[0]);
		engfunc(EngFunc_WriteCoord, maxs[1]);
		engfunc(EngFunc_WriteCoord, maxs[2]);
		write_short(100);
		write_byte(random_num(25, 255));
		write_byte(random_num(25, 255));
		write_byte(random_num(25, 255));
		message_end( );
		
		g_NexusSpawn[iEnt] = false;
	}
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime( ) + random_float(5.0, 10.0));
}
public HamTraceAttack(iEnt, Attacker, Float: Damage, Float: Direction[3], Trace, DamageBits)
{
	if( !is_valid_ent(iEnt) )
		return;
	
	if( !isNexus(iEnt) )
		return;
	
	new Float: end[3];
	get_tr2(Trace, TR_vecEndPos, end);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, end[0]);
	engfunc(EngFunc_WriteCoord, end[1]);
	engfunc(EngFunc_WriteCoord, end[2]);
	write_short(spr_blood_spray);
	write_short(spr_blood_drop);
	write_byte(247);
	write_byte(random_num(1, 5));
	message_end( );
}
public HamObjectCaps(id)
{
	if( !is_user_alive(id) )
		return;

	if( get_user_button(id) & IN_USE )
	{
		static Float: gametime; gametime = get_gametime( );
		if( gametime - 1.0 > g_Cooldown[id] )
		{
			static iEnt, iBody;
			get_user_aiming(id, iEnt, iBody, 75);
			
			if( isNexus(iEnt) )
			{
				new iEntCN[32];
				entity_get_string(iEnt, EV_SZ_classname, iEntCN, charsmax(iEntCN));
				
				if( (equali(iEntCN, g_Nexus_T) && get_user_team(id) == 1)
				|| (equali(iEntCN, g_Nexus_CT) && get_user_team(id) == 2) )
				{
					client_print(id, print_chat, "Aceeasi echipa");
				}
				else
				{
					client_print(id, print_chat, "Echipa diferita");
				}
			}
			g_Cooldown[id] = gametime;
		}
	}
}
public EventNewRound( )
{
	new iEnt = -1;
	
	while( (iEnt = find_ent_by_class(iEnt, g_Nexus_T)) )
	{
		if( g_NexusDead[iEnt] )
		{
			entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
			entity_set_float(iEnt, EV_FL_takedamage, 1.0);
			entity_set_float(iEnt, EV_FL_nextthink, get_gametime( ) + 0.01);
			
			g_NexusDead[iEnt] = false;
		}	
		entity_set_float(iEnt, EV_FL_health, float(get_pcvar_num(nexus_health)));
	}
	iEnt = -1;
	
	while( (iEnt = find_ent_by_class(iEnt, g_Nexus_CT)) )
	{
		if( g_NexusDead[iEnt] )
		{
			entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
			entity_set_float(iEnt, EV_FL_takedamage, 1.0);
			entity_set_float(iEnt, EV_FL_nextthink, get_gametime( ) + 0.01);
			
			g_NexusDead[iEnt] = false;
		}	
		entity_set_float(iEnt, EV_FL_health, float(get_pcvar_num(nexus_health)));
	}
}
CreateNexus(id, iTeam, Float: flOrigin[3] = { 0.0, 0.0, 0.0 }, Float: flAngle[3] = { 0.0, 0.0, 0.0 })
{
	new iEnt = create_entity("info_target");
	
	switch( iTeam )
	{
		case Tero:
		{
			entity_set_string(iEnt, EV_SZ_classname, g_Nexus_T);
			set_rendering(iEnt, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 30);
		}
		case CT:
		{
			entity_set_string(iEnt, EV_SZ_classname, g_Nexus_CT);
			set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 30);
		}
	}
	if( id )
	{
		entity_get_vector(id, EV_VEC_origin, flOrigin);
		entity_set_origin(iEnt, flOrigin);
		flOrigin[2] += 80.0;
		entity_set_origin(id, flOrigin);
		entity_get_vector(id, EV_VEC_angles, flAngle);
		flAngle[0] = 0.0;
		entity_set_vector(iEnt, EV_VEC_angles, flAngle);
	}
	else 
	{
		entity_set_origin(iEnt, flOrigin);
		entity_set_vector(iEnt, EV_VEC_angles, flAngle);
	}
	entity_set_float(iEnt, EV_FL_takedamage, 1.0);
	entity_set_float(iEnt, EV_FL_health, float(get_pcvar_num(nexus_health)));
	
	entity_set_model(iEnt, g_NexusModel);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_NONE);
	entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
	
	
	new Float: fMins[3] = {-12.0, -12.0, 0.0 };
	new Float: fMaxs[3] = { 12.0, 12.0, 75.0 };

	entity_set_size(iEnt, fMins, fMaxs);
	entity_set_byte(iEnt, EV_BYTE_controller1, 125);
	drop_to_floor(iEnt);
	
	g_NexusSpawn[iEnt] = true;
	g_NexusDead[iEnt] = false;
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime( ) + 0.01);
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
	{
		mkdir(szNexusDir);
	}
	if( !file_exists(szFile) )
	{
		write_file(szFile, "");
	}
	new szFileOrigin[3][32];
	new szOrigin[128], szAngle[128];
	new Float: fOrigin[3], Float: fAngles[3];
	new iLine, iLength, szBuffer[256];
	
	while( read_file(szFile, iLine++, szBuffer, charsmax(szBuffer), iLength) )
	{
		if( (szBuffer[0]== ';') || !iLength )
			continue;
		
		new const szTero[11] = "Tero -";
		new const szCT[11] = "CT -";
		new iTeam;
		
		if( containi(szBuffer, szTero) != -1 )
		{
			replace(szBuffer, 255, szTero, "");
			iTeam = 1;
		}
		else if( containi(szBuffer, szCT) != -1 )
		{
			replace(szBuffer, 255, szCT, "");
			iTeam = 2;
		}
		trim(szBuffer);
		
		strtok(szBuffer, szOrigin, charsmax(szOrigin), szAngle, charsmax(szAngle), '|', 0);
			
		parse(szOrigin, szFileOrigin[0], charsmax(szFileOrigin[ ]), szFileOrigin[1], charsmax(szFileOrigin[ ]), szFileOrigin[2], charsmax(szFileOrigin[ ]));
		
		fOrigin[0] = str_to_float(szFileOrigin[0]);
		fOrigin[1] = str_to_float(szFileOrigin[1]);
		fOrigin[2] = str_to_float(szFileOrigin[2]);
		
		fAngles[1] = str_to_float(szAngle[1]);
		
		CreateNexus(0, iTeam, fOrigin, fAngles);
	}
}
SaveNexus( )
{
	new szConfigsDir[256], szFile[256], szNexusDir[256];
	
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szNexusDir, charsmax(szNexusDir),"%s/Nexus", szConfigsDir);
	formatex(szFile, charsmax(szFile), "%s/%s.cfg", szNexusDir, szMapName);
		
	if( file_exists(szFile) )
		delete_file(szFile);
	
	new Float:fEntOrigin[3], Float:fEntAngles[3];
	new szBuffer[256];
	new iEnt = -1;
	
	while( (iEnt = find_ent_by_class(iEnt, g_Nexus_T)) )
	{
		entity_get_vector(iEnt, EV_VEC_origin, fEntOrigin);
		entity_get_vector(iEnt, EV_VEC_angles, fEntAngles);
		
		formatex(szBuffer, charsmax(szBuffer), "Tero - %d %d %d | %d", floatround(fEntOrigin[0]), floatround(fEntOrigin[1]), floatround(fEntOrigin[2]), floatround(fEntAngles[1]));
		
		write_file(szFile, szBuffer, -1);
	}
	iEnt = -1;
	
	while( (iEnt = find_ent_by_class(iEnt, g_Nexus_CT)) )
	{
		entity_get_vector(iEnt, EV_VEC_origin, fEntOrigin);
		entity_get_vector(iEnt, EV_VEC_angles, fEntAngles);
		
		formatex(szBuffer, charsmax(szBuffer), "CT - %d %d %d | %d", floatround(fEntOrigin[0]), floatround(fEntOrigin[1]), floatround(fEntOrigin[2]), floatround(fEntAngles[1]));
		
		write_file(szFile, szBuffer, -1);
	}
}
bool: isNexus(iEnt)
{
	if( is_valid_ent(iEnt) )
	{
		new iEntCN[32];
		entity_get_string(iEnt, EV_SZ_classname, iEntCN, 32);
		
		if( equal(iEntCN, g_Nexus_T) || equal(iEntCN, g_Nexus_CT) )
		{
			return true;
		}
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
		new Float: fSizeMin[3];
		new Float: fSizeMax[3];
		
		entity_get_vector(iEnt, EV_VEC_mins, fSizeMin);
		entity_get_vector(iEnt, EV_VEC_maxs, fSizeMax);
		
		entity_get_vector(iEnt, EV_VEC_origin, vOrigin);
		
		fSizeMin[0] += 1.0;
		fSizeMax[0] -= 1.0;
		fSizeMin[1] += 1.0;
		fSizeMax[1] -= 1.0; 
		fSizeMin[2] += 1.0;
		fSizeMax[2] -= 1.0;
		
		for( new i = 0; i < 14; ++i )
		{
			vPoint = vOrigin;
			
			switch( i )
			{
				case 0: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMax[2]; }
				case 1: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMax[2]; }
				case 2: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMax[2]; }
				case 3: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMax[2]; }
				case 4: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMin[2]; }
				case 5: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMin[2]; }
				case 6: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMin[2]; }
				case 7: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMin[2]; }
				
				case 8: { vPoint[0] += fSizeMax[0]; }
				case 9: { vPoint[0] += fSizeMin[0]; }
				case 10: { vPoint[1] += fSizeMax[1]; }
				case 11: { vPoint[1] += fSizeMin[1]; }
				case 12: { vPoint[2] += fSizeMax[2]; }
				case 13: { vPoint[2] += fSizeMin[2]; }
			}
			content = point_contents(vPoint);
			
			if( content == CONTENTS_EMPTY || content == 0 )
			{
				return false;
			}
		}
	}
	else
	{
		return false;
	}
	return true;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
