#include <iostream>
#include <WinSock2.h>
#include <string>
#include <fstream>
#include <iterator>
#include <filesystem>
#include <sstream>
#include <vector>
#include <mutex>
#include <thread>

#pragma comment(lib, "Ws2_32.lib")

namespace fs = std::filesystem;

std::string readFile(const fs::path& path) {
    std::ifstream file(path, std::ios::binary);

    if (!file) {
        return "";
    }

    return std::string(
        std::istreambuf_iterator<char>(file),
        std::istreambuf_iterator<char>()
    );
}

struct ReloadClient {
    SOCKET socket;
};

std::vector<ReloadClient> reloadClients;
std::mutex reloadMutex;

std::vector<int> phronovaEvents;
std::mutex eventMutex;

struct ReactiveUpdate {
    int id;
    std::string value;
};

std::vector<ReactiveUpdate> reactiveUpdates;
std::mutex reactiveMutex;

bool serverRunning = true;
SOCKET serverSocket = INVALID_SOCKET;

void addReactiveUpdate(
    int id,
    const std::string& value
) {
    std::lock_guard<std::mutex> lock(
        reactiveMutex
    );

    reactiveUpdates.push_back({
        id,
        value
    });
}

std::vector<ReactiveUpdate> getReactiveUpdates() {
    std::lock_guard<std::mutex> lock(
        reactiveMutex
    );

    std::vector<ReactiveUpdate> updates =
        reactiveUpdates;

    reactiveUpdates.clear();

    return updates;
}
void addPhronovaEvent(int eventId) {
    std::lock_guard<std::mutex> lock(eventMutex);
    phronovaEvents.push_back(eventId);
}

std::vector<int> getPhronovaEvents() {
    std::lock_guard<std::mutex> lock(eventMutex);

    std::vector<int> events =
        phronovaEvents;

    phronovaEvents.clear();

    return events;
}

void notifyReload() {
    std::lock_guard<std::mutex> lock(reloadMutex);

    std::string message =
        "data: reload\r\n"
        "\r\n";

    for (auto it = reloadClients.begin();
         it != reloadClients.end();) {

        int result = send(
            it->socket,
            message.c_str(),
            static_cast<int>(message.size()),
            0
        );

        if (result == SOCKET_ERROR) {
            closesocket(it->socket);
            it = reloadClients.erase(it);
        } else {
            ++it;
        }
    }
}

void addReloadClient(SOCKET client) {
    std::lock_guard<std::mutex> lock(reloadMutex);

    reloadClients.push_back({
        client
    });
}

std::string getContentType(
    const fs::path& path
) {
    std::string extension =
        path.extension().string();

    if (extension == ".html") {
        return "text/html";
    }

    if (extension == ".css") {
        return "text/css";
    }

    if (extension == ".js") {
        return "application/javascript";
    }

    if (extension == ".json") {
        return "application/json";
    }

    if (extension == ".png") {
        return "image/png";
    }

    if (extension == ".jpg" ||
        extension == ".jpeg") {
        return "image/jpeg";
    }

    if (extension == ".svg") {
        return "image/svg+xml";
    }

    if (extension == ".ico") {
        return "image/x-icon";
    }

    if (extension == ".webp") {
        return "image/webp";
    }

    return "application/octet-stream";
}

bool isSafePath(
    const std::string& url
) {
    if (url.find("..") != std::string::npos) {
        return false;
    }

    if (url.find('\\') != std::string::npos) {
        return false;
    }

    return true;
}

BOOL WINAPI consoleHandler(DWORD signal)
{
    if (signal == CTRL_C_EVENT) {
        serverRunning = false;
        return TRUE;
    }

    return FALSE;
}

void handleClient(
    SOCKET client,
    const fs::path& generatedDir,
    const fs::path& cssFile
)
{
    char buffer[4096]{};

    int received =
        recv(
            client,
            buffer,
            sizeof(buffer) - 1,
            0
        );

    if (received <= 0) {
        closesocket(client);
        return;
    }

    std::istringstream request(buffer);

    std::string method;
    std::string url;
    std::string version;

    request
        >> method
        >> url
        >> version;

    std::cout
        << "Request: "
        << url
        << "\n";

    if (
            url.find('?') !=
            std::string::npos
        ) {
            url =
                url.substr(
                    0,
                    url.find('?')
                );
        }

        if (
            url ==
            "/__phronova_reload"
        ) {
            std::string response =
                "HTTP/1.1 200 OK\r\n"
                "Content-Type: "
                "text/event-stream\r\n"
                "Cache-Control: no-cache\r\n"
                "Connection: keep-alive\r\n"
                "\r\n"
                ": connected\r\n"
                "\r\n";

            send(
                client,
                response.c_str(),
                static_cast<int>(
                    response.size()
                ),
                0
            );

            addReloadClient(client);

            return;
        }

        if (
            url.rfind(
                "/__phronova_event/",
                0
            ) == 0
        ) {
            std::string eventId =
                url.substr(
                    std::string("/__phronova_event/").length()
                );

            try {
                int id = std::stoi(eventId);

                addPhronovaEvent(id);
            }
            catch (...) {
                // Ignore invalid event IDs
            }

            std::string response =
                "HTTP/1.1 200 OK\r\n"
                "Content-Type: text/plain\r\n"
                "Content-Length: 2\r\n"
                "Connection: close\r\n"
                "\r\n"
                "OK";

            send(
                client,
                response.c_str(),
                static_cast<int>(
                    response.size()
                ),
                0
            );

            closesocket(client);

            return;
        }

        if (
            url ==
            "/__phronova_events"
        ) {
            std::vector<int> events =
                getPhronovaEvents();

            std::string body;

            for (int id : events) {
                body +=
                    std::to_string(id) +
                    "\n";
            }

            std::string response =
                "HTTP/1.1 200 OK\r\n"
                "Content-Type: text/plain\r\n"
                "Content-Length: " +
                std::to_string(body.size()) +
                "\r\n"
                "Connection: close\r\n"
                "\r\n" +
                body;

            send(
                client,
                response.c_str(),
                static_cast<int>(
                    response.size()
                ),
                0
            );

            closesocket(client);

            return;
        }

        if (
    url.rfind(
        "/__phronova_reactive_update/",
        0
    ) == 0
) {
    std::string path =
        url.substr(
            std::string("/__phronova_reactive_update/").length()
        );

    size_t separator =
        path.find('/');

    if (separator != std::string::npos) {
        try {
            int id =
                std::stoi(
                    path.substr(0, separator)
                );

            std::string value =
                path.substr(separator + 1);

            addReactiveUpdate(id, value);
            std::cout
                << "Reactive update: "
                << id
                << " = "
                << value
                << "\n";
        }
        catch (...) {
            // Ignore invalid reactive updates
        }
    }

    std::string response =
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 2\r\n"
        "Connection: close\r\n"
        "\r\n"
        "OK";

    send(
        client,
        response.c_str(),
        static_cast<int>(
            response.size()
        ),
        0
    );

    closesocket(client);

    return;
}

        if (
            url ==
            "/__phronova_reactive_updates"
        ) {
            std::vector<ReactiveUpdate> updates =
                getReactiveUpdates();

            std::cout
                << "Sending reactive updates: "
                << updates.size()
                << "\n";

            std::string body;

            for (const auto& update : updates) {
                body +=
                    std::to_string(update.id) +
                    "|" +
                    update.value +
                    "\n";
            }

            std::string response =
                "HTTP/1.1 200 OK\r\n"
                "Content-Type: text/plain\r\n"
                "Content-Length: " +
                std::to_string(body.size()) +
                "\r\n"
                "Connection: close\r\n"
                "\r\n" +
                body;

            send(
                client,
                response.c_str(),
                static_cast<int>(
                    response.size()
                ),
                0
            );

            closesocket(client);

            return;
        }
        if (
            url ==
            "/__phronova_reload_trigger"
        ) {
            notifyReload();

            std::string response =
                "HTTP/1.1 200 OK\r\n"
                "Content-Type: text/plain\r\n"
                "Content-Length: 2\r\n"
                "Connection: close\r\n"
                "\r\n"
                "OK";

            send(
                client,
                response.c_str(),
                static_cast<int>(
                    response.size()
                ),
                0
            );

            closesocket(client);

            return;
        }

        if (!isSafePath(url)) {

            std::string response =
                "HTTP/1.1 400 Bad Request\r\n"
                "Content-Length: 0\r\n"
                "Connection: close\r\n"
                "\r\n";

            send(
                client,
                response.c_str(),
                static_cast<int>(
                    response.size()
                ),
                0
            );

            closesocket(client);

            return;
        }

        std::string contentType =
            "text/html";

        fs::path requestedFile;

        if (
            url ==
            "/src/style.css"
        ) {
            requestedFile =
                cssFile;

            contentType =
                "text/css";
        }
        else if (
            url.rfind(
                "/assets/",
                0
            ) == 0
        ) {
            std::string assetPath =
                url.substr(
                    1
                );

            requestedFile =
                generatedDir /
                fs::path(assetPath);
           /* std::ofstream debugFile(
                "phronova-server-debug.txt",
                std::ios::app
            );

            debugFile
                << "Path: "
                << requestedFile.string()
                << "\n";

            debugFile
                << "Exists: "
                << fs::exists(requestedFile)
                << "\n";

            debugFile
                << "Size: ";
            
            if (fs::exists(requestedFile)) {
                debugFile << fs::file_size(requestedFile);
            } else {
                debugFile << "N/A";
            }

            debugFile << "\n\n";

            debugFile.close();*/

            contentType =
                getContentType(
                    requestedFile
                );
        }
        else if (
            url.find('.', url.find_last_of('/')) !=
            std::string::npos
        ) {
            requestedFile =
                generatedDir /
                url.substr(1);

            contentType =
                getContentType(
                    requestedFile
                );
        }
        else {

            if (
                url == "/"
            ) {
                requestedFile =
                    generatedDir /
                    "index.html";
            }

            else {

                requestedFile =
                    generatedDir /
                    url.substr(1) /
                    "index.html";
            }

            contentType =
                "text/html";
        }
        std::string body =
            readFile(
                requestedFile
            );

        std::string status;

        if (body.empty()) {

            status =
                "404 Not Found";

            body =
                "404 - Page not found";

            contentType =
                "text/plain";
        }

        else {

            status =
                "200 OK";
        }


        std::string response =
            "HTTP/1.1 " +
            status +
            "\r\n" +

            "Content-Type: " +
            contentType +
            "; charset=utf-8\r\n" +

            "Content-Length: " +
            std::to_string(
                body.size()
            ) +
            "\r\n" +

            "Connection: close\r\n" +

            "\r\n" +

            body;

        send(
            client,
            response.c_str(),
            static_cast<int>(
                response.size()
            ),
            0
        );
    
    closesocket(client);
}
int main(
    int argc,
    char* argv[]
) {
    if (argc < 3) {
        std::cout
            << "Usage: server.exe "
            << "<generated_dir> "
            << "<css_file>\n";

        return 1;
    }

    WSADATA info{};

    SetConsoleCtrlHandler(
        consoleHandler,
        TRUE
    );

    if (
        WSAStartup(
            MAKEWORD(2, 2),
            &info
        ) != 0
    ) {
        std::cout
            << "Startup failed\n";

        return 1;
    }

    SOCKET server =
        socket(
            AF_INET,
            SOCK_STREAM,
            IPPROTO_TCP
        );
    serverSocket = server;

    if (
        server == INVALID_SOCKET
    ) {
        WSACleanup();
        return 1;
    }

    sockaddr_in address{};

    address.sin_family =
        AF_INET;

    address.sin_port =
        htons(1125);

    address.sin_addr.s_addr =
        htonl(INADDR_LOOPBACK);

    if (
        bind(
            server,
            reinterpret_cast<sockaddr*>(
                &address
            ),
            sizeof(address)
        ) == SOCKET_ERROR
    ) {
        std::cout
            << "Bind failed\n";

        closesocket(server);
        WSACleanup();

        return 1;
    }

    if (
        listen(
            server,
            SOMAXCONN
        ) == SOCKET_ERROR
    ) {
        closesocket(server);
        WSACleanup();

        return 1;
    }

    fs::path generatedDir =
        fs::absolute(argv[1]);

    fs::path cssFile =
        fs::absolute(argv[2]);

    std::cout
        << "Phronova development server "
        << "running on port 1125\n";

    while (serverRunning) {

        SOCKET client =
            accept(
                server,
                nullptr,
                nullptr
            );

        if (client == INVALID_SOCKET) {
            if (!serverRunning) {
                break;
            }
            continue;
        }

        std::thread(
            handleClient,
            client,
            generatedDir,
            cssFile
        ).detach();
    }
    closesocket(server);
    WSACleanup();

    return 0;
}