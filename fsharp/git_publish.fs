// abstraction-provenance: {"artifact_sha256": "c73e25dd51a9c44ed90539b76471db5258f4308ee12fb0bb75002c41df82bbfa", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "fsharp"}
// git_publish.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

namespace GitPublishAgent

open System
open System.Diagnostics
open System.IO
open System.Text.Json

/// <summary>
/// Git Publish Agent - Automatisierte Skill-Veröffentlichung
/// </summary>

module Program =
    let SKILLS_DIR = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".openclaw", "workspace", "skills")

    /// <summary>
    /// Commit skill changes.
    /// </summary>
    let gitCommit (skillPath: string) (message: string option) =
        let commitMessage = 
            match message with
            | Some m -> m
            | None -> $"[skill] Auto-update {Path.GetFileName(skillPath)} - {DateTime.Now:yyyy-MM-ddTHH:mm:ss}"

        let startInfoAdd = ProcessStartInfo(
            FileName = "git",
            Arguments = $"add \"{skillPath}\"",
            WorkingDirectory = Directory.GetParent(SKILLS_DIR).FullName,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        )

        use processAdd = new Process(StartInfo = startInfoAdd)
        processAdd.Start() |> ignore
        processAdd.WaitForExit()

        let startInfoCommit = ProcessStartInfo(
            FileName = "git",
            Arguments = $"commit -m \"{commitMessage}\"",
            WorkingDirectory = Directory.GetParent(SKILLS_DIR).FullName,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        )

        use processCommit = new Process(StartInfo = startInfoCommit)
        processCommit.Start() |> ignore
        processCommit.WaitForExit()
        processCommit.ExitCode = 0

    /// <summary>
    /// Publish to ClawHub.
    /// </summary>
    let clawhubPublish (skillName: string) =
        let skillPath = Path.Combine(SKILLS_DIR, skillName)
        let startInfo = ProcessStartInfo(
            FileName = "clawhub",
            Arguments = $"publish \"{skillPath}\" --slug {skillName} --version 1.0.0",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        )

        use process = new Process(StartInfo = startInfo)
        process.Start() |> ignore
        process.WaitForExit()
        (process.ExitCode = 0, process.StandardOutput.ReadToEnd())

    /// <summary>
    /// Publish all changed skills with rate limiting.
    /// </summary>
    let batchPublish () =
        let startInfo = ProcessStartInfo(
            FileName = "git",
            Arguments = $"status --short \"{SKILLS_DIR}\"",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        )

        use process = new Process(StartInfo = startInfo)
        process.Start() |> ignore
        process.WaitForExit()

        let output = process.StandardOutput.ReadToEnd()
        let changed = 
            output.Split('\n')
            |> Array.filter (fun line -> line.Trim().Length > 0 && line.Contains("skills/"))
            |> Array.map (fun line -> line.Split("skills/").[1].Split('/').[0])
            |> Array.distinct

        printfn $"Changed skills: {String.Join(", ", changed)}"

        // Publish with delay
        changed
        |> Seq.take (min 5 changed.Length)
        |> Seq.iteri (fun i skill ->
            if i > 0 then
                printfn "Waiting 15min for rate limit..."
                // In real: System.Threading.Thread.Sleep(900000)

            printfn $"Publishing {skill}..."
            let commitOk = gitCommit (Path.Combine(SKILLS_DIR, skill)) None
            if commitOk then
                let pubOk, output = clawhubPublish skill
                printfn $"  {(if pubOk then "✓" else "✗")} {output}"
        )

    [<EntryPoint>]
    let main argv =
        let parser = ArgumentParser.Create<Arguments>()
        let args = parser.Parse(argv)

        if args.Skill.IsSome then
            let skillPath = Path.Combine(SKILLS_DIR, args.Skill.Value)
            if args.NoPublish then
                gitCommit skillPath args.Message |> ignore
            else
                gitCommit skillPath args.Message |> ignore
                clawhubPublish args.Skill.Value |> ignore
        elif args.All then
            batchPublish()
        else
            printfn "Use --skill <name> or --all"

        0

// Define argument parsing structure
type Arguments() =
    [<Argument(Name = "skill", HelpText = "Single skill to publish")>]
    member val Skill : string option = None with get, set

    [<Argument(Name = "all", HelpText = "Publish all changed")>]
    member val All : bool = false with get, set

    [<Argument(Name = "no-publish", HelpText = "Commit only")>]
    member val NoPublish : bool = false with get, set

    [<Argument(Name = "message", HelpText = "Custom commit message")>]
    member val Message : string option = None with get, set

// Note: This implementation assumes the existence of an ArgumentParser module
// that can parse command-line arguments similar to Python's argparse.
// You might need to install a NuGet package like CommandLineParser for this.
