// abstraction-provenance: {"artifact_sha256": "a18fb1045dafd02198f2913f7dc511f7c07d8975e31bbd1cd63c326b7193894a", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "fsharp"}
// gateway_transport.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module GatewayTransport

open System
open System.IO
open System.Net.Http
open System.Text
open System.Text.Json
open System.Threading

type TransportUnresolved(message: string, innerException: exn) =
    inherit Exception(message, innerException)

type TransportUnresolvedEx = 
    inherit TransportUnresolved
    new(message: string) = { inherit TransportUnresolved(message, null) }
    new(message: string, innerException: exn) = { inherit TransportUnresolved(message, innerException) }

let gateway_token() =
    let token = Environment.GetEnvironmentVariable("OPENCLAW_GATEWAY_TOKEN")
    if not(String.IsNullOrWhiteSpace(token)) then
        token.Trim()
    else
        let configPathEnv = Environment.GetEnvironmentVariable("OPENCLAW_CONFIG_PATH")
        let configPath = 
            if String.IsNullOrEmpty(configPathEnv) then
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".openclaw", "openclaw.json")
            else
                configPathEnv
        
        try
            let configJson = File.ReadAllText(configPath, Encoding.UTF8)
            let configDoc = JsonDocument.Parse(configJson)
            match configDoc.RootElement.GetProperty("gateway").GetProperty("auth").TryGetProperty("token") with
            | true, tokenElement -> 
                let tokenValue = tokenElement.GetString()
                if not(String.IsNullOrEmpty(tokenValue)) && not(tokenValue.StartsWith("${")) then
                    tokenValue.Trim()
                else
                    ""
            | false, _ -> ""
        with
        | :? IOException | :? JsonException | :? KeyNotFoundException -> ""

type GatewayTransport(state: obj, save: obj -> unit, url: string, token: string, ?timeout: int, ?interval: int, ?httpClient: HttpClient, ?clock: unit -> float, ?sleep: int -> unit) =
    
    let timeout = defaultArg timeout 3900
    let interval = defaultArg interval 3
    let httpClient = defaultArg httpClient (new HttpClient())
    let clock = defaultArg clock (fun () -> float(DateTime.Now.Ticks / TimeSpan.TicksPerMillisecond))
    let sleep = defaultArg sleep (fun ms -> Thread.Sleep(ms))
    
    do
        let uri = Uri(url)
        if uri.Scheme <> "http" && uri.Scheme <> "https" then
            failwith "invalid Gateway URL"
        if uri.Scheme = "http" && uri.Host <> "127.0.0.1" && uri.Host <> "localhost" && uri.Host <> "::1" then
            failwith "unencrypted Gateway must use loopback"
        if String.IsNullOrWhiteSpace(token) || timeout <= 0 || interval <= 0 then
            failwith "Gateway token and positive timeouts required"

    member private this.Request(node: string, requestObj: obj, ?deviceId: string) =
        let deviceId = deviceId |> Option.defaultValue null
        let payloadDict = dict [
            ("node", box node)
            ("device_id", box deviceId)
            ("request", box requestObj)
        ]
        let payloadJson = JsonSerializer.Serialize(payloadDict)
        let content = new StringContent(payloadJson, Encoding.UTF8, "application/json")
        
        content.Headers.Add("Authorization", "Bearer " + token.Trim())
        
        let timeoutValue = if node = "node4" then 150000 else 40000 // milliseconds
        use cts = new CancellationTokenSource(timeoutValue)
        
        try
            let! result = httpClient.PostAsync(url, content, cts.Token)
            let! raw = result.Content.ReadAsByteArrayAsync(cts.Token)
            
            if raw.Length > 4_000_000 then
                failwith "response too large"
                
            let jsonString = Encoding.UTF8.GetString(raw)
            let data = JsonSerializer.Deserialize<obj>(jsonString)
            
            match data with
            | :? System.Collections.Generic.Dictionary<string, obj> as dictData ->
                if not(dictData.ContainsKey("result")) then
                    failwith "invalid gateway response"
                    
                if deviceId <> null then
                    match dictData.TryGetValue("device_id") with
                    | true, returnedDeviceId when returnedDeviceId.ToString() <> deviceId ->
                        failwith "gateway device identity mismatch"
                    | _ -> ()
                    
                dictData.["result"]
            | _ -> failwith "invalid gateway response"
        with
        | :? TaskCanceledException | :? HttpRequestException | :? JsonException as ex ->
            raise(TransportUnresolvedEx("Gateway request failed", ex))

    member this.Available() =
        let result = this.Request("node1", dict [("operation", "availability")])
        match result with
        | :? System.Collections.Generic.Dictionary<string, obj> -> result :?> System.Collections.Generic.Dictionary<string, obj>
        | _ -> raise(TransportUnresolvedEx("invalid node availability"))

    member private this.Release(original: System.Collections.Generic.Dictionary<string, obj>, entry: System.Collections.Generic.Dictionary<string, obj>) =
        if entry.ContainsKey("released") && entry.["released"] :? bool && (entry.["released"] :?> bool) then
            ()
        else
            try
                let result = this.Request(
                    original.["selected_node"].ToString(),
                    dict [
                        ("operation", "release")
                        ("job_id", original.["job_id"])
                        ("attempt_id", original.["attempt_id"])
                    ],
                    original.["selected_device_id"].ToString()
                )
                
                match result with
                | :? System.Collections.Generic.Dictionary<string, obj> as resultDict ->
                    let hasStatusReleased = 
                        resultDict.ContainsKey("status") && 
                        resultDict.["status"].ToString() = "released"
                        
                    let keysMatch = 
                        ["job_id"; "attempt_id"; "selected_node"; "target_language"]
                        |> List.forall (fun key -> 
                            resultDict.ContainsKey(key) && 
                            original.ContainsKey(key) &&
                            resultDict.[key].ToString() = original.[key].ToString())
                    
                    if hasStatusReleased && keysMatch then
                        entry.["released"] <- true
                        save(state)
                | _ -> ()
            with
            | :? TransportUnresolved -> () // Retry cleanup later; the result is durable in manager state.

    member this.ReleasePending() =
        match state with
        | :? System.Collections.Generic.Dictionary<string, obj> as stateDict ->
            match stateDict.TryGetValue("auftraege") with
            | true, auftraege when auftraege :? System.Collections.Generic.Dictionary<string, obj> ->
                let auftraegeDict = auftraege :?> System.Collections.Generic.Dictionary<string, obj>
                auftraegeDict.Values
                |> Seq.iter (fun entry ->
                    match entry with
                    | :? System.Collections.Generic.Dictionary<string, obj> as entryDict ->
                        if entryDict.ContainsKey("status") && 
                           (entryDict.["status"].ToString() = "completed" ||
                            entryDict.["status"].ToString() = "rejected" ||
                            entryDict.["status"].ToString() = "failed") &&
                           entryDict.ContainsKey("job") &&
                           entryDict.["job"] :? System.Collections.Generic.Dictionary<string, obj> then
                            this.Release(entryDict.["job"] :?> System.Collections.Generic.Dictionary<string, obj>, entryDict)
                    | _ -> ()
                )
            | _ -> ()
        | _ -> ()

    member this.Reject(job: System.Collections.Generic.Dictionary<string, obj>, reason: string) =
        if not(job.ContainsKey("source_sha256")) || not(job.ContainsKey("target_language")) then
            ()
        else
            let key = job.["source_sha256"].ToString() + ":" + job.["target_language"].ToString()
            
            match state with
            | :? System.Collections.Generic.Dictionary<string, obj> as stateDict ->
                match stateDict.TryGetValue("auftraege") with
                | true, auftraege when auftraege :? System.Collections.Generic.Dictionary<string, obj> ->
                    let auftraegeDict = auftraege :?> System.Collections.Generic.Dictionary<string, obj>
                    match auftraegeDict.TryGetValue(key) with
                    | true, entry when entry :? System.Collections.Generic.Dictionary<string, obj> ->
                        let entryDict = entry :?> System.Collections.Generic.Dictionary<string, obj>
                        if entryDict.ContainsKey("status") && entryDict.["status"].ToString() = "completed" then
                            let jobAttemptId = 
                                if job.ContainsKey("attempt_id") then job.["attempt_id"].ToString()
                                else ""
                                
                            let entryJobAttemptId = 
                                match entryDict.TryGetValue("job") with
                                | true, entryJob when entryJob :? System.Collections.Generic.Dictionary<string, obj> ->
                                    let entryJobDict = entryJob :?> System.Collections.Generic.Dictionary<string, obj>
                                    if entryJobDict.ContainsKey("attempt_id") then entryJobDict.["attempt_id"].ToString()
                                    else ""
                                | _ -> ""
                            
                            if entryJobAttemptId <> jobAttemptId then
                                raise(TransportUnresolvedEx("rejected attempt identity mismatch"))
                                
                            entryDict.["status"] <- "rejected"
                            entryDict.["validation_error"] <- reason.Substring(0, min 500 reason.Length)
                            save(state)
                    | _ -> ()
                | _ -> ()
            | _ -> ()

    member this.Invoke(job: System.Collections.Generic.Dictionary<string, obj>) =
        if not(job.ContainsKey("source_sha256")) || 
           not(job.ContainsKey("target_language")) || 
           not(job.ContainsKey("selected_device_id")) then
            failwith "missing source identity"
            
        let key = job.["source_sha256"].ToString() + ":" + job.["target_language"].ToString()
        
        let entries = 
            match state with
            | :? System.Collections.Generic.Dictionary<string, obj> as stateDict ->
                if not(stateDict.ContainsKey("auftraege")) then
                    let newEntries = System.Collections.Generic.Dictionary<string, obj>()
                    stateDict.["auftraege"] <- newEntries :> obj
                    newEntries
                else
                    match stateDict.["auftraege"] with
                    | :? System.Collections.Generic.Dictionary<string, obj> as existingEntries -> existingEntries
                    | _ -> 
                        let newEntries = System.Collections.Generic.Dictionary<string, obj>()
                        stateDict.["auftraege"] <- newEntries :> obj
                        newEntries
            | _ -> 
                let newState = System.Collections.Generic.Dictionary<string, obj>()
                state <- newState :> obj
                let newEntries = System.Collections.Generic.Dictionary<string, obj>()
                newState.["auftraege"] <- newEntries :> obj
                newEntries
        
        let entry = 
            match entries.TryGetValue(key) with
            | true, foundEntry when foundEntry :? System.Collections.Generic.Dictionary<string, obj> -> 
                Some(foundEntry :?> System.Collections.Generic.Dictionary<string, obj>)
            | _ -> None
            
        let fresh, entry, original = 
            match entry with
            | Some(entryDict) when entryDict.ContainsKey("status") && entryDict.["status"].ToString() = "rejected" ->
                this.Release(
                    entryDict.["job"] :?> System.Collections.Generic.Dictionary<string, obj>, 
                    entryDict
                )
                
                if not(entryDict.ContainsKey("released") && entryDict.["released"] :? bool && (entryDict.["released"] :?> bool)) then
                    raise(TransportUnresolvedEx("rejected attempt release is unresolved"))
                    
                let previous = entryDict
                let original = System.Collections.Generic.Dictionary<string, obj>(job)
                original.["attempt_id"] <- Guid.NewGuid().ToString()
                
                let newEntry = System.Collections.Generic.Dictionary<string, obj>()
                newEntry.["job"] <- original :> obj
                newEntry.["status"] <- "submitted"
                
                let previousAttempts = 
                    if previous.ContainsKey("previous_attempts") && previous.["previous_attempts"] :? System.Collections.Generic.IList<obj> then
                        let list = previous.["previous_attempts"] :?> System.Collections.Generic.IList<obj>
                        [for item in list -> item] @ [
                            dict [
                                ("job_id", previous.["job"] :?> System.Collections.Generic.Dictionary<string, obj>.["job_id"])
                                ("attempt_id", previous.["job"] :?> System.Collections.Generic.Dictionary<string, obj>.["attempt_id"])
                                ("selected_node", previous.["job"] :?> System.Collections.Generic.Dictionary<string, obj>.["selected_node"])
                                ("validation_error", previous.["validation_error"])
                            ] :> obj
                        ]
                    else
                        [
                            dict [
                                ("job_id", previous.["job"] :?> System.Collections.Generic.Dictionary<string, obj>.["job_id"])
                                ("attempt_id", previous.["job"] :?> System.Collections.Generic.Dictionary<string, obj>.["attempt_id"])
                                ("selected_node", previous.["job"] :?> System.Collections.Generic.Dictionary<string, obj>.["selected_node"])
                                ("validation_error", previous.["validation_error"])
                            ] :> obj
                        ]
                        
                newEntry.["previous_attempts"] <- previousAttempts :> obj
                entries.[key] <- newEntry :> obj
                save(state)
                true, newEntry, original
            | Some(entryDict) -> 
                false, entryDict, entryDict.["job"] :?> System.Collections.Generic.Dictionary<string, obj>
            | None ->
                let original = System.Collections.Generic.Dictionary<string, obj>(job)
                original.["attempt_id"] <- Guid.NewGuid().ToString()
                
                let newEntry = System.Collections.Generic.Dictionary<string, obj>()
                newEntry.["job"] <- original :> obj
                newEntry.["status"] <- "submitted"
                entries.[key] <- newEntry :> obj
                
                // If this write fails there must be no remote submission.
                save(state)
                true, newEntry, original
                
        // The dispatcher verifies the job object after transport returns.
        for KeyValue(k, v) in original do
            job.[k] <- v
            
        if entry.ContainsKey("response") && entry.["response"] <> null then
            this.Release(original, entry)
            entry.["response"]
        elif entry.ContainsKey("status") && entry.["status"].ToString() = "failed" then
            raise(TransportUnresolvedEx("attempt requires reconciliation"))
        else
            let mutable status = null
            let freshSubmission = fresh
            
            if freshSubmission then
                try
                    status <- this.Request(
                        original.["selected_node"].ToString(),
                        dict [("operation", "execute"); ("job", original :> obj)],
                        original.["selected_device_id"].ToString()
                    )
                with
                | :? TransportUnresolved -> 
                    () // The request may have been accepted. Query, never resend.
                    
            let deadline = clock() + float timeout
            let rec loop() =
                if isNull status then
                    status <- this.Request(
                        original.["selected_node"].ToString(),
                        dict [
                            ("operation", "status")
                            ("job_id", original.["job_id"])
                            ("attempt_id", original.["attempt_id"])
                        ],
                        original.["selected_device_id"].ToString()
                    )
                    
                match status with
                | :? System.Collections.Generic.Dictionary<string, obj> as statusDict ->
                    let identityMismatch = 
                        ["job_id"; "attempt_id"; "selected_node"; "target_language"]
                        |> List.exists (fun k -> 
                            not(statusDict.ContainsKey(k)) || 
                            not(original.ContainsKey(k)) ||
                            statusDict.[k].ToString() <> original.[k].ToString())
                            
                    if identityMismatch then
                        raise(TransportUnresolvedEx("status identity mismatch"))
                        
                    let stateValue = statusDict.["status"].ToString()
                    if stateValue = "completed" then
                        let response = statusDict.["response"]
                        match response with
                        | :? System.Collections.Generic.Dictionary<string, obj> as responseDict ->
                            let invalidResult = 
                                not(responseDict.ContainsKey("status")) ||
                                responseDict.["status"].ToString() <> "ok" ||
                                not(responseDict.ContainsKey("code")) ||
                                String.IsNullOrWhiteSpace(responseDict.["code"].ToString()) ||
                                ["job_id"; "selected_node"; "target_language"]
                                |> List.exists (fun k -> 
                                    not(responseDict.ContainsKey(k)) || 
                                    not(original.ContainsKey(k)) ||
                                    responseDict.[k].ToString() <> original.[k].ToString())
                                    
                            if invalidResult then
                                raise(TransportUnresolvedEx("invalid translation result"))
                                
                            entry.["response"] <- response
                            entry.["status"] <- "completed"
                            save(state)
                            this.Release(original, entry)
                            response
                        | _ -> raise(TransportUnresolvedEx("invalid translation result"))
                    elif stateValue = "failed" || stateValue = "unknown" then
                        entry.["status"] <- stateValue
                        save(state)
                        if stateValue = "failed" then
                            this.Release(original, entry)
                        raise(TransportUnresolvedEx("attempt requires reconciliation"))
                    elif stateValue <> "running" || clock() >= deadline then
                        raise(TransportUnresolvedEx("attempt is unresolved"))
                    else
                        sleep(interval * 1000) // Convert to milliseconds
                        status <- null
                        loop()
                | _ -> raise(TransportUnresolvedEx("attempt is not known by the node"))
                
            loop()
