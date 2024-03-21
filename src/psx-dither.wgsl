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

@fragment
fn fragment(in: FragmentInput) -> @location(0) vec4<f32> {
    let half_texel = vec3<f32>(1.0 / 64. / 2.);


    // Notice the ".rbg".
    // If we sample the LUT using ".rgb" instead,
    // the way the 3D texture is loaded will mean the
    // green and blue colors are swapped.
    // This mitigates that.
    let raw_color = textureSample(base_color_texture, base_color_sampler, in.uv).rgb; //final_col.rbg;
    let base_col = vec4<f32>(textureSample(lut_texture, lut_sampler, raw_color.rbg + half_texel).rgb, 1.0);

 //   let base_col = textureSample(base_color_texture, base_color_sampler, in.uv);
    let dith_size = vec2<f32>(textureDimensions(dither_color_texture));
    let buf_size = vec2<f32>(textureDimensions(base_color_texture));
    let dith = textureSample(dither_color_texture, dither_color_sampler, in.uv * (buf_size / dith_size)).rgb - 0.5;
    var final_col = vec3(0.0, 0.0, 0.0);
    if material.banding_enabled > 0u {
    //    final_col = round(base_col.rgb * material.dither_amount + dith * (1.0)) / material.dither_amount;
        
        final_col = round(base_col.rgb * material.dither_amount + dith * (1.0)) / material.dither_amount;
    } else {
        final_col = round(base_col.rgb * material.dither_amount + dith * (0.0)) / material.dither_amount;
    }

     if dot(raw_color, vec3(-1.,1.,-1.)) > 0.9 {
        final_col = material.replace_color * (1. - in.uv.y);
    }
 


    //Noise stuff
    var maxStrength = 0.025;
    let minStrength = 0.125;

    let speed = 10.00;

    let iResolution = vec2(1920., 1080.) / 4.;

    let uv = floor(in.uv.xy * iResolution) / iResolution;
    let uv2 = fract(uv*fract(sin(globals.time*speed)));
    
    //--- Strength animate ---
//    maxStrength = clamp(sin(globals.time/2.0),minStrength,maxStrength);
    //-----------------------
    
    //--- Black and white ---
    let colour = vec3(random(uv2.xy))*maxStrength;

    return vec4(final_col-colour, 1.0);
}