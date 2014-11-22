#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include "include/retakes.inc"



/***********************
 *                     *
 *   Global variables  *
 *                     *
 ***********************/

#define POINTS_KILL 300
#define POINTS_DMG 10
#define POINTS_BOMB 150
#define POINTS_LOSS 2000

/** Client variable arrays **/
int g_SpawnIndices[MAXPLAYERS+1] = 0;
int g_RoundPoints[MAXPLAYERS+1] = 0;
bool g_PluginTeamSwitch[MAXPLAYERS+1] = false;
int g_Team[MAXPLAYERS+1] = 0;

/** Queue Handles **/
Handle g_hWaitingQueue = INVALID_HANDLE;
Handle g_hRankingQueue = INVALID_HANDLE;

/** ConVar handles **/
Handle g_hCvarVersion = INVALID_HANDLE;
Handle g_hEditorEnabled = INVALID_HANDLE;
Handle g_hMaxPlayers = INVALID_HANDLE;
Handle g_hRatioConstant = INVALID_HANDLE;
Handle g_hRoundsToScramble = INVALID_HANDLE;
Handle g_hRoundTime = INVALID_HANDLE;

/** Editing global variables **/
bool g_EditMode = false;
int g_PlayerBeingEdited = -1;
bool g_ShowingSpawns = false;

/** Win-streak data **/
bool g_ScrambleSignal = false;
int g_WinStreak = 0;
int g_RoundCount = 0;

/** Stored info from the spawns config file **/
#define MAX_SPAWNS 256
int g_NumSpawns = 0;
bool g_SpawnDeleted[MAX_SPAWNS];
float g_SpawnPoints[MAX_SPAWNS][3];
float g_SpawnAngles[MAX_SPAWNS][3];
Bombsite g_SpawnSites[MAX_SPAWNS];
int g_SpawnTeams[MAX_SPAWNS];
bool g_SpawnNoBomb[MAX_SPAWNS];

/** Bomb-site stuff read from the map **/
ArrayList g_SiteMins = null;
ArrayList g_SiteMaxs = null;

/** Data created for the current retake scenario **/
Bombsite g_Bombsite;
bool g_SpawnTaken[MAX_SPAWNS];
char g_PlayerPrimary[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char g_PlayerSecondary[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char g_PlayerNades[MAXPLAYERS+1][NADE_STRING_LENGTH];
int g_PlayerHealth[MAXPLAYERS+1];
int g_PlayerArmor[MAXPLAYERS+1];
bool g_PlayerHelmet[MAXPLAYERS+1];
bool g_PlayerKit[MAXPLAYERS+1];

/** Global offsets needed **/
int g_helmetOffset = 0;

/** Per-round information about the player setup **/
bool g_bombPlanted = false;
int g_BombOwner = -1;
int g_NumCT = 0;
int g_NumT = 0;
int g_ActivePlayers = 0;
bool g_RoundSpawnsDecided = false; // spawns are lazily decided on the first player spawn event

/** Forwards **/
Handle g_OnTeamsSet = INVALID_HANDLE;
Handle g_OnFailToPlant = INVALID_HANDLE;
Handle g_OnRoundWon = INVALID_HANDLE;
Handle g_OnSitePicked = INVALID_HANDLE;
Handle g_hOnTeamSizesSet = INVALID_HANDLE;
Handle g_OnWeaponsAllocated = INVALID_HANDLE;
Handle g_hOnPreRoundEnqueue = INVALID_HANDLE;

#include "retakes/editor.sp"
#include "retakes/generic.sp"
#include "retakes/natives.sp"
#include "retakes/priorityqueue.sp"
#include "retakes/queue.sp"
#include "retakes/spawns.sp"



/***********************
 *                     *
 * Sourcemod functions *
 *                     *
 ***********************/

public Plugin:myinfo = {
    name = "CS:GO Retakes",
    author = "splewis",
    description = "CS:GO Retake practice",
    version = PLUGIN_VERSION,
    url = "https://github.com/splewis/csgo-retakes"
};

public OnPluginStart() {
    LoadTranslations("common.phrases");
    LoadTranslations("retakes.phrases");

    /** ConVars **/
    g_hEditorEnabled = CreateConVar("sm_retakes_editor_enabled", "1", "Whether the editor can be launched by admins");
    g_hMaxPlayers = CreateConVar("sm_retakes_maxplayers", "9", "Maximum number of players allowed in the game at once.", _, true, 2.0);
    g_hRatioConstant = CreateConVar("sm_retakes_ratio_constant", "0.4", "Ratio constant for team sizes.");
    g_hRoundsToScramble = CreateConVar("sm_retakes_scramble_rounds", "10", "Consecutive terrorist wins to cause a team scramble.");
    g_hRoundTime = CreateConVar("sm_retakes_round_time", "12", "Round time left in seconds.");

    /** Create/Execute retakes cvars **/
    AutoExecConfig(true, "retakes", "sourcemod/retakes");

    g_hCvarVersion = CreateConVar("sm_retakes_version", PLUGIN_VERSION, "Current retakes version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(g_hCvarVersion, PLUGIN_VERSION);

    /** Command hooks **/
    AddCommandListener(Command_TeamJoin, "jointeam");

    /** Admin commands **/
    RegAdminCmd("sm_edit", Command_EditSpawns, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_spawns", Command_EditSpawns, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_new", Command_AddPlayer, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_player", Command_AddPlayer, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_show", Command_Show, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_deletespawn", Command_DeleteSpawn, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_bomb", Command_Bomb, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_nobomb", Command_NoBomb, ADMFLAG_CHANGEMAP);

    /** Event hooks **/
    HookEvent("player_connect_full", Event_PlayerConnectFull);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_hurt", Event_DamageDealt);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_prestart", Event_RoundPreStart);
    HookEvent("round_poststart", Event_RoundPostStart);
    HookEvent("round_freeze_end", Event_RoundFreezeEnd);
    HookEvent("bomb_planted", Event_BombPlant);
    HookEvent("bomb_exploded", Event_Bomb);
    HookEvent("bomb_defused", Event_Bomb);
    HookEvent("round_end", Event_RoundEnd);

    g_OnFailToPlant = CreateGlobalForward("Retakes_OnFailToPlant", ET_Ignore, Param_Cell);
    g_OnTeamsSet = CreateGlobalForward("Retakes_OnTeamsSet", ET_Ignore);
    g_OnRoundWon = CreateGlobalForward("Retakes_OnRoundWon", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_OnSitePicked = CreateGlobalForward("Retakes_OnSitePicked", ET_Ignore, Param_CellByRef);
    g_hOnTeamSizesSet = CreateGlobalForward("Retakes_OnTeamSizesSet", ET_Ignore, Param_CellByRef, Param_CellByRef);
    g_OnWeaponsAllocated = CreateGlobalForward("Retakes_OnWeaponsAllocated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hOnPreRoundEnqueue = CreateGlobalForward("Retakes_OnPreRoundEnqueue", ET_Ignore, Param_Cell, Param_Cell);

    g_helmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");

    g_SiteMins = ArrayList(3);
    g_SiteMaxs = ArrayList(3);
}

public OnMapStart() {
    g_ScrambleSignal = false;
    g_WinStreak = 0;
    g_RoundCount = 0;
    g_RoundSpawnsDecided = false;

    g_ShowingSpawns = false;
    g_EditMode = false;
    CreateTimer(1.0, Timer_ShowSpawns, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    FindSites();
    g_NumSpawns = ParseSpawns();
    g_hWaitingQueue = Queue_Init();
    ServerCommand("exec sourcemod/retakes/retakes_game.cfg");

    /** begin insane warmup hacks **/
    ServerCommand("mp_do_warmup_period 1");
    ServerCommand("mp_warmuptime 25");
    ServerCommand("mp_warmup_start");
    ServerCommand("mp_warmup_start");
}

public OnMapEnd() {
    WriteSpawns();
    Queue_Destroy(g_hWaitingQueue);
}

public OnClientConnected(client) {
    ResetClientVariables(client);
}

public OnClientDisconnect(client) {
    ResetClientVariables(client);
    int tHumanCount=0, ctHumanCount=0;
    GetTeamsClientCounts(tHumanCount, ctHumanCount);
    if (tHumanCount == 0 || ctHumanCount == 0) {
        CS_TerminateRound(1.0, CSRoundEnd_TerroristWin);
    }
}

/**
 * Helper functions that resets client variables when they join or leave.
 */
ResetClientVariables(client) {
    if (client == g_BombOwner)
        g_BombOwner = -1;
    Queue_Drop(g_hWaitingQueue, client);
    g_Team[client] = CS_TEAM_SPECTATOR;
    g_PluginTeamSwitch[client] = false;
    g_RoundPoints[client] = -POINTS_LOSS;
}

/***********************
 *                     *
 *    Command Hooks    *
 *                     *
 ***********************/

public Action Command_TeamJoin(int client, const char[] command, argc) {
    if (!IsValidClient(client) || argc < 1)
        return Plugin_Handled;

    if (g_EditMode) {
        SwitchPlayerTeam(client, CS_TEAM_CT);
        CS_RespawnPlayer(client);
        return Plugin_Handled;
    }

    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));
    int team_to = StringToInt(arg);
    int team_from = GetClientTeam(client);

    // if same team, teamswitch controlled by the plugin
    // note if a player hits autoselect their team_from=team_to=CS_TEAM_NONE
    if ((team_from == team_to && team_from != CS_TEAM_NONE) || g_PluginTeamSwitch[client] || IsFakeClient(client)) {
        return Plugin_Continue;
    } else {
        // ignore switches between T/CT team
        if (   (team_from == CS_TEAM_CT && team_to == CS_TEAM_T )
            || (team_from == CS_TEAM_T  && team_to == CS_TEAM_CT)) {
            return Plugin_Handled;

        } else if (team_to == CS_TEAM_SPECTATOR) {
            // voluntarily joining spectator will not put you in the queue
            SwitchPlayerTeam(client, CS_TEAM_SPECTATOR);
            Queue_Drop(g_hWaitingQueue, client);
            return Plugin_Handled;

        } else {
            return PlacePlayer(client);
        }
    }
}

/**
 * Generic logic for placing a player into the correct team when they join.
 */
public Action PlacePlayer(int client) {
    int tHumanCount=0, ctHumanCount=0, nPlayers=0;
    GetTeamsClientCounts(tHumanCount, ctHumanCount);
    nPlayers = tHumanCount + ctHumanCount;

    if (Retakes_InWarmup() && nPlayers < GetConVarInt(g_hMaxPlayers)) {
        return Plugin_Continue;
    }

    if (nPlayers < 2) {
        ChangeClientTeam(client, CS_TEAM_SPECTATOR);
        Queue_Enqueue(g_hWaitingQueue, client);
        CS_TerminateRound(0.0, CSRoundEnd_CTWin);
        return Plugin_Handled;
    }

    ChangeClientTeam(client, CS_TEAM_SPECTATOR);
    Queue_Enqueue(g_hWaitingQueue, client);
    Retakes_Message(client, "%t", "JoinedQueueMessage");
    return Plugin_Handled;
}



/***********************
 *                     *
 *     Event Hooks     *
 *                     *
 ***********************/

/**
 * Called when a player joins a team, silences team join events
 */
public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)  {
    dontBroadcast = true;
    return Plugin_Changed;
}

/**
 * Full connect event right when a player joins.
 * This sets the auto-pick time to a high value because mp_forcepicktime is broken and
 * if a player does not select a team but leaves their mouse over one, they are
 * put on that team and spawned, so we can't allow that.
 */
public Event_PlayerConnectFull(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 3600.0);
}

/**
 * Called when a player spawns.
 * Gives default weapons. (better than mp_ct_default_primary since it gives the player the correct skin)
 */
public Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client) || !IsOnTeam(client) || g_EditMode || Retakes_InWarmup())
        return;

    if (!g_RoundSpawnsDecided) {
        if (IsPlayer(g_BombOwner)) {
            g_SpawnIndices[g_BombOwner] = SelectSpawn(g_BombOwner, true);
        }

        for (int i = 1; i <= MAXPLAYERS; i++) {
            if (IsPlayer(i) && IsOnTeam(i) && i != g_BombOwner) {
                g_SpawnIndices[i] = SelectSpawn(i, false);
            }
        }
        g_RoundSpawnsDecided = true;
    }

    SetupPlayer(client);
}

/**
 * Called when a player dies - gives points to killer, and does database stuff with the kill.
 */
public Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    if (Retakes_InWarmup())
        return;

    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    bool validAttacker = IsValidClient(attacker);
    bool validVictim = IsValidClient(victim);

    if (validAttacker && validVictim) {
        if (HelpfulAttack(attacker, victim)) {
            g_RoundPoints[attacker] += POINTS_KILL;
        } else {
            g_RoundPoints[attacker] -= POINTS_KILL;
        }
    }
}

/**
 * Called when a player deals damage to another player - ads round points if needed.
 */
public Action Event_DamageDealt(Handle event, const char[] name, bool dontBroadcast) {
    if (Retakes_InWarmup())
        return Plugin_Continue;

    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    bool validAttacker = IsValidClient(attacker);
    bool validVictim = IsValidClient(victim);

    if (validAttacker && validVictim && HelpfulAttack(attacker, victim) ) {
        int damage = GetEventInt(event, "dmg_PlayerHealth");
        g_RoundPoints[attacker] += damage / POINTS_DMG;
    }
    return Plugin_Continue;
}

/**
 * Called when the bomb explodes or is defuser, gives ponts to the one that planted/defused it.
 */
public Event_BombPlant(Handle event, const char[] name, bool dontBroadcast) {
    g_bombPlanted = true;
}

/**
 * Called when the bomb explodes or is defused, gives ponts to the one that planted/defused it.
 */
public Event_Bomb(Handle event, const char[] name, bool dontBroadcast) {
    if (Retakes_InWarmup())
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsValidClient(client)) {
        g_RoundPoints[client] += POINTS_BOMB;
    }
}

/**
 * Called before any other round start events. This is the best place to change teams
 * since it should happen before respawns.
 */
public Event_RoundPreStart(Handle event, const char[] name, bool dontBroadcast) {
    if (Retakes_InWarmup())
        return;

    g_RoundSpawnsDecided = false;
    RoundEndUpdates();
    UpdateTeams();

    Call_StartForward(g_OnTeamsSet);
    Call_Finish();

    ArrayList ts = ArrayList();
    for (int i = 1; i < MaxClients; i++) {
        if (IsValidClient(i) && IsOnTeam(i)) {
            Client_RemoveAllWeapons(i);
            if (GetClientTeam(i) == CS_TEAM_T) {
                ts.Push(i);
            }
        }
    }

    if (ts.Length >= 1) {
        int player = RandomElement(ts);
        g_BombOwner = player;
    }
    delete ts;
}

public Event_RoundPostStart(Handle event, const char[] name, bool dontBroadcast) {
    if (Retakes_InWarmup())
        return;

    if (!g_EditMode) {
        GameRules_SetProp("m_iRoundTime", GetConVarInt(g_hRoundTime), 4, 0, true);
        char bombsite[4];
        GetSiteString(g_Bombsite, bombsite, sizeof(bombsite));
        Retakes_MessageToAll("%t", "RetakeSiteMessage", bombsite, g_NumT, g_NumCT);
    }

    g_bombPlanted = false;
}

/**
 * Round freezetime end, resets the round points and unfreezes the players.
 */
public Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
        g_RoundPoints[i] = 0;
    }
}

/**
 * Round end event, calls the appropriate winner (T/CT) unction and sets the scores.
 */
public Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
    if (Retakes_InWarmup())
        return;

    if (g_ActivePlayers >= 2) {
        g_RoundCount++;
        int winner = GetEventInt(event, "winner");

        ArrayList ts = ArrayList();
        ArrayList cts = ArrayList();

        for (int i = 1; i <= MaxClients; i++) {
            if (IsPlayer(i)) {
                if (GetClientTeam(i) == CS_TEAM_CT)
                    cts.Push(i);
                else if (GetClientTeam(i) == CS_TEAM_T)
                    ts.Push(i);
            }
        }

        Call_StartForward(g_OnRoundWon);
        Call_PushCell(winner);
        Call_PushCell(ts);
        Call_PushCell(cts);
        Call_Finish();

        delete ts;
        delete cts;

        for (int i = 1; i <= MaxClients; i++) {
            if (IsPlayer(i) && GetClientTeam(i) != winner) {
                g_RoundPoints[i] -= POINTS_LOSS;
            }
        }

        if (winner == CS_TEAM_T) {
            TerroristsWon();
        } else if (winner == CS_TEAM_CT) {
            CounterTerroristsWon();
        }
    }
}



/***********************
 *                     *
 *    Retakes logic    *
 *                     *
 ***********************/

/**
 * Called at the end of the round - puts all the players into a priority queue by
 * their score for placing them next round.
 */
public void RoundEndUpdates() {
    g_hRankingQueue = PQ_Init();

    Call_StartForward(g_hOnPreRoundEnqueue);
    Call_PushCell(g_hRankingQueue);
    Call_PushCell(g_hWaitingQueue);
    Call_Finish();


    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i) && IsOnTeam(i)) {
            PQ_Enqueue(g_hRankingQueue, i, g_RoundPoints[i]);
        }
    }

    while (!Queue_IsEmpty(g_hWaitingQueue) && PQ_GetSize(g_hRankingQueue) < GetConVarInt(g_hMaxPlayers)) {
        int client = Queue_Dequeue(g_hWaitingQueue);
        if (IsPlayer(client)) {
            PQ_Enqueue(g_hRankingQueue, client, -POINTS_LOSS);
        } else {
            break;
        }
    }
}

/**
 * Places players onto the correct team.
 * This assumes the priority queue has already been built (e.g. by RoundEndUpdates).
 */
public void UpdateTeams() {
    for (int i = 0; i < MAX_SPAWNS; i++)
        g_SpawnTaken[i] = false;

    if (g_NumSpawns < GetConVarInt(g_hMaxPlayers)) {
        LogError("This map does not have enough spawns!");
        return;
    }

    g_Bombsite = GetRandomBool() ? BombsiteA : BombsiteB;
    Call_StartForward(g_OnSitePicked);
    Call_PushCellRef(g_Bombsite);
    Call_Finish();

    g_ActivePlayers = PQ_GetSize(g_hRankingQueue);
    if (g_ActivePlayers > GetConVarInt(g_hMaxPlayers))
        g_ActivePlayers = GetConVarInt(g_hMaxPlayers);

    g_NumT = RoundToNearest(GetConVarFloat(g_hRatioConstant) * float(g_ActivePlayers));
    if (g_NumT < 1)
        g_NumT = 1;

    g_NumCT = g_ActivePlayers - g_NumT;

    Call_StartForward(g_hOnTeamSizesSet);
    Call_PushCellRef(g_NumT);
    Call_PushCellRef(g_NumCT);
    Call_Finish();

    if (g_ScrambleSignal) {
        int n = GetArraySize(g_hRankingQueue);
        for (int i = 0; i < n; i++) {
            int value = GetRandomInt(1, 1000);
            SetArrayCell(g_hRankingQueue, i, value, 1);
        }
        g_ScrambleSignal = false;
    }

    ArrayList ts = ArrayList();
    ArrayList cts = ArrayList();

    for (int i = 0; i < g_NumT; i++) {
        int client = PQ_Dequeue(g_hRankingQueue);
        if (IsValidClient(client)) {
            SwitchPlayerTeam(client, CS_TEAM_T);
            ts.Push(client);
            g_Team[client] = CS_TEAM_T;
            g_PlayerPrimary[client] = "weapon_ak47";
            g_PlayerSecondary[client] = "weapon_glock";
            g_PlayerNades[client] = "";
            g_PlayerKit[client] = false;
            g_PlayerHealth[client] = 100;
            g_PlayerArmor[client] = 100;
            g_PlayerHelmet[client] = true;
        }
    }

    for (int i = 0; i < g_NumCT; i++) {
        int client = PQ_Dequeue(g_hRankingQueue);
        if (IsValidClient(client)) {
            SwitchPlayerTeam(client, CS_TEAM_CT);
            g_Team[client] = CS_TEAM_CT;
            cts.Push(client);
            g_PlayerPrimary[client] = "weapon_m4a1";
            g_PlayerSecondary[client] = "weapon_hkp2000";
            g_PlayerNades[client] = "";
            g_PlayerKit[client] = true;
            g_PlayerHealth[client] = 100;
            g_PlayerArmor[client] = 100;
            g_PlayerHelmet[client] = true;
        }
    }

    Call_StartForward(g_OnWeaponsAllocated);
    Call_PushCell(ts);
    Call_PushCell(cts);
    Call_PushCell(g_Bombsite);
    Call_Finish();

    int length = Queue_Length(g_hWaitingQueue);
    for (int i = 0; i < length; i++) {
        int client = GetArrayCell(g_hWaitingQueue, i);
        if (IsValidClient(client)) {
            Retakes_Message(client, "%t", "WaitingQueueMessage", GetConVarInt(g_hMaxPlayers));
        }
    }

    delete ts;
    delete cts;
    PQ_Destroy(g_hRankingQueue);
}

/**
 * Timer event to handle Terrorist Win
 */
public void TerroristsWon() {
    int toScramble = GetConVarInt(g_hRoundsToScramble);
    g_WinStreak++;

    if (g_WinStreak >= toScramble) {
        g_ScrambleSignal = true;
        Retakes_MessageToAll("%t", "ScrambleMessage", toScramble);
        g_WinStreak = 0;
    } else if (g_WinStreak >= toScramble - 3) {
        Retakes_MessageToAll("%t", "WinStreakAlmostToScramble", g_WinStreak, toScramble - g_WinStreak);
    } else if (g_WinStreak >= 3) {
        Retakes_MessageToAll("%t", "WinStreak", g_WinStreak);
    }
}

/**
 * Timer event to handle Counter-Terrorist Win
 */
public void CounterTerroristsWon() {
    if (!g_bombPlanted && IsValidClient(g_BombOwner) && g_RoundCount >= 3) {
        Retakes_MessageToAll("\x03%N \x01failed to plant...", g_BombOwner);
        Call_StartForward(g_OnFailToPlant);
        Call_PushCell(g_BombOwner);
        Call_Finish();
    }

    if (g_WinStreak >= 3) {
        Retakes_MessageToAll("%t", "WinStreakOver", g_WinStreak);
    }

    g_WinStreak = 0;
}
