#include <sourcemod>
#include "include/retakes.inc"
#include "include/priorityqueue.inc"
#include "retakes/generic.sp"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "CS:GO Retakes: random teams",
    author = "splewis",
    description = "Makes the teams fully random every round",
    version = PLUGIN_VERSION,
    url = "https://github.com/splewis/csgo-retakes"
};

public void Retakes_OnPostRoundEnqueue(Handle rankingQueue) {
    Handle players = CreateArray();

    while (!PQ_IsEmpty(rankingQueue)) {
        int client = PQ_Dequeue(rankingQueue);
        PushArrayCell(players, client);
    }

    while (GetArraySize(players) > 0) {
        int client = GetArrayCell(players, 0);
        RemoveFromArray(players, 0);
        int value = GetRandomInt(0, 1000);
        PQ_Enqueue(rankingQueue, client, value);
    }

    CloseHandle(players);
}
