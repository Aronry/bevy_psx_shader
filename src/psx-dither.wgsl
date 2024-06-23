#import bevy_sprite::mesh2d_view_bindings
#import bevy_sprite::mesh2d_bindings
#import bevy_sprite::{
    mesh2d_view_bindings::globals,
}


struct PsxDitherMaterial {
    replace_color: vec3<f32>,
    dither_amount: f32,
    banding_enabled: u32,
    time: f32,
};

@group(1) @binding(0)
var<uniform> material: PsxDitherMaterial;
@group(1) @binding(1)
var base_color_texture: texture_2d<f32>;
@group(1) @binding(2)
var base_color_sampler: sampler;
@group(1) @binding(3)
var dither_color_texture: texture_2d<f32>;
@group(1) @binding(4)
var dither_color_sampler: sampler;
@group(1) @binding(5)
var lut_texture: texture_3d<f32>;
@group(1) @binding(6)
var lut_sampler: sampler;

fn random (noise: vec2<f32>) -> f32
{
    //--- Noise: Low Static (X axis) ---
    //return fract(sin(dot(noise.yx,vec2(0.000128,0.233)))*804818480.159265359);
    
    //--- Noise: Low Static (Y axis) ---
    //return fract(sin(dot(noise.xy,vec2(0.000128,0.233)))*804818480.159265359);
    
  	//--- Noise: Low Static Scanlines (X axis) ---
    //return fract(sin(dot(noise.xy,vec2(98.233,0.0001)))*925895933.14159265359);
    
   	//--- Noise: Low Static Scanlines (Y axis) ---
    //return fract(sin(dot(noise.xy,vec2(0.0001,98.233)))*925895933.14159265359);
    
    //--- Noise: High Static Scanlines (X axis) ---
    //return fract(sin(dot(noise.xy,vec2(0.0001,98.233)))*12073103.285);
    
    //--- Noise: High Static Scanlines (Y axis) ---
    //return fract(sin(dot(noise.xy,vec2(98.233,0.0001)))*12073103.285);
    
    //--- Noise: Full Static ---
    return fract(sin(dot(noise.xy,vec2(10.998,98.233)))*12433.14159265359);
}

struct FragmentInput {
    @location(0) c_position: vec4<f32>,
    @location(1) world_normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
};

struct Wave {
    waves_x: f32,
    waves_y: f32,

    speed_x: f32,
    speed_y: f32,

    amplitude_x: f32,
    amplitude_y: f32
};

@fragment
fn fragment(in: FragmentInput) -> @location(0) vec4<f32> {

/*     var wave: Wave;

    wave.waves_x = 0.;
    wave.waves_y = 0.;
    wave.speed_x = 1.;
    wave.speed_y = 1.;
    wave.amplitude_x = 0.03;
    wave.amplitude_y = 0.04;

    let PI = 3.1415926535897932384;

            let pi_uv = PI * in.uv;
    let pi_time = PI * globals.time;

    let offset_x = sin((pi_uv.y * wave.waves_x) + (pi_time * wave.speed_x)) * wave.amplitude_x;
    let offset_y = sin((pi_uv.x * wave.waves_y) + (pi_time * wave.speed_y)) * wave.amplitude_y;

    let uv_displaced = vec2<f32>(in.uv.x + offset_x, in.uv.y + offset_y);
 */

let uv_displaced = in.uv;

    //Noise stuff
    var maxStrength = 0.025;
    let minStrength = 0.125;

    let speed = 10.00;

    let iResolution = vec2(1920., 1080.) / 4.;

    let uv = floor(uv_displaced.xy * iResolution) / iResolution;
    let uv2 = fract(uv*fract(sin(globals.time*speed)));
    
    //--- Strength animate ---
//    maxStrength = clamp(sin(globals.time/2.0),minStrength,maxStrength);
    //-----------------------
    
    //--- Black and white ---
    let colour = vec3(random(uv2.xy))*maxStrength;


    let base_col = textureSample(base_color_texture, base_color_sampler, uv_displaced);
    let dith_size = vec2<f32>(textureDimensions(dither_color_texture));
    let buf_size = vec2<f32>(textureDimensions(base_color_texture));
    let dith = textureSample(dither_color_texture, dither_color_sampler, uv_displaced * (buf_size / dith_size)).rgb - 0.5;
    var final_col = vec3(0.0, 0.0, 0.0);
    if material.banding_enabled > 0u {
    //    final_col = round(base_col.rgb * material.dither_amount + dith * (1.0)) / material.dither_amount;
        
        final_col = round(base_col.rgb * material.dither_amount + dith * (1.0)) / material.dither_amount;
    } else {
        final_col = round(base_col.rgb * material.dither_amount + dith * (0.0)) / material.dither_amount;
    }

/*      if dot(raw_color, vec3(-1.,1.,-1.)) > 0.0 {
        final_col = material.replace_color * (1. - uv_displaced.y);
    } */
    if base_col.a <= 0.1 {
        final_col = material.replace_color * (1. - uv_displaced.y);
    }



 
    let half_texel = vec3<f32>(1.0 / 64. / 2.);


    // Notice the ".rbg".
    // If we sample the LUT using ".rgb" instead,
    // the way the 3D texture is loaded will mean the
    // green and blue colors are swapped.
    // This mitigates that.
    let raw_color = final_col.rbg - colour * 0.5;
    final_col = vec4<f32>(textureSample(lut_texture, lut_sampler, raw_color + half_texel).rgb, 1.0).rgb;

    let pixel_size_y = 1.0 / 1920. * 1.;
    let pixel_size_x = 1.0 / 1080. * 1.;

    var current_color = final_col;
    var color_left = textureSample(base_color_texture, base_color_sampler, uv_displaced - vec2(pixel_size_x, pixel_size_y)).rgb;

    current_color = current_color * vec3(1.2, 0.5, 1.0 - 1.2);
    color_left = color_left * vec3(1. - 1.2, 0.5, 1.2);

    final_col = current_color + color_left;

    return vec4(final_col, 1.0);
}