<?php
// abstraction-provenance: {"artifact_sha256": "875add4f455895555ca55e27fa9367d0792dda5b44413aa057aa0e8016bca7d3", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "php"}
// json_batch_processor.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).
 */

require_once 'json_processor.php'; // Stellt parse_json und parse_and_validate bereit

class BatchResult {
    public $index;
    public $source;
    public $success;
    public $data;
    public $error;

    public function __construct(int $index, string $source, bool $success, $data = null, ?string $error = null) {
        $this->index = $index;
        $this->source = $source;
        $this->success = $success;
        $this->data = $data;
        $this->error = $error;
    }

    public function toDict(): array {
        return [
            "index" => $this->index,
            "source" => $this->source,
            "success" => $this->success,
            "data" => $this->data,
            "error" => $this->error
        ];
    }
}

function readJsonl(string $filePath): Generator {
    /**
     * Liest JSON-Lines (NDJSON) Datei Zeile für Zeile.
     *
     * @param string $filePath Pfad zur .jsonl oder .ndjson Datei
     * @return Generator Geparste JSON-Objekte
     */
    $handle = fopen($filePath, 'r');
    if (!$handle) {
        throw new Exception("Cannot open file: $filePath");
    }

    $lineNum = 1;
    while (($line = fgets($handle)) !== false) {
        $line = trim($line);
        if (empty($line)) {
            $lineNum++;
            continue;
        }
        try {
            yield json_decode($line, true, 512, JSON_THROW_ON_ERROR);
        } catch (Exception $e) {
            yield new BatchResult(
                $lineNum,
                "$filePath:$lineNum",
                false,
                null,
                "JSON decode error: " . $e->getMessage()
            );
        }
        $lineNum++;
    }
    fclose($handle);
}

function processBatch(array $inputs, callable $processor, int $maxWorkers = 4): array {
    /**
     * Verarbeitet eine Liste von Inputs parallel.
     *
     * @param array $inputs Liste der zu verarbeitenden Eingaben (Strings oder Pfade)
     * @param callable $processor Funktion, die (input, index) -> BatchResult zurückgibt
     * @param int $maxWorkers Anzahl paralleler Worker
     * @return array Liste der BatchResult-Objekte
     */
    $results = [];
    $pool = [];

    foreach ($inputs as $idx => $inp) {
        $pool[] = [$inp, $idx];
    }

    // Simuliere parallele Verarbeitung durch sequenzielle Abarbeitung
    foreach ($pool as [$inp, $idx]) {
        try {
            $result = call_user_func($processor, $inp, $idx);
            $results[] = $result;
        } catch (Exception $e) {
            $results[] = new BatchResult(
                $idx,
                (string)$inp,
                false,
                null,
                "Unexpected error: " . $e->getMessage()
            );
        }
    }

    usort($results, function($a, $b) {
        return $a->index <=> $b->index;
    });

    return $results;
}

function processFileBatch(array $filePaths, bool $repair = true, ?string $validateModel = null, int $maxWorkers = 4): array {
    /**
     * Verarbeitet mehrere JSON-Dateien im Batch.
     *
     * @param array $filePaths Liste der Datei-Pfade
     * @param bool $repair Ob JSON-Reparatur angewendet werden soll
     * @param string|null $validateModel Optionales Validierungsmodell
     * @param int $maxWorkers Parallele Worker
     * @return array Liste der BatchResult-Objekte
     */
    $processor = function($path, $idx) use ($repair, $validateModel) {
        try {
            $content = file_get_contents($path);
            if ($content === false) {
                throw new Exception("Could not read file: $path");
            }

            if ($validateModel !== null) {
                $data = parse_and_validate($content, $validateModel, $repair);
            } else {
                $data = parse_json($content, $repair);
            }

            return new BatchResult(
                $idx,
                $path,
                true,
                $data
            );
        } catch (JSONProcessingError $e) {
            return new BatchResult(
                $idx,
                $path,
                false,
                null,
                $e->getMessage()
            );
        } catch (Exception $e) {
            return new BatchResult(
                $idx,
                $path,
                false,
                null,
                get_class($e) . ": " . $e->getMessage()
            );
        }
    };

    return processBatch($filePaths, $processor, $maxWorkers);
}

function processJsonlFile(string $filePath, bool $repair = true, ?string $validateModel = null): array {
    /**
     * Verarbeitet eine JSON-Lines Datei.
     *
     * @param string $filePath Pfad zur .jsonl Datei
     * @param bool $repair Ob Reparatur angewendet werden soll
     * @param string|null $validateModel Optionales Validierungsmodell
     * @return array Liste der BatchResult-Objekte
     */
    $results = [];
    $handle = fopen($filePath, 'r');
    if (!$handle) {
        throw new Exception("Cannot open file: $filePath");
    }

    $lineNum = 1;
    while (($line = fgets($handle)) !== false) {
        $line = trim($line);
        if (empty($line)) {
            $lineNum++;
            continue;
        }

        try {
            if ($validateModel !== null) {
                $data = parse_and_validate($line, $validateModel, $repair);
            } else {
                $data = parse_json($line, $repair);
            }

            $results[] = new BatchResult(
                $lineNum,
                "$filePath:$lineNum",
                true,
                $data
            );
        } catch (JSONProcessingError $e) {
            $results[] = new BatchResult(
                $lineNum,
                "$filePath:$lineNum",
                false,
                null,
                $e->getMessage()
            );
        }

        $lineNum++;
    }
    fclose($handle);

    return $results;
}

function writeJsonl(array $results, string $outputPath, bool $onlySuccessful = true) {
    /**
     * Schreibt BatchResult-Liste als JSON-Lines.
     *
     * @param array $results Liste der Ergebnisse
     * @param string $outputPath Ausgabedatei
     * @param bool $onlySuccessful Nur erfolgreiche Ergebnisse schreiben
     */
    $handle = fopen($outputPath, 'w');
    if (!$handle) {
        throw new Exception("Cannot write to file: $outputPath");
    }

    foreach ($results as $result) {
        if ($onlySuccessful && !$result->success) {
            continue;
        }
        fwrite($handle, json_encode($result->toDict(), JSON_UNESCAPED_UNICODE) . "\n");
    }
    fclose($handle);
}

function main($argv) {
    $parser = [
        'description' => "Batch JSON Processor"
    ];

    // Simple argument parsing
    $options = getopt("lrw:o:s", ["jsonl", "repair", "workers:", "output:", "summary"]);
    $inputs = array_slice($argv, 1);

    // Entferne Optionen aus den Inputs
    $cleanInputs = [];
    $skipNext = false;
    for ($i = 1; $i < count($argv); $i++) {
        if ($skipNext) {
            $skipNext = false;
            continue;
        }
        if (strpos($argv[$i], '-') === 0) {
            // Ist eine Option
            if (in_array($argv[$i], ['-w', '--workers', '-o', '--output'])) {
                $skipNext = true; // Nächster Wert ist Parameter
            }
            continue;
        }
        $cleanInputs[] = $argv[$i];
    }

    $jsonlMode = isset($options['l']) || isset($options['jsonl']);
    $repair = isset($options['r']) || isset($options['repair']);
    $workers = isset($options['w']) ? (int)$options['w'] : (isset($options['workers']) ? (int)$options['workers'] : 4);
    $output = $options['o'] ?? ($options['output'] ?? null);
    $summary = isset($options['s']) || isset($options['summary']);

    $allResults = [];

    if ($jsonlMode) {
        // JSON-Lines Modus
        foreach ($cleanInputs as $inputPath) {
            $results = processJsonlFile($inputPath, $repair);
            $allResults = array_merge($allResults, $results);
        }
    } else {
        // Standard JSON Batch
        $allResults = processFileBatch($cleanInputs, $repair, null, $workers);
    }

    // Statistiken
    $successful = 0;
    $failed = 0;
    foreach ($allResults as $result) {
        if ($result->success) {
            $successful++;
        } else {
            $failed++;
        }
    }

    if ($summary) {
        echo "Processed: " . count($allResults) . "\n";
        echo "Successful: $successful\n";
        echo "Failed: $failed\n";
    } else {
        foreach ($allResults as $result) {
            if ($result->success) {
                echo json_encode($result->data, JSON_UNESCAPED_UNICODE) . "\n";
            } else {
                fwrite(STDERR, "ERROR [{$result->source}]: {$result->error}\n");
            }
        }
    }

    // Optional: JSONL Output
    if ($output) {
        writeJsonl($allResults, $output, false);
        fwrite(STDERR, "\nResults written to: $output\n");
    }

    exit($failed === 0 ? 0 : 1);
}

main($argv);
