import os
import glob
import re

pattern = re.compile(
    r'<a href="([^"]*)" class="[^"]*text-2xl font-black tracking-tight[^"]*">\s*<span class="bg-gradient-to-r from-violet-400 via-fuchsia-400 to-cyan-400 bg-clip-text text-transparent">LELE</span>\s*<span class="[^"]*">Design</span>\s*</a>',
    re.IGNORECASE | re.DOTALL
)

replacement = r'''<a href="\1" class="flex flex-col justify-center group transition-transform hover:scale-105">
        <div class="text-2xl md:text-[28px] font-black tracking-tighter leading-none flex items-center gap-1.5 drop-shadow-[0_0_15px_rgba(168,85,247,0.4)]">
          <span class="bg-gradient-to-r from-violet-400 via-fuchsia-400 to-fuchsia-300 bg-clip-text text-transparent">LELE</span>
          <span class="text-cyan-400 font-normal tracking-tight drop-shadow-[0_0_10px_rgba(34,211,238,0.5)]">OFICIAL</span>
        </div>
        <span class="text-[10px] font-semibold tracking-[0.25em] text-white/40 mt-1 uppercase pl-0.5">Diseño y Optimizaciones</span>
      </a>'''

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content, count = pattern.subn(replacement, content)
    
    if count > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {count} logo(s) in {filepath}")

# Process all html files in pages directory
for file in glob.glob('pages/*.html'):
    process_file(file)

print("Replacement complete.")
