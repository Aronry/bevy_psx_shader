#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::mesh_bindings

struct PsxMaterial {
    color: vec4<f32>,
    fog_color: vec4<f32>,
    snap_amount: f32,
    fog_distance: vec2<f32>,
};
@group(2) @binding(0)
var<uniform> material: PsxMaterial;
@group(2) @binding(1)
var base_color_texture: texture_2d<f32>;
@group(2) @binding(2)
var base_color_sampler: sampler;

// NOTE: Bindings must come before functions that use them!
#import bevy_pbr::mesh_functions


struct FragmentInput {
    @location(0) c_position: vec4<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) fog: f32,
    @location(3) vertex_color: vec4<f32>,
};


@fragment
fn fragment(in: FragmentInput) -> @location(0) vec4<f32> {
    let fir_col = in.vertex_color * material.color * textureSample(base_color_texture, base_color_sampler, in.uv / in.c_position.w);
    let col = vec4(mix(fir_col.rgb, material.fog_color.rgb, in.fog), 1.0);
    return col;
}



