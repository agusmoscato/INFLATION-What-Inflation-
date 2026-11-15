import math, sys
def repulgue(cx, cy, rx, ry, n, a0, a1, size):
    out=[]
    for i in range(n):
        t=a0+(a1-a0)*(i+0.5)/n
        x=cx+rx*math.cos(t); y=cy-ry*math.sin(t)
        # tangent angle
        dx=-rx*math.sin(t); dy=-ry*math.cos(t)
        ang=math.degrees(math.atan2(dy,dx))
        out.append(f'<g transform="translate({x:.1f},{y:.1f}) rotate({ang+35:.1f})"><path d="M {-size} 0 C {-size*0.6} {-size*1.25}, {size*0.9} {-size*1.1}, {size} 0 C {size*0.5} {size*0.55}, {-size*0.5} {size*0.55}, {-size} 0 Z" class="rep"/><path d="M {-size*0.55} {-size*0.15} C {-size*0.1} {-size*0.7}, {size*0.4} {-size*0.6}, {size*0.6} {-size*0.15}" class="repl"/></g>')
    return "\n".join(out)

GRAIN='<feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="1" seed="3" result="g"/><feColorMatrix in="g" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -0.9 1.35" result="ga"/><feComposite in="d" in2="ga" operator="in"/>'
def empanada(board, face=True, steam=True, W=512, grain=True):
    cx,cy=256,330; rx,ry=190,205
    body=f"M {cx-rx} {cy} A {rx} {ry} 0 0 1 {cx+rx} {cy} C {cx+rx-40} {cy+38}, {cx-rx+40} {cy+38}, {cx-rx} {cy} Z"
    hatch=[]
    for i in range(-14,16):
        x=cx+i*14
        hatch.append(f'<line x1="{x-60}" y1="{cy+40}" x2="{x+60}" y2="{cy-200}" class="hatch"/>')
    VB='0 0 512 512' if board else '36 22 440 440'
    s=f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="{VB}">
<defs>
 <filter id="wob" x="-10%" y="-10%" width="120%" height="120%">
  <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="7" result="n"/>
  <feDisplacementMap in="SourceGraphic" in2="n" scale="7" xChannelSelector="R" yChannelSelector="G" result="d"/>
{GRAIN if grain else ""}
 </filter>
 <clipPath id="clip"><path d="{body}"/></clipPath>
 <radialGradient id="dough" cx="45%" cy="35%" r="75%">
  <stop offset="0" stop-color="#FFD98A"/><stop offset="0.6" stop-color="#F2B055"/><stop offset="1" stop-color="#D98B36"/>
 </radialGradient>
</defs>
<style>
 .hatch{{stroke:#FFE7B0;stroke-width:5;stroke-opacity:.35;stroke-linecap:round}}
 .rep{{fill:#F7C46C;stroke:#A85A22;stroke-width:5;stroke-linejoin:round}}
 .repl{{fill:none;stroke:#FFE7B0;stroke-width:4;stroke-linecap:round;opacity:.8}}
 .ol{{fill:none;stroke:#A85A22;stroke-width:9;stroke-linejoin:round;stroke-linecap:round}}
 .w{{fill:#F4F1E8}} .k{{fill:#1E1A17}}
 .steam{{fill:none;stroke:#F4F1E8;stroke-width:9;stroke-linecap:round;opacity:.85}}
</style>
{'<rect width="512" height="512" fill="#2F4A3A"/>' if board else ''}
<g filter="url(#wob)">
 <ellipse cx="{cx}" cy="{cy+44}" rx="{rx-10}" ry="16" fill="#000" opacity="{0.25 if board else 0.18}"/>
 <path d="{body}" fill="url(#dough)"/>
 <g clip-path="url(#clip)">{''.join(hatch)}
  <ellipse cx="{cx-70}" cy="{cy-120}" rx="55" ry="22" fill="#FFF3D0" opacity=".55" transform="rotate(-25 {cx-70} {cy-120})"/>
  <circle cx="{cx+95}" cy="{cy-70}" r="5" fill="#C9792E"/><circle cx="{cx+120}" cy="{cy-40}" r="4" fill="#C9792E"/><circle cx="{cx-130}" cy="{cy-30}" r="4" fill="#C9792E"/>
 </g>
 <path d="{body}" class="ol"/>
 {repulgue(cx,cy,rx+4,ry+4,17,math.radians(176),math.radians(4),21)}
 {'''<g>
  <ellipse cx="200" cy="262" rx="27" ry="31" class="w"/><ellipse cx="312" cy="262" rx="27" ry="31" class="w"/>
  <circle cx="206" cy="268" r="14" class="k"/><circle cx="318" cy="268" r="14" class="k"/>
  <circle cx="211" cy="262" r="5" class="w"/><circle cx="323" cy="262" r="5" class="w"/>
  <ellipse cx="160" cy="312" rx="24" ry="14" fill="#F59AB5" opacity=".85"/><ellipse cx="352" cy="312" rx="24" ry="14" fill="#F59AB5" opacity=".85"/>
  <path d="M 228 305 Q 256 336 284 305" fill="none" stroke="#1E1A17" stroke-width="8" stroke-linecap="round"/>
 </g>''' if face else ''}
 {'''<path d="M 196 92 C 176 72, 216 58, 196 34" class="steam"/><path d="M 256 82 C 236 58, 276 44, 256 18" class="steam"/><path d="M 316 92 C 296 72, 336 58, 316 34" class="steam"/>''' if steam else ''}
</g>
</svg>'''
    return s
open("emp_board.svg","w").write(empanada(True))
open("emp_icon.svg","w").write(empanada(False, face=True, steam=False, grain=False))
