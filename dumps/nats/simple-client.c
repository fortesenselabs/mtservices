#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define MAX_BUFFER_SIZE 4096

typedef struct
{
    char server_address[15];
    int server_port;
    int socket;
} NATSClient;

void connectToServer(NATSClient *client)
{
    struct sockaddr_in server;

    client->socket = socket(AF_INET, SOCK_STREAM, 0);
    if (client->socket == -1)
    {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    server.sin_addr.s_addr = inet_addr(client->server_address);
    server.sin_family = AF_INET;
    server.sin_port = htons(client->server_port);

    if (connect(client->socket, (struct sockaddr *)&server, sizeof(server)) < 0)
    {
        perror("Connection failed");
        exit(EXIT_FAILURE);
    }

    printf("Connected to NATS server\n");
}

void handshake(NATSClient *client)
{
    char connect_msg[50];
    sprintf(connect_msg, "CONNECT {}\r\n");

    if (send(client->socket, connect_msg, strlen(connect_msg), 0) < 0)
    {
        perror("Handshake failed");
        exit(EXIT_FAILURE);
    }

    char response[MAX_BUFFER_SIZE];
    if (recv(client->socket, response, sizeof(response), 0) < 0)
    {
        perror("Failed to receive handshake response");
        exit(EXIT_FAILURE);
    }

    printf("%s", response);
    if (!strstr(response, "+OK"))
    {
        fprintf(stderr, "Handshake failed\n");
        exit(EXIT_FAILURE);
    }

    if (recv(client->socket, response, sizeof(response), 0) < 0)
    {
        perror("Failed to receive PING message");
        exit(EXIT_FAILURE);
    }

    if (strstr(response, "PING"))
    {
        // Respond with "PONG"
        char pong_msg[] = "PONG\r\n";
        if (send(client->socket, pong_msg, strlen(pong_msg), 0) < 0)
        {
            perror("Failed to send PONG response");
            exit(EXIT_FAILURE);
        }
    }
}

void publish(NATSClient *client, const char *subject, const char *message)
{
    char publish_cmd[MAX_BUFFER_SIZE];
    sprintf(publish_cmd, "PUB %s %zu\r\n%s\r\n", subject, strlen(message), message);

    if (send(client->socket, publish_cmd, strlen(publish_cmd), 0) < 0)
    {
        perror("Failed to publish message");
        exit(EXIT_FAILURE);
    }
}

void subscribe(NATSClient *client, const char *subject, const char *sid)
{
    char subscribe_cmd[MAX_BUFFER_SIZE];
    sprintf(subscribe_cmd, "SUB %s %s\r\n", subject, sid);

    if (send(client->socket, subscribe_cmd, strlen(subscribe_cmd), 0) < 0)
    {
        perror("Failed to subscribe");
        exit(EXIT_FAILURE);
    }
}

void receiveMessage(NATSClient *client, char *buffer)
{
    if (recv(client->socket, buffer, MAX_BUFFER_SIZE, 0) < 0)
    {
        perror("Failed to receive message");
        exit(EXIT_FAILURE);
    }
}

void closeConnection(NATSClient *client)
{
    close(client->socket);
    printf("Connection closed\n");
}

int main()
{
    NATSClient client;
    strcpy(client.server_address, "147.75.47.215");
    client.server_port = 4222;

    connectToServer(&client);
    handshake(&client);

    // Subscribe to a subject
    subscribe(&client, "foo.*", "90");

    // Publish a message
    const char *message_data = "{\"hey\":\"hello\"}";
    publish(&client, "foo.bar", message_data);

    // Receive messages
    char received_message[MAX_BUFFER_SIZE];
    for (int i = 0; i < 5; ++i)
    { // Receive 5 messages
        receiveMessage(&client, received_message);
        printf("Received: %s\n", received_message);

        // Check if received message is a PING message
        if (strstr(received_message, "PING"))
        {
            // Respond with "PONG"
            char pong_msg[] = "PONG\r\n";
            if (send(client.socket, pong_msg, strlen(pong_msg), 0) < 0)
            {
                perror("Failed to send PONG response");
                exit(EXIT_FAILURE);
            }
        }
    }

    printf("Exiting...\n");
    closeConnection(&client);

    return 0;
}
