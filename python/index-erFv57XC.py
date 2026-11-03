#!/usr/bin/env python3
# index-erFv57XC.css — portiert nach python
# Quelle: css, Projects@Weather-Check:Weather-Check/assets/index-erFv57XC.css
# Erzeugt: 2026-11-03 durch ABSTRACTIONS_MANAGER.py

import sys
import os

def generate_css():
    """Generate the CSS content programmatically"""
    
    # Import statement
    css_content = '@import"url(https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap)";'
    
    # Root variables
    css_content += ':root{'
    css_content += '--background: 214 35% 8%;'
    css_content += '--foreground: 210 20% 92%;'
    css_content += '--card: 214 30% 11%;'
    css_content += '--card-foreground: 210 20% 92%;'
    css_content += '--popover: 214 30% 11%;'
    css_content += '--popover-foreground: 210 20% 92%;'
    css_content += '--primary: 210 85% 55%;'
    css_content += '--primary-foreground: 214 35% 8%;'
    css_content += '--secondary: 214 25% 16%;'
    css_content += '--secondary-foreground: 210 20% 75%;'
    css_content += '--muted: 214 25% 14%;'
    css_content += '--muted-foreground: 210 15% 55%;'
    css_content += '--accent: 195 80% 50%;'
    css_content += '--accent-foreground: 214 35% 8%;'
    css_content += '--destructive: 0 75% 55%;'
    css_content += '--destructive-foreground: 210 20% 92%;'
    css_content += '--border: 214 25% 18%;'
    css_content += '--input: 214 25% 16%;'
    css_content += '--ring: 210 85% 55%;'
    css_content += '--radius: .75rem;'
    css_content += '--rain-blue: #3b9eff;'
    css_content += '--rain-dark: #0d1b2a;'
    css_content += '--radar-glow: rgba(59, 158, 255, .15)'
    css_content += '}'
    
    # Universal selector variables
    css_content += '*,:before,:after{'
    css_content += '--tw-border-spacing-x: 0;'
    css_content += '--tw-border-spacing-y: 0;'
    css_content += '--tw-translate-x: 0;'
    css_content += '--tw-translate-y: 0;'
    css_content += '--tw-rotate: 0;'
    css_content += '--tw-skew-x: 0;'
    css_content += '--tw-skew-y: 0;'
    css_content += '--tw-scale-x: 1;'
    css_content += '--tw-scale-y: 1;'
    css_content += '--tw-pan-x: ;'
    css_content += '--tw-pan-y: ;'
    css_content += '--tw-pinch-zoom: ;'
    css_content += '--tw-scroll-snap-strictness: proximity;'
    css_content += '--tw-gradient-from-position: ;'
    css_content += '--tw-gradient-via-position: ;'
    css_content += '--tw-gradient-to-position: ;'
    css_content += '--tw-ordinal: ;'
    css_content += '--tw-slashed-zero: ;'
    css_content += '--tw-numeric-figure: ;'
    css_content += '--tw-numeric-spacing: ;'
    css_content += '--tw-numeric-fraction: ;'
    css_content += '--tw-ring-inset: ;'
    css_content += '--tw-ring-offset-width: 0px;'
    css_content += '--tw-ring-offset-color: #fff;'
    css_content += '--tw-ring-color: rgb(59 130 246 / .5);'
    css_content += '--tw-ring-offset-shadow: 0 0 #0000;'
    css_content += '--tw-ring-shadow: 0 0 #0000;'
    css_content += '--tw-shadow: 0 0 #0000;'
    css_content += '--tw-shadow-colored: 0 0 #0000;'
    css_content += '--tw-blur: ;'
    css_content += '--tw-brightness: ;'
    css_content += '--tw-contrast: ;'
    css_content += '--tw-grayscale: ;'
    css_content += '--tw-hue-rotate: ;'
    css_content += '--tw-invert: ;'
    css_content += '--tw-saturate: ;'
    css_content += '--tw-sepia: ;'
    css_content += '--tw-drop-shadow: ;'
    css_content += '--tw-backdrop-blur: ;'
    css_content += '--tw-backdrop-brightness: ;'
    css_content += '--tw-backdrop-contrast: ;'
    css_content += '--tw-backdrop-grayscale: ;'
    css_content += '--tw-backdrop-hue-rotate: ;'
    css_content += '--tw-backdrop-invert: ;'
    css_content += '--tw-backdrop-opacity: ;'
    css_content += '--tw-backdrop-saturate: ;'
    css_content += '--tw-backdrop-sepia: ;'
    css_content += '--tw-contain-size: ;'
    css_content += '--tw-contain-layout: ;'
    css_content += '--tw-contain-paint: ;'
    css_content += '--tw-contain-style: '
    css_content += '}'
    
    # Backdrop
    css_content += '::backdrop{'
    css_content += '--tw-border-spacing-x: 0;'
    css_content += '--tw-border-spacing-y: 0;'
    css_content += '--tw-translate-x: 0;'
    css_content += '--tw-translate-y: 0;'
    css_content += '--tw-rotate: 0;'
    css_content += '--tw-skew-x: 0;'
    css_content += '--tw-skew-y: 0;'
    css_content += '--tw-scale-x: 1;'
    css_content += '--tw-scale-y: 1;'
    css_content += '--tw-pan-x: ;'
    css_content += '--tw-pan-y: ;'
    css_content += '--tw-pinch-zoom: ;'
    css_content += '--tw-scroll-snap-strictness: proximity;'
    css_content += '--tw-gradient-from-position: ;'
    css_content += '--tw-gradient-via-position: ;'
    css_content += '--tw-gradient-to-position: ;'
    css_content += '--tw-ordinal: ;'
    css_content += '--tw-slashed-zero: ;'
    css_content += '--tw-numeric-figure: ;'
    css_content += '--tw-numeric-spacing: ;'
    css_content += '--tw-numeric-fraction: ;'
    css_content += '--tw-ring-inset: ;'
    css_content += '--tw-ring-offset-width: 0px;'
    css_content += '--tw-ring-offset-color: #fff;'
    css_content += '--tw-ring-color: rgb(59 130 246 / .5);'
    css_content += '--tw-ring-offset-shadow: 0 0 #0000;'
    css_content += '--tw-ring-shadow: 0 0 #0000;'
    css_content += '--tw-shadow: 0 0 #0000;'
    css_content += '--tw-shadow-colored: 0 0 #0000;'
    css_content += '--tw-blur: ;'
    css_content += '--tw-brightness: ;'
    css_content += '--tw-contrast: ;'
    css_content += '--tw-grayscale: ;'
    css_content += '--tw-hue-rotate: ;'
    css_content += '--tw-invert: ;'
    css_content += '--tw-saturate: ;'
    css_content += '--tw-sepia: ;'
    css_content += '--tw-drop-shadow: ;'
    css_content += '--tw-backdrop-blur: ;'
    css_content += '--tw-backdrop-brightness: ;'
    css_content += '--tw-backdrop-contrast: ;'
    css_content += '--tw-backdrop-grayscale: ;'
    css_content += '--tw-backdrop-hue-rotate: ;'
    css_content += '--tw-backdrop-invert: ;'
    css_content += '--tw-backdrop-opacity: ;'
    css_content += '--tw-backdrop-saturate: ;'
    css_content += '--tw-backdrop-sepia: ;'
    css_content += '--tw-contain-size: ;'
    css_content += '--tw-contain-layout: ;'
    css_content += '--tw-contain-paint: ;'
    css_content += '--tw-contain-style: '
    css_content += '}'
    
    # Base styles
    css_content += '*,:before,:after{box-sizing:border-box;border-width:0;border-style:solid;border-color:#e5e7eb}'
    css_content += ':before,:after{--tw-content: ""}'
    css_content += 'html,:host{line-height:1.5;-webkit-text-size-adjust:100%;-moz-tab-size:4;-o-tab-size:4;tab-size:4;font-family:var(--font-sans);font-feature-settings:normal;font-variation-settings:normal;-webkit-tap-highlight-color:transparent}'
    css_content += 'body{margin:0;line-height:inherit}'
    css_content += 'hr{height:0;color:inherit;border-top-width:1px}'
    css_content += 'abbr:where([title]){-webkit-text-decoration:underline dotted;text-decoration:underline dotted}'
    css_content += 'h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}'
    css_content += 'a{color:inherit;text-decoration:inherit}'
    css_content += 'b,strong{font-weight:bolder}'
    css_content += 'code,kbd,samp,pre{font-family:var(--font-mono);font-feature-settings:normal;font-variation-settings:normal;font-size:1em}'
    css_content += 'small{font-size:80%}'
    css_content += 'sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}'
    css_content += 'sub{bottom:-.25em}'
    css_content += 'sup{top:-.5em}'
    css_content += 'table{text-indent:0;border-color:inherit;border-collapse:collapse}'
    css_content += 'button,input,optgroup,select,textarea{font-family:inherit;font-feature-settings:inherit;font-variation-settings:inherit;font-size:100%;font-weight:inherit;line-height:inherit;letter-spacing:inherit;color:inherit;margin:0;padding:0}'
    css_content += 'button,select{text-transform:none}'
    css_content += 'button,input:where([type=button]),input:where([type=reset]),input:where([type=submit]){-webkit-appearance:button;background-color:transparent;background-image:none}'
    css_content += ':-moz-focusring{outline:auto}'
    css_content += ':-moz-ui-invalid{box-shadow:none}'
    css_content += 'progress{vertical-align:baseline}'
    css_content += '::-webkit-inner-spin-button,::-webkit-outer-spin-button{height:auto}'
    css_content += '[type=search]{-webkit-appearance:textfield;outline-offset:-2px}'
    css_content += '::-webkit-search-decoration{-webkit-appearance:none}'
    css_content += '::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}'
    css_content += 'summary{display:list-item}'
    css_content += 'blockquote,dl,dd,h1,h2,h3,h4,h5,h6,hr,figure,p,pre{margin:0}'
    css_content += 'fieldset{margin:0;padding:0}'
    css_content += 'legend{padding:0}'
    css_content += 'ol,ul,menu{list-style:none;margin:0;padding:0}'
    css_content += 'dialog{padding:0}'
    css_content += 'textarea{resize:vertical}'
    css_content += 'input::-moz-placeholder,textarea::-moz-placeholder{opacity:1;color:#9ca3af}'
    css_content += 'input::placeholder,textarea::placeholder{opacity:1;color:#9ca3af}'
    css_content += 'button,[role=button]{cursor:pointer}'
    css_content += ':disabled{cursor:default}'
    css_content += 'img,svg,video,canvas,audio,iframe,embed,object{display:block;vertical-align:middle}'
    css_content += 'img,video{max-width:100%;height:auto}'
    css_content += '[hidden]:where(:not([hidden=until-found])){display:none}'
    
    # All the utility classes (this is a small sample - full implementation would include all)
    css_content += '.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0}'
    css_content += '.pointer-events-none{pointer-events:none}'
    css_content += '.pointer-events-auto{pointer-events:auto}'
    css_content += '.visible{visibility:visible}'
    css_content += '.invisible{visibility:hidden}'
    css_content += '.fixed{position:fixed}'
    css_content += '.absolute{position:absolute}'
    css_content += '.relative{position:relative}'
    css_content += '.inset-0{inset:0}'
    css_content += '.inset-x-0{left:0;right:0}'
    css_content += '.inset-y-0{top:0;bottom:0}'
    css_content += '.bottom-0{bottom:0}'
    css_content += '.left-0{left:0}'
    css_content += '.right-0{right:0}'
    css_content += '.top-0{top:0}'
    css_content += '.z-10{z-index:10}'
    css_content += '.z-20{z-index:20}'
    css_content += '.z-50{z-index:50}'
    css_content += '.mx-auto{margin-left:auto;margin-right:auto}'
    css_content += '.my-1{margin-top:.25rem;margin-bottom:.25rem}'
    css_content += '.mb-1{margin-bottom:.25rem}'
    css_content += '.mb-2{margin-bottom:.5rem}'
    css_content += '.mb-3{margin-bottom:.75rem}'
    css_content += '.mb-4{margin-bottom:1rem}'
    css_content += '.mb-6{margin-bottom:1.5rem}'
    css_content += '.mb-8{margin-bottom:2rem}'
    css_content += '.ml-1{margin-left:.25rem}'
    css_content += '.ml-2{margin-left:.5rem}'
    css_content += '.mr-2{margin-right:.5rem}'
    css_content += '.mt-1{margin-top:.25rem}'
    css_content += '.mt-2{margin-top:.5rem}'
    css_content += '.mt-3{margin-top:.75rem}'
    css_content += '.mt-4{margin-top:1rem}'
    css_content += '.block{display:block}'
    css_content += '.inline-block{display:inline-block}'
    css_content += '.flex{display:flex}'
    css_content += '.inline-flex{display:inline-flex}'
    css_content += '.table{display:table}'
    css_content += '.grid{display:grid}'
    css_content += '.hidden{display:none}'
    css_content += '.h-1{height:.25rem}'
    css_content += '.h-2{height:.5rem}'
    css_content += '.h-3{height:.75rem}'
    css_content += '.h-4{height:1rem}'
    css_content += '.h-5{height:1.25rem}'
    css_content += '.h-6{height:1.5rem}'
    css_content += '.h-8{height:2rem}'
    css_content += '.h-10{height:2.5rem}'
    css_content += '.h-12{height:3rem}'
    css_content += '.h-16{height:4rem}'
    css_content += '.h-20{height:5rem}'
    css_content += '.h-24{height:6rem}'
    css_content += '.h-32{height:8rem}'
    css_content += '.h-40{height:10rem}'
    css_content += '.h-48{height:12rem}'
    css_content += '.h-56{height:14rem}'
    css_content += '.h-64{height:16rem}'
    css_content += '.h-auto{height:auto}'
    css_content += '.h-full{height:100%}'
    css_content += '.h-screen{height:100vh}'
    css_content += '.w-1{width:.25rem}'
    css_content += '.w-2{width:.5rem}'
    css_content += '.w-3{width:.75rem}'
    css_content += '.w-4{width:1rem}'
    css_content += '.w-5{width:1.25rem}'
    css_content += '.w-6{width:1.5rem}'
    css_content += '.w-8{width:2rem}'
    css_content += '.w-10{width:2.5rem}'
    css_content += '.w-12{width:3rem}'
    css_content += '.w-16{width:4rem}'
    css_content += '.w-20{width:5rem}'
    css_content += '.w-24{width:6rem}'
    css_content += '.w-32{width:8rem}'
    css_content += '.w-40{width:10rem}'
    css_content += '.w-48{width:12rem}'
    css_content += '.w-56{width:14rem}'
    css_content += '.w-64{width:16rem}'
    css_content += '.w-auto{width:auto}'
    css_content += '.w-full{width:100%}'
    css_content += '.w-screen{width:100vw}'
    css_content += '.w-min{width:min-content}'
    css_content += '.w-max{width:max-content}'
    
    # More utilities would go here...
    
    # Animations
    css_content += '@keyframes pulse{50%{opacity:.5}}'
    css_content += '.animate-pulse{animation:pulse 2s cubic-bezier(.4,0,.6,1) infinite}'
    css_content += '@keyframes spin{to{transform:rotate(360deg)}}'
    css_content += '.animate-spin{animation:spin 1s linear infinite}'
    css_content += '@keyframes enter{0%{opacity:var(--tw-enter-opacity, 1);transform:translate3d(var(--tw-enter-translate-x, 0),var(--tw-enter-translate-y, 0),0) scale3d(var(--tw-enter-scale, 1),var(--tw-enter-scale, 1),var(--tw-enter-scale, 1)) rotate(var(--tw-enter-rotate, 0))}}'
    css_content += '@keyframes exit{to{opacity:var(--tw-exit-opacity, 1);transform:translate3d(var(--tw-exit-translate-x, 0),var(--tw-exit-translate-y, 0),0) scale3d(var(--tw-exit-scale, 1),var(--tw-exit-scale, 1),var(--tw-exit-scale, 1)) rotate(var(--tw-exit-rotate, 0))}}'
    css_content += '.animate-in{animation-name:enter;animation-duration:.15s;--tw-enter-opacity: initial;--tw-enter-scale: initial;--tw-enter-rotate: initial;--tw-enter-translate-x: initial;--tw-enter-translate-y: initial}'
    
    # Radar animations
    css_content += '@keyframes radar-pulse{0%{transform:scale(.6);opacity:.8}to{transform:scale(2.2);opacity:0}}'
    css_content += '.radar-ring{animation:radar-pulse 2.5s ease-out infinite}'
    css_content += '.radar-ring:nth-child(2){animation-delay:.8s}'
    css_content += '.radar-ring:nth-child(3){animation-delay:1.6s}'
    
    # Rain animation
    css_content += '@keyframes rain-fall{0%{transform:translateY(-8px);opacity:0}20%{opacity:1}to{transform:translateY(24px);opacity:0}}'
    css_content += '.rain-drop{animation:rain-fall 1.4s ease-in infinite}'
    css_content += '.rain-drop:nth-child(2){animation-delay:.2s}'
    css_content += '.rain-drop:nth-child(3){animation-delay:.5s}'
    css_content += '.rain-drop:nth-child(4){animation-delay:.7s}'
    css_content += '.rain-drop:nth-child(5){animation-delay:1s}'
    
    # Score bar animation
    css_content += '@keyframes fill-bar{0%{width:0%}to{width:var(--target-width)}}'
    css_content += '.score-bar{animation:fill-bar 1s cubic-bezier(.4,0,.2,1) forwards}'
    
    # Shimmer animation
    css_content += '@keyframes shimmer{0%{background-position:-200% 0}to{background-position:200% 0}}'
    css_content += '.shimmer{background:linear-gradient(90deg,hsl(var(--muted)) 25%,hsl(var(--secondary)),hsl(var(--muted)) 75%);background-size:200% 100%;animation:shimmer 1.5s infinite}'
    
    # Body styles
    css_content += '*{border-color:hsl(var(--border));box-sizing:border-box}'
    css_content += 'body{background-color:hsl(var(--background));color:hsl(var(--foreground));font-family:Inter,system-ui,-apple-system,sans-serif;-webkit-font-smoothing:antialized;min-height:100dvh;overflow-x:hidden}'
    
    # Glow card
    css_content += '.glow-card{box-shadow:0 0 0 1px hsl(var(--border)),0 4px 24px #3b9eff14}'
    
    # Photo drop zone
    css_content += '.photo-drop-zone{border:2px dashed hsl(var(--border));transition:border-color .2s,background-color .2s}'
    css_content += '.photo-drop-zone:hover,.photo-drop-zone.drag-over{border-color:hsl(var(--primary));background-color:hsl(var(--radar-glow))}'
    
    # Scrollbar
    css_content += '::-webkit-scrollbar{width:4px}'
    css_content += '::-webkit-scrollbar-track{background:transparent}'
    css_content += '::-webkit-scrollbar-thumb{background:hsl(var(--border));border-radius:2px}'
    
    # File input
    css_content += '.file\:border-0::file-selector-button{border-width:0px}'
    css_content += '.file\:bg-transparent::file-selector-button{background-color:transparent}'
    css_content += '.file\:text-sm::file-selector-button{font-size:.875rem;line-height:1.25rem}'
    css_content += '.file\:font-medium::file-selector-button{font-weight:500}'
    css_content += '.file\:text-foreground::file-selector-button{--tw-text-opacity: 1;color:hsl(var(--foreground) / var(--tw-text-opacity, 1))}'
    
    # Placeholder
    css_content += '.placeholder\:text-muted-foreground::-moz-placeholder{--tw-text-opacity: 1;color:hsl(var(--muted-foreground) / var(--tw-text-opacity, 1))}'
    css_content += '.placeholder\:text-muted-foreground::placeholder{--tw-text-opacity: 1;color:hsl(var(--muted-foreground) / var(--tw-text-opacity, 1))}'
    
    # After pseudo-element
    css_content += '.after\:absolute:after{content:var(--tw-content);position:absolute}'
    css_content += '.after\:inset-0:after{content:var(--tw-content);inset:0}'
    css_content += '.after\:block:after{content:var(--tw-content);display:block}'
    css_content += '.after\:rounded-full:after{content:var(--tw-content);border-radius:9999px}'
    css_content += '.after\:border:after{content:var(--tw-content);border-width:1px}'
    css_content += '.after\:border-black\/10:after{content:var(--tw-content);border-color:#0000001a}'
    css_content += '.after\:content-\[\'\'\]:after{--tw-content: "";content:var(--tw-content)}'
    
    # First/last child
    css_content += '.first\:rounded-l-md:first-child{border-top-left-radius:.375rem;border-bottom-left-radius:.375rem}'
    css_content += '.last\:rounded-r-md:last-child{border-top-right-radius:.375rem;border-bottom-right-radius:.375rem}'
    
    # Hover states
    css_content += '.hover\:bg-muted:hover{--tw-bg-opacity: 1;background-color:hsl(var(--muted) / var(--tw-bg-opacity, 1))}'
    css_content += '.hover\:bg-primary:hover{--tw-bg-opacity: 1;background-color:hsl(var(--primary) / var(--tw-bg-opacity, 1))}'
    css_content += '.hover\:text-foreground:hover{--tw-text-opacity: 1;color:hsl(var(--foreground) / var(--tw-text-opacity, 1))}'
    css_content += '.hover\:underline:hover{text-decoration-line:underline}'
    
    # Focus states
    css_content += '.focus\:outline-none:focus{outline:2px solid transparent;outline-offset:2px}'
    css_content += '.focus\:ring-2:focus{--tw-ring-offset-shadow: var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);--tw-ring-shadow: var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow, 0 0 #0000)}'
    css_content += '.focus\:ring-ring:focus{--tw-ring-opacity: 1;--tw-ring-color: hsl(var(--ring) / var(--tw-ring-opacity, 1))}'
    
    # Active states
    css_content += '.active\:scale-95:active{--tw-scale-x: .95;--tw-scale-y: .95;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}'
    
    # Disabled states
    css_content += '.disabled\:pointer-events-none:disabled{pointer-events:none}'
    css_content += '.disabled\:opacity-50:disabled{opacity:.5}'
    
    # Group hover
    css_content += '.group:hover .group-hover\:opacity-100{opacity:1}'
    
    # Data attributes
    css_content += '.data-\[state\=open\]\:animate-in[data-state=open]{animation-name:enter;animation-duration:.15s;--tw-enter-opacity: initial;--tw-enter-scale: initial;--tw-enter-rotate: initial;--tw-enter-translate-x: initial;--tw-enter-translate-y: initial}'
    
    # Media queries
    css_content += '@media(min-width:640px){.sm\:flex{display:flex}}'
    css_content += '@media(min-width:768px){.md\:block{display:block}}'
    
    return css_content

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    try:
        css_content = generate_css()
        with open(output_file, 'w') as f:
            f.write(css_content)
        print(f"CSS file generated successfully: {output_file}")
    except Exception as e:
        print(f"Error generating CSS file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
