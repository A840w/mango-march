# First-Person Tree Climbing Setup

Target: Godot 4.4+

## Scene Hierarchy

```text
player (CharacterBody3D, PlayerController.gd)
├── StandingCollison (CollisionShape3D)
├── CameraPivot (Node3D)
│   └── Camera3D
│       ├── LeftHand (Sprite3D)
│       ├── RightHand (Sprite3D)
│       └── ArmP (Node3D)
│           ├── LeftArm (SpringArm3D)
│           │   └── LeftHandcollison (Area3D)
│           │       └── CollisionShape3D
│           └── RightArm (SpringArm3D)
│               └── RightHandcollison (Area3D)
│                   └── CollisionShape3D
└── components (Node)
    ├── ClimbingComponent (ClimbingComponent.gd)
    ├── LeftHandArmComponent (HandArmComponent.gd)
    └── RightHandArmComponent (HandArmComponent.gd)
```

## Script Responsibilities

`PlayerController.gd`

- Extends `CharacterBody3D`.
- Handles WASD movement, gravity, jumping, mouse look, and `move_and_slide()`.
- Reads damped climbing velocity from `ClimbingComponent`.

`ClimbingComponent.gd`

- Updates both hand components.
- Computes one-hand and two-hand anchors.
- Produces smoothed climb velocity from anchor pull plus camera look influence.

`HandArmComponent.gd`

- Handles one hand: mouse button input, arm extension/retraction, Area3D detection, lock/unlock, hand sprite position.
- Emits `grabbed(hand, grab_position, grabbed_node)` and `released(hand)`.

`ClimbEnums.gd`

- Shared hand enums, state enums, climbable group names, and damping helper.

## Required Groups

Only nodes in these groups can be grabbed:

- `ClimbableTree`
- `ClimbableBranch`

Add those groups to your trunk/branch collision bodies or climbable `Area3D` nodes.

## Input

- Left mouse button: left hand.
- Right mouse button: right hand.
- Existing project WASD actions are used: `left`, `right`, `up`, `down`.
- `ui_accept` jumps only while grounded and not attached.

## Signal Connections

The scene is already wired through exported references:

- `ClimbingComponent.left_hand` -> `components/LeftHandArmComponent`
- `ClimbingComponent.right_hand` -> `components/RightHandArmComponent`
- Each `HandArmComponent` connects its own `Area3D.body_entered/body_exited/area_entered/area_exited`.
- `ClimbingComponent` connects to each hand's `grabbed` and `released` signals in `_ready()`.

## Tuning

Start here:

- `HandArmComponent.reach_distance`
- `HandArmComponent.extension_speed`
- `HandArmComponent.retraction_speed`
- `ClimbingComponent.climb_speed`
- `ClimbingComponent.anchor_pull_strength`
- `ClimbingComponent.camera_influence_strength`
- `PlayerController.attached_gravity_scale`

Turn on `debug_enabled` on any of the three scripts for print output.
