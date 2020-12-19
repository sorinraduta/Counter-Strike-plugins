#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <ColorChat>


#define OWN_ZONES 36
#define MIS_ZONES 6
#define OWN_SOUNDS 16

static const PLUGIN_NAME[] 	= "Hide'N'Seek Ownage + Missions";
static const PLUGIN_AUTHOR[] 	= "sPuf ? & Rap";
static const PLUGIN_VERSION[]	= "1.0.1";


static const Own_Ent[]	= "trigger_own";
static const Mis_Ent[]	= "trigger_mis";

#pragma semicolon 1

new Missions[33];
new IsAccepted[33];
new Survive[33];
new Victims[33];
new Points[33];

new OwnedId;
new OwnedName[32];

new bool:Damaged[33];
new bool:Owned[33];
new bool:FirstOwn[33];
new bool:FirstTouchSM[33];
new bool:FirstTouchSL[33];
new bool:FirstTouchRR[33];
new bool:FirstTouchAC[33];

new Float: Block[33];
new Float: OwnTime[33];
new Float: MissionTime[33];
new Float: JumpTime[33];
new Float: DmgTime[33];

new bool:IsDucked[33];
new bool:IsAfk[33];

new bool:Hear[33];
new bool:Message[33];
new bool:Effect[33];

new Float:AfkOrigin[33][3],Float:OldAfkOrigin[33][3];

new bool:RoofMap = false;
new g_hud_center;

new cvar_dmg;

new const Float: Mins[OWN_ZONES][3] = {

	{ 1795.4, 85.5, 226.0},		//pod
	{-61.9, -575.7, 25.0},		//market
	{-445.2, 386.7, 1025.0},	//cutie scara mare
	{-381.6, 451.2, 1025.0},	//cutie scara panou red dog
	{193.8, -155.8, 0.8},		//cutie market 1
	{131.1, -90.5, 1.7}, 		//cutie market 2
	{-124.5, -170.8, 2.0},		//cutie market 3
	{1155.0, -126.5, 1.0},		//cutie pod
	{546.9, -381.9, 64.0},		//wb market spre mkt
	{578.5, -188.9, 64.0},		//wb market spre scara stiu eu uscara :))
	{546.9, -1086.8, 64.0},		//wb cts spre market
	{578.0, -1117.0, 64.0},		//wb cts spre pod de la cts rr
	{1283.9, -189.6, 67.0},		//wb pod spre scara
	{1473.3, -381.8, 67.00},  	//wb pod culoar
	{-1276.5, -251.1, 1217.0},	//cutie ts langa scara verdeata
	{-1212.5, -509.2, 1217.0},	//cutie ts spre rr cutia de jos
	{-1213.5, -444.1, 1281.0},	//cutie ts spre rr cutia de sus
	{1073.0, -201.8, 1120.0},	//panou pod
	{1049.5, -213.0, 1087.0},	//margine panou pod
	{661.4, -1485.9, 1184.0},	//panou cts scara pod zona spre stg
	{715.2, -1443.8, 1153.0},	//picior panou cts 1
	{793.2, -1363.3, 1152.0},	//picior panou cts 2
	{-798.2, -701.4, 512.7},	//cutie sus scara ts de jos
	{-1405.5, 258.7, 1152.5},	//scara verdeata wr colt
	{-85.8,-1086.5, -23.5}, 	//prelata zona in dreata
	{77.9, -1087.8, -27.2},		//prelata zona in stanga
	{-84.5, -910.5, 2.0},		//prelata zona in fata
	{1280.3, -1017.2, 1088.3},	//panou wb ct spawn
	{-477.7, -1112.5, 641.5},	//cutie de langa umbrele
	{773.8, 771.9,930.0},		//pod cabana zona 1
	{772.5, 812.4, 952.0}, 		//pod cabana zona 2
	{-2170.5, -1530.6, 1344.8},	//lj zona 1
	{-2043.8, -2748.2, 1345.0},	//lj zona 2
	{-2555.5, -2747.4, 1345.8},	//lj zona 3
	{1282.0, -275.2, 1088.0},	//panou pod spre stanga
	{178.2, -652.0, -61.9}		//cutie mareket spre prelata
};
new const Float: Maxs[OWN_ZONES][3] = {

	{1853.4, 255.5, 228.0}, 		//pod
	{190.0, -129.5, 27.0},		//market
	{-323.2, 444.7, 1027.0},	//cutie scara mare
	{-323.6, 509.2, 1027.0},	//cutie scara panou red dog
	{251.8, -99.9, 2.9},		//cutie market 1
	{187.1, -36.5, 3.7},		//cutie market 2
	{-68.5, -116.8, 4.0},		//cutie market 3
	{1213.0, -66.5, 3.0},		//cutie pod
	{572.9, -197.9, 80.0},		//wb market spre mkt
	{766.5, -162.9, 76.0},		//wb market spre scara stiu eu uscara :))
	{572.9, -896.8, 76.0},		//wb cts spre market
	{766.0, -1091.0, 78.0},		//wb cts spre pod de la cts rr
	{1469.9, -163.6, 85.0},		//wb pod spre scara
	{1501.3, -193.8, 83.0},		//wb pod culoar
	{-1220.5, -197.1, 1219.0},	//cutie ts langa scara verdeata
	{-1156.5, -453.2, 1219.0},	//cutie ts spre rr cutia de jos
	{-1155.5, -388.1, 1283.0},	//cutie ts spre rr cutia de sus
	{1147.0, -197.8, 1132.0},	//panou pod
	{1109.5, -211.0, 1099.0},	//margine panou pod
	{663.4, -1473.9, 1196.0},	//panou cts scara pod spre stg
	{719.2, -1439.8, 1157.0},	//picior panou cts 1
	{797.2, -1359.3, 1156.0},	//picior panou cts 2
	{-738.2, -641.4, 514.7},	//cutie sus scara ts de jos
	{-1365.5, 274.7, 1180.5},	//scara verdeata wr colt
	{-77.8, -898.5, 18.3},		//prelata in dreapta
	{83.9, -899.7, 16.7},		//prelata in stanga
	{83.3, -898.5, 24.0},		//prelata fata
	{1284.3, -1015.2, 1092.3},	//panou wb ct spawn
	{-455.7, -1090.5, 643.5},	//cutie de langa umbrele
	{1145.8, 1017.9, 964.0},	//pod cabana zona 1
	{1146.5, 978.4, 1026.0}, 	//pod cabana zona 2
	{-1988.5, -1284.6, 1348.8},	//lj zona 1
	{-1923.8, -2628.2, 1347.0},	//lj zona 2
	{-2435.5, -2627.4, 1347.8},	//lj zona 3
	{1284.0, -273.2, 1092.0},	//panou pod spre stanga
	{186.2, -598.0, -23.9}
};
new const Types[OWN_ZONES] = {

 	1, 2, 3, 3, 2, 2, 2, 4, 5, 5,
	5, 5, 5, 5, 6, 6, 7, 8, 8, 9,
	9, 9,10, 11, 12, 12, 12, 13, 14, 15, 15,
	16, 16, 16, 8, 17
};
new const Messages[18][] = {
	"", // null
	"Anticamera",//1
	"Market",//2
	"Cutii, pop dog",//3
	"Sub pod, la cutie",//4
	"WallBug",//wb mkt - 5
	"Cutie, TS",//6
	"Cutia mare, TS",//7
	"Panou, pod",//8
	"Panou, CTS",//9
	"Cutie, sub TS-RR",// 10
	"TS - White Roof",// 11
	"Prelata",//12
	"Panou, CTS",//13
	"Cutie, umbrele",//14
	"Cabana",//15
	"LJR",//16
	"Cutie, market"//17
};
new const Float: M_Mins[MIS_ZONES][3] =
{
	{-257.637, 589.970, 914.081},		//Scara pop
	{-502.743, 237.909, 913.838},		//Scara mare
	{-633.170, 261.400, 924.031},		//Margine scara mare
	{-509.089, 387.186, 961.031},		//Cutie sacra mare
	{-1008.854, -639.011, 1153.031},		//Terro Spawn
	{-1017.918, -1020.982, 1026.229}		//Red Roof
	/*{1861.117,  -119.101,  -358.968}	Anticamera*/
};
new const Float: M_Maxs[MIS_ZONES][3] =
{
	{-237.637, 625.970, 926.0},		//Scara pop
	{-458.743, 257.909, 925.8},		//Scara mare
	{-335.170, 271.400, 928.0},		//Margine scara mare
	{-451.089, 445.186, 963.03},		//Cutie sacra mare
	{-674.854, -595.011, 1159.03},		//Terro Spawn
	{-737.918, -994.982, 1048.2}		//Red Roof
	/*//{2167.117,  504.898,  -306.9}		Anticamera*/
};
new const M_Types[MIS_ZONES] =
{
	1, 2, 3, 4, 5, 6 //, 7
};
/*new const Float: M_Messages[MIS_ZONES+1][] =
{
	"", //null
	"Scara pop",
	"Scara mare",
	"Margine scara mare",
	"Cutie sacra mare",
	"Terro Spawn",
	"Red Roof"
	//"Anticamera"
};*/
new const MissionsMenuNames[15][] =
{
	"\rOwnage Missions^n\yDoriti sa incepeti misiunile?",
	"\rMisiunea 1^n\yDu-te la pod si owneaza pe cineva la cabana",
	"\rMisiunea 2^n\yDu-te CTS si da un ownage la panou",
	"\rMisiunea 3^n\yDu-te si da un ownage la Market",
	"\rMisiunea 4^n\yDu-te si da 2 ownage-uri consecutive la Market",
	"\rMisiunea 5^n\yDu-te si owneaza pe cineva la scara mare",
	"\rMisiunea 6^n\yDu-te sub pod si da un ownage la cutii",
	"\rMisiunea 7^n\yDu-te sub RR si da un ownage la cutii",
	"\rMisiunea 8^n\yDu-te la market si da un ownage la prelata",
	"\rMisiunea 9^n\yDu-te la market si da un ownage la cutie",
	"\rMisiunea 10^n\yCastiga 5 runde consecutive (T)",
	"\rMisiunea 11^n\yOmoara 5 Teroristi intr-o singura runda (CT)",
	"\rMisiunea 12^n\ySari cutia de la PopDog din Ladder",
	"\rMisiunea 13^n\ySari cutia de la Scara Mare din Ladder",
	"\rMisiunea 14^n\ySari TS-RR"
};

new const Sounds[OWN_SOUNDS][] = {

	"misc/own_dominating1.wav","misc/own_fuck.wav","misc/own_nuu.wav",
	"misc/own_whoa.wav","misc/own_risamalo.wav","misc/own_dominating2.wav",
	"misc/own_gege.mp3","misc/own_ownage.wav","misc/own_yasuck.wav",
	"misc/own_dominating3.wav","misc/own_humiliation.wav","misc/own_power.wav",
	"misc/own_yeahbaby.wav","misc/own_dominating.wav","misc/own_freza.wav",
	"misc/own_diabolique.wav"
};

public plugin_precache() {

	new mapName[33];
	get_mapname(mapName, 32);

	if(!equali(mapName, "awp_rooftops", 12) || equali(mapName, "awp_rooftops_remake", 19)) {
		RoofMap = false;
	} else {
		RoofMap = true;

		for(new i = 0;i < OWN_SOUNDS;i++) {
			precache_sound(Sounds[i]);
		}
	}
}
public plugin_init() {

	if(!RoofMap) {
		new pluginName[33];
		format(pluginName, 32, "[Dezactivat] %s", PLUGIN_NAME);
		register_plugin(pluginName,PLUGIN_VERSION,PLUGIN_AUTHOR);
		pause("ade");
	}
	else if(RoofMap) {

		register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

		register_clcmd( "say", "hook_say" );
		register_clcmd("say /ownmenu", "OwnMenu");
		register_clcmd("say /misiuni", "cmdMENU");
		register_clcmd("say /puncte", "cmdPoints");
		register_concmd("amx_misiuni", "cmdMissions", ADMIN_ALL, "<name>");
		cvar_dmg =register_cvar("own_nodmg","1");

		register_forward(FM_Touch, "fwd_Owning");
		register_forward(FM_PlayerPreThink,"fwdPlayerPreThink");
		register_touch( Own_Ent, "player", "FwdTriggerTouch" );
		register_touch( Mis_Ent, "player", "Fwd_TriggerTouch" );
		register_event("SendAudio","RoundEnd","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw");
		register_event("DeathMsg", "DeathMsg", "a");
		RegisterHam(Ham_TakeDamage, "player", "CBasePlayer_TakeDamage", true);

		CreateOwnZones();

		g_hud_center = CreateHudSyncObj();
	}
}
public CreateOwnZones() {

	for (new i = 0;i < OWN_ZONES;i++ ) {

		CreateTrigger(Types[i], Mins[i], Maxs[i] );

	}
	for (new i = 0;i < MIS_ZONES;i++ ) {

		M_CreateTrigger(M_Types[i], M_Mins[i], M_Maxs[i]);

	}
}
CreateTrigger(const EntType,  const Float:flMins[ 3 ], const Float:flMaxs[ 3 ] ) {
	new iEntity = create_entity( "info_target" );

	if( !is_valid_ent( iEntity ) ) {
		return 0;
	}

	entity_set_string( iEntity, EV_SZ_classname, Own_Ent );
	entity_set_int( iEntity, EV_INT_iuser1, EntType );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_NONE );
	entity_set_int( iEntity, EV_INT_solid, SOLID_TRIGGER );
	entity_set_size( iEntity, flMins, flMaxs );

	return iEntity;
}
M_CreateTrigger(const M_EntType,  const Float:M_flMins[ 3 ], const Float:M_flMaxs[ 3 ] ) {
	new M_iEntity = create_entity( "info_target" );

	if( !is_valid_ent( M_iEntity ) ) {
		return 0;
	}

	entity_set_string( M_iEntity, EV_SZ_classname, Mis_Ent );
	entity_set_int( M_iEntity, EV_INT_iuser1, M_EntType );
	entity_set_int( M_iEntity, EV_INT_movetype, MOVETYPE_NONE );
	entity_set_int( M_iEntity, EV_INT_solid, SOLID_TRIGGER );
	entity_set_size( M_iEntity, M_flMins, M_flMaxs );

	return M_iEntity;
}
public client_connect(id) {

	Hear[id] = true;
	Message[id] = true;
	Effect[id] = true;

	IsAfk[id] = false;
	Block[id] = get_gametime();

	OldAfkOrigin[id][0] = 0.0;
	OldAfkOrigin[id][1] = 0.0;
	OldAfkOrigin[id][2] = 0.0;

	Owned[id] = false;
	FirstOwn[id] = false;
	FirstTouchSM[id] = false;
	FirstTouchSL[id] = false;
	FirstTouchRR[id] = false;
	FirstTouchAC[id] = false;

	Missions[id]= 0;
	IsAccepted[id] = 0;
	Survive[id] = 0;
	Victims[id] = 0;
	Points[id] = 0;

	set_task(3.0,"CheckAfk",id+12345,"",0,"b");
}

public client_disconnect(id) {

	IsAfk[id] = false;
	Owned[id] = false;
	FirstOwn[id] = false;
	FirstTouchSM[id] = false;
	FirstTouchSL[id] = false;
	FirstTouchRR[id] = false;
	FirstTouchAC[id] = false;

	remove_task(id+12345);
}
public MissionsMenu(id, page)
{
	new menuname[64];
	formatex(menuname, 63, "%s",MissionsMenuNames[ Missions[id] ]);
	new menu = menu_create(menuname, "MissionsMenuHandler");
	if(Missions[id] == 0 )
	{
		menu_additem(menu, "\wDa", "1", 0);
		menu_additem(menu, "Nu^n^n\rwww.disconnect.ro", "2", 0);
	}
	else
	{
		menu_additem(menu, "\wAccept", "1", 0);
		menu_additem(menu, "Refuz^n^n\rwww.disconnect.ro", "2", 0);
	}
	menu_display(id, menu, page);
}
public cmdMENU(id)
{
	if(IsAccepted[id] == Missions[id] && IsAccepted[id] != 0)
	{
		ColorChat(id, GREEN, "[D/C]^x01 Ai acceptat deja misiunea.");

		return PLUGIN_HANDLED;
	}
	MissionsMenu(id, 0);

	return PLUGIN_HANDLED;
}
public MissionsMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}

	new data[6], iName[64];
	new iaccess, callback;

	menu_item_getinfo(menu, item, iaccess, data,5, iName, 63, callback);

	new key = str_to_num(data);

	switch(key)
	{
		case 1:
		{

			if(Missions[id] == 0)
			{
				ColorChat(0, BLUE, "^x04[D/C]^x01 Ai^x03 acceptat^x01 provocarea. In^x03 5^x01 secunde vei primi prima misiune.");
				Missions[id] = 1;
				set_task(5.0, "cmdMENU", id);

				return 0;
			}
			else if(Missions[id] > 0)
			{
				IsAccepted[id] = Missions[id];
				ColorChat(0, BLUE, "^x04[D/C]^x01 Ai^x03 acceptat^x01 misiunea. Pentru mai multe informatii despre misiune, tasteaza^x03 /infomission^x01.");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(Missions[id] == 0)
			{
				ColorChat(0, BLUE, "^x04[D/C]^x01 Ai^x03 refuzat^x01 provocarea.");
				return PLUGIN_HANDLED;
			}

			ColorChat(0, BLUE, "^x04[D/C]^x01 Ai^x03 refuzat^x01 misiunea. In caz ca vroiai sa accepti, scrie^x03 /misiuni^x01.");

		}
	}
	return 0;
}
public OwnMenu(id) {

	new OwnMenuMsg[64];
	formatex(OwnMenuMsg, 63, "\rHide'N'Seek Ownage by sPuf ?");
	new MenuOwn = menu_create(OwnMenuMsg, "OwnMenuHandler", 0);

	new ownmsg[64],ownsound[64],owneffect[64];
	formatex(ownmsg, 63, "\yMesaje: %s", Message[id] ? "\w Activate" : "\d Dezactivate");
	formatex(ownsound, 63, "\ySunete: %s", Hear[id] ? "\w Activate" : "\d Dezactivate");
	formatex(owneffect, 63, "\yEfecte: %s", Effect[id] ? "\w Activate" : "\d Dezactivate");

	menu_additem(MenuOwn, ownmsg, "1", 0);
	menu_additem(MenuOwn, ownsound, "2", 0);
	menu_additem(MenuOwn, owneffect, "3", 0);


	menu_setprop(MenuOwn, MPROP_EXITNAME, "\yIesire^n^n\rwww.disconnect.ro");
	menu_display(id, MenuOwn, 0);

	return PLUGIN_HANDLED;
}

public OwnMenuHandler(id, menu, item) {

	if(item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	new data[6], iName[64];
	new access, callback;

	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new key = str_to_num(data);

	switch(key) {
		case 1: {
			OwnMsg(id);
			OwnMenu(id);
		}
		case 2: {
			OwnSound(id);
			OwnMenu(id);
		}
		case 3: {
			OwnEffect(id);
			OwnMenu(id);
		}
	}

	return PLUGIN_HANDLED;
}
public cmdPoints(id)
{
	if(Missions[id] == 0)
	{
		ColorChat(id, GREEN, "[D/C]^x01 Nu ai acceptat sa incepi misiunile.");
		ColorChat(id, GREEN, "[D/C]^x01 Pentru a incepe misiunile, tasteaza^x03 /misiuni.");

		return PLUGIN_HANDLED;
	}

	set_hudmessage(233, 233, 233, 0.01 , 0.15, 10);
	show_hudmessage(id, "Puncte: %d^nMisiunea: %d", Points[id], IsAccepted[id]);
	ColorChat(id, GREEN, "[D/C]^x01 Ai^x03 %d^x01 puncte.", Points[id]);

	return PLUGIN_HANDLED;
}
public OwnMsg(id) {
	if(Message[id]) {
		Message[id] = false;
		ColorChat(id,RED,"^x04[D/C]^x01 Ti-ai^x03 dezactivat^x01 mesajele de la ownage-uri !");
		return PLUGIN_HANDLED;
	} else if(!Message[id] ){
		Message[id] = true;
		ColorChat(id,RED,"^x04[D/C]^x01 Ti-ai^x03 activat^x01 mesajele de la ownage-uri !");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
public OwnSound(id) {
	if(Hear[id]) {
		Hear[id] = false;
		ColorChat(id,RED,"^x04[D/C]^x01 Ti-ai^x03 dezactivat^x01 sunetele de la ownage-uri !");
		return PLUGIN_HANDLED;
	} else if(!Hear[id] ){
		Hear[id] = true;
		ColorChat(id,RED,"^x04[D/C]^x01 Ti-ai^x03 activat^x01 sunetele de la ownage-uri !");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
public OwnEffect(id) {

	if(Effect[id]) {
		Effect[id] = false;
		ColorChat(id,RED,"^x04[D/C]^x01 Ti-ai^x03 dezactivat^x01 efectele de la ownage-uri !");
		return PLUGIN_HANDLED;
	} else if(!Effect[id] ){
		Effect[id] = true;
		ColorChat(id,RED,"^x04[D/C]^x01 Ti-ai^x03 activat^x01 efectele de la ownage-uri !");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}
public hook_say(id)
{
	static args[192], command[192];
	read_args(args,charsmax(args));

	if(!args[0])
	{
		return PLUGIN_CONTINUE;
	}
	remove_quotes(args[0]);
	if(equal(args, "/misiuni", strlen("/misiuni")) || equal(args, "/misiune", strlen("/misiune"))) {
		replace(args,charsmax(args), "/", "" );
		formatex(command, charsmax(command) , "amx_%s", args);
		client_cmd(id, command);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public cmdMissions(id)
{
	new target[32];
    	read_argv(1, target, 31);

	if(equali(target,""))
	{
		new name[32];
		get_user_name(id, name, 31);

		ColorChat(0, RED, "^x04[D/C]^x03 %s^x01 este la misiunea^x03 %d^x01 si are^x03 %d^x01 puncte.", name, Missions[id], Points[id]);
		return PLUGIN_HANDLED;
	}
    	new player = cmd_target(id, target, 8);
    	if(!player || player == id)
	{
		return PLUGIN_HANDLED;
	}
	else
	{
		new name[32];
		get_user_name(player, name, 31);

		ColorChat(0, RED, "^x04[D/C]^x03 %s^x01 este la misiunea^x03 %d^x01 si are^x03 %d^x01 puncte.", name, Missions[player], Points[player]);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public CheckAfk(id) {

	id -= 12345;

	if(is_user_ok(id) && cs_get_user_team(id)  == CS_TEAM_CT) {

		pev(id, pev_origin, AfkOrigin[id]);

		if(AfkOrigin[id][0] == OldAfkOrigin[id][0] &&
			AfkOrigin[id][1] == OldAfkOrigin[id][1] &&
			AfkOrigin[id][2] == OldAfkOrigin[id][2] && !IsAfk[id]) {

			IsAfk[id] = true;

		}
		if(AfkOrigin[id][0] != OldAfkOrigin[id][0] &&
			AfkOrigin[id][1] != OldAfkOrigin[id][1] &&
			AfkOrigin[id][2] != OldAfkOrigin[id][2] && IsAfk[id]) {

			IsAfk[id] = false;
		}

		OldAfkOrigin[id][0] = AfkOrigin[id][0];
		OldAfkOrigin[id][1] = AfkOrigin[id][1];
		OldAfkOrigin[id][2] = AfkOrigin[id][2];
	}
}
/*
"Scara pop" //1
"Scara mare" //2
"Margine scara mare" //3
"Cutie sacra mare" //4
"Terro Spawn" //5
"Red Roof" //6
"Anticamera" //7
*/
public Fwd_TriggerTouch(const M_iEntity, const id)
{
	if(is_user_ok(id))
	{
		new name[32];
		get_user_name(id, name, 31);

		static M_Type;
		M_Type = entity_get_int(M_iEntity, EV_INT_iuser1);

		if(M_Type == 1)
		{
			JumpTime[id] = get_gametime();
			FirstTouchSL[id] = true;
		}
		if(M_Type == 2)
		{
			JumpTime[id] = get_gametime();
			FirstTouchSM[id] = true;
		}
		if(M_Type == 3)
		{
			FirstTouchSM[id] = false;
		}
		if(M_Type == 4 && (get_gametime() - JumpTime[id] < 2.0) && FirstTouchSM[id])
		{
			ColorChat(0, GREEN, "[D/C]^x03 %s^x01 a sarit^x04 Cutia^x01 de la^x04 Scara Mare^x01 din^x04 Ladder^x01.", name);
			FirstTouchSM[id] = false;
			if(Missions[id] == 13 && IsAccepted[id] == 13)
			{
				Points[id] += 20;
				cmdPoints(id);
				Missions[id]++;
				ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 13!", name);
				ColorChat(id, GREEN, "[D/C]^x01 Misiunea 13 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
			}
		}
		if(M_Type == 5)
		{
			JumpTime[id] = get_gametime();
			FirstTouchRR[id] = true;
		}
		if(M_Type == 6 && (get_gametime() - JumpTime[id] < 3.0) && FirstTouchRR[id])
		{
			ColorChat(0, GREEN, "[D/C]^x03 %s^x01 a sarit^x04 TS-RR^x01.", name);
			FirstTouchRR[id] = false;
			if(Missions[id] == 14 && IsAccepted[id] == 14)
			{
				Points[id] += 40;
				cmdPoints(id);
				Missions[id]++;
				ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 14!", name);
				ColorChat(id, GREEN, "[D/C]^x01 Misiunea 14 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
			}
		}
	}
	return PLUGIN_HANDLED;
}
public FwdTriggerTouch( const iEntity, const id )
{
	if(is_user_ok(id)){

		new name[32];
		get_user_name(id,name,31);


		static Type;
		Type = entity_get_int( iEntity, EV_INT_iuser1 );

		if(Type == 3 && (get_gametime() - JumpTime[id] < 1.5) && FirstTouchSL[id])
		{
			ColorChat(0, GREEN, "[D/C]^x03 %s^x01 a sarit^x04 Cutia^x01 de la^x04 PopDog^x01 din^x04 Ladder^x01.", name);
			FirstTouchSL[id] = false;
			if(Missions[id] == 12 && IsAccepted[id] == 12)
			{
				Points[id] += 60;
				cmdPoints(id);
				Missions[id]++;
				ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 12!", name);
				ColorChat(id, GREEN, "[D/C]^x01 Misiunea 14 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
			}
		}
		if(Owned[id]) {

			Owned[id] = false;

			if(get_pcvar_num(cvar_dmg) == 1) {

				if(!Damaged[id]) {
					CheckUserMissions(id, Type, name);
					MsgSoundEffect(Type, name, OwnedName);
				}
				else if(Damaged[id]) {
					ColorChat(id,RED,"^x04[D/C]^x03 Deoarece ai primit damage, ownage-ul nu este valabil.");
				}
				return PLUGIN_HANDLED;
			}
			else
			{
				CheckUserMissions(id, Type, name);
				MsgSoundEffect(Type, name, OwnedName);
			}

		}
	}
	return PLUGIN_CONTINUE;
}
public MsgSoundEffect(const Type, const name[], const ownedname[]) {

	new x = random_num(0,OWN_SOUNDS -1);
	set_hudmessage( 0, 255, 255, -1.0, 0.20, 0, 0.0, 2.0, 0.0, 1.0, -1);

	new Players[32];
	new PlayersNum, player;

	get_players(Players, PlayersNum, "ch");
	for(new i=0; i<PlayersNum; i++) {
		player = Players[i];
		if(Message[player]) {
			ShowSyncHudMsg(player, g_hud_center, "%s OWNED %s^n %s",name,OwnedName, Messages[Type]);
			ColorChat(player,RED,"^x04[D/C]^x03 %s^x01 OWNED^x03 %s^x01 (^x04%s^x01)", name, ownedname,Messages[Type]);
		}
		if(Hear[player]) {
			if( contain(Sounds[x], ".wav") > 0 ) client_cmd(player,"spk %s",Sounds[x]);
			else if( contain(Sounds[x], ".mp3") > 0 ) client_cmd(player,"mp3 play ^"sound/%s^"",Sounds[x]);
		}
		if(player == OwnedId) {
			if(Effect[player]) {
				ShakeScreen(OwnedId);
				FadeScreen(OwnedId);
			}
		}
	}


}
public DeathMsg( )
{
	new killer = read_data(1);

	new PlayersNum, Players[32];
	get_players(Players, PlayersNum, "ch");
	for( new i=0; i<PlayersNum; i++)
	{
		if(cs_get_user_team(Players[i]) == CS_TEAM_CT && Missions[Players[i]] == 11 && IsAccepted[Players[i]] == 11 && Players[i] == killer )
		{
			if(Victims[Players[i]] == 4)
			{
				new name[32];
				get_user_name(Players[i], name, 31);

				Points[Players[i]] += 20;
				cmdPoints(Players[i]);
				Missions[Players[i]]++;
				ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 11!", name);
				ColorChat(Players[i], GREEN, "[D/C]^x01 Misiunea 11 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");

				break;
			}
			new VictimsRemaining[33];

			Victims[Players[i]]++;
			VictimsRemaining[Players[i]] = 5 - Victims[Players[i]];
			ColorChat(Players[i], GREEN, "[D/C]^x01 Mai ai de omorat^x03 %d^x01 teroristi, pentru a termina misiunea.", VictimsRemaining[Players[i]]);
		}
	}
	return PLUGIN_CONTINUE;
}
public RoundEnd()
{
	new PlayersNum, Players[32];
	get_players(Players, PlayersNum, "ch");
	for( new i=0; i<PlayersNum; i++)
	{
		if(cs_get_user_team(Players[i]) == CS_TEAM_CT && Missions[Players[i]] == 11 && IsAccepted[Players[i]] == 11)
		{
			Victims[Players[i]] = 0;
		}

		if(cs_get_user_team(Players[i]) == CS_TEAM_T && Missions[Players[i]] == 10 && IsAccepted[Players[i]] == 10)
		{
			if(is_user_alive(Players[i]))
			{
				if(Survive[Players[i]] == 4)
				{
					new name[32];
					get_user_name(Players[i], name, 31);

					Points[Players[i]] += 35;
					cmdPoints(Players[i]);
					Missions[Players[i]]++;
					ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 10!", name);
					ColorChat(Players[i], GREEN, "[D/C]^x01 Misiunea 10 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
					break;
				}
				new SurviveRemaining[33];

				Survive[Players[i]]++;
				SurviveRemaining[Players[i]] = 5 - Survive[Players[i]];
				ColorChat(Players[i], GREEN, "[D/C]^x01 Mai ai de castigat^x03 %d^x01 runde, pentru a termina misiunea.", SurviveRemaining[Players[i]]);
			}
			else
			{
				Survive[Players[i]] = 0;
			}
		}
	}
	return PLUGIN_CONTINUE;
}
/*
	"", // null
	"Anticamera",//1
	"Market",//2
	"Cutii, pop dog",//3
	"Sub pod, la cutie",//4
	"WallBug",//wb mkt - 5
	"Cutie, TS",//6
	"Cutia mare, TS",//7
	"Panou, pod",//8
	"Panou, CTS",//9
	"Cutie, sub TS-RR",// 10
	"TS - White Roof",// 11
	"Prelata",//12
	"Panou, CTS",//13
	"Cutie, umbrele",//14
	"Cabana",//15
	"LJR",//16
	"Cutie, market"//17
*/
public CheckUserMissions( id, const Type , const name[])
{
	if(Type == 15 && Missions[id] == 1 && IsAccepted[id] == 1)
	{
		Points[id] += 10;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 1!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 1 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 9 && Missions[id] == 2 && IsAccepted[id] == 2)
	{
		Points[id] += 45;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 2!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 2 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 2 && Missions[id] == 3 && IsAccepted[id] == 3)
	{
		Points[id] += 30;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 3!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 3 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 2 && Missions[id] == 4 && IsAccepted[id] == 4)
	{
		if(!FirstOwn[id])
		{
			FirstOwn[id] = true;
			MissionTime[id] = get_gametime() ;
			ColorChat(id, GREEN, "[D/C]^x01 Prima parte a misiunii este completa.");
			ColorChat(id, GREEN, "[D/C]^x01 Pentru a termina misiunea, trebuie sa mai dai un ownage la market in mai putin de^x04 10^x01 secunde.");

			return PLUGIN_HANDLED;
		}

		else if (FirstOwn[id] && (get_gametime() - MissionTime[id] < 10.0))
		{
			Points[id] += 65;
			cmdPoints(id);
			Missions[id]++;
			ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 4!", name);
			ColorChat(id, GREEN, "[D/C]^x01 Misiunea 4 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
		}
	}
	else if(Type == 3 && Missions[id] == 5 && IsAccepted[id] == 5)
	{
		Points[id] += 30;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 5!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 5 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 4 && Missions[id] == 6 && IsAccepted[id] == 6)
	{
		Points[id] += 15;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 6!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 6 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 10 && Missions[id] == 7 && IsAccepted[id] == 7)
	{
		Points[id] += 20;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 7!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 7 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 12 && Missions[id] == 8 && IsAccepted[id] == 8)
	{
		Points[id] += 35;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 8!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 8 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	else if(Type == 17 && Missions[id] == 9 && IsAccepted[id] == 9)
	{
		Points[id] += 25;
		cmdPoints(id);
		Missions[id]++;
		ColorChat(0, BLUE, "^x04[D/C]^x03 %s a terminat misiunea 9!", name);
		ColorChat(id, GREEN, "[D/C]^x01 Misiunea 9 COMPLETA. Tasteaza^x03 /misiuni^x01 pentru urmatoarea misiune.");
	}
	return PLUGIN_HANDLED;
}
public fwdPlayerPreThink(id) {

	if(is_user_ok(id) ) {

		if(cs_get_user_team(id)  == CS_TEAM_CT ) {

			static button;
			button = pev(id, pev_button );

			if((button & IN_FORWARD || button & IN_BACK
			|| button & IN_MOVELEFT || button & IN_MOVERIGHT
			|| button & IN_JUMP || button & IN_DUCK) && IsAfk[id] ) {

				IsAfk[id] = false;
			}
		}
		if((get_gametime() - OwnTime[id] > 1.5) && Owned[id] ) {

			Owned[id] = false;
			OwnedId = 0;
		}

		if(get_pcvar_num(cvar_dmg) == 1) {
			if((get_gametime() - DmgTime[id] > 1.5) && Damaged[id] ) {
				Damaged[id] = false;
			}
		}
	}

	return FMRES_IGNORED;
}

public fwd_Owning(owned, owner) {

	static OwnedClassname[32],OwnerClassname[32];
	pev(owned,pev_classname,OwnedClassname, 31);
	pev(owner, pev_classname, OwnerClassname, 31);

	if(!equal(OwnedClassname, "player") || !equal(OwnerClassname, "player")) return FMRES_IGNORED;

	if(!is_user_ok(owned) || !is_user_ok(owner) || IsAfk[owned] ) return FMRES_IGNORED;

	if(cs_get_user_team(owner)  == CS_TEAM_CT || cs_get_user_team(owner) == cs_get_user_team(owned)) return FMRES_IGNORED;


	static Float:OwnedOrigin[3],Float:OwnerOrigin[3];
	pev(owned, pev_origin, OwnedOrigin);
	pev(owner, pev_origin, OwnerOrigin);

	new Float:OwnDistance = OwnerOrigin[2] - OwnedOrigin[2];
	new Float:NeededDistance;

	IsDucked[owner] = is_in_duck(owner);
	IsDucked[owned] = is_in_duck(owned);

	if(IsDucked[owned] && !IsDucked[owner] || !IsDucked[owned] && IsDucked[owner] ) NeededDistance = 54.0;
	if(IsDucked[owned] && IsDucked[owner] ) NeededDistance = 36.0;
	if(!IsDucked[owned] && !IsDucked[owner] ) NeededDistance = 72.0;

	if( OwnDistance >= NeededDistance && !Owned[owner] ) {

		if( (get_gametime() - Block[owner] > 3.0)) {

			OwnedId = owned;
			get_user_name(owned,OwnedName,31);
			Owned[owner] = true;
			Block[owner] = get_gametime();
			OwnTime[owner] = get_gametime();

			return FMRES_IGNORED;
		}

	}

	return FMRES_IGNORED;
}
public CBasePlayer_TakeDamage(id, iInflictor, iAttacker, Float:flDamage, bitsDamageType) {

	if(get_pcvar_num(cvar_dmg) != 1 || !iAttacker || id == iAttacker || !is_user_ok(iAttacker)
		|| !is_user_ok(id) || cs_get_user_team(id) == cs_get_user_team(iAttacker)) return HAM_IGNORED;

	Damaged[id] = true;
	DmgTime[id] = get_gametime();

	return HAM_IGNORED;
 }
stock bool:is_in_duck(entity) {

	if(!pev_valid(entity)) return false;

	static Float:absmin[3], Float:absmax[3];

	pev(entity, pev_absmin, absmin);
	pev(entity, pev_absmax, absmax);

	absmin[2]+=64.0;

	if(absmin[2] < absmax[2]) return false;

	return true;
}
stock is_user_ok(id) {

	if(is_user_alive(id) && is_user_connected(id) && !is_user_bot(id))
		return 1;

	return 0;
}
ShakeScreen(id) {

	message_begin(MSG_ONE,get_user_msgid("ScreenShake"),{0,0,0},id);
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(1<<13);
	message_end();

}

FadeScreen(id) {

	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(floatround(4096.0 * 3.0, floatround_round));
	write_short(0x0000);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	write_byte(110);
	message_end();
}
