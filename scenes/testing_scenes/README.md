# Tesseract 4D Demo

## Overview

This demo scene shows a tesseract (4D hypercube) rotating in 4D space using vertex color encoding for the W coordinate.

## Files

- **tesseract_4d_demo.tscn** - The demo scene
- **tesseract_4d_controller.gd** - Script that handles rotation and shader setup
- Uses **tesseract_red_test_5.glb** - Tesseract mesh with W coordinates encoded in vertex colors

## How It Works

### Vertex Color Encoding

The tesseract mesh has 72 vertices with colors encoding the 4th dimension:
- **Black vertices** (R=0.0) → W = -1.0 (inner cube)
- **Red vertices** (R=1.0) → W = +1.0 (outer cube)

### Shader Processing

The 4D projection shader ([4d_projection.gdshader](../../shaders/4d_projection.gdshader)) reads:
```glsl
vec4 pos_4d = vec4(VERTEX.xyz, COLOR.r * 2.0 - 1.0);
```

This reconstructs the full 4D position and applies 4D rotations in 6 planes:
- **XW, YW, ZW** - 4D rotations (into/out of the W dimension)
- **XY, XZ, YZ** - Standard 3D rotations

## Controls

### Auto-Rotation
- **SPACE** - Toggle auto-rotation on/off
- **R** - Reset all rotations to 0

### Manual 4D Rotations
- **W/S** - Rotate in XW plane (spin around X-axis into W)
- **A/D** - Rotate in YW plane (spin around Y-axis into W)
- **Q/E** - Rotate in ZW plane (spin around Z-axis into W)

### Manual 3D Rotations
- **Arrow Up/Down** - Rotate in XZ plane
- **Arrow Left/Right** - Rotate in XY plane

## What to Observe

When rotating in 4D (XW, YW, ZW planes), you'll see:
- **Vertices changing color** as they rotate through the W dimension
- **Inner and outer cubes** swapping positions
- **Edges appearing and disappearing** as they rotate through 4D space
- **Perspective distortion** based on W coordinate (similar to 3D perspective but in 4D)

The shader applies perspective projection in 4D:
```glsl
float w_factor = projection_distance / (projection_distance + w_offset);
return vec3(p.x * w_factor, p.y * w_factor, p.z * w_factor);
```

This makes vertices with larger W coordinates appear smaller (further away in 4D).

## Troubleshooting

If the tesseract appears all one color:
1. Check that vertex colors were properly exported from Blender
2. Verify the shader is applied (check material_override)
3. Run the diagnostic: [check_tesseract_colors.gd](../../check_tesseract_colors.gd)

Expected vertex colors:
- Should have both R=0.0 (black) and R=1.0 (red) vertices
- Approximately 50% of vertices at each W value
- Total of 72 vertices (16 logical corners, duplicated for faces)

## Technical Details

**Mesh Structure:**
- 16 logical vertices (4D hypercube corners)
- 72 mesh vertices (triangulated with duplicates)
- 24 triangulated faces

**4D Rotations:**
- Each frame applies 6 rotation matrices
- Order: XY → XZ → YZ → XW → YW → ZW
- All rotations preserve the tesseract structure

**Performance:**
- All rotations done in vertex shader (GPU)
- ~72 vertices processed per frame
- Negligible performance impact
