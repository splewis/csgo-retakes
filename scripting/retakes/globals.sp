/***********************
 *                     *
 *   Global variables  *
 *                     *
 ***********************/

/**
 * The general way players are put on teams is using a system of
 * "round points". Actions during a round earn points, and at the end of the round,
 * players are put into a priority queue using their rounds as the value.
 */
#define POINTS_KILL 50
#define POINTS_DMG 1
#define POINTS_BOMB 50
#define POINTS_LOSS 5000

#define SITESTRING(%1) ((%1) == BombsiteA ? "A" : "B")
#define TEAMSTRING(%1) ((%1) == CS_TEAM_CT ? "CT" : "T")

bool g_Enabled = true;
ArrayList g_SavedCvars;

/** Client variable arrays **/
int g_SpawnIndices[MAXPLAYERS+1];
int g_RoundPoints[MAXPLAYERS+1];
bool g_PluginTeamSwitch[MAXPLAYERS+1];
int g_Team[MAXPLAYERS+1];

/** Queue Handles **/
ArrayList g_hWaitingQueue;
ArrayList g_hRankingQueue;

/** ConVar handles **/
ConVar g_EnabledCvar;
ConVar g_hAutoTeamsCvar;
ConVar g_hCvarVersion;
ConVar g_hEditorEnabled;
ConVar g_hMaxPlayers;
ConVar g_hRatioConstant;
ConVar g_hRoundsToScramble;
ConVar g_hRoundTime;
ConVar g_hUseRandomTeams;
ConVar g_WarmupTimeCvar;

/** Editing global variables **/
bool g_EditMode;
bool g_DirtySpawns; // whether the spawns have been edited since loading from the file

/** Win-streak data **/
bool g_ScrambleSignal;
int g_WinStreak;
int g_RoundCount;
bool g_HalfTime;

/** Stored info from the spawns config file **/
#define MAX_SPAWNS 256
int g_NumSpawns;
bool g_SpawnDeleted[MAX_SPAWNS];
float g_SpawnPoints[MAX_SPAWNS][3];
float g_SpawnAngles[MAX_SPAWNS][3];
Bombsite g_SpawnSites[MAX_SPAWNS];
int g_SpawnTeams[MAX_SPAWNS];
SpawnType g_SpawnTypes[MAX_SPAWNS];

/** Spawns being edited per-client **/
int g_EditingSpawnTeams[MAXPLAYERS+1];
SpawnType g_EditingSpawnTypes[MAXPLAYERS+1];

/** Bomb-site stuff read from the map **/
ArrayList g_SiteMins;
ArrayList g_SiteMaxs;

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

/** Per-round information about the player setup **/
bool g_bombPlantSignal;
bool g_bombPlanted;
int g_BombOwner = -1;
int g_NumCT;
int g_NumT;
int g_ActivePlayers;
bool g_RoundSpawnsDecided; // spawns are lazily decided on the first player spawn event

/** Forwards **/
Handle g_hOnGunsCommand;
Handle g_hOnPostRoundEnqueue;
Handle g_hOnPreRoundEnqueue;
Handle g_hOnTeamSizesSet;
Handle g_hOnTeamsSet;
Handle g_OnFailToPlant;
Handle g_OnRoundWon;
Handle g_OnSitePicked;
Handle g_OnWeaponsAllocated;
