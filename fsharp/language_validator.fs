// abstraction-provenance: {"artifact_sha256": "edb207abdc29e24d541d6112d9db45936a3dd01920fbca78f5b557e1703bcc18", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "fsharp"}
// language_validator.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

namespace LanguageValidator

open System
open System.Diagnostics
open System.IO
open System.Collections.Generic

type ValidationResult = {
    Language: string
    Valid: bool
    Errors: string list
    Warnings: string list
    DocUrl: string option
}

type LanguageConfig = {
    Cmd: string
    Args: string list
    Linter: string option
}

type LanguageValidator(language: string, useWebSearch: bool) =
    let languages = dict [
        "bash", { Cmd = "bash"; Args = ["-n"]; Linter = Some "shellcheck" }
        "sh", { Cmd = "sh"; Args = ["-n"]; Linter = Some "shellcheck" }
        "python", { Cmd = "python3"; Args = ["-m"; "py_compile"]; Linter = Some "pylint" }
        "perl", { Cmd = "perl"; Args = ["-c"]; Linter = Some "perlcritic" }
        "raku", { Cmd = "raku"; Args = ["-c"]; Linter = None }
        "powershell", { Cmd = "pwsh"; Args = ["-Command"; "Get-Command"]; Linter = None }
        "javascript", { Cmd = "node"; Args = ["--check"]; Linter = Some "eslint" }
        "tcl", { Cmd = "tclsh"; Args = []; Linter = None }
    ]
    
    let config = 
        match languages.TryGetValue(language.ToLower()) with
        | true, cfg -> cfg
        | false, _ -> failwith $"Unsupported language: {language}"
    
    let runProcess cmd args timeout =
        try
            use proc = new Process()
            proc.StartInfo.FileName <- cmd
            proc.StartInfo.Arguments <- String.concat " " args
            proc.StartInfo.UseShellExecute <- false
            proc.StartInfo.RedirectStandardOutput <- true
            proc.StartInfo.RedirectStandardError <- true
            proc.Start() |> ignore
            
            if proc.WaitForExit(timeout) then
                Ok { ExitCode = proc.ExitCode; StdOut = proc.StandardOutput.ReadToEnd(); StdErr = proc.StandardError.ReadToEnd() }
            else
                proc.Kill()
                Error "Validation timeout"
        with
        | :? FileNotFoundException -> Error $"Command not found: {cmd}"
        | ex -> Error ex.Message
    
    let fetchDocs() =
        if not useWebSearch then None
        else
            let docs = dict [
                "powershell", "https://docs.microsoft.com/powershell/"
                "raku", "https://docs.raku.org/"
                "tcl", "https://www.tcl.tk/"
            ]
            match docs.TryGetValue(language) with
            | true, url -> Some url
            | false, _ -> None
    
    member this.Validate(scriptPath: string) =
        let errors = ResizeArray()
        let warnings = ResizeArray()
        
        // Syntax check
        let result = runProcess config.Cmd (config.Args @ [scriptPath]) 30000
        match result with
        | Error msg -> errors.Add(msg)
        | Ok procResult when procResult.ExitCode <> 0 -> errors.Add(procResult.StdErr)
        | _ -> ()
        
        // Linter check if available
        match config.Linter with
        | Some linter ->
            let linterWarnings = this.RunLinter(scriptPath, linter)
            warnings.AddRange(linterWarnings)
        | None -> ()
        
        { Language = language
          Valid = errors.Count = 0
          Errors = List.ofSeq errors
          Warnings = List.ofSeq warnings
          DocUrl = if errors.Count > 0 then fetchDocs() else None }
    
    member private this.RunLinter(scriptPath: string, linter: string) =
        let warnings = ResizeArray()
        try
            match linter with
            | "shellcheck" ->
                let result = runProcess "shellcheck" ["-f"; "gcc"; scriptPath] 30000
                match result with
                | Ok procResult when not (String.IsNullOrEmpty(procResult.StdOut)) ->
                    procResult.StdOut.Split('\n', StringSplitOptions.RemoveEmptyEntries)
                    |> Array.iter warnings.Add
                | _ -> ()
            | "pylint" ->
                let result = runProcess "pylint" ["--output-format=parseable"; scriptPath] 30000
                match result with
                | Ok procResult when not (String.IsNullOrEmpty(procResult.StdOut)) ->
                    procResult.StdOut.Split('\n', StringSplitOptions.RemoveEmptyEntries)
                    |> Array.iter warnings.Add
                | _ -> ()
            | _ -> ()
        with
        | :? FileNotFoundException -> warnings.Add($"Linter not installed: {linter}")
        | _ -> ()
        
        List.ofSeq warnings

and ProcessResult = {
    ExitCode: int
    StdOut: string
    StdErr: string
}

module Program =
    [<EntryPoint>]
    let main argv =
        let lang = ref ""
        let script = ref ""
        let noWebSearch = ref false
        
        let rec parseArgs args =
            match args with
            | [] -> ()
            | "--lang" :: value :: rest ->
                lang := value
                parseArgs rest
            | "--no-websearch" :: rest ->
                noWebSearch := true
                parseArgs rest
            | arg :: rest when arg.StartsWith("-") ->
                failwith $"Unknown argument: {arg}"
            | arg :: rest ->
                script := arg
                parseArgs rest
        
        parseArgs (List.ofArray argv)
        
        if !script = "" || !lang = "" then
            printfn "Usage: language_validator <script> --lang <language>"
            1
        else
            try
                let validator = LanguageValidator(!lang, not !noWebSearch)
                let result = validator.Validate(!script)
                
                printfn $"Language: {result.Language}"
                printfn $"Valid: {result.Valid}"
                if not (List.isEmpty result.Errors) then
                    printfn $"Errors: {List.length result.Errors}"
                    result.Errors |> List.take (min 5 (List.length result.Errors))
                                  |> List.iter (fun err -> printfn $"  - {err}")
                if not (List.isEmpty result.Warnings) then
                    printfn $"Warnings: {List.length result.Warnings}"
                    result.Warnings |> List.take (min 5 (List.length result.Warnings))
                                   |> List.iter (fun warn -> printfn $"  - {warn}")
                match result.DocUrl with
                | Some url -> printfn $"Docs: {url}"
                | None -> ()
                
                if result.Valid then 0 else 1
            with
            | ex ->
                eprintfn $"Error: {ex.Message}"
                1
