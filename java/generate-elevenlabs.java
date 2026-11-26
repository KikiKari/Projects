// abstraction-provenance: {"artifact_sha256": "a52f9ac22858a8bf831f5c5bb491e14953b05cdbe54b9875fb3d3beebc583d22", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "java"}
// generate-elevenlabs.mjs — portiert nach java
// Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class GenerateElevenlabs {
    public static void main(String[] args) throws Exception {
        String key = System.getenv("ELEVENLABS_API_KEY");
        String voiceId = System.getenv("ELEVENLABS_VOICE_ID");
        if (voiceId == null || voiceId.isEmpty()) {
            voiceId = "JBFqnCBsd6RMkjVDRZzb";
        }
        if (key == null || key.isEmpty()) {
            throw new RuntimeException("ELEVENLABS_API_KEY fehlt.");
        }

        String text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.";

        // Create connection
        URL url = new URL("https://api.elevenlabs.io/v1/text-to-speech/" + voiceId + "?output_format=mp3_44100_128");
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod("POST");
        connection.setRequestProperty("xi-api-key", key);
        connection.setRequestProperty("Content-Type", "application/json");
        connection.setDoOutput(true);

        // Create request body
        String requestBody = "{"
                + "\"text\":\"" + text + "\","
                + "\"model_id\":\"eleven_multilingual_v2\","
                + "\"voice_settings\":{"
                + "\"stability\":0.58,"
                + "\"similarity_boost\":0.72,"
                + "\"style\":0.18,"
                + "\"use_speaker_boost\":true"
                + "}"
                + "}";

        // Send request
        try (OutputStream os = connection.getOutputStream()) {
            byte[] input = requestBody.getBytes("utf-8");
            os.write(input, 0, input.length);
        }

        if (connection.getResponseCode() != 200) {
            throw new RuntimeException("ElevenLabs fehlgeschlagen: " + connection.getResponseCode());
        }

        // Create directories
        Path audioDir = Paths.get("..", "public", "audio");
        Files.createDirectories(audioDir);

        // Write MP3 file
        Path mp3Path = audioDir.resolve("project-narration.mp3");
        try (InputStream inputStream = connection.getInputStream()) {
            Files.copy(inputStream, mp3Path);
        }

        // Create JSON result
        String jsonResult = "{\n"
                + "  \"model\": \"eleven_multilingual_v2\",\n"
                + "  \"voiceId\": \"" + voiceId + "\",\n"
                + "  \"characters\": " + text.length() + ",\n"
                + "  \"text\": \"" + text + "\",\n"
                + "  \"output\": \"public/audio/project-narration.mp3\"\n"
                + "}";

        // Write JSON file
        Path jsonPath = Paths.get("..", "media-production", "elevenlabs-result.json");
        Files.createDirectories(jsonPath.getParent());
        Files.write(jsonPath, jsonResult.getBytes());

        System.out.println("ElevenLabs abgeschlossen: " + text.length() + " Zeichen.");
    }
}
