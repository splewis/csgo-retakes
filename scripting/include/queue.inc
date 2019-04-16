#if defined _queue_included
  #endinput
#endif
#define _queue_included

/**
 * Initializes the queue and returns a new handle to it that must be closed.
 */
stock ArrayList Queue_Init() {
    ArrayList queueHandle = new ArrayList();
    return queueHandle;
}

/**
 * Push a Client to the end of the Queue (don't add a client if already in queue).
 */
stock void Queue_Enqueue(ArrayList queueHandle, int client) {
    if (Queue_Find(queueHandle, client) == -1)
        queueHandle.Push(client);
}

stock void Queue_EnqueueFront(ArrayList queueHandle, int client) {
    if (Queue_Find(queueHandle, client) != -1)
        return;

    if (queueHandle.Length == 0) {
        Queue_Enqueue(queueHandle, client);
    } else {
        queueHandle.ShiftUp(0);
        queueHandle.Set(0, client);
    }
}

/**
 * Finds a client in the Queue and returns their index.
 */
stock int Queue_Find(ArrayList queueHandle, int client) {
    return queueHandle.FindValue(client);
}

/**
 * Drops a client from the Queue.
 */
stock void Queue_Drop(ArrayList queueHandle, int client) {
    int index = Queue_Find(queueHandle, client);
    if (index != -1)
        queueHandle.Erase(index);
}

/**
 * Get queue length, does not validate clients in queue.
 */
stock int Queue_Length(ArrayList queueHandle) {
    return queueHandle.Length;
}

/**
 * Test if queue is empty.
 */
stock bool Queue_IsEmpty(ArrayList queueHandle) {
    return Queue_Length(queueHandle) == 0;
}

/**
 * Peeks the head of the queue.
 */
stock int Queue_Peek(ArrayList queueHandle) {
    return queueHandle.Get(0);
}

/**
 * Fetch next client from queue.
 */
stock int Queue_Dequeue(ArrayList queueHandle) {
    int val = Queue_Peek(queueHandle);
    queueHandle.Erase(0);
    return val;
}

/**
 * Clears all entires in a queue.
 */
stock void Queue_Clear(ArrayList queueHandle) {
    queueHandle.Clear();
}

/**
 * Closes the handle for the queue.
 */
stock void Queue_Destroy(ArrayList queueHandle) {
    delete queueHandle;
}
