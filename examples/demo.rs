use bevy::{prelude::*, render::render_resource::Extent3d, sprite::Mesh2dHandle};
use bevy_psx::{camera::{scale_render_image, PsxCamera, RenderImage}, material::PsxMaterial, PsxPlugin};

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(ImagePlugin::default_nearest()))
    //    .add_plugins(DefaultPlugins)
        .add_plugins(PsxPlugin)
        .insert_resource(Msaa::Off)
        .add_systems(Startup,setup)
        .add_systems(Update,rotate)
    //    .add_systems(Update,render_image_scale2.after(scale_render_image))
        .run();
}

// RN3 TEST LOLOL

/// Set up a simple 3D scene
fn setup(
    mut commands: Commands,
    _meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<PsxMaterial>>,
    mut smaterials: ResMut<Assets<StandardMaterial>>,
    asset_server: Res<AssetServer>,
) {
    commands.spawn(PsxCamera::new(
        UVec2::new(1920 /2 , 1080 /2),
        None,
        Color::rgba(0.,0.,0.,0.),
        false,
        48.,
        45.,
        1
    ));
    let transform =
    Transform::from_scale(Vec3::splat(0.20)).with_translation(Vec3::new(0.0, -3.5, -10.0));
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh2/Primitive0"),
            material: materials.add(PsxMaterial {
                color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                snap_amount: 10.0,  
                fog_distance: Vec2::new(250.0, 750.0), 
                
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh0/Primitive0"),
            material: materials.add(PsxMaterial {
                color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                snap_amount: 10.0,  
                fog_distance: Vec2::new(250.0, 750.0), 
                
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            //import from gltf dvaBlender.glb
            mesh: asset_server.load("dvaBlender.glb#Mesh1/Primitive0"),
            material: materials.add(PsxMaterial {
               // color_texture load from gltf
               // color_texture: Some(asset_server.load("crate.png")),
                color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                snap_amount: 10.0,  
                fog_distance: Vec2::new(250.0, 750.0), 
                
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
/* 
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh2/Primitive0"),
            material: smaterials.add(StandardMaterial {
                base_color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh0/Primitive0"),
            material: smaterials.add(StandardMaterial {
                base_color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            //import from gltf dvaBlender.glb
            mesh: asset_server.load("dvaBlender.glb#Mesh1/Primitive0"),
            material: smaterials.add(StandardMaterial {
                base_color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    )); */
    commands.spawn(PointLightBundle {
        transform: Transform::from_translation(Vec3::new(0.0, 0.0, 10.0)),
        ..default()
    });

}

#[derive(Component)]
struct Rotates;

/// Rotates any entity around the x and y axis
fn rotate(time: Res<Time>, mut query: Query<&mut Transform, With<Rotates>>) {
    for mut transform in &mut query {
        transform.rotate_y(0.95 * time.delta_seconds());
        // transform.scale = Vec3::splat(0.25);
        // transform.rotate_x(0.95 * time.delta_seconds());
        // transform.rotate_z(0.95 * time.delta_seconds());
    }
}
pub fn render_image_scale2(
    time: Res<Time>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut images: ResMut<Assets<Image>>,
    mut pixel_meshes: Query<&Mesh2dHandle, With<RenderImage>>,
    mut pixel_cameras: Query<&mut PsxCamera>,
    mut cameras: Query<&mut Camera>,
    windows: Query<&Window>,
) {
    if time.elapsed_seconds() < 2. {
        return;
    }

    for window in windows.iter() {
        

        for mut psx_camera in pixel_cameras.iter_mut() {
            for mut camera in cameras.iter_mut() {
                if let Some(image_handle) = camera.target.as_image() {
                    if let Some(image) = images.get_mut(image_handle) {
                        let window_size = UVec2::new(window.resolution.physical_width(), window.resolution.physical_height());
    


                        let size = Extent3d {
                            width: window_size.x / 2,
                            height: window_size.y / 2,
                            ..default()
                        };


                        if image.size() != UVec2::new(size.width, size.height) {
                            psx_camera.size = UVec2::new(size.width, size.height);
                            println!("FAG");
                            image.resize(size);    
                            for pixel_mesh in pixel_meshes.iter() {
                                if let Some(mesh) = meshes.get_mut(pixel_mesh.0.clone()) {
                                    *mesh = Mesh::from(shape::Quad::new(Vec2::new(
                                        size.width as f32,
                                        size.height as f32,
                                    )));
                                }
                            }
                        }
                    }
                }
            }
        }

    }

}
