#!/usr/bin/env node
// model_usage.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
// auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Summarize CodexBar local cost usage by model.
 *
 * Defaults to current model (most recent daily entry), or list all models.
 */

const fs = require('fs');
const { spawnSync } = require('child_process');

function eprint(msg) {
    console.error(msg);
}

function runCodexbarCost(provider) {
    const cmd = ['codexbar', 'cost', '--format', 'json', '--provider', provider];
    const result = spawnSync(cmd[0], cmd.slice(1), { encoding: 'utf-8' });
    
    if (result.error) {
        if (result.error.code === 'ENOENT') {
            throw new Error('codexbar not found on PATH. Install CodexBar CLI first.');
        }
        throw new Error(`codexbar cost failed (${result.error.message}).`);
    }
    
    if (result.status !== 0) {
        throw new Error(`codexbar cost failed (exit ${result.status}).`);
    }
    
    try {
        const payload = JSON.parse(result.stdout);
        if (!Array.isArray(payload)) {
            throw new Error('Expected codexbar cost JSON array.');
        }
        return payload;
    } catch (err) {
        throw new Error(`Failed to parse codexbar JSON output: ${err.message}`);
    }
}

function loadPayload(inputPath, provider) {
    let data;
    if (inputPath) {
        let raw;
        if (inputPath === '-') {
            raw = fs.readFileSync(0, 'utf-8');
        } else {
            raw = fs.readFileSync(inputPath, 'utf-8');
        }
        data = JSON.parse(raw);
    } else {
        data = runCodexbarCost(provider);
    }

    if (typeof data === 'object' && !Array.isArray(data)) {
        return data;
    }

    if (Array.isArray(data)) {
        for (const entry of data) {
            if (typeof entry === 'object' && entry.provider === provider) {
                return entry;
            }
        }
        throw new Error(`Provider '${provider}' not found in codexbar payload.`);
    }

    throw new Error('Unsupported JSON input format.');
}

function parseDailyEntries(payload) {
    const daily = payload.daily;
    if (!daily) {
        return [];
    }
    if (!Array.isArray(daily)) {
        return [];
    }
    return daily.filter(entry => typeof entry === 'object');
}

function parseDate(value) {
    try {
        const parsed = new Date(value);
        return isNaN(parsed.getTime()) ? null : parsed;
    } catch (err) {
        return null;
    }
}

function filterByDays(entries, days) {
    if (!days) {
        return entries;
    }
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days + 1);
    const filtered = [];
    for (const entry of entries) {
        const day = entry.date;
        if (typeof day !== 'string') {
            continue;
        }
        const parsed = parseDate(day);
        if (parsed && parsed >= cutoff) {
            filtered.push(entry);
        }
    }
    return filtered;
}

function aggregateCosts(entries) {
    const totals = {};
    for (const entry of entries) {
        const breakdowns = entry.modelBreakdowns;
        if (!breakdowns) {
            continue;
        }
        if (!Array.isArray(breakdowns)) {
            continue;
        }
        for (const item of breakdowns) {
            if (typeof item !== 'object') {
                continue;
            }
            const model = item.modelName;
            const cost = item.cost;
            if (typeof model !== 'string') {
                continue;
            }
            if (typeof cost !== 'number') {
                continue;
            }
            totals[model] = (totals[model] || 0) + cost;
        }
    }
    return totals;
}

function pickCurrentModel(entries) {
    if (!entries.length) {
        return [null, null];
    }
    const sortedEntries = [...entries].sort((a, b) => {
        const aDate = a.date || '';
        const bDate = b.date || '';
        return aDate.localeCompare(bDate);
    });
    
    for (let i = sortedEntries.length - 1; i >= 0; i--) {
        const entry = sortedEntries[i];
        const breakdowns = entry.modelBreakdowns;
        if (Array.isArray(breakdowns) && breakdowns.length) {
            const scored = [];
            for (const item of breakdowns) {
                if (typeof item !== 'object') {
                    continue;
                }
                const model = item.modelName;
                const cost = item.cost;
                if (typeof model === 'string' && typeof cost === 'number') {
                    scored.push({ model, cost });
                }
            }
            if (scored.length) {
                scored.sort((a, b) => b.cost - a.cost);
                return [scored[0].model, typeof entry.date === 'string' ? entry.date : null];
            }
        }
        const modelsUsed = entry.modelsUsed;
        if (Array.isArray(modelsUsed) && modelsUsed.length) {
            const last = modelsUsed[modelsUsed.length - 1];
            if (typeof last === 'string') {
                return [last, typeof entry.date === 'string' ? entry.date : null];
            }
        }
    }
    return [null, null];
}

function usd(value) {
    if (value === null || value === undefined) {
        return '—';
    }
    return '$' + value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function latestDayCost(entries, model) {
    if (!entries.length) {
        return [null, null];
    }
    const sortedEntries = [...entries].sort((a, b) => {
        const aDate = a.date || '';
        const bDate = b.date || '';
        return aDate.localeCompare(bDate);
    });
    
    for (let i = sortedEntries.length - 1; i >= 0; i--) {
        const entry = sortedEntries[i];
        const breakdowns = entry.modelBreakdowns;
        if (!Array.isArray(breakdowns)) {
            continue;
        }
        for (const item of breakdowns) {
            if (typeof item !== 'object') {
                continue;
            }
            if (item.modelName === model) {
                const cost = typeof item.cost === 'number' ? item.cost : null;
                const day = typeof entry.date === 'string' ? entry.date : null;
                return [day, cost];
            }
        }
    }
    return [null, null];
}

function renderTextCurrent(provider, model, latestDate, totalCost, latestCost, latestCostDate, entryCount) {
    const lines = [`Provider: ${provider}`, `Current model: ${model}`];
    if (latestDate) {
        lines.push(`Latest model date: ${latestDate}`);
    }
    lines.push(`Total cost (rows): ${usd(totalCost)}`);
    if (latestCostDate) {
        lines.push(`Latest day cost: ${usd(latestCost)} (${latestCostDate})`);
    }
    lines.push(`Daily rows: ${entryCount}`);
    return lines.join('\n');
}

function renderTextAll(provider, totals) {
    const lines = [`Provider: ${provider}`, 'Models:'];
    const sortedTotals = Object.entries(totals).sort((a, b) => b[1] - a[1]);
    for (const [model, cost] of sortedTotals) {
        lines.push(`- ${model}: ${usd(cost)}`);
    }
    return lines.join('\n');
}

function buildJsonCurrent(provider, model, latestDate, totalCost, latestCost, latestCostDate, entryCount) {
    return {
        provider: provider,
        mode: 'current',
        model: model,
        latestModelDate: latestDate,
        totalCostUSD: totalCost,
        latestDayCostUSD: latestCost,
        latestDayCostDate: latestCostDate,
        dailyRowCount: entryCount
    };
}

function buildJsonAll(provider, totals) {
    const sortedTotals = Object.entries(totals).sort((a, b) => b[1] - a[1]);
    return {
        provider: provider,
        mode: 'all',
        models: sortedTotals.map(([model, cost]) => ({
            model: model,
            totalCostUSD: cost
        }))
    };
}

function main() {
    const args = require('yargs')
        .usage('Usage: $0 [options]')
        .option('provider', {
            describe: 'Provider to analyze',
            choices: ['codex', 'claude'],
            default: 'codex'
        })
        .option('mode', {
            describe: 'Output mode',
            choices: ['current', 'all'],
            default: 'current'
        })
        .option('model', {
            describe: 'Explicit model name to report instead of auto-current',
            type: 'string'
        })
        .option('input', {
            describe: 'Path to codexbar cost JSON (or "-" for stdin)',
            type: 'string'
        })
        .option('days', {
            describe: 'Limit to last N days (based on daily rows)',
            type: 'number'
        })
        .option('format', {
            describe: 'Output format',
            choices: ['text', 'json'],
            default: 'text'
        })
        .option('pretty', {
            describe: 'Pretty-print JSON output',
            type: 'boolean'
        })
        .help()
        .argv;

    let payload;
    try {
        payload = loadPayload(args.input, args.provider);
    } catch (err) {
        eprint(err.message);
        return 1;
    }

    let entries = parseDailyEntries(payload);
    entries = filterByDays(entries, args.days);

    if (args.mode === 'current') {
        let model = args.model;
        let latestDate = null;
        if (!model) {
            [model, latestDate] = pickCurrentModel(entries);
        }
        if (!model) {
            eprint('No model data found in codexbar cost payload.');
            return 2;
        }
        const totals = aggregateCosts(entries);
        const totalCost = totals[model];
        const [latestCostDate, latestCost] = latestDayCost(entries, model);

        if (args.format === 'json') {
            const payloadOut = buildJsonCurrent(
                args.provider,
                model,
                latestDate,
                totalCost,
                latestCost,
                latestCostDate,
                entries.length
            );
            console.log(JSON.stringify(payloadOut, null, args.pretty ? 2 : null));
        } else {
            console.log(renderTextCurrent(
                args.provider,
                model,
                latestDate,
                totalCost,
                latestCost,
                latestCostDate,
                entries.length
            ));
        }
        return 0;
    }

    const totals = aggregateCosts(entries);
    if (!Object.keys(totals).length) {
        eprint('No model breakdowns found in codexbar cost payload.');
        return 2;
    }

    if (args.format === 'json') {
        const payloadOut = buildJsonAll(args.provider, totals);
        console.log(JSON.stringify(payloadOut, null, args.pretty ? 2 : null));
    } else {
        console.log(renderTextAll(args.provider, totals));
    }
    return 0;
}

if (require.main === module) {
    process.exitCode = main();
}
