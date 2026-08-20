#!/usr/bin/env node
// tavily_search.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/tavily/scripts/tavily_search.py
// auch in: OpenClaw@gateway2:skills/tavily/scripts/tavily_search.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Tavily AI Search - Optimized search for LLMs and AI applications
 * Requires: npm install tavily
 */

const fs = require('fs');
const path = require('path');
const { Command } = require('commander');

// Try to import the tavily client
let TavilyClient;
try {
  const tavilyModule = require('tavily');
  TavilyClient = tavilyModule.TavilyClient || tavilyModule.default || tavilyModule;
} catch (error) {
  // If module is not found, we'll handle it in the search function
}

/**
 * Execute a Tavily search query.
 * 
 * @param {string} query - Search query string
 * @param {string} apiKey - Tavily API key (tvly-...)
 * @param {Object} options - Search options
 * @returns {Promise<Object>} Tavily API response
 */
async function search(query, apiKey, options = {}) {
  const {
    searchDepth = "basic",
    topic = "general",
    maxResults = 5,
    includeAnswer = true,
    includeRawContent = false,
    includeImages = false,
    includeDomains = null,
    excludeDomains = null
  } = options;

  // Check if tavily module is available
  if (!TavilyClient) {
    return {
      error: "tavily package not installed. Run: npm install tavily",
      installCommand: "npm install tavily"
    };
  }

  if (!apiKey) {
    return {
      error: "Tavily API key required. Get one at https://tavily.com",
      setupInstructions: "Set TAVILY_API_KEY environment variable or use --api-key option"
    };
  }

  try {
    const client = new TavilyClient({ apiKey });
    
    // Build search parameters
    const searchParams = {
      query,
      searchDepth,
      topic,
      maxResults,
      includeAnswer,
      includeRawContent,
      includeImages
    };

    if (includeDomains) {
      searchParams.includeDomains = includeDomains;
    }
    
    if (excludeDomains) {
      searchParams.excludeDomains = excludeDomains;
    }

    const response = await client.search(searchParams);

    return {
      success: true,
      query,
      answer: response.answer,
      results: response.results || [],
      images: response.images || [],
      responseTime: response.responseTime,
      usage: response.usage || {}
    };
  } catch (error) {
    return {
      error: error.message,
      query
    };
  }
}

/**
 * Format and display search results in human-readable format
 * @param {Object} result - Search result object
 */
function displayResults(result) {
  console.log(`Query: ${result.query}`);
  console.log(`Response time: ${result.responseTime || 'N/A'}s`);
  console.log(`Credits used: ${result.usage?.credits || 'N/A'}\n`);

  if (result.answer) {
    console.log("=== AI ANSWER ===");
    console.log(result.answer);
    console.log();
  }

  if (result.results && result.results.length > 0) {
    console.log("=== RESULTS ===");
    result.results.forEach((item, index) => {
      console.log(`\n${index + 1}. ${item.title || 'No title'}`);
      console.log(`   URL: ${item.url || 'N/A'}`);
      console.log(`   Score: ${item.score !== undefined ? item.score.toFixed(3) : 'N/A'}`);
      if (item.content) {
        let content = item.content;
        if (content.length > 200) {
          content = content.substring(0, 200) + "...";
        }
        console.log(`   ${content}`);
      }
    });
  }

  if (result.images && result.images.length > 0) {
    console.log(`\n=== IMAGES (${result.images.length}) ===`);
    result.images.slice(0, 5).forEach(imgUrl => {
      console.log(`   ${imgUrl}`);
    });
  }
}

async function main() {
  const program = new Command();

  program
    .description("Tavily AI Search - Optimized search for LLMs")
    .argument("<query>", "Search query")
    .option("-k, --api-key <key>", "Tavily API key (or set TAVILY_API_KEY env var)")
    .option("-d, --depth <depth>", "Search depth: 'basic' (fast) or 'advanced' (comprehensive)", "basic")
    .option("-t, --topic <topic>", "Search topic: 'general' or 'news' (current events)", "general")
    .option("-m, --max-results <number>", "Maximum number of results (1-10)", "5")
    .option("--no-answer", "Exclude AI-generated answer summary")
    .option("-r, --raw-content", "Include raw HTML content of sources")
    .option("-i, --images", "Include relevant images in results")
    .option("--include-domains <domains...>", "List of domains to specifically include")
    .option("--exclude-domains <domains...>", "List of domains to exclude")
    .option("-j, --json", "Output raw JSON response")
    .helpOption('-h, --help', 'Display help for command')
    .addHelpText('afterAll', `
Examples:
  # Basic search
  $0 "What is quantum computing?"
  
  # Advanced search with more results
  $0 "Climate change solutions" --depth advanced --max-results 10
  
  # News-focused search
  $0 "AI developments" --topic news
  
  # Domain filtering
  $0 "Python tutorials" --include-domains python.org --exclude-domains w3schools.com
  
  # Include images in results
  $0 "Eiffel Tower" --images

Environment Variables:
  TAVILY_API_KEY    Your Tavily API key (get one at https://tavily.com)
    `);

  program.parse();

  const options = program.opts();
  const query = program.args[0];

  // Get API key from options or environment
  const apiKey = options.apiKey || process.env.TAVILY_API_KEY;

  // Convert maxResults to integer
  const maxResults = parseInt(options.maxResults, 10);

  const result = await search(query, apiKey, {
    searchDepth: options.depth,
    topic: options.topic,
    maxResults: isNaN(maxResults) ? 5 : maxResults,
    includeAnswer: options.answer,
    includeRawContent: options.rawContent,
    includeImages: options.images,
    includeDomains: options.includeDomains,
    excludeDomains: options.excludeDomains
  });

  if (options.json) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    if (result.error) {
      console.error(`Error: ${result.error}`);
      if (result.installCommand) {
        console.error(`\nTo install: ${result.installCommand}`);
      }
      if (result.setupInstructions) {
        console.error(`\nSetup: ${result.setupInstructions}`);
      }
      process.exit(1);
    }
    
    displayResults(result);
  }
}

if (require.main === module) {
  main().catch(error => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { search };
