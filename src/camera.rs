// use std::f32::consts::PI;

use std::f32::consts::PI;

use bevy::{
    pbr::ScreenSpaceReflectionsBundle, prelude::*, render::{
        camera::{Exposure, PhysicalCameraParameters, RenderTarget, Viewport}, render_asset::RenderAssetUsages, render_resource::{
            Extent3d, TextureDescriptor, TextureDimension, TextureFormat, TextureUsages,
        }, texture::{BevyDefault, ImageAddressMode, ImageSampler, ImageSamplerDescriptor}, view::RenderLayers
    }, sprite::MaterialMesh2dBundle, window::PrimaryWindow
};

use bevy::render::render_resource::*;

use crate::material::{Lut, PsxDitherMaterial, PSX_LUT_HANDLE};

#[derive(Component)]
pub struct PsxCamera {
    pub size: UVec2,
    pub fixed_axis: Option<bool>,
    pub clear_color: Color,
    pub hdr: bool,
    pub dither_amount: f32,
    pub fov: f32,
    pub banding_enabled: u32,
    init: bool,
}

impl Default for PsxCamera {
    fn default() -> Self {
        Self {
            size: UVec2::new(1920 / 2, 1080 / 2),
            fixed_axis: None,
            clear_color: Color::WHITE,
            init: false,
            hdr: false,
            dither_amount: 8.0,
            fov: 105.,
            banding_enabled: 1,
        }
    }
}

impl PsxCamera {
    pub fn new(
        size: UVec2,
        axis: Option<bool>,
        clear_color: Color,
        hdr: bool,
        dither_amount: f32,
        fov: f32,
        banding_enabled: u32,
    ) -> Self {
        Self {
            size,
            fixed_axis: axis,
            clear_color,
            init: false,
            hdr,
            dither_amount,
            fov,
            banding_enabled,
            ..default()
        }
    }

    pub fn from_height(height: u32) -> Self {
        Self {
            size: UVec2::new(0, height),
            fixed_axis: Some(false),
            clear_color: Color::WHITE,
            init: false,
            hdr: false,
            ..default()
        }
    }
    pub fn from_width(width: u32) -> Self {
        Self {
            size: UVec2::new(width, 0),
            fixed_axis: Some(true),
            clear_color: Color::WHITE,
            init: false,
            hdr: false,
            ..default()
        }
    }
    pub fn from_resolution(width: u32, height: u32) -> Self {
        Self {
            size: UVec2::new(width, height),
            fixed_axis: None,
            clear_color: Color::WHITE,
            init: false,
            hdr: false,
            ..default()
        }
    }
}

#[derive(Component)]
pub struct RenderImage;

#[derive(Component)]
pub struct FinalCameraTag;

pub fn setup_camera(
    mut commands: Commands,
    mut camera: Query<(&mut PsxCamera, Entity)>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<PsxDitherMaterial>>,
    mut images: ResMut<Assets<Image>>,
) {
    for (mut pixel_camera, entity) in camera.iter_mut() {
        if !pixel_camera.init {
            pixel_camera.init = true;
            let size = Extent3d {
                width: pixel_camera.size.x,
                height: pixel_camera.size.y,
                ..default()
            };

            
            let lut_image = images
                .get_mut(&PSX_LUT_HANDLE)
                .expect("Handle should point to asset");

            // The LUT is a 3d texture. It has 64 layers, each of which is a 64x64 image.
            lut_image.texture_descriptor.size = Extent3d {
                width: 64,
                height: 64,
                depth_or_array_layers: 64,
            };
            lut_image.texture_descriptor.dimension = TextureDimension::D3;
            lut_image.texture_descriptor.format = TextureFormat::Rgba8Unorm;

            lut_image.texture_view_descriptor = Some(TextureViewDescriptor {
                label: Some("LUT Texture View"),
                format: Some(TextureFormat::Rgba8Unorm),
                dimension: Some(TextureViewDimension::D3),
                ..default()
            });

            // This is the texture that will be rendered to.
            let mut image = Image {
                texture_descriptor: TextureDescriptor {
                    label: None,
                    size,
                    dimension: TextureDimension::D2,
                    format: TextureFormat::bevy_default(),
                    mip_level_count: 1,
                    sample_count: 1,
                    usage: TextureUsages::TEXTURE_BINDING
                        | TextureUsages::COPY_DST
                        | TextureUsages::RENDER_ATTACHMENT,
                    view_formats: &[],
                },
                sampler: ImageSampler::nearest(),
            //    asset_usage: RenderAssetUsages::RENDER_WORLD,
                ..default()
            };

            // fill image.data with zeroes
            image.resize(size);

            let image_handle = images.add(image);

            // The camera we are actually rendering to
            let camera = if pixel_camera.hdr {
                Camera3dBundle {
                //    tonemapping: bevy::core_pipeline::tonemapping::Tonemapping::None,
                    camera: Camera {
                        target: RenderTarget::Image(image_handle.clone()),
                        clear_color: ClearColorConfig::Custom(Color::rgba(0.,0.,0.,0.)),
                        hdr: true,
                        ..default()
                    },
                    camera_3d: Camera3d {
                    //    clear_color: ClearColorConfig::Custom(pixel_camera.clear_color),
                        ..default()
                    },
                    projection: Projection::Perspective(PerspectiveProjection {
                        fov: pixel_camera.fov * PI / 180.,
                        ..default()
                    }),
                    exposure: Exposure::from_physical_camera(PhysicalCameraParameters {
                        aperture_f_stops: 1.0,
                        shutter_speed_s: 1. / 31.,
                        sensitivity_iso: 500.,
                        ..Default::default()
                    }), 
                    ..Default::default()
                }
            } else {
                Camera3dBundle {
                //    tonemapping: bevy::core_pipeline::tonemapping::Tonemapping::None,
                    camera: Camera {
                        target: RenderTarget::Image(image_handle.clone()),
                        clear_color: ClearColorConfig::Custom(Color::rgba(0.,0.,0.,0.)),
                        hdr: false,
                        ..default()
                    },
                    projection: Projection::Perspective(PerspectiveProjection {
                        fov: pixel_camera.fov * PI / 180.,
                        ..default()
                    }),
                    exposure: Exposure::from_physical_camera(PhysicalCameraParameters {
                        aperture_f_stops: 1.0,
                        shutter_speed_s: 1. / 31.,
                        sensitivity_iso: 500.,
                        ..Default::default()
                    }), 
                    ..Default::default()
                }
            };

            commands
                .entity(entity)
            //    .insert()
                //.insert((UiCameraConfig { show_ui: false }, camera));
                .insert((Visibility::Hidden, camera, ScreenSpaceReflectionsBundle::default()));

            let render_layer = 3 ;
            let ui_layer = render_layer - 1;

            let quad_handle = meshes.add(Mesh::from(Rectangle::new(
                size.width as f32,
                size.height as f32,
            )));


            //dithering
            let level = 3;
            let power = level + 1;
            let map_size: u32 = 1 << power;
            let mut buffer = Vec::<u8>::new();

            for row in 0..map_size {
                for col in 0..map_size {
                    let a = row ^ col;
                    // Interleave bits of `a` with bits of y coordinate in reverse order
                    let mut result: u64 = 0;
                    let mut bit = 0;
                    let mut mask = power as i32 - 1;
                    loop {
                        if bit >= 2 * power {
                            break;
                        }
                        result |= (((col >> mask) & 1) << bit) as u64;
                        bit += 1;
                        result |= (((a >> mask) & 1) << bit) as u64;
                        bit += 1;
                        mask -= 1;
                    }
                    let value = ((result as f32 / map_size.pow(2) as f32) * 255.0) as u8;
                    buffer.push(value);
                }
            }

            let mut image = Image::new(
                Extent3d {
                    width: map_size,
                    height: map_size,
                    depth_or_array_layers: 1,
                },
                TextureDimension::D2,
                buffer,
                TextureFormat::R8Unorm,
                RenderAssetUsages::RENDER_WORLD,
            );
            image.texture_descriptor.usage = TextureUsages::COPY_DST
                | TextureUsages::STORAGE_BINDING
                | TextureUsages::TEXTURE_BINDING;
            let mut desc = ImageSamplerDescriptor::nearest();
            desc.address_mode_u = ImageAddressMode::Repeat;
            desc.address_mode_v = ImageAddressMode::Repeat;
            desc.address_mode_w = ImageAddressMode::Repeat;
            image.sampler = ImageSampler::Descriptor(desc);

            let dither_handle = images.add(image);




            commands.spawn((
                MaterialMesh2dBundle {
                    mesh: quad_handle.into(),
                    material: materials.add(PsxDitherMaterial {
                        dither_amount: pixel_camera.dither_amount,
                        banding_enabled: pixel_camera.banding_enabled,
                        color_texture: Some(image_handle),
                        dither_color_texture: Some(dither_handle),
                        ..Default::default()
                    }),
                    transform: Transform { ..default() },
                    ..default()
                },
                RenderLayers::layer(render_layer),
                RenderImage,
            ));

            commands.spawn((
                Camera2dBundle {
                    camera: Camera {
                        viewport: Some(Viewport {
                            physical_size: UVec2 {
                                x: pixel_camera.size.x,
                                y: pixel_camera.size.y,
                            },
                            ..Default::default()
                        }),
                        // renders after the first main camera which has default value: 0.
                        order: 1,
                        ..default()
                    },
                    ..Camera2dBundle::default()
                },
                RenderLayers::layer(render_layer),
                FinalCameraTag,
                //UiCameraConfig { show_ui: false },
            ));
            commands.spawn((
                Camera2dBundle {
                    camera: Camera {

                        // renders after the camera that draws the texture
                        order: 2,
                        clear_color: ClearColorConfig::None,
                        ..default()
                    },
                    camera_2d: Camera2d {},
                    ..Default::default()
                },
                RenderLayers::layer(ui_layer),
            ));
        }
    }
}

pub fn scale_render_image(
    mut texture_query: Query<&mut Transform, With<RenderImage>>,
    mut camera_query: Query<&mut bevy::render::camera::Camera, With<FinalCameraTag>>,
    mut psx_camera_query: Query<&PsxCamera>,
    mut windows: Query<&mut Window, With<PrimaryWindow>>,
) {
    if let Ok(mut texture_transform) = texture_query.get_single_mut() {
        if let Ok(window) = windows.get_single_mut() {
            if let Ok(mut camera) = camera_query.get_single_mut() {
                if let Ok(psx_camera) = psx_camera_query.get_single_mut() {
                    let (screen_width, screen_height) = (psx_camera.size.x, psx_camera.size.y);
                    let aspect_ratio = screen_width as f32 / screen_height as f32;
                    let window_size: UVec2 = if window.physical_height() > window.physical_width()
                        || window.physical_height() as f32 * aspect_ratio
                            > window.physical_width() as f32
                    {
                        UVec2::new(
                            window.physical_width(),
                            (window.physical_width() as f32 / aspect_ratio).floor() as u32,
                        )
                    } else {
                        UVec2::new(
                            (window.physical_height() as f32 * aspect_ratio).floor() as u32,
                            window.physical_height(),
                        )
                    };

                    let scale_width = window_size.x as f32 / screen_width as f32;
                    let scale_height = window_size.y as f32 / screen_height as f32;
                    let window_position: UVec2 = if window.physical_height()
                        > window.physical_width()
                        || window.physical_height() as f32 * aspect_ratio
                            > window.physical_width() as f32
                    {
                        if let Some(height) =
                            (window.physical_height() / 2).checked_sub(window_size.y / 2)
                        {
                            UVec2::new(0, height)
                        } else {
                            UVec2::ZERO
                        }
                    } else if let Some(width) =
                        (window.physical_width() / 2).checked_sub(window_size.x / 2)
                    {
                        UVec2::new(width, 0)
                    } else {
                        UVec2::ZERO
                    };

                    texture_transform.scale = Vec3::new(scale_width, scale_height, 1.0);
/* 
                    println!("texture_transform.scale: {}", texture_transform.scale);
                    println!("window_size: {}", window_size);
                    println!("screen_size: {} {}", screen_width, screen_height);
 */
                    camera.viewport = Some(Viewport {
                        physical_size: window_size,
                        physical_position: window_position,
                        ..Default::default()
                    });
                }
            }
        }
    }
}


