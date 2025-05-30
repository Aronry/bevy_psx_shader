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
    pixel_blur: f32,
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

fn modulo(x: f32, y: f32) -> f32 {
    return x - y * floor(x / y);
} 

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
    let iResolution = vec2<f32>(textureDimensions(base_color_texture)) * 4.;

    let transitionDelay = 0.5;			// Start transition after x Seconds.
    let transitionTime = 1.5;				// Transition lasts x Seconds.
    let maximumBlockSize = 12.0;			// Maximum Block Size (2 ^ x)
    let blockOffset = vec2(0.5, 0.5);		// Inner Block offset
    let pixelateCenter = vec2(0.5, 0.5);	// Pixelate offset.
    
    // Animation Calculations
    let time = modulo(globals.time, (transitionDelay+transitionTime)*2.0); // Repeat every 4 seconds.
    let animTime = clamp(time - transitionDelay, 0.0, transitionTime);		// Time in 0..transitionTime
  //  let animProgress = animTime / transitionTime;								// Time as Progress (0..1)
    let animProgress = material.pixel_blur;
    let animStuff = 1.0 - (abs(animProgress - 0.5) * 2.0);					// Progress as a bounce value (0..1..0)
    // There are two ways to calculate this, one is pixel aligned the other is block aligned.
    let animBlockSize = floor(pow(2.0, maximumBlockSize * animStuff));		// Block Size, always a multiple of 2. (Pixel Aligned)

    var finalUV = in.uv;				// Use 0..1 UVs
    finalUV -= pixelateCenter;		// Offset by the pixelation center.
    finalUV *= iResolution.xy;		// Convert to 0..Resolution UVs for pixelation.
    finalUV /= animBlockSize;		// Divide by current block size.
    finalUV = floor(finalUV) + blockOffset;	// Use floor() on it to get aligned pixels. *1
    finalUV *= animBlockSize;		// Multiply by current block size.
    finalUV /= iResolution.xy;		// Convert back to 0..1 UVs for texture sampling.
    finalUV += pixelateCenter;		// Revert the offset by the pixelation center again.

    let uv_displaced = finalUV; //in.uv;

    //Noise stuff
    var maxStrength = 0.025;
    let minStrength = 0.125;

    let speed = 10.00;


  //  let uv = floor(uv_displaced.xy * iResolution) / iResolution;
   // let uv2 = fract(uv*fract(sin(globals.time*speed)));
    
    //--- Strength animate ---
//    maxStrength = clamp(sin(globals.time/2.0),minStrength,maxStrength);
    //-----------------------
    
    //--- Black and white ---


    var base_col = textureSample(base_color_texture, base_color_sampler, uv_displaced);

    let pixel_size_y = 1.0 / iResolution.x * 3.;
    let pixel_size_x = 1.0 / iResolution.y * 3.;

    var current_color = base_col;
    var color_left = textureSample(base_color_texture, base_color_sampler, uv_displaced - vec2(pixel_size_x, pixel_size_y));

    current_color = current_color * vec4(1.2, 0.5, 1.0 - 1.2, 1.);
    color_left = color_left * vec4(1. - 1.2, 0.5, 1.2, 1.);

    base_col = current_color + color_left;
//    base_col = vec4(base_col.rgb + dpdx(base_col.rgb)*vec3(3.,0.,-3.), base_col.a);
    base_col = base_col;

    let sky_col = material.replace_color  * (0.7 - uv_displaced.y) + vec3<f32>(0.,0.,0.);
    base_col += vec4<f32>(base_col.rgb + (sky_col * max(1. - base_col.a, 0.)), 1.);

    base_col = base_col * vec4<f32>(material.mult_color, 1.);



    var final_col = ditherColor(base_col.rgb, uv_displaced, iResolution.x / 4., iResolution.y / 4.);

    let half_texel = vec3<f32>(1.0 / 64. / 2.);

    // Notice the ".rbg".
    // If we sample the LUT using ".rgb" instead,
    // the way the 3D texture is loaded will mean the
    // green and blue colors are swapped.
    // This mitigates that.
    let raw_color = final_col.rbg;// - colour * 0.5;
    final_col = vec4<f32>(textureSample(lut_texture, lut_sampler, raw_color + half_texel).rgb, 1.0).rgb;
/* 
    let noise = (fract(sin(dot(in.uv * globals.time, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
    final_col += vec3(noise * 0.05);
 */
    return vec4(final_col, 1.0);
}
