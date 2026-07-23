using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

internal static class NativeHostLauncher
{
    public static int Main()
    {
        string appDirectory = AppDomain.CurrentDomain.BaseDirectory;
        var startInfo = new ProcessStartInfo
        {
            FileName = Path.Combine(appDirectory, "node", "node.exe"),
            Arguments = "\"" + Path.Combine(appDirectory, "native-host.mjs") + "\"",
            WorkingDirectory = appDirectory,
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden
        };
        using (var child = Process.Start(startInfo))
        {
            if (child == null) return 2;
            Stream input = Console.OpenStandardInput();
            Stream output = Console.OpenStandardOutput();
            Task stdin = input.CopyToAsync(child.StandardInput.BaseStream)
                .ContinueWith(_ => child.StandardInput.Close());
            Task stdout = child.StandardOutput.BaseStream.CopyToAsync(output);
            Task stderr = child.StandardError.BaseStream.CopyToAsync(Stream.Null);
            child.WaitForExit();
            Task.WaitAll(stdout, stderr);
            return child.ExitCode;
        }
    }
}
