#include <amxmodx>
#include <engine>
#include <ColorChat>

#pragma semicolon 1

#define ARCTIC_ZONES 14


static const PLUGIN[ ] 		= "Deathrun Shortcuts";
static const AUTHOR[ ] 		= "Rap";
static const VERSION[ ]		= "0.1.0";

static const Arctic_Ent[ ]	= "trigger_arctic";
static const Dust2009_Ent[ ]	= "trigger_dust2009";
static const Diavola_Ent[ ]	= "trigger_diavola";


new const Float: Dust2009_Mins[ ] = {-743.0, -412.7, -202.3};
new const Float: Dust2009_Maxs[ ] = {-723.0, -212.8, -70.3};

new const Float: Diavola_Mins[ ] = {789.1, 703.3, -239.2};
new const Float: Diavola_Maxs[ ] = {889.1, 833.3, -207.2};

new const Float: Arctic_Mins[ARCTIC_ZONES][3] =
{
	{-903.2, -2289.3, -320.5},
	{-903.0, -2271.6, -209.3},
	{152.3, -1822.0, -317.2},
	{1756.4, -2287.3, -325.1},
	{-887.4, 17.7, -324.7},
	{-872.7, 41.0, -315.8},
	{-880.4, 261.0, -218.1},
	{-848.5, 478.5, -317.2},
	{1820.0, 14.0, -321.2},
	{-1015.5, 2449.8, -322.8},
	{-1017.1, 2905.1, -318.9},
	{1946.4, 2446.2, -322.4},
	{-1077.7, 2399.5, -347.0},
	{-1095.599, 2433.600, 75.800}
};
new const Float: Arctic_Maxs[ARCTIC_ZONES][3] =
{
	{1776.5, -2269.3, -228.5},
	{-783.0, -2251.6, -37.2},
	{1772.3, -1802.0, -225.1},
	{1776.4, -1807.4, -233.1},
	{1832.5, 37.9, -232.8},
	{-852.7, 481.0, -223.8},
	{-840.4, 277.0, -66.1},
	{1831.3, 498.5, -225.3},
	{1840.0, 494.0, -229.1},
	{1964.4, 2469.8, -230.8},
	{1962.8, 2925.1, -226.9},
	{1966.4, 2926.2, -230.4},
	{-1037.7, 2479.5, -35.0},
	{1984.099, 2943.600, 135.8}
};

const TASK_NOTSOLID = 1234;
const TASK_DUST2009 = 3562;

new bool: TaskDust2009 = false;


public plugin_init( )
{
	new szMapName[33];
	get_mapname(szMapName, 32);
	
	if( equali(szMapName, "deathrun_arctic", 15) )
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		
		register_touch(Arctic_Ent, "player", "FwdTriggerTouchArctic");
		CreateZonesArctic( );
	}
	else if( equali(szMapName, "deathrun_dust2009", 17) )
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		
		new iEntity = create_entity("info_target");
	
		if( !is_valid_ent(iEntity) )
			return 0;
			
		entity_set_string(iEntity, EV_SZ_classname, Dust2009_Ent);
		entity_set_int(iEntity, EV_INT_solid, SOLID_BBOX);
		entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_size(iEntity, Dust2009_Mins, Dust2009_Maxs);
		
		set_rendering(iEntity, kRenderFxGlowShell, 0, 0, 230, kRenderNormal, 3);
		
		register_touch(Dust2009_Ent, "player", "FwdTriggerTouchDust2009");
	}
	else if( equali(szMapName, "deathrun_diavola", 16) )
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		
		new iEntity = create_entity("info_target");
	
		if( !is_valid_ent(iEntity) )
			return 0;
			
		entity_set_string(iEntity, EV_SZ_classname, Diavola_Ent);
		entity_set_int(iEntity, EV_INT_solid, SOLID_BBOX);
		entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_size(iEntity, Diavola_Mins, Diavola_Maxs);
		
		register_touch(Diavola_Ent, "player", "FwdTriggerTouchDiavola");
	}
	else
	{
		new szPlugin[33];
		format(szPlugin, 32, "[Dezactivat] %s", PLUGIN);
		register_plugin(szPlugin, VERSION, AUTHOR);
		pause("ade");
	}
	return PLUGIN_CONTINUE;
}
public StopTask( ) TaskDust2009 = false;

public CreateZonesArctic( )
{
	for( new i = 0; i < ARCTIC_ZONES; i++ )
	{
		CreateTrigger(Arctic_Mins[i], Arctic_Maxs[i]);
	}
}
CreateTrigger(const Float:flMins[3], const Float:flMaxs[3])
{
	new iEntity = create_entity("info_target");
	
	if( !is_valid_ent(iEntity) )
		return 0;
		
	entity_set_string(iEntity, EV_SZ_classname, Arctic_Ent);
	entity_set_int(iEntity, EV_INT_solid, SOLID_TRIGGER);	
	entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_NONE);
	entity_set_size(iEntity, flMins, flMaxs);
	
	return iEntity;
}
public FwdTriggerTouchArctic(const iEntity, const id)
{
	if( is_user_ok(id) )
	{
		new szName[32], Players[32];
		new PlayersNum, player;
		
		get_user_name(id, szName, 31);
		get_players(Players, PlayersNum, "ch");		
		for( new i = 0; i < PlayersNum; i++ )
		{
			player = Players[i];
			if( player == id )
			{
				user_silentkill(id);
				FadeScreen(id);
				
				ColorChat(id, RED, "^x04[Deathrun Bugs]^x01 Ai primit^x03 slay^x01 deoarece ai scurtat.");
			}
			else
			{
				ColorChat(player, RED, "^x04[Deathrun Bugs]^x03 %s^x01 a primit^x03 slay^x01 deoarece a scurtat.", szName);
			}
		}
	}
	return PLUGIN_CONTINUE;
}
public FwdTriggerTouchDust2009(const iEntity, const id)
{
	if( is_user_ok(id) )
	{
		if( get_user_team(id) == 1 )
		{
			if( !TaskDust2009 )
			{
				taskMessageDust2009(TASK_DUST2009 + id);
				TaskDust2009 = true;
			}
		}
		else if( get_user_team(id) == 2 )
		{
			taskSolidNot(TASK_NOTSOLID + iEntity);
		}
	}
	return PLUGIN_CONTINUE;
}
public FwdTriggerTouchDiavola(const iEntity, const id)
{
	if( is_user_ok(id) )
	{
		user_silentkill(id);
	}
	return PLUGIN_CONTINUE;
}
public taskMessageDust2009(id)
{
	id -= TASK_DUST2009;
	
	ShakeScreen(id);
	FadeScreen(id);
			
	ColorChat(id, GREEN, "[Deathrun Bugs]^x01 Nu iti este permis sa iti parasesti baza.");
	
	set_task(5.0, "StopTask");
}
public taskSolidNot(iEntity)
{
	iEntity -= TASK_NOTSOLID;
	
	if( is_valid_ent(iEntity) )
	{
		entity_set_int(iEntity, EV_INT_solid, SOLID_NOT);
		set_task(3.0, "taskSolid", TASK_NOTSOLID + iEntity);
	}
}
public taskSolid(iEntity)
{
	iEntity -= TASK_NOTSOLID;
	
	if( is_valid_ent(iEntity) )
	{
		entity_set_int(iEntity, EV_INT_solid, SOLID_BBOX);
	}
}

ShakeScreen(id)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, id);
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(1<<13);
	message_end( );
	
}
FadeScreen(id)
{      
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(0x0000);
	write_byte(210);
	write_byte(0);
	write_byte(0);
	write_byte(100);
	message_end( );

}
stock is_user_ok(id)
{
	if( is_user_alive(id) && is_user_connected(id) && !is_user_bot(id) )
		return 1;
		
	return 0;
}
