#!/usr/bin/env python3
"""ResetSelf 品牌标记生成器。

单一几何来源：同一份 96x96 栅格上的图形描述，同时输出
  - SVG（矢量、可编辑、可直接进 App / 图标）
  - PNG（主标、单色/反白变体、App 图标各密度）
  - preview.html（对照表：最终主标 + 备选方案）

最终采用：归位环（return-ring）
  - 开口圆环 = 旧循环，走到顶部收住
  - 缺口 = 走出循环
  - 墨色实心点落在环的终点 = 回到原点，从这里重新开始

配色只取项目现有色板：GREEN #819B8E（app_theme 种子色）、INK #2D2D2D、TILE #F7F7F5。
"""

import base64
import math
import os

from PIL import Image, ImageDraw

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
PNG_DIR = os.path.join(OUT_DIR, "png")

GRID = 96.0
CENTER = GRID / 2

GREEN = (129, 155, 142)  # #819B8E
INK = (45, 45, 45)  # #2D2D2D
TILE = (247, 247, 245)  # #F7F7F5
WHITE = (255, 255, 255)

SUPERSAMPLE = 8

BRAND_SLUG = "resetself-mark"


def hexcolor(rgb):
    return "#%02X%02X%02X" % rgb


def pt(r, deg, cx=CENTER, cy=CENTER):
    a = math.radians(deg)
    return (cx + r * math.cos(a), cy + r * math.sin(a))


def arc(cx, cy, r, a0, a1, w, color, opacity=1.0):
    return {
        "type": "arc",
        "cx": cx,
        "cy": cy,
        "r": r,
        "a0": a0,
        "a1": a1,
        "w": w,
        "color": color,
        "opacity": opacity,
    }


def circle(cx, cy, r, w, color, opacity=1.0):
    return {
        "type": "circle",
        "cx": cx,
        "cy": cy,
        "r": r,
        "w": w,
        "color": color,
        "opacity": opacity,
    }


def dot(cx, cy, r, color, opacity=1.0):
    return {
        "type": "dot",
        "cx": cx,
        "cy": cy,
        "r": r,
        "color": color,
        "opacity": opacity,
    }


def recolor(shapes, ring_color, dot_color):
    """按角色换色：最后一个 dot 视为落点。"""
    dot_index = max(i for i, s in enumerate(shapes) if s["type"] == "dot")
    out = []
    for index, shape in enumerate(shapes):
        clone = dict(shape)
        clone["color"] = dot_color if index == dot_index else ring_color
        out.append(clone)
    return out


# ---------------------------------------------------------------- 方案 A 真空环
def mark_vacuum_ring():
    spans = [30, 22, 34, 18, 28, 24, 36, 20, 26, 30]
    gaps = [6, 10, 8, 14, 7, 11, 5, 13, 9, 9]
    shapes = []
    angle = -105.0
    for span, gap in zip(spans, gaps):
        shapes.append(arc(CENTER, CENTER, 35.5, angle, angle + span, 2.6, GREEN, 0.55))
        angle += span + gap
    shapes.append(circle(CENTER, CENTER, 17.5, 4.2, GREEN))
    shapes.append(dot(CENTER, CENTER, 4.6, GREEN))
    return shapes


# ---------------------------------------------------------------- 方案 B 归位环
RING_RADIUS = 30.0
RING_WIDTH = 6.4
GAP_START = -30.0  # 缺口右边界（上右）
GAP_SPAN = 62.0  # 缺口大小
LEG_DOT_RADIUS = 6.5  # 落点半径


def mark_return_ring():
    end = GAP_START - GAP_SPAN  # 顺时针自 GAP_START 起画一周，止于此处（正上方）
    shapes = [arc(CENTER, CENTER, RING_RADIUS, GAP_START, end + 360, RING_WIDTH, GREEN)]
    shapes.append(dot(*pt(RING_RADIUS, GAP_START), r=RING_WIDTH / 2, color=GREEN))
    shapes.append(dot(*pt(RING_RADIUS, end), r=LEG_DOT_RADIUS, color=INK))
    return shapes


# ---------------------------------------------------------------- 方案 C 九点环
def mark_nine_dots():
    shapes = []
    for index in range(9):
        angle = -90.0 + index * 40.0
        x, y = pt(30.5, angle)
        if index == 0:
            shapes.append(dot(x, y, 6.6, INK))
        else:
            shapes.append(dot(x, y, 4.6, GREEN, 0.8))
    return shapes


CONCEPTS = [
    ("vacuum-ring", "真空环", "旧惯性收束成一块安静的内核", mark_vacuum_ring),
    ("nine-dots", "九点环", "9 个真实动作围成一个内核", mark_nine_dots),
]


# ---------------------------------------------------------------------- 渲染
def render_png(shapes, size, background=None):
    canvas = size * SUPERSAMPLE
    unit = canvas / GRID

    base = Image.new(
        "RGBA",
        (canvas, canvas),
        (background[0], background[1], background[2], 255)
        if background
        else (0, 0, 0, 0),
    )

    for shape in shapes:
        mask = Image.new("L", (canvas, canvas), 0)
        draw = ImageDraw.Draw(mask)
        color = shape["color"]

        if shape["type"] == "dot":
            cx, cy, r = shape["cx"] * unit, shape["cy"] * unit, shape["r"] * unit
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)

        elif shape["type"] == "circle":
            r = shape["r"] * unit
            w = shape["w"] * unit
            box_r = r + w / 2
            cx, cy = shape["cx"] * unit, shape["cy"] * unit
            draw.ellipse(
                [cx - box_r, cy - box_r, cx + box_r, cy + box_r],
                outline=255,
                width=max(1, int(round(w))),
            )

        elif shape["type"] == "arc":
            r = shape["r"] * unit
            w = shape["w"] * unit
            box_r = r + w / 2
            cx, cy = shape["cx"] * unit, shape["cy"] * unit
            draw.arc(
                [cx - box_r, cy - box_r, cx + box_r, cy + box_r],
                shape["a0"],
                shape["a1"],
                fill=255,
                width=max(1, int(round(w))),
            )
            for angle in (shape["a0"], shape["a1"]):
                x = cx + r * math.cos(math.radians(angle))
                y = cy + r * math.sin(math.radians(angle))
                draw.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=255)

        opacity = shape["opacity"]
        if opacity < 1.0:
            mask = mask.point(lambda value, o=opacity: int(value * o))

        layer = Image.new("RGBA", (canvas, canvas), (color[0], color[1], color[2], 255))
        base.paste(layer, (0, 0), mask)

    return base.resize((size, size), Image.LANCZOS)


def render_svg(shapes, label="ResetSelf"):
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" '
        'width="96" height="96" role="img" aria-label="%s">' % label
    ]
    for shape in shapes:
        opacity = shape["opacity"]
        attrs = 'stroke="%s" fill="none" stroke-linecap="round"' % hexcolor(shape["color"])
        if opacity < 1.0:
            attrs += ' stroke-opacity="%.2f"' % opacity

        if shape["type"] == "dot":
            parts.append(
                '  <circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s"%s/>'
                % (
                    shape["cx"],
                    shape["cy"],
                    shape["r"],
                    hexcolor(shape["color"]),
                    ' fill-opacity="%.2f"' % opacity if opacity < 1.0 else "",
                )
            )
        elif shape["type"] == "circle":
            parts.append(
                '  <circle cx="%.2f" cy="%.2f" r="%.2f" stroke-width="%.2f" %s/>'
                % (shape["cx"], shape["cy"], shape["r"], shape["w"], attrs)
            )
        elif shape["type"] == "arc":
            x0, y0 = pt(shape["r"], shape["a0"], shape["cx"], shape["cy"])
            x1, y1 = pt(shape["r"], shape["a1"], shape["cx"], shape["cy"])
            large = 1 if abs(shape["a1"] - shape["a0"]) > 180 else 0
            parts.append(
                '  <path d="M %.2f %.2f A %.2f %.2f 0 %d 1 %.2f %.2f" stroke-width="%.2f" %s/>'
                % (x0, y0, shape["r"], shape["r"], large, x1, y1, shape["w"], attrs)
            )
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


# 图形外接半径 / 半画布：用于把标记摆进图标安全区
MARK_BBOX_RATIO = (RING_RADIUS + RING_WIDTH / 2) / CENTER


def render_icon(shapes, size, ratio, background):
    """把标记按给定量占比（外接尺寸 / 画布）居中放进方形图标；背景为 None 时留透明。"""
    mark_size = max(4, int(round(size * ratio / MARK_BBOX_RATIO)))
    mark = render_png(shapes, mark_size)
    fill = (background[0], background[1], background[2], 255) if background else (0, 0, 0, 0)
    tile = Image.new("RGBA", (size, size), fill)
    offset = (size - mark_size) // 2
    tile.paste(mark, (offset, offset), mark)
    return tile


def save_png(image, name):
    path = os.path.join(PNG_DIR, name)
    image.save(path)
    return path


def build_concepts():
    for slug, name, _tagline, builder in CONCEPTS:
        shapes = builder()
        with open(os.path.join(OUT_DIR, "%s.svg" % slug), "w", encoding="utf-8") as handle:
            handle.write(render_svg(shapes))
        for size in (1024, 192, 96, 48):
            save_png(render_png(shapes, size), "%s-%d.png" % (slug, size))
        print("备选 %s -> svg + png" % name)


def build_brand():
    primary = mark_return_ring()
    mono = recolor(primary, GREEN, GREEN)
    inverse = recolor(primary, WHITE, WHITE)

    with open(os.path.join(OUT_DIR, "%s.svg" % BRAND_SLUG), "w", encoding="utf-8") as handle:
        handle.write(render_svg(primary))
    with open(
        os.path.join(OUT_DIR, "%s-mono.svg" % BRAND_SLUG), "w", encoding="utf-8"
    ) as handle:
        handle.write(render_svg(mono))

    for size in (1024, 512, 192, 96, 48, 24):
        save_png(render_png(primary, size), "%s-%d.png" % (BRAND_SLUG, size))
    save_png(render_png(mono, 1024), "%s-mono-1024.png" % BRAND_SLUG)
    save_png(render_png(inverse, 1024), "%s-inverse-1024.png" % BRAND_SLUG)

    # 方形 App 图标（旧版启动器 / 通用方图）：浅底 + 图形占 72%
    for size in (512, 192, 144, 96, 72, 48):
        save_png(render_icon(primary, size, 0.72, TILE), "%s-tile-%d.png" % (BRAND_SLUG, size))

    # 自适应图标前景：108dp 栅格，图形收进 61% 安全区，透明底由启动器着色
    for density, size in (
        ("mdpi", 108),
        ("hdpi", 162),
        ("xhdpi", 216),
        ("xxhdpi", 324),
        ("xxxhdpi", 432),
    ):
        save_png(
            render_icon(primary, size, 0.611, None),
            "%s-foreground-%s.png" % (BRAND_SLUG, density),
        )

    print("主标 %s -> svg + png（1024/512/192/96/48/24）+ mono/inverse + 图标各密度" % BRAND_SLUG)
    return primary


def data_uri(path):
    with open(path, "rb") as handle:
        return "data:image/png;base64," + base64.b64encode(handle.read()).decode()


def write_preview(primary):
    primary_svg = open(os.path.join(OUT_DIR, "%s.svg" % BRAND_SLUG), encoding="utf-8").read()
    lockup_svg = primary_svg.replace('width="96" height="96"', 'width="26" height="26"')
    icon_top = primary_svg.replace('width="96" height="96"', 'width="112" height="112"')

    alternates = []
    for slug, name, tagline, _builder in CONCEPTS:
        svg = open(os.path.join(OUT_DIR, "%s.svg" % slug), encoding="utf-8").read()
        alternates.append(
            """
      <div class="alt">
        <div class="tile mid">{svg}</div>
        <div class="altmeta"><strong>{name}</strong><span>{tagline}</span>
          <code>design/logo/{slug}.svg</code></div>
      </div>""".format(name=name, tagline=tagline, slug=slug, svg=svg)
        )

    html = """<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8"/>
<title>ResetSelf · 归位环</title>
<style>
  :root {{ --green:#819B8E; --ink:#2D2D2D; --tile:#F7F7F5; --line:#E9E9E4; }}
  body {{ margin:0; padding:48px; background:var(--tile); color:var(--ink);
         font:14px/1.6 -apple-system,"Segoe UI","Noto Sans SC",sans-serif; }}
  h1 {{ font-size:20px; letter-spacing:3px; font-weight:600; margin:0 0 6px; }}
  .sub {{ color:#8E8E93; margin-bottom:34px; }}
  .panel {{ background:#fff; border:1px solid var(--line); border-radius:32px;
           padding:30px 34px; margin-bottom:26px; }}
  h2 {{ font-size:15px; font-weight:600; margin:0 0 4px; }}
  .note {{ color:#8E8E93; font-size:12.5px; margin-bottom:22px; }}
  .stage {{ display:flex; align-items:center; gap:30px; flex-wrap:wrap; }}
  .tile {{ display:flex; align-items:center; justify-content:center; background:var(--tile);
          border-radius:24px; }}
  .tile svg {{ display:block; }}
  .big {{ width:150px; height:150px; }} .big svg {{ width:116px; height:116px; }}
  .mid {{ width:84px; height:84px; }} .mid svg {{ width:64px; height:64px; }}
  .small {{ width:60px; height:60px; border-radius:20px; }} .small svg {{ width:46px; height:46px; }}
  .tiny {{ width:38px; height:38px; border-radius:12px; }} .tiny svg {{ width:28px; height:28px; }}
  .dark {{ background:var(--ink); }} .white {{ background:#fff; border:1px solid var(--line); }}
  .lockup {{ background:transparent; flex-direction:row; gap:10px; }}
  .wordmark {{ letter-spacing:2.4px; font-size:13px; color:#2D2D2DCC; font-weight:500; }}
  .legend {{ color:#8E8E93; font-size:12px; }}
  .legend img {{ vertical-align:middle; image-rendering:pixelated; border-radius:10px; }}
  .alt {{ display:flex; gap:20px; align-items:center; }}
  .altmeta {{ display:flex; flex-direction:column; }}
  .altmeta strong {{ font-size:14px; }} .altmeta span {{ color:#8E8E93; font-size:12.5px; }}
  code {{ color:#B4B4B9; font-size:11.5px; }}
  .cols {{ display:flex; gap:34px; flex-wrap:wrap; }}
</style>
</head>
<body>
  <h1>RESETSELF</h1>
  <div class="sub">归位环 · 开口圆环走到顶部收住，墨色落点回到原点 · 配色取自 app_theme 种子色</div>

  <div class="panel">
    <h2>主标</h2>
    <div class="note">矢量源 design/logo/{slug}.svg，PNG 已导出 1024 / 512 / 192 / 96 / 48 / 24</div>
    <div class="stage">
      <div class="tile big">{icon_top}</div>
      <div class="tile mid">{svg}</div>
      <div class="tile small">{svg}</div>
      <div class="tile tiny">{svg}</div>
      <div class="lockup"><span class="wordmark">ResetSelf</span><span>{lockup}</span></div>
    </div>
    <div class="legend" style="margin-top:20px">
      <img alt="" src="{png48}"/> 48px
      <img alt="" src="{png24}" style="margin-left:14px"/> 24px
      &nbsp;（实际像素，未缩放）
    </div>
  </div>

  <div class="panel">
    <h2>变体与 App 图标</h2>
    <div class="note">单色用于受限场景，反白用于深底；方形图标留 72% 图形占比，自适应图标前景收进 61% 安全区</div>
    <div class="stage cols">
      <div class="tile white"><img alt="" src="{mono}" style="width:96px"/></div>
      <div class="tile dark"><img alt="" src="{inverse}" style="width:96px"/></div>
      <div class="tile" style="width:104px;height:104px;border-radius:28px"><img alt="" src="{tile128}" style="width:88px"/></div>
      <div class="legend">单色 &nbsp;·&nbsp; 反白 &nbsp;·&nbsp; 方形图标</div>
    </div>
  </div>

  <div class="panel">
    <h2>备选</h2>
    <div class="note">未采用，文件保留在 design/logo/ 下备查</div>
    <div class="stage cols">{alternates}</div>
  </div>
</body>
</html>
""".format(
        slug=BRAND_SLUG,
        icon_top=icon_top,
        svg=primary_svg.replace('width="96" height="96"', 'width="64" height="64"'),
        lockup=lockup_svg,
        png48=data_uri(os.path.join(PNG_DIR, "%s-48.png" % BRAND_SLUG)),
        png24=data_uri(os.path.join(PNG_DIR, "%s-24.png" % BRAND_SLUG)),
        mono=data_uri(os.path.join(PNG_DIR, "%s-mono-1024.png" % BRAND_SLUG)),
        inverse=data_uri(os.path.join(PNG_DIR, "%s-inverse-1024.png" % BRAND_SLUG)),
        tile128=data_uri(os.path.join(PNG_DIR, "%s-tile-512.png" % BRAND_SLUG)),
        alternates="\n".join(alternates),
    )
    with open(os.path.join(OUT_DIR, "preview.html"), "w", encoding="utf-8") as handle:
        handle.write(html)
    print("preview.html 生成完成")


def main():
    os.makedirs(PNG_DIR, exist_ok=True)
    build_concepts()
    primary = build_brand()
    write_preview(primary)


if __name__ == "__main__":
    main()
