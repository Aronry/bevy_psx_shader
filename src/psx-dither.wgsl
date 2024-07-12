#import bevy_sprite::mesh2d_view_bindings
#import bevy_sprite::mesh2d_bindings
#import bevy_sprite::{
    mesh2d_view_bindings::globals,
}


struct PsxDitherMaterial {
    replace_color: vec3<f32>,
    mult_color: vec3<f32>,
    dither_amount: f32,
    banding_enabled: u32,
};



@group(2) @binding(0)
var<uniform> material: PsxDitherMaterial;
@group(2) @binding(1)
var base_color_texture: texture_2d<f32>;
@group(2) @binding(2)
var base_color_sampler: sampler;
@group(2) @binding(3)
var dither_color_texture: texture_2d<f32>;
@group(2) @binding(4)
var dither_color_sampler: sampler;
@group(2) @binding(5)
var lut_texture: texture_3d<f32>;
@group(2) @binding(6)
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


fn channelError(col: f32, colMin: f32, colMax: f32) -> f32 {
	let range: f32 = abs(colMin - colMax);
	let aRange: f32 = abs(col - colMin);
	return aRange / range;
} 

fn ditheredChannel(error: f32, ditherBlockUV: vec2<f32>) -> f32 {
	let pattern: f32 = textureSample(dither_color_texture, dither_color_sampler, ditherBlockUV).r;
	if (error > pattern) {
		return 1.;
	} else { 
		return 0.;
	}
} 
/* 
fn mix(a: vec4<f32>, b: vec4<f32>, amt: f32) -> vec4<f32> {
	return (1. - amt) * a + b * amt;
}  */

fn RGBtoYUV(rgb: vec3<f32>) -> vec3<f32> {
	var yuv: vec3<f32>;
	yuv.r = rgb.r * 0.2126 + 0.7152 * rgb.g + 0.0722 * rgb.b;
	yuv.g = (rgb.b - yuv.r) / 1.8556;
	yuv.b = (rgb.r - yuv.r) / 1.5748;
	var yuvgb = yuv.gb;
	yuvgb = yuv.gb + (0.5);
	yuv.g = yuvgb.x;
	yuv.b = yuvgb.y;
	return yuv;
} 

fn YUVtoRGB(inyuv: vec3<f32>) -> vec3<f32> {
/* 	var yuvgb = yuv.gb;
	yuvgb = yuv.gb - (0.5);
	yuv.g = yuvgb.x;
	yuv.b = yuvgb.y; */
    var yuv = inyuv;
    yuv.g -= 0.5;
    yuv.b -= 0.5;
	return vec3<f32>(yuv.r * 1. + yuv.g * 0. + yuv.b * 1.5748, yuv.r * 1. + yuv.g * -0.187324 + yuv.b * -0.468124, yuv.r * 1. + yuv.g * 1.8556 + yuv.b * 0.);
} 

fn ditherColor(col: vec3<f32>, uv: vec2<f32>, xres: f32, yres: f32) -> vec3<f32> {
	var yuv: vec3<f32> = RGBtoYUV(col);
	let col1: vec3<f32> = floor(yuv * material.dither_amount) / material.dither_amount;
	let col2: vec3<f32> = ceil(yuv * material.dither_amount) / material.dither_amount;
	let ditherBlockUV: vec2<f32> = uv * vec2<f32>(xres / 8., yres / 8.);
	yuv.x = mix(col1.x, col2.x, ditheredChannel(channelError(yuv.x, col1.x, col2.x), ditherBlockUV));
	yuv.y = mix(col1.y, col2.y, ditheredChannel(channelError(yuv.y, col1.y, col2.y), ditherBlockUV));
	yuv.z = mix(col1.z, col2.z, ditheredChannel(channelError(yuv.z, col1.z, col2.z), ditherBlockUV));
	return YUVtoRGB(yuv);
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

    let iResolution = vec2<f32>(textureDimensions(base_color_texture)) * 4.;

    let uv = floor(uv_displaced.xy * iResolution) / iResolution;
    let uv2 = fract(uv*fract(sin(globals.time*speed)));
    
    //--- Strength animate ---
//    maxStrength = clamp(sin(globals.time/2.0),minStrength,maxStrength);
    //-----------------------
    
    //--- Black and white ---
    let colour = vec3(random(uv2.xy))*maxStrength;


    var base_col = textureSample(base_color_texture, base_color_sampler, uv_displaced);

    let pixel_size_y = 1.0 / iResolution.x * 3.;
    let pixel_size_x = 1.0 / iResolution.y * 3.;

    var current_color = base_col;
    var color_left = textureSample(base_color_texture, base_color_sampler, uv_displaced - vec2(pixel_size_x, pixel_size_y));

    current_color = current_color * vec4(1.2, 0.5, 1.0 - 1.2, 1.);
    color_left = color_left * vec4(1. - 1.2, 0.5, 1.2, 1.);

    base_col = current_color + color_left;
    base_col = base_col;

    let sky_col = vec3<f32>(1.,1.,1.)  * (1. - uv_displaced.y) + vec3<f32>(0.,0.,1.);
    base_col += vec4<f32>(base_col.rgb + (sky_col * max(1. - base_col.a, 0.)), 1.);
/*     if base_col.a <= 0.1 {
        base_col = vec4<f32>(material.replace_color * (1. - uv_displaced.y), 1.);
    }
 */
    base_col = base_col * vec4<f32>(material.mult_color, 1.);



    var final_col = ditherColor(base_col.rgb, uv_displaced, iResolution.x / 4., iResolution.y / 4.);

/* 
    let dith_size = vec2<f32>(textureDimensions(dither_color_texture));
    let buf_size = vec2<f32>(textureDimensions(base_color_texture));
    let dith = textureSample(dither_color_texture, dither_color_sampler, uv_displaced * (buf_size / dith_size)).rgb - 0.5;
    var final_col = vec3(0.0, 0.0, 0.0);


    let screen_size = vec2i(textureDimensions(base_color_texture));
    let threshold_map_size = vec2i(textureDimensions(dither_color_texture));
    let pixel_position = vec2i(floor(in.uv * vec2f(screen_size)));
    let map_position = vec2f(pixel_position % threshold_map_size) / vec2f(threshold_map_size);

    let threshold = textureSample(dither_color_texture, dither_color_sampler, map_position).r;

    let base_color = base_col.rgb; // - colour * 0.5;
    let luma = (0.2126 * base_color.r + 0.7152 * base_color.g + 0.0722 * base_color.b);
    let value = f32(luma >= threshold);




    if material.banding_enabled > 0u {
    //    final_col = round(base_col.rgb * material.dither_amount + dith * (1.0)) / material.dither_amount;
        
        final_col = round(base_col.rgb * material.dither_amount + (value - 0.5) * (1.0)) / material.dither_amount;
    } else {
        final_col = round(base_col.rgb * material.dither_amount + (value - 0.5) * (1.0)) / material.dither_amount;
    }
 */
/*      if dot(raw_color, vec3(-1.,1.,-1.)) > 0.0 {
        final_col = material.replace_color * (1. - uv_displaced.y);
    } */




    let half_texel = vec3<f32>(1.0 / 64. / 2.);


    // Notice the ".rbg".
    // If we sample the LUT using ".rgb" instead,
    // the way the 3D texture is loaded will mean the
    // green and blue colors are swapped.
    // This mitigates that.
    let raw_color = final_col.rbg;// - colour * 0.5;
    final_col = vec4<f32>(textureSample(lut_texture, lut_sampler, raw_color + half_texel).rgb, 1.0).rgb;

    return vec4(final_col, 1.0);
}
