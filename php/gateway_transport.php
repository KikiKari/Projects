<?php
// abstraction-provenance: {"artifact_sha256": "0c16e71674f7832670eb194f639e069ec4ffdba2aa6e2682bcc5f6b5dac22ff2", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "php"}
// gateway_transport.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Gateway-authenticated transport with manager-owned attempt records.
 *
 * An attempt is saved before submission. If its outcome is uncertain, subsequent
 * calls only query the same node and attempt; they do not submit it again.
 */

class TransportUnresolved extends RuntimeException {}

function gateway_token() {
    // Use the local Gateway credential without changing its configuration.
    $token = trim($_ENV['OPENCLAW_GATEWAY_TOKEN'] ?? '');
    if ($token) {
        return $token;
    }
    $configPath = $_ENV['OPENCLAW_CONFIG_PATH'] ?? null;
    if (!$configPath) {
        $homeDir = getenv('HOME') ?: getenv('USERPROFILE');
        $configPath = $homeDir ? $homeDir . '/.openclaw/openclaw.json' : '';
    }
    if (!file_exists($configPath)) {
        return '';
    }
    try {
        $content = file_get_contents($configPath);
        if ($content === false) {
            return '';
        }
        $config = json_decode($content, true);
        if (!is_array($config)) {
            return '';
        }
        $token = $config['gateway']['auth']['token'] ?? '';
    } catch (Exception $e) {
        return '';
    }
    return (is_string($token) && !str_starts_with($token, '${')) ? trim($token) : '';
}

class GatewayTransport {
    private $state;
    private $save;
    private $url;
    private $token;
    private $timeout;
    private $interval;
    private $opener;
    private $clock;
    private $sleep;

    public function __construct(&$state, $save, $url, $token, $options = []) {
        $parsed = parse_url($url);
        if (!isset($parsed['scheme']) || !in_array($parsed['scheme'], ['http', 'https']) || !isset($parsed['host'])) {
            throw new InvalidArgumentException('invalid Gateway URL');
        }
        if ($parsed['scheme'] === 'http' && !in_array($parsed['host'], ['127.0.0.1', 'localhost', '::1'])) {
            throw new InvalidArgumentException('unencrypted Gateway must use loopback');
        }
        if (!trim($token) || ($options['timeout'] ?? 0) <= 0 || ($options['interval'] ?? 0) <= 0) {
            throw new InvalidArgumentException('Gateway token and positive timeouts required');
        }
        $this->state =& $state;
        $this->save = $save;
        $this->url = $url;
        $this->token = trim($token);
        $this->timeout = $options['timeout'] ?? 3900;
        $this->interval = $options['interval'] ?? 3;
        $this->opener = $options['opener'] ?? 'file_get_contents';
        $this->clock = $options['clock'] ?? function() { return microtime(true); };
        $this->sleep = $options['sleep'] ?? 'usleep';
    }

    private function _request($node, $request, $device_id = null) {
        $payload = json_encode([
            'node' => $node,
            'device_id' => $device_id,
            'request' => $request
        ], JSON_UNESCAPED_UNICODE);
        
        $context = stream_context_create([
            'http' => [
                'method' => 'POST',
                'header' => [
                    'Authorization: Bearer ' . $this->token,
                    'Content-Type: application/json',
                    'Content-Length: ' . strlen($payload)
                ],
                'content' => $payload,
                'timeout' => ($node === 'node4') ? 150 : 40
            ]
        ]);
        
        try {
            $raw = file_get_contents($this->url, false, $context);
            if ($raw === false) {
                throw new Exception('Failed to read response');
            }
            if (strlen($raw) > 4_000_000) {
                throw new InvalidArgumentException('response too large');
            }
            $data = json_decode($raw, true);
            if (!is_array($data) || !array_key_exists('result', $data)) {
                throw new InvalidArgumentException('invalid gateway response');
            }
            if ($device_id !== null && ($data['device_id'] ?? null) !== $device_id) {
                throw new InvalidArgumentException('gateway device identity mismatch');
            }
            return $data['result'];
        } catch (Exception $error) {
            throw new TransportUnresolved('Gateway request failed', 0, $error);
        }
    }

    public function available() {
        $result = $this->_request('node1', ['operation' => 'availability']);
        if (!is_array($result)) {
            throw new TransportUnresolved('invalid node availability');
        }
        return $result;
    }

    private function _release($original, &$entry) {
        if (!empty($entry['released'])) {
            return;
        }
        try {
            $result = $this->_request(
                $original['selected_node'],
                [
                    'operation' => 'release',
                    'job_id' => $original['job_id'],
                    'attempt_id' => $original['attempt_id']
                ],
                $original['selected_device_id']
            );
        } catch (TransportUnresolved $e) {
            return; // Retry cleanup later; the result is durable in manager state.
        }
        if (is_array($result) && 
            ($result['status'] ?? null) === 'released' &&
            ($result['job_id'] ?? null) === $original['job_id'] &&
            ($result['attempt_id'] ?? null) === $original['attempt_id'] &&
            ($result['selected_node'] ?? null) === $original['selected_node'] &&
            ($result['target_language'] ?? null) === $original['target_language']) {
            $entry['released'] = true;
            call_user_func($this->save, $this->state);
        }
    }

    public function release_pending() {
        $auftraege = $this->state['auftraege'] ?? [];
        foreach ($auftraege as &$entry) {
            if (is_array($entry) && 
                in_array($entry['status'] ?? null, ['completed', 'rejected', 'failed']) &&
                is_array($entry['job'] ?? null)) {
                $this->_release($entry['job'], $entry);
            }
        }
    }

    public function reject($job, $reason) {
        // Record a completed response rejected by validation, before retrying it.
        $key = ($job['source_sha256'] ?? '') . ':' . ($job['target_language'] ?? '');
        $entry = $this->state['auftraege'][$key] ?? null;
        if (!is_array($entry) || ($entry['status'] ?? null) !== 'completed') {
            return;
        }
        if (($entry['job']['attempt_id'] ?? null) !== ($job['attempt_id'] ?? null)) {
            throw new TransportUnresolved('rejected attempt identity mismatch');
        }
        $entry['status'] = 'rejected';
        $entry['validation_error'] = substr(strval($reason), 0, 500);
        call_user_func($this->save, $this->state);
    }

    public function __invoke($job) {
        if (empty($job['source_sha256']) || empty($job['target_language']) || empty($job['selected_device_id'])) {
            throw new InvalidArgumentException('missing source identity');
        }
        $key = $job['source_sha256'] . ':' . $job['target_language'];
        if (!isset($this->state['auftraege'])) {
            $this->state['auftraege'] = [];
        }
        $entries =& $this->state['auftraege'];
        $entry = $entries[$key] ?? null;
        
        if (is_array($entry) && ($entry['status'] ?? null) === 'rejected') {
            $this->_release($entry['job'], $entry);
            if (empty($entry['released'])) {
                throw new TransportUnresolved('rejected attempt release is unresolved');
            }
            $previous = $entry;
            $original = array_merge($job, ['attempt_id' => uniqid()]);
            $entry = [
                'job' => $original,
                'status' => 'submitted',
                'previous_attempts' => array_merge(
                    $previous['previous_attempts'] ?? [],
                    [[
                        'job_id' => $previous['job']['job_id'] ?? null,
                        'attempt_id' => $previous['job']['attempt_id'] ?? null,
                        'selected_node' => $previous['job']['selected_node'] ?? null,
                        'validation_error' => $previous['validation_error'] ?? null,
                    ]]
                )
            ];
            $entries[$key] = $entry;
            call_user_func($this->save, $this->state);
            $fresh = true;
        } else {
            $fresh = ($entry === null);
        }
        
        if ($entry === null) {
            $original = array_merge($job, ['attempt_id' => uniqid()]);
            $entry = ['job' => $original, 'status' => 'submitted'];
            $entries[$key] = $entry;
            // If this write fails there must be no remote submission.
            call_user_func($this->save, $this->state);
        }
        
        $original = $entry['job'];
        // The dispatcher verifies the job object after transport returns.
        $job = array_merge($job, $original);
        
        if (isset($entry['response'])) {
            $this->_release($original, $entry);
            return $entry['response'];
        }
        
        if (($entry['status'] ?? null) === 'failed') {
            throw new TransportUnresolved('attempt requires reconciliation');
        }
        
        $status = null;
        if ($fresh) {
            try {
                $status = $this->_request(
                    $original['selected_node'],
                    ['operation' => 'execute', 'job' => $original],
                    $original['selected_device_id']
                );
            } catch (TransportUnresolved $e) {
                // The request may have been accepted. Query, never resend.
            }
        }
        
        $deadline = call_user_func($this->clock) + $this->timeout;
        while (true) {
            if ($status === null) {
                $status = $this->_request(
                    $original['selected_node'],
                    [
                        'operation' => 'status',
                        'job_id' => $original['job_id'],
                        'attempt_id' => $original['attempt_id']
                    ],
                    $original['selected_device_id']
                );
            }
            
            if (!is_array($status)) {
                throw new TransportUnresolved('attempt is not known by the node');
            }
            
            if (($status['job_id'] ?? null) !== $original['job_id'] ||
                ($status['attempt_id'] ?? null) !== $original['attempt_id'] ||
                ($status['selected_node'] ?? null) !== $original['selected_node'] ||
                ($status['target_language'] ?? null) !== $original['target_language']) {
                throw new TransportUnresolved('status identity mismatch');
            }
            
            $state = $status['status'] ?? null;
            if ($state === 'completed') {
                $response = $status['response'] ?? null;
                if (!is_array($response) || 
                    ($response['status'] ?? null) !== 'ok' ||
                    ($response['job_id'] ?? null) !== $original['job_id'] ||
                    ($response['selected_node'] ?? null) !== $original['selected_node'] ||
                    ($response['target_language'] ?? null) !== $original['target_language'] ||
                    !is_string($response['code'] ?? null) || 
                    !trim($response['code'])) {
                    throw new TransportUnresolved('invalid translation result');
                }
                $entry['response'] = $response;
                $entry['status'] = 'completed';
                call_user_func($this->save, $this->state);
                $this->_release($original, $entry);
                return $response;
            }
            
            if (in_array($state, ['failed', 'unknown'])) {
                $entry['status'] = $state;
                call_user_func($this->save, $this->state);
                if ($state === 'failed') {
                    $this->_release($original, $entry);
                }
                throw new TransportUnresolved('attempt requires reconciliation');
            }
            
            if ($state !== 'running' || call_user_func($this->clock) >= $deadline) {
                throw new TransportUnresolved('attempt is unresolved');
            }
            
            $sleepFunc = $this->sleep;
            $sleepFunc($this->interval * 1000000); // Convert seconds to microseconds
            $status = null;
        }
    }
}
