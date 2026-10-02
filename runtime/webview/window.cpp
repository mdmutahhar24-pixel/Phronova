#define UNICODE
#define _UNICODE
#include <windows.h>
#include <WebView2.h>
#include <iostream>
#include <string>
#include <Shlwapi.h>
using CreateEnvironmentfn = HRESULT (STDAPICALLTYPE *)(PCWSTR, PCWSTR, ICoreWebView2EnvironmentOptions*, ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler*);

ICoreWebView2Controller* controller = nullptr;
ICoreWebView2* pointer = nullptr;

HINSTANCE hInstance = GetModuleHandle(nullptr);

LRESULT WindowProc(HWND handler, UINT uInt, WPARAM wParam, LPARAM lParam) {

    if (uInt == WM_DESTROY) {
        if (pointer != nullptr) {
            pointer -> Release();
            pointer = nullptr;
        }
        if (controller != nullptr) {
            controller -> Close();
            controller -> Release();
            controller = nullptr;
        }
        PostQuitMessage(0);
        return 0;
    } else {
        if (uInt == WM_SIZE && controller != nullptr) {
            RECT area{};
            BOOL rectA = GetClientRect(handler, &area);
            if (rectA) {
                controller -> put_Bounds(area);
                return 0;
            }
        }
        return DefWindowProcW(handler, uInt, wParam, lParam);
    }
}

WNDCLASSW wndClass = WNDCLASSW {0, WindowProc, 0, 0, hInstance, nullptr, LoadCursor(nullptr, IDC_ARROW), GetSysColorBrush(COLOR_WINDOW), nullptr, L"PhronovaWindow"};


class ControllerCompletedHandler : public ICoreWebView2CreateCoreWebView2ControllerCompletedHandler {
    public:
        ControllerCompletedHandler(HWND param, std::wstring param2) {
            wnd = param;
            htmlFile = param2;
        }
        HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppvObject) override {
            if (ppvObject == nullptr) {
                return E_POINTER;
            }

            *ppvObject = nullptr;

            if (IsEqualIID(riid, IID_IUnknown)) {
                *ppvObject = this;
                AddRef();
                return S_OK;
            }

            if (IsEqualIID(riid, IID_ICoreWebView2CreateCoreWebView2ControllerCompletedHandler)) {
                *ppvObject = this;
                AddRef();
                return S_OK;
            }

            return E_NOINTERFACE;
        }
        ULONG STDMETHODCALLTYPE AddRef() override {
            refCount += 1;
            return refCount;
        }
        ULONG STDMETHODCALLTYPE Release() override {
            ULONG localVar = 0;
            if (refCount > 0) {
                refCount -= 1;
                localVar = refCount;
            }
            if (refCount == 0) {
                localVar = refCount;
                delete this;
            }

            return localVar;

        }
        HRESULT STDMETHODCALLTYPE Invoke(HRESULT errorCode, ICoreWebView2Controller *result) override {
            if (FAILED(errorCode)) {
                return errorCode;
            } else {
                if (result != nullptr) {
                    RECT rect{};
                    BOOL cRect = GetClientRect(wnd, &rect);
                    if (!cRect) {
                        return E_FAIL;
                    }
                    result -> put_Bounds(rect);
                    result -> put_IsVisible(TRUE);
                    result -> AddRef();
                    controller = result;
                    HRESULT htmlConv = result -> get_CoreWebView2(&pointer);
                    if (FAILED(htmlConv)) {
                        return E_FAIL;
                    }

                    pointer -> Navigate(htmlFile.c_str());
                    
                }
                return S_OK;
            }
        }
    private:
        ULONG refCount = 1;
        HWND wnd;
        std::wstring htmlFile;
};

class EnvironmentCompletedHandler : public ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler {
    public:
        EnvironmentCompletedHandler(HWND param, std::wstring param2) {
            wnd = param;
            htmlFile = param2;
        }
        HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppvObject) override {
            if (ppvObject == nullptr) {
                return E_POINTER;
            }

            *ppvObject = nullptr;

            if (IsEqualIID(riid, IID_IUnknown)) {
                *ppvObject = this;
                AddRef();
                return S_OK;
            }

            if (IsEqualIID(riid, IID_ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler)) {
                *ppvObject = this;
                AddRef();
                return S_OK;
            }

            return E_NOINTERFACE;
        }
        ULONG STDMETHODCALLTYPE AddRef() override {
            refCount += 1;
            return refCount;
        }
        ULONG STDMETHODCALLTYPE Release() override {
            ULONG localVar = 0;
            if (refCount > 0) {
                refCount -= 1;
                localVar = refCount;
            }
            if (refCount == 0) {
                localVar = refCount;
                delete this;
            }

            return localVar;

        }
        HRESULT STDMETHODCALLTYPE Invoke(HRESULT errorCode, ICoreWebView2Environment *result) override {
            if (FAILED(errorCode)) {
                return errorCode;
            } else {
                result -> CreateCoreWebView2Controller(wnd, new ControllerCompletedHandler(wnd, htmlFile));
                return S_OK;
            }
        }
    private:
        ULONG refCount = 1;
        HWND wnd;
        std::wstring htmlFile;
};

int main(int argc, char* argv[]) {

    HWND console = GetConsoleWindow();

    if (console != nullptr) {
        ShowWindow(console, SW_HIDE);
    }

    if (argc < 2) {
        std::cout << "HTML file path required";
        return 1;
    }

    int convToWchar = MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, nullptr, 0);
    std::wstring htmlFile;
    htmlFile.resize(convToWchar);
    int convToWcharTwo = MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, htmlFile.data(), convToWchar);


    std::cout << argv[1];
    HRESULT com = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    if (!SUCCEEDED(com)) {
        return 1;
    }

    HMODULE lib = LoadLibraryW(L"WebView2Loader.dll");

    if (lib == nullptr) {
        return 1;
    }

    FARPROC libHandle = GetProcAddress(lib, "CreateCoreWebView2EnvironmentWithOptions");

    if (libHandle == nullptr) {
        return 1;
    }

    CreateEnvironmentfn convertLibHandle = reinterpret_cast<CreateEnvironmentfn>(libHandle);

    ATOM registered = RegisterClassW(&wndClass);

    if (registered == 0) {
        return 1;
    }

    HWND newWnd = CreateWindowW(L"PhronovaWindow", L"Phronova", WS_OVERLAPPEDWINDOW, 0, 0, 500, 500, nullptr, nullptr, hInstance, nullptr);

    if (newWnd == nullptr) {
        return 1;
    }

    EnvironmentCompletedHandler* envCompletedHander = new EnvironmentCompletedHandler(newWnd, htmlFile);

    ShowWindow(newWnd, SW_SHOW);

    if (FAILED(convertLibHandle(nullptr, nullptr, nullptr, envCompletedHander))) {
        return 1;
    }

    

    MSG message;

    while (GetMessageW(&message, nullptr, 0, 0) > 0) {
        TranslateMessage(&message);
        DispatchMessage(&message);
    }

    return 0;
}