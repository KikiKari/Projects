#!/usr/bin/env node
// test-skill-contract.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/test-skill-contract.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Regression checks for /tiktok_live_mon routing and monitor actions.
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import assert from 'assert';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SKILL_PATH = resolve(__dirname, '..', 'SKILL.md');
const DISPATCHER = (
    "/home/openclaw/.openclaw/workspace/tiktok-monitor/" +
    "tiktok_dispatch.py url @name --quality auto --json"
);
const CONTROLLER = (
    "/home/openclaw/.openclaw/workspace/tiktok-monitor/" +
    "tiktok-monitorctl.sh"
);

class MonitorSkillContractTests {
    static text = readFileSync(SKILL_PATH, 'utf8');
    static normalizedText = this.text.replace(/\s+/g, ' ');

    static runTests() {
        this.test_bare_handle_uses_dispatcher_as_first_tool_call();
        this.test_slash_command_bypasses_the_model();
        this.test_no_preliminary_playwright_or_dependency_probe();
        this.test_direct_exec_without_shell_wrapper();
        this.test_success_json_wins_over_trailing_diagnostics();
        this.test_running_dispatcher_is_polled_without_restart();
        this.test_monitor_actions_remain_controller_backed();
        this.test_one_shot_response_contract_covers_all_statuses();
        this.test_invalid_current_input_is_not_taken_from_history();
        console.log('All tests passed!');
    }

    static test_bare_handle_uses_dispatcher_as_first_tool_call() {
        assert(this.normalizedText.includes(
            "dispatcher exec must be the first tool call"
        ), "dispatcher exec must be the first tool call");
        assert(this.text.includes(DISPATCHER), DISPATCHER);
        assert(this.text.includes(
            "A bare handle never starts a daemon"
        ), "A bare handle never starts a daemon");
    }

    static test_slash_command_bypasses_the_model() {
        const expectedItems = [
            "command-dispatch: tool",
            "command-tool: tiktok_live_mon_command",
            "command-arg-mode: raw"
        ];
        
        for (const expected of expectedItems) {
            assert(this.text.includes(expected), expected);
        }
    }

    static test_no_preliminary_playwright_or_dependency_probe() {
        const expectedItems = [
            "Before this dispatcher call, do not invoke or inspect",
            "`tiktok-check-profile.js`",
            "Do not attempt to install or repair browser dependencies",
            "failed preliminary tool call"
        ];
        
        for (const expected of expectedItems) {
            assert(this.normalizedText.includes(expected), expected);
        }
    }

    static test_direct_exec_without_shell_wrapper() {
        const expectedItems = [
            "Invoke that executable directly as the exec command",
            "Do not invoke `bash`",
            "`bash -lc`",
            "wrapper must not be attempted in the first place"
        ];
        
        for (const expected of expectedItems) {
            assert(this.normalizedText.includes(expected), expected);
        }
    }

    static test_success_json_wins_over_trailing_diagnostics() {
        const expectedItems = [
            "display the final stdout JSON before trailing stderr diagnostics",
            "regardless of its visual position",
            "the tool execution succeeded",
            "Never replace such a result with a generic tool-failure message",
            "`node_available`"
        ];
        
        for (const expected of expectedItems) {
            assert(this.normalizedText.includes(expected), expected);
        }
    }

    static test_running_dispatcher_is_polled_without_restart() {
        const expectedItems = [
            "Start exactly one dispatcher exec per request",
            "do not rerun exec",
            'sessionId: "NAME"',
            "Continue polling that same name until completion"
        ];
        
        for (const expected of expectedItems) {
            assert(this.text.includes(expected), expected);
        }
    }

    static test_monitor_actions_remain_controller_backed() {
        const actions = ["start", "status", "stop"];
        
        for (const action of actions) {
            const command = `${CONTROLLER} ${action} @name`;
            assert(this.text.includes(command), command);
        }
        
        assert(this.text.includes(
            "prevents duplicate active monitors"
        ), "prevents duplicate active monitors");
        assert(this.text.includes(
            "Without the current word `start`"
        ), "Without the current word `start`");
    }

    static test_one_shot_response_contract_covers_all_statuses() {
        const legacy = (
            "@<handle> is currently " +
            "<OFFLINE|RESTRICTED|OVERLDED|TECHNICAL_ERROR> on TikTok.\n" +
            "VLC/MPV: not available\n" +
            "Method: <method>"
        );
        assert(this.text.includes(legacy), legacy);
        
        const liveStatus = "@<handle> is currently LIVE on TikTok.\nTitel: <room.title>";
        assert(this.text.includes(liveStatus), liveStatus);
        
        const expectedItems = [
            "Stream-URLs:",
            "<label> (HLS):",
            "<label> (FLV):",
            "exactly one URL and nothing else",
            "No raw URL appears in plain text"
        ];
        
        const normalizedText = this.text.replace(/\s+/g, ' ');
        for (const expected of expectedItems) {
            assert(normalizedText.includes(expected), expected);
        }
        
        const statuses = [
            "live", "offline", "restricted", "overloaded",
            "dependency_missing", "technical_error"
        ];
        
        for (const status of statuses) {
            assert(this.text.includes(status), status);
        }
    }

    static test_invalid_current_input_is_not_taken_from_history() {
        assert(this.text.includes(
            "Derive the action, handle, hours, and poll interval only"
        ), "Derive the action, handle, hours, and poll interval only");
        assert(this.text.includes(
            "Never take them from"
        ), "Never take them from");
    }
}

MonitorSkillContractTests.runTests();
