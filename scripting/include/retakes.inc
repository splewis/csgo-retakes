#if defined __retakes_included__
  #endinput
#endif
#define __retakes_included__

enum Bombsite {
    BombsiteA,
    BombsiteB
};

#define NADE_STRING_LENGTH 8
#define WEAPON_STRING_LENGTH 32

forward void Retakes_OnPreRoundEnqueue(Handle rankingQueue, Handle waitingQueue);
forward void Retakes_OnSitePicked(Bombsite& site);
forward void Retakes_OnTeamSizesSet(int& tCount, int& ctCount);
forward void Retakes_OnTeamsSet();
forward void Retakes_OnFailToPlant(int client);
forward void Retakes_OnRoundWon(int winner, ArrayList tPlayers, ArrayList ctPlayers);
forward void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite);

// Returns if the player has joined the game, i.e. if they are on a team or in the waiting queue.
// Clients not joined can be considered AFK.
native bool Retakes_IsJoined(int client);

// Returns if a client is in the waiting queue.
native bool Retakes_IsInQueue(int client);

// Sends a retake formatted message to a client.
native void Retakes_Message(int client, const char[] format, any:...);

// Sends a retake formatted message to all clients.
native void Retakes_MessageToAll(const char[] format, any:...);

native int Retakes_GetNumActiveTs();
native int Retakes_GetNumActiveCTs();
native int Retakes_GetNumActivePlayers();
native Bombsite Retakes_GetCurrrentBombsite();

native int Retakes_GetRoundPoints(int client);
native int Retakes_SetRoundPoints(int client, int points);
native int Retakes_ChangeRoundPoints(int client, int dp);

native void Retakes_SetPlayerInfo(int client, char[] primary="", char[] secondary="", char[] nades="", int health=100, int armor=0, bool helmet=false, bool kit=false);
native int Retakes_GetRetakeRoundsPlayed();
native bool Retakes_InWarmup();
native int Retakes_GetMaxPlayers();

stock void GetSiteString(Bombsite site, char[] buffer, int length) {
    switch (site) {
        case BombsiteA: Format(buffer, length, "A");
        case BombsiteB: Format(buffer, length, "B");
        default: Format(buffer, length, "Unknown");
    }
}

public SharedPlugin:__pl_retakes = {
    name = "retakes",
    file = "retakes.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_retakes_SetNTVOptional() {
    MarkNativeAsOptional("Retakes_IsJoined");
    MarkNativeAsOptional("Retakes_IsInQueue");
    MarkNativeAsOptional("Retakes_Message");
    MarkNativeAsOptional("Retakes_MessageToAll");
    MarkNativeAsOptional("Retakes_GetNumActiveTs");
    MarkNativeAsOptional("Retakes_GetNumActiveCTs");
    MarkNativeAsOptional("Retakes_GetNumActivePlayers");
    MarkNativeAsOptional("Retakes_GetCurrrentBombsite");
    MarkNativeAsOptional("Retakes_GetRoundPoints");
    MarkNativeAsOptional("Retakes_SetRoundPoints");
    MarkNativeAsOptional("Retakes_ChangeRoundPoints");
    MarkNativeAsOptional("Retakes_SetPlayerInfo");
    MarkNativeAsOptional("Retakes_GetRetakeRoundsPlayed");
    MarkNativeAsOptional("Retakes_InWarmup");
    MarkNativeAsOptional("Retakes_GetMaxPlayers");
}
#endif
