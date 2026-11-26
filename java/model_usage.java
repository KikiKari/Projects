// abstraction-provenance: {"artifact_sha256": "cc681c1b68ee9b970431b25916687fc8b12c31dd6123c184da067cb3d789bc57", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "java"}
// model_usage.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
// auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.*;
import java.util.*;
import java.util.stream.*;
import com.google.gson.*;

public class ModelUsage {
    private static final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public static void main(String[] args) {
        System.exit(run(args));
    }

    private static int run(String[] args) {
        Map<String, Object> options = parseArguments(args);
        
        String provider = (String) options.getOrDefault("provider", "codex");
        String mode = (String) options.getOrDefault("mode", "current");
        String modelArg = (String) options.get("model");
        String inputPath = (String) options.get("input");
        Integer days = (Integer) options.get("days");
        String format = (String) options.getOrDefault("format", "text");
        boolean pretty = (Boolean) options.getOrDefault("pretty", false);

        JsonObject payload;
        try {
            payload = loadPayload(inputPath, provider);
        } catch (Exception e) {
            System.err.println(e.getMessage());
            return 1;
        }

        List<JsonObject> entries = parseDailyEntries(payload);
        entries = filterByDays(entries, days);

        if ("current".equals(mode)) {
            String model = modelArg;
            String latestDate = null;
            
            if (model == null || model.isEmpty()) {
                ModelDateResult result = pickCurrentModel(entries);
                model = result.model;
                latestDate = result.date;
            }
            
            if (model == null || model.isEmpty()) {
                System.err.println("No model data found in codexbar cost payload.");
                return 2;
            }
            
            Map<String, Double> totals = aggregateCosts(entries);
            Double totalCost = totals.get(model);
            
            LatestCostResult latestCostResult = latestDayCost(entries, model);
            String latestCostDate = latestCostResult.date;
            Double latestCost = latestCostResult.cost;

            if ("json".equals(format)) {
                JsonObject output = buildJsonCurrent(
                    provider, model, latestDate, totalCost, 
                    latestCost, latestCostDate, entries.size()
                );
                System.out.println(gson.toJson(output));
            } else {
                String output = renderTextCurrent(
                    provider, model, latestDate, totalCost,
                    latestCost, latestCostDate, entries.size()
                );
                System.out.println(output);
            }
            return 0;
        }

        Map<String, Double> totals = aggregateCosts(entries);
        if (totals.isEmpty()) {
            System.err.println("No model breakdowns found in codexbar cost payload.");
            return 2;
        }

        if ("json".equals(format)) {
            JsonObject output = buildJsonAll(provider, totals);
            System.out.println(gson.toJson(output));
        } else {
            String output = renderTextAll(provider, totals);
            System.out.println(output);
        }
        return 0;
    }

    private static Map<String, Object> parseArguments(String[] args) {
        Map<String, Object> options = new HashMap<>();
        
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--provider":
                    if (i + 1 < args.length) {
                        options.put("provider", args[++i]);
                    }
                    break;
                case "--mode":
                    if (i + 1 < args.length) {
                        options.put("mode", args[++i]);
                    }
                    break;
                case "--model":
                    if (i + 1 < args.length) {
                        options.put("model", args[++i]);
                    }
                    break;
                case "--input":
                    if (i + 1 < args.length) {
                        options.put("input", args[++i]);
                    }
                    break;
                case "--days":
                    if (i + 1 < args.length) {
                        try {
                            options.put("days", Integer.parseInt(args[++i]));
                        } catch (NumberFormatException e) {
                            // Ignore invalid number
                        }
                    }
                    break;
                case "--format":
                    if (i + 1 < args.length) {
                        options.put("format", args[++i]);
                    }
                    break;
                case "--pretty":
                    options.put("pretty", true);
                    break;
            }
        }
        
        return options;
    }

    private static JsonObject runCodexbarCost(String provider) throws IOException, InterruptedException {
        ProcessBuilder pb = new ProcessBuilder("codexbar", "cost", "--format", "json", "--provider", provider);
        Process process = pb.start();
        
        StringBuilder output = new StringBuilder();
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        String line;
        while ((line = reader.readLine()) != null) {
            output.append(line).append("\n");
        }
        
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new RuntimeException("codexbar cost failed (exit " + exitCode + ").");
        }
        
        return JsonParser.parseString(output.toString()).getAsJsonObject();
    }

    private static JsonObject loadPayload(String inputPath, String provider) throws IOException {
        String rawData;
        if (inputPath != null && !inputPath.isEmpty()) {
            if ("-".equals(inputPath)) {
                rawData = new Scanner(System.in).useDelimiter("\\A").next();
            } else {
                rawData = Files.readString(Paths.get(inputPath));
            }
        } else {
            try {
                return runCodexbarCost(provider);
            } catch (InterruptedException e) {
                throw new RuntimeException("codexbar execution interrupted");
            }
        }
        
        JsonElement element = JsonParser.parseString(rawData);
        if (element.isJsonObject()) {
            return element.getAsJsonObject();
        }
        
        if (element.isJsonArray()) {
            JsonArray array = element.getAsJsonArray();
            for (JsonElement item : array) {
                if (item.isJsonObject()) {
                    JsonObject obj = item.getAsJsonObject();
                    JsonElement providerElement = obj.get("provider");
                    if (providerElement != null && providerElement.isJsonPrimitive() && 
                        providerElement.getAsString().equals(provider)) {
                        return obj;
                    }
                }
            }
            throw new RuntimeException("Provider '" + provider + "' not found in codexbar payload.");
        }
        
        throw new RuntimeException("Unsupported JSON input format.");
    }

    private static List<JsonObject> parseDailyEntries(JsonObject payload) {
        JsonElement dailyElement = payload.get("daily");
        if (dailyElement == null || !dailyElement.isJsonArray()) {
            return new ArrayList<>();
        }
        
        List<JsonObject> result = new ArrayList<>();
        JsonArray dailyArray = dailyElement.getAsJsonArray();
        for (JsonElement element : dailyArray) {
            if (element.isJsonObject()) {
                result.add(element.getAsJsonObject());
            }
        }
        return result;
    }

    private static LocalDate parseDate(String value) {
        try {
            return LocalDate.parse(value, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        } catch (Exception e) {
            return null;
        }
    }

    private static List<JsonObject> filterByDays(List<JsonObject> entries, Integer days) {
        if (days == null) {
            return entries;
        }
        
        LocalDate cutoff = LocalDate.now().minusDays(days - 1);
        List<JsonObject> filtered = new ArrayList<>();
        
        for (JsonObject entry : entries) {
            JsonElement dateElement = entry.get("date");
            if (dateElement != null && dateElement.isJsonPrimitive()) {
                LocalDate parsed = parseDate(dateElement.getAsString());
                if (parsed != null && !parsed.isBefore(cutoff)) {
                    filtered.add(entry);
                }
            }
        }
        return filtered;
    }

    private static Map<String, Double> aggregateCosts(List<JsonObject> entries) {
        Map<String, Double> totals = new HashMap<>();
        
        for (JsonObject entry : entries) {
            JsonElement breakdownsElement = entry.get("modelBreakdowns");
            if (breakdownsElement != null && breakdownsElement.isJsonArray()) {
                JsonArray breakdowns = breakdownsElement.getAsJsonArray();
                for (JsonElement item : breakdowns) {
                    if (item.isJsonObject()) {
                        JsonObject obj = item.getAsJsonObject();
                        JsonElement modelElement = obj.get("modelName");
                        JsonElement costElement = obj.get("cost");
                        
                        if (modelElement != null && modelElement.isJsonPrimitive() &&
                            costElement != null && (costElement.isJsonPrimitive() && 
                            (costElement.getAsJsonPrimitive().isNumber()))) {
                            
                            String model = modelElement.getAsString();
                            double cost = costElement.getAsDouble();
                            totals.put(model, totals.getOrDefault(model, 0.0) + cost);
                        }
                    }
                }
            }
        }
        return totals;
    }

    private static class ModelDateResult {
        String model;
        String date;
        
        ModelDateResult(String model, String date) {
            this.model = model;
            this.date = date;
        }
    }

    private static ModelDateResult pickCurrentModel(List<JsonObject> entries) {
        if (entries.isEmpty()) {
            return new ModelDateResult(null, null);
        }
        
        entries.sort((a, b) -> {
            JsonElement dateA = a.get("date");
            JsonElement dateB = b.get("date");
            String strA = dateA != null && dateA.isJsonPrimitive() ? dateA.getAsString() : "";
            String strB = dateB != null && dateB.isJsonPrimitive() ? dateB.getAsString() : "";
            return strA.compareTo(strB);
        });
        
        Collections.reverse(entries);
        
        for (JsonObject entry : entries) {
            JsonElement breakdownsElement = entry.get("modelBreakdowns");
            if (breakdownsElement != null && breakdownsElement.isJsonArray()) {
                JsonArray breakdowns = breakdownsElement.getAsJsonArray();
                List<ModelCost> scored = new ArrayList<>();
                
                for (JsonElement item : breakdowns) {
                    if (item.isJsonObject()) {
                        JsonObject obj = item.getAsJsonObject();
                        JsonElement modelElement = obj.get("modelName");
                        JsonElement costElement = obj.get("cost");
                        
                        if (modelElement != null && modelElement.isJsonPrimitive() &&
                            costElement != null && costElement.isJsonPrimitive() && 
                            (costElement.getAsJsonPrimitive().isNumber())) {
                            
                            scored.add(new ModelCost(
                                modelElement.getAsString(), 
                                costElement.getAsDouble()
                            ));
                        }
                    }
                }
                
                if (!scored.isEmpty()) {
                    scored.sort((a, b) -> Double.compare(b.cost, a.cost));
                    JsonElement dateElement = entry.get("date");
                    String dateStr = dateElement != null && dateElement.isJsonPrimitive() ? 
                        dateElement.getAsString() : null;
                    return new ModelDateResult(scored.get(0).model, dateStr);
                }
            }
            
            JsonElement modelsUsedElement = entry.get("modelsUsed");
            if (modelsUsedElement != null && modelsUsedElement.isJsonArray()) {
                JsonArray modelsUsed = modelsUsedElement.getAsJsonArray();
                if (!modelsUsed.isEmpty()) {
                    JsonElement lastElement = modelsUsed.get(modelsUsed.size() - 1);
                    if (lastElement.isJsonPrimitive()) {
                        JsonElement dateElement = entry.get("date");
                        String dateStr = dateElement != null && dateElement.isJsonPrimitive() ? 
                            dateElement.getAsString() : null;
                        return new ModelDateResult(lastElement.getAsString(), dateStr);
                    }
                }
            }
        }
        return new ModelDateResult(null, null);
    }

    private static class ModelCost {
        String model;
        double cost;
        
        ModelCost(String model, double cost) {
            this.model = model;
            this.cost = cost;
        }
    }

    private static String usd(Double value) {
        if (value == null) {
            return "—";
        }
        return String.format("$%,.2f", value);
    }

    private static class LatestCostResult {
        String date;
        Double cost;
        
        LatestCostResult(String date, Double cost) {
            this.date = date;
            this.cost = cost;
        }
    }

    private static LatestCostResult latestDayCost(List<JsonObject> entries, String model) {
        if (entries.isEmpty()) {
            return new LatestCostResult(null, null);
        }
        
        entries.sort((a, b) -> {
            JsonElement dateA = a.get("date");
            JsonElement dateB = b.get("date");
            String strA = dateA != null && dateA.isJsonPrimitive() ? dateA.getAsString() : "";
            String strB = dateB != null && dateB.isJsonPrimitive() ? dateB.getAsString() : "";
            return strA.compareTo(strB);
        });
        
        Collections.reverse(entries);
        
        for (JsonObject entry : entries) {
            JsonElement breakdownsElement = entry.get("modelBreakdowns");
            if (breakdownsElement != null && breakdownsElement.isJsonArray()) {
                JsonArray breakdowns = breakdownsElement.getAsJsonArray();
                for (JsonElement item : breakdowns) {
                    if (item.isJsonObject()) {
                        JsonObject obj = item.getAsJsonObject();
                        JsonElement modelNameElement = obj.get("modelName");
                        if (modelNameElement != null && modelNameElement.isJsonPrimitive() &&
                            modelNameElement.getAsString().equals(model)) {
                            
                            JsonElement costElement = obj.get("cost");
                            Double cost = null;
                            if (costElement != null && costElement.isJsonPrimitive() && 
                                costElement.getAsJsonPrimitive().isNumber()) {
                                cost = costElement.getAsDouble();
                            }
                            
                            JsonElement dateElement = entry.get("date");
                            String dateStr = dateElement != null && dateElement.isJsonPrimitive() ? 
                                dateElement.getAsString() : null;
                                
                            return new LatestCostResult(dateStr, cost);
                        }
                    }
                }
            }
        }
        return new LatestCostResult(null, null);
    }

    private static String renderTextCurrent(
        String provider,
        String model,
        String latestDate,
        Double totalCost,
        Double latestCost,
        String latestCostDate,
        int entryCount
    ) {
        List<String> lines = new ArrayList<>();
        lines.add("Provider: " + provider);
        lines.add("Current model: " + model);
        if (latestDate != null) {
            lines.add("Latest model date: " + latestDate);
        }
        lines.add("Total cost (rows): " + usd(totalCost));
        if (latestCostDate != null) {
            lines.add("Latest day cost: " + usd(latestCost) + " (" + latestCostDate + ")");
        }
        lines.add("Daily rows: " + entryCount);
        return String.join("\n", lines);
    }

    private static String renderTextAll(String provider, Map<String, Double> totals) {
        List<String> lines = new ArrayList<>();
        lines.add("Provider: " + provider);
        lines.add("Models:");
        
        List<Map.Entry<String, Double>> sortedEntries = new ArrayList<>(totals.entrySet());
        sortedEntries.sort((a, b) -> Double.compare(b.getValue(), a.getValue()));
        
        for (Map.Entry<String, Double> entry : sortedEntries) {
            lines.add("- " + entry.getKey() + ": " + usd(entry.getValue()));
        }
        return String.join("\n", lines);
    }

    private static JsonObject buildJsonCurrent(
        String provider,
        String model,
        String latestDate,
        Double totalCost,
        Double latestCost,
        String latestCostDate,
        int entryCount
    ) {
        JsonObject obj = new JsonObject();
        obj.addProperty("provider", provider);
        obj.addProperty("mode", "current");
        obj.addProperty("model", model);
        if (latestDate != null) {
            obj.addProperty("latestModelDate", latestDate);
        }
        if (totalCost != null) {
            obj.addProperty("totalCostUSD", totalCost);
        }
        if (latestCost != null) {
            obj.addProperty("latestDayCostUSD", latestCost);
        }
        if (latestCostDate != null) {
            obj.addProperty("latestDayCostDate", latestCostDate);
        }
        obj.addProperty("dailyRowCount", entryCount);
        return obj;
    }

    private static JsonObject buildJsonAll(String provider, Map<String, Double> totals) {
        JsonObject obj = new JsonObject();
        obj.addProperty("provider", provider);
        obj.addProperty("mode", "all");
        
        JsonArray modelsArray = new JsonArray();
        List<Map.Entry<String, Double>> sortedEntries = new ArrayList<>(totals.entrySet());
        sortedEntries.sort((a, b) -> Double.compare(b.getValue(), a.getValue()));
        
        for (Map.Entry<String, Double> entry : sortedEntries) {
            JsonObject modelObj = new JsonObject();
            modelObj.addProperty("model", entry.getKey());
            modelObj.addProperty("totalCostUSD", entry.getValue());
            modelsArray.add(modelObj);
        }
        obj.add("models", modelsArray);
        return obj;
    }
}
