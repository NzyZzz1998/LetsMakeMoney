using System.Text.Json;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.Graphics;
using Windows.UI.Text;
using WinRT.Interop;

namespace LmmWinUiSpike;

public sealed partial class MainWindow : Window
{
    private const string SavedBaseline = "10,000";
    private static readonly Brush PrimaryTextBrush =
        new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 47, 45, 42));
    private static readonly Brush MutedFeedbackBrush =
        new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 110, 107, 101));
    private static readonly Brush SuccessFeedbackBrush =
        new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 78, 138, 96));
    private static readonly Brush DangerFeedbackBrush =
        new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 180, 84, 72));
    private static readonly FontWeight NormalWeight = new() { Weight = 400 };
    private static readonly FontWeight SemiBoldWeight = new() { Weight = 600 };
    private AppWindow? _appWindow;
    private TrayIconService? _tray;
    private string _savedSalary = SavedBaseline;

    public MainWindow()
    {
        BuildProgrammaticUi();
        Title = "LetsMakeMoney";
    }

    private void BuildProgrammaticUi()
    {
        Root = new Grid { Background = Brush(252, 252, 251) };
        MiniView = BuildMiniView();
        WorkbenchView = BuildWorkbenchView();
        SettingsView = BuildSettingsView();
        Root.Children.Add(MiniView);
        Root.Children.Add(WorkbenchView);
        Root.Children.Add(SettingsView);
        Content = Root;
        Root.Loaded += Root_Loaded;
    }

    private void Root_Loaded(object sender, RoutedEventArgs e)
    {
        Root.Loaded -= Root_Loaded;
        InitializeRuntime();
    }

    private Grid BuildMiniView()
    {
        var view = new Grid { Padding = new Thickness(12) };
        AddColumn(view, 44);
        AddColumn(view, 12);
        AddStarColumn(view);
        AddColumn(view, 38);

        var open = Button("¥", OpenWorkbench_Click);
        open.Width = 40;
        open.Height = 40;
        open.Background = Brush(249, 190, 57);
        view.Children.Add(open);

        MiniDragRegion = new Grid();
        Grid.SetColumn(MiniDragRegion, 2);
        AddRow(MiniDragRegion, 18);
        AddRow(MiniDragRegion, 31);
        AddRow(MiniDragRegion, 8);
        AddRow(MiniDragRegion, 18);
        view.Children.Add(MiniDragRegion);
        MiniDragRegion.Children.Add(Text("今日已赚", 11, MutedFeedbackBrush));
        var status = Text("工作中", 11, SuccessFeedbackBrush);
        status.HorizontalAlignment = HorizontalAlignment.Right;
        MiniDragRegion.Children.Add(status);
        var amount = Text("¥ 186.42", 25, null, SemiBoldWeight);
        Grid.SetRow(amount, 1);
        MiniDragRegion.Children.Add(amount);
        var progress = ProgressTrack(56, 5);
        Grid.SetRow(progress, 2);
        MiniDragRegion.Children.Add(progress);
        var detail = Text("工作进度 56%                              距离下班 4:38:20", 10, MutedFeedbackBrush);
        Grid.SetRow(detail, 3);
        MiniDragRegion.Children.Add(detail);

        var settings = Button("⚙", OpenSettings_Click);
        settings.Width = 38;
        settings.Height = 34;
        Grid.SetColumn(settings, 3);
        view.Children.Add(settings);
        return view;
    }

    private Grid BuildWorkbenchView()
    {
        var view = new Grid { Visibility = Visibility.Collapsed };
        AddRow(view, 52);
        AddStarRow(view);

        WorkbenchDragRegion = new Grid
        {
            Padding = new Thickness(18, 8, 12, 8),
            BorderBrush = Brush(221, 218, 212),
            BorderThickness = new Thickness(0, 0, 0, 1)
        };
        AddStarColumn(WorkbenchDragRegion);
        AddColumn(WorkbenchDragRegion, 84);
        AddColumn(WorkbenchDragRegion, 8);
        AddColumn(WorkbenchDragRegion, 38);
        WorkbenchDragRegion.Children.Add(Text("LetsMakeMoney", 14, null, SemiBoldWeight, VerticalAlignment.Center));
        var settings = Button("设置", OpenSettings_Click);
        Grid.SetColumn(settings, 1);
        WorkbenchDragRegion.Children.Add(settings);
        var close = Button("×", BackToMini_Click);
        Grid.SetColumn(close, 3);
        WorkbenchDragRegion.Children.Add(close);
        view.Children.Add(WorkbenchDragRegion);

        var body = new Grid();
        AddColumn(body, 150);
        AddStarColumn(body);
        Grid.SetRow(body, 1);
        var navigation = new StackPanel
        {
            Padding = new Thickness(12, 18, 12, 12),
            Spacing = 8,
            Background = Brush(245, 245, 243)
        };
        navigation.Children.Add(Button("今日", ShowToday_Click));
        navigation.Children.Add(Button("日历", ShowCalendar_Click));
        navigation.Children.Add(Button("隐藏到托盘", HideToTray_Click));
        body.Children.Add(navigation);

        var content = new Grid { Padding = new Thickness(28, 24, 28, 24) };
        Grid.SetColumn(content, 1);
        TodayContent = BuildTodayContent();
        CalendarContent = BuildCalendarContent();
        CalendarContent.Visibility = Visibility.Collapsed;
        content.Children.Add(TodayContent);
        content.Children.Add(CalendarContent);
        body.Children.Add(content);
        view.Children.Add(body);
        return view;
    }

    private Grid BuildTodayContent()
    {
        var grid = new Grid();
        AddRow(grid, 68);
        AddStarRow(grid);
        var heading = new StackPanel { Spacing = 5 };
        heading.Children.Add(Text("今天，继续把时间变成看得见的进度", 24, null, SemiBoldWeight));
        heading.Children.Add(Text("2026 年 7 月 23 日 · 周四", 12, MutedFeedbackBrush));
        grid.Children.Add(heading);

        var cards = new Grid();
        AddStarColumn(cards);
        AddColumn(cards, 18);
        AddStarColumn(cards);
        Grid.SetRow(cards, 1);
        var income = Card();
        income.Children.Add(Text("今日已赚", 12, MutedFeedbackBrush));
        income.Children.Add(Text("¥ 186.42", 38, null, SemiBoldWeight));
        income.Children.Add(Text("日薪 ¥ 500.00 · 时薪 ¥ 62.50", 12, MutedFeedbackBrush));
        income.Children.Add(Text("收入进度 56%", 12));
        income.Children.Add(ProgressTrack(56, 8));
        income.Children.Add(Text("本月累计                 ¥ 3,842.00", 13));
        income.Children.Add(Text("本月工作日               8 / 20 天", 13));
        income.Children.Add(Text("距离下班                 4:38:20", 13));
        cards.Children.Add(WrapCard(income));

        var schedule = Card();
        schedule.Children.Add(Text("今日安排", 12, MutedFeedbackBrush));
        schedule.Children.Add(Text("08:00–18:00", 18, null, SemiBoldWeight));
        schedule.Children.Add(Text("08:00    开始工作", 14));
        schedule.Children.Add(Text("12:00    午休 12:00–14:00", 14));
        schedule.Children.Add(Text("18:00    结束工作", 14));
        var scheduleCard = WrapCard(schedule);
        Grid.SetColumn(scheduleCard, 2);
        cards.Children.Add(scheduleCard);
        grid.Children.Add(cards);
        return grid;
    }

    private Grid BuildCalendarContent()
    {
        var grid = new Grid();
        var stack = new StackPanel { Spacing = 16 };
        stack.Children.Add(Text("收入日历", 24, null, SemiBoldWeight));
        stack.Children.Add(Text("只记录工作日、调休、节假日与收入结果", 12, MutedFeedbackBrush));
        stack.Children.Add(Text(
            "                         2026 年 7 月\n\n" +
            "日    一    二    三    四    五    六\n" +
            "               1     2     3     4\n" +
            " 5     6     7     8     9    10    11\n" +
            "12    13    14    15    16    17    18\n" +
            "19    20    21    22    23    24    25\n" +
            "26    27    28    29    30    31", 18));
        grid.Children.Add(stack);
        return grid;
    }

    private Grid BuildSettingsView()
    {
        var view = new Grid { Visibility = Visibility.Collapsed };
        AddRow(view, 52);
        AddStarRow(view);
        AddRow(view, 58);

        SettingsDragRegion = new Grid
        {
            Padding = new Thickness(18, 8, 12, 8),
            BorderBrush = Brush(221, 218, 212),
            BorderThickness = new Thickness(0, 0, 0, 1)
        };
        AddStarColumn(SettingsDragRegion);
        AddColumn(SettingsDragRegion, 38);
        SettingsDragRegion.Children.Add(Text("设置", 14, null, SemiBoldWeight, VerticalAlignment.Center));
        var close = Button("×", BackToMini_Click);
        Grid.SetColumn(close, 1);
        SettingsDragRegion.Children.Add(close);
        view.Children.Add(SettingsDragRegion);

        var body = new Grid();
        AddColumn(body, 178);
        AddStarColumn(body);
        Grid.SetRow(body, 1);
        var navigation = new StackPanel
        {
            Padding = new Thickness(14, 20, 14, 14),
            Spacing = 8,
            Background = Brush(245, 245, 243)
        };
        navigation.Children.Add(Text("偏好设置", 16, null, SemiBoldWeight));
        navigation.Children.Add(Text("更改只保存在本机", 11, MutedFeedbackBrush));
        navigation.Children.Add(new Button { Content = "收入与作息", Height = 38 });
        navigation.Children.Add(new Button { Content = "日历", Height = 38, IsEnabled = false });
        navigation.Children.Add(new Button { Content = "窗口与启动", Height = 38, IsEnabled = false });
        navigation.Children.Add(new Button { Content = "数据与支持", Height = 38, IsEnabled = false });
        body.Children.Add(navigation);

        var form = new StackPanel { Padding = new Thickness(28, 24, 28, 20), Spacing = 14 };
        form.Children.Add(Text("收入与作息", 24, null, SemiBoldWeight));
        form.Children.Add(Text("用于计算日薪、时薪、今日收益和工作进度。", 12, MutedFeedbackBrush));
        form.Children.Add(Text("收入", 12, SuccessFeedbackBrush, SemiBoldWeight));
        SalaryInput = new TextBox { Width = 138, Height = 36, Text = SavedBaseline, TextAlignment = TextAlignment.Right };
        form.Children.Add(FormRow("月薪", SalaryInput));
        form.Children.Add(FormRow("休息模式", Combo("双休", "单休", "大小周")));
        form.Children.Add(Text("工作时间", 12, SuccessFeedbackBrush, SemiBoldWeight));
        form.Children.Add(FormRow("上班时间", Combo("08:00", "09:00")));
        form.Children.Add(FormRow("午休时长", Combo("2 小时", "1 小时")));
        FailureToggle = new CheckBox { Content = "模拟配置写入失败（技术 Spike）", Foreground = MutedFeedbackBrush };
        form.Children.Add(FailureToggle);
        var scroll = new ScrollViewer { Content = form };
        Grid.SetColumn(scroll, 1);
        body.Children.Add(scroll);
        view.Children.Add(body);

        var footer = new Grid
        {
            Padding = new Thickness(20, 10, 20, 10),
            BorderBrush = Brush(221, 218, 212),
            BorderThickness = new Thickness(0, 1, 0, 0)
        };
        AddStarColumn(footer);
        AddColumn(footer, 96);
        AddColumn(footer, 10);
        AddColumn(footer, 88);
        FeedbackText = Text("没有未保存的更改", 12, MutedFeedbackBrush, null, VerticalAlignment.Center);
        footer.Children.Add(FeedbackText);
        var reset = Button("恢复默认", ResetSettings_Click);
        Grid.SetColumn(reset, 1);
        footer.Children.Add(reset);
        var save = Button("保存", SaveSettings_Click);
        save.Background = Brush(233, 169, 35);
        Grid.SetColumn(save, 3);
        footer.Children.Add(save);
        Grid.SetRow(footer, 2);
        view.Children.Add(footer);
        return view;
    }

    private static Border WrapCard(StackPanel content) =>
        new()
        {
            Padding = new Thickness(20),
            Background = Brush(255, 255, 255),
            BorderBrush = Brush(221, 218, 212),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(10),
            Child = content
        };

    private static StackPanel Card() => new() { Spacing = 13 };

    private static Grid FormRow(string label, Control control)
    {
        var row = new Grid { Height = 54 };
        AddStarColumn(row);
        AddColumn(row, 150);
        row.Children.Add(Text(label, 13, null, SemiBoldWeight, VerticalAlignment.Center));
        control.HorizontalAlignment = HorizontalAlignment.Right;
        Grid.SetColumn(control, 1);
        row.Children.Add(control);
        return row;
    }

    private static ComboBox Combo(params string[] options)
    {
        var combo = new ComboBox { Width = 138, Height = 36, SelectedIndex = 0 };
        foreach (var option in options)
        {
            combo.Items.Add(option);
        }
        return combo;
    }

    private static Button Button(string label, RoutedEventHandler handler)
    {
        var button = new Button
        {
            Content = label,
            Height = 36,
            Foreground = PrimaryTextBrush,
            Background = Brush(248, 247, 244),
            BorderBrush = Brush(221, 218, 212),
            BorderThickness = new Thickness(1)
        };
        button.Click += handler;
        return button;
    }

    private static TextBlock Text(
        string value,
        double size,
        Brush? foreground = null,
        FontWeight? weight = null,
        VerticalAlignment vertical = VerticalAlignment.Stretch)
    {
        var text = new TextBlock
        {
            Text = value,
            FontSize = size,
            FontWeight = weight ?? NormalWeight,
            VerticalAlignment = vertical,
            TextWrapping = TextWrapping.Wrap
        };
        text.Foreground = foreground ?? PrimaryTextBrush;
        return text;
    }

    private static SolidColorBrush Brush(byte red, byte green, byte blue) =>
        new(Microsoft.UI.ColorHelper.FromArgb(255, red, green, blue));

    private static Border ProgressTrack(double value, double height)
    {
        var track = new Grid();
        track.ColumnDefinitions.Add(new ColumnDefinition
        {
            Width = new GridLength(Math.Clamp(value, 0, 100), GridUnitType.Star)
        });
        track.ColumnDefinitions.Add(new ColumnDefinition
        {
            Width = new GridLength(Math.Max(100 - value, 0.001), GridUnitType.Star)
        });
        var fill = new Border
        {
            Background = Brush(233, 169, 35),
            CornerRadius = new CornerRadius(height / 2)
        };
        track.Children.Add(fill);
        return new Border
        {
            Height = height,
            Background = Brush(232, 230, 225),
            CornerRadius = new CornerRadius(height / 2),
            Child = track
        };
    }

    private static void AddColumn(Grid grid, double width) =>
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(width) });

    private static void AddStarColumn(Grid grid) =>
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

    private static void AddRow(Grid grid, double height) =>
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(height) });

    private static void AddStarRow(Grid grid) =>
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

    public void InitializeRuntime()
    {
        if (_appWindow is not null)
        {
            return;
        }

        var hwnd = WindowNative.GetWindowHandle(this);
        _appWindow = AppWindow.GetFromWindowId(Microsoft.UI.Win32Interop.GetWindowIdFromWindow(hwnd));
        _appWindow.Closing += (_, args) =>
        {
            args.Cancel = true;
            _appWindow.Hide();
        };
        ShowMode("mini");
    }

    private void ShowMode(string mode)
    {
        if (_appWindow is null)
        {
            return;
        }

        MiniView.Visibility = mode == "mini" ? Visibility.Visible : Visibility.Collapsed;
        WorkbenchView.Visibility = mode == "workbench" ? Visibility.Visible : Visibility.Collapsed;
        SettingsView.Visibility = mode == "settings" ? Visibility.Visible : Visibility.Collapsed;
        switch (mode)
        {
            case "mini":
                ResizeClientDip(344, 120);
                break;
            case "workbench":
                ResizeClientDip(820, 620);
                break;
            case "settings":
                ResizeClientDip(720, 540);
                break;
        }
        _appWindow.Show();
        Activate();
    }

    private void ResizeClientDip(double width, double height)
    {
        if (_appWindow is null)
        {
            return;
        }

        var scale = Root.XamlRoot?.RasterizationScale ?? 1.0;
        _appWindow.ResizeClient(new SizeInt32(
            (int)Math.Round(width * scale),
            (int)Math.Round(height * scale)));
    }

    private void RestoreFromTray()
    {
        if (_appWindow is null)
        {
            return;
        }

        _appWindow.Show();
        Activate();
    }

    private void OpenSettingsFromTray() => ShowMode("settings");

    private void OpenWorkbench_Click(object sender, RoutedEventArgs e) => ShowMode("workbench");

    private void OpenSettings_Click(object sender, RoutedEventArgs e) => ShowMode("settings");

    private void BackToMini_Click(object sender, RoutedEventArgs e) => ShowMode("mini");

    private void HideToTray_Click(object sender, RoutedEventArgs e) => _appWindow?.Hide();

    private void MiniMore_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Microsoft.UI.Xaml.Controls.Button button)
        {
            button.Flyout?.ShowAt(button);
        }
    }

    private void ShowToday_Click(object sender, RoutedEventArgs e)
    {
        TodayContent.Visibility = Visibility.Visible;
        CalendarContent.Visibility = Visibility.Collapsed;
    }

    private void ShowCalendar_Click(object sender, RoutedEventArgs e)
    {
        TodayContent.Visibility = Visibility.Collapsed;
        CalendarContent.Visibility = Visibility.Visible;
    }

    private async void SaveSettings_Click(object sender, RoutedEventArgs e)
    {
        if (FailureToggle.IsChecked == true)
        {
            FeedbackText.Text = "保存失败：配置文件暂时不可写，输入已保留";
            FeedbackText.Foreground = DangerFeedbackBrush;
            return;
        }
        var normalized = SalaryInput.Text.Trim();
        if (normalized == _savedSalary)
        {
            FeedbackText.Text = "没有需要保存的更改";
            FeedbackText.Foreground = MutedFeedbackBrush;
            return;
        }
        try
        {
            var directory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "LetsMakeMoney",
                "v1-spike");
            Directory.CreateDirectory(directory);
            var finalPath = Path.Combine(directory, "settings.json");
            var temporaryPath = finalPath + ".tmp";
            await File.WriteAllTextAsync(
                temporaryPath,
                JsonSerializer.Serialize(new { salary = normalized }, new JsonSerializerOptions { WriteIndented = true }));
            File.Move(temporaryPath, finalPath, true);
            _savedSalary = normalized;
            FeedbackText.Text = "已保存到本机";
            FeedbackText.Foreground = SuccessFeedbackBrush;
        }
        catch (Exception error)
        {
            FeedbackText.Text = $"保存失败：{error.Message}，输入已保留";
            FeedbackText.Foreground = DangerFeedbackBrush;
        }
    }

    private void ResetSettings_Click(object sender, RoutedEventArgs e)
    {
        SalaryInput.Text = SavedBaseline;
        FeedbackText.Text = "已恢复默认值，保存后生效";
        FeedbackText.Foreground = MutedFeedbackBrush;
    }
}
