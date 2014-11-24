#define MESSAGE_PREFIX "[\x05Retakes\x01]"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {
    CreateNative("Retakes_IsJoined", Native_IsJoined);
    CreateNative("Retakes_IsInQueue", Native_IsInQueue);
    CreateNative("Retakes_Message", Native_RetakeMessage);
    CreateNative("Retakes_MessageToAll", Native_RetakeMessageToAll);
    CreateNative("Retakes_GetNumActiveTs", Native_GetNumActiveTs);
    CreateNative("Retakes_GetNumActiveCTs", Native_GetNumActiveCTs);
    CreateNative("Retakes_GetNumActivePlayers", Native_GetNumActivePlayers);
    CreateNative("Retakes_GetCurrrentBombsite", Native_GetCurrrentBombsite);
    CreateNative("Retakes_GetRoundPoints", Native_GetRoundPoints);
    CreateNative("Retakes_SetRoundPoints", Native_SetRoundPoints);
    CreateNative("Retakes_ChangeRoundPoints", Native_ChangeRoundPoints);
    CreateNative("Retakes_GetPlayerInfo", Native_GetPlayerInfo);
    CreateNative("Retakes_SetPlayerInfo", Native_SetPlayerInfo);
    CreateNative("Retakes_GetRetakeRoundsPlayed", Native_GetRetakeRoundsPlayed);
    CreateNative("Retakes_InWarmup", Native_InWarmup);
    CreateNative("Retakes_GetMaxPlayers", Native_GetMaxPlayers);
    RegPluginLibrary("retakes");
    return APLRes_Success;
}

public Native_IsJoined(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (!IsPlayer(client))
        return false;
    return GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT || Queue_Find(g_hWaitingQueue, client) != -1;
}

public Native_IsInQueue(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (!IsPlayer(client))
        return false;
    return Queue_Find(g_hWaitingQueue, client) != -1;
}

public Native_RetakeMessage(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (!IsPlayer(client))
        ThrowNativeError(SP_ERROR_PARAM, "Client %d is not a player", client);

    SetGlobalTransTarget(client);
    char buffer[1024];
    int bytesWritten = 0;
    FormatNativeString(0, 2, 3, sizeof(buffer), bytesWritten, buffer);

    char finalMsg[1024];
    Format(finalMsg, sizeof(finalMsg), "%s %s", MESSAGE_PREFIX, buffer);
    Colorize(finalMsg, sizeof(finalMsg));

    PrintToChat(client, finalMsg);
}

public Native_RetakeMessageToAll(Handle plugin, numParams) {
    char buffer[1024];
    char finalMsg[1024];
    int bytesWritten = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i)) {
            SetGlobalTransTarget(i);
            FormatNativeString(0, 1, 2, sizeof(buffer), bytesWritten, buffer);
            Format(finalMsg, sizeof(finalMsg), "%s %s", MESSAGE_PREFIX, buffer);

            Colorize(finalMsg, sizeof(finalMsg));
            PrintToChat(i, finalMsg);
        }
    }
}

public Native_GetNumActiveTs(Handle plugin, numParams) {
    return g_NumT;
}

public Native_GetNumActiveCTs(Handle plugin, numParams) {
    return g_NumCT;
}

public Native_GetNumActivePlayers(Handle plugin, numParams) {
    return g_NumT + g_NumCT;
}

public Native_GetCurrrentBombsite(Handle plugin, numParams) {
    return _:g_Bombsite;
}

public Native_GetRoundPoints(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (client <= 0)
        ThrowNativeError(SP_ERROR_PARAM, "Client %d is not a player", client);

    return g_RoundPoints[client];
}

public Native_SetRoundPoints(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (client <= 0)
        ThrowNativeError(SP_ERROR_PARAM, "Client %d is not a player", client);

    int points = GetNativeCell(2);
    g_RoundPoints[client] = points;
}

public Native_ChangeRoundPoints(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (client <= 0)
        ThrowNativeError(SP_ERROR_PARAM, "Client %d is not a player", client);

    int dp = GetNativeCell(2);
    g_RoundPoints[client] += dp;
}

public Native_GetPlayerInfo(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (client <= 0)
        ThrowNativeError(SP_ERROR_PARAM, "Client %d is not a player", client);

    SetNativeString(2, g_PlayerPrimary[client], WEAPON_STRING_LENGTH);
    SetNativeString(3, g_PlayerSecondary[client], WEAPON_STRING_LENGTH);
    SetNativeString(4, g_PlayerNades[client], NADE_STRING_LENGTH);

    SetNativeCellRef(5, g_PlayerHealth[client]);
    SetNativeCellRef(6, g_PlayerArmor[client]);
    SetNativeCellRef(7, g_PlayerHelmet[client]);
    SetNativeCellRef(8, g_PlayerKit[client]);
}

public Native_SetPlayerInfo(Handle plugin, numParams) {
    int client = GetNativeCell(1);
    if (client <= 0)
        ThrowNativeError(SP_ERROR_PARAM, "Client %d is not a player", client);

    GetNativeString(2, g_PlayerPrimary[client], WEAPON_STRING_LENGTH);
    GetNativeString(3, g_PlayerSecondary[client], WEAPON_STRING_LENGTH);
    GetNativeString(4, g_PlayerNades[client], NADE_STRING_LENGTH);

    g_PlayerHealth[client] = GetNativeCell(5);
    g_PlayerArmor[client] = GetNativeCell(6);
    g_PlayerHelmet[client] = GetNativeCell(7);
    g_PlayerKit[client] = GetNativeCell(8);
}

public Native_GetRetakeRoundsPlayed(Handle plugin, numParams) {
    return g_RoundCount;
}

public Native_InWarmup(Handle plugin, numParams) {
    return GameRules_GetProp("m_bWarmupPeriod");
}

public Native_GetMaxPlayers(Handle plugin, numParams) {
    return GetConVarInt(g_hMaxPlayers);
}
