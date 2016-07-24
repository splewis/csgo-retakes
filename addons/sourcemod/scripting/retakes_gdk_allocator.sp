#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include "include/retakes.inc"
#include "retakes/generic.sp"

#pragma semicolon 1

#define MENU_TIME_LENGTH 15

public Plugin myinfo = 
{
    name = "CS:GO Retakes: Gdk's alternate weapon allocator",
    author = "Gdk",
    description = "Alternate weapon allocator for splewis retakes plugin",
    version = "1.2.5",
    url = "TopSecretGaming.net"
};

// Prices
int g_nade_price_hegrenade = 300;
int g_nade_price_flashbang = 200;
int g_nade_price_smokegrenade = 500;
int g_nade_price_molotov = 400;
int g_nade_price_incgrenade = 600;
int g_nade_price_decoy = 50;
int g_gun_price_p250 = 300;
int g_gun_price_cz = 500;
int g_gun_price_fiveseven = 500;
int g_gun_price_tec9 = 500;
int g_gun_price_deagle = 700;
int g_gun_price_elite = 500;
int g_kevlar_price = 650;

// Nades
int g_hegrenade_ct_count = 0;
int g_hegrenade_t_count = 0;
int g_flashbang_ct_count = 0;
int g_flashbang_t_count = 0;
int g_smokegrenade_ct_count = 0;
int g_smokegrenade_t_count = 0;
int g_molotov_ct_count = 0;
int g_molotov_t_count = 0;
int g_decoy_ct_count = 0;
int g_decoy_t_count = 0;

// Guns
int  g_ct_pistol[MAXPLAYERS+1];
int  g_ct_sidearm[MAXPLAYERS+1];
int  g_t_pistol[MAXPLAYERS+1];
int  g_t_sidearm[MAXPLAYERS+1];
int  g_awp[MAXPLAYERS+1];
bool g_silenced_m4[MAXPLAYERS+1];
bool g_taser[MAXPLAYERS+1];

// Cookies
Handle g_ct_pistol_cookie = INVALID_HANDLE;
Handle g_t_pistol_cookie = INVALID_HANDLE;
Handle g_ct_sidearm_cookie = INVALID_HANDLE;
Handle g_t_sidearm_cookie = INVALID_HANDLE;
Handle g_m4_cookie = INVALID_HANDLE;
Handle g_awp_cookie = INVALID_HANDLE;
Handle g_taser_cookie = INVALID_HANDLE;

// Convars
Handle g_advertise_pistol_menu = INVALID_HANDLE;
Handle g_hegrenade_ct_max = INVALID_HANDLE;
Handle g_hegrenade_t_max = INVALID_HANDLE;
Handle g_flashbang_ct_max = INVALID_HANDLE;
Handle g_flashbang_t_max = INVALID_HANDLE;
Handle g_smokegrenade_ct_max = INVALID_HANDLE;
Handle g_smokegrenade_t_max = INVALID_HANDLE;
Handle g_molotov_ct_max = INVALID_HANDLE;
Handle g_molotov_t_max = INVALID_HANDLE;
Handle g_decoy_ct_max = INVALID_HANDLE;
Handle g_decoy_t_max = INVALID_HANDLE;
Handle g_awp_ct_max = INVALID_HANDLE;
Handle g_awp_t_max = INVALID_HANDLE;
Handle g_pistolrounds  = INVALID_HANDLE;
Handle g_deagle_enabled  = INVALID_HANDLE;
Handle g_cz_enabled  = INVALID_HANDLE;
Handle g_p250_enabled  = INVALID_HANDLE;
Handle g_tec9_enabled = INVALID_HANDLE;
Handle g_fiveseven_enabled = INVALID_HANDLE;
Handle g_dual_elite_enabled = INVALID_HANDLE;
Handle g_revolver_enabled = INVALID_HANDLE;


public void OnPluginStart() 
{
	g_ct_pistol_cookie = RegClientCookie("retakes_ct_pistol", "", CookieAccess_Private);
	g_ct_sidearm_cookie = RegClientCookie("retakes_ct_sidearm", "", CookieAccess_Private);
    	g_t_pistol_cookie = RegClientCookie("retakes_t_pistol", "", CookieAccess_Private);
	g_t_sidearm_cookie = RegClientCookie("retakes_t_sidearm", "", CookieAccess_Private);
    	g_m4_cookie  = RegClientCookie("retakes_m4", "", CookieAccess_Private);
    	g_awp_cookie = RegClientCookie("retakes_awp", "", CookieAccess_Private);
	g_taser_cookie = RegClientCookie("retakes_taser", "", CookieAccess_Public);


    	RegConsoleCmd("sm_guns", Command_GunsMenu, "Opens the retakes primary weapons menu");
	RegConsoleCmd("sm_pistols", Command_PistolsMenu, "Opens the retakes seconday weapons menu");

    	//convars
    	g_pistolrounds = CreateConVar(		"sm_retakes_pistolrounds", "5", "The number of pistol rounds (0 = no pistol round)");
	g_advertise_pistol_menu = CreateConVar(	"sm_retakes_advertise_pistol_menu", "1", "Advertise pistol menu after guns menu displayed? \n0=no, 1=yes, 2=Always display pistol menu");
    	g_hegrenade_ct_max = CreateConVar(	"sm_retakes_hegrenade_ct_max", "1", "Max hegrenade CT team can have");
    	g_hegrenade_t_max = CreateConVar(	"sm_retakes_hegrenade_t_max", "1", "Max hegrenade T team can have");
    	g_flashbang_ct_max = CreateConVar(	"sm_retakes_flashbang_ct_max", "2", "Max flashbang CT team can have");
    	g_flashbang_t_max = CreateConVar(	"sm_retakes_flashbang_t_max", "1", "Max flashbang T team can have");
    	g_smokegrenade_ct_max = CreateConVar(	"sm_retakes_smokegrenade_ct_max", "1", "Max smokegrenade CT team can have");
    	g_smokegrenade_t_max = CreateConVar(	"sm_retakes_smokegrenade_t_max", "1", "Max smokegrenade T team can have");
    	g_molotov_ct_max = CreateConVar(	"sm_retakes_molotov_ct_max", "1", "Max molotov CT team can have");
    	g_molotov_t_max = CreateConVar(		"sm_retakes_molotov_t_max", "1", "Max molotov T team can have");
    	g_decoy_ct_max = CreateConVar(		"sm_retakes_decoy_ct_max", "1", "Max decoys CT team can have");
    	g_decoy_t_max = CreateConVar(		"sm_retakes_decoy_t_max", "1", "Max decoys T team can have");
	g_awp_ct_max = CreateConVar(		"sm_retakes_awp_ct_max", "1", "Max AWP CT team can have");
	g_awp_t_max = CreateConVar(		"sm_retakes_awp_t_max", "1", "Max AWP T team can have");
    	g_deagle_enabled = CreateConVar(	"sm_retakes_deagle_enabled", "1", "Whether players can choose deagle");
    	g_cz_enabled = CreateConVar(		"sm_retakes_cz_enabled", "1", "Whether players can choose CZ");
    	g_p250_enabled = CreateConVar(		"sm_retakes_p250_enabled", "1", "Whether the players can choose P250");
    	g_tec9_enabled = CreateConVar(		"sm_retakes_tec9_enabled", "1", "Whether players can choose Tec9");
	g_fiveseven_enabled = CreateConVar(	"sm_retakes_fiveseven_enabled", "1", "Whether players can choose Five seven");
    	g_dual_elite_enabled = CreateConVar(	"sm_retakes_dual_elite_enabled", "1", "Whether players can choose Dual Elite");
    	g_revolver_enabled  = CreateConVar(	"sm_retakes_revolver_enabled", "1", "Whether players can choose Revolver");

    	AutoExecConfig(true, "retakes_gdk_allocator", "sourcemod/retakes");
}

public Action Command_GunsMenu(int client, int args) 
{
	GiveM4Menu(client);
	return Plugin_Handled;
}

public Action Command_PistolsMenu(int client, int args) 
{
	if (GetConVarInt(g_p250_enabled) || GetConVarInt(g_tec9_enabled) || GetConVarInt(g_fiveseven_enabled) || 
	GetConVarInt(g_cz_enabled) || GetConVarInt(g_dual_elite_enabled) || GetConVarInt(g_deagle_enabled))
	{
		GiveCTPistolMenu(client);
	}
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	char gunsChatCommands[][] = {"gun", "guns", ".gun", ".guns", ".setup", "!gun", "gnus", "primary", "!primary"};
	for (int i = 0; i < sizeof(gunsChatCommands); i++) 
	{
		if (StrEqual(args[0], gunsChatCommands[i], false))
		GiveM4Menu(client);
	}
	
	char pistolsChatCommands[][] = {"pistol", "pistols", ".pistol", ".pistols", "secondary", "!secondary", "!pistol", "/pistol"};
	for (int i = 0; i < sizeof(pistolsChatCommands); i++) 
	{
		if (StrEqual(args[0], pistolsChatCommands[i], false))
		{
			if (GetConVarInt(g_p250_enabled) || GetConVarInt(g_tec9_enabled) || GetConVarInt(g_fiveseven_enabled) || 
			GetConVarInt(g_cz_enabled) || GetConVarInt(g_dual_elite_enabled) || GetConVarInt(g_deagle_enabled))
			{
				GiveCTPistolMenu(client);
			}
		}
	}
	return Plugin_Continue;
}

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) 
{
    WeaponAllocator(tPlayers, ctPlayers, bombsite);
}

/**
 * Updates client weapon settings according to their cookies.
 */
public void OnClientCookiesCached(int client) 
{
	if (IsFakeClient(client))
        	return;

	if(!GetClientCookieTime(client, g_ct_pistol_cookie))
	{
		SetCookieInt(client, g_ct_pistol_cookie, 1);
	}
	if(!GetClientCookieTime(client, g_t_pistol_cookie))
	{
		SetCookieInt(client, g_t_pistol_cookie, 1);
	}
	if(!GetClientCookieTime(client, g_ct_sidearm_cookie))
	{
		SetCookieInt(client, g_ct_sidearm_cookie, 6);
	}
	if(!GetClientCookieTime(client, g_t_sidearm_cookie))
	{
		SetCookieInt(client, g_t_sidearm_cookie, 6);
	}
	if(!GetClientCookieTime(client, g_m4_cookie))
	{
		SetCookieInt(client, g_m4_cookie, 0);
	}
	if(!GetClientCookieTime(client, g_awp_cookie))
	{
		SetCookieInt(client, g_awp_cookie, 1);
	}
	if(!GetClientCookieTime(client, g_taser_cookie))
	{
		SetCookieInt(client, g_taser_cookie, 1);
	}

    	g_ct_pistol[client] = GetCookieInt (client, g_ct_pistol_cookie);
	g_t_pistol[client] = GetCookieInt (client, g_t_pistol_cookie);
	g_ct_sidearm[client] = GetCookieInt (client, g_ct_sidearm_cookie);
	g_t_sidearm[client] = GetCookieInt (client, g_t_sidearm_cookie);
	g_silenced_m4[client] = GetCookieBool (client, g_m4_cookie);
	g_awp[client] = GetCookieInt (client, g_awp_cookie);
	g_taser[client] = GetCookieBool (client, g_taser_cookie);
}

public void WeaponAllocator(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) 
{
    	int tCount = GetArraySize(tPlayers);
    	int ctCount = GetArraySize(ctPlayers);

	g_hegrenade_ct_count = 0;
	g_hegrenade_t_count = 0;
	g_flashbang_ct_count = 0;
	g_flashbang_t_count = 0;
	g_smokegrenade_ct_count = 0;
	g_smokegrenade_t_count = 0;
	g_molotov_ct_count = 0;
	g_molotov_t_count = 0;
	g_decoy_ct_count = 0;
	g_decoy_t_count = 0;

    	bool isPistolRound = Retakes_GetRetakeRoundsPlayed() < GetConVarInt(g_pistolrounds);

    	char primary[WEAPON_STRING_LENGTH];
    	char secondary[WEAPON_STRING_LENGTH];
    	char nades[NADE_STRING_LENGTH];

    	int health = 100;
    	int kevlar = 100;
    	bool helmet = true;
    	bool kit = true;
    	int numkits = 0;
    	int odds = 0;
	int t_awp_given = 0;
    	int ct_awp_given = 0;
    	int pistol_round_dollars = 800;

	// Admins
	int num_t_admin_awps = 0;
	int num_ct_admin_awps = 0;
	int t_rand_admin_awp = 0;
	int ct_rand_admin_awp = 0;
	int t_admin_awp[MAXPLAYERS+1];
	int ct_admin_awp[MAXPLAYERS+1];

//T players

	//Count t admins for priority awp
	for (int i = 0; i < tCount; i++) 
	{
		int client = GetArrayCell(tPlayers, i);
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			if(g_awp[client] == 1)
			{
				int rand = GetRandomInt(1, 3);
				if(rand == 1)
				{
					num_t_admin_awps++;
					t_admin_awp[client] = num_t_admin_awps;
				}
			}
			else if(g_awp[client] == 2)
			{
				num_t_admin_awps++;
				t_admin_awp[client] = num_t_admin_awps;
			}		
		}
	}

	//Chose which t admin gets awp
	t_rand_admin_awp = GetRandomInt(1, num_t_admin_awps);

    	for (int i = 0; i < tCount; i++) 
	{
        	int client = GetArrayCell(tPlayers, i);
      		pistol_round_dollars = 800;
		primary = "";

//T gun round primary
        	if (!isPistolRound)
        	{
            		int randGiveAwp = GetRandomInt(1, 3);
			
			kit = false;
			kevlar = 100;
			helmet = true;
			health = 100;

			if (GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				if(t_admin_awp[client] == t_rand_admin_awp && t_awp_given < GetConVarInt(g_awp_t_max))
				{
					primary = "weapon_awp";
					t_awp_given++;
				}
				else 
				{
                			primary = "weapon_ak47";
            			}
					
			}
            		else if (g_awp[client] == 1 && randGiveAwp && t_awp_given < GetConVarInt(g_awp_t_max) && num_t_admin_awps < 1) 
			{
                		primary = "weapon_awp";
				t_awp_given++;
            		} 
			else 
			{
                		primary = "weapon_ak47";
            		}
			
//T Gun round pistols
			if (g_t_sidearm[client] == 2 && GetConVarInt(g_p250_enabled))
        		{
				secondary = "weapon_p250";
			}
			else if (g_t_sidearm[client] == 3 && GetConVarInt(g_tec9_enabled))
        		{
            			secondary = "weapon_tec9";
        		}
        		else if (g_t_sidearm[client] == 4 && GetConVarInt(g_cz_enabled))
        		{
            			secondary = "weapon_cz75a";
        		}
        		else if (g_t_sidearm[client] == 5 && GetConVarInt(g_revolver_enabled))
			{
				secondary = "weapon_revolver";
        		}
			else if (g_t_sidearm[client] == 6 && GetConVarInt(g_deagle_enabled))
			{
				secondary = "weapon_deagle";
        		}
			else if (g_t_sidearm[client] == 7 && GetConVarInt(g_dual_elite_enabled))
			{
				secondary = "weapon_elite";
			}		
			else
			{
				secondary = "weapon_glock";
			}
        	}
		
//T Pistol round
		if(isPistolRound)
		{
        		kit = false;
			helmet = false;
			health = 100;
			kevlar = 0;

			if (g_t_pistol[client] == 2 && GetConVarInt(g_p250_enabled) == 1)
        		{
            			secondary = "weapon_p250";
            			pistol_round_dollars = pistol_round_dollars - g_gun_price_p250;
        		}
        		else if (g_t_pistol[client] == 3 && GetConVarInt(g_tec9_enabled) == 1)
        		{
            			secondary = "weapon_tec9";
            			pistol_round_dollars = pistol_round_dollars - g_gun_price_tec9;
        		}
        		else if (g_t_pistol[client] == 4 && GetConVarInt(g_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
            			pistol_round_dollars = pistol_round_dollars - g_gun_price_cz;
        		}
        		else if (g_t_pistol[client] == 5 && GetConVarInt(g_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
				pistol_round_dollars = pistol_round_dollars - g_gun_price_elite;
			}
			else if (g_t_pistol[client] == 6 && GetConVarInt(g_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
				pistol_round_dollars = pistol_round_dollars - g_gun_price_deagle;
        		}		
			else
			{
				secondary = "weapon_glock";
			}
		
			if(pistol_round_dollars >= g_kevlar_price)
			{
				odds = GetRandomInt(1,10);
                 		// 90% to have kevlar if money before nades
				// 10% will have kevlar and nades
                 		if (odds < 10)
                 		{
                        		kevlar = 100;
                        		pistol_round_dollars = pistol_round_dollars - g_kevlar_price;
                 		}
			}
		}

        	SetNades(nades, true, isPistolRound, pistol_round_dollars);

		// Give armor to the lucky 10% that get nades and armor (glock only)
		if(isPistolRound && pistol_round_dollars >= g_kevlar_price)
		{
			kevlar = 100;
			pistol_round_dollars = pistol_round_dollars - g_kevlar_price;
		}
		
        	Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
	}

//Ct players

	//Count ct admins for priority awp
	for (int i = 0; i < ctCount; i++) 
	{
		int client = GetArrayCell(ctPlayers, i);
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			if(g_awp[client] == 1)
			{
				int rand = GetRandomInt(1, 3);
				if(rand == 1)
				{
					num_ct_admin_awps++;
					ct_admin_awp[client] = num_ct_admin_awps;
				}
			}
			else if(g_awp[client] == 2)
			{
				num_ct_admin_awps++;
				ct_admin_awp[client] = num_ct_admin_awps;
			}		
		}
	}

	//Chose which ct admin gets awp
	ct_rand_admin_awp = GetRandomInt(1, num_ct_admin_awps);
	
	for (int i = 0; i < ctCount; i++) 
	{
		int client = GetArrayCell(ctPlayers, i);
		pistol_round_dollars = 800;
		primary = "";
		
//CT gun round primary
        	if (!isPistolRound)
        	{
			kit = true;
			kevlar = 100;
			helmet = true;
			health = 100;

			int randGiveAwp = GetRandomInt(1, 3);


			if (GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				if(ct_admin_awp[client] == ct_rand_admin_awp && ct_awp_given < GetConVarInt(g_awp_ct_max))
				{
					primary = "weapon_awp";
					ct_awp_given++;
				}
				else if (g_silenced_m4[client]) 
				{
                			primary = "weapon_m4a1_silencer";
            			} 
				else 
				{
                			primary = "weapon_m4a1";
            			}
					
			}

            		else if (g_awp[client] == 1 && randGiveAwp == 1 && ct_awp_given < GetConVarInt(g_awp_ct_max) && num_ct_admin_awps < 1) 
			{
                		primary = "weapon_awp";
				ct_awp_given++;
            		} 
			else if (g_silenced_m4[client]) 
			{
                		primary = "weapon_m4a1_silencer";
            		} 
			else 
			{
                		primary = "weapon_m4a1";
            		}

//CT Gun round pistols
			if (g_ct_sidearm[client] == 2 && GetConVarInt(g_p250_enabled) == 1)
        		{
				secondary = "weapon_p250";
			}
			else if (g_ct_sidearm[client] == 3 && GetConVarInt(g_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_fiveseven";
        		}
        		else if (g_ct_sidearm[client] == 4 && GetConVarInt(g_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
        		}
        		else if (g_ct_sidearm[client] == 5 && GetConVarInt(g_revolver_enabled) == 1)
			{
				secondary = "weapon_revolver";
        		}
			else if (g_ct_sidearm[client] == 6 && GetConVarInt(g_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
        		}
			else if (g_ct_sidearm[client] == 7 && GetConVarInt(g_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
			}		
			else
			{
				secondary = "weapon_hkp2000";
			}
        	}

//CT Pistol round
		if(isPistolRound)
		{
        		kevlar = 0;
			kit = false;
			helmet = false;
			health = 100;

			//35% chance to have a kit
			odds = GetRandomInt(1, 100);
			if(odds > 65)
			{
				kit = true;
				numkits++;
			}
						
			//If there are no kits, give one
			if(numkits < 1 && i == (ctCount-1))
			{
				kit = true;
				numkits++;
			}

			if (g_ct_pistol[client] == 2 && GetConVarInt(g_p250_enabled) == 1)
        		{
            			secondary = "weapon_p250";
            			pistol_round_dollars = pistol_round_dollars - g_gun_price_p250;
        		}
        		else if (g_ct_pistol[client] == 3 && GetConVarInt(g_fiveseven_enabled) == 1)
        		{
            			secondary = "weapon_fiveseven";
            			pistol_round_dollars = pistol_round_dollars - g_gun_price_fiveseven;
        		}
        		else if (g_ct_pistol[client] == 4 && GetConVarInt(g_cz_enabled) == 1)
        		{
            			secondary = "weapon_cz75a";
            			pistol_round_dollars = pistol_round_dollars - g_gun_price_cz;
        		}
        		else if (g_ct_pistol[client] == 5 && GetConVarInt(g_dual_elite_enabled) == 1)
			{
				secondary = "weapon_elite";
				pistol_round_dollars = pistol_round_dollars - g_gun_price_elite;
			}
			else if (g_ct_pistol[client] == 6 && GetConVarInt(g_deagle_enabled) == 1)
			{
				secondary = "weapon_deagle";
				pistol_round_dollars = pistol_round_dollars - g_gun_price_deagle;
        		}		
			else
			{
				secondary = "weapon_hkp2000";
				if(pistol_round_dollars >= g_kevlar_price)
				{
					odds = GetRandomInt(1,10);
                 			// 80% to have kevlar if money before kit and nades
					// 20% will have kevlar and nades
                 			if (odds > 2)
                 			{
                        			kevlar = 100;
                        			pistol_round_dollars = pistol_round_dollars - g_kevlar_price;
                 			}
				}
			}
		
		}
	
        	SetNades(nades, false, isPistolRound, pistol_round_dollars);
		

		// Give armor to the lucky 20% that get nades and armor (usp/p2000 only)
		if(isPistolRound && pistol_round_dollars >= g_kevlar_price)
		{	
				kevlar = 100;
				pistol_round_dollars = pistol_round_dollars - g_kevlar_price;
		}
		
        	Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
    	}
}

static void SetNades(char nades[NADE_STRING_LENGTH], bool terrorist, bool isPistolRound, int pistol_round_dollars) 
{
	nades = "";

        int max_hegrenade_allow = terrorist ? GetConVarInt(g_hegrenade_t_max) : GetConVarInt(g_hegrenade_ct_max);
        int max_flashbang_allow = terrorist ? GetConVarInt(g_flashbang_t_max) : GetConVarInt(g_flashbang_ct_max);
        int max_smokegrenade_allow = terrorist ? GetConVarInt(g_smokegrenade_t_max) : GetConVarInt(g_smokegrenade_ct_max);
        int max_molotov_allow = terrorist ? GetConVarInt(g_molotov_t_max) : GetConVarInt(g_molotov_ct_max);
	int max_decoy_allow = terrorist ? GetConVarInt(g_decoy_t_max) : GetConVarInt(g_decoy_ct_max);	

        int he_number = 0;
        int smoke_number = 0;
        int flashbang_number = 0;
        int molotov_number = 0;
	int decoy_number = 0;

        int maxgrenades = GetConVarInt(FindConVar("ammo_grenade_limit_total"));
        int maxflashbang = GetConVarInt(FindConVar("ammo_grenade_limit_flashbang"));

        int rand;
	int randgive = 0;
        int indice = 0;

        for(int i=0; i < 10; i++)
        {
		rand = GetRandomInt(1, 4);

            	if (maxgrenades <= indice)
                	break;

            	switch(rand) 
		{
		
			//Add chance to give no nade of that type
			case 1:
				if ((terrorist ? g_smokegrenade_t_count : g_smokegrenade_ct_count) < max_smokegrenade_allow && smoke_number == 0)
				{
					randgive = GetRandomInt(1, 10);

                    			if(randgive > 5)
					{
						if(pistol_round_dollars >= g_nade_price_smokegrenade || !isPistolRound)
						{
							nades[indice] = 's';
                        				pistol_round_dollars = pistol_round_dollars - g_nade_price_smokegrenade;
                        				smoke_number++;
                        				if (terrorist)
								g_smokegrenade_t_count++;
							else
                            					g_smokegrenade_ct_count++;
						}
					}
					indice++;
				}
			
			case 2:
				if ((terrorist ? g_hegrenade_t_count : g_hegrenade_ct_count) < max_hegrenade_allow && he_number == 0)
                    		{
					randgive = GetRandomInt(1, 10);

					if(randgive > 4)
					{
                      				if(pistol_round_dollars >= g_nade_price_hegrenade || !isPistolRound)
						{
							nades[indice] = 'h';
                        				pistol_round_dollars = pistol_round_dollars - g_nade_price_hegrenade;
                        				he_number++;
                        				if (terrorist)
                            					g_hegrenade_t_count++;
                        				else
                            					g_hegrenade_ct_count++;
						}
					}
					indice++;
                   		}			

                	case 3:
				if ((terrorist ? g_flashbang_t_count : g_flashbang_ct_count) < max_flashbang_allow && flashbang_number < maxflashbang)
                    		{
					randgive = GetRandomInt(1, 10);

					if(randgive > 3)
					{
						if(pistol_round_dollars >= g_nade_price_flashbang || !isPistolRound)
						{
                        				nades[indice] = 'f';
                        				pistol_round_dollars = pistol_round_dollars - g_nade_price_flashbang;
                        				flashbang_number++;
                        				if (terrorist)
                            					g_flashbang_t_count++;
                        				else
                           					g_flashbang_ct_count++;
						}
					}
					indice++;
                   		}

                	case 4:
				if ((terrorist ? g_molotov_t_count : g_molotov_ct_count) < max_molotov_allow && molotov_number == 0)
                    		{
					randgive = GetRandomInt(1, 20);
				
                    			if(randgive < 5)
					{	
                        			if (terrorist)
						{
							if(pistol_round_dollars >= g_nade_price_molotov || !isPistolRound)
							{
                            					pistol_round_dollars = pistol_round_dollars - g_nade_price_molotov;
								nades[indice] = 'm';
								g_molotov_t_count++;
								molotov_number++;
							}
						}
                        			else
						{
							if(pistol_round_dollars >= g_nade_price_incgrenade || !isPistolRound)
							{
                            					pistol_round_dollars = pistol_round_dollars - g_nade_price_incgrenade;
								nades[indice] = 'i';
								g_molotov_ct_count++;
								molotov_number++;
							}
						}
					}
					else if(randgive > 19 && (terrorist ? g_decoy_t_count : g_decoy_ct_count) < max_decoy_allow && decoy_number == 0) //sometimes give decoy
					{
						if(pistol_round_dollars >= g_nade_price_decoy || !isPistolRound)
						{
							nades[indice] = 'd';
							pistol_round_dollars = pistol_round_dollars - g_nade_price_decoy;
							if (terrorist)
                            					g_decoy_t_count++;
                        				else
                            					g_decoy_ct_count++;
						}
					}
					indice++;
                    		}
		}//switch(rand)
	}//for(int i=0; i < 10; i++)
}//static void SetNades

//////////////Menus////////////////////

//M4 Menu
public void GiveM4Menu(int client) 
{
	Handle menu = CreateMenu(MenuHandler_M4);
    	SetMenuTitle(menu, "Select a CT rifle:");
    	AddMenuBool(menu, false, "M4A4");
    	AddMenuBool(menu, true, "M4A1-S");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_M4(Handle menu, MenuAction action, int param1, int param2) 
{
    	if (action == MenuAction_Select) 
	{
        	int client = param1;
        	bool useSilenced = GetMenuBool(menu, param2);
        	g_silenced_m4[client] = useSilenced;
        	SetCookieBool(client, g_m4_cookie, useSilenced);

        	if (GetConVarInt(g_awp_ct_max) > 0 || GetConVarInt(g_awp_t_max) > 0)
			GiveAwpMenu(client);
        	else
            		CloseHandle(menu);
    	} 
	else if (action == MenuAction_End) 
        	CloseHandle(menu);
}

//Awp Menu
public void GiveAwpMenu(int client) 
{

    	Handle menu = CreateMenu(MenuHandler_AWP);
    	SetMenuTitle(menu, "Allow yourself to receive AWPs?");

	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		AddMenuInt(menu, 1, "Sometimes");
    		AddMenuInt(menu, 2, "As much as possible");
		AddMenuInt(menu, 3, "No");
	}
	else
    	{
		AddMenuInt(menu, 1, "Yes");
    		AddMenuInt(menu, 3, "No");
	}
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_AWP(Handle menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        	int client = param1;
        	int allowAwps = GetMenuInt(menu, param2);
        	g_awp[client] = allowAwps;
        	SetCookieInt(client, g_awp_cookie, allowAwps);
		
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			GiveTaserMenu(client);
		}
		else
		{
			if (GetConVarInt(g_advertise_pistol_menu) == 1)
				PrintToChat(client, "To customize your pistols type: \x04!pistols");
			if (GetConVarInt(g_advertise_pistol_menu) == 2)
				GiveCTPistolMenu(client);
		}
    	} 
	else if (action == MenuAction_End) 
        	CloseHandle(menu);
}

//Taser Menu
public void GiveTaserMenu(int client)
{
    Handle menu = CreateMenu(MenuHandler_TASER);
    SetMenuTitle(menu, "Equip Taser?");
    AddMenuBool(menu, true, "Yes");
    AddMenuBool(menu, false, "No");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_TASER(Handle menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
	       	int client = param1;
     		bool allowTaser = GetMenuBool(menu, param2);
        	g_taser[client] = allowTaser;
        	SetCookieBool(client, g_taser_cookie, allowTaser);
		
		if (GetConVarInt(g_advertise_pistol_menu) == 1)
			PrintToChat(client, "To customize your pistols type: \x04!pistols");
		if (GetConVarInt(g_advertise_pistol_menu) == 2)
			GiveCTPistolMenu(client);
 	} 
	else if (action == MenuAction_End) 
        	CloseHandle(menu);
}

//CT pistol Menu
public void GiveCTPistolMenu(int client) 
{
	Handle menu = CreateMenu(MenuHandler_CT_PISTOL);
	SetMenuTitle(menu, "Select CT pistol round weapon:");
	AddMenuInt(menu, 1, "P2000/USP-S");
	if (GetConVarInt(g_p250_enabled) == 1)
		AddMenuInt(menu, 2, "p250");
    	if (GetConVarInt(g_fiveseven_enabled) == 1)
    		AddMenuInt(menu, 3, "Fiveseven");
    	if (GetConVarInt(g_cz_enabled) == 1)
       	 	AddMenuInt(menu, 4, "CZ75");
	if (GetConVarInt(g_dual_elite_enabled) == 1)
       	 	AddMenuInt(menu, 5, "Dual Elite");
   	if (GetConVarInt(g_dual_elite_enabled) == 1)
        	AddMenuInt(menu, 6, "Deagle");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_CT_PISTOL(Handle menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        	int client = param1;
        	int gunchoice = GetMenuInt(menu, param2);
        	g_ct_pistol[client] = gunchoice;
        	SetCookieInt(client, g_ct_pistol_cookie, gunchoice);
        	GiveCTSideMenu(client);
    	} 
	else if (action == MenuAction_End)
        	CloseHandle(menu);
}

//CT sidearm menu
public void GiveCTSideMenu(int client) 
{
	Handle menu = CreateMenu(MenuHandler_CT_Sidearm);
	SetMenuTitle(menu, "Select CT sidearm:");
	AddMenuInt(menu, 1, "P2000/USP-S");
	if (GetConVarInt(g_p250_enabled) == 1)
		AddMenuInt(menu, 2, "p250");
    	if (GetConVarInt(g_fiveseven_enabled) == 1)
    		AddMenuInt(menu, 3, "Fiveseven");
    	if (GetConVarInt(g_cz_enabled) == 1)
       	 	AddMenuInt(menu, 4, "CZ75");
	if (GetConVarInt(g_revolver_enabled) == 1)
       	 	AddMenuInt(menu, 5, "R8 Revolver");
   	if (GetConVarInt(g_deagle_enabled) == 1)
        	AddMenuInt(menu, 6, "Deagle");
	if (GetConVarInt(g_dual_elite_enabled) == 1)
       		AddMenuInt(menu, 7, "Dual Elite");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_CT_Sidearm(Handle menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        	int client = param1;
        	int gunchoice = GetMenuInt(menu, param2);
        	g_ct_sidearm[client] = gunchoice;
        	SetCookieInt(client, g_ct_sidearm_cookie, gunchoice);
        	GiveTPistolMenu(client);
    	} 
	else if (action == MenuAction_End)
        	CloseHandle(menu);
}

//T pistol Menu
public void GiveTPistolMenu(int client) 
{
	Handle menu = CreateMenu(MenuHandler_T_PISTOL);
	SetMenuTitle(menu, "Select T pistol round weapon:");
	AddMenuInt(menu, 1, "Glock");
	if (GetConVarInt(g_p250_enabled) == 1)
		AddMenuInt(menu, 2, "p250");
    	if (GetConVarInt(g_tec9_enabled) == 1)
    		AddMenuInt(menu, 3, "Tec-9");
    	if (GetConVarInt(g_cz_enabled) == 1)
       	 	AddMenuInt(menu, 4, "CZ75");
	if (GetConVarInt(g_dual_elite_enabled) == 1)
       	 	AddMenuInt(menu, 5, "Dual Elite");
   	if (GetConVarInt(g_dual_elite_enabled) == 1)
        	AddMenuInt(menu, 6, "Deagle");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_T_PISTOL(Handle menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        	int client = param1;
        	int gunchoice = GetMenuInt(menu, param2);
        	g_t_pistol[client] = gunchoice;
        	SetCookieInt(client, g_t_pistol_cookie, gunchoice);
        	GiveTSideMenu(client);
    	} 
	else if (action == MenuAction_End)
        	CloseHandle(menu);
}

//T sidearm menu
public void GiveTSideMenu(int client) 
{
	Handle menu = CreateMenu(MenuHandler_T_Sidearm);
	SetMenuTitle(menu, "Select T sidearm:");
	AddMenuInt(menu, 1, "Glock");
	if (GetConVarInt(g_p250_enabled) == 1)
		AddMenuInt(menu, 2, "p250");
    	if (GetConVarInt(g_tec9_enabled) == 1)
    		AddMenuInt(menu, 3, "Tec-9");
    	if (GetConVarInt(g_cz_enabled) == 1)
       	 	AddMenuInt(menu, 4, "CZ75");
	if (GetConVarInt(g_revolver_enabled) == 1)
       	 	AddMenuInt(menu, 5, "R8 Revolver");
   	if (GetConVarInt(g_deagle_enabled) == 1)
        	AddMenuInt(menu, 6, "Deagle");
	if (GetConVarInt(g_dual_elite_enabled) == 1)
       		AddMenuInt(menu, 7, "Dual Elite");
    	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_T_Sidearm(Handle menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        	int client = param1;
        	int gunchoice = GetMenuInt(menu, param2);
        	g_t_sidearm[client] = gunchoice;
        	SetCookieInt(client, g_t_sidearm_cookie, gunchoice);
    	} 
	else if (action == MenuAction_End)
        	CloseHandle(menu);
}

