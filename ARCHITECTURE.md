# Hyperulottoukkavuus - 4D Puzzle Game Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GAME WORLD 4D                               │
│                    (Global Singleton/Autoload)                      │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│  │ DimensionManager │  │ CollisionManager │  │   LevelManager   │ │
│  │      4D          │  │       4D         │  │                  │ │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
        ┌───────────────┐ ┌──────────────┐ ┌──────────────┐
        │   Player4D    │ │  Object4D    │ │Camera4DFollow│
        │  (extends     │ │ (base class) │ │              │
        │   Object4D)   │ │              │ │              │
        └───────────────┘ └──────────────┘ └──────────────┘
```

## Core Systems Architecture

### 1. Dimension & Slicing System

```
┌─────────────────────────────────────────────────────────────────┐
│                    DIMENSION MANAGER 4D                         │
│                  scripts/4d/dimension_manager_4d.gd             │
├─────────────────────────────────────────────────────────────────┤
│ Responsibilities:                                               │
│ • Manages current dimension (1D → 2D → 3D → 4D)               │
│ • Creates slice hyperplanes for each dimension                 │
│ • Handles manual slice rotation (Z/X keys in 1D/2D)           │
│ • Coordinates with camera for slice orientation                │
│                                                                 │
│ Key Properties:                                                │
│ • current_dimension: int (1-4)                                 │
│ • slice_hyperplane: HyperplaneND                              │
│ • slice_rotation_angle: float (for 1D/2D)                     │
│ • slice_thickness: float (8.0 units)                          │
│ • use_geometric_slicing: bool (true)                          │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │        HYPERPLANE ND                  │
        │   scripts/4d/hyperplane_nd.gd        │
        ├──────────────────────────────────────┤
        │ Mathematical representation of        │
        │ N-dimensional hyperplanes             │
        │                                       │
        │ • normal: Vector4                     │
        │ • point: Vector4                      │
        │ • dimension: int                      │
        │                                       │
        │ Methods:                              │
        │ • signed_distance(point)              │
        │ • is_point_on_plane(point)           │
        │ • rotate_around_y(angle)             │
        └──────────────────────────────────────┘
```

### 2. Object & Physics System

```
┌─────────────────────────────────────────────────────────────────┐
│                         OBJECT 4D                               │
│                   scripts/4d/object_4d.gd                       │
├─────────────────────────────────────────────────────────────────┤
│ Base class for all 4D objects                                  │
│                                                                 │
│ Core Properties:                                               │
│ • position_4d: Vector4 (XYZW position)                        │
│ • velocity_4d: Vector4 (XYZW velocity)                        │
│ • collision_radius_4d: float                                   │
│ • mesh_instance: MeshInstance3D (visual)                      │
│                                                                 │
│ Dimension Locking:                                            │
│ • lock_position_to_1d() - Constrains to line                  │
│ • lock_position_to_2d() - Constrains to plane                 │
│ • lock_position_to_3d() - Preserves W position                │
│                                                                 │
│ Visibility:                                                    │
│ • Culled when outside current slice                           │
│ • Player always visible                                        │
└─────────────────────────────────────────────────────────────────┘
                           │
                           │ extends
                           ▼
        ┌──────────────────────────────────────┐
        │           PLAYER 4D                   │
        │      scripts/player.gd                │
        ├──────────────────────────────────────┤
        │ Player-specific behavior              │
        │                                       │
        │ • Movement input handling             │
        │ • Dimension switching (mouse clicks) │
        │ • Slice rotation (Z/X keys)          │
        │ • Jump mechanics                      │
        │ • Gravity application                 │
        └──────────────────────────────────────┘
```

### 3. Collision System

```
┌─────────────────────────────────────────────────────────────────┐
│                    COLLISION MANAGER 4D                         │
│               scripts/4d/collision_manager_4d.gd                │
├─────────────────────────────────────────────────────────────────┤
│ Handles all 4D collision detection and response                │
│                                                                 │
│ Collision Types:                                               │
│ 1. Hypersphere-Hypersphere (object-object)                    │
│    • Distance-based in N dimensions                            │
│    • Dimension-aware (1D/2D/3D/4D modes)                      │
│                                                                 │
│ 2. Hypersphere-Hyperplane (object-floor/wall)                │
│    • Uses CollisionPlane4D instances                          │
│    • Generic bounce/slide physics                             │
│    • Ground detection (Y-axis normals)                        │
│                                                                 │
│ Slice Filtering:                                              │
│ • is_object_in_slice_geometric()                              │
│ • Only collide with objects in current slice                  │
│ • Uses GeometricIntersection utilities                        │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ├────────────────┐
                           ▼                ▼
        ┌─────────────────────────┐  ┌──────────────────────┐
        │ GeometricIntersection   │  │  CollisionPlane4D    │
        │ scripts/4d/geometric_   │  │  (InfiniteFloor4D)   │
        │    intersection.gd      │  │  scripts/4d/         │
        ├─────────────────────────┤  │  infinite_floor_4d.gd│
        │ Intersection tests:     │  ├──────────────────────┤
        │                         │  │ Infinite planes in   │
        │ • Line-hyperplane       │  │ 4D space             │
        │ • Sphere-hyperplane     │  │                      │
        │ • AABB-hyperplane       │  │ Properties:          │
        │                         │  │ • plane_normal: Vec4 │
        │ Returns:                │  │ • position_4d: Vec4  │
        │ • Intersection point    │  │ • visual_size: float │
        │ • Boolean result        │  │                      │
        │ • Distance/t-value      │  │ Hybrid Rendering:    │
        └─────────────────────────┘  │ • Threshold regen    │
                                     │ • Grid snapping      │
                                     │ • W coord fixing     │
                                     └──────────────────────┘
```

### 4. Camera & Rendering System

```
┌─────────────────────────────────────────────────────────────────┐
│                      CAMERA 4D FOLLOW                           │
│                scripts/4d/camera_4d_follow.gd                   │
├─────────────────────────────────────────────────────────────────┤
│ Dimension-aware camera system                                  │
│                                                                 │
│ 4D/3D Mode (Perspective):                                      │
│ • Mouse-look enabled (yaw/pitch)                               │
│ • PROJECTION_PERSPECTIVE                                       │
│ • FOV 75°                                                      │
│ • Smooth follow with offset                                    │
│                                                                 │
│ 2D/1D Mode (Orthogonal):                                       │
│ • Mouse-look DISABLED                                          │
│ • PROJECTION_ORTHOGONAL                                        │
│ • Fixed side/top view                                          │
│ • Camera locked, slice rotates instead                         │
│                                                                 │
│ Key Properties:                                                │
│ • yaw, pitch: float                                            │
│ • follow_speed, offset_distance: float                         │
│ • mouse_captured: bool                                         │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │      4D PROJECTION SHADER             │
        │   shaders/4d_projection.gdshader     │
        ├──────────────────────────────────────┤
        │ Vertex shader for 4D rotations       │
        │                                       │
        │ Inputs:                               │
        │ • VERTEX (XYZ)                        │
        │ • COLOR.r (W coordinate, normalized) │
        │ • Rotation angles (6 planes)         │
        │                                       │
        │ 4D Rotation Planes:                   │
        │ • XW, YW, ZW (4D rotations)          │
        │ • XY, XZ, YZ (3D rotations)          │
        │                                       │
        │ Output:                               │
        │ • Rotated VERTEX (XYZ)               │
        │ • COLOR (W-based visualization)      │
        └──────────────────────────────────────┘
```

### 5. UI & Debug System

```
┌─────────────────────────────────────────────────────────────────┐
│                          LEVEL UI                               │
│                    scripts/level_ui.gd                          │
├─────────────────────────────────────────────────────────────────┤
│ Real-time player information display                           │
│                                                                 │
│ Displays:                                                      │
│ • XYZW position (updated every frame)                         │
│ • Current dimension                                            │
│ • Slice information                                            │
│                                                                 │
│ Format: "Position: X: %.2f Y: %.2f Z: %.2f W: %.2f"          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  SLICE PLANE VISUALIZER                         │
│              scripts/4d/slice_plane_visualizer.gd               │
├─────────────────────────────────────────────────────────────────┤
│ Visual representation of current slice                         │
│                                                                 │
│ Dimension-aware meshes:                                        │
│ • 3D mode: BoxMesh (3D volume slice)                          │
│ • 2D mode: QuadMesh (2D plane slice)                          │
│ • 1D mode: CylinderMesh (thick line)                          │
│ • 4D mode: Hidden (no slicing)                                │
│                                                                 │
│ Properties:                                                    │
│ • Semi-transparent cyan material                               │
│ • Rotates with slice orientation                              │
│ • Updates dynamically                                          │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Dimension Switching Flow

```
Player Input (Mouse Click)
        │
        ▼
┌───────────────────┐
│   Player4D        │
│   _input()        │
└───────────────────┘
        │
        ▼
┌───────────────────────────────────┐
│ DimensionManager4D                │
│ set_dimension(dim, camera, pos)   │
└───────────────────────────────────┘
        │
        ├─────────────┬──────────────┬──────────────┐
        ▼             ▼              ▼              ▼
┌──────────────┐ ┌─────────┐ ┌──────────────┐ ┌────────────┐
│ Initialize   │ │ Create  │ │ Update       │ │ Notify     │
│ slice        │ │ hyper-  │ │ camera       │ │ all        │
│ rotation     │ │ plane   │ │ projection   │ │ Object4D   │
│ angle        │ │         │ │              │ │ instances  │
└──────────────┘ └─────────┘ └──────────────┘ └────────────┘
        │             │              │              │
        └─────────────┴──────────────┴──────────────┘
                           │
                           ▼
                ┌──────────────────┐
                │ All objects lock │
                │ positions to     │
                │ new dimension    │
                └──────────────────┘
```

### Collision Detection Flow (Every Frame)

```
┌─────────────────────────────────────────────────────────────┐
│                    _physics_process()                       │
│                  (Called on Object4D)                       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│         CollisionManager4D.check_collisions(obj)            │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────────┐
│ Check plane   │  │ Check if in  │  │ Check object-    │
│ collisions    │  │ current      │  │ object           │
│ (floors/      │  │ slice        │  │ collisions       │
│  walls)       │  │ (geometric)  │  │ (hypersphere)    │
└───────────────┘  └──────────────┘  └──────────────────┘
        │                  │                  │
        │                  │ (filters)        │
        │                  └──────────────────┤
        │                                     │
        ▼                                     ▼
┌───────────────┐                    ┌──────────────┐
│ Apply bounce/ │                    │ Apply        │
│ slide physics │                    │ collision    │
│ Set grounded  │                    │ response     │
└───────────────┘                    └──────────────┘
```

### Slice Rotation Flow (1D/2D Only)

```
Player holds Z or X key
        │
        ▼
┌───────────────────────────────┐
│ Player4D                      │
│ handle_slice_rotation(delta)  │
└───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ DimensionManager4D                    │
│ slice_rotation_angle += delta * 1.5   │
└───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ DimensionManager4D                    │
│ update_slice_hyperplane()             │
└───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ HyperplaneND                          │
│ • Recalculate normal from angle       │
│ • Update slice visualization          │
│ • Trigger visibility/collision update │
└───────────────────────────────────────┘
```

### Infinite Floor Rendering Flow (Hybrid Approach)

```
┌─────────────────────────────────────────────────────────────┐
│         InfiniteFloor4D._process() - Every Frame            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │ Project player pos onto plane        │
        │ Check movement thresholds:           │
        │ • Player moved > 50 units?           │
        │ • Plane moved > 50 units?            │
        │ • Plane rotated?                     │
        └──────────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        ▼                                     ▼
┌──────────────────┐              ┌──────────────────────┐
│ YES: REGENERATE  │              │ NO: GRID SNAPPING    │
├──────────────────┤              ├──────────────────────┤
│ 1. Update        │              │ 1. Calculate offset  │
│    position_4d   │              │    from position_4d  │
│ 2. Call generate_│              │ 2. Snap to 2.0 grid │
│    hyperplane_   │              │ 3. Move mesh         │
│    mesh()        │              │    transform only    │
│ 3. Reset mesh    │              │                      │
│    position to   │              │ (Fast, no regen)     │
│    Vector3.ZERO  │              │                      │
│ 4. Update        │              └──────────────────────┘
│    tracking vars │
│                  │
│ (Slow, 1-5x/sec) │
└──────────────────┘

Result: ✅ No flickering (W coords always match XYZ)
        ✅ Good performance (minimal regenerations)
```

## Key Architectural Patterns

### 1. **Singleton Pattern**
```
GameWorld4D (Autoload)
├── DimensionManager4D (single instance)
├── CollisionManager4D (single instance)
└── LevelManager (single instance)
```

### 2. **Component-Based Architecture**
```
Object4D (Base)
├── position_4d, velocity_4d (data)
├── collision_radius_4d (physics)
├── mesh_instance (rendering)
└── Extensible via inheritance
```

### 3. **Event-Driven Updates**
```
Dimension Change
├── Triggers: set_dimension()
├── Notifies: All Object4D instances
└── Updates: Camera, Hyperplane, Locks
```

### 4. **Hybrid Optimization**
```
Infinite Floor
├── Threshold-based regeneration (expensive)
└── Grid snapping (cheap, between regenerations)
```

## File Structure

```
Hyperulottoukkavuus/
├── scripts/
│   ├── 4d/
│   │   ├── camera_4d_follow.gd          # Camera system
│   │   ├── collision_manager_4d.gd      # Collision detection
│   │   ├── dimension_manager_4d.gd      # Dimension/slicing
│   │   ├── geometric_intersection.gd    # Intersection math
│   │   ├── hyperplane_nd.gd             # Hyperplane math
│   │   ├── infinite_floor_4d.gd         # Infinite planes
│   │   ├── object_4d.gd                 # Base 4D object
│   │   └── slice_plane_visualizer.gd    # Debug visualization
│   ├── slicing/ (Phase 4 - not integrated)
│   │   ├── edge_slicer.gd               # Edge intersection
│   │   ├── mesh_slicer.gd               # Mesh slicing
│   │   └── dynamic_slice_mesh.gd        # Renderable meshes
│   ├── player.gd                         # Player controller
│   ├── level_manager.gd                  # Level control
│   └── level_ui.gd                       # UI display
├── shaders/
│   └── 4d_projection.gdshader            # 4D rotation shader
├── scenes/
│   ├── main.tscn                         # Main scene
│   ├── level2.tscn                       # Level 2
│   ├── level_ui.tscn                     # UI scene
│   └── slice_plane_visualizer.tscn      # Debug viz
├── tests/
│   ├── test_hyperplane.gd                # Hyperplane tests
│   ├── test_slice_intersection.gd       # Intersection tests
│   ├── test_edge_slicer.gd              # Edge slicer tests
│   └── test_mesh_slicing.gd             # Mesh slicing tests
└── LLM_CONTEXT.md                        # Implementation log
```

## Critical Design Decisions

### 1. **Dimension-Specific Hyperplane Normals**
- **4D→3D**: Pure W-axis normal `(0,0,0,1)` - shows all at same W
- **3D→2D**: Y-axis rotation only `(sin θ, 0, cos θ, 0)` - preserves gravity
- **2D→1D**: Same as 3D→2D - consistent rotation model

### 2. **Camera Behavior by Dimension**
- **4D/3D**: Mouse-look enabled, perspective projection
- **2D/1D**: Mouse-look disabled, orthogonal projection, manual slice rotation

### 3. **W Position Preservation**
- When entering 3D from 4D, W is stored (not zeroed)
- Allows objects to exist at any W coordinate
- Critical for multi-layer 4D puzzles

### 4. **Collision Filtering**
- Objects outside current slice are invisible AND non-collidable
- Uses geometric intersection tests, not simple distance checks
- Player always visible regardless of slice

### 5. **Infinite Floor Hybrid Rendering**
- **Problem**: W coordinates baked in vertex colors, mesh moves via transform
- **Solution**: Regenerate mesh when needed, snap grid between
- **Threshold**: 50 units player movement or plane rotation
- **Performance**: 1-5 regenerations/sec vs 480/sec continuous

## Performance Characteristics

| System | Cost per Frame | Notes |
|--------|---------------|-------|
| Collision Detection | ~0.1-0.5ms | Depends on object count |
| Slice Filtering | ~0.05ms | Geometric intersection tests |
| Infinite Floors (8x) | ~0.1-0.3ms | With hybrid approach |
| 4D Shader | GPU-bound | 6 rotation matrices per vertex |
| Dimension Switch | One-time | ~1-2ms spike |

**Target**: 60 FPS (16.67ms budget) ✅ Achieved

## Testing Coverage

- **29 passing tests** (GDUnit4)
  - 7 hyperplane tests
  - 9 intersection tests
  - 13 edge slicer tests
- **Manual testing**: Dimension switching, rotation, collision
- **Performance testing**: 8 floors @ 60 FPS

## Future Expansion Points

### Phase 4 Integration (Optional)
- True geometric cross-sections (mesh slicing)
- Located in `scripts/slicing/`
- Infrastructure complete but not integrated

### Optimization Opportunities
- Spatial partitioning for collision
- Mesh caching for static objects
- Slice mesh pooling

### Gameplay Extensions
- Moving/rotating infinite floors ✅ Supported
- 4D portals/teleportation
- Dimension-locked puzzles
- Multi-player (same dimension sync)

---

**Last Updated**: 2025-11-28
**Project Status**: Core systems complete, ready for level design
