"""c64kit/tools/asset_converter.py

CLI tool and library to convert images to C64 format (charset, sprite, tilemap).
Includes Floyd-Steinberg dithering and duplicate character deduplication.
"""

import argparse
import os
import numpy as np
from PIL import Image
from typing import List, Tuple, Dict, Any, Optional

__all__ = [
    "C64_PALETTE",
    "get_closest_color",
    "dither_image",
    "convert_to_charset",
    "convert_to_sprites",
    "generate_html_preview",
    "export_data",
]

# Standard C64 Palette
C64_PALETTE: Dict[int, Tuple[int, int, int]] = {
    0: (0, 0, 0),          # BLACK
    1: (255, 255, 255),    # WHITE
    2: (136, 0, 0),        # RED
    3: (170, 255, 238),    # CYAN
    4: (204, 68, 204),     # PURPLE
    5: (0, 204, 85),       # GREEN
    6: (0, 0, 170),        # BLUE
    7: (238, 238, 119),    # YELLOW
    8: (221, 136, 85),     # ORANGE
    9: (102, 68, 0),       # BROWN
    10: (255, 119, 119),   # LIGHT_RED
    11: (51, 51, 51),      # DARK_GREY
    12: (119, 119, 119),   # GREY
    13: (170, 255, 102),   # LIGHT_GREEN
    14: (0, 136, 255),     # LIGHT_BLUE
    15: (221, 221, 221),   # LIGHT_GREY
}


def get_closest_color(rgb: Tuple[float, float, float], palette: Dict[int, Tuple[int, int, int]] = C64_PALETTE) -> int:
    """Finds the closest C64 palette index for a given RGB color.

    Args:
        rgb: The RGB color tuple to match.
        palette: The dictionary mapping C64 color index to RGB tuple.

    Returns:
        The matched C64 color index.
    """
    min_dist = float('inf')
    best_index = 0
    r, g, b = rgb
    for index, col in palette.items():
        dist = (r - col[0])**2 + (g - col[1])**2 + (b - col[2])**2
        if dist < min_dist:
            min_dist = dist
            best_index = index
    return best_index


def dither_image(image: Image.Image, palette: Dict[int, Tuple[int, int, int]] = C64_PALETTE) -> Tuple[np.ndarray, np.ndarray]:
    """Applies Floyd-Steinberg dithering to map an image to the C64 palette.

    Args:
        image: PIL Image in RGB format.
        palette: C64 palette mapping.

    Returns:
        A tuple of (color_indexed_array, rgb_array).
    """
    img_rgb = image.convert('RGB')
    width, height = img_rgb.size
    pixels = np.array(img_rgb, dtype=np.float32)
    indexed = np.zeros((height, width), dtype=np.uint8)

    for y in range(height):
        for x in range(width):
            old_px = pixels[y, x].copy()
            best_idx = get_closest_color(tuple(old_px), palette)
            indexed[y, x] = best_idx
            new_px = np.array(palette[best_idx], dtype=np.float32)
            pixels[y, x] = new_px

            err = old_px - new_px

            if x + 1 < width:
                pixels[y, x + 1] = np.clip(pixels[y, x + 1] + err * 7.0 / 16.0, 0, 255)
            if y + 1 < height:
                if x - 1 >= 0:
                    pixels[y + 1, x - 1] = np.clip(pixels[y + 1, x - 1] + err * 3.0 / 16.0, 0, 255)
                pixels[y + 1, x] = np.clip(pixels[y + 1, x] + err * 5.0 / 16.0, 0, 255)
                if x + 1 < width:
                    pixels[y + 1, x + 1] = np.clip(pixels[y + 1, x + 1] + err * 1.0 / 16.0, 0, 255)

    rgb_out = np.clip(pixels, 0, 255).astype(np.uint8)
    return indexed, rgb_out


def convert_to_charset(indexed_img: np.ndarray, bg_color: int = 0) -> Tuple[List[bytes], List[int], Dict[str, Any]]:
    """Converts a C64 indexed image to an optimized (deduplicated) 8x8 charset and tilemap.

    Args:
        indexed_img: 2D numpy array of C64 color indexes (0-15).
        bg_color: The color index to be treated as background (becomes bit 0).

    Returns:
        A tuple containing:
          - A list of unique character data (each 8 bytes).
          - A list of character indexes for each 8x8 block in reading order (tilemap).
          - A dictionary with statistics/metadata.
    """
    height, width = indexed_img.shape
    rows = height // 8
    cols = width // 8

    unique_chars: List[bytes] = []
    char_to_id: Dict[bytes, int] = {}
    tilemap: List[int] = []
    char_counts: Dict[int, int] = {}

    for r in range(rows):
        for c in range(cols):
            # Extract 8x8 block
            block = indexed_img[r*8:(r+1)*8, c*8:(c+1)*8]
            char_bytes = []
            for y in range(8):
                byte_val = 0
                for x in range(8):
                    pixel = block[y, x]
                    bit = 0 if pixel == bg_color else 1
                    byte_val = (byte_val << 1) | bit
                char_bytes.append(byte_val)

            char_data = bytes(char_bytes)

            if char_data not in char_to_id:
                char_id = len(unique_chars)
                unique_chars.append(char_data)
                char_to_id[char_data] = char_id
            else:
                char_id = char_to_id[char_data]

            tilemap.append(char_id)
            char_counts[char_id] = char_counts.get(char_id, 0) + 1

    # Frequency ordering metadata
    sorted_by_freq = sorted(char_counts.items(), key=lambda x: x[1], reverse=True)

    metadata = {
        "original_blocks": rows * cols,
        "unique_characters": len(unique_chars),
        "saving_ratio": 1.0 - (len(unique_chars) / (rows * cols)) if (rows * cols) > 0 else 0.0,
        "frequency": sorted_by_freq,
    }

    return unique_chars, tilemap, metadata


def convert_to_sprites(indexed_img: np.ndarray, sprite_color: int = 1) -> List[bytes]:
    """Converts a C64 indexed image to 24x21 hardware sprites.

    Each sprite is 63 bytes (24x21 bits) + 1 byte padding = 64 bytes total.

    Args:
        indexed_img: 2D numpy array of C64 color indexes (0-15).
        sprite_color: Color index representing sprite foreground (bit 1).

    Returns:
        List of 64-byte sprite binary strings.
    """
    height, width = indexed_img.shape
    rows = height // 21
    cols = width // 24

    sprites: List[bytes] = []

    for r in range(rows):
        for c in range(cols):
            block = indexed_img[r*21:(r+1)*21, c*24:(c+1)*24]
            sprite_bytes = []
            for y in range(21):
                # 24 pixels = 3 bytes
                for b_idx in range(3):
                    byte_val = 0
                    for x in range(8):
                        pixel = block[y, b_idx*8 + x]
                        bit = 1 if pixel == sprite_color else 0
                        byte_val = (byte_val << 1) | bit
                    sprite_bytes.append(byte_val)
            # Add 1 byte of padding for 64-byte alignment
            sprite_bytes.append(0)
            sprites.append(bytes(sprite_bytes))

    return sprites


def generate_html_preview(indexed_img: np.ndarray, output_path: str) -> None:
    """Generates an HTML preview representing the dithered/indexed image with real C64 colors.

    Args:
        indexed_img: 2D numpy array of C64 color indexes.
        output_path: File path where HTML preview will be saved.
    """
    height, width = indexed_img.shape
    zoom = 4

    html_parts = [
        "<!DOCTYPE html>",
        "<html>",
        "<head>",
        "  <title>C64 Asset Preview</title>",
        "  <style>",
        "    body { background: #1a1a1a; color: #e0e0e0; font-family: monospace; text-align: center; margin: 20px; }",
        "    h1 { color: #00cc55; }",
        "    .preview-container { margin: 20px auto; display: inline-block; border: 4px solid #fff; box-shadow: 0 0 15px rgba(0,0,0,0.5); }",
        "    svg { display: block; }",
        "  </style>",
        "</head>",
        "<body>",
        "  <h1>C64 Asset Preview</h1>",
        f"  <p>Resolution: {width}x{height} (Zoom: {zoom}x)</p>",
        '  <div class="preview-container">',
        f'    <svg width="{width * zoom}" height="{height * zoom}" viewBox="0 0 {width} {height}" shape-rendering="crispEdges">'
    ]

    # Group pixels to optimize SVG size
    for y in range(height):
        x = 0
        while x < width:
            color_idx = indexed_img[y, x]
            # Run-length encoding of identical pixel colors on same row
            length = 1
            while x + length < width and indexed_img[y, x + length] == color_idx:
                length += 1

            r, g, b = C64_PALETTE[color_idx]
            hex_color = f"#{r:02x}{g:02x}{b:02x}"
            html_parts.append(f'      <rect x="{x}" y="{y}" width="{length}" height="1" fill="{hex_color}" />')
            x += length

    html_parts.extend([
        "    </svg>",
        "  </div>",
        "</body>",
        "</html>"
    ])

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(html_parts))


def export_data(data: List[bytes], format_type: str, label: str = "asset_data") -> str:
    """Exports binary data list to assembly, raw binary, or C header.

    Args:
        data: List of bytes components.
        format_type: Output format 'asm', 'bin', or 'c'.
        label: Prefix name for assembly labels or C variables.

    Returns:
        The formatted string content (or hex dump string).
    """
    if format_type == "bin":
        return b"".join(data).decode("latin-1")  # raw binary returned

    elif format_type == "c":
        all_bytes = b"".join(data)
        lines = []
        lines.append(f"// Generated C64 Asset: {label}")
        lines.append(f"const unsigned char {label}[] = {{")
        chunk_size = 16
        for i in range(0, len(all_bytes), chunk_size):
            chunk = all_bytes[i:i+chunk_size]
            hex_str = ", ".join(f"0x{b:02x}" for b in chunk)
            comma = "," if i + chunk_size < len(all_bytes) else ""
            lines.append(f"    {hex_str}{comma}")
        lines.append("};")
        lines.append(f"const unsigned int {label}_len = {len(all_bytes)};")
        return "\n".join(lines)

    else:  # 'asm' format
        lines = []
        lines.append(f"; Generated C64 Asset: {label}")
        lines.append(f"{label}:")
        for chunk in data:
            # Output in groups of 8 bytes for readability
            for i in range(0, len(chunk), 8):
                subchunk = chunk[i:i+8]
                bytes_str = ", ".join(f"${b:02x}" for b in subchunk)
                lines.append(f"    .byte {bytes_str}")
        return "\n".join(lines)


def main() -> None:
    """Main execution function for CLI usage."""
    parser = argparse.ArgumentParser(description="Convert images to C64 format (charset, sprite, tilemap).")
    parser.add_argument("--input", required=True, help="Input image filepath (PNG/JPG)")
    parser.add_argument("--output", required=True, help="Output output filepath")
    parser.add_argument("--format", default="asm", choices=["asm", "bin", "c"], help="Output format type")
    parser.add_argument("--mode", default="charset", choices=["charset", "sprite", "tilemap"], help="Conversion mode")
    parser.add_argument("--bg-color", type=int, default=0, help="Background color index for charset mode (0-15)")
    parser.add_argument("--sprite-color", type=int, default=1, help="Foreground color index for sprite mode (0-15)")
    parser.add_argument("--preview", help="Optional output filepath for HTML preview")

    args = parser.parse_value = parser.parse_args() if hasattr(parser, "parse_value") else parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' does not exist.")
        return

    try:
        img = Image.open(args.input)
    except Exception as e:
        print(f"Error: Could not open image. {e}")
        return

    # Process and dither
    indexed, _ = dither_image(img)

    # Optional HTML preview
    if args.preview:
        generate_html_preview(indexed, args.preview)

    label = os.path.splitext(os.path.basename(args.output))[0]

    if args.mode == "charset":
        chars, _, _ = convert_to_charset(indexed, bg_color=args.bg_color)
        out_content = export_data(chars, args.format, label=label)
    elif args.mode == "sprite":
        sprites = convert_to_sprites(indexed, sprite_color=args.sprite_color)
        out_content = export_data(sprites, args.format, label=label)
    else:  # tilemap
        chars, tilemap, _ = convert_to_charset(indexed, bg_color=args.bg_color)
        tilemap_bytes = bytes(tilemap)
        if args.format == "bin":
            out_content = (b"".join(chars) + tilemap_bytes).decode("latin-1")
        elif args.format == "c":
            char_c = export_data(chars, "c", label=f"{label}_chars")
            tilemap_c = export_data([tilemap_bytes], "c", label=f"{label}_map")
            out_content = f"{char_c}\n\n{tilemap_c}"
        else:
            char_asm = export_data(chars, "asm", label=f"{label}_chars")
            tilemap_asm = export_data([tilemap_bytes], "asm", label=f"{label}_map")
            out_content = f"{char_asm}\n\n{tilemap_asm}"

    # Write output
    if args.format == "bin":
        with open(args.output, "wb") as f:
            f.write(out_content.encode("latin-1"))
    else:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(out_content)

    print(f"Successfully converted '{args.input}' to '{args.output}' in {args.mode} mode ({args.format}).")


if __name__ == "__main__":
    main()
