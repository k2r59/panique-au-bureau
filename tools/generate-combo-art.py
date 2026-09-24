from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
font=TTFont('assets/fonts/LilitaOne-Regular.ttf'); glyphs=font.getGlyphSet(); cmap=font.getBestCmap(); scale=78/font['head'].unitsPerEm
for n in range(2,6):
    x=0; paths=[]
    for c in f'COMBO ×{n}':
        name=cmap[ord(c)]; pen=SVGPathPen(glyphs); glyphs[name].draw(TransformPen(pen,(scale,0,0,-scale,x,0)))
        paths.append(f'<path d="{pen.getCommands()}"/>'); x+=glyphs[name].width*scale
    shape=''.join(paths)
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="320" viewBox="0 0 500 160"><defs><linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#fff6a5"/><stop offset=".42" stop-color="#ffdc48"/><stop offset="1" stop-color="#ff981b"/></linearGradient><g id="letters">{shape}</g></defs><g transform="translate({(500-x)/2:.2f},111) rotate(-4 {x/2:.2f} -25)">
<use href="#letters" transform="translate(0 8)" fill="#4a1624" stroke="#4a1624" stroke-width=".14"/>
<g fill="#ab3d0e" stroke="#6a2519" stroke-width="9" stroke-linejoin="round"><use href="#letters" transform="translate(0 6)"/></g>
<g fill="url(#gold)" stroke="#e87812" stroke-width="6" stroke-linejoin="round" paint-order="stroke fill"><use href="#letters"/></g>
<g fill="url(#gold)"><use href="#letters"/></g></g></svg>'''
    # Outline strokes must use non-scaling-stroke because each glyph carries its font scaling.
    svg=svg.replace('<path transform=', '<path vector-effect="non-scaling-stroke" transform=')
    Path(f'assets/ui/combo-gold-{n}.svg').write_text(svg)
