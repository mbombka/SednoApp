"""Convert the supplied Sedno artwork into deterministic Android resources."""
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "mobile/android/app/src/main/res"
SVG = ROOT / "docs/Content/sedno-icon.svg"
PNG = ROOT / "docs/Content/sedno-icon-A-512.png"
NS = "{http://www.w3.org/2000/svg}"


def main():
    source = Image.open(PNG).convert("RGBA")
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        target = RES / f"mipmap-{density}/ic_launcher.png"
        source.resize((size, size), Image.Resampling.LANCZOS).save(target)

    artwork = ET.parse(SVG).getroot().find(f"{NS}g")
    paths = []
    for shape in artwork:
        if shape.tag == f"{NS}path":
            paths.append(shape.attrib["d"])
        elif shape.tag == f"{NS}circle":
            cx, cy, radius = (float(shape.attrib[k]) for k in ("cx", "cy", "r"))
            paths.append(f"M{cx-radius},{cy} a{radius},{radius} 0,1 0,{2*radius},0 a{radius},{radius} 0,1 0,{-2*radius},0")
        else:
            raise ValueError("Unsupported vector shape")
    mark = "\n".join(f'        <path android:fillColor="#FFFFFF" android:pathData="{path}" />' for path in paths)
    header = '<?xml version="1.0" encoding="utf-8"?>\n<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
    # Keep the mark inside the adaptive icon's circular safe zone.
    foreground = header + '    android:width="108dp" android:height="108dp" android:viewportWidth="1254" android:viewportHeight="1254">\n'
    foreground += '    <group android:translateX="100.32" android:translateY="100.32" android:scaleX="0.84" android:scaleY="0.84">\n' + mark + '\n    </group>\n</vector>\n'
    (RES / "drawable/ic_launcher_foreground.xml").write_text(foreground)
    splash = header + '    android:width="288dp" android:height="288dp" android:viewportWidth="1881" android:viewportHeight="1881">\n'
    splash += '    <group android:translateX="313.5" android:translateY="313.5">\n'
    splash += '        <path android:fillColor="@color/sedno_blue" android:pathData="M627,0 A627,627 0,1 1,627,1254 A627,627 0,1 1,627,0 Z" />\n'
    splash += mark + '\n    </group>\n</vector>\n'
    (RES / "drawable/ic_sedno_splash.xml").write_text(splash)


if __name__ == "__main__":
    main()
