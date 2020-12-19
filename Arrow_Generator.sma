#include <amxmodx>
#include <fakemeta>

#pragma semicolon 1

static const

	PLUGIN[ ] =		"Arrow Generator",
	VERSION[ ] =		"0.1",
	AUTHOR[ ] =		"Rap^^";

#define TASK_DRAW 1234
#define TEMPORARY 0
#define MAX_ARROWS 100

static const szSprite[ ]	=	"sprites/dot.spr";

enum _:Coordinates
{
	X = 0,
	Y,
	Z
}

enum _:Attributes
{
	DIRECTION = 0,
	WAY,
	SIZE,
	COLOR,
	RED,
	GREEN,
	BLUE
}

new Float: g_flArrowCoord[MAX_ARROWS][Coordinates];

new g_iArrowAttrib[MAX_ARROWS][Attributes];

new g_szFile[100];

new g_iMenu;
new g_iAxe;
new g_iSize;
new g_iColor;
new g_iArrow = -1;
new g_iArrowsNum;

new iSprite;


public plugin_init( )
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /arrows", "cmdArrows");
}

public plugin_precache( )
{
	iSprite = precache_model(szSprite);
}

public plugin_cfg( )
{
	get_localinfo("amxx_configsdir", g_szFile, sizeof(g_szFile) - 1);
	
	new szMapName[32];
	get_mapname(szMapName, sizeof(szMapName) - 1);
	
	format(g_szFile, sizeof(g_szFile) - 1, "%s/Arrows", g_szFile);

	if( !dir_exists(g_szFile) )
	{
		mkdir(g_szFile);
		
		format(g_szFile, sizeof(g_szFile) - 1, "%s/%s.arrows", g_szFile, szMapName);
		
		return;
	}
	
	format(g_szFile, sizeof(g_szFile) - 1, "%s/%s.arrows", g_szFile, szMapName);

	new iFile = fopen(g_szFile, "rt");
	
	if( !iFile )
	{
		return;
	}

	new szData[128], iSizeofCoord = 4, iSizeofAttrib = 7;
	new szArrowAtribb[Attributes][8], szArrowCoord[Coordinates][5];
	
	while( !feof(iFile) && (g_iArrowsNum < MAX_ARROWS) )
	{
		fgets(iFile, szData, sizeof(szData) - 1 );
		trim(szData);
		
		if( !szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/') )
			continue;
		
		parse(szData,
		szArrowCoord[0],		iSizeofCoord,
		szArrowCoord[1],		iSizeofCoord,
		szArrowCoord[2],		iSizeofCoord,
		szArrowAtribb[DIRECTION],	iSizeofAttrib,
		szArrowAtribb[WAY],		iSizeofAttrib,
		szArrowAtribb[SIZE],		iSizeofAttrib,
		szArrowAtribb[COLOR],		iSizeofAttrib,
		szArrowAtribb[RED],		iSizeofAttrib,
		szArrowAtribb[GREEN],		iSizeofAttrib,
		szArrowAtribb[BLUE],		iSizeofAttrib);
		
		g_iArrowsNum++;
		
		for( new i = X; i <= Z; i++ )
		{
			g_flArrowCoord[g_iArrowsNum][i] = str_to_float(szArrowCoord[i]);
		}
		
		for( new i = DIRECTION; i <= BLUE; i++ )
		{
			g_iArrowAttrib[g_iArrowsNum][i] = str_to_num(szArrowAtribb[i]);
		}
	}
	
	fclose(iFile);
	
	StartTask( );
}

public plugin_end( )
{
	new iFile = fopen(g_szFile, "wt");
	
	if( !iFile )
	{
		return;
	}
	
	new szData[128];
	
	if( g_iArrowsNum == 0 )
	{
		delete_file(g_szFile);
	}
	
	for( new i = 1; i <= g_iArrowsNum; i++ )
	{
		formatex(szData, sizeof(szData) - 1, "%f %f %f %d %d %d %d %d %d %d^n",
		g_flArrowCoord[i][X],
		g_flArrowCoord[i][Y],
		g_flArrowCoord[i][Z],
		g_iArrowAttrib[i][DIRECTION],
		g_iArrowAttrib[i][WAY],
		g_iArrowAttrib[i][SIZE],
		g_iArrowAttrib[i][COLOR],
		g_iArrowAttrib[i][RED],
		g_iArrowAttrib[i][GREEN],
		g_iArrowAttrib[i][BLUE]);
		
		fputs(iFile, szData);
	}
	
	fclose(iFile);
}

public client_disconnect(id)
{
	if( g_iMenu == id )
	{
		g_iMenu = 0;
	}
}

public cmdArrows(id)
{
	if( get_user_flags(id) & read_flags("a") )
	{
		if( g_iMenu )
		{
			client_print(id, print_center, "Someone already uses the menu");
			
			return PLUGIN_HANDLED;
		}
		
		MainMenu(id);
	}
	
	return PLUGIN_HANDLED;
}

public MainMenu(id)
{
	if( g_iArrow == -1 )
	{
		CreateNewArrow(id);
	}
	
	g_iMenu = id;
	
	new NextMSG[64], NumMSG[64], TitleMSG[128];
	
	formatex(NextMSG, sizeof(NextMSG) - 1, "%s", g_iArrowsNum == 0 ? "\rCreate \dArrow^n":"\rNext \dArrow^n");
	formatex(NumMSG, sizeof(NumMSG) - 1, "\w(\dArrow \y%d\w/\d%d\w)", g_iArrow, g_iArrowsNum);
	formatex(TitleMSG, sizeof(TitleMSG) - 1, "\dArrows Generator\w Main Menu \yby Rap^^^n%s", g_iArrow == 0 ? "\w(New \dArrow\w)":NumMSG);
	
	new iMenu = menu_create(TitleMSG, "MainHandler", 0);
	
	menu_additem(iMenu, NextMSG,			"1");
	menu_additem(iMenu, "\yPosition",		"2");
	menu_additem(iMenu, "\yAppearance^n",		"3");
	menu_additem(iMenu, "Save",			"4");
	menu_additem(iMenu, "Delete",			"5");
	menu_additem(iMenu, "Delete all \dArrows",	"6");
	
	menu_display(id, iMenu, 0);
	
	return PLUGIN_HANDLED;
}

public MainHandler(id, iMenu, item)
{
	if( item == MENU_EXIT )
	{
		g_iMenu = 0;
		g_iArrow = -1;
		
		menu_destroy(iMenu);
		
		return PLUGIN_HANDLED;
	}
	
	new data[6], name[64];
	new _access, callback;
	
	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);
	
	new iKey = str_to_num(data);
	
	switch( iKey )
	{
		case 1:
		{
			if( g_iArrow++ < g_iArrowsNum )
			{
				for( new i = X; i <= Z; i++ )
				{
					g_flArrowCoord[TEMPORARY][i] = g_flArrowCoord[g_iArrow][i];
				}
				
				for( new i = DIRECTION; i <= BLUE; i++ )
				{
					g_iArrowAttrib[TEMPORARY][i] = g_iArrowAttrib[g_iArrow][i];
				}
			}
			
			else
			{
				CreateNewArrow(id);
			}
		}
		
		case 2:
		{
			PositionMenu(id);
			
			return PLUGIN_HANDLED;
		}
		
		case 3:
		{
			AppearanceMenu(id);
			
			return PLUGIN_HANDLED;
		}
		
		case 4:
		{
			if( g_iArrow == 0 )
			{
				if( g_iArrowsNum < MAX_ARROWS )
				{
					g_iArrowsNum++;
					
					for( new i = X; i <= Z; i++ )
					{
						g_flArrowCoord[g_iArrowsNum][i] = g_flArrowCoord[TEMPORARY][i];
					}
					
					for( new i = DIRECTION; i <= BLUE; i++ )
					{
						g_iArrowAttrib[g_iArrowsNum][i] = g_iArrowAttrib[TEMPORARY][i];
					}
					
					client_print(id, print_center, "Arrow #%d saved", g_iArrowsNum);
					
					g_iArrow = g_iArrowsNum;
				}
				
				else
				{
					client_print(id, print_center, "Too much arrows created");
				}
			}
			
			else
			{
				for( new i = X; i <= Z; i++ )
				{
					g_flArrowCoord[g_iArrow][i] = g_flArrowCoord[TEMPORARY][i];
				}
					
				for( new i = DIRECTION; i <= BLUE; i++ )
				{
					g_iArrowAttrib[g_iArrow][i] = g_iArrowAttrib[TEMPORARY][i];
				}
					
				client_print(id, print_center, "Arrow #%d modified", g_iArrow);
			}
		}
		
		case 5:
		{
			if( g_iArrowsNum == 0 )
			{
				client_print(id, print_center, "No Arrow found");
				
				MainMenu(id);
				
				return PLUGIN_HANDLED;
			}
			
			for( new i = g_iArrow; i < g_iArrowsNum; i ++ )
			{
				for( new j = X; j <= Z; j++ )
				{
					g_flArrowCoord[i][j] = g_flArrowCoord[i + 1][j];
				}
				
				for( new j = DIRECTION; j <= BLUE; j++ )
				{
					g_iArrowAttrib[i][j] = g_iArrowAttrib[i + 1][j];
				}
			}
			
			g_iArrowsNum--;
			g_iArrow = 0;
			
			CreateNewArrow(id);
		}
		
		case 6:
		{
			g_iArrow = -1;
			g_iArrowsNum = 0;
		}
	}
	
	MainMenu(id);
	
	return PLUGIN_HANDLED;
}
public PositionMenu(id)
{
	new szAxesMSG[64], szSizeMSG[64], szIncreaseMSG[64], szDecreaseMSG[64];
	
	static const szAxes[ ][ ] = {"X", "Y", "Z"};
	static const szSize[ ][ ] = {"Small", "Medium", "Large"};
	
	formatex(szAxesMSG, sizeof(szAxesMSG) - 1, "Current Axe: \d%s", szAxes[g_iAxe]);
	formatex(szSizeMSG, sizeof(szSizeMSG) - 1, "Increase/Decrease size: \d%s^n", szSize[g_iSize]);
	formatex(szIncreaseMSG, sizeof(szIncreaseMSG) - 1, "Increase \d%s \waxe", szAxes[g_iAxe]);
	formatex(szDecreaseMSG, sizeof(szDecreaseMSG) - 1, "Decrease \d%s \waxe^n", szAxes[g_iAxe]);
	
	new iMenu = menu_create("\dArrows Generator\w Position Menu \yby Rap^^", "PositionHandler", 0);
	
	menu_additem(iMenu, szAxesMSG,				"1");
	menu_additem(iMenu, szSizeMSG,				"2");
	menu_additem(iMenu, "\yCreate \dArrow \yhere^n",	"3");
	menu_additem(iMenu, szIncreaseMSG,			"4");
	menu_additem(iMenu, szDecreaseMSG,			"5");
	menu_additem(iMenu, "Increase \dArrow \wsize",		"6");
	menu_additem(iMenu, "Decrease \dArrow \wsize",		"7");
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu, 0);
	
	return PLUGIN_HANDLED;
}
public PositionHandler(id, iMenu, item)
{
	if( item == MENU_EXIT )
	{
		MainMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	static iSize = 1;
	
	new data[6], name[64];
	new _access, callback;
	
	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);
	
	new iKey = str_to_num(data);
	
	switch( iKey )
	{
		case 1:
		{
			if( g_iAxe++ == 2 )
			{
				g_iAxe = 0;
			}
		}
		
		case 2:
		{
			switch( ++g_iSize )
			{
				case 1:
				{
					iSize = 10;
				}
				
				case 2:
				{
					iSize = 50;
				}
				
				case 3:
				{
					iSize = 1;
					g_iSize = 0;
				}
			}
		}
		
		case 3:
		{
			pev(id, pev_origin, g_flArrowCoord[TEMPORARY]);
		}
		
		case 4:
		{
			g_flArrowCoord[TEMPORARY][g_iAxe] += iSize;
		}
		
		case 5:
		{
			g_flArrowCoord[TEMPORARY][g_iAxe] -= iSize;
		}
		
		case 6:
		{
			g_iArrowAttrib[TEMPORARY][SIZE] += iSize;
		}
		
		case 7:
		{
			g_iArrowAttrib[TEMPORARY][SIZE] -= iSize;
			
			if( g_iArrowAttrib[TEMPORARY][SIZE] <= 0 )
			{
				g_iArrowAttrib[TEMPORARY][SIZE] = 1;
			}
		}
	}
	
	PositionMenu(id);
	
	return PLUGIN_HANDLED;
}
public AppearanceMenu(id)
{
	new szDirectionMSG[32], szWayMSG[32], szColorsMSG[32], szRedMSG[32], szGreenMSG[32], szBlueMSG[32], szIncrMSG[32];
	
	static const szDirection[ ][ ] =	{"D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12"};
	static const szWay[ ][ ] =	{"W1", "W2"};
	static const szColors[ ][ ] =	{"Custom", "White", "Red", "Green", "Blue", "Yellow", "Cyan", "Pink", "Grey"};
	static const szIncr[ ][ ] =	{"1", "10", "50"};
	
	formatex(szDirectionMSG, sizeof(szDirectionMSG) - 1, "\yDirection: \d%s", szDirection[g_iArrowAttrib[TEMPORARY][DIRECTION]]);
	formatex(szWayMSG, sizeof(szWayMSG) - 1, "\yWay: \d%s^n", szWay[g_iArrowAttrib[TEMPORARY][WAY]]);
	formatex(szColorsMSG, sizeof(szColorsMSG) - 1, "\rColor: \d%s^n", szColors[g_iArrowAttrib[TEMPORARY][COLOR]]);
	formatex(szRedMSG, sizeof(szRedMSG) - 1, "Red: \d%d", g_iArrowAttrib[TEMPORARY][RED]);
	formatex(szGreenMSG, sizeof(szGreenMSG) - 1, "Green: \d%d", g_iArrowAttrib[TEMPORARY][GREEN]);
	formatex(szBlueMSG, sizeof(szBlueMSG) - 1, "Blue: \d%d^n", g_iArrowAttrib[TEMPORARY][BLUE]);
	formatex(szIncrMSG, sizeof(szIncrMSG) - 1, "Increase color size: \d%s", szIncr[g_iColor]);
	
	new iMenu = menu_create("\dArrows Generator\w Appearance Menu \yby Rap^^", "AppearanceHandler", 0);
	
	menu_additem(iMenu, szDirectionMSG,	"1");
	menu_additem(iMenu, szWayMSG,		"2");
	menu_additem(iMenu, szColorsMSG,	"3");
	menu_additem(iMenu, szRedMSG,		"4");
	menu_additem(iMenu, szGreenMSG,		"5");
	menu_additem(iMenu, szBlueMSG,		"6");
	menu_additem(iMenu, szIncrMSG,		"7");
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Back");
	
	menu_display(id, iMenu, 0);
	
	return PLUGIN_HANDLED;
}
public AppearanceHandler(id, iMenu, item)
{
	if( item == MENU_EXIT )
	{
		MainMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	static iSize = 1;
	
	new data[6], name[64];
	new _access, callback;
	
	menu_item_getinfo(iMenu, item, _access, data, 5, name, 63, callback);
	
	new iKey = str_to_num(data);
	
	switch( iKey )
	{
		case 1:
		{
			if( g_iArrowAttrib[TEMPORARY][DIRECTION]++ == 11 )
			{
				g_iArrowAttrib[TEMPORARY][DIRECTION] = 0;
			}
		}
		
		case 2:
		{
			if( g_iArrowAttrib[TEMPORARY][WAY]++ == 1 )
			{
				g_iArrowAttrib[TEMPORARY][WAY] = 0;
			}
		}
		
		case 3:
		{
			switch( ++g_iArrowAttrib[TEMPORARY][COLOR] )
			{
				case 2:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 255;
					g_iArrowAttrib[TEMPORARY][GREEN] = 0;
					g_iArrowAttrib[TEMPORARY][BLUE] = 0;
				}
				
				case 3:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 0;
					g_iArrowAttrib[TEMPORARY][GREEN] = 255;
					g_iArrowAttrib[TEMPORARY][BLUE] = 0;
				}
				
				case 4:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 0;
					g_iArrowAttrib[TEMPORARY][GREEN] = 0;
					g_iArrowAttrib[TEMPORARY][BLUE] = 255;
				}
				
				case 5:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 255;
					g_iArrowAttrib[TEMPORARY][GREEN] = 255;
					g_iArrowAttrib[TEMPORARY][BLUE] = 0;
				}
				
				case 6:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 0;
					g_iArrowAttrib[TEMPORARY][GREEN] = 255;
					g_iArrowAttrib[TEMPORARY][BLUE] = 255;
				}
				
				case 7:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 255;
					g_iArrowAttrib[TEMPORARY][GREEN] = 0;
					g_iArrowAttrib[TEMPORARY][BLUE] = 255;
				}
				
				case 8:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 192;
					g_iArrowAttrib[TEMPORARY][GREEN] = 192;
					g_iArrowAttrib[TEMPORARY][BLUE] = 192;
				}
				
				case 9:
				{
					g_iArrowAttrib[TEMPORARY][RED] = 255;
					g_iArrowAttrib[TEMPORARY][GREEN] = 255;
					g_iArrowAttrib[TEMPORARY][BLUE] = 255;
					g_iArrowAttrib[TEMPORARY][COLOR] = 1;
				}
			}
		}
		
		case 4:
		{
			if( (g_iArrowAttrib[TEMPORARY][RED] += iSize) > 255 )
			{
				g_iArrowAttrib[TEMPORARY][RED] = 0;
			}
			
			g_iArrowAttrib[TEMPORARY][COLOR] = 0;
		}
		
		case 5:
		{
			if( (g_iArrowAttrib[TEMPORARY][GREEN] += iSize) > 255 )
			{
				g_iArrowAttrib[TEMPORARY][GREEN] = 0;
			}
			
			g_iArrowAttrib[TEMPORARY][COLOR] = 0;
		}
		
		case 6:
		{
			if( (g_iArrowAttrib[TEMPORARY][BLUE] += iSize) > 255 )
			{
				g_iArrowAttrib[TEMPORARY][BLUE] = 0;
			}
			
			g_iArrowAttrib[TEMPORARY][COLOR] = 0;
		}
		
		case 7:
		{
			switch( ++g_iColor )
			{
				case 1:
				{
					iSize = 10;
				}
				
				case 2:
				{
					iSize = 50;
				}
				
				case 3:
				{
					iSize = 1;
					g_iColor = 0;
				}
			}
		}
	}
	
	AppearanceMenu(id);
	
	return PLUGIN_HANDLED;
}
public CreateNewArrow(id)
{
	pev(id, pev_origin, g_flArrowCoord[TEMPORARY]);
				
	g_iArrowAttrib[TEMPORARY][DIRECTION] = 0;
	g_iArrowAttrib[TEMPORARY][WAY] = 0;
	g_iArrowAttrib[TEMPORARY][SIZE] = 40;
	g_iArrowAttrib[TEMPORARY][COLOR] = 1;
	g_iArrowAttrib[TEMPORARY][RED] = 255;
	g_iArrowAttrib[TEMPORARY][GREEN] = 255;
	g_iArrowAttrib[TEMPORARY][BLUE] = 255;
	
	g_iArrow = 0;
	
	client_print(id, print_center, "New Arrow created");
	
	StartTask( );
}
public StartTask( )
{
	if( !task_exists(TASK_DRAW) )
	{
		set_task(0.8, "DrawArrows", TASK_DRAW, _, _, "b");
	}
}
public DrawArrows(TASK)
{
	new Float: flPoint0[3];
	new Float: flPoint1[3];
	new Float: flPoint2[3];
	new Float: flPoint3[3];
	new Float: flPoint4[3];
	new Float: flLenght, Float: flPiece, Float: flAngle;
	new iDirection, iWay, iLenght, iPiece, iAngle, iColors[3];
	
	for( new i = 0; i <= g_iArrowsNum; i++ )
	{
		if( (g_iArrow > TEMPORARY && i == g_iArrow) || (i == TEMPORARY && !g_iMenu) )
		{
			continue;
		}
		
		flPoint0[0] = g_flArrowCoord[i][0];
		flPoint0[1] = g_flArrowCoord[i][1];
		flPoint0[2] = g_flArrowCoord[i][2];
		
		iDirection = g_iArrowAttrib[i][DIRECTION];
		iWay = g_iArrowAttrib[i][WAY];
		
		iLenght = g_iArrowAttrib[i][SIZE];
		iPiece = (iLenght / 3) / 2;
		iAngle = (iLenght / 3) * 2;
		
		flLenght = (iLenght + iPiece) / 1.4;
		flPiece = (iLenght - iAngle) / 1.4;
		flAngle = ((iLenght - iPiece) * 1.4);
		
		iColors[0] = g_iArrowAttrib[i][RED];
		iColors[1] = g_iArrowAttrib[i][GREEN];
		iColors[2] = g_iArrowAttrib[i][BLUE];
		
		switch( iWay )
		{
			case 0:
			{
				switch( iDirection )
				{
					case 0:
					{
						flPoint1[0] = flPoint0[0] + iPiece + iLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] - iPiece - iLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0] + iPiece;
						flPoint3[1] = flPoint0[1] - iAngle;
						flPoint3[2] = flPoint0[2];
						
						flPoint4[0] = flPoint0[0] + iPiece;
						flPoint4[1] = flPoint0[1] + iAngle;
						flPoint4[2] = flPoint0[2];
					}
					
					case 1:
					{
						flPoint1[0] = flPoint0[0] + iPiece + iLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] - iPiece - iLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0] + iPiece;
						flPoint3[1] = flPoint0[1];
						flPoint3[2] = flPoint0[2] - iAngle;
						
						flPoint4[0] = flPoint0[0] + iPiece;
						flPoint4[1] = flPoint0[1];
						flPoint4[2] = flPoint0[2] + iAngle;
					}
					
					case 2:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] + iPiece + iLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] - iPiece - iLenght;
						
						flPoint3[0] = flPoint0[0] - iAngle;
						flPoint3[1] = flPoint0[1];
						flPoint3[2] = flPoint0[2] + iPiece;
						
						flPoint4[0] = flPoint0[0] + iAngle;
						flPoint4[1] = flPoint0[1];
						flPoint4[2] = flPoint0[2] + iPiece;
					}
					
					case 3:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] + iPiece + iLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] - iPiece - iLenght;
						
						flPoint3[0] = flPoint0[0];
						flPoint3[1] = flPoint0[1] - iAngle;
						flPoint3[2] = flPoint0[2] + iPiece;
						
						flPoint4[0] = flPoint0[0];
						flPoint4[1] = flPoint0[1] + iAngle;
						flPoint4[2] = flPoint0[2] + iPiece;
					}
					
					case 4:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] + iPiece + iLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] - iPiece - iLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0] - iAngle;
						flPoint3[1] = flPoint0[1] + iPiece;
						flPoint3[2] = flPoint0[2];
						
						flPoint4[0] = flPoint0[0] + iAngle;
						flPoint4[1] = flPoint0[1] + iPiece;
						flPoint4[2] = flPoint0[2];
					}
					
					case 5:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] + iPiece + iLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] - iPiece - iLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0];
						flPoint3[1] = flPoint0[1] + iPiece;
						flPoint3[2] = flPoint0[2] - iAngle;
						
						flPoint4[0] = flPoint0[0];
						flPoint4[1] = flPoint0[1] + iPiece;
						flPoint4[2] = flPoint0[2] + iAngle;
					}
					
					case 6:
					{
						flPoint1[0] = flPoint0[0] + flLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] - flLenght;
						
						flPoint2[0] = flPoint0[0] - flLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] + flLenght;
						
						flPoint3[0] = flPoint1[0] - flAngle;
						flPoint3[1] = flPoint1[1];
						flPoint3[2] = flPoint1[2] + flPiece;
						
						flPoint4[0] = flPoint1[0] - flPiece;
						flPoint4[1] = flPoint1[1];
						flPoint4[2] = flPoint1[2] + flAngle;
					}
					
					case 7:
					{
						flPoint1[0] = flPoint0[0] + flLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] + flLenght;
						
						flPoint2[0] = flPoint0[0] - flLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] - flLenght;
						
						flPoint3[0] = flPoint1[0] - flAngle;
						flPoint3[1] = flPoint1[1];
						flPoint3[2] = flPoint1[2] - flPiece;
						
						flPoint4[0] = flPoint1[0] - flPiece;
						flPoint4[1] = flPoint1[1];
						flPoint4[2] = flPoint1[2] - flAngle;
					}
					
					case 8:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] + flLenght;
						flPoint1[2] = flPoint0[2] + flLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] - flLenght;
						flPoint2[2] = flPoint0[2] - flLenght;
						
						flPoint3[0] = flPoint1[0];
						flPoint3[1] = flPoint1[1] - flAngle;
						flPoint3[2] = flPoint1[2] - flPiece;
						
						flPoint4[0] = flPoint1[0];
						flPoint4[1] = flPoint1[1] - flPiece;
						flPoint4[2] = flPoint1[2] - flAngle;
					}
					
					case 9:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] - flLenght;
						flPoint1[2] = flPoint0[2] + flLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] + flLenght;
						flPoint2[2] = flPoint0[2] - flLenght;
						
						flPoint3[0] = flPoint1[0];
						flPoint3[1] = flPoint1[1] + flAngle;
						flPoint3[2] = flPoint1[2] - flPiece;
						
						flPoint4[0] = flPoint1[0];
						flPoint4[1] = flPoint1[1] + flPiece;
						flPoint4[2] = flPoint1[2] - flAngle;
					}
					
					case 10:
					{
						flPoint1[0] = flPoint0[0] + flLenght;
						flPoint1[1] = flPoint0[1] + flLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] - flLenght;
						flPoint2[1] = flPoint0[1] - flLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint1[0] - flPiece;
						flPoint3[1] = flPoint1[1] - flAngle;
						flPoint3[2] = flPoint1[2];
						
						flPoint4[0] = flPoint1[0] - flAngle;
						flPoint4[1] = flPoint1[1] - flPiece;
						flPoint4[2] = flPoint1[2];
					}
					
					case 11:
					{
						flPoint1[0] = flPoint0[0] + flLenght;
						flPoint1[1] = flPoint0[1] - flLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] - flLenght;
						flPoint2[1] = flPoint0[1] + flLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint1[0] - flPiece;
						flPoint3[1] = flPoint1[1] + flAngle;
						flPoint3[2] = flPoint1[2];
						
						flPoint4[0] = flPoint1[0] - flAngle;
						flPoint4[1] = flPoint1[1] + flPiece;
						flPoint4[2] = flPoint1[2];
					}
				}
			}
			
			case 1:
			{
				switch( iDirection )
				{
					case 0:
					{
						flPoint1[0] = flPoint0[0] - iPiece - iLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] + iPiece + iLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0] - iPiece;
						flPoint3[1] = flPoint0[1] - iAngle;
						flPoint3[2] = flPoint0[2];
						
						flPoint4[0] = flPoint0[0] - iPiece;
						flPoint4[1] = flPoint0[1] + iAngle;
						flPoint4[2] = flPoint0[2];
					}
					
					case 1:
					{
						flPoint1[0] = flPoint0[0] - iPiece - iLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] + iPiece + iLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0] - iPiece;
						flPoint3[1] = flPoint0[1];
						flPoint3[2] = flPoint0[2] - iAngle;
						
						flPoint4[0] = flPoint0[0] - iPiece;
						flPoint4[1] = flPoint0[1];
						flPoint4[2] = flPoint0[2] + iAngle;
					}
					
					case 2:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] - iPiece - iLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] + iPiece + iLenght;
						
						flPoint3[0] = flPoint0[0] - iAngle;
						flPoint3[1] = flPoint0[1];
						flPoint3[2] = flPoint0[2] - iPiece;
						
						flPoint4[0] = flPoint0[0] + iAngle;
						flPoint4[1] = flPoint0[1];
						flPoint4[2] = flPoint0[2] - iPiece;
					}
					
					case 3:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] - iPiece - iLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] + iPiece + iLenght;
						
						flPoint3[0] = flPoint0[0];
						flPoint3[1] = flPoint0[1] - iAngle;
						flPoint3[2] = flPoint0[2] - iPiece;
						
						flPoint4[0] = flPoint0[0];
						flPoint4[1] = flPoint0[1] + iAngle;
						flPoint4[2] = flPoint0[2] - iPiece;
					}
					
					case 4:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] - iPiece - iLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] + iPiece + iLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0] - iAngle;
						flPoint3[1] = flPoint0[1] - iPiece;
						flPoint3[2] = flPoint0[2];
						
						flPoint4[0] = flPoint0[0] + iAngle;
						flPoint4[1] = flPoint0[1] - iPiece;
						flPoint4[2] = flPoint0[2];
					}
					
					case 5:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] - iPiece - iLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] + iPiece + iLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint0[0];
						flPoint3[1] = flPoint0[1] - iPiece;
						flPoint3[2] = flPoint0[2] - iAngle;
						
						flPoint4[0] = flPoint0[0];
						flPoint4[1] = flPoint0[1] - iPiece;
						flPoint4[2] = flPoint0[2] + iAngle;
					}
					
					case 6:
					{
						flPoint1[0] = flPoint0[0] - flLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] + flLenght;
						
						flPoint2[0] = flPoint0[0] + flLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] - flLenght;
						
						flPoint3[0] = flPoint1[0] + flAngle;
						flPoint3[1] = flPoint1[1];
						flPoint3[2] = flPoint1[2] - flPiece;
						
						flPoint4[0] = flPoint1[0] + flPiece;
						flPoint4[1] = flPoint1[1];
						flPoint4[2] = flPoint1[2] - flAngle;
					}
					
					case 7:
					{
						flPoint1[0] = flPoint0[0] - flLenght;
						flPoint1[1] = flPoint0[1];
						flPoint1[2] = flPoint0[2] - flLenght;
						
						flPoint2[0] = flPoint0[0] + flLenght;
						flPoint2[1] = flPoint0[1];
						flPoint2[2] = flPoint0[2] + flLenght;
						
						flPoint3[0] = flPoint1[0] + flAngle;
						flPoint3[1] = flPoint1[1];
						flPoint3[2] = flPoint1[2] + flPiece;
						
						flPoint4[0] = flPoint1[0] + flPiece;
						flPoint4[1] = flPoint1[1];
						flPoint4[2] = flPoint1[2] + flAngle;
					}
					
					case 8:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] - flLenght;
						flPoint1[2] = flPoint0[2] - flLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] + flLenght;
						flPoint2[2] = flPoint0[2] + flLenght;
						
						flPoint3[0] = flPoint1[0];
						flPoint3[1] = flPoint1[1] + flAngle;
						flPoint3[2] = flPoint1[2] + flPiece;
						
						flPoint4[0] = flPoint1[0];
						flPoint4[1] = flPoint1[1] + flPiece;
						flPoint4[2] = flPoint1[2] + flAngle;
					}
					
					case 9:
					{
						flPoint1[0] = flPoint0[0];
						flPoint1[1] = flPoint0[1] + flLenght;
						flPoint1[2] = flPoint0[2] - flLenght;
						
						flPoint2[0] = flPoint0[0];
						flPoint2[1] = flPoint0[1] - flLenght;
						flPoint2[2] = flPoint0[2] + flLenght;
						
						flPoint3[0] = flPoint1[0];
						flPoint3[1] = flPoint1[1] - flAngle;
						flPoint3[2] = flPoint1[2] + flPiece;
						
						flPoint4[0] = flPoint1[0];
						flPoint4[1] = flPoint1[1] - flPiece;
						flPoint4[2] = flPoint1[2] + flAngle;
					}
					
					case 10:
					{
						flPoint1[0] = flPoint0[0] - flLenght;
						flPoint1[1] = flPoint0[1] - flLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] + flLenght;
						flPoint2[1] = flPoint0[1] + flLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint1[0] + flPiece;
						flPoint3[1] = flPoint1[1] + flAngle;
						flPoint3[2] = flPoint1[2];
						
						flPoint4[0] = flPoint1[0] + flAngle;
						flPoint4[1] = flPoint1[1] + flPiece;
						flPoint4[2] = flPoint1[2];
					}
					
					case 11:
					{
						flPoint1[0] = flPoint0[0] - flLenght;
						flPoint1[1] = flPoint0[1] + flLenght;
						flPoint1[2] = flPoint0[2];
						
						flPoint2[0] = flPoint0[0] + flLenght;
						flPoint2[1] = flPoint0[1] - flLenght;
						flPoint2[2] = flPoint0[2];
						
						flPoint3[0] = flPoint1[0] + flPiece;
						flPoint3[1] = flPoint1[1] - flAngle;
						flPoint3[2] = flPoint1[2];
						
						flPoint4[0] = flPoint1[0] + flAngle;
						flPoint4[1] = flPoint1[1] - flPiece;
						flPoint4[2] = flPoint1[2];
					}
				}
			}
		}
		
		DrawLine(flPoint1, flPoint2, iColors);
		DrawLine(flPoint1, flPoint3, iColors);
		DrawLine(flPoint1, flPoint4, iColors);
	}
}
public FX_Line(iStart[3], iStop[3], iColor[3], iBrightness)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY) ;
	
	write_byte(TE_BEAMPOINTS) ;
	
	write_coord(iStart[0]) ;
	write_coord(iStart[1]);
	write_coord(iStart[2]);
	
	write_coord(iStop[0]);
	write_coord(iStop[1]);
	write_coord(iStop[2]);
	
	write_short(iSprite);
	
	write_byte(1);
	write_byte(1);
	write_byte(10);
	write_byte(5);
	write_byte(0);
	
	write_byte(iColor[0]);
	write_byte(iColor[1]);
	write_byte(iColor[2]);
	
	write_byte(iBrightness);
	write_byte(0);
	
	message_end( );
}
public DrawLine(Float: flStart[3], Float: flEnd[3], iColor[3])
{
	new iStart[3];
	new iEnd[3];
	
	iStart[0] = floatround(flStart[0]);
	iStart[1] = floatround(flStart[1]);
	iStart[2] = floatround(flStart[2]);
	
	iEnd[0] = floatround(flEnd[0]);
	iEnd[1] = floatround(flEnd[1]);
	iEnd[2] = floatround(flEnd[2]);

	FX_Line(iStart, iEnd, iColor, 200);
}
