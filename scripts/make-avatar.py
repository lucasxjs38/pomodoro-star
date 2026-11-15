#!/usr/bin/env python3
"""生成圆形头像：从方形图标裁出正圆，四角透明，适配 GitHub 圆形头像。"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SRC = Path("/Users/wenxinxiaowo/.openclaw/workspace/PomodoroStar/icon/icon-1024.png")
OUT = Path("/Users/wenxinxiaowo/.openclaw/workspace/PomodoroStar/icon/avatar-round-512.png")

SIZE = 512
SS = 4  # 超采样倍数，边缘更平滑


def main() -> int:
    if not SRC.exists():
        print(f"缺少源图: {SRC}", file=sys.stderr)
        return 1

    base = Image.open(SRC).convert("RGBA")

    # 让番茄略微缩小，留出安全边距，避免圆形裁切贴边
    inner = int(SIZE * SS * 0.92)
    scaled = base.resize((inner, inner), Image.LANCZOS)

    canvas = Image.new("RGBA", (SIZE * SS, SIZE * SS), (0, 0, 0, 0))
    offset = ((SIZE * SS - inner) // 2, (SIZE * SS - inner) // 2)
    canvas.paste(scaled, offset)

    mask = Image.new("L", (SIZE * SS, SIZE * SS), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, SIZE * SS - 1, SIZE * SS - 1), fill=255)
    canvas.putalpha(mask)

    final = canvas.resize((SIZE, SIZE), Image.LANCZOS)
    final.save(OUT, "PNG", optimize=True)
    print(f"已生成: {OUT}")
    print(f"大小: {OUT.stat().st_size} 字节")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
