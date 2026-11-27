#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "5d26ba0b784da5bb9d026d5d8fc5fb6f4fa24116e931f2614e6b5f2a814de5f6", "source_sha256": "9be2a45ff3b835da1be1793cc88c8cb54d6a2456cf2ccc358c8243df836440e3", "target_language": "ruby"}
# status-overview-panel.css — portiert nach ruby
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Generates the status-overview-panel.css file
class StatusOverviewPanelCSSGenerator
  def initialize(output_file)
    @output_file = output_file
  end

  def generate
    css_content = [
      overview_row_styles,
      overview_state_styles,
      overview_count_styles,
      overview_actions_styles,
      additional_styles,
      overview_retry_styles,
      top_setting_styles,
      visually_hidden_styles
    ].join("\n\n")

    File.write(@output_file, css_content)
  end

  private

  def overview_row_styles
    <<~CSS
      .overview-row { display:grid; grid-template-columns:24px minmax(0,1fr) 11px 22px auto; gap:7px; align-items:center; margin:6px 0; }
      .overview-row input { min-width:0; width:100%; }
    CSS
  end

  def overview_state_styles
    <<~CSS
      .overview-state { width:11px; height:11px; border-radius:50%; background:#888; }
      .overview-state.online { background:var(--good); box-shadow:0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent); }
      .overview-state.offline { background:var(--bad); box-shadow:0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }
      .overview-state.checking, .overview-state.error { background:var(--warn); }
    CSS
  end

  def overview_count_styles
    <<~CSS
      .overview-count { font-size:11px; text-align:center; font-variant-numeric:tabular-nums; }
    CSS
  end

  def overview_actions_styles
    <<~CSS
      .overview-actions { display:grid; grid-template-columns:44px repeat(2,minmax(0,1fr)); gap:6px; align-items:stretch; }
      .overview-actions button { min-width:0; padding:8px 2px; font-size:11px; white-space:nowrap; }
    CSS
  end

  def additional_styles
    <<~CSS
      #overview-rows { display:flex; flex-direction:column; }
      .monitor-settings > label:not(.option-row) { display:block; margin:12px 0; }
      .monitor-settings .option-row input { appearance:auto; width:13px; height:13px; min-width:13px; background:none; }
      .overview-link { padding:8px 0; border-bottom:1px solid #bbb; overflow-wrap:anywhere; }
      .overview-link p { margin:4px 0; }
    CSS
  end

  def overview_retry_styles
    <<~CSS
      .overview-row .overview-retry { width:24px; min-width:24px; height:26px; min-height:26px; padding:0; background-image:var(--icon-reset); background-size:20px; background-position:center; background-repeat:no-repeat; }
    CSS
  end

  def top_setting_styles
    <<~CSS
      .top-setting input { appearance:auto; -webkit-appearance:checkbox; width:13px; height:13px; min-width:13px; background:none; }
    CSS
  end

  def visually_hidden_styles
    <<~CSS
      .overview-visually-hidden { position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0,0,0,0); white-space:nowrap; border:0; }
      .overview-row[hidden] { display:none; }
    CSS
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <output-file>"
    exit 1
  end

  generator = StatusOverviewPanelCSSGenerator.new(ARGV[0])
  generator.generate
  puts "CSS file generated successfully: #{ARGV[0]}"
end
