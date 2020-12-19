#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <ColorChat>

#define JUMP_ZONES 5

#pragma semicolon 1

static const PLUGIN[] 	= "Hide'N'Seek Jumps";
static const AUTHOR[] 	= "sPuf ? & Rap";
static const VERSION[]	= "1.0";

static const Jump_Ent[]	= "trigger_jump";


new bool:FirstTouchSM[33];
new bool:FirstTouchRR[33];
new bool:FirstTouchAC[33];

new Float: JumpTime[33];

new bool:RoofMap = false;

new const Float: Mins[JUMP_ZONES][3] =
{
	{-502.743, 237.909, 913.838},		// Scara mare
	{-633.170, 261.400, 924.031},		// Margine scara mare
	{-509.089, 387.186, 961.031},		// Cutie sacra mare
	{-1008.854, -639.011, 1153.031},	// Terro Spawn
	{-1017.918, -1020.982, 1026.229}	// Red Roof
	/*{1861.117,  -119.101,  -358.968}	Anticamera*/
};
new const Float: Maxs[JUMP_ZONES][3] =
{
	{-458.743, 257.909, 925.8},		// Scara mare
	{-335.170, 271.400, 928.0},		// Margine scara mare
	{-451.089, 445.186, 963.03},		// Cutie sacra mare
	{-674.854, -595.011, 1159.03},		// Terro Spawn
	{-737.918, -994.982, 1048.2}		// Red Roof
	/*//{2167.117,  504.898,  -306.9}	Anticamera*/
};
new const Types[JUMP_ZONES] =
{
	1, 2, 3, 4, 5 //, 6, 7
};
/*new const Float: Messages[JUMP_ZONES +1][] =
{
	"", // null
	"Scara mare",
	"Margine scara mare",
	"Cutie sacra mare",
	"Terro Spawn",
	"Red Roof"
	// "Anticamera"
};*/
public plugin_precache()
{
	new mapName[33];
	get_mapname(mapName, 32);

	if(!equali(mapName, "awp_rooftops", 12) || equali(mapName, "awp_rooftops_remake", 19))
	{
		RoofMap = false;
	}
	else
	{
		RoofMap = true;
	}
}
public plugin_init()
{
	if(!RoofMap)
	{
		new pluginName[33];
		format(pluginName, 32, "%s dezactivat", PLUGIN);
		register_plugin(pluginName, VERSION, AUTHOR);
		pause("ade");
	}
	else if(RoofMap)
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		register_touch(Jump_Ent, "player", "FwdTriggerTouch");

		CreateOwnZones();
	}
}
public CreateOwnZones()
{
	for (new i = 0;i < JUMP_ZONES;i++) {

		CreateTrigger(Types[i], Mins[i], Maxs[i]);

	}
}
CreateTrigger(const EntType, const Float: flMins[3], const Float: flMaxs[3])
{
	new iEntity = create_entity("info_target");

	if(!is_valid_ent(iEntity))
	{
		return PLUGIN_HANDLED;
	}

	entity_set_string( iEntity, EV_SZ_classname, Jump_Ent);
	entity_set_int(iEntity, EV_INT_iuser1, EntType);
	entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_NONE);
	entity_set_int(iEntity, EV_INT_solid, SOLID_TRIGGER);
	entity_set_size(iEntity, flMins, flMaxs);

	return iEntity;
}
public client_connect(id)
{
	FirstTouchSM[id] = false;
	FirstTouchRR[id] = false;
	FirstTouchAC[id] = false;
}

public client_disconnect(id)
{
	FirstTouchSM[id] = false;
	FirstTouchRR[id] = false;
	FirstTouchAC[id] = false;

	remove_task(id+12345);
}
/*
"Scara mare" // 1
"Margine scara mare" // 2
"Cutie sacra mare" // 3
"Terro Spawn" // 4
"Red Roof" // 5
"Anticamera" // 6
*/
public FwdTriggerTouch(const iEntity, const id)
{
	if(is_user_ok(id))
	{
		new name[32];
		get_user_name(id, name, 31);

		static Type;
		Type = entity_get_int(iEntity, EV_INT_iuser1);

		if(Type == 1)
		{
			JumpTime[id] = get_gametime();
			FirstTouchSM[id] = true;
		}
		if(Type == 2)
		{
			FirstTouchSM[id] = false;
		}
		if(Type == 3 && (get_gametime() - JumpTime[id] < 2.0) && FirstTouchSM[id])
		{
			ColorChat(0, GREEN, "[D/C]^x03 %s^x01 a sarit^x04 Cutia^x01 de la^x04 Scara Mare^x01 din^x04 Ladder^x01.", name);
			FirstTouchSM[id] = false;
		}
		if(Type == 4)
		{
			JumpTime[id] = get_gametime();
			FirstTouchRR[id] = true;
		}
		if(Type == 5 && (get_gametime() - JumpTime[id] < 3.0) && FirstTouchRR[id])
		{
			ColorChat(0, GREEN, "[D/C]^x03 %s^x01 a sarit^x04 TS-RR^x01.", name);
			FirstTouchRR[id] = false;
		}
	}
	return PLUGIN_HANDLED;
}
stock is_user_ok(id)
{
	if(is_user_alive(id) && is_user_connected(id) && !is_user_bot(id))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}
