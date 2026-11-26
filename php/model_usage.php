<?php
// abstraction-provenance: {"artifact_sha256": "c4532cda51791cdb2fb1b34d17685d0a4ab1d602dd02b39bbdec71d6d11baf78", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "php"}
// model_usage.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
// auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Summarize CodexBar local cost usage by model.
 *
 * Defaults to current model (most recent daily entry), or list all models.
 */

function eprint($msg) {
    fwrite(STDERR, $msg . PHP_EOL);
}

function run_codexbar_cost($provider) {
    $cmd = ['codexbar', 'cost', '--format', 'json', '--provider', $provider];
    $process = proc_open(
        implode(' ', array_map('escapeshellarg', $cmd)),
        [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w']
        ],
        $pipes
    );

    if (!is_resource($process)) {
        throw new RuntimeException("Failed to start codexbar process.");
    }

    fclose($pipes[0]);
    $output = stream_get_contents($pipes[1]);
    $errorOutput = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $returnCode = proc_close($process);

    if ($returnCode !== 0) {
        throw new RuntimeException("codexbar cost failed (exit {$returnCode}).");
    }

    $payload = json_decode($output, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new RuntimeException("Failed to parse codexbar JSON output: " . json_last_error_msg());
    }

    if (!is_array($payload)) {
        throw new RuntimeException("Expected codexbar cost JSON array.");
    }

    return $payload;
}

function load_payload($input_path, $provider) {
    if ($input_path) {
        if ($input_path === '-') {
            $raw = file_get_contents('php://stdin');
        } else {
            $raw = file_get_contents($input_path);
        }
        $data = json_decode($raw, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new RuntimeException("Failed to parse JSON input: " . json_last_error_msg());
        }
    } else {
        $data = run_codexbar_cost($provider);
    }

    if (is_array($data) && array_key_exists('provider', $data) && $data['provider'] === $provider) {
        return $data;
    }

    if (is_array($data)) {
        foreach ($data as $entry) {
            if (is_array($entry) && isset($entry['provider']) && $entry['provider'] === $provider) {
                return $entry;
            }
        }
        throw new RuntimeException("Provider '{$provider}' not found in codexbar payload.");
    }

    throw new RuntimeException("Unsupported JSON input format.");
}

function parse_daily_entries($payload) {
    $daily = $payload['daily'] ?? [];
    if (!is_array($daily)) {
        return [];
    }
    return array_filter($daily, function($entry) {
        return is_array($entry);
    });
}

function parse_date($value) {
    $date = DateTime::createFromFormat('Y-m-d', $value);
    return $date ? $date->format('Y-m-d') : null;
}

function filter_by_days($entries, $days) {
    if (!$days) {
        return $entries;
    }
    $cutoff = new DateTime();
    $cutoff->sub(new DateInterval("P" . ($days - 1) . "D"));
    $filtered = [];
    foreach ($entries as $entry) {
        $day = $entry['date'] ?? null;
        if (!is_string($day)) {
            continue;
        }
        $parsed = DateTime::createFromFormat('Y-m-d', $day);
        if ($parsed && $parsed >= $cutoff) {
            $filtered[] = $entry;
        }
    }
    return $filtered;
}

function aggregate_costs($entries) {
    $totals = [];
    foreach ($entries as $entry) {
        $breakdowns = $entry['modelBreakdowns'] ?? null;
        if (!$breakdowns || !is_array($breakdowns)) {
            continue;
        }
        foreach ($breakdowns as $item) {
            if (!is_array($item)) {
                continue;
            }
            $model = $item['modelName'] ?? null;
            $cost = $item['cost'] ?? null;
            if (!is_string($model) || !is_numeric($cost)) {
                continue;
            }
            if (!isset($totals[$model])) {
                $totals[$model] = 0.0;
            }
            $totals[$model] += (float)$cost;
        }
    }
    return $totals;
}

function pick_current_model($entries) {
    if (empty($entries)) {
        return [null, null];
    }
    usort($entries, function($a, $b) {
        return strcmp($a['date'] ?? '', $b['date'] ?? '');
    });
    foreach (array_reverse($entries) as $entry) {
        $breakdowns = $entry['modelBreakdowns'] ?? null;
        if (is_array($breakdowns) && !empty($breakdowns)) {
            $scored = [];
            foreach ($breakdowns as $item) {
                if (!is_array($item)) {
                    continue;
                }
                $model = $item['modelName'] ?? null;
                $cost = $item['cost'] ?? null;
                if (is_string($model) && is_numeric($cost)) {
                    $scored[] = ['model' => $model, 'cost' => (float)$cost];
                }
            }
            if (!empty($scored)) {
                usort($scored, function($a, $b) {
                    return $b['cost'] <=> $a['cost'];
                });
                return [$scored[0]['model'], $entry['date'] ?? null];
            }
        }
        $models_used = $entry['modelsUsed'] ?? null;
        if (is_array($models_used) && !empty($models_used)) {
            $last = end($models_used);
            if (is_string($last)) {
                return [$last, $entry['date'] ?? null];
            }
        }
    }
    return [null, null];
}

function usd($value) {
    if ($value === null) {
        return "—";
    }
    return "$" . number_format($value, 2, '.', ',');
}

function latest_day_cost($entries, $model) {
    if (empty($entries)) {
        return [null, null];
    }
    usort($entries, function($a, $b) {
        return strcmp($a['date'] ?? '', $b['date'] ?? '');
    });
    foreach (array_reverse($entries) as $entry) {
        $breakdowns = $entry['modelBreakdowns'] ?? null;
        if (!is_array($breakdowns)) {
            continue;
        }
        foreach ($breakdowns as $item) {
            if (!is_array($item)) {
                continue;
            }
            if (isset($item['modelName']) && $item['modelName'] === $model) {
                $cost = is_numeric($item['cost'] ?? null) ? (float)$item['cost'] : null;
                $day = is_string($entry['date'] ?? null) ? $entry['date'] : null;
                return [$day, $cost];
            }
        }
    }
    return [null, null];
}

function render_text_current($provider, $model, $latest_date, $total_cost, $latest_cost, $latest_cost_date, $entry_count) {
    $lines = [
        "Provider: {$provider}",
        "Current model: {$model}"
    ];
    if ($latest_date) {
        $lines[] = "Latest model date: {$latest_date}";
    }
    $lines[] = "Total cost (rows): " . usd($total_cost);
    if ($latest_cost_date) {
        $lines[] = "Latest day cost: " . usd($latest_cost) . " ({$latest_cost_date})";
    }
    $lines[] = "Daily rows: {$entry_count}";
    return implode(PHP_EOL, $lines);
}

function render_text_all($provider, $totals) {
    arsort($totals);
    $lines = [
        "Provider: {$provider}",
        "Models:"
    ];
    foreach ($totals as $model => $cost) {
        $lines[] = "- {$model}: " . usd($cost);
    }
    return implode(PHP_EOL, $lines);
}

function build_json_current($provider, $model, $latest_date, $total_cost, $latest_cost, $latest_cost_date, $entry_count) {
    return [
        'provider' => $provider,
        'mode' => 'current',
        'model' => $model,
        'latestModelDate' => $latest_date,
        'totalCostUSD' => $total_cost,
        'latestDayCostUSD' => $latest_cost,
        'latestDayCostDate' => $latest_cost_date,
        'dailyRowCount' => $entry_count
    ];
}

function build_json_all($provider, $totals) {
    arsort($totals);
    $models = [];
    foreach ($totals as $model => $cost) {
        $models[] = [
            'model' => $model,
            'totalCostUSD' => $cost
        ];
    }
    return [
        'provider' => $provider,
        'mode' => 'all',
        'models' => $models
    ];
}

function main($argv) {
    $options = getopt('', [
        'provider:',
        'mode:',
        'model:',
        'input:',
        'days:',
        'format:',
        'pretty'
    ]);

    $provider = $options['provider'] ?? 'codex';
    $mode = $options['mode'] ?? 'current';
    $model = $options['model'] ?? null;
    $input = $options['input'] ?? null;
    $days = isset($options['days']) ? (int)$options['days'] : null;
    $format = $options['format'] ?? 'text';
    $pretty = isset($options['pretty']);

    if (!in_array($provider, ['codex', 'claude'])) {
        eprint("Invalid provider. Must be 'codex' or 'claude'.");
        return 1;
    }

    if (!in_array($mode, ['current', 'all'])) {
        eprint("Invalid mode. Must be 'current' or 'all'.");
        return 1;
    }

    if (!in_array($format, ['text', 'json'])) {
        eprint("Invalid format. Must be 'text' or 'json'.");
        return 1;
    }

    try {
        $payload = load_payload($input, $provider);
    } catch (Exception $e) {
        eprint($e->getMessage());
        return 1;
    }

    $entries = parse_daily_entries($payload);
    $entries = filter_by_days($entries, $days);

    if ($mode === 'current') {
        $latest_date = null;
        if (!$model) {
            list($model, $latest_date) = pick_current_model($entries);
        }
        if (!$model) {
            eprint("No model data found in codexbar cost payload.");
            return 2;
        }
        $totals = aggregate_costs($entries);
        $total_cost = $totals[$model] ?? null;
        list($latest_cost_date, $latest_cost) = latest_day_cost($entries, $model);

        if ($format === 'json') {
            $payload_out = build_json_current(
                $provider,
                $model,
                $latest_date,
                $total_cost,
                $latest_cost,
                $latest_cost_date,
                count($entries)
            );
            echo json_encode($payload_out, $pretty ? JSON_PRETTY_PRINT : 0) . PHP_EOL;
        } else {
            echo render_text_current(
                $provider,
                $model,
                $latest_date,
                $total_cost,
                $latest_cost,
                $latest_cost_date,
                count($entries)
            ) . PHP_EOL;
        }
        return 0;
    }

    $totals = aggregate_costs($entries);
    if (empty($totals)) {
        eprint("No model breakdowns found in codexbar cost payload.");
        return 2;
    }

    if ($format === 'json') {
        $payload_out = build_json_all($provider, $totals);
        echo json_encode($payload_out, $pretty ? JSON_PRETTY_PRINT : 0) . PHP_EOL;
    } else {
        echo render_text_all($provider, $totals) . PHP_EOL;
    }
    return 0;
}

exit(main($argv));
