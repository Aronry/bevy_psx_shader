#import bevy_pbr::mesh_view_bindings::view
#import bevy_pbr::mesh_view_bindings::globals
#import bevy_pbr::mesh_bindings::mesh
#import bevy_pbr::mesh_bindings::mesh

struct PsxMaterial {
    color: vec4<f32>,
    fog_color: vec4<f32>,
    snap_amount: f32,
    fog_distance: vec2<f32>
};

@group(2) @binding(0)
var<uniform> material: PsxMaterial;

// NOTE: Bindings must come before functions that use them!
#import bevy_render::instance_index::get_instance_index 
#import bevy_pbr::mesh_functions::{get_model_matrix, mesh_position_local_to_clip, mesh_normal_local_to_world}
struct Vertex {
    @builtin(instance_index) instance_index: u32,
    @location(0) position: vec4<f32>,
    @location(1) normal: vec3<f32>,
    #ifdef VERTEX_COLORS
        @location(4) color: vec4<f32>,
    #endif
    @location(2) uv: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) c_position: vec4<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) fog: f32,
    @location(3) vertex_color: vec4<f32>,
};

@vertex
fn vertex(vertex: Vertex) -> VertexOutput {
    var out: VertexOutput;
    let in_clip = mesh_position_local_to_clip(get_model_matrix(vertex.instance_index), vertex.position);
    let snap_scale = material.snap_amount;
    var position = vec4(
        in_clip.x  / in_clip.w,
        in_clip.y  / in_clip.w,
        in_clip.z  / in_clip.w,
        in_clip.w
    );
    position = vec4(
        floor(in_clip.x * snap_scale) / snap_scale,
        floor(in_clip.y * snap_scale) / snap_scale,
        in_clip.z,
        in_clip.w
    );

    let world_normal = mesh_normal_local_to_world(
        vertex.normal,
        // Use vertex_no_morph.instance_index instead of vertex.instance_index to work around a wgpu dx12 bug.
        // See https://github.com/gfx-rs/naga/issues/2416
        vertex.instance_index
    );

    let depth_vert = view.projection * vec4(position);
    let depth = abs(depth_vert.z / depth_vert.w);
    out.clip_position = position;
    out.c_position = position;
    out.uv = vertex.uv * position.w;
    out.fog = 1.0 - clamp((material.fog_distance.y - depth) / (material.fog_distance.y - material.fog_distance.x), 0.0, 1.0);

    #ifdef VERTEX_COLORS
        out.vertex_color = vertex.color;
    #else
        out.vertex_color = vec4(1.0, 1.0, 1.0, 1.0);
        out.vertex_color = (sin(globals.time * 2. + out.c_position.y * 40. + out.c_position.x * 220. + cos(out.c_position.z) * 99.) * 0.5 + 0.5) * out.vertex_color * 16.;

    #endif
    
    return out;
}
