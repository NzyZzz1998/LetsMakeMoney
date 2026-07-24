using System.Text;
using Microsoft.UI.Xaml;

namespace LmmWinUiSpike;

public partial class App : Application
{
    private MainWindow? _window;

    public App()
    {
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        try
        {
            _window = new MainWindow();
            _window.Activate();
        }
        catch (Exception error)
        {
            var logPath = Path.Combine(Path.GetTempPath(), "LmmWinUiSpike-startup.log");
            File.WriteAllText(logPath, error.ToString(), Encoding.UTF8);
            throw;
        }
    }

}
