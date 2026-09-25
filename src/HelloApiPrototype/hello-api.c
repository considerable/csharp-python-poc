/*
 * The C program is a standalone HTTP server, while the C# code is
 * an Azure Function and therefore does not create or manage its own socket.
 */
 
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define DEFAULT_PORT 8080
#define BUFFER_SIZE 4096

static void send_response(int client_fd, int status_code,
                          const char *status_text, const char *body)
{
    char response[1024];

    int length = snprintf(
        response,
        sizeof(response),
        "HTTP/1.1 %d %s\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "\r\n"
        "%s",
        status_code,
        status_text,
        strlen(body),
        body);

    send(client_fd, response, (size_t)length, 0);
}

static void handle_request(int client_fd, const char *request)
{
    char method[16];
    char path[256];

    if (sscanf(request, "%15s %255s", method, path) != 2) {
        send_response(
            client_fd,
            400,
            "Bad Request",
            "{\"error\":\"Bad Request\"}");
        return;
    }

    if (strcmp(method, "GET") != 0) {
        send_response(
            client_fd,
            405,
            "Method Not Allowed",
            "{\"error\":\"Method Not Allowed\"}");
        return;
    }

    if (strcmp(path, "/api/hello") == 0) {
        send_response(
            client_fd,
            200,
            "OK",
            "{\"message\":\"Hello from Azure Functions!\","
            "\"service\":\"hello-api\"}");
        return;
    }

    send_response(
        client_fd,
        404,
        "Not Found",
        "{\"error\":\"Not Found\"}");
}

int main(void)
{
    const char *port_env = getenv("PORT");
    int port = port_env ? atoi(port_env) : DEFAULT_PORT;

    if (port <= 0 || port > 65535) {
        port = DEFAULT_PORT;
    }

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return 1;
    }

    int opt = 1;
    if (setsockopt(
            server_fd,
            SOL_SOCKET,
            SO_REUSEADDR,
            &opt,
            sizeof(opt)) < 0) {
        perror("setsockopt");
        close(server_fd);
        return 1;
    }

    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons((uint16_t)port);

    if (bind(
            server_fd,
            (struct sockaddr *)&address,
            sizeof(address)) < 0) {
        perror("bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 10) < 0) {
        perror("listen");
        close(server_fd);
        return 1;
    }

    printf("Listening on port %d\n", port);

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);

        int client_fd = accept(
            server_fd,
            (struct sockaddr *)&client_addr,
            &client_len);

        if (client_fd < 0) {
            perror("accept");
            continue;
        }

        char buffer[BUFFER_SIZE];

        ssize_t bytes_received = recv(
            client_fd,
            buffer,
            sizeof(buffer) - 1,
            0);

        if (bytes_received > 0) {
            buffer[bytes_received] = '\0';

            char *request_line = strtok(buffer, "\r\n");

            if (request_line != NULL) {
                handle_request(client_fd, request_line);
            }
        }

        close(client_fd);
    }

    close(server_fd);
    return 0;
}