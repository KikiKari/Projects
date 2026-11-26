#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "44a860b283a9b0bb20091c61c102cbf3c3afec7943d8c0bca506c8c96d45a602", "source_sha256": "b88df9f02f19546f5017a166224fb0f62931a65cd0239064afc9de2e7c454027", "target_language": "ruby"}
# globals.css — portiert nach ruby
# Quelle: css, Onboarding@main:app/globals.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Generates a CSS file with global styles and variables
class GlobalsCSSGenerator
  def initialize
    @variables = {
      bg: '#faf8f4',
      surface: '#ffffff',
      'surface-2': '#f1eee7',
      ink: '#1b1a17',
      'ink-2': '#3c3a34',
      muted: '#6e6a61',
      line: '#e5e1d8',
      'line-strong': '#d4cfc3',
      accent: '#a8542f',
      'accent-press': '#8e4526',
      'accent-tint': '#f1e5dd',
      'on-accent': '#ffffff',
      'accent-2': '#2e7d7b',
      'accent-2-press': '#225e5b',
      'accent-3': '#c77d2e',
      'footer-bg': '#191815',
      'footer-fg': '#efeae0',
      'footer-muted': '#9a958a',
      success: '#2e7d5b',
      danger: '#9e3f32',
      'font-display': '"Iowan Old Style", "Palatino Linotype", Georgia, "Times New Roman", serif',
      'font-sans': '"Segoe UI", Inter, system-ui, -apple-system, sans-serif',
      'font-mono': '"Cascadia Code", "SFMono-Regular", Consolas, ui-monospace, monospace',
      'space-1': '0.25rem',
      'space-2': '0.5rem',
      'space-3': '0.75rem',
      'space-4': '1rem',
      'space-5': '1.25rem',
      'space-6': '1.5rem',
      'space-8': '2rem',
      'space-10': '2.5rem',
      'space-12': '3rem',
      'space-16': '4rem',
      'space-20': '5rem',
      'space-24': '6rem',
      'space-30': '7.5rem',
      'radius-sm': '0.375rem',
      'radius-md': '0.625rem',
      'radius-lg': '1.125rem',
      'radius-pill': '999px',
      'shadow-sm': '0 1px 2px rgb(27 26 23 / 6%)',
      'shadow-md': '0 10px 30px -16px rgb(27 26 23 / 22%)',
      'shadow-lg': '0 34px 70px -34px rgb(27 26 23 / 32%)',
      container: '75rem',
      'motion-fast': '180ms',
      'motion-base': '350ms',
      'motion-slow': '800ms',
      'ease-out': 'cubic-bezier(0.22, 0.61, 0.36, 1)'
    }

    @theme_variables = [
      '--color-bg: var(--bg)',
      '--color-surface: var(--surface)',
      '--color-surface-2: var(--surface-2)',
      '--color-ink: var(--ink)',
      '--color-ink-2: var(--ink-2)',
      '--color-muted: var(--muted)',
      '--color-line: var(--line)',
      '--color-line-strong: var(--line-strong)',
      '--color-accent: var(--accent)',
      '--color-accent-2: var(--accent-2)',
      '--color-accent-3: var(--accent-3)',
      '--font-display: var(--font-display)',
      '--font-sans: var(--font-sans)',
      '--font-mono: var(--font-mono)'
    ]

    @base_styles = {
      '*': ['box-sizing: border-box'],
      'html': ['scroll-behavior: smooth'],
      'body': [
        'margin: 0',
        'background: var(--bg)',
        'color: var(--ink)',
        'font-family: var(--font-sans)',
        'line-height: 1.5',
        '-webkit-font-smoothing: antialiased'
      ],
      'a': ['color: inherit'],
      'button, input, textarea': ['font: inherit'],
      '::selection': [
        'background: var(--accent-tint)',
        'color: var(--ink)'
      ]
    }

    @utility_classes = {
      '.display': [
        'font-family: var(--font-display)',
        'font-weight: 400',
        'letter-spacing: -0.022em'
      ],
      '.eyebrow': [
        'font-family: var(--font-mono)',
        'font-size: 0.75rem',
        'letter-spacing: 0.16em',
        'text-transform: uppercase'
      ],
      '.focus-ring:focus-visible': [
        'outline: 2px solid var(--accent)',
        'outline-offset: 4px'
      ],
      '.content-auto': [
        'content-visibility: auto',
        'contain-intrinsic-size: 1px 800px'
      ]
    }

    @media_queries = {
      '(prefers-reduced-motion: reduce)': {
        'html': ['scroll-behavior: auto'],
        '*, *::before, *::after': [
          'animation-duration: 0.01ms !important',
          'animation-iteration-count: 1 !important',
          'scroll-behavior: auto !important',
          'transition-duration: 0.01ms !important'
        ]
      }
    }

    @special_rules = [
      '/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */',
      'body[data-hero-immersive="true"] > header,',
      'body[data-hero-immersive="true"] header[data-site-header] {',
      '  opacity: 0;',
      '  pointer-events: none;',
      '  transition: opacity 0.4s ease-out;',
      '}',
      '',
      '/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */',
      '@keyframes dropfall {',
      '  0% {',
      '    transform: translateY(0);',
      '    opacity: 0;',
      '  }',
      '  10% {',
      '    opacity: 0.9;',
      '  }',
      '  90% {',
      '    opacity: 0.7;',
      '  }',
      '  100% {',
      '    transform: translateY(110vh);',
      '    opacity: 0;',
      '  }',
      '}'
    ]
  end

  def generate_css
    css = []
    
    # Add import statement
    css << '@import "tailwindcss";'
    css << ''
    
    # Add root variables
    css << ':root {'
    @variables.each do |name, value|
      css << "  --#{name}: #{value};"
    end
    css << '}'
    css << ''
    
    # Add theme inline block
    css << '@theme inline {'
    @theme_variables.each do |variable|
      css << "  #{variable};"
    end
    css << '}'
    css << ''
    
    # Add base styles
    @base_styles.each do |selector, rules|
      css << "#{selector} { #{rules.join('; ')}; }"
    end
    css << ''
    
    # Add utility classes
    @utility_classes.each do |selector, rules|
      css << "#{selector} {"
      rules.each do |rule|
        css << "  #{rule};"
      end
      css << '}'
    end
    css << ''
    
    # Add media queries
    @media_queries.each do |query, rules|
      css << "@media #{query} {"
      rules.each do |selector, selector_rules|
        css << "  #{selector} { #{selector_rules.join('; ')}; }"
      end
      css << '}'
    end
    css << ''
    
    # Add special rules
    @special_rules.each do |rule|
      css << rule
    end
    
    css.join("\n")
  end

  def write_to_file(filename)
    File.write(filename, generate_css)
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <output-file>"
    exit 1
  end

  generator = GlobalsCSSGenerator.new
  generator.write_to_file(ARGV[0])
  puts "CSS file generated: #{ARGV[0]}"
end
