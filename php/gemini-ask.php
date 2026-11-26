<?php
// abstraction-provenance: {"artifact_sha256": "e8a27e6564ebd2879b940710a91e99ee37585af30d286b197ca3484267598eba", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "php"}
// gemini-ask.js — portiert nach php
// Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
// auch in: OpenClaw@gateway2:scripts/gemini-ask.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * gemini-ask.php - CLI tool for Google Gemini API
 * 
 * Usage:
 *   php gemini-ask.php "Your question here"
 *   echo "Your question" | php gemini-ask.php
 *   php gemini-ask.php --file prompt.txt
 *   php gemini-ask.php --model gemini-pro "Your question"
 * 
 * Environment:
 *   GEMINI_API_KEY - Required API key
 *   GEMINI_MODEL   - Optional default model (default: gemini-pro)
 */

const DEFAULT_MODEL = 'gemini-pro';

function main() {
    // Check API key
    $apiKey = getenv('GEMINI_API_KEY');
    if (!$apiKey) {
        fwrite(STDERR, "Error: GEMINI_API_KEY environment variable is required\n");
        exit(1);
    }

    // Parse arguments
    $prompt = '';
    $modelName = getenv('GEMINI_MODEL') ?: DEFAULT_MODEL;
    global $argv;
    $args = array_slice($argv, 1);
    
    // Check for --model flag
    $modelIndex = array_search('--model', $args) ?: array_search('-m', $args);
    if ($modelIndex !== false && isset($args[$modelIndex + 1])) {
        $modelName = $args[$modelIndex + 1];
        array_splice($args, $modelIndex, 2);
    }

    // Check for --system flag (system prompt)
    $systemPrompt = '';
    $systemIndex = array_search('--system', $args) ?: array_search('-s', $args);
    if ($systemIndex !== false && isset($args[$systemIndex + 1])) {
        $systemPrompt = $args[$systemIndex + 1];
        array_splice($args, $systemIndex, 2);
    }

    if (in_array('--file', $args) || in_array('-f', $args)) {
        $fileIndex = array_search('--file', $args) ?: array_search('-f', $args);
        $filePath = $args[$fileIndex + 1] ?? null;
        if (!$filePath) {
            fwrite(STDERR, "Error: No file specified\n");
            exit(1);
        }
        $prompt = file_get_contents($filePath);
        if ($prompt === false) {
            fwrite(STDERR, "Error: Could not read file $filePath\n");
            exit(1);
        }
        // Remove --file and path from args
        array_splice($args, $fileIndex, 2);
    } else if (count($args) > 0) {
        $prompt = implode(' ', $args);
    } else if (!posix_isatty(STDIN)) {
        // Read from stdin
        $prompt = stream_get_contents(STDIN);
    }

    if (trim($prompt) === '') {
        fwrite(STDERR, "Error: No prompt provided\n");
        fwrite(STDERR, "Usage: gemini-ask \"your question\"\n");
        fwrite(STDERR, "       gemini-ask --model gemini-pro \"your question\"\n");
        fwrite(STDERR, "       echo \"your question\" | gemini-ask\n");
        exit(1);
    }

    try {
        // Prepare generation config
        $generationConfig = [
            'maxOutputTokens' => 8192,
            'temperature' => 0.7,
            'topP' => 0.95,
        ];

        if ($systemPrompt) {
            // Use chat with system prompt
            $history = [
                ['role' => 'user', 'parts' => [['text' => $systemPrompt]]],
                ['role' => 'model', 'parts' => [['text' => 'Understood. I will follow that instruction.']]]
            ];
            
            $result = sendChatMessage($apiKey, $modelName, $generationConfig, $history, $prompt);
        } else {
            // Direct generation
            $result = generateContent($apiKey, $modelName, $generationConfig, $prompt);
        }

        echo $result . "\n";
    } catch (Exception $error) {
        fwrite(STDERR, "Error: " . $error->getMessage() . "\n");
        if (strpos($error->getMessage(), 'API key') !== false) {
            fwrite(STDERR, "Make sure GEMINI_API_KEY is set correctly\n");
        }
        exit(1);
    }
}

function generateContent($apiKey, $model, $config, $prompt) {
    $url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";
    
    $data = [
        'contents' => [
            [
                'role' => 'user',
                'parts' => [
                    ['text' => $prompt]
                ]
            ]
        ],
        'generationConfig' => $config
    ];

    $options = [
        'http' => [
            'header' => "Content-Type: application/json\r\n",
            'method' => 'POST',
            'content' => json_encode($data)
        ]
    ];

    $context = stream_context_create($options);
    $response = file_get_contents($url, false, $context);
    
    if ($response === false) {
        throw new Exception("Failed to get response from API");
    }
    
    $responseData = json_decode($response, true);
    
    if (isset($responseData['error'])) {
        throw new Exception($responseData['error']['message']);
    }
    
    return $responseData['candidates'][0]['content']['parts'][0]['text'];
}

function sendChatMessage($apiKey, $model, $config, $history, $prompt) {
    $url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";
    
    $data = [
        'contents' => array_merge($history, [
            [
                'role' => 'user',
                'parts' => [
                    ['text' => $prompt]
                ]
            ]
        ]),
        'generationConfig' => $config
    ];

    $options = [
        'http' => [
            'header' => "Content-Type: application/json\r\n",
            'method' => 'POST',
            'content' => json_encode($data)
        ]
    ];

    $context = stream_context_create($options);
    $response = file_get_contents($url, false, $context);
    
    if ($response === false) {
        throw new Exception("Failed to get response from API");
    }
    
    $responseData = json_decode($response, true);
    
    if (isset($responseData['error'])) {
        throw new Exception($responseData['error']['message']);
    }
    
    return $responseData['candidates'][0]['content']['parts'][0]['text'];
}

main();
?>
