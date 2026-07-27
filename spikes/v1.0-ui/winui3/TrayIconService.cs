using System.Runtime.InteropServices;
using Microsoft.UI.Dispatching;

namespace LmmWinUiSpike;

internal sealed class TrayIconService : IDisposable
{
    private const uint CallbackMessage = 0x8001;
    private const uint WmCommand = 0x0111;
    private const uint WmLeftButtonUp = 0x0202;
    private const uint WmRightButtonUp = 0x0205;
    private const int GwlpWndProc = -4;
    private const uint NimAdd = 0x00000000;
    private const uint NimDelete = 0x00000002;
    private const uint NimSetVersion = 0x00000004;
    private const uint NifMessage = 0x00000001;
    private const uint NifIcon = 0x00000002;
    private const uint NifTip = 0x00000004;
    private const uint NotifyIconVersion4 = 4;
    private const uint MfString = 0x00000000;
    private const uint MfSeparator = 0x00000800;
    private const uint TpmRightButton = 0x0002;
    private const uint TpmBottomAlign = 0x0020;
    private const uint IdiApplication = 32512;
    private const uint MenuToggle = 1;
    private const uint MenuSettings = 2;
    private const uint MenuExit = 3;

    private readonly IntPtr _windowHandle;
    private readonly DispatcherQueue _dispatcher;
    private readonly Action _toggle;
    private readonly Action _settings;
    private readonly Action _exit;
    private readonly WindowProcedure _windowProcedure;
    private readonly IntPtr _previousWindowProcedure;
    private NotifyIconData _iconData;
    private bool _disposed;

    public TrayIconService(
        IntPtr windowHandle,
        DispatcherQueue dispatcher,
        Action toggle,
        Action settings,
        Action exit)
    {
        _windowHandle = windowHandle;
        _dispatcher = dispatcher;
        _toggle = toggle;
        _settings = settings;
        _exit = exit;
        _windowProcedure = WindowMessage;
        _previousWindowProcedure = SetWindowLongPtr(
            _windowHandle,
            GwlpWndProc,
            Marshal.GetFunctionPointerForDelegate(_windowProcedure));

        _iconData = new NotifyIconData
        {
            Size = (uint)Marshal.SizeOf<NotifyIconData>(),
            WindowHandle = _windowHandle,
            Id = 1,
            Flags = NifMessage | NifIcon | NifTip,
            CallbackMessage = CallbackMessage,
            IconHandle = LoadIcon(IntPtr.Zero, new IntPtr(IdiApplication)),
            ToolTip = "LetsMakeMoney v1.0 技术 Spike"
        };
        if (!ShellNotifyIcon(NimAdd, ref _iconData))
        {
            throw new InvalidOperationException(
                $"创建托盘图标失败：{Marshal.GetLastWin32Error()}");
        }
        _iconData.Version = NotifyIconVersion4;
        _ = ShellNotifyIcon(NimSetVersion, ref _iconData);
    }

    private IntPtr WindowMessage(
        IntPtr windowHandle,
        uint message,
        IntPtr wordParameter,
        IntPtr longParameter)
    {
        if (message == CallbackMessage)
        {
            var mouseMessage = (uint)(longParameter.ToInt64() & 0xffff);
            if (mouseMessage == WmLeftButtonUp)
            {
                _dispatcher.TryEnqueue(() => _toggle());
                return IntPtr.Zero;
            }
            if (mouseMessage == WmRightButtonUp)
            {
                ShowContextMenu();
                return IntPtr.Zero;
            }
        }
        else if (message == WmCommand)
        {
            var command = (uint)(wordParameter.ToInt64() & 0xffff);
            switch (command)
            {
                case MenuToggle:
                    _dispatcher.TryEnqueue(() => _toggle());
                    break;
                case MenuSettings:
                    _dispatcher.TryEnqueue(() => _settings());
                    break;
                case MenuExit:
                    _dispatcher.TryEnqueue(() => _exit());
                    break;
            }
            return IntPtr.Zero;
        }

        return CallWindowProc(
            _previousWindowProcedure,
            windowHandle,
            message,
            wordParameter,
            longParameter);
    }

    private void ShowContextMenu()
    {
        if (!GetCursorPosition(out var point))
        {
            return;
        }
        var menu = CreatePopupMenu();
        if (menu == IntPtr.Zero)
        {
            return;
        }
        try
        {
            _ = AppendMenu(menu, MfString, MenuToggle, "显示 / 隐藏窗口");
            _ = AppendMenu(menu, MfString, MenuSettings, "设置");
            _ = AppendMenu(menu, MfSeparator, 0, null);
            _ = AppendMenu(menu, MfString, MenuExit, "退出");
            _ = SetForegroundWindow(_windowHandle);
            _ = TrackPopupMenu(
                menu,
                TpmRightButton | TpmBottomAlign,
                point.X,
                point.Y,
                0,
                _windowHandle,
                IntPtr.Zero);
        }
        finally
        {
            _ = DestroyMenu(menu);
        }
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }
        _disposed = true;
        _ = ShellNotifyIcon(NimDelete, ref _iconData);
        if (_previousWindowProcedure != IntPtr.Zero)
        {
            _ = SetWindowLongPtr(_windowHandle, GwlpWndProc, _previousWindowProcedure);
        }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct NotifyIconData
    {
        public uint Size;
        public IntPtr WindowHandle;
        public uint Id;
        public uint Flags;
        public uint CallbackMessage;
        public IntPtr IconHandle;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string ToolTip;

        public uint State;
        public uint StateMask;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string Info;

        public uint Version;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string InfoTitle;

        public uint InfoFlags;
        public Guid ItemGuid;
        public IntPtr BalloonIconHandle;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Point
    {
        public int X;
        public int Y;
    }

    private delegate IntPtr WindowProcedure(
        IntPtr windowHandle,
        uint message,
        IntPtr wordParameter,
        IntPtr longParameter);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool Shell_NotifyIconW(uint message, ref NotifyIconData data);

    private static bool ShellNotifyIcon(uint message, ref NotifyIconData data) =>
        Shell_NotifyIconW(message, ref data);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadIconW(IntPtr instance, IntPtr iconName);

    private static IntPtr LoadIcon(IntPtr instance, IntPtr iconName) =>
        LoadIconW(instance, iconName);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW", SetLastError = true)]
    private static extern IntPtr SetWindowLongPtr(
        IntPtr windowHandle,
        int index,
        IntPtr newValue);

    [DllImport("user32.dll", EntryPoint = "CallWindowProcW")]
    private static extern IntPtr CallWindowProc(
        IntPtr previousProcedure,
        IntPtr windowHandle,
        uint message,
        IntPtr wordParameter,
        IntPtr longParameter);

    [DllImport("user32.dll", EntryPoint = "GetCursorPos")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetCursorPosition(out Point point);

    [DllImport("user32.dll")]
    private static extern IntPtr CreatePopupMenu();

    [DllImport("user32.dll", EntryPoint = "AppendMenuW", CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool AppendMenu(
        IntPtr menu,
        uint flags,
        uint item,
        string? text);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool TrackPopupMenu(
        IntPtr menu,
        uint flags,
        int x,
        int y,
        int reserved,
        IntPtr windowHandle,
        IntPtr rectangle);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DestroyMenu(IntPtr menu);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetForegroundWindow(IntPtr windowHandle);
}
