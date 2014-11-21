/**
 * Initializes the queue and returns a handle to it that must be closed.
 */
public Handle:PQ_Init() {
    new Handle:queueHandle = CreateArray(2);
    queueHandle = CreateArray(2);
    ClearArray(queueHandle);
    return queueHandle;
}

/**
 * Adds a player and a value to the queue.
 */
public PQ_Enqueue(Handle:queueHandle, any:client, value) {
    if (PQ_FindClient(queueHandle, client) != -1)
        return;

    new index = GetArraySize(queueHandle);
    PushArrayCell(queueHandle, client);
    SetArrayCell(queueHandle, index, client, 0);
    SetArrayCell(queueHandle, index, value, 1);
}

/**
 * Selects the player with the max value in the queue and removes them, returning their client index.
 */
public any:PQ_Dequeue(Handle:queueHandle) {
    new any:maxIndex = -1;
    new any:maxClient = -1;
    new any:maxScore = -1;

    for (new i = 0; i < GetArraySize(queueHandle); i++) {
        new any:client = GetArrayCell(queueHandle, i, 0);
        new any:score = GetArrayCell(queueHandle, i, 1);
        if (maxIndex == -1 || score > maxScore) {
            maxIndex = i;
            maxClient = client;
            maxScore = score;
        }
    }
    if (maxIndex != -1) {
        RemoveFromArray(queueHandle, maxIndex);
    }
    return maxClient;
}

/**
 * Finds an index of the client in the queue. Returns -1 if the client isn't in it.
 */
public any:PQ_FindClient(Handle:queueHandle, client) {
    for (new i = 0; i < GetArraySize(queueHandle); i++) {
        new c = GetArrayCell(queueHandle, i, 0);
        if (client == c)
            return i;
    }
    return -1;
}

/**
 * Drops a client from the queue completely.
 */
public PQ_DropFromQueue(Handle:queueHandle, client) {
    new index = PQ_FindClient(queueHandle, client);
    if (index != -1)
        RemoveFromArray(queueHandle, index);
}

/**
 * Returns the current size of the queue.
 */
public any:PQ_GetSize(Handle:queueHandle) {
    return GetArraySize(queueHandle);
}

/**
 * Returns is the queu is empty.
 */
public bool:PQ_IsEmpty(Handle:queueHandle) {
    return PQ_GetSize(queueHandle) == 0;
}

/**
 * Clears the Handle for a queue.
 */
public PQ_Destroy(Handle:queueHandle) {
    CloseHandle(queueHandle);
}
